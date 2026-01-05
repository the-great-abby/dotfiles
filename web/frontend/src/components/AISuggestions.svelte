<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let suggestions = []
  let loading = true
  let error = null

  const loadSuggestions = async () => {
    try {
      loading = true
      error = null
      const result = await api.getAISuggestions()
      suggestions = result.suggestions || []
      loading = false
    } catch (err) {
      console.error('Failed to load AI suggestions:', err)
      error = err.message || 'Failed to load AI suggestions'
      loading = false
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

  onMount(() => {
    loadSuggestions()
  })
</script>

<div class="ai-suggestions">
  <div class="header">
    <h2>🤖 AI Suggestions & MCP Tools</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  <div class="actions">
    <button on:click={loadSuggestions} class="btn-refresh">🔄 Refresh</button>
  </div>

  {#if loading}
    <div class="loading">Loading AI suggestions...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadSuggestions} class="btn-retry">Retry</button>
    </div>
  {:else if suggestions.length === 0}
    <div class="empty">
      <p>No AI suggestions available at this time.</p>
      <p>Suggestions are generated based on your daily logs and system activity.</p>
    </div>
  {:else}
    <div class="suggestions-list">
      {#each suggestions as suggestion (suggestion.id || suggestion.type + suggestion.date)}
        <div class="suggestion-item" class:type-morning={suggestion.type === 'morning'} class:type-evening={suggestion.type === 'evening'} class:type-general={suggestion.type === 'general'}>
          <div class="suggestion-header">
            <div class="suggestion-type">
              {#if suggestion.type === 'morning'}
                🌅 Morning Suggestions
              {:else if suggestion.type === 'evening'}
                🌙 Evening Suggestions
              {:else}
                💡 General Suggestion
              {/if}
            </div>
            {#if suggestion.date}
              <div class="suggestion-date">{formatDate(suggestion.date)}</div>
            {/if}
            {#if suggestion.confidence !== undefined}
              <div class="suggestion-confidence">
                Confidence: {Math.round(suggestion.confidence * 100)}%
              </div>
            {/if}
          </div>
          
          {#if suggestion.title}
            <div class="suggestion-title">{suggestion.title}</div>
          {/if}
          
          <div class="suggestion-content">
            {suggestion.content || 'No content available'}
          </div>
          
          {#if suggestion.created_at}
            <div class="suggestion-meta">
              Created: {formatDate(suggestion.created_at)}
            </div>
          {/if}
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .ai-suggestions {
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

  .actions {
    margin-bottom: 1.5rem;
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

  .suggestions-list {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .suggestion-item {
    padding: 1.5rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    background: #f8f9fa;
  }

  .suggestion-item.type-morning {
    border-left: 4px solid #ffc107;
    background: #fffbf0;
  }

  .suggestion-item.type-evening {
    border-left: 4px solid #764ba2;
    background: #f8f4ff;
  }

  .suggestion-item.type-general {
    border-left: 4px solid #667eea;
  }

  .suggestion-header {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
    flex-wrap: wrap;
  }

  .suggestion-type {
    font-weight: 600;
    color: #333;
    font-size: 1.125rem;
  }

  .suggestion-date,
  .suggestion-confidence {
    font-size: 0.875rem;
    color: #666;
  }

  .suggestion-confidence {
    margin-left: auto;
    padding: 0.25rem 0.5rem;
    background: #e9ecef;
    border-radius: 4px;
  }

  .suggestion-title {
    font-size: 1.125rem;
    font-weight: 600;
    color: #333;
    margin-bottom: 0.75rem;
  }

  .suggestion-content {
    color: #333;
    line-height: 1.8;
    white-space: pre-wrap;
    word-wrap: break-word;
    margin-bottom: 0.75rem;
  }

  .suggestion-meta {
    font-size: 0.75rem;
    color: #999;
    margin-top: 0.5rem;
  }
</style>
