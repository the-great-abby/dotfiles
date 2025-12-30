<script>
  import { createEventDispatcher } from 'svelte'
  export let status

  const dispatch = createEventDispatcher()
</script>

<div class="dashboard">
  <h2>Dashboard</h2>

  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-icon">📥</div>
      <div class="stat-content">
        <div class="stat-value">{status.inbox_count}</div>
        <div class="stat-label">Inbox Items</div>
      </div>
    </div>

    <div class="stat-card">
      <div class="stat-icon">✅</div>
      <div class="stat-content">
        <div class="stat-value">{status.active_tasks}</div>
        <div class="stat-label">Active Tasks</div>
      </div>
    </div>

    <div class="stat-card">
      <div class="stat-icon">📁</div>
      <div class="stat-content">
        <div class="stat-value">{status.active_projects}</div>
        <div class="stat-label">Active Projects</div>
      </div>
    </div>

    <div class="stat-card">
      <div class="stat-icon">✓</div>
      <div class="stat-content">
        <div class="stat-value">{status.completed_today}</div>
        <div class="stat-label">Completed Today</div>
      </div>
    </div>
    {#if status.advice_results_pending !== undefined && status.advice_results_pending > 0}
      <div class="stat-card stat-card-highlight" on:click={() => dispatch('navigate', 'advice-review')} role="button" tabindex="0" on:keydown={(e) => e.key === 'Enter' && dispatch('navigate', 'advice-review')}>
        <div class="stat-icon">📋</div>
        <div class="stat-content">
          <div class="stat-value">{status.advice_results_pending}</div>
          <div class="stat-label">Advice to Review</div>
        </div>
      </div>
    {/if}
  </div>

  <div class="quick-actions">
    <h3>Quick Actions</h3>
    <div class="actions-grid">
      <button class="action-btn" on:click={() => dispatch('navigate', 'capture')}>
        📥 Capture
      </button>
      <button class="action-btn" on:click={() => dispatch('navigate', 'inbox')}>
        📋 Process Inbox
      </button>
      <button class="action-btn" on:click={() => dispatch('navigate', 'tasks')}>
        ✅ View Tasks
      </button>
      <button class="action-btn" on:click={() => dispatch('navigate', 'menu')}>
        🧙 Full Menu
      </button>
    </div>
  </div>
</div>

<style>
  .dashboard {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }

  .dashboard h2 {
    font-size: 1.8rem;
    margin-bottom: 2rem;
    color: #333;
  }

  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .stat-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 8px;
    padding: 1.5rem;
    display: flex;
    align-items: center;
    gap: 1rem;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  .stat-icon {
    font-size: 2.5rem;
  }

  .stat-content {
    flex: 1;
  }

  .stat-value {
    font-size: 2rem;
    font-weight: 600;
    line-height: 1;
  }

  .stat-label {
    font-size: 0.9rem;
    opacity: 0.9;
    margin-top: 0.25rem;
  }

  .quick-actions {
    margin-top: 2rem;
  }

  .quick-actions h3 {
    font-size: 1.3rem;
    margin-bottom: 1rem;
    color: #333;
  }

  .actions-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
  }

  .action-btn {
    background: #f8f9fa;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    padding: 1rem 1.5rem;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .action-btn:hover {
    background: #e9ecef;
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(102, 126, 234, 0.2);
  }

  .stat-card-highlight {
    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    cursor: pointer;
    transition: transform 0.2s;
  }

  .stat-card-highlight:hover {
    transform: translateY(-4px);
    box-shadow: 0 6px 12px rgba(0,0,0,0.15);
  }
</style>




