<script>
  import { onMount } from 'svelte'
  import { createEventDispatcher } from 'svelte'
  import { api } from '../services/api.js'

  const dispatch = createEventDispatcher()

  let projects = []
  let loading = true
  let error = null

  const loadProjects = async () => {
    try {
      loading = true
      error = null
      const result = await api.getProjects()
      projects = result.projects || []
      loading = false
    } catch (err) {
      console.error('Failed to load projects:', err)
      error = err.message || 'Failed to load projects'
      loading = false
    }
  }

  onMount(() => {
    loadProjects()
  })
</script>

<div class="projects-list">
  <div class="header">
    <h2>📁 Manage Projects</h2>
    <button on:click={() => dispatch('close')} class="close-btn">×</button>
  </div>

  {#if loading}
    <div class="loading">Loading projects...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadProjects} class="btn-retry">Retry</button>
    </div>
  {:else if projects.length === 0}
    <div class="empty">No projects found</div>
  {:else}
    <div class="projects">
      {#each projects as project (project.id)}
        <div class="project-item">
          <div class="project-content">
            <div class="project-name">{project.name}</div>
            <div class="project-meta">
              <span class="status">{project.status}</span>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .projects-list {
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

  .projects {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1rem;
  }

  .project-item {
    padding: 1.5rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    transition: all 0.2s;
  }

  .project-item:hover {
    border-color: #667eea;
    background: #f8f9fa;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(102, 126, 234, 0.2);
  }

  .project-content {
    flex: 1;
  }

  .project-name {
    font-size: 1.1rem;
    font-weight: 500;
    color: #333;
    margin-bottom: 0.5rem;
  }

  .project-meta {
    display: flex;
    gap: 0.5rem;
    font-size: 0.875rem;
  }

  .status {
    color: #666;
    text-transform: capitalize;
  }
</style>

