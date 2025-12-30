# GTD Wizard Web Interface Design

## Overview

This document outlines the design for a web-based interface that provides the same wizard-like experience as the CLI wizard, accessible via a browser. The web interface will maintain the same functionality while providing a modern, responsive UI.

## Architecture

### High-Level Architecture

```
┌─────────────────┐
│   Web Browser   │
│  (React/Vue)    │
└────────┬────────┘
         │ HTTP/WebSocket
         │
┌────────▼────────┐
│  Web Server     │
│  (FastAPI/Flask)│
└────────┬────────┘
         │
         │ Shell Commands / API Calls
         │
┌────────▼────────┐
│  GTD Backend    │
│  (Bash Scripts) │
└─────────────────┘
```

### Technology Stack Options

#### Option 1: Python Backend (Recommended)
- **Backend**: FastAPI or Flask
- **Frontend**: React or Vue.js
- **Communication**: REST API + WebSocket for real-time updates
- **Shell Integration**: Subprocess calls to bash scripts

#### Option 2: Node.js Backend
- **Backend**: Express.js or Fastify
- **Frontend**: React or Vue.js
- **Communication**: REST API + WebSocket
- **Shell Integration**: Child process calls to bash scripts

#### Option 3: Full-Stack Framework
- **Framework**: Next.js (React) or Nuxt.js (Vue)
- **API Routes**: Server-side API routes
- **Shell Integration**: Node.js child processes

## UI/UX Design

### Main Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  🧙 GTD Wizard                                    [Settings] │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 📥 Inbox     │  │ ✅ Tasks     │  │ 📁 Projects   │      │
│  │   12 items   │  │   8 active   │  │   5 active    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 📊 Reviews   │  │ 🧠 Second    │  │ 📚 Learning   │      │
│  │   Daily ✓    │  │   Brain      │  │   Available   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Quick Actions                                       │   │
│  │  [Capture] [Process Inbox] [Daily Review] [Status]  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Recent Activity                                             │
│  • Task "Review report" completed 2 hours ago               │
│  • Project "Website Redesign" updated 5 hours ago           │
│  • Daily log entry created 1 day ago                       │
└─────────────────────────────────────────────────────────────┘
```

### Main Menu (Wizard Interface)

```
┌─────────────────────────────────────────────────────────────┐
│  🧙 GTD Wizard - Main Menu                    [Home] [Help] │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📥 INPUTS - Capture & Process                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. 📥 Capture Something to Inbox                    │  │
│  │ 2. 📋 Process Inbox Items (12 items)                │  │
│  │ 3. 📝 Log to Daily Log                              │  │
│  │ 4. 🌅 Morning/Evening Check-In                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  🗂️ ORGANIZATION - Manage Your System                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 5. ✅ Manage Tasks                                   │  │
│  │ 6. 📁 Manage Projects                                │  │
│  │ 7. 📂 Manage Areas of Responsibility                │  │
│  │ 8. 🗺️ Manage MOCs                                   │  │
│  │ 9. 🔗 Zettelkasten (Atomic Notes)                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  📤 OUTPUTS - Reviews & Creation                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 10. 📊 Review (Daily/Weekly/Monthly)                │  │
│  │ 11. 🧠 Sync with Second Brain                        │  │
│  │ 12. ✍️ Express Phase (Create Content)                │  │
│  │ 13. 📋 Use Templates                                 │  │
│  │ 14. 🎨 Create Diagrams & Mindmaps                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  📚 LEARNING - Guides & Discovery                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 15. 📖 Learn Organization System                      │  │
│  │ 16. 🧠 Learn Second Brain                            │  │
│  │ 17. 🎯 Discover Life Vision                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  🔍 ANALYSIS - Insights & Tracking                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 18. 🔎 Search GTD System                             │  │
│  │ 19. 📊 System Status                                 │  │
│  │ 20. 🎯 Goal Tracking & Progress                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  🛠️ TOOLS & SUPPORT                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 21. 🤖 Get Advice from Personas                      │  │
│  │ 22. 🔄 Manage Habits & Recurring Tasks               │  │
│  │ 23. 🤖 AI Suggestions & MCP Tools                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ⚙️ SETTINGS                                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 24. ⚙️ Configuration & Setup                         │  │
│  │ 25. 🎮 Gamification & Habitica                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  [Type number or search...]                                 │
└─────────────────────────────────────────────────────────────┘
```

### Capture Wizard Interface

```
┌─────────────────────────────────────────────────────────────┐
│  📥 Capture to Inbox                          [← Back] [×]  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  What would you like to capture?                            │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ ○ Task (actionable item)                             │  │
│  │ ○ Idea (someday/maybe)                               │  │
│  │ ○ Reference (information to keep)                     │  │
│  │ ○ Link (URL to save)                                 │  │
│  │ ○ Call (phone call notes)                             │  │
│  │ ○ Email (email action)                                │  │
│  │ ○ General note                                        │  │
│  │ ○ Zettelkasten note (atomic idea)                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Description:                                          │  │
│  │ ┌──────────────────────────────────────────────────┐ │  │
│  │ │                                                   │ │  │
│  │ │                                                   │ │  │
│  │ └──────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  [Cancel]                                    [Capture →]    │
└─────────────────────────────────────────────────────────────┘
```

### Task Management Interface

```
┌─────────────────────────────────────────────────────────────┐
│  ✅ Manage Tasks                              [← Back] [×]   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Active Tasks (8)                    [+ New Task]     │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ ☐ Review quarterly report            [High] [Work]    │  │
│  │ ☐ Update project documentation      [Medium] [Home]  │  │
│  │ ☐ Schedule team meeting              [Low] [Work]     │  │
│  │ ☐ Review code changes                [High] [Work]    │  │
│  │ ☐ Plan vacation                      [Medium] [Home] │  │
│  │ ☐ Call dentist                       [Low] [Home]     │  │
│  │ ☐ Write blog post                    [Medium] [Home] │  │
│  │ ☐ Review pull requests               [High] [Work]    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Filters: [All] [High Priority] [Work] [Home] [Completed]  │
│                                                              │
│  Actions: [Complete Selected] [Update] [Link to Project]  │
└─────────────────────────────────────────────────────────────┘
```

### Review Interface

```
┌─────────────────────────────────────────────────────────────┐
│  📊 Daily Review                              [← Back] [×]   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Step 1 of 5: Process Inbox                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                              │
│  You have 12 items in your inbox.                           │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Item 1 of 12                                          │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │ Review quarterly report                               │  │
│  │                                                       │  │
│  │ What is this?                                         │  │
│  │ ○ Task (actionable)                                  │  │
│  │ ○ Project (multi-step)                               │  │
│  │ ○ Reference (information)                            │  │
│  │ ○ Someday/Maybe (future)                             │  │
│  │ ○ Trash (not needed)                                 │  │
│  │                                                       │  │
│  │ [← Previous]              [Next →] [Skip] [Delete]   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Progress: ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 33%         │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Real-Time Updates
- WebSocket connection for live status updates
- Progress indicators for long-running operations
- Toast notifications for completed actions

### 2. Responsive Design
- Mobile-friendly interface
- Tablet-optimized layouts
- Desktop full-featured experience

### 3. Search & Navigation
- Global search across all GTD items
- Keyboard shortcuts (same as CLI)
- Breadcrumb navigation
- Quick actions menu

### 4. Visual Enhancements
- Color-coded priorities
- Status badges
- Progress bars
- Charts and graphs for analytics

### 5. Interactive Guides
- Contextual help panels
- Step-by-step wizards
- Tooltips and hints
- Video tutorials (optional)

## API Design

### REST Endpoints

```python
# Main Menu
GET  /api/menu                    # Get main menu structure
GET  /api/menu/{section}          # Get menu section

# Capture
POST /api/capture                 # Capture new item
GET  /api/inbox                   # List inbox items
POST /api/inbox/{id}/process      # Process inbox item

# Tasks
GET  /api/tasks                   # List tasks
POST /api/tasks                   # Create task
PUT  /api/tasks/{id}              # Update task
DELETE /api/tasks/{id}            # Delete task
POST /api/tasks/{id}/complete     # Complete task

# Projects
GET  /api/projects                # List projects
POST /api/projects                # Create project
GET  /api/projects/{id}           # Get project details
PUT  /api/projects/{id}           # Update project

# Reviews
GET  /api/reviews/daily           # Get daily review data
POST /api/reviews/daily           # Complete daily review
GET  /api/reviews/weekly          # Get weekly review data
POST /api/reviews/weekly          # Complete weekly review

# Status
GET  /api/status                  # Get system status
GET  /api/stats                   # Get statistics

# Search
GET  /api/search?q={query}        # Search GTD system

# Sync
POST /api/sync/second-brain       # Sync with Second Brain
GET  /api/sync/status             # Get sync status
```

### WebSocket Events

```javascript
// Client → Server
{
  "type": "subscribe",
  "channel": "status"
}

// Server → Client
{
  "type": "status_update",
  "data": {
    "inbox_count": 12,
    "active_tasks": 8,
    "active_projects": 5
  }
}

{
  "type": "operation_progress",
  "operation": "sync_second_brain",
  "progress": 75,
  "message": "Syncing projects..."
}
```

## Backend Integration

### Shell Script Execution

```python
# Example FastAPI endpoint
from fastapi import FastAPI
import subprocess
import json

app = FastAPI()

@app.post("/api/capture")
async def capture_item(item: CaptureItem):
    """Capture item to inbox via bash script"""
    result = subprocess.run(
        ["gtd-capture", item.type, item.description],
        capture_output=True,
        text=True,
        cwd=os.path.expanduser("~/code/dotfiles")
    )
    
    if result.returncode == 0:
        return {"success": True, "message": result.stdout}
    else:
        return {"success": False, "error": result.stderr}
```

### Command Wrapper

```python
class GTDBackend:
    """Wrapper for GTD bash scripts"""
    
    def __init__(self):
        self.base_dir = os.path.expanduser("~/code/dotfiles")
        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.base_dir}/bin:{self.env['PATH']}"
    
    def execute_command(self, command: str, *args) -> dict:
        """Execute GTD command and return structured result"""
        cmd = [f"{self.base_dir}/bin/{command}"] + list(args)
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=self.base_dir,
            env=self.env
        )
        
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    
    def get_tasks(self) -> list:
        """Get list of tasks"""
        result = self.execute_command("gtd-task", "list", "--json")
        if result["success"]:
            return json.loads(result["stdout"])
        return []
    
    def capture_item(self, item_type: str, description: str) -> dict:
        """Capture item to inbox"""
        return self.execute_command("gtd-capture", item_type, description)
```

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Set up web server (FastAPI/Flask)
- [ ] Create API endpoints for basic operations
- [ ] Implement shell script integration
- [ ] Basic frontend with main menu
- [ ] Authentication/authorization (if needed)

### Phase 2: Core Features (Week 3-4)
- [ ] Capture wizard interface
- [ ] Task management interface
- [ ] Project management interface
- [ ] Inbox processing interface
- [ ] Basic status dashboard

### Phase 3: Advanced Features (Week 5-6)
- [ ] Review wizards (daily/weekly/monthly)
- [ ] Second Brain sync interface
- [ ] Search functionality
- [ ] Analytics and charts
- [ ] Real-time updates (WebSocket)

### Phase 4: Polish & Enhancement (Week 7-8)
- [ ] Responsive design
- [ ] Keyboard shortcuts
- [ ] Help system and guides
- [ ] Performance optimization
- [ ] Error handling and validation

## Security Considerations

1. **Authentication**: Optional user authentication if multi-user
2. **Authorization**: File system access controls
3. **Input Validation**: Sanitize all user inputs
4. **Command Injection**: Prevent shell injection attacks
5. **Rate Limiting**: Prevent abuse of API endpoints
6. **HTTPS**: Use SSL/TLS for all connections

## Deployment Options

### Option 1: Local Development Server
```bash
# Run locally for personal use
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Option 2: Docker Container
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Option 3: Systemd Service
```ini
[Unit]
Description=GTD Wizard Web Interface
After=network.target

[Service]
Type=simple
User=abby
WorkingDirectory=/home/abby/code/dotfiles/web
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## Example Implementation Structure

```
web/
├── backend/
│   ├── main.py              # FastAPI app
│   ├── api/
│   │   ├── __init__.py
│   │   ├── capture.py       # Capture endpoints
│   │   ├── tasks.py         # Task endpoints
│   │   ├── projects.py      # Project endpoints
│   │   └── reviews.py       # Review endpoints
│   ├── core/
│   │   ├── __init__.py
│   │   ├── gtd_backend.py   # Shell script wrapper
│   │   └── models.py        # Data models
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard.vue
│   │   │   ├── Menu.vue
│   │   │   ├── CaptureWizard.vue
│   │   │   ├── TaskList.vue
│   │   │   └── ReviewWizard.vue
│   │   ├── views/
│   │   │   ├── Home.vue
│   │   │   └── Settings.vue
│   │   ├── services/
│   │   │   └── api.js        # API client
│   │   └── App.vue
│   ├── package.json
│   └── vite.config.js
├── docker-compose.yml
└── README.md
```

## Benefits of Web Interface

1. **Accessibility**: Access from any device with a browser
2. **Visual Appeal**: Modern, intuitive UI
3. **Real-Time Updates**: Live status and progress
4. **Better UX**: Drag-and-drop, visual feedback
5. **Mobile Support**: Use on phone/tablet
6. **Sharing**: Easier to share screenshots/demos
7. **Analytics**: Visual charts and graphs
8. **Multi-Tab**: Work with multiple views simultaneously

## Migration Path

1. **Parallel Operation**: Web and CLI can coexist
2. **Gradual Migration**: Use web for new features, CLI for existing
3. **Feature Parity**: Ensure all CLI features work in web
4. **User Choice**: Let users choose their preferred interface

## Next Steps

1. **Prototype**: Build minimal viable version
2. **User Testing**: Get feedback on UI/UX
3. **Iterate**: Refine based on usage
4. **Documentation**: Create user guide
5. **Deployment**: Set up production environment





