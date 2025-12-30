<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let tasks = []
  let loading = true
  let error = null
  let completingTaskId = null

  const loadTasks = async () => {
    try {
      loading = true
      error = null
      const result = await api.getTasks()
      tasks = result.tasks || []
      loading = false
    } catch (err) {
      console.error('Failed to load tasks:', err)
      error = err.message || 'Failed to load tasks'
      loading = false
    }
  }

  const completeTask = async (taskId, event) => {
    // Only complete if checkbox is checked
    if (!event || !event.target || !event.target.checked) {
      return
    }
    
    // Prevent double-completion
    if (completingTaskId === taskId) {
      return
    }
    
    // Don't complete if already done
    const task = tasks.find(t => t.id === taskId)
    if (task && (task.status === 'done' || task.status === 'completed')) {
      event.target.checked = false
      return
    }
    
    try {
      completingTaskId = taskId
      console.log('Completing task with ID:', taskId)
      await api.completeTask(taskId)
      await loadTasks()
      // Refresh status to update completed count
      if (typeof window !== 'undefined' && window.dispatchEvent) {
        window.dispatchEvent(new CustomEvent('refresh-status'))
      }
    } catch (err) {
      console.error('Failed to complete task:', err)
      // Uncheck the checkbox on error
      if (event && event.target) {
        event.target.checked = false
      }
      const errorMessage = err.message || 'Failed to complete task. Please try again.'
      alert(`Error: ${errorMessage}\n\nTask ID: ${taskId}\n\nMake sure the task ID is correct.`)
    } finally {
      completingTaskId = null
    }
  }

  onMount(() => {
    loadTasks()
  })
</script>

<div class="task-list">
  <div class="header">
    <h2>✅ Manage Tasks</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  {#if loading}
    <div class="loading">Loading tasks...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadTasks} class="btn-retry">Retry</button>
    </div>
  {:else if tasks.length === 0}
    <div class="empty">No tasks found</div>
  {:else}
    <div class="tasks">
      {#each tasks as task (task.id)}
        <div class="task-item">
          <input
            type="checkbox"
            checked={task.status === 'done' || task.status === 'completed'}
            on:change={(e) => completeTask(task.id, e)}
            class="task-checkbox"
            disabled={task.status === 'done' || task.status === 'completed' || completingTaskId === task.id}
          />
          <div class="task-content">
            <div class="task-description">{task.description}</div>
            <div class="task-details">
              {#if task.context || task.energy || task.priority}
                <div class="task-metadata">
                  {#if task.context}
                    <span class="detail-item">Context: {task.context}</span>
                  {/if}
                  {#if task.energy}
                    <span class="detail-item">Energy: {task.energy}</span>
                  {/if}
                  {#if task.priority}
                    <span class="detail-item">Priority: {task.priority}</span>
                  {/if}
                </div>
              {/if}
              {#if task.project}
                <div class="task-project">Project: {task.project}</div>
              {/if}
              {#if task.area}
                <div class="task-area">Area: {task.area}</div>
              {/if}
              {#if task.repository}
                <div class="task-repository">Repository: {task.repository}</div>
              {/if}
            </div>
            <div class="task-meta">
              <span class="priority priority-{task.priority}">{task.priority}</span>
              <span class="status">{task.status}</span>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .task-list {
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

  .tasks {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .task-item {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    padding: 1rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    transition: all 0.2s;
  }

  .task-item:hover {
    border-color: #667eea;
    background: #f8f9fa;
  }

  .task-checkbox {
    margin-top: 0.25rem;
    width: 1.25rem;
    height: 1.25rem;
    cursor: pointer;
  }

  .task-content {
    flex: 1;
  }

  .task-description {
    font-size: 1rem;
    color: #333;
    margin-bottom: 0.75rem;
    font-weight: 500;
  }

  .task-details {
    margin-bottom: 0.75rem;
    font-size: 0.875rem;
    color: #666;
  }

  .task-metadata {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-bottom: 0.5rem;
  }

  .detail-item {
    color: #666;
  }

  .task-project,
  .task-area,
  .task-repository {
    margin-bottom: 0.25rem;
    color: #555;
  }

  .task-project {
    font-weight: 500;
    color: #667eea;
  }

  .task-meta {
    display: flex;
    gap: 0.5rem;
    font-size: 0.875rem;
    margin-top: 0.5rem;
  }

  .priority {
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-weight: 500;
  }

  .priority-high {
    background: #fee;
    color: #c33;
  }

  .priority-medium {
    background: #ffe;
    color: #993;
  }

  .priority-low {
    background: #efe;
    color: #393;
  }

  .status {
    color: #666;
  }
</style>




