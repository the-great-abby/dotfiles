<script>
  import { onMount, onDestroy } from 'svelte'
  import Dashboard from './components/Dashboard.svelte'
  import Menu from './components/Menu.svelte'
  import CaptureWizard from './components/CaptureWizard.svelte'
  import TaskList from './components/TaskList.svelte'
  import InboxProcessor from './components/InboxProcessor.svelte'
  import ProjectsList from './components/ProjectsList.svelte'
  import AdviceReview from './components/AdviceReview.svelte'
  import AdviceWizard from './components/AdviceWizard.svelte'
  import HabitsManager from './components/HabitsManager.svelte'
  import AISuggestions from './components/AISuggestions.svelte'
  import DailyReview from './components/DailyReview.svelte'
  import DailyLogEntry from './components/DailyLogEntry.svelte'
  import CheckInSelector from './components/CheckInSelector.svelte'
  import StatusBar from './components/StatusBar.svelte'
  import { api } from './services/api.js'
  import { notificationService } from './services/notifications.js'

  let currentView = 'dashboard'
  let status = {
    inbox_count: 0,
    active_tasks: 0,
    active_projects: 0,
    completed_today: 0,
    status: 'ok'
  }
  let showSettings = false
  let ws = null
  let lastAdviceCount = 0
  let adviceCheckInterval = null
  let notificationPermissionStatus = 'default'
  let toastMessage = null
  let toastTimeout = null
  
  const showToast = (message, duration = 5000) => {
    toastMessage = message
    if (toastTimeout) {
      clearTimeout(toastTimeout)
    }
    toastTimeout = setTimeout(() => {
      toastMessage = null
    }, duration)
  }

  const requestNotificationPermission = async () => {
    try {
      const granted = await notificationService.requestPermission()
      // Update permission status
      notificationPermissionStatus = notificationService.getPermissionStatus()
      if (granted) {
        console.log('✅ Notification permission granted!')
        showToast('✅ Notifications enabled! You will now receive alerts when your advice is ready.')
      } else {
        console.log('Notification permission not granted')
        if (notificationPermissionStatus === 'denied') {
          showToast('Notification permission was denied. Please enable it in your browser settings.')
        }
      }
    } catch (error) {
      console.error('Error requesting notification permission:', error)
      notificationPermissionStatus = notificationService.getPermissionStatus()
    }
  }

  const loadStatus = async () => {
    try {
      const newStatus = await api.getStatus()
      
      // Check if new advice results are available
      if (newStatus.advice_results_pending > lastAdviceCount && lastAdviceCount > 0) {
        // New advice results available - show notification
        const newCount = newStatus.advice_results_pending - lastAdviceCount
        notificationService.notify(
          '🤖 New Advice Ready',
          {
            body: `You have ${newCount} new advice result${newCount > 1 ? 's' : ''} ready to review`,
            tag: 'advice-ready',
            data: { type: 'advice-ready', count: newCount }
          }
        )
      }
      
      lastAdviceCount = newStatus.advice_results_pending || 0
      status = newStatus
    } catch (error) {
      console.error('Failed to load status:', error)
    }
  }

  const refreshStatus = () => {
    loadStatus()
  }

  const handleNavigate = (event) => {
    // In Svelte, event handlers receive the event detail directly
    // But handle both cases: direct value or event object
    const view = (typeof event === 'object' && event.detail !== undefined) ? event.detail : event
    if (view && typeof view === 'string') {
      currentView = view
    } else {
      console.error('Invalid view value:', view)
      currentView = 'dashboard'
    }
  }

  const handleMenuSelect = (event) => {
    // In Svelte, event handlers receive the event detail directly
    // But handle both cases: direct value or event object
    const route = (typeof event === 'object' && event.detail !== undefined) ? event.detail : event
    if (route && typeof route === 'string') {
      // Remove leading slash and normalize route
      // For routes like /learn/org, use the full path as view name
      let view = route.replace(/^\//, '') || 'menu'
      // Replace slashes with dashes for view names (e.g., learn/org -> learn-org)
      view = view.replace(/\//g, '-')
      console.log('Navigating to view:', view, 'from route:', route)
      currentView = view
    } else {
      console.error('Invalid route value:', route, 'event:', event)
      currentView = 'menu'
    }
  }

  const handleItemCaptured = () => {
    loadStatus()
  }

  const handleItemProcessed = () => {
    loadStatus()
  }

  const connectWebSocket = () => {
    // Use the same origin for WebSocket (works with nginx proxy in production)
    // In development, vite proxy handles /ws -> ws://localhost:8000
    // In production, nginx proxy handles /ws -> ws://localhost:8000
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const wsUrl = `${protocol}//${window.location.host}/ws`
    
    ws = new WebSocket(wsUrl)
    
    ws.onopen = () => {
      console.log('WebSocket connected')
    }
    
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        console.log('WebSocket message received:', data.type, data)
        
        if (data.type === 'status_update' && data.data) {
          status = data.data
        } else if (data.type === 'advice_ready') {
          // Show notification when advice is ready
          console.log('Advice ready notification received:', data)
          
          // Always show in-app toast notification (works even if browser notifications fail)
          const personaName = data.persona || 'Persona'
          showToast(`🤖 Advice from ${personaName} is ready! Click to review.`, 10000)
          
          // Also try browser notification
          notificationService.notifyAdviceReady(
            personaName,
            data.question || ''
          ).then(notification => {
            if (notification) {
              console.log('✅ Browser notification shown for advice:', data.request_id)
              
              // Check if page is in focus - if so, browser might not show notification
              if (document.hasFocus()) {
                console.log('⚠️  Page is in focus - browser notification might not appear. In-app toast shown instead.')
              }
            } else {
              console.warn('⚠️  Browser notification not shown (permission denied or error)')
              console.log('✅ In-app toast notification shown instead')
            }
          }).catch(error => {
            console.error('Error showing notification:', error)
            console.log('✅ In-app toast notification shown instead')
          })
        } else if (data.type === 'new_suggestion') {
          // Show notification for new AI suggestions
          notificationService.notifyNewSuggestion(
            data.title || 'New suggestion available'
          )
        }
      } catch (error) {
        console.error('Error parsing WebSocket message:', error, event.data)
      }
    }
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error)
    }
    
    ws.onclose = () => {
      console.log('WebSocket disconnected, reconnecting...')
      setTimeout(connectWebSocket, 3000)
    }
  }

  onMount(() => {
    loadStatus()
    connectWebSocket()
    
    // Check notification permission status (don't request automatically)
    // Some browsers require a user gesture to request permission
    notificationPermissionStatus = notificationService.getPermissionStatus()
    if (notificationPermissionStatus === 'default') {
      console.log('Notification permission not yet requested. Click "Enable Notifications" button to enable.')
    } else if (notificationPermissionStatus === 'denied') {
      console.warn('Notification permission was denied. User must enable it in browser settings.')
    } else if (notificationPermissionStatus === 'granted') {
      console.log('✅ Notification permission is granted')
    }
    
    // Check for new advice results every 30 seconds
    adviceCheckInterval = setInterval(() => {
      loadStatus()
    }, 30000)
  })

  onDestroy(() => {
    if (ws) {
      ws.close()
    }
    if (adviceCheckInterval) {
      clearInterval(adviceCheckInterval)
    }
  })
</script>

<div id="app">
  <header class="app-header">
    <h1>🧙 GTD Wizard</h1>
    <div class="header-actions">
      <button on:click={refreshStatus} class="icon-btn" title="Refresh">🔄</button>
      <button on:click={() => showSettings = !showSettings} class="icon-btn" title="Settings">⚙️</button>
    </div>
  </header>

  <main class="app-main">
    {#if currentView === 'dashboard'}
      <Dashboard {status} on:navigate={handleNavigate} />
    {:else if currentView === 'menu'}
      <Menu on:select={handleMenuSelect} on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'capture'}
      <CaptureWizard on:close={() => currentView = 'menu'} on:captured={handleItemCaptured} />
    {:else if currentView === 'tasks'}
      <TaskList on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'inbox'}
      <InboxProcessor on:close={() => currentView = 'dashboard'} on:processed={handleItemProcessed} />
    {:else if currentView === 'projects'}
      <ProjectsList on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'advice-review'}
      <AdviceReview on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'advice'}
      <AdviceWizard on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'habits'}
      <HabitsManager on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'ai-suggestions'}
      <AISuggestions on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'review-morning'}
      <DailyReview reviewType="morning" on:close={() => currentView = 'dashboard'} on:saved={refreshStatus} />
    {:else if currentView === 'review-evening'}
      <DailyReview reviewType="evening" on:close={() => currentView = 'dashboard'} on:saved={refreshStatus} />
    {:else if currentView === 'log'}
      <DailyLogEntry 
        on:close={() => currentView = 'dashboard'} 
        on:saved={refreshStatus}
        on:navigate={handleNavigate}
      />
    {:else if currentView === 'checkin'}
      <CheckInSelector on:close={() => currentView = 'dashboard'} on:saved={refreshStatus} />
    {:else}
      <div class="coming-soon">
        <h2>Coming Soon</h2>
        <p>The "{currentView}" feature is not yet implemented.</p>
        <button on:click={() => currentView = 'dashboard'} class="btn-back">← Back to Dashboard</button>
      </div>
    {/if}
  </main>

  <StatusBar {status} />

  {#if showSettings}
    <div class="settings-overlay" on:click={() => showSettings = false}>
      <div class="settings-panel" on:click|stopPropagation>
        <div class="settings-header">
          <h2>Settings</h2>
          <button on:click={() => showSettings = false} class="close-btn">×</button>
        </div>
        <div class="settings-content">
          <div class="settings-section">
            <h3>Notifications</h3>
            <p class="settings-description">
              Enable browser notifications to be alerted when your advice is ready.
            </p>
            <div class="notification-status">
              <strong>Status:</strong> 
              {#if notificationPermissionStatus === 'granted'}
                <span class="status-granted">✅ Enabled</span>
              {:else if notificationPermissionStatus === 'denied'}
                <span class="status-denied">❌ Denied</span>
                <p class="status-help">To enable notifications, please allow them in your browser settings.</p>
              {:else}
                <span class="status-default">⏳ Not requested</span>
              {/if}
            </div>
            {#if notificationPermissionStatus !== 'granted'}
              <button 
                on:click={requestNotificationPermission} 
                class="btn-primary"
                disabled={notificationPermissionStatus === 'denied'}
              >
                {notificationPermissionStatus === 'denied' ? 'Enable in Browser Settings' : 'Enable Notifications'}
              </button>
            {/if}
          </div>
        </div>
      </div>
    </div>
  {/if}

  {#if toastMessage}
    <div class="toast" on:click={() => { 
      const message = toastMessage
      toastMessage = null
      if (toastTimeout) clearTimeout(toastTimeout)
      // Navigate to advice review if it's an advice notification
      if (message && message.includes('Advice')) {
        currentView = 'advice-review'
      }
    }}>
      <div class="toast-content">
        {toastMessage}
      </div>
    </div>
  {/if}
</div>

<style>
  .app-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1rem 2rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  .app-header h1 {
    font-size: 1.5rem;
    font-weight: 600;
  }

  .header-actions {
    display: flex;
    gap: 0.5rem;
  }

  .icon-btn {
    background: rgba(255,255,255,0.2);
    border: none;
    color: white;
    padding: 0.5rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1.2rem;
    transition: background 0.2s;
  }

  .icon-btn:hover {
    background: rgba(255,255,255,0.3);
  }

  .app-main {
    max-width: 1200px;
    margin: 2rem auto;
    padding: 0 1rem;
    min-height: calc(100vh - 200px);
  }

  .coming-soon {
    background: white;
    border-radius: 8px;
    padding: 3rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    text-align: center;
  }

  .coming-soon h2 {
    font-size: 2rem;
    color: #333;
    margin-bottom: 1rem;
  }

  .coming-soon p {
    color: #666;
    font-size: 1.1rem;
    margin-bottom: 2rem;
  }

  .btn-back {
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-back:hover {
    background: #5568d3;
  }

  /* Settings Panel */
  .settings-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .settings-panel {
    background: white;
    border-radius: 12px;
    padding: 2rem;
    max-width: 500px;
    width: 90%;
    max-height: 80vh;
    overflow-y: auto;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  }

  .settings-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #eee;
  }

  .settings-header h2 {
    margin: 0;
    font-size: 1.5rem;
    color: #333;
  }

  .settings-content {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .settings-section h3 {
    margin: 0 0 0.5rem 0;
    font-size: 1.2rem;
    color: #333;
  }

  .settings-description {
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 1rem;
  }

  .notification-status {
    margin-bottom: 1rem;
    padding: 1rem;
    background: #f5f5f5;
    border-radius: 6px;
  }

  .notification-status strong {
    display: block;
    margin-bottom: 0.5rem;
    color: #333;
  }

  .status-granted {
    color: #22c55e;
    font-weight: 600;
  }

  .status-denied {
    color: #ef4444;
    font-weight: 600;
  }

  .status-default {
    color: #f59e0b;
    font-weight: 600;
  }

  .status-help {
    margin-top: 0.5rem;
    font-size: 0.85rem;
    color: #666;
  }

  .btn-primary {
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-primary:hover:not(:disabled) {
    background: #5568d3;
  }

  .btn-primary:disabled {
    background: #ccc;
    cursor: not-allowed;
  }

  /* Toast Notification */
  .toast {
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1rem 1.5rem;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    z-index: 2000;
    cursor: pointer;
    animation: slideIn 0.3s ease-out;
    max-width: 400px;
    min-width: 300px;
  }

  @keyframes slideIn {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  .toast-content {
    font-size: 1rem;
    line-height: 1.5;
  }

  .toast:hover {
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
    transform: translateY(-2px);
    transition: all 0.2s;
  }
</style>




