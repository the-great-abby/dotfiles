/**
 * Popup script for GTD Article Processor
 */

const DEFAULT_API_ENDPOINT = 'http://localhost:8000';

// Load settings
async function loadSettings() {
  const result = await chrome.storage.sync.get(['apiEndpoint']);
  const endpoint = result.apiEndpoint || DEFAULT_API_ENDPOINT;
  document.getElementById('apiEndpoint').value = endpoint;
  return endpoint;
}

// Save settings
async function saveSettings() {
  const endpoint = document.getElementById('apiEndpoint').value.trim();
  await chrome.storage.sync.set({ apiEndpoint: endpoint });
  showStatus('Settings saved!', 'success');
}

// Show status message
function showStatus(message, type = 'loading') {
  const statusEl = document.getElementById('status');
  statusEl.textContent = message;
  statusEl.className = `status ${type}`;
  setTimeout(() => {
    if (type !== 'loading') {
      statusEl.style.display = 'none';
    }
  }, type === 'error' ? 5000 : 3000);
}

// Show results
function showResults(title, content) {
  const resultsEl = document.getElementById('results');
  resultsEl.innerHTML = `<h3>${title}</h3><pre>${escapeHtml(content)}</pre>`;
  resultsEl.classList.add('show');
}

// Escape HTML
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Extract content from current tab
async function extractContent() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  
  try {
    const response = await chrome.tabs.sendMessage(tab.id, { action: 'extractContent' });
    if (response.success) {
      return response.content;
    } else {
      throw new Error(response.error || 'Failed to extract content');
    }
  } catch (error) {
    throw new Error(`Failed to extract content: ${error.message}`);
  }
}

// Check if API is reachable
async function checkApiConnection(apiEndpoint) {
  try {
    // Try to reach the health endpoint first
    const healthUrl = `${apiEndpoint}/api/health`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000);
    
    try {
      const response = await fetch(healthUrl, { 
        method: 'GET', 
        signal: controller.signal 
      });
      clearTimeout(timeoutId);
      return response.ok;
    } catch (e) {
      clearTimeout(timeoutId);
      // Try root endpoint as fallback
      const rootUrl = `${apiEndpoint}/`;
      const rootResponse = await fetch(rootUrl, { 
        method: 'GET', 
        signal: AbortSignal.timeout(2000) 
      });
      return rootResponse.ok;
    }
  } catch (e) {
    return false;
  }
}

// Send content to API
async function processContent(action, content) {
  const apiEndpoint = await loadSettings();
  const url = `${apiEndpoint}/api/browser/process`;

  showStatus(`Processing ${action}...`, 'loading');

  try {
    // Check if API is reachable first
    const isReachable = await checkApiConnection(apiEndpoint);
    if (!isReachable) {
      throw new Error(`Cannot connect to API at ${apiEndpoint}. Make sure the FastAPI server is running. Start it with: cd ~/code/dotfiles/web/backend && python3 -m uvicorn main:app --host 127.0.0.1 --port 8000`);
    }

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        action,
        content: {
          url: content.url,
          title: content.title,
          text: content.text.substring(0, 10000), // Limit text size
          description: content.description,
          author: content.author,
        }
      })
    });

    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}`;
      
      if (response.status === 404) {
        errorMessage = `Endpoint not found. Make sure the API server is running and includes the /api/browser/process endpoint.`;
      } else if (response.status === 500) {
        errorMessage = `Server error. Check the API server logs for details.`;
      } else {
        try {
          const errorData = await response.json();
          errorMessage = errorData.detail || errorData.message || errorMessage;
        } catch (e) {
          errorMessage = `${response.statusText} (${response.status})`;
        }
      }
      
      throw new Error(errorMessage);
    }

    const result = await response.json();
    showStatus('Success!', 'success');
    return result;
  } catch (error) {
    let errorMessage = error.message;
    
    // Handle network errors
    if (error.name === 'TypeError' && error.message.includes('fetch')) {
      errorMessage = `Network error: Cannot connect to ${apiEndpoint}. Make sure the FastAPI server is running on port 8000.`;
    } else if (error.name === 'AbortError') {
      errorMessage = `Connection timeout. The API server may not be responding.`;
    }
    
    showStatus(`Error: ${errorMessage}`, 'error');
    throw new Error(errorMessage);
  }
}

// Initialize popup
async function init() {
  // Load settings
  await loadSettings();

  // Extract and display page info
  try {
    const content = await extractContent();
    document.getElementById('pageTitle').textContent = content.title || 'Untitled';
    document.getElementById('pageUrl').textContent = content.url;
    
    const textLength = content.text.length;
    const wordCount = content.text.split(/\s+/).filter(w => w.length > 0).length;
    document.getElementById('contentStats').textContent = 
      `${textLength.toLocaleString()} characters, ${wordCount.toLocaleString()} words`;
  } catch (error) {
    showStatus(`Error loading page: ${error.message}`, 'error');
  }

  // Set up action buttons
  document.getElementById('summarizeBtn').addEventListener('click', async () => {
    try {
      const content = await extractContent();
      const result = await processContent('summarize', content);
      showResults('Summary', result.summary || result.result || JSON.stringify(result, null, 2));
    } catch (error) {
      console.error('Summarize error:', error);
    }
  });

  document.getElementById('suggestTasksBtn').addEventListener('click', async () => {
    try {
      const content = await extractContent();
      const result = await processContent('suggest_tasks', content);
      showResults('Task Suggestions', result.suggestions || result.result || JSON.stringify(result, null, 2));
    } catch (error) {
      console.error('Suggest tasks error:', error);
    }
  });

  document.getElementById('createTaskBtn').addEventListener('click', async () => {
    try {
      const content = await extractContent();
      const result = await processContent('create_task', content);
      showResults('Task Created', result.message || result.result || JSON.stringify(result, null, 2));
    } catch (error) {
      console.error('Create task error:', error);
    }
  });

  document.getElementById('analyzeBtn').addEventListener('click', async () => {
    try {
      const content = await extractContent();
      const result = await processContent('analyze', content);
      
      // Handle error responses
      if (result.success === false) {
        showStatus(result.error || 'Analysis failed', 'error');
        showResults('Analysis Error', result.error || JSON.stringify(result, null, 2));
      } else if (result.status === 'queued') {
        // Analysis was queued for background processing
        showStatus('✅ Analysis queued! Processing in background...', 'success');
        const message = result.message || 'Analysis has been queued for background processing.';
        const note = result.note || 'Check your deep analysis results directory when complete.';
        showResults('Analysis Queued', `${message}\n\n${note}\n\nQueue Status: ${result.queue_status || 'unknown'}`);
      } else {
        // Immediate result (shouldn't happen for analyze, but handle it)
        showResults('Analysis', result.analysis || result.result || JSON.stringify(result, null, 2));
      }
    } catch (error) {
      console.error('Analyze error:', error);
      showStatus(`Error: ${error.message}`, 'error');
    }
  });

  // Settings
  document.getElementById('saveSettingsBtn').addEventListener('click', saveSettings);
  
  // Connection test
  document.getElementById('testConnectionBtn').addEventListener('click', async () => {
    const statusEl = document.getElementById('connectionStatus');
    const apiEndpoint = await loadSettings();
    
    statusEl.textContent = 'Testing connection...';
    statusEl.className = '';
    
    try {
      const isReachable = await checkApiConnection(apiEndpoint);
      if (isReachable) {
        statusEl.textContent = `✅ Connected to ${apiEndpoint}`;
        statusEl.className = 'success';
      } else {
        statusEl.innerHTML = `❌ Cannot connect to ${apiEndpoint}<br><small>Make sure the API server is running:<br><code>cd ~/code/dotfiles/web/backend && python3 -m uvicorn main:app --host 127.0.0.1 --port 8000</code></small>`;
        statusEl.className = 'error';
      }
    } catch (error) {
      statusEl.innerHTML = `❌ Connection failed: ${error.message}<br><small>Check your API endpoint in settings</small>`;
      statusEl.className = 'error';
    }
  });
  
  // Show connection test in settings
  document.querySelector('.settings details').addEventListener('toggle', (e) => {
    if (e.target.open) {
      document.getElementById('connectionTest').style.display = 'block';
    }
  });
}

// Run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
