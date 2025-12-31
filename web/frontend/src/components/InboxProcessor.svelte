<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let inboxItems = []
  let currentIndex = 0
  let loading = true
  let processing = false
  let selectedType = 'task'
  let description = ''
  let error = null

  const processTypes = [
    { value: 'task', label: 'Task (actionable)' },
    { value: 'project', label: 'Project (multi-step)' },
    { value: 'reference', label: 'Reference (information)' },
    { value: 'idea', label: 'Someday/Maybe (future)' }
  ]

  const loadInbox = async () => {
    try {
      loading = true
      error = null
      const result = await api.getInbox()
      inboxItems = result.items || []
      if (inboxItems.length > 0) {
        description = inboxItems[0].description
      }
      loading = false
    } catch (err) {
      console.error('Failed to load inbox:', err)
      error = err.message || 'Failed to load inbox'
      loading = false
    }
  }

  const processCurrent = async () => {
    if (processing || !description.trim()) return

    processing = true
    try {
      await api.processInboxItem(inboxItems[currentIndex].id, {
        type: selectedType,
        description: description.trim()
      })
      
      // Reload inbox to get updated list (file was deleted)
      await loadInbox()
      
      // Stay at current index (which now points to the next item)
      // If we were at the last item, currentIndex will be at the new last item
      if (currentIndex >= inboxItems.length && inboxItems.length > 0) {
        currentIndex = inboxItems.length - 1
      }
      if (inboxItems.length > 0) {
        description = inboxItems[currentIndex].description || ''
      } else {
        description = ''
      }
      dispatch('processed')
    } catch (error) {
      console.error('Failed to process item:', error)
      alert('Failed to process item. Please try again.')
    } finally {
      processing = false
    }
  }

  const skip = () => {
    if (currentIndex < inboxItems.length - 1) {
      currentIndex++
      description = inboxItems[currentIndex].description || ''
    }
  }

  const deleteItem = async () => {
    if (inboxItems.length === 0 || processing) return
    
    if (!confirm('Are you sure you want to delete this inbox item?')) {
      return
    }
    
    processing = true
    try {
      await api.deleteInboxItem(inboxItems[currentIndex].id)
      
      // Remove from local list
      inboxItems = inboxItems.filter((_, i) => i !== currentIndex)
      if (currentIndex >= inboxItems.length) {
        currentIndex = Math.max(0, inboxItems.length - 1)
      }
      if (inboxItems.length > 0) {
        description = inboxItems[currentIndex].description
      } else {
        // Reload inbox if empty
        await loadInbox()
      }
      dispatch('processed')
    } catch (error) {
      console.error('Failed to delete item:', error)
      alert('Failed to delete item. Please try again.')
    } finally {
      processing = false
    }
  }

  onMount(() => {
    loadInbox()
  })

  $: currentItem = inboxItems[currentIndex]
  $: progress = inboxItems.length > 0 ? ((currentIndex + 1) / inboxItems.length) * 100 : 0
</script>

<div class="inbox-processor">
  <div class="header">
    <h2>📋 Process Inbox Items</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  {#if loading}
    <div class="loading">Loading inbox...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadInbox} class="btn-retry">Retry</button>
    </div>
  {:else if inboxItems.length === 0}
    <div class="empty">Inbox is empty! 🎉</div>
  {:else}
    <div class="processor-content">
      <div class="progress-info">
        <span>Item {currentIndex + 1} of {inboxItems.length}</span>
        <div class="progress-bar">
          <div class="progress-fill" style="width: {progress}%"></div>
        </div>
      </div>

      <div class="item-card">
        <h3>What is this?</h3>
        <div class="options">
          {#each processTypes as type}
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

        <div class="description-section">
          <label for="inbox-description">Description</label>
          <textarea
            id="inbox-description"
            bind:value={description}
            rows="3"
            class="description-input"
          ></textarea>
        </div>

        <div class="actions">
          <button on:click={skip} class="btn-secondary">Skip</button>
          <button on:click={deleteItem} class="btn-danger">Delete</button>
          <button
            on:click={processCurrent}
            class="btn-primary"
            disabled={processing || !description.trim()}
          >
            {processing ? 'Processing...' : 'Process →'}
          </button>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .inbox-processor {
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

  .loading, .empty, .error {
    text-align: center;
    padding: 2rem;
    color: #666;
  }

  .error {
    color: #c33;
  }

  .btn-retry {
    margin-top: 1rem;
    padding: 0.5rem 1rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .btn-retry:hover {
    background: #5568d3;
  }

  .progress-info {
    margin-bottom: 2rem;
  }

  .progress-info span {
    display: block;
    margin-bottom: 0.5rem;
    color: #666;
    font-size: 0.9rem;
  }

  .progress-bar {
    width: 100%;
    height: 8px;
    background: #e9ecef;
    border-radius: 4px;
    overflow: hidden;
  }

  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
    transition: width 0.3s;
  }

  .item-card {
    border: 2px solid #e9ecef;
    border-radius: 8px;
    padding: 1.5rem;
  }

  .item-card h3 {
    margin-bottom: 1rem;
    color: #333;
  }

  .options {
    display: grid;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
  }

  .option {
    display: flex;
    align-items: center;
    padding: 0.75rem;
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

  .description-section {
    margin-bottom: 1.5rem;
  }

  .description-section label {
    display: block;
    margin-bottom: 0.5rem;
    color: #555;
    font-weight: 500;
  }

  .description-input {
    width: 100%;
    padding: 0.75rem;
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

  .actions {
    display: flex;
    justify-content: flex-end;
    gap: 1rem;
  }

  .btn-primary, .btn-secondary, .btn-danger {
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

  .btn-danger {
    background: #fee;
    color: #c33;
  }

  .btn-danger:hover {
    background: #fdd;
  }
</style>




