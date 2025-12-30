#!/usr/bin/env python3
"""
GTD Wizard Web Interface - FastAPI Backend
Minimal working prototype that integrates with existing GTD bash scripts
"""
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import subprocess
import json
import os
import asyncio
import sys
from typing import Optional, List, Dict, Any
from pathlib import Path
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="GTD Wizard API",
    description="Web interface for GTD Wizard system",
    version="1.0.0"
)

# CORS middleware for frontend
# Allow both development (Vite) and production (nginx) origins
cors_origins = [
    "http://localhost:5173",  # Vite dev server
    "http://localhost:3000",  # Alternative dev port
    "http://127.0.0.1:5173",
    "http://localhost",  # Production nginx
    "http://gtd-wizard.local",  # Production domain
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Find GTD base directory (where GTD scripts live)
GTD_BASE = Path.home() / "code" / "dotfiles"
if not GTD_BASE.exists():
    GTD_BASE = Path.home() / "code" / "personal" / "dotfiles"

# Find GTD data directory (where GTD data lives)
# Try to read from config file, otherwise use default
GTD_DATA_BASE = Path.home() / "Documents" / "gtd"
gtd_config_file = Path.home() / ".gtd_config"
if not gtd_config_file.exists():
    for path in [
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config",
    ]:
        if path.exists():
            gtd_config_file = path
            break

if gtd_config_file.exists():
    try:
        with open(gtd_config_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith("GTD_BASE_DIR_HOME=") or line.startswith("GTD_BASE_DIR="):
                    value = line.split("=", 1)[1].strip().strip('"').strip("'")
                    # Expand $HOME
                    value = value.replace("$HOME", str(Path.home()))
                    if value:
                        GTD_DATA_BASE = Path(value)
                        break
    except Exception as e:
        logger.warning(f"Error reading GTD config: {e}, using default {GTD_DATA_BASE}")

# GTD directory structure
INBOX_PATH = GTD_DATA_BASE / "0-inbox"
TASKS_PATH = GTD_DATA_BASE / "tasks"
PROJECTS_PATH = GTD_DATA_BASE / "1-projects"

if not GTD_DATA_BASE.exists():
    logger.warning(f"GTD data directory not found. Expected: {GTD_DATA_BASE}")

# Models
class CaptureItem(BaseModel):
    type: str  # task, idea, reference, link, call, email, note, zettelkasten
    description: str
    priority: Optional[str] = None
    project: Optional[str] = None

class TaskCreate(BaseModel):
    description: str
    priority: Optional[str] = "medium"
    project: Optional[str] = None

class InboxProcess(BaseModel):
    type: str  # task, project, reference, etc.
    description: str
    priority: Optional[str] = None

class SystemStatus(BaseModel):
    inbox_count: int
    active_tasks: int
    active_projects: int
    completed_today: int
    advice_results_pending: int = 0
    status: str = "ok"

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to WebSocket: {e}")

manager = ConnectionManager()

# Helper: Execute GTD command
def execute_gtd_command(command: str, *args, timeout: int = 30) -> Dict[str, Any]:
    """Execute a GTD bash command and return structured result"""
    cmd_path = GTD_BASE / "bin" / command
    
    if not cmd_path.exists():
        logger.error(f"Command not found: {cmd_path}")
        return {
            "success": False,
            "stdout": "",
            "stderr": f"Command not found: {command}",
            "returncode": 1
        }
    
    try:
        env = os.environ.copy()
        env["PATH"] = f"{GTD_BASE / 'bin'}:{env.get('PATH', '')}"
        
        result = subprocess.run(
            [str(cmd_path)] + list(args),
            capture_output=True,
            text=True,
            cwd=str(GTD_BASE),
            env=env,
            timeout=timeout
        )
        
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        logger.error(f"Command timed out: {command}")
        return {
            "success": False,
            "stdout": "",
            "stderr": "Command timed out",
            "returncode": -1
        }
    except Exception as e:
        logger.error(f"Error executing command {command}: {e}")
        return {
            "success": False,
            "stdout": "",
            "stderr": str(e),
            "returncode": -1
        }

# Helper: Count files in directory
def count_files(directory: Path, pattern: str = "*.md") -> int:
    """Count files matching pattern in directory"""
    if not directory.exists():
        return 0
    try:
        return len(list(directory.glob(pattern)))
    except Exception as e:
        logger.error(f"Error counting files in {directory}: {e}")
        return 0

# Helper: Get pending suggestions (read from suggestions directory)
def get_pending_suggestions(confidence_filter: str = "all") -> List[Dict[str, Any]]:
    """Get pending task suggestions from the suggestions directory"""
    suggestions_dir = GTD_DATA_BASE / "suggestions"
    suggestions = []
    
    if not suggestions_dir.exists():
        return suggestions
    
    try:
        for file in suggestions_dir.glob("*.json"):
            try:
                with open(file, 'r') as f:
                    data = json.load(f)
                
                # Filter by status
                if data.get("status") not in (None, "pending"):
                    continue
                
                # Filter by confidence if specified
                if confidence_filter != "all":
                    confidence = data.get("confidence", 0.0)
                    if confidence_filter == "high" and confidence < 0.7:
                        continue
                    elif confidence_filter == "medium" and (confidence < 0.4 or confidence >= 0.7):
                        continue
                    elif confidence_filter == "low" and confidence >= 0.4:
                        continue
                
                suggestions.append({
                    "id": file.stem,
                    "title": data.get("title", ""),
                    "reason": data.get("reason", ""),
                    "confidence": data.get("confidence", 0.0),
                    "context": data.get("context", ""),
                    "priority": data.get("priority", ""),
                })
            except (json.JSONDecodeError, KeyError) as e:
                logger.warning(f"Error reading suggestion file {file}: {e}")
                continue
        
        # Sort by confidence (highest first)
        suggestions.sort(key=lambda x: x.get("confidence", 0.0), reverse=True)
        return suggestions
    except Exception as e:
        logger.error(f"Error getting suggestions: {e}")
        return []

# Helper: Perform web search using persona helper
def perform_web_search(query: str) -> str:
    """Perform web search using the enhanced search system"""
    try:
        # Add functions directory to path
        functions_dir = GTD_BASE / "zsh" / "functions"
        if str(functions_dir) not in sys.path:
            sys.path.insert(0, str(functions_dir))
        
        from gtd_persona_helper import execute_web_search, read_config, _extract_user_context
        
        config = read_config()
        context = _extract_user_context(config)
        results = execute_web_search(query, use_enhanced_search=True, context=context)
        return results
    except ImportError as e:
        logger.error(f"Failed to import web search functions: {e}")
        return f"Error: Web search not available: {str(e)}"
    except Exception as e:
        logger.error(f"Error performing web search: {e}")
        return f"Error: {str(e)}"

# Helper: Count projects (count subdirectories with README.md)
def count_projects(projects_path: Path) -> int:
    """Count projects (subdirectories with README.md)"""
    if not projects_path.exists():
        return 0
    try:
        count = 0
        for item in projects_path.iterdir():
            if item.is_dir() and (item / "README.md").exists():
                count += 1
        return count
    except Exception as e:
        logger.error(f"Error counting projects in {projects_path}: {e}")
        return 0

# Helper: Parse task list output
def parse_task_list(output: str) -> List[Dict[str, Any]]:
    """Parse task list output into structured format"""
    tasks = []
    lines = output.strip().split("\n")
    
    current_task = None
    
    for line in lines:
        original_line = line
        line = line.strip()
        
        # Skip empty lines and separators
        if not line or line.startswith("---"):
            # Empty line means end of current task
            if current_task and current_task.get("id"):
                tasks.append(current_task)
                current_task = None
            continue
        
        # Look for numbered task entries like "[1] Task name"
        if line.startswith("[") and "]" in line:
            # Save previous task if exists
            if current_task and current_task.get("id"):
                tasks.append(current_task)
            
            # Extract task number and description
            parts = line.split("]", 1)
            if len(parts) == 2:
                number_part = parts[0].replace("[", "").strip()
                description = parts[1].strip()
                current_task = {
                    "id": None,  # Will be set when we find the ID line
                    "description": description,
                    "priority": "medium",
                    "status": "active",
                    "context": None,
                    "energy": None,
                    "project": None,
                    "area": None,
                    "repository": None
                }
                
                # Try to extract priority from description
                if "[High]" in description or "[HIGH]" in description:
                    current_task["priority"] = "high"
                elif "[Low]" in description or "[LOW]" in description:
                    current_task["priority"] = "low"
        
        # Look for ID line like "     ID: task-id" (may be indented)
        elif current_task and "ID:" in line:
            task_id = line.split("ID:", 1)[1].strip()
            current_task["id"] = task_id
        
        # Look for Context/Energy/Priority line like "     Context: ... | Energy: ... | Priority: ..."
        elif current_task and ("Context:" in line or "Energy:" in line or "Priority:" in line):
            # Parse the combined line
            if "Context:" in line:
                context_part = line.split("Context:", 1)[1]
                if "|" in context_part:
                    context_part = context_part.split("|")[0]
                current_task["context"] = context_part.strip()
            
            if "Energy:" in line:
                energy_part = line.split("Energy:", 1)[1]
                if "|" in energy_part:
                    energy_part = energy_part.split("|")[0]
                current_task["energy"] = energy_part.strip()
            
            if "Priority:" in line:
                priority_part = line.split("Priority:", 1)[1]
                if "|" in priority_part:
                    priority_part = priority_part.split("|")[0]
                priority = priority_part.strip().lower()
                if priority in ["high", "medium", "low"]:
                    current_task["priority"] = priority
        
        # Look for Project line like "     Project: project-name"
        elif current_task and "Project:" in line:
            project = line.split("Project:", 1)[1].strip()
            current_task["project"] = project
        
        # Look for Area line like "     Area: area-name"
        elif current_task and "Area:" in line:
            area = line.split("Area:", 1)[1].strip()
            current_task["area"] = area
        
        # Look for Repository line like "     Repository: repo-name"
        elif current_task and "Repository:" in line:
            repository = line.split("Repository:", 1)[1].strip()
            current_task["repository"] = repository
        
        # Look for Status line (standalone)
        elif current_task and "Status:" in line and "Priority:" not in line:
            status = line.split("Status:", 1)[1].strip().lower()
            if status in ["active", "done", "completed"]:
                current_task["status"] = status
    
    # Add last task if exists
    if current_task and current_task.get("id"):
        tasks.append(current_task)
    
    # Fallback: if no tasks found with IDs, try to read from files directly
    if not tasks or all(t.get("id") is None for t in tasks):
        tasks = []
        if TASKS_PATH.exists():
            for file in sorted(TASKS_PATH.glob("*.md")):
                task_id = file.stem  # Use filename without .md as ID
                try:
                    with open(file, 'r') as f:
                        content = f.read()
                        # Extract title from first line or frontmatter
                        lines = content.split("\n")
                        description = file.stem
                        priority = "medium"
                        status = "active"
                        
                        # Try to get from frontmatter
                        if content.startswith("---"):
                            frontmatter_end = content.find("---", 3)
                            if frontmatter_end > 0:
                                frontmatter = content[3:frontmatter_end]
                                for fm_line in frontmatter.split("\n"):
                                    if ":" in fm_line:
                                        key, value = fm_line.split(":", 1)
                                        key = key.strip().lower()
                                        value = value.strip()
                                        if key == "title":
                                            description = value
                                        elif key == "priority":
                                            priority = value.lower()
                                        elif key == "status":
                                            status = value.lower()
                        
                        # Fallback to first heading
                        if description == file.stem:
                            for line in lines:
                                if line.startswith("# "):
                                    description = line[2:].strip()
                                    break
                        
                        tasks.append({
                            "id": task_id,
                            "description": description,
                            "priority": priority,
                            "status": status
                        })
                except Exception as e:
                    logger.warning(f"Error reading task file {file}: {e}")
                    continue
    
    return tasks

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "GTD Wizard API",
        "version": "1.0.0",
        "status": "running",
        "gtd_base": str(GTD_BASE),
        "gtd_data_base": str(GTD_DATA_BASE)
    }

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "gtd_base_exists": GTD_BASE.exists(),
        "gtd_data_base_exists": GTD_DATA_BASE.exists()
    }

@app.get("/api/menu")
async def get_menu():
    """Get main menu structure matching CLI wizard"""
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
                    {"id": 7, "title": "📂 Manage Areas of Responsibility", "route": "/areas"},
                    {"id": 8, "title": "🗺️ Manage MOCs", "route": "/mocs"},
                    {"id": 9, "title": "🔗 Zettelkasten (Atomic Notes)", "route": "/zettelkasten"}
                ]
            },
            {
                "title": "📤 OUTPUTS - Reviews & Creation",
                "items": [
                    {"id": 10, "title": "📊 Review (Daily/Weekly/Monthly)", "route": "/reviews"},
                    {"id": 11, "title": "🧠 Sync with Second Brain", "route": "/sync"},
                    {"id": 12, "title": "✍️ Express Phase (Create Content)", "route": "/express"},
                    {"id": 13, "title": "📋 Use Templates", "route": "/templates"},
                    {"id": 14, "title": "🎨 Create Diagrams & Mindmaps", "route": "/diagrams"}
                ]
            },
            {
                "title": "📚 LEARNING - Guides & Discovery",
                "items": [
                    {"id": 15, "title": "📖 Learn Organization System", "route": "/learn/org"},
                    {"id": 16, "title": "🧠 Learn Second Brain", "route": "/learn/brain"},
                    {"id": 17, "title": "🎯 Discover Life Vision", "route": "/learn/vision"}
                ]
            },
            {
                "title": "🔍 ANALYSIS - Insights & Tracking",
                "items": [
                    {"id": 18, "title": "🔎 Search GTD System", "route": "/search"},
                    {"id": 19, "title": "📊 System Status", "route": "/status"},
                    {"id": 20, "title": "🎯 Goal Tracking & Progress", "route": "/goals"}
                ]
            },
            {
                "title": "🛠️ TOOLS & SUPPORT",
                "items": [
                    {"id": 21, "title": "🤖 Get Advice from Personas", "route": "/advice"},
                    {"id": 22, "title": "📋 Review Advice Results", "route": "/advice-review"},
                    {"id": 23, "title": "🔄 Manage Habits & Recurring Tasks", "route": "/habits"},
                    {"id": 24, "title": "🤖 AI Suggestions & MCP Tools", "route": "/ai-suggestions"}
                ]
            },
            {
                "title": "⚙️ SETTINGS",
                "items": [
                    {"id": 25, "title": "⚙️ Configuration & Setup", "route": "/settings"},
                    {"id": 26, "title": "🎮 Gamification & Habitica", "route": "/gamification"}
                ]
            }
        ]
    }

@app.get("/api/status")
async def get_status():
    """Get system status"""
    try:
        # Count inbox items directly
        inbox_count = count_files(INBOX_PATH, "*.md")
        
        # Count tasks directly
        task_count = count_files(TASKS_PATH, "*.md")
        
        # Also count tasks in project directories
        if PROJECTS_PATH.exists():
            for project_dir in PROJECTS_PATH.iterdir():
                if project_dir.is_dir():
                    task_count += count_files(project_dir, "*.md")
                    # Exclude README.md from task count
                    if (project_dir / "README.md").exists():
                        task_count -= 1
        
        # Count projects (subdirectories with README.md)
        project_count = count_projects(PROJECTS_PATH)
        
        # TODO: Count completed today from daily logs
        completed_today = 0
        
        # Count pending advice results (completed but not reviewed)
        advice_results_pending = 0
        if ADVICE_RESULTS_DIR.exists():
            for result_file in ADVICE_RESULTS_DIR.glob("*.json"):
                try:
                    with open(result_file, 'r') as f:
                        data = json.load(f)
                    if data.get("status") == "completed" and not data.get("reviewed", False):
                        advice_results_pending += 1
                except:
                    continue
        
        return SystemStatus(
            inbox_count=inbox_count,
            active_tasks=task_count,
            active_projects=project_count,
            completed_today=completed_today,
            advice_results_pending=advice_results_pending
        )
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/capture")
async def capture_item(item: CaptureItem):
    """Capture an item to inbox"""
    try:
        args = [item.type, item.description]
        if item.priority:
            args.extend(["--priority", item.priority])
        if item.project:
            args.extend(["--project", item.project])
        
        result = execute_gtd_command("gtd-capture", *args)
        
        if result["success"]:
            # Broadcast update via WebSocket
            await manager.broadcast({
                "type": "status_update",
                "message": "Item captured successfully"
            })
            return {
                "success": True,
                "message": "Item captured successfully"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result["stderr"] or "Failed to capture item"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error capturing item: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/inbox")
async def get_inbox():
    """Get inbox items"""
    try:
        items = []
        if INBOX_PATH.exists():
            for i, file in enumerate(sorted(INBOX_PATH.glob("*.md")), 1):
                # Read first line as description
                try:
                    with open(file, 'r') as f:
                        first_line = f.readline().strip()
                        description = first_line.replace("#", "").strip()
                        if not description:
                            description = file.stem
                except:
                    description = file.stem
                
                items.append({
                    "id": i,
                    "description": description,
                    "type": "unknown",
                    "file": str(file.name)
                })
        return {"items": items}
    except Exception as e:
        logger.error(f"Error getting inbox: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/inbox/{item_id}/process")
async def process_inbox_item(item_id: int, action: InboxProcess):
    """Process an inbox item"""
    try:
        # Capture as the specified type
        args = [action.type, action.description]
        if action.priority:
            args.extend(["--priority", action.priority])
        
        result = execute_gtd_command("gtd-capture", *args)
        
        if result["success"]:
            # Broadcast update
            await manager.broadcast({
                "type": "status_update",
                "message": "Item processed successfully"
            })
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
        logger.error(f"Error processing inbox item: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/tasks")
async def get_tasks(priority: Optional[str] = None, status: Optional[str] = None):
    """Get tasks"""
    try:
        args = ["list"]
        if priority:
            args.extend(["--priority", priority])
        if status:
            args.extend(["--status", status])
        
        result = execute_gtd_command("gtd-task", *args)
        
        if result["success"]:
            tasks = parse_task_list(result["stdout"])
            return {"tasks": tasks}
        else:
            # Fallback: read tasks directly from files
            tasks = []
            if TASKS_PATH.exists():
                for file in sorted(TASKS_PATH.glob("*.md")):
                    task_id = file.stem  # Use filename as ID
                    try:
                        with open(file, 'r') as f:
                            content = f.read()
                            lines = content.split("\n")
                            description = file.stem
                            priority = "medium"
                            status = "active"
                            
                            # Try to get from frontmatter
                            if content.startswith("---"):
                                frontmatter_end = content.find("---", 3)
                                if frontmatter_end > 0:
                                    frontmatter = content[3:frontmatter_end]
                                    for fm_line in frontmatter.split("\n"):
                                        if ":" in fm_line:
                                            key, value = fm_line.split(":", 1)
                                            key = key.strip().lower()
                                            value = value.strip()
                                            if key == "title":
                                                description = value
                                            elif key == "priority":
                                                priority = value.lower()
                                            elif key == "status":
                                                status = value.lower()
                            
                            # Fallback to first heading
                            if description == file.stem:
                                for line in lines:
                                    if line.startswith("# "):
                                        description = line[2:].strip()
                                        break
                            
                            tasks.append({
                                "id": task_id,
                                "description": description,
                                "priority": priority,
                                "status": status
                            })
                    except Exception as e:
                        logger.warning(f"Error reading task file {file}: {e}")
                        continue
            return {"tasks": tasks}
    except Exception as e:
        logger.error(f"Error getting tasks: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/tasks")
async def create_task(task: TaskCreate):
    """Create a new task"""
    try:
        args = ["add", task.description]
        if task.priority:
            args.extend(["--priority", task.priority])
        if task.project:
            args.extend(["--project", task.project])
        
        result = execute_gtd_command("gtd-task", *args)
        
        if result["success"]:
            await manager.broadcast({
                "type": "status_update",
                "message": "Task created successfully"
            })
            return {
                "success": True,
                "message": "Task created successfully"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=result["stderr"] or "Failed to create task"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating task: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/tasks/{task_id}/complete")
async def complete_task(task_id: str):
    """Complete a task"""
    try:
        result = execute_gtd_command("gtd-task", "complete", task_id)
        
        if result["success"]:
            await manager.broadcast({
                "type": "status_update",
                "message": "Task completed successfully"
            })
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
        logger.error(f"Error completing task: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/projects")
async def get_projects():
    """Get projects"""
    try:
        result = execute_gtd_command("gtd-project", "list")
        
        if result["success"]:
            projects = []
            lines = result["stdout"].strip().split("\n")
            for i, line in enumerate(lines, 1):
                line = line.strip()
                if line and not line.startswith("---"):
                    projects.append({
                        "id": i,
                        "name": line,
                        "status": "active"
                    })
            return {"projects": projects}
        else:
            # Fallback: list project directories
            projects = []
            if PROJECTS_PATH.exists():
                for i, project_dir in enumerate(sorted(PROJECTS_PATH.iterdir()), 1):
                    if project_dir.is_dir() and (project_dir / "README.md").exists():
                        # Read project name from README.md
                        try:
                            with open(project_dir / "README.md", 'r') as f:
                                first_line = f.readline().strip()
                                name = first_line.replace("#", "").strip()
                                if not name:
                                    name = project_dir.name
                        except:
                            name = project_dir.name
                        
                        projects.append({
                            "id": i,
                            "name": name,
                            "status": "active"
                        })
            return {"projects": projects}
    except Exception as e:
        logger.error(f"Error getting projects: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# MCP/Suggestions Endpoints
@app.get("/api/suggestions")
async def get_suggestions(confidence_filter: Optional[str] = "all"):
    """Get pending task suggestions"""
    try:
        suggestions = get_pending_suggestions(confidence_filter)
        return {"suggestions": suggestions, "count": len(suggestions)}
    except Exception as e:
        logger.error(f"Error getting suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/suggestions/{suggestion_id}/create")
async def create_task_from_suggestion(suggestion_id: str):
    """Create a task from a suggestion"""
    try:
        suggestions_dir = GTD_DATA_BASE / "suggestions"
        suggestion_file = suggestions_dir / f"{suggestion_id}.json"
        
        if not suggestion_file.exists():
            raise HTTPException(status_code=404, detail="Suggestion not found")
        
        # Read suggestion
        with open(suggestion_file, 'r') as f:
            suggestion_data = json.load(f)
        
        title = suggestion_data.get("title", "")
        if not title:
            raise HTTPException(status_code=400, detail="Suggestion has no title")
        
        # Create task using gtd-task command
        result = execute_gtd_command("gtd-task", "add", title)
        
        if result["success"]:
            # Mark suggestion as accepted
            suggestion_data["status"] = "accepted"
            suggestion_data["accepted_at"] = datetime.now().isoformat()
            with open(suggestion_file, 'w') as f:
                json.dump(suggestion_data, f, indent=2)
            
            await manager.broadcast({
                "type": "status_update",
                "message": "Task created from suggestion"
            })
            return {"success": True, "message": "Task created successfully"}
        else:
            raise HTTPException(status_code=400, detail=result.get("stderr", "Failed to create task"))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating task from suggestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/suggestions/{suggestion_id}/dismiss")
async def dismiss_suggestion_endpoint(suggestion_id: str):
    """Dismiss a suggestion"""
    try:
        suggestions_dir = GTD_DATA_BASE / "suggestions"
        suggestion_file = suggestions_dir / f"{suggestion_id}.json"
        
        if not suggestion_file.exists():
            raise HTTPException(status_code=404, detail="Suggestion not found")
        
        # Mark as dismissed
        with open(suggestion_file, 'r') as f:
            suggestion_data = json.load(f)
        
        suggestion_data["status"] = "dismissed"
        suggestion_data["dismissed_at"] = datetime.now().isoformat()
        with open(suggestion_file, 'w') as f:
            json.dump(suggestion_data, f, indent=2)
        
        return {"success": True, "message": "Suggestion dismissed"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error dismissing suggestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/search")
async def web_search(query: str):
    """Perform web search using enhanced search"""
    try:
        results = perform_web_search(query)
        return {"query": query, "results": results, "success": True}
    except Exception as e:
        logger.error(f"Error performing web search: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Advice Review Endpoints
ADVICE_RESULTS_DIR = GTD_DATA_BASE / "advice_results"

@app.get("/api/advice-results")
async def get_advice_results(status_filter: Optional[str] = None):
    """Get list of advice results ready for review"""
    try:
        results = []
        if not ADVICE_RESULTS_DIR.exists():
            return {"results": [], "count": 0}
        
        # Get all JSON result files
        for result_file in sorted(ADVICE_RESULTS_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
            try:
                with open(result_file, 'r') as f:
                    data = json.load(f)
                
                # Filter by status if specified
                result_status = data.get("status", "unknown")
                if status_filter and result_status != status_filter:
                    continue
                
                # Only show completed or error results (skip pending)
                if result_status not in ("completed", "error"):
                    continue
                
                result_id = result_file.stem
                answer_file = ADVICE_RESULTS_DIR / f"{result_id}_answer.txt"
                
                # Get answer text (from file or JSON)
                answer_text = ""
                if answer_file.exists():
                    with open(answer_file, 'r', encoding='utf-8') as f:
                        answer_text = f.read()
                elif "answer" in data:
                    answer_text = data.get("answer", "")
                
                results.append({
                    "id": result_id,
                    "persona": data.get("persona", "unknown"),
                    "question": data.get("question", ""),
                    "mode": data.get("mode", "normal"),
                    "status": result_status,
                    "answer": answer_text,
                    "preview": data.get("preview", answer_text[:200] + "..." if len(answer_text) > 200 else answer_text),
                    "error": data.get("error", ""),
                    "created_at": data.get("created_at", ""),
                    "completed_at": data.get("completed_at", ""),
                    "duration_seconds": data.get("duration_seconds", 0),
                    "reviewed": data.get("reviewed", False),
                    "reviewed_at": data.get("reviewed_at", None)
                })
            except (json.JSONDecodeError, KeyError, IOError) as e:
                logger.warning(f"Error reading advice result file {result_file}: {e}")
                continue
        
        # Sort by completed_at (newest first)
        results.sort(key=lambda x: x.get("completed_at", ""), reverse=True)
        
        return {"results": results, "count": len(results)}
    except Exception as e:
        logger.error(f"Error getting advice results: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/advice-results/{result_id}")
async def get_advice_result(result_id: str):
    """Get a specific advice result by ID"""
    try:
        result_file = ADVICE_RESULTS_DIR / f"{result_id}.json"
        if not result_file.exists():
            raise HTTPException(status_code=404, detail="Advice result not found")
        
        with open(result_file, 'r') as f:
            data = json.load(f)
        
        answer_file = ADVICE_RESULTS_DIR / f"{result_id}_answer.txt"
        answer_text = ""
        if answer_file.exists():
            with open(answer_file, 'r', encoding='utf-8') as f:
                answer_text = f.read()
        elif "answer" in data:
            answer_text = data.get("answer", "")
        
        return {
            "id": result_id,
            "persona": data.get("persona", "unknown"),
            "question": data.get("question", ""),
            "mode": data.get("mode", "normal"),
            "status": data.get("status", "unknown"),
            "answer": answer_text,
            "error": data.get("error", ""),
            "created_at": data.get("created_at", ""),
            "completed_at": data.get("completed_at", ""),
            "duration_seconds": data.get("duration_seconds", 0),
            "reviewed": data.get("reviewed", False),
            "reviewed_at": data.get("reviewed_at", None)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting advice result: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/advice-results/{result_id}/review")
async def mark_advice_reviewed(result_id: str):
    """Mark an advice result as reviewed"""
    try:
        result_file = ADVICE_RESULTS_DIR / f"{result_id}.json"
        if not result_file.exists():
            raise HTTPException(status_code=404, detail="Advice result not found")
        
        with open(result_file, 'r') as f:
            data = json.load(f)
        
        data["reviewed"] = True
        data["reviewed_at"] = datetime.now().isoformat() + "Z"
        
        with open(result_file, 'w') as f:
            json.dump(data, f, indent=2)
        
        await manager.broadcast({
            "type": "status_update",
            "message": "Advice result marked as reviewed"
        })
        
        return {"success": True, "message": "Advice result marked as reviewed"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking advice as reviewed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/advice-results/{result_id}")
async def delete_advice_result(result_id: str):
    """Delete an advice result (archive it)"""
    try:
        result_file = ADVICE_RESULTS_DIR / f"{result_id}.json"
        answer_file = ADVICE_RESULTS_DIR / f"{result_id}_answer.txt"
        
        if not result_file.exists():
            raise HTTPException(status_code=404, detail="Advice result not found")
        
        # Move to archive directory instead of deleting
        archive_dir = ADVICE_RESULTS_DIR / "archived"
        archive_dir.mkdir(exist_ok=True)
        
        if result_file.exists():
            result_file.rename(archive_dir / result_file.name)
        if answer_file.exists():
            answer_file.rename(archive_dir / answer_file.name)
        
        await manager.broadcast({
            "type": "status_update",
            "message": "Advice result archived"
        })
        
        return {"success": True, "message": "Advice result archived"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error archiving advice result: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Echo back or handle message
            await websocket.send_json({"type": "echo", "message": data})
    except WebSocketDisconnect:
        manager.disconnect(websocket)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
