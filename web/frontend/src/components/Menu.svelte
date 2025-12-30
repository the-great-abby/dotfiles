<script>
  import { onMount } from 'svelte'
  import { api } from '../services/api.js'
  import { createEventDispatcher } from 'svelte'

  const dispatch = createEventDispatcher()

  let menu = { sections: [] }
  let loading = true
  let error = null

  // List of implemented routes
  const implementedRoutes = ['/capture', '/inbox', '/tasks', '/projects', '/dashboard', '/menu']

  const isImplemented = (route) => {
    return implementedRoutes.includes(route)
  }

  const loadMenu = async () => {
    try {
      loading = true
      error = null
      menu = await api.getMenu()
      loading = false
    } catch (err) {
      console.error('Failed to load menu:', err)
      error = err.message || 'Failed to load menu'
      loading = false
    }
  }

  const selectItem = (item) => {
    console.log('Menu item selected:', item.route)
    dispatch('select', item.route)
  }

  const goBack = () => {
    dispatch('close')
  }

  onMount(() => {
    loadMenu()
  })
</script>

<div class="menu-container">
  <div class="menu-header">
    <h2>🧙 GTD Wizard Menu</h2>
    <button on:click={goBack} class="btn-back">← Back to Dashboard</button>
  </div>

  {#if loading}
    <div class="loading">Loading menu...</div>
  {:else if error}
    <div class="error">
      <p>Error: {error}</p>
      <button on:click={loadMenu} class="btn-retry">Retry</button>
    </div>
  {:else}
    {#each menu.sections as section}
      <div class="menu-section">
        <h2 class="section-title">{section.title}</h2>
        <div class="menu-items">
          {#each section.items as item}
            <button
              class="menu-item"
              class:coming-soon={!isImplemented(item.route)}
              on:click={() => selectItem(item)}
              title={isImplemented(item.route) ? '' : 'Coming soon'}
            >
              {item.title}
              {#if !isImplemented(item.route)}
                <span class="badge">Soon</span>
              {/if}
            </button>
          {/each}
        </div>
      </div>
    {/each}
  {/if}
</div>

<style>
  .menu-container {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }

  .menu-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 2px solid #e9ecef;
  }

  .menu-header h2 {
    font-size: 1.5rem;
    color: #333;
    margin: 0;
  }

  .btn-back {
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-back:hover {
    background: #5568d3;
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

  .btn-retry:hover {
    background: #5568d3;
  }

  .menu-section {
    margin-bottom: 2rem;
  }

  .menu-section:last-child {
    margin-bottom: 0;
  }

  .section-title {
    font-size: 1.2rem;
    font-weight: 600;
    margin: 0 0 1rem 0;
    color: #333;
  }

  .menu-items {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1rem;
  }

  .menu-item {
    background: #f8f9fa;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    padding: 1rem 1.5rem;
    text-align: left;
    cursor: pointer;
    transition: all 0.2s;
    font-size: 1rem;
    font-family: inherit;
    display: flex;
    justify-content: space-between;
    align-items: center;
    position: relative;
  }

  .menu-item:hover:not(.coming-soon) {
    background: #e9ecef;
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(102, 126, 234, 0.2);
  }

  .menu-item.coming-soon {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .menu-item.coming-soon:hover {
    border-color: #e9ecef;
    transform: none;
    box-shadow: none;
  }

  .badge {
    background: #ffc107;
    color: #333;
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-weight: 600;
    margin-left: 0.5rem;
  }
</style>




