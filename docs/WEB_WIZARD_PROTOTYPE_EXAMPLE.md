# GTD Wizard Web Interface - Prototype Example

This document shows a minimal working example of the web interface.

## Backend Example (FastAPI)

### `web/backend/main.py`

```python
#!/usr/bin/env python3
"""
GTD Wizard Web Interface - FastAPI Backend
"""
from fastapi import FastAPI, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import subprocess
import json
import os
from typing import Optional, List
import asyncio

app = FastAPI(title="GTD Wizard API")

# CORS middleware for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GTD base directory
GTD_BASE = os.path.expanduser("~/code/dotfiles")
if not os.path.exists(GTD_BASE):
    GTD_BASE = os.path.expanduser("~/code/personal/dotfiles")

# Models
class CaptureItem(BaseModel):
    type: str  # task, idea, reference, link, etc.
    description: str
    priority: Optional[str] = None
    project: Optional[str] = None

class TaskUpdate(BaseModel):
    description: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None

class SystemStatus(BaseModel):
    inbox_count: int
    active_tasks: int
    active_projects: int
    completed_today: int

# Helper: Execute GTD command
def execute_gtd_command(command: str, *args) -> dict:
    """Execute a GTD bash command and return structured result"""
    cmd_path = os.path.join(GTD_BASE, "bin", command)
    
    if not os.path.exists(cmd_path):
        raise HTTPException(status_code=404, detail=f"Command not found: {command}")
    
    try:
        env = os.environ.copy()
        env["PATH"] = f"{GTD_BASE}/bin:{env.get('PATH', '')}"
        
        result = subprocess.run(
            [cmd_path] + list(args),
            capture_output=True,
            text=True,
            cwd=GTD_BASE,
            env=env,
            timeout=30
        )
        
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="Command timed out")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "GTD Wizard API",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/api/menu")
async def get_menu():
    """Get main menu structure"""
    return {
        "sections": [
            {
                "title": "📥 INPUTS - Capture & Process",
                "items": [
                    {"id": 1, "title": "📥 Capture Something to Inbox", "route": "/capture"},
                    {"id": 2, "title": "📋 Process Inbox Items", "route": "/inbox"},
                    {"id": 3, "title": "📝 Log to Daily Log", "route": "/log"},
                    {"id": 4, "title": "🌅 Morning/Evening Check-In", "route": "/checkin"}
                ]
            },
            {
                "title": "🗂️ ORGANIZATION - Manage Your System",
                "items": [
                    {"id": 5, "title": "✅ Manage Tasks", "route": "/tasks"},
                    {"id": 6, "title": "📁 Manage Projects", "route": "/projects"},
                    {"id": 7, "title": "📂 Manage Areas", "route": "/areas"},
                    {"id": 8, "title": "🗺️ Manage MOCs", "route": "/mocs"},
                    {"id": 9, "title": "🔗 Zettelkasten", "route": "/zettelkasten"}
                ]
            },
            {
                "title": "📤 OUTPUTS - Reviews & Creation",
                "items": [
                    {"id": 10, "title": "📊 Review", "route": "/reviews"},
                    {"id": 11, "title": "🧠 Sync with Second Brain", "route": "/sync"},
                    {"id": 12, "title": "✍️ Express Phase", "route": "/express"},
                    {"id": 13, "title": "📋 Use Templates", "route": "/templates"}
                ]
            }
        ]
    }

@app.get("/api/status")
async def get_status():
    """Get system status"""
    try:
        # Get inbox count
        inbox_result = execute_gtd_command("gtd-inbox", "count")
        inbox_count = 0
        if inbox_result["success"]:
            try:
                inbox_count = int(inbox_result["stdout"].strip())
            except:
                pass
        
        # Get task count
        task_result = execute_gtd_command("gtd-task", "list", "--count")
        task_count = 0
        if task_result["success"]:
            try:
                task_count = int(task_result["stdout"].strip())
            except:
                pass
        
        # Get project count
        project_result = execute_gtd_command("gtd-project", "list", "--count")
        project_count = 0
        if project_result["success"]:
            try:
                project_count = int(project_result["stdout"].strip())
            except:
                pass
        
        return SystemStatus(
            inbox_count=inbox_count,
            active_tasks=task_count,
            active_projects=project_count,
            completed_today=0  # TODO: Implement
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/capture")
async def capture_item(item: CaptureItem):
    """Capture item to inbox"""
    try:
        # Build command arguments
        args = [item.type, item.description]
        if item.priority:
            args.extend(["--priority", item.priority])
        if item.project:
            args.extend(["--project", item.project])
        
        result = execute_gtd_command("gtd-capture", *args)
        
        if result["success"]:
            return {
                "success": True,
                "message": result["stdout"] or "Item captured successfully"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result["stderr"] or "Failed to capture item"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/inbox")
async def get_inbox():
    """Get inbox items"""
    try:
        result = execute_gtd_command("gtd-inbox", "list", "--json")
        
        if result["success"]:
            try:
                items = json.loads(result["stdout"])
                return {"items": items}
            except json.JSONDecodeError:
                # Fallback: parse text output
                lines = result["stdout"].strip().split("\n")
                items = []
                for i, line in enumerate(lines, 1):
                    if line.strip():
                        items.append({
                            "id": i,
                            "description": line.strip(),
                            "type": "unknown"
                        })
                return {"items": items}
        else:
            return {"items": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/inbox/{item_id}/process")
async def process_inbox_item(item_id: int, action: dict):
    """Process an inbox item"""
    try:
        # Get inbox item first
        inbox_result = execute_gtd_command("gtd-inbox", "list")
        
        # Process based on action
        action_type = action.get("type", "task")  # task, project, reference, etc.
        description = action.get("description", "")
        
        # Capture as the specified type
        result = execute_gtd_command("gtd-capture", action_type, description)
        
        if result["success"]:
            # Remove from inbox (if gtd-inbox supports it)
            return {
                "success": True,
                "message": "Item processed successfully"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result["stderr"] or "Failed to process item"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/tasks")
async def get_tasks(priority: Optional[str] = None, status: Optional[str] = None):
    """Get list of tasks"""
    try:
        args = ["list"]
        if priority:
            args.extend(["--priority", priority])
        if status:
            args.extend(["--status", status])
        
        result = execute_gtd_command("gtd-task", *args)
        
        if result["success"]:
            # Parse task list output
            tasks = []
            lines = result["stdout"].strip().split("\n")
            for line in lines:
                if line.strip() and not line.startswith("ID:"):
                    # Parse task line (format may vary)
                    tasks.append({
                        "id": len(tasks) + 1,
                        "description": line.strip(),
                        "priority": "medium",  # TODO: Parse from output
                        "status": "active"
                    })
            return {"tasks": tasks}
        else:
            return {"tasks": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/tasks")
async def create_task(task: dict):
    """Create a new task"""
    try:
        description = task.get("description", "")
        priority = task.get("priority", "medium")
        project = task.get("project")
        
        args = ["add", description, "--priority", priority]
        if project:
            args.extend(["--project", project])
        
        result = execute_gtd_command("gtd-task", *args)
        
        if result["success"]:
            return {
                "success": True,
                "message": result["stdout"] or "Task created successfully"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result["stderr"] or "Failed to create task"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/tasks/{task_id}/complete")
async def complete_task(task_id: int):
    """Complete a task"""
    try:
        result = execute_gtd_command("gtd-task", "complete", str(task_id))
        
        if result["success"]:
            return {
                "success": True,
                "message": "Task completed successfully"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result["stderr"] or "Failed to complete task"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# WebSocket for real-time updates
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await websocket.accept()
    
    try:
        while True:
            # Send status updates every 5 seconds
            status = await get_status()
            await websocket.send_json({
                "type": "status_update",
                "data": status.dict()
            })
            await asyncio.sleep(5)
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## Frontend Example (Vue.js)

### `web/frontend/src/App.vue`

```vue
<template>
  <div id="app">
    <header class="app-header">
      <h1>🧙 GTD Wizard</h1>
      <div class="header-actions">
        <button @click="refreshStatus">🔄</button>
        <button @click="showSettings = true">⚙️</button>
      </div>
    </header>

    <main class="app-main">
      <Dashboard v-if="currentView === 'dashboard'" :status="status" />
      <Menu v-else-if="currentView === 'menu'" @select="handleMenuSelect" />
      <CaptureWizard v-else-if="currentView === 'capture'" @close="currentView = 'menu'" />
      <TaskList v-else-if="currentView === 'tasks'" @close="currentView = 'menu'" />
      <InboxProcessor v-else-if="currentView === 'inbox'" @close="currentView = 'menu'" />
    </main>

    <StatusBar :status="status" />
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
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
      completed_today: 0
    })
    const showSettings = ref(false)

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

    const handleMenuSelect = (route) => {
      currentView.value = route.replace('/', '') || 'menu'
    }

    onMounted(() => {
      loadStatus()
      // Set up WebSocket connection for real-time updates
      const ws = new WebSocket('ws://localhost:8000/ws')
      ws.onmessage = (event) => {
        const data = JSON.parse(event.data)
        if (data.type === 'status_update') {
          status.value = data.data
        }
      }
    })

    return {
      currentView,
      status,
      showSettings,
      refreshStatus,
      handleMenuSelect
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background: #f5f5f5;
}

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

.header-actions button {
  background: rgba(255,255,255,0.2);
  border: none;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  margin-left: 0.5rem;
}

.app-main {
  max-width: 1200px;
  margin: 2rem auto;
  padding: 0 1rem;
}
</style>
```

### `web/frontend/src/components/Menu.vue`

```vue
<template>
  <div class="menu-container">
    <div class="menu-section" v-for="section in menu.sections" :key="section.title">
      <h2 class="section-title">{{ section.title }}</h2>
      <div class="menu-items">
        <button
          v-for="item in section.items"
          :key="item.id"
          class="menu-item"
          @click="selectItem(item)"
        >
          {{ item.title }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { api } from '../services/api'

export default {
  name: 'Menu',
  emits: ['select'],
  setup(props, { emit }) {
    const menu = ref({ sections: [] })

    const loadMenu = async () => {
      try {
        menu.value = await api.getMenu()
      } catch (error) {
        console.error('Failed to load menu:', error)
      }
    }

    const selectItem = (item) => {
      emit('select', item.route)
    }

    onMounted(() => {
      loadMenu()
    })

    return {
      menu,
      selectItem
    }
  }
}
</script>

<style scoped>
.menu-container {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.section-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 2rem 0 1rem;
  color: #333;
}

.section-title:first-child {
  margin-top: 0;
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
}

.menu-item:hover {
  background: #e9ecef;
  border-color: #667eea;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(102, 126, 234, 0.2);
}
</style>
```

### `web/frontend/src/components/CaptureWizard.vue`

```vue
<template>
  <div class="capture-wizard">
    <div class="wizard-header">
      <h2>📥 Capture to Inbox</h2>
      <button @click="$emit('close')" class="close-btn">×</button>
    </div>

    <div class="wizard-content">
      <div class="step">
        <h3>What would you like to capture?</h3>
        <div class="options">
          <label
            v-for="type in captureTypes"
            :key="type.value"
            class="option"
            :class="{ active: selectedType === type.value }"
          >
            <input
              type="radio"
              :value="type.value"
              v-model="selectedType"
            />
            <span>{{ type.label }}</span>
          </label>
        </div>
      </div>

      <div class="step">
        <h3>Description</h3>
        <textarea
          v-model="description"
          placeholder="Enter description..."
          rows="4"
          class="description-input"
        ></textarea>
      </div>

      <div class="wizard-actions">
        <button @click="$emit('close')" class="btn-secondary">Cancel</button>
        <button @click="capture" class="btn-primary" :disabled="!canCapture">
          Capture →
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { api } from '../services/api'

export default {
  name: 'CaptureWizard',
  emits: ['close', 'captured'],
  setup(props, { emit }) {
    const selectedType = ref('task')
    const description = ref('')
    const loading = ref(false)

    const captureTypes = [
      { value: 'task', label: 'Task (actionable item)' },
      { value: 'idea', label: 'Idea (someday/maybe)' },
      { value: 'reference', label: 'Reference (information to keep)' },
      { value: 'link', label: 'Link (URL to save)' },
      { value: 'call', label: 'Call (phone call notes)' },
      { value: 'email', label: 'Email (email action)' },
      { value: 'note', label: 'General note' },
      { value: 'zettelkasten', label: 'Zettelkasten note (atomic idea)' }
    ]

    const canCapture = computed(() => {
      return selectedType.value && description.value.trim().length > 0
    })

    const capture = async () => {
      if (!canCapture.value) return

      loading.value = true
      try {
        await api.captureItem({
          type: selectedType.value,
          description: description.value.trim()
        })
        emit('captured')
        emit('close')
      } catch (error) {
        console.error('Failed to capture:', error)
        alert('Failed to capture item. Please try again.')
      } finally {
        loading.value = false
      }
    }

    return {
      selectedType,
      description,
      loading,
      captureTypes,
      canCapture,
      capture
    }
  }
}
</script>

<style scoped>
.capture-wizard {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.wizard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.wizard-header h2 {
  font-size: 1.5rem;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  color: #999;
}

.close-btn:hover {
  color: #333;
}

.step {
  margin-bottom: 2rem;
}

.step h3 {
  margin-bottom: 1rem;
  color: #555;
}

.options {
  display: grid;
  gap: 0.5rem;
}

.option {
  display: flex;
  align-items: center;
  padding: 1rem;
  border: 2px solid #e9ecef;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.option:hover {
  border-color: #667eea;
}

.option.active {
  border-color: #667eea;
  background: #f0f4ff;
}

.option input {
  margin-right: 0.5rem;
}

.description-input {
  width: 100%;
  padding: 1rem;
  border: 2px solid #e9ecef;
  border-radius: 6px;
  font-size: 1rem;
  font-family: inherit;
}

.wizard-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
}

.btn-primary, .btn-secondary {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #5568d3;
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  background: #e9ecef;
  color: #333;
}

.btn-secondary:hover {
  background: #dee2e6;
}
</style>
```

### `web/frontend/src/services/api.js`

```javascript
const API_BASE = 'http://localhost:8000/api'

export const api = {
  async getMenu() {
    const response = await fetch(`${API_BASE}/menu`)
    if (!response.ok) throw new Error('Failed to fetch menu')
    return response.json()
  },

  async getStatus() {
    const response = await fetch(`${API_BASE}/status`)
    if (!response.ok) throw new Error('Failed to fetch status')
    return response.json()
  },

  async captureItem(item) {
    const response = await fetch(`${API_BASE}/capture`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to capture item')
    }
    return response.json()
  },

  async getInbox() {
    const response = await fetch(`${API_BASE}/inbox`)
    if (!response.ok) throw new Error('Failed to fetch inbox')
    return response.json()
  },

  async getTasks(priority, status) {
    const params = new URLSearchParams()
    if (priority) params.append('priority', priority)
    if (status) params.append('status', status)
    const response = await fetch(`${API_BASE}/tasks?${params}`)
    if (!response.ok) throw new Error('Failed to fetch tasks')
    return response.json()
  },

  async createTask(task) {
    const response = await fetch(`${API_BASE}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(task)
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to create task')
    }
    return response.json()
  },

  async completeTask(taskId) {
    const response = await fetch(`${API_BASE}/tasks/${taskId}/complete`, {
      method: 'POST'
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to complete task')
    }
    return response.json()
  }
}
```

## Running the Prototype

### Backend

```bash
cd web/backend
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn python-multipart
python main.py
```

### Frontend

```bash
cd web/frontend
npm install
npm run dev
```

### Access

- Frontend: http://localhost:5173 (or 3000)
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Next Steps

1. Add more components (TaskList, InboxProcessor, etc.)
2. Implement WebSocket for real-time updates
3. Add error handling and loading states
4. Implement authentication (if needed)
5. Add tests
6. Deploy to production





