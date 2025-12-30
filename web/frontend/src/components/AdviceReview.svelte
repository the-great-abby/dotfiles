<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let results = []
  let loading = true
  let error = null
  let selectedResult = null
  let showOnlyUnreviewed = true
  let markingReviewed = null
  let deletingResult = null

  const loadResults = async () => {
    try {
      loading = true
      error = null
      const result = await api.getAdviceResults(showOnlyUnreviewed ? null : null)
      results = result.results || []
      loading = false
    } catch (err) {
      console.error('Failed to load advice results:', err)
      error = err.message || 'Failed to load advice results'
      loading = false
    }
  }

  const viewResult = async (resultId) => {
    try {
      const result = await api.getAdviceResult(resultId)
      selectedResult = result
    } catch (err) {
      console.error('Failed to load advice result:', err)
      alert(`Error: ${err.message || 'Failed to load advice result'}`)
    }
  }

  const markReviewed = async (resultId, event) => {
    event.stopPropagation()
    if (markingReviewed === resultId) return
    
    try {
      markingReviewed = resultId
      await api.markAdviceReviewed(resultId)
      await loadResults()
      if (selectedResult && selectedResult.id === resultId) {
        selectedResult.reviewed = true
        selectedResult.reviewed_at = new Date().toISOString()
      }
    } catch (err) {
      console.error('Failed to mark as reviewed:', err)
      alert(`Error: ${err.message || 'Failed to mark as reviewed'}`)
    } finally {
      markingReviewed = null
    }
  }

  const deleteResult = async (resultId, event) => {
    event.stopPropagation()
    if (!confirm('Are you sure you want to archive this advice result?')) {
      return
    }
    
    if (deletingResult === resultId) return
    
    try {
      deletingResult = resultId
      await api.deleteAdviceResult(resultId)
      if (selectedResult && selectedResult.id === resultId) {
        selectedResult = null
      }
      await loadResults()
    } catch (err) {
      console.error('Failed to delete advice result:', err)
      alert(`Error: ${err.message || 'Failed to archive advice result'}`)
    } finally {
      deletingResult = null
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'Unknown'
    try {
      const date = new Date(dateString)
      return date.toLocaleString()
    } catch {
      return dateString
    }
  }

  const formatDuration = (seconds) => {
    if (!seconds) return 'N/A'
    if (seconds < 60) return `${seconds}s`
    const minutes = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${minutes}m ${secs}s`
  }

  onMount(() => {
    loadResults()
  })
</script>

<div class="advice-review">
  <div class="header">
    <h2>📋 Review Advice Results</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  {#if selectedResult}
    <div class="result-detail">
      <div class="detail-header">
        <button on:click={() => selectedResult = null} class="back-btn">← Back to List</button>
        <div class="detail-actions">
          {#if !selectedResult.reviewed}
            <button 
              on:click={(e) => markReviewed(selectedResult.id, e)}
              class="btn-mark-reviewed"
              disabled={markingReviewed === selectedResult.id}
            >
              {markingReviewed === selectedResult.id ? 'Marking...' : '✓ Mark as Reviewed'}
            </button>
          {/if}
          <button 
            on:click={(e) => deleteResult(selectedResult.id, e)}
            class="btn-delete"
            disabled={deletingResult === selectedResult.id}
          >
            {deletingResult === selectedResult.id ? 'Archiving...' : '🗑️ Archive'}
          </button>
        </div>
      </div>

      <div class="detail-content">
        <div class="detail-meta">
          <div class="meta-item">
            <span class="meta-label">Persona:</span>
            <span class="meta-value">{selectedResult.persona}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Mode:</span>
            <span class="meta-value">{selectedResult.mode}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Status:</span>
            <span class="meta-value status-{selectedResult.status}">{selectedResult.status}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Created:</span>
            <span class="meta-value">{formatDate(selectedResult.created_at)}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Completed:</span>
            <span class="meta-value">{formatDate(selectedResult.completed_at)}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Duration:</span>
            <span class="meta-value">{formatDuration(selectedResult.duration_seconds)}</span>
          </div>
          {#if selectedResult.reviewed}
            <div class="meta-item">
              <span class="meta-label">Reviewed:</span>
              <span class="meta-value">{formatDate(selectedResult.reviewed_at)}</span>
            </div>
          {/if}
        </div>

        <div class="detail-question">
          <h3>Question:</h3>
          <p>{selectedResult.question}</p>
        </div>

        {#if selectedResult.status === 'error'}
          <div class="detail-error">
            <h3>Error:</h3>
            <p>{selectedResult.error || 'Unknown error occurred'}</p>
          </div>
        {:else}
          <div class="detail-answer">
            <h3>Answer:</h3>
            <div class="answer-content">{selectedResult.answer || 'No answer available'}</div>
          </div>
        {/if}
      </div>
    </div>
  {:else}
    <div class="filters">
      <label class="filter-toggle">
        <input 
          type="checkbox" 
          bind:checked={showOnlyUnreviewed}
          on:change={loadResults}
        />
        <span>Show only unreviewed</span>
      </label>
      <button on:click={loadResults} class="btn-refresh">🔄 Refresh</button>
    </div>

    {#if loading}
      <div class="loading">Loading advice results...</div>
    {:else if error}
      <div class="error">
        <p>Error: {error}</p>
        <button on:click={loadResults} class="btn-retry">Retry</button>
      </div>
    {:else if results.length === 0}
      <div class="empty">
        {#if showOnlyUnreviewed}
          <p>No unreviewed advice results found.</p>
          <p>All advice results have been reviewed!</p>
        {:else}
          <p>No advice results found.</p>
        {/if}
      </div>
    {:else}
      <div class="results-list">
        {#each results as result (result.id)}
          <div 
            class="result-item {result.reviewed ? 'reviewed' : ''}"
            on:click={() => viewResult(result.id)}
            role="button"
            tabindex="0"
            on:keydown={(e) => e.key === 'Enter' && viewResult(result.id)}
          >
            <div class="result-header">
              <div class="result-persona">{result.persona}</div>
              <div class="result-status status-{result.status}">{result.status}</div>
              {#if result.reviewed}
                <div class="result-reviewed-badge">✓ Reviewed</div>
              {/if}
            </div>
            <div class="result-question">{result.question}</div>
            <div class="result-preview">{result.preview || result.answer?.substring(0, 200) + '...' || 'No preview available'}</div>
            <div class="result-footer">
              <span class="result-date">{formatDate(result.completed_at)}</span>
              <span class="result-duration">{formatDuration(result.duration_seconds)}</span>
              <div class="result-actions" on:click|stopPropagation>
                {#if !result.reviewed}
                  <button 
                    on:click={(e) => markReviewed(result.id, e)}
                    class="btn-mark-small"
                    disabled={markingReviewed === result.id}
                    title="Mark as reviewed"
                  >
                    ✓
                  </button>
                {/if}
                <button 
                  on:click={(e) => deleteResult(result.id, e)}
                  class="btn-delete-small"
                  disabled={deletingResult === result.id}
                  title="Archive"
                >
                  🗑️
                </button>
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  {/if}
</div>

<style>
  .advice-review {
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

  .filters {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #e9ecef;
  }

  .filter-toggle {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
  }

  .btn-refresh {
    padding: 0.5rem 1rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.875rem;
  }

  .btn-refresh:hover {
    background: #5568d3;
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

  .results-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .result-item {
    padding: 1.5rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
  }

  .result-item:hover {
    border-color: #667eea;
    background: #f8f9fa;
  }

  .result-item.reviewed {
    opacity: 0.7;
    background: #f8f9fa;
  }

  .result-header {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 0.75rem;
  }

  .result-persona {
    font-weight: 600;
    color: #667eea;
    font-size: 1rem;
  }

  .result-status {
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 500;
  }

  .status-completed {
    background: #d4edda;
    color: #155724;
  }

  .status-error {
    background: #f8d7da;
    color: #721c24;
  }

  .result-reviewed-badge {
    margin-left: auto;
    padding: 0.25rem 0.5rem;
    background: #d1ecf1;
    color: #0c5460;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 500;
  }

  .result-question {
    font-size: 1rem;
    color: #333;
    margin-bottom: 0.5rem;
    font-weight: 500;
  }

  .result-preview {
    font-size: 0.875rem;
    color: #666;
    margin-bottom: 0.75rem;
    line-height: 1.5;
  }

  .result-footer {
    display: flex;
    align-items: center;
    gap: 1rem;
    font-size: 0.75rem;
    color: #999;
  }

  .result-actions {
    margin-left: auto;
    display: flex;
    gap: 0.5rem;
  }

  .btn-mark-small,
  .btn-delete-small {
    padding: 0.25rem 0.5rem;
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.875rem;
  }

  .btn-mark-small:hover {
    background: #d4edda;
    border-color: #c3e6cb;
  }

  .btn-delete-small:hover {
    background: #f8d7da;
    border-color: #f5c6cb;
  }

  .result-detail {
    margin-top: 1rem;
  }

  .detail-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 2px solid #e9ecef;
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

  .detail-actions {
    display: flex;
    gap: 0.5rem;
  }

  .btn-mark-reviewed {
    padding: 0.5rem 1rem;
    background: #28a745;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .btn-mark-reviewed:hover:not(:disabled) {
    background: #218838;
  }

  .btn-mark-reviewed:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .btn-delete {
    padding: 0.5rem 1rem;
    background: #dc3545;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .btn-delete:hover:not(:disabled) {
    background: #c82333;
  }

  .btn-delete:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .detail-content {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .detail-meta {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 6px;
  }

  .meta-item {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .meta-label {
    font-size: 0.75rem;
    color: #666;
    font-weight: 500;
  }

  .meta-value {
    font-size: 0.875rem;
    color: #333;
  }

  .detail-question,
  .detail-answer,
  .detail-error {
    padding: 1.5rem;
    background: #f8f9fa;
    border-radius: 6px;
  }

  .detail-question h3,
  .detail-answer h3,
  .detail-error h3 {
    margin-top: 0;
    margin-bottom: 1rem;
    color: #333;
    font-size: 1.125rem;
  }

  .detail-question p {
    color: #333;
    line-height: 1.6;
    margin: 0;
  }

  .answer-content {
    color: #333;
    line-height: 1.8;
    white-space: pre-wrap;
    word-wrap: break-word;
  }

  .detail-error {
    background: #f8d7da;
    border: 1px solid #f5c6cb;
  }

  .detail-error h3 {
    color: #721c24;
  }

  .detail-error p {
    color: #721c24;
    margin: 0;
  }
</style>

