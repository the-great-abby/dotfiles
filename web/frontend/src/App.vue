<template>
  <div id="app">
    <header class="app-header">
      <h1>🧙 GTD Wizard</h1>
      <div class="header-actions">
        <button @click="refreshStatus" class="icon-btn" title="Refresh">🔄</button>
        <button @click="showSettings = !showSettings" class="icon-btn" title="Settings">⚙️</button>
      </div>
    </header>

    <main class="app-main">
      <Dashboard 
        v-if="currentView === 'dashboard'" 
        :status="status" 
        @navigate="handleNavigate"
      />
      <Menu 
        v-else-if="currentView === 'menu'" 
        @select="handleMenuSelect" 
      />
      <CaptureWizard 
        v-else-if="currentView === 'capture'" 
        @close="currentView = 'menu'"
        @captured="handleItemCaptured"
      />
      <TaskList 
        v-else-if="currentView === 'tasks'" 
        @close="currentView = 'menu'"
      />
      <InboxProcessor 
        v-else-if="currentView === 'inbox'" 
        @close="currentView = 'menu'"
        @processed="handleItemProcessed"
      />
    </main>

    <StatusBar :status="status" />
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted } from 'vue'
import Dashboard from './components/Dashboard.vue'
import Menu from './components/Menu.vue'
import CaptureWizard from './components/CaptureWizard.vue'
import TaskList from './components/TaskList.vue'
import InboxProcessor from './components/InboxProcessor.vue'
import StatusBar from './components/StatusBar.vue'
import { api } from './services/api'

export default {
  name: 'App',
  components: {
    Dashboard,
    Menu,
    CaptureWizard,
    TaskList,
    InboxProcessor,
    StatusBar
  },
  setup() {
    const currentView = ref('dashboard')
    const status = ref({
      inbox_count: 0,
      active_tasks: 0,
      active_projects: 0,
      completed_today: 0,
      status: 'ok'
    })
    const showSettings = ref(false)
    let ws = null

    const loadStatus = async () => {
      try {
        status.value = await api.getStatus()
      } catch (error) {
        console.error('Failed to load status:', error)
      }
    }

    const refreshStatus = () => {
      loadStatus()
    }

    const handleNavigate = (view) => {
      currentView.value = view
    }

    const handleMenuSelect = (route) => {
      const view = route.replace('/', '') || 'menu'
      currentView.value = view
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
            status.value = data.data
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

    onMounted(() => {
      loadStatus()
      connectWebSocket()
    })

    onUnmounted(() => {
      if (ws) {
        ws.close()
      }
    })

    return {
      currentView,
      status,
      showSettings,
      refreshStatus,
      handleNavigate,
      handleMenuSelect,
      handleItemCaptured,
      handleItemProcessed
    }
  }
}
</script>

<style scoped>
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
</style>




