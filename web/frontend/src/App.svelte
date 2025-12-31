<script>
  import { onMount, onDestroy } from 'svelte'
  import Dashboard from './components/Dashboard.svelte'
  import Menu from './components/Menu.svelte'
  import CaptureWizard from './components/CaptureWizard.svelte'
  import TaskList from './components/TaskList.svelte'
  import InboxProcessor from './components/InboxProcessor.svelte'
  import ProjectsList from './components/ProjectsList.svelte'
  import AdviceReview from './components/AdviceReview.svelte'
  import DailyReview from './components/DailyReview.svelte'
  import StatusBar from './components/StatusBar.svelte'
  import { api } from './services/api.js'

  let currentView = 'dashboard'
  let status = {
    inbox_count: 0,
    active_tasks: 0,
    active_projects: 0,
    completed_today: 0,
    status: 'ok'
  }
  let showSettings = false
  let ws = null

  const loadStatus = async () => {
    try {
      status = await api.getStatus()
    } catch (error) {
      console.error('Failed to load status:', error)
    }
  }

  const refreshStatus = () => {
    loadStatus()
  }

  const handleNavigate = (event) => {
    // In Svelte, event handlers receive the event detail directly
    // But handle both cases: direct value or event object
    const view = (typeof event === 'object' && event.detail !== undefined) ? event.detail : event
    if (view && typeof view === 'string') {
      currentView = view
    } else {
      console.error('Invalid view value:', view)
      currentView = 'dashboard'
    }
  }

  const handleMenuSelect = (event) => {
    // In Svelte, event handlers receive the event detail directly
    // But handle both cases: direct value or event object
    const route = (typeof event === 'object' && event.detail !== undefined) ? event.detail : event
    if (route && typeof route === 'string') {
      // Remove leading slash and normalize route
      // For routes like /learn/org, use the full path as view name
      let view = route.replace(/^\//, '') || 'menu'
      // Replace slashes with dashes for view names (e.g., learn/org -> learn-org)
      view = view.replace(/\//g, '-')
      console.log('Navigating to view:', view, 'from route:', route)
      currentView = view
    } else {
      console.error('Invalid route value:', route, 'event:', event)
      currentView = 'menu'
    }
  }

  const handleItemCaptured = () => {
    loadStatus()
  }

  const handleItemProcessed = () => {
    loadStatus()
  }

  const connectWebSocket = () => {
    // Use the same origin for WebSocket (works with nginx proxy in production)
    // In development, vite proxy handles /ws -> ws://localhost:8000
    // In production, nginx proxy handles /ws -> ws://localhost:8000
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const wsUrl = `${protocol}//${window.location.host}/ws`
    
    ws = new WebSocket(wsUrl)
    
    ws.onopen = () => {
      console.log('WebSocket connected')
    }
    
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.type === 'status_update' && data.data) {
          status = data.data
        }
      } catch (error) {
        console.error('Error parsing WebSocket message:', error)
      }
    }
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error)
    }
    
    ws.onclose = () => {
      console.log('WebSocket disconnected, reconnecting...')
      setTimeout(connectWebSocket, 3000)
    }
  }

  onMount(() => {
    loadStatus()
    connectWebSocket()
  })

  onDestroy(() => {
    if (ws) {
      ws.close()
    }
  })
</script>

<div id="app">
  <header class="app-header">
    <h1>🧙 GTD Wizard</h1>
    <div class="header-actions">
      <button on:click={refreshStatus} class="icon-btn" title="Refresh">🔄</button>
      <button on:click={() => showSettings = !showSettings} class="icon-btn" title="Settings">⚙️</button>
    </div>
  </header>

  <main class="app-main">
    {#if currentView === 'dashboard'}
      <Dashboard {status} on:navigate={handleNavigate} />
    {:else if currentView === 'menu'}
      <Menu on:select={handleMenuSelect} on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'capture'}
      <CaptureWizard on:close={() => currentView = 'menu'} on:captured={handleItemCaptured} />
    {:else if currentView === 'tasks'}
      <TaskList on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'inbox'}
      <InboxProcessor on:close={() => currentView = 'dashboard'} on:processed={handleItemProcessed} />
    {:else if currentView === 'projects'}
      <ProjectsList on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'advice-review'}
      <AdviceReview on:close={() => currentView = 'dashboard'} />
    {:else if currentView === 'review-morning'}
      <DailyReview reviewType="morning" on:close={() => currentView = 'dashboard'} on:saved={refreshStatus} />
    {:else if currentView === 'review-evening'}
      <DailyReview reviewType="evening" on:close={() => currentView = 'dashboard'} on:saved={refreshStatus} />
    {:else}
      <div class="coming-soon">
        <h2>Coming Soon</h2>
        <p>The "{currentView}" feature is not yet implemented.</p>
        <button on:click={() => currentView = 'dashboard'} class="btn-back">← Back to Dashboard</button>
      </div>
    {/if}
  </main>

  <StatusBar {status} />
</div>

<style>
  .app-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1rem 2rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  .app-header h1 {
    font-size: 1.5rem;
    font-weight: 600;
  }

  .header-actions {
    display: flex;
    gap: 0.5rem;
  }

  .icon-btn {
    background: rgba(255,255,255,0.2);
    border: none;
    color: white;
    padding: 0.5rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1.2rem;
    transition: background 0.2s;
  }

  .icon-btn:hover {
    background: rgba(255,255,255,0.3);
  }

  .app-main {
    max-width: 1200px;
    margin: 2rem auto;
    padding: 0 1rem;
    min-height: calc(100vh - 200px);
  }

  .coming-soon {
    background: white;
    border-radius: 8px;
    padding: 3rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    text-align: center;
  }

  .coming-soon h2 {
    font-size: 2rem;
    color: #333;
    margin-bottom: 1rem;
  }

  .coming-soon p {
    color: #666;
    font-size: 1.1rem;
    margin-bottom: 2rem;
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
</style>




