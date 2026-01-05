<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let personas = []
  let selectedPersona = 'hank'
  let question = ''
  let mode = 'normal'
  let webSearch = false
  let loading = false
  let loadingPersonas = true
  let error = null
  let result = null

  const modes = [
    { value: 'normal', label: 'Normal (with GTD context)' },
    { value: 'random', label: 'Random persona' },
    { value: 'simple', label: 'Simple (no GTD context)' },
    { value: 'all', label: 'All personas' }
  ]

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
      error = err.message || 'Failed to load personas'
      loadingPersonas = false
    }
  }

  const submitRequest = async () => {
    if (!question.trim()) {
      error = 'Please enter a question'
      return
    }

    if (mode === 'normal' && !selectedPersona) {
      error = 'Please select a persona'
      return
    }

    loading = true
    error = null
    result = null

    try {
      const response = await api.requestAdvice({
        persona: selectedPersona,
        question: question.trim(),
        mode: mode,
        web_search: webSearch,
        background: true  // Always process in background
      })

      result = {
        type: 'queued',
        request_id: response.request_id,
        message: response.message
      }
    } catch (err) {
      console.error('Failed to request advice:', err)
      error = err.message || 'Failed to request advice'
    } finally {
      loading = false
    }
  }

  const reset = () => {
    question = ''
    result = null
    error = null
  }

  onMount(() => {
    loadPersonas()
  })
</script>

<div class="advice-wizard">
  <div class="header">
    <h2>🤖 Get Advice from Personas</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  {#if result}
    <div class="result-view">
      <div class="result-header">
        <button on:click={reset} class="back-btn">← Ask Another Question</button>
      </div>

      <div class="result-success">
        <h3>✓ Request Queued</h3>
        <p>{result.message}</p>
        <p class="result-id">Request ID: {result.request_id}</p>
        <p class="result-hint">You'll receive a notification when the advice is ready. Check "Review Advice Results" to see it.</p>
      </div>
    </div>
  {:else}
    <div class="form-view">
      {#if loadingPersonas}
        <div class="loading">Loading personas...</div>
      {:else if error && !loading}
        <div class="error">
          <p>Error: {error}</p>
          <button on:click={() => error = null} class="btn-dismiss">Dismiss</button>
        </div>
      {/if}

      <form on:submit|preventDefault={submitRequest}>
        <div class="form-group">
          <label for="mode">Mode:</label>
          <select id="mode" bind:value={mode}>
            {#each modes as m}
              <option value={m.value}>{m.label}</option>
            {/each}
          </select>
        </div>

        {#if mode !== 'random' && mode !== 'all'}
          <div class="form-group">
            <label for="persona">Persona:</label>
            <select id="persona" bind:value={selectedPersona} disabled={loadingPersonas}>
              {#each personas as persona}
                <option value={persona}>{persona}</option>
              {/each}
            </select>
          </div>
        {/if}

        {#if mode === 'simple'}
          <div class="form-group">
            <label class="checkbox-label">
              <input type="checkbox" bind:checked={webSearch} />
              <span>Enable web search</span>
            </label>
          </div>
        {/if}

        <div class="form-group">
          <label for="question">Question:</label>
          <textarea
            id="question"
            bind:value={question}
            placeholder="What do you need advice about?"
            rows="5"
            disabled={loading}
          ></textarea>
          <p class="form-hint">Your request will be queued for background processing. You'll receive a notification when the advice is ready.</p>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-submit" disabled={loading || !question.trim()}>
            {loading ? 'Processing...' : 'Get Advice'}
          </button>
          <button type="button" class="btn-cancel" on:click={() => dispatch('close')} disabled={loading}>
            Cancel
          </button>
        </div>
      </form>
    </div>
  {/if}
</div>

<style>
  .advice-wizard {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
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

  .form-view {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .form-group label {
    font-weight: 500;
    color: #333;
  }

  .form-group select,
  .form-group textarea {
    padding: 0.75rem;
    border: 2px solid #e9ecef;
    border-radius: 4px;
    font-size: 1rem;
    font-family: inherit;
  }

  .form-group select:focus,
  .form-group textarea:focus {
    outline: none;
    border-color: #667eea;
  }

  .form-group textarea {
    resize: vertical;
    min-height: 100px;
  }

  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
  }

  .checkbox-label input[type="checkbox"] {
    width: 1.2rem;
    height: 1.2rem;
    cursor: pointer;
  }

  .form-hint {
    font-size: 0.875rem;
    color: #666;
    margin-top: 0.25rem;
  }

  .form-actions {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
  }

  .btn-submit {
    padding: 0.75rem 1.5rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-submit:hover:not(:disabled) {
    background: #5568d3;
  }

  .btn-submit:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .btn-cancel {
    padding: 0.75rem 1.5rem;
    background: #6c757d;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-cancel:hover:not(:disabled) {
    background: #5a6268;
  }

  .loading, .error {
    padding: 1rem;
    border-radius: 4px;
  }

  .loading {
    text-align: center;
    color: #666;
  }

  .error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
  }

  .btn-dismiss {
    margin-top: 0.5rem;
    padding: 0.5rem 1rem;
    background: #dc3545;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .result-view {
    margin-top: 1rem;
  }

  .result-header {
    margin-bottom: 1.5rem;
  }

  .back-btn {
    padding: 0.5rem 1rem;
    background: #6c757d;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .back-btn:hover {
    background: #5a6268;
  }

  .result-success {
    padding: 1.5rem;
    background: #d4edda;
    border: 1px solid #c3e6cb;
    border-radius: 6px;
    color: #155724;
  }

  .result-success h3 {
    margin-top: 0;
    margin-bottom: 1rem;
  }

  .result-id {
    font-family: monospace;
    font-size: 0.875rem;
    margin: 0.5rem 0;
  }

  .result-hint {
    font-size: 0.875rem;
    margin-top: 1rem;
    opacity: 0.8;
  }
</style>
