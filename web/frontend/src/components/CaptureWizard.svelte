<script>
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let selectedType = 'task'
  let description = ''
  let loading = false
  let error = null

  const captureTypes = [
    { value: 'task', label: 'Task (actionable item)' },
    { value: 'idea', label: 'Idea (someday/maybe)' },
    { value: 'reference', label: 'Reference (information to keep)' },
    { value: 'link', label: 'Link (URL to save)' },
    { value: 'call', label: 'Call (phone call notes)' },
    { value: 'email', label: 'Email (email action)' },
    { value: 'note', label: 'General note' },
    { value: 'zettelkasten', label: 'Zettelkasten note (atomic idea)' }
  ]

  $: canCapture = selectedType && description.trim().length > 0

  const capture = async () => {
    if (!canCapture || loading) return

    loading = true
    error = null
    try {
      await api.captureItem({
        type: selectedType,
        description: description.trim()
      })
      dispatch('captured')
      dispatch('close')
      // Reset form
      selectedType = 'task'
      description = ''
    } catch (err) {
      console.error('Failed to capture:', err)
      error = err.message || 'Failed to capture item. Please try again.'
    } finally {
      loading = false
    }
  }
</script>

<div class="capture-wizard">
  <div class="wizard-header">
    <h2>📥 Capture to Inbox</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  <div class="wizard-content">
    <div class="step">
      <h3>What would you like to capture?</h3>
      <div class="options">
        {#each captureTypes as type}
          <label
            class="option"
            class:active={selectedType === type.value}
          >
            <input
              type="radio"
              value={type.value}
              bind:group={selectedType}
            />
            <span>{type.label}</span>
          </label>
        {/each}
      </div>
    </div>

    <div class="step">
      <h3>Description</h3>
      <textarea
        bind:value={description}
        placeholder="Enter description..."
        rows="4"
        class="description-input"
      ></textarea>
    </div>

    {#if error}
      <div class="error-message">{error}</div>
    {/if}

    <div class="wizard-actions">
      <button on:click={() => dispatch('close')} class="btn-secondary">Cancel</button>
      <button on:click={capture} class="btn-primary" disabled={!canCapture || loading}>
        {loading ? 'Capturing...' : 'Capture →'}
      </button>
    </div>
  </div>
</div>

<style>
  .capture-wizard {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }

  .wizard-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
  }

  .wizard-header h2 {
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

  .step {
    margin-bottom: 2rem;
  }

  .step h3 {
    margin-bottom: 1rem;
    color: #555;
  }

  .options {
    display: grid;
    gap: 0.5rem;
  }

  .option {
    display: flex;
    align-items: center;
    padding: 1rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
  }

  .option:hover {
    border-color: #667eea;
  }

  .option.active {
    border-color: #667eea;
    background: #f0f4ff;
  }

  .option input {
    margin-right: 0.5rem;
  }

  .description-input {
    width: 100%;
    padding: 1rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    font-family: inherit;
    resize: vertical;
  }

  .description-input:focus {
    outline: none;
    border-color: #667eea;
  }

  .wizard-actions {
    display: flex;
    justify-content: flex-end;
    gap: 1rem;
    margin-top: 2rem;
  }

  .btn-primary, .btn-secondary {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-primary {
    background: #667eea;
    color: white;
  }

  .btn-primary:hover:not(:disabled) {
    background: #5568d3;
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary {
    background: #e9ecef;
    color: #333;
  }

  .btn-secondary:hover {
    background: #dee2e6;
  }

  .error-message {
    background: #fee;
    color: #c33;
    padding: 1rem;
    border-radius: 6px;
    margin-bottom: 1rem;
  }
</style>




