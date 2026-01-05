<script>
  import { createEventDispatcher, onMount } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let entry = ''
  let saving = false
  let error = null
  let success = false
  let showQualityTips = true
  let showAdvicePrompt = false
  let savedEntry = '' // Store the saved entry for advice request
  let personas = []
  let loadingPersonas = false
  let selectedPersona = 'hank'
  let requestingAdvice = false
  let adviceRequestId = null
  let adviceQueued = false

  const loadPersonas = async () => {
    try {
      loadingPersonas = true
      const data = await api.getPersonas()
      personas = data.personas || []
      if (personas.length > 0 && !personas.includes(selectedPersona)) {
        selectedPersona = personas[0]
      }
      loadingPersonas = false
    } catch (err) {
      console.error('Failed to load personas:', err)
      loadingPersonas = false
    }
  }

  const submitEntry = async () => {
    if (!entry.trim() || saving) return

    saving = true
    error = null
    success = false
    showAdvicePrompt = false
    adviceQueued = false
    adviceRequestId = null

    try {
      const entryText = entry.trim()
      await api.addDailyLogEntry(entryText)
      success = true
      savedEntry = entryText
      entry = ''
      
      // Dispatch saved event
      dispatch('saved')
      
      // Show advice prompt after a brief delay
      setTimeout(() => {
        showAdvicePrompt = true
      }, 500)
    } catch (err) {
      console.error('Failed to save daily log entry:', err)
      error = err.message || 'Failed to save entry'
    } finally {
      saving = false
    }
  }

  const requestAdvice = async (adviceType) => {
    if (requestingAdvice) return

    requestingAdvice = true
    error = null
    adviceQueued = false

    try {
      let requestData = {
        question: `I just logged this: ${savedEntry}. What are your thoughts?`,
        background: true
      }

      if (adviceType === 'random') {
        requestData.persona = 'random'
        requestData.mode = 'random'
      } else if (adviceType === 'specific') {
        requestData.persona = selectedPersona
        requestData.mode = 'normal'
      } else {
        // Skip
        showAdvicePrompt = false
        requestingAdvice = false
        return
      }

      const response = await api.requestAdvice(requestData)
      adviceRequestId = response.request_id
      adviceQueued = true
      
      // Show success message with processing status
      showAdvicePrompt = false
      success = true
      
      // Refresh status to update advice count
      dispatch('saved')
      
      // Keep success message visible for a bit
      setTimeout(() => {
        success = false
        // Keep adviceQueued flag visible so user knows it's processing
        // It will be cleared when a new entry is submitted
      }, 3000)
    } catch (err) {
      console.error('Failed to request advice:', err)
      error = err.message || 'Failed to request advice'
    } finally {
      requestingAdvice = false
    }
  }

  const skipAdvice = () => {
    showAdvicePrompt = false
  }

  onMount(() => {
    // Preload personas in case user wants specific persona
    loadPersonas()
  })

  const handleKeyDown = (e) => {
    // Allow Ctrl+Enter or Cmd+Enter to submit
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault()
      submitEntry()
    }
  }
</script>

<div class="daily-log-entry">
  <div class="header">
    <h2>📝 Log to Daily Log</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  <div class="content">
    <p class="description">
      Add an entry to your daily log. This will be timestamped and saved to today's log file.
    </p>

    <!-- Quality Tips Section -->
    <div class="quality-tips-section">
      <button 
        class="quality-tips-header" 
        on:click={() => showQualityTips = !showQualityTips}
        type="button"
        aria-expanded={showQualityTips}
        aria-label="Toggle quality tips"
      >
        <h3>💡 Quality Tips - Write Better Entries</h3>
        <span class="toggle-btn" class:expanded={showQualityTips}>
          {showQualityTips ? '▼' : '▶'}
        </span>
      </button>
      
      {#if showQualityTips}
        <div class="quality-tips-content">
          <div class="tips-grid">
            <div class="tip-item">
              <strong>💡 Always include WHY, not just WHAT</strong>
              <p>Add context for decisions</p>
            </div>
            <div class="tip-item">
              <strong>💡 Follow up with outcomes</strong>
              <p>Log results, not just actions</p>
            </div>
            <div class="tip-item">
              <strong>💡 Capture learnings</strong>
              <p>Note what you discovered</p>
            </div>
            <div class="tip-item">
              <strong>💡 Be specific</strong>
              <p>'Fixed memory leak' not 'made optimizations'</p>
            </div>
          </div>

          <div class="templates-section">
            <h4>📝 Quick Structure Templates:</h4>
            <ul>
              <li><strong>Technical:</strong> [What] - [Why/Context] - [How/Solution] - [Result]</li>
              <li><strong>Task:</strong> [What] - [Context] - [Outcome/Learning] - [Next Steps]</li>
              <li><strong>Reflection:</strong> [Thought] - [Context] - [Action/Decision] - [Why]</li>
            </ul>
          </div>

          <div class="quick-wins-section">
            <h4>✅ Quick Wins - Add these to your entries:</h4>
            <ul>
              <li><strong>'Result:'</strong> for fixes - 'Fixed X - Result: [what happened]'</li>
              <li><strong>'Learning:'</strong> for discoveries - 'Discovered X - Learning: [insight]'</li>
              <li><strong>'Next:'</strong> for tasks - 'Completed X - Next: [what's next]'</li>
              <li><strong>'Why:'</strong> for decisions - 'Decided X - Why: [reasoning]'</li>
            </ul>
          </div>

          <div class="avoid-section">
            <p><strong>❌ Avoid:</strong> 'Fixed something', 'Made optimizations', 'System seems better'</p>
            <p><strong>✅ Use:</strong> Specific details with context, outcomes, and learnings</p>
          </div>
        </div>
      {/if}
    </div>

    {#if error}
      <div class="error-message">
        <p>Error: {error}</p>
      </div>
    {/if}

    {#if success && !showAdvicePrompt}
      <div class="success-message">
        <p>✓ Entry saved successfully!</p>
      </div>
    {/if}

    {#if adviceQueued && !showAdvicePrompt}
      <div class="advice-processing-status">
        <p class="processing-indicator">
          <span class="spinner">⏳</span>
          <strong>Advice request queued for processing</strong>
        </p>
        <p class="processing-details">
          Your request is being processed in the background. You'll receive a notification when the advice is ready.
        </p>
        <p class="processing-actions">
          <button 
            class="btn-link" 
            on:click={() => {
              dispatch('close')
              // Navigate to advice review - use a small delay to ensure close happens first
              setTimeout(() => {
                dispatch('navigate', 'advice-review')
              }, 100)
            }}
          >
            View Advice Results →
          </button>
        </p>
      </div>
    {/if}

    <div class="form-section">
      <label for="entry">Log Entry</label>
      <textarea
        id="entry"
        bind:value={entry}
        placeholder="What would you like to log today?"
        rows="6"
        class="entry-textarea"
        on:keydown={handleKeyDown}
        disabled={saving}
      ></textarea>
      <p class="hint">💡 Tip: Press Ctrl+Enter (or Cmd+Enter on Mac) to save quickly</p>
    </div>

    <div class="form-actions">
      <button
        on:click={submitEntry}
        class="btn-primary"
        disabled={saving || !entry.trim()}
      >
        {saving ? 'Saving...' : 'Save Entry'}
      </button>
      <button
        on:click={() => dispatch('close')}
        class="btn-secondary"
        disabled={saving}
      >
        Cancel
      </button>
    </div>
  </div>

  <!-- Advice Prompt Modal -->
  {#if showAdvicePrompt}
    <div 
      class="advice-modal-overlay" 
      role="dialog"
      aria-modal="true"
      aria-labelledby="advice-modal-title"
    >
      <button
        class="advice-modal-backdrop"
        on:click={skipAdvice}
        on:keydown={(e) => {
          if (e.key === 'Escape' || e.key === 'Enter' || e.key === ' ') {
            e.preventDefault()
            skipAdvice()
          }
        }}
        aria-label="Close advice prompt"
        type="button"
      ></button>
      <div class="advice-modal">
        <div class="advice-modal-header">
          <h3 id="advice-modal-title">🤖 Get AI Feedback on This Entry?</h3>
          <button on:click={skipAdvice} class="close-btn" aria-label="Close advice prompt">×</button>
        </div>
        
        <div class="advice-modal-content">
          <p class="advice-prompt-text">
            Would you like AI feedback on this log entry?
          </p>
          
          <div class="advice-options">
            <button
              class="advice-option"
              on:click={() => requestAdvice('random')}
              disabled={requestingAdvice}
            >
              <div class="advice-option-icon">🎲</div>
              <div class="advice-option-content">
                <strong>Random Persona</strong>
                <p>Get feedback from a randomly selected persona (background processing)</p>
              </div>
            </button>

            <button
              class="advice-option"
              on:click={() => requestAdvice('specific')}
              disabled={requestingAdvice || loadingPersonas}
            >
              <div class="advice-option-icon">👤</div>
              <div class="advice-option-content">
                <strong>Choose Specific Persona</strong>
                {#if loadingPersonas}
                  <p>Loading personas...</p>
                {:else if personas.length > 0}
                  <select
                    bind:value={selectedPersona}
                    class="persona-select"
                    on:click|stopPropagation
                  >
                    {#each personas as persona}
                      <option value={persona}>{persona}</option>
                    {/each}
                  </select>
                  <p>Get feedback from selected persona (background processing)</p>
                {:else}
                  <p>Failed to load personas</p>
                {/if}
              </div>
            </button>

            <button
              class="advice-option skip"
              on:click={skipAdvice}
              disabled={requestingAdvice}
            >
              <div class="advice-option-icon">⏭️</div>
              <div class="advice-option-content">
                <strong>Skip Feedback</strong>
                <p>Continue without getting advice</p>
              </div>
            </button>
          </div>

          {#if requestingAdvice}
            <div class="requesting-advice">
              <p>📤 Queuing advice request...</p>
            </div>
          {/if}

          <div class="advice-modal-footer">
            <p class="advice-hint">
              💡 You'll receive a notification when the advice is ready. 
              Review results in the Advice Review section.
            </p>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .daily-log-entry {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    max-width: 700px;
    margin: 0 auto;
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
  }

  .header h2 {
    font-size: 1.5rem;
    color: #333;
    margin: 0;
  }

  .close-btn {
    background: none;
    border: none;
    font-size: 2rem;
    cursor: pointer;
    color: #999;
    padding: 0;
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .close-btn:hover {
    color: #333;
  }

  .content {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .description {
    color: #666;
    font-size: 1rem;
    margin: 0;
  }

  .error-message {
    padding: 1rem;
    background: #fee;
    border: 1px solid #fcc;
    border-radius: 6px;
    color: #c33;
  }

  .error-message p {
    margin: 0;
  }

  .success-message {
    padding: 1rem;
    background: #efe;
    border: 1px solid #cfc;
    border-radius: 6px;
    color: #3c3;
  }

  .success-message p {
    margin: 0;
  }

  .form-section {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .form-section label {
    font-weight: 600;
    color: #333;
    font-size: 1rem;
  }

  .entry-textarea {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    font-family: inherit;
    resize: vertical;
    min-height: 120px;
  }

  .entry-textarea:focus {
    outline: none;
    border-color: #667eea;
  }

  .entry-textarea:disabled {
    background: #f5f5f5;
    cursor: not-allowed;
  }

  .hint {
    font-size: 0.85rem;
    color: #666;
    margin: 0;
    font-style: italic;
  }

  .form-actions {
    display: flex;
    gap: 1rem;
    justify-content: flex-end;
    padding-top: 1rem;
    border-top: 2px solid #e9ecef;
  }

  .btn-primary {
    padding: 0.75rem 2rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-primary:hover:not(:disabled) {
    background: #5568d3;
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary {
    padding: 0.75rem 2rem;
    background: #f8f9fa;
    color: #333;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secondary:hover:not(:disabled) {
    background: #e9ecef;
    border-color: #ccc;
  }

  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .quality-tips-section {
    background: #f0f4ff;
    border: 2px solid #667eea;
    border-radius: 8px;
    overflow: hidden;
    margin-bottom: 1rem;
  }

  .quality-tips-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 1.5rem;
    background: #667eea;
    color: white;
    cursor: pointer;
    user-select: none;
    border: none;
    width: 100%;
    text-align: left;
    transition: background 0.2s;
  }

  .quality-tips-header:hover {
    background: #5568d3;
  }

  .quality-tips-header h3 {
    margin: 0;
    font-size: 1.1rem;
    font-weight: 600;
    pointer-events: none;
  }

  .toggle-btn {
    background: rgba(255, 255, 255, 0.2);
    border: none;
    color: white;
    font-size: 0.9rem;
    width: 2rem;
    height: 2rem;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s;
    pointer-events: none;
    flex-shrink: 0;
  }

  .toggle-btn.expanded {
    transform: rotate(0deg);
  }

  .quality-tips-content {
    padding: 1.5rem;
    background: white;
  }

  .tips-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    margin-bottom: 1.5rem;
  }

  .tip-item {
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 6px;
    border-left: 4px solid #667eea;
  }

  .tip-item strong {
    display: block;
    color: #333;
    margin-bottom: 0.5rem;
    font-size: 0.95rem;
  }

  .tip-item p {
    margin: 0;
    color: #666;
    font-size: 0.9rem;
  }

  .templates-section,
  .quick-wins-section {
    margin-bottom: 1.5rem;
  }

  .templates-section h4,
  .quick-wins-section h4 {
    margin: 0 0 0.75rem 0;
    color: #333;
    font-size: 1rem;
  }

  .templates-section ul,
  .quick-wins-section ul {
    margin: 0;
    padding-left: 1.5rem;
    color: #555;
  }

  .templates-section li,
  .quick-wins-section li {
    margin-bottom: 0.5rem;
    line-height: 1.5;
    font-size: 0.9rem;
  }

  .templates-section strong,
  .quick-wins-section strong {
    color: #667eea;
  }

  .avoid-section {
    padding: 1rem;
    background: #fff9e6;
    border-radius: 6px;
    border-left: 4px solid #ffc107;
  }

  .avoid-section p {
    margin: 0.5rem 0;
    font-size: 0.9rem;
    line-height: 1.6;
  }

  .avoid-section p:first-child {
    margin-top: 0;
  }

  .avoid-section p:last-child {
    margin-bottom: 0;
  }

  /* Advice Processing Status */
  .advice-processing-status {
    margin-top: 1rem;
    padding: 1rem;
    background: #f0f4ff;
    border-radius: 6px;
    border-left: 4px solid #667eea;
  }

  .processing-indicator {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin: 0 0 0.5rem 0;
    color: #667eea;
    font-size: 1rem;
  }

  .spinner {
    font-size: 1.2rem;
    animation: pulse 2s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% {
      opacity: 1;
    }
    50% {
      opacity: 0.5;
    }
  }

  .processing-details {
    margin: 0.5rem 0;
    color: #666;
    font-size: 0.9rem;
    line-height: 1.5;
  }

  .processing-actions {
    margin: 0.75rem 0 0 0;
  }

  .btn-link {
    background: none;
    border: none;
    color: #667eea;
    text-decoration: underline;
    cursor: pointer;
    font-size: 0.9rem;
    padding: 0;
    font-family: inherit;
  }

  .btn-link:hover {
    color: #5568d3;
  }

  /* Advice Modal Styles */
  .advice-modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .advice-modal-backdrop {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    border: none;
    padding: 0;
    cursor: pointer;
  }

  .advice-modal {
    position: relative;
    background: white;
    border-radius: 12px;
    padding: 0;
    max-width: 600px;
    width: 90%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    z-index: 1001;
  }

  .advice-modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem;
    border-bottom: 2px solid #e9ecef;
  }

  .advice-modal-header h3 {
    margin: 0;
    font-size: 1.3rem;
    color: #333;
  }

  .advice-modal-content {
    padding: 1.5rem;
  }

  .advice-prompt-text {
    font-size: 1.1rem;
    color: #666;
    margin-bottom: 1.5rem;
    text-align: center;
  }

  .advice-options {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }

  .advice-option {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    padding: 1rem;
    background: #f8f9fa;
    border: 2px solid #e9ecef;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
  }

  .advice-option:hover:not(:disabled) {
    background: #e9ecef;
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  }

  .advice-option:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .advice-option.skip {
    background: #fff;
    border-color: #ccc;
  }

  .advice-option-icon {
    font-size: 2rem;
    flex-shrink: 0;
  }

  .advice-option-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .advice-option-content strong {
    font-size: 1.1rem;
    color: #333;
  }

  .advice-option-content p {
    margin: 0;
    font-size: 0.9rem;
    color: #666;
    line-height: 1.4;
  }

  .persona-select {
    padding: 0.5rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    background: white;
    cursor: pointer;
    margin-bottom: 0.5rem;
  }

  .persona-select:focus {
    outline: none;
    border-color: #667eea;
  }

  .requesting-advice {
    text-align: center;
    padding: 1rem;
    background: #f0f4ff;
    border-radius: 6px;
    margin-bottom: 1rem;
  }

  .requesting-advice p {
    margin: 0;
    color: #667eea;
    font-weight: 600;
  }

  .advice-modal-footer {
    padding-top: 1rem;
    border-top: 2px solid #e9ecef;
  }

  .advice-hint {
    margin: 0;
    font-size: 0.9rem;
    color: #666;
    text-align: center;
    line-height: 1.5;
  }
</style>
