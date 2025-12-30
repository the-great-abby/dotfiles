<script>
  export let status
</script>

<footer class="status-bar">
  <div class="status-items">
    <span class="status-item">
      <span class="status-icon">📥</span>
      <span class="status-value">{status.inbox_count}</span>
      <span class="status-label">Inbox</span>
    </span>
    <span class="status-item">
      <span class="status-icon">✅</span>
      <span class="status-value">{status.active_tasks}</span>
      <span class="status-label">Tasks</span>
    </span>
    <span class="status-item">
      <span class="status-icon">📁</span>
      <span class="status-value">{status.active_projects}</span>
      <span class="status-label">Projects</span>
    </span>
    <span class="status-item">
      <span class="status-icon">✓</span>
      <span class="status-value">{status.completed_today}</span>
      <span class="status-label">Today</span>
    </span>
    {#if status.advice_results_pending !== undefined && status.advice_results_pending > 0}
      <span class="status-item status-item-highlight">
        <span class="status-icon">📋</span>
        <span class="status-value">{status.advice_results_pending}</span>
        <span class="status-label">Advice</span>
      </span>
    {/if}
  </div>
</footer>

<style>
  .status-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: white;
    border-top: 1px solid #e9ecef;
    padding: 0.75rem 2rem;
    box-shadow: 0 -2px 4px rgba(0,0,0,0.05);
  }

  .status-items {
    display: flex;
    justify-content: center;
    gap: 2rem;
    max-width: 1200px;
    margin: 0 auto;
  }

  .status-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #666;
    font-size: 0.9rem;
  }

  .status-icon {
    font-size: 1.2rem;
  }

  .status-value {
    font-weight: 600;
    color: #333;
  }

  .status-label {
    color: #999;
  }

  .status-item-highlight {
    color: #667eea;
  }

  .status-item-highlight .status-value {
    color: #667eea;
    font-weight: 700;
  }
</style>





