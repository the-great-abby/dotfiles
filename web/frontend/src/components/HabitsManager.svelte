<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let habits = []
  let loading = true
  let error = null
  let completingHabit = null

  const loadHabits = async () => {
    try {
      loading = true
      error = null
      const result = await api.getHabits()
      habits = result.habits || []
      loading = false
    } catch (err) {
      console.error('Failed to load habits:', err)
      error = err.message || 'Failed to load habits'
      loading = false
    }
  }

  const completeHabit = async (habitName, event) => {
    if (!event || !event.target || !event.target.checked) {
      return
    }

    if (completingHabit === habitName) return

    try {
      completingHabit = habitName
      await api.completeHabit(habitName)
      await loadHabits()
    } catch (err) {
      console.error('Failed to complete habit:', err)
      alert(`Error: ${err.message || 'Failed to complete habit'}`)
      // Uncheck on error
      if (event && event.target) {
        event.target.checked = false
      }
    } finally {
      completingHabit = null
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'Never'
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString()
    } catch {
      return dateString
    }
  }

  onMount(() => {
    loadHabits()
  })
</script>

<div class="habits-manager">
  <div class="header">
    <h2>🔄 Manage Habits & Recurring Tasks</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  <div class="actions">
    <button on:click={loadHabits} class="btn-refresh">🔄 Refresh</button>
  </div>

  {#if loading}
    <div class="loading">Loading habits...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadHabits} class="btn-retry">Retry</button>
    </div>
  {:else if habits.length === 0}
    <div class="empty">
      <p>No habits found.</p>
      <p>Create habits using the CLI: <code>gtd-habit add "Habit Name"</code></p>
    </div>
  {:else}
    <div class="habits-list">
      {#each habits as habit (habit.slug)}
        <div class="habit-item" class:due-today={habit.due_today}>
          <div class="habit-header">
            <label class="habit-checkbox">
              <input
                type="checkbox"
                checked={!habit.due_today}
                on:change={(e) => completeHabit(habit.name, e)}
                disabled={completingHabit === habit.name || habit.status !== 'active'}
              />
              <span class="habit-name">{habit.name}</span>
            </label>
            {#if habit.due_today}
              <span class="due-badge">Due Today</span>
            {/if}
            {#if habit.status !== 'active'}
              <span class="status-badge status-{habit.status}">{habit.status}</span>
            {/if}
          </div>
          
          {#if habit.description}
            <div class="habit-description">{habit.description}</div>
          {/if}
          
          <div class="habit-meta">
            <span class="meta-item">
              <strong>Frequency:</strong> {habit.frequency}
            </span>
            {#if habit.time_of_day}
              <span class="meta-item">
                <strong>Time:</strong> {habit.time_of_day}
              </span>
            {/if}
            <span class="meta-item">
              <strong>Last completed:</strong> {formatDate(habit.last_completed)}
            </span>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .habits-manager {
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

  .habits-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .habit-item {
    padding: 1.5rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    transition: all 0.2s;
  }

  .habit-item.due-today {
    border-color: #ffc107;
    background: #fffbf0;
  }

  .habit-header {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 0.75rem;
  }

  .habit-checkbox {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    cursor: pointer;
    flex: 1;
  }

  .habit-checkbox input[type="checkbox"] {
    width: 1.5rem;
    height: 1.5rem;
    cursor: pointer;
  }

  .habit-name {
    font-size: 1.125rem;
    font-weight: 600;
    color: #333;
  }

  .due-badge {
    padding: 0.25rem 0.5rem;
    background: #ffc107;
    color: #333;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
  }

  .status-badge {
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 500;
  }

  .status-inactive {
    background: #e9ecef;
    color: #6c757d;
  }

  .habit-description {
    color: #666;
    margin-bottom: 0.75rem;
    font-size: 0.875rem;
  }

  .habit-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    font-size: 0.875rem;
    color: #999;
  }

  .meta-item strong {
    color: #666;
  }

  .empty code {
    background: #f8f9fa;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-family: monospace;
    font-size: 0.875rem;
  }
</style>
