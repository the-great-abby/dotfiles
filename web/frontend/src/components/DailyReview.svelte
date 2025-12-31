<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  export let reviewType = 'morning' // morning or evening

  let loading = true
  let saving = false
  let error = null
  let reviewData = null
  
  // Form fields
  let priority1 = ''
  let priority2 = ''
  let priority3 = ''
  let accomplishments = ''
  let blockers = ''
  let attentionItems = ''
  let whatWentWell = ''
  let morningFeeling = ''  // How am I feeling (energy, mood, readiness)
  let todayGoals = ''  // What do I need to accomplish today
  let gratitude = ''  // What am I grateful for
  let logWeather = false  // Whether to log weather
  let completedHabits = []  // Habits that were completed

  const loadReviewData = async () => {
    try {
      loading = true
      error = null
      reviewData = await api.getDailyReviewData(reviewType)
      
      // If there's an existing review, we could load it here
      // For now, we'll just show the form
      loading = false
    } catch (err) {
      console.error('Failed to load review data:', err)
      error = err.message || 'Failed to load review data'
      loading = false
    }
  }

  const submitReview = async () => {
    if (saving) return

    saving = true
    try {
      await api.submitDailyReview({
        type: reviewType,
        priority1: priority1.trim(),
        priority2: priority2.trim(),
        priority3: priority3.trim(),
        accomplishments: accomplishments.trim(),
        blockers: blockers.trim(),
        attention_items: attentionItems.trim(),
        what_went_well: whatWentWell.trim(),
        morning_feeling: morningFeeling.trim(),
        today_goals: todayGoals.trim(),
        gratitude: gratitude.trim(),
        log_weather: logWeather
      })
      
      // Complete habits if any were selected
      if (completedHabits.length > 0) {
        for (const habitName of completedHabits) {
          try {
            await api.completeHabit(habitName)
          } catch (err) {
            console.error(`Failed to complete habit ${habitName}:`, err)
          }
        }
      }
      
      dispatch('saved')
      alert(`${reviewType === 'morning' ? 'Morning' : 'Evening'} review saved successfully!`)
    } catch (err) {
      console.error('Failed to save review:', err)
      alert(`Failed to save review: ${err.message || 'Unknown error'}`)
    } finally {
      saving = false
    }
  }

  onMount(() => {
    loadReviewData()
  })

  $: timeLabel = reviewType === 'morning' ? 'Morning' : 'Evening'
  $: timeIcon = reviewType === 'morning' ? '🌅' : '🌙'
  $: dayOfWeek = reviewData ? new Date(reviewData.date).toLocaleDateString('en-US', { weekday: 'long' }) : ''
</script>

<div class="daily-review">
  <div class="header">
    <h2>{timeIcon} {timeLabel} Check-In{#if reviewData && reviewData.date} - {reviewData.date}{#if dayOfWeek} ({dayOfWeek}){/if}{/if}</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  {#if loading}
    <div class="loading">Loading review data...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadReviewData} class="btn-retry">Retry</button>
    </div>
  {:else if reviewData}
    <div class="review-content">
      <!-- Quick Status -->
      <div class="quick-status-section">
        <h3>📊 Quick Status</h3>
        <div class="stats-section">
          <div class="stat">
            <span class="stat-label">📥 Inbox:</span>
            <span class="stat-value">{reviewData.inbox_count} item(s)</span>
          </div>
          <div class="stat">
            <span class="stat-label">✅ Active Tasks:</span>
            <span class="stat-value">{reviewData.active_tasks}</span>
          </div>
          {#if reviewData.active_projects !== undefined}
            <div class="stat">
              <span class="stat-label">📁 Active Projects:</span>
              <span class="stat-value">{reviewData.active_projects}</span>
            </div>
          {/if}
        </div>
      </div>

      <!-- Habits Due Today (morning only) -->
      {#if reviewType === 'morning' && reviewData.habits_due && reviewData.habits_due.length > 0}
        <div class="habits-section">
          <h3>🔁 Habits Due Today</h3>
          <div class="habits-list">
            {#each reviewData.habits_due as habit}
              <label class="habit-item">
                <input
                  type="checkbox"
                  checked={completedHabits.includes(habit)}
                  on:change={(e) => {
                    if (e.target.checked) {
                      completedHabits = [...completedHabits, habit]
                    } else {
                      completedHabits = completedHabits.filter(h => h !== habit)
                    }
                  }}
                />
                <span>{habit}</span>
              </label>
            {/each}
          </div>
        </div>
      {/if}

      <!-- AI Suggestions -->
      {#if reviewData.ai_suggestions}
        <div class="ai-suggestions-section">
          <h3>🤖 AI Suggestions (Based on Recent Logs)</h3>
          <div class="ai-suggestions-content">{reviewData.ai_suggestions}</div>
        </div>
      {:else if reviewType === 'morning'}
        <div class="ai-suggestions-section">
          <h3>🤖 AI Suggestions (Based on Recent Logs)</h3>
          <div class="ai-suggestions-empty">(No suggestions available - try logging more entries)</div>
        </div>
      {/if}

      <!-- Calendar Info -->
      {#if reviewData.calendar_info}
        <div class="calendar-section">
          <h3>📅 {reviewType === 'morning' ? "Today's" : "Tomorrow's"} Calendar</h3>
          <pre class="calendar-info">{reviewData.calendar_info}</pre>
        </div>
      {/if}

      <!-- Review Form -->
      <div class="review-form">
        {#if reviewType === 'morning'}
          <!-- Morning Review Questions (matching CLI check-in) -->
          <div class="form-section">
            <h3>1. How am I feeling this morning? (energy, mood, readiness)</h3>
            <textarea
              bind:value={morningFeeling}
              placeholder="e.g., energy - 5, mood - 5, readiness - 5"
              rows="2"
              class="review-textarea"
            ></textarea>
          </div>

          <div class="form-section">
            <h3>2. What are my top 3 priorities for today?</h3>
            <div class="priorities">
              <input
                type="text"
                bind:value={priority1}
                placeholder="Priority 1"
                class="priority-input"
              />
              <input
                type="text"
                bind:value={priority2}
                placeholder="Priority 2"
                class="priority-input"
              />
              <input
                type="text"
                bind:value={priority3}
                placeholder="Priority 3"
                class="priority-input"
              />
            </div>
          </div>

          <div class="form-section">
            <h3>3. What do I need to accomplish today?</h3>
            <textarea
              bind:value={todayGoals}
              placeholder="What do you need to accomplish today?"
              rows="3"
              class="review-textarea"
            ></textarea>
          </div>

          <div class="form-section">
            <h3>4. What might get in my way today? (blockers, distractions)</h3>
            <textarea
              bind:value={blockers}
              placeholder="What obstacles or blockers are you facing?"
              rows="3"
              class="review-textarea"
            ></textarea>
          </div>

          <div class="form-section">
            <h3>5. What am I grateful for today?</h3>
            <textarea
              bind:value={gratitude}
              placeholder="What are you grateful for today?"
              rows="2"
              class="review-textarea"
            ></textarea>
          </div>

          <!-- Weather Logging Option -->
          <div class="form-section">
            <h3>🌤️ Weather Conditions</h3>
            <p class="form-hint">💡 Tip: Logging weather helps identify patterns with energy levels, mood, and productivity.</p>
            <label class="checkbox-label">
              <input
                type="checkbox"
                bind:checked={logWeather}
              />
              <span>Log current weather</span>
            </label>
          </div>
        {:else}
          <!-- Evening Review Questions -->
          <div class="form-section">
            <h3>1. What did I accomplish today?</h3>
            <textarea
              bind:value={accomplishments}
              placeholder="List what you accomplished today..."
              rows="4"
              class="review-textarea"
            ></textarea>
          </div>

          <div class="form-section">
            <h3>2. What went well today?</h3>
            <textarea
              bind:value={whatWentWell}
              placeholder="What went well or what are you grateful for?"
              rows="3"
              class="review-textarea"
            ></textarea>
          </div>

          <div class="form-section">
            <h3>3. What's blocking me?</h3>
            <textarea
              bind:value={blockers}
              placeholder="What obstacles or blockers are you facing?"
              rows="3"
              class="review-textarea"
            ></textarea>
          </div>

          <div class="form-section">
            <h3>4. What are my top 3 priorities for tomorrow?</h3>
            <div class="priorities">
              <input
                type="text"
                bind:value={priority1}
                placeholder="Priority 1"
                class="priority-input"
              />
              <input
                type="text"
                bind:value={priority2}
                placeholder="Priority 2"
                class="priority-input"
              />
              <input
                type="text"
                bind:value={priority3}
                placeholder="Priority 3"
                class="priority-input"
              />
            </div>
          </div>

          <div class="form-section">
            <h3>5. What needs my attention?</h3>
            <textarea
              bind:value={attentionItems}
              placeholder="What items need your attention?"
              rows="3"
              class="review-textarea"
            ></textarea>
          </div>
        {/if}

        <div class="form-actions">
          <button
            on:click={submitReview}
            class="btn-primary"
            disabled={saving}
          >
            {saving ? 'Saving...' : 'Save Review'}
          </button>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .daily-review {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    max-width: 800px;
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

  .loading, .error {
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

  .quick-status-section {
    margin-bottom: 2rem;
  }

  .quick-status-section h3 {
    font-size: 1.1rem;
    color: #333;
    margin-bottom: 0.75rem;
  }

  .stats-section {
    display: flex;
    gap: 2rem;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 6px;
  }

  .stat {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .stat-label {
    font-size: 0.9rem;
    color: #666;
  }

  .stat-value {
    font-size: 1.2rem;
    font-weight: 600;
    color: #333;
  }

  .calendar-section {
    margin-bottom: 2rem;
    padding: 1rem;
    background: #f0f4ff;
    border-radius: 6px;
    border-left: 4px solid #667eea;
  }

  .calendar-section h3 {
    margin-bottom: 0.5rem;
    color: #333;
    font-size: 1.1rem;
  }

  .calendar-info {
    font-family: 'Monaco', 'Menlo', monospace;
    font-size: 0.85rem;
    color: #555;
    white-space: pre-wrap;
    margin: 0;
  }

  .review-form {
    margin-top: 2rem;
  }

  .form-section {
    margin-bottom: 2rem;
  }

  .form-section h3 {
    font-size: 1.1rem;
    color: #333;
    margin-bottom: 0.75rem;
  }

  .priorities {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .priority-input {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    font-family: inherit;
  }

  .priority-input:focus {
    outline: none;
    border-color: #667eea;
  }

  .review-textarea {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    font-family: inherit;
    resize: vertical;
  }

  .review-textarea:focus {
    outline: none;
    border-color: #667eea;
  }

  .form-actions {
    display: flex;
    justify-content: flex-end;
    margin-top: 2rem;
    padding-top: 2rem;
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

  .habits-section {
    margin-bottom: 2rem;
    padding: 1rem;
    background: #fff9e6;
    border-radius: 6px;
    border-left: 4px solid #ffc107;
  }

  .habits-section h3 {
    margin-bottom: 1rem;
    color: #333;
    font-size: 1.1rem;
  }

  .habits-list {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .habit-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem;
    cursor: pointer;
  }

  .habit-item input[type="checkbox"] {
    width: 1.2rem;
    height: 1.2rem;
    cursor: pointer;
  }

  .ai-suggestions-section {
    margin-bottom: 2rem;
    padding: 1rem;
    background: #f0f4ff;
    border-radius: 6px;
    border-left: 4px solid #667eea;
  }

  .ai-suggestions-section h3 {
    margin-bottom: 0.75rem;
    color: #333;
    font-size: 1.1rem;
  }

  .ai-suggestions-content {
    color: #555;
    white-space: pre-wrap;
    line-height: 1.6;
  }

  .ai-suggestions-empty {
    color: #999;
    font-style: italic;
  }

  .form-hint {
    font-size: 0.9rem;
    color: #666;
    margin-bottom: 0.5rem;
  }

  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    padding: 0.5rem;
  }

  .checkbox-label input[type="checkbox"] {
    width: 1.2rem;
    height: 1.2rem;
    cursor: pointer;
  }
</style>
