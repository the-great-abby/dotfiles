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
# Read Tailscale domain from environment or config
TAILSCALE_DOMAIN = os.getenv("GTD_TAILSCALE_DOMAIN", "")
cors_origins = [
    "http://localhost:5173",  # Vite dev server
    "http://localhost:3000",  # Alternative dev port
    "http://127.0.0.1:5173",
    "http://localhost",  # Production nginx
    "http://gtd-wizard.local",  # Production domain
]
# Add Tailscale domain if configured
if TAILSCALE_DOMAIN:
    cors_origins.extend([
        f"http://{TAILSCALE_DOMAIN}",
        f"https://{TAILSCALE_DOMAIN}",
    ])
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
WEEKLY_REVIEWS_PATH = GTD_DATA_BASE / "weekly-reviews"
HABITS_PATH = GTD_DATA_BASE / "habits"

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

class DailyReview(BaseModel):
    type: str  # morning or evening
    priority1: Optional[str] = None
    priority2: Optional[str] = None
    priority3: Optional[str] = None
    accomplishments: Optional[str] = None
    blockers: Optional[str] = None
    attention_items: Optional[str] = None
    what_went_well: Optional[str] = None
    morning_feeling: Optional[str] = None  # How am I feeling (energy, mood, readiness)
    today_goals: Optional[str] = None  # What do I need to accomplish today
    gratitude: Optional[str] = None  # What am I grateful for
    log_weather: Optional[bool] = False  # Whether to log weather

class DailyLogEntry(BaseModel):
    entry: str  # The log entry text

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
                    {"id": 10, "title": "🌅 Morning Review", "route": "/review/morning"},
                    {"id": 11, "title": "🌙 Evening Review", "route": "/review/evening"},
                    {"id": 12, "title": "📊 Other Reviews (Weekly/Monthly)", "route": "/reviews"},
                    {"id": 13, "title": "🧠 Sync with Second Brain", "route": "/sync"},
                    {"id": 14, "title": "✍️ Express Phase (Create Content)", "route": "/express"},
                    {"id": 15, "title": "📋 Use Templates", "route": "/templates"},
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
                # Read full file content, handling frontmatter
                try:
                    with open(file, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                    
                    # Check if file has frontmatter (starts with ---)
                    content_lines = []
                    in_frontmatter = False
                    frontmatter_end = False
                    first_line_title = file.stem  # Fallback title
                    
                    for line in lines:
                        if line.strip() == "---":
                            if not in_frontmatter:
                                # First --- marks start of frontmatter
                                in_frontmatter = True
                                continue  # Skip the opening ---
                            else:
                                # Second --- marks end of frontmatter
                                frontmatter_end = True
                                continue  # Skip the closing ---
                        
                        if in_frontmatter and not frontmatter_end:
                            # We're in frontmatter, skip this line
                            continue
                        
                        # This line should be included in content
                        content_lines.append(line)
                        # Extract title from first content line if it's a heading
                        if len(content_lines) == 1:
                            stripped = line.strip()
                            if stripped.startswith("# "):
                                first_line_title = stripped[2:].strip()
                            elif stripped:
                                first_line_title = stripped
                    
                    # Get full content (everything after frontmatter, or entire file if no frontmatter)
                    content = "".join(content_lines).strip()
                    
                    # If content is empty, use filename as fallback
                    if not content:
                        content = first_line_title
                    
                    # Use first non-empty line as title for reference
                    description = content
                    
                except Exception as e:
                    logger.warning(f"Error reading inbox file {file}: {e}")
                    description = file.stem
                    content = ""
                
                items.append({
                    "id": i,
                    "description": description,  # Full content
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
        # Find the inbox file corresponding to this item_id
        inbox_file = None
        if INBOX_PATH.exists():
            sorted_files = sorted(INBOX_PATH.glob("*.md"))
            if 1 <= item_id <= len(sorted_files):
                inbox_file = sorted_files[item_id - 1]  # item_id is 1-indexed
        
        if not inbox_file or not inbox_file.exists():
            raise HTTPException(status_code=404, detail=f"Inbox item {item_id} not found")
        
        # Capture as the specified type
        args = [action.type, action.description]
        if action.priority:
            args.extend(["--priority", action.priority])
        
        result = execute_gtd_command("gtd-capture", *args)
        
        if result["success"]:
            # Delete the inbox file after successful processing
            try:
                inbox_file.unlink()
                logger.info(f"Deleted processed inbox file: {inbox_file}")
            except Exception as e:
                logger.warning(f"Failed to delete inbox file {inbox_file}: {e}")
                # Don't fail the request if deletion fails, item was still processed
            
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

@app.delete("/api/inbox/{item_id}")
async def delete_inbox_item(item_id: int):
    """Delete an inbox item without processing it"""
    try:
        # Find the inbox file corresponding to this item_id
        inbox_file = None
        if INBOX_PATH.exists():
            sorted_files = sorted(INBOX_PATH.glob("*.md"))
            if 1 <= item_id <= len(sorted_files):
                inbox_file = sorted_files[item_id - 1]  # item_id is 1-indexed
        
        if not inbox_file or not inbox_file.exists():
            raise HTTPException(status_code=404, detail=f"Inbox item {item_id} not found")
        
        # Delete the file
        try:
            inbox_file.unlink()
            logger.info(f"Deleted inbox file: {inbox_file}")
            
            # Broadcast update
            await manager.broadcast({
                "type": "status_update",
                "message": "Inbox item deleted"
            })
            
            return {
                "success": True,
                "message": "Item deleted successfully"
            }
        except Exception as e:
            logger.error(f"Failed to delete inbox file {inbox_file}: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to delete file: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting inbox item: {e}")
        raise HTTPException(status_code=500, detail=str(e))

def get_daily_log_dir() -> Path:
    """Get the daily log directory from config or use default"""
    daily_log_dir = Path.home() / "Documents" / "daily_logs"
    daily_log_config = Path.home() / ".daily_log_config"
    if not daily_log_config.exists():
        for path in [
            Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".daily_log_config",
            Path.home() / "code" / "dotfiles" / "zsh" / ".daily_log_config",
        ]:
            if path.exists():
                daily_log_config = path
                break
    
    if daily_log_config.exists():
        try:
            with open(daily_log_config, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("DAILY_LOG_DIR="):
                        value = line.split("=", 1)[1].strip().strip('"').strip("'")
                        value = value.replace("$HOME", str(Path.home()))
                        if value:
                            daily_log_dir = Path(value)
                            break
        except Exception as e:
            logger.debug(f"Could not read daily log config: {e}")
    
    return daily_log_dir

@app.get("/api/reviews/daily")
async def get_daily_review_data(review_type: Optional[str] = None):
    """Get data for daily review (morning or evening)"""
    try:
        from datetime import datetime
        
        # Auto-detect time of day if not specified
        if not review_type:
            current_hour = datetime.now().hour
            review_type = "morning" if current_hour < 12 else "evening"
        
        if review_type not in ["morning", "evening"]:
            raise HTTPException(status_code=400, detail="review_type must be 'morning' or 'evening'")
        
        # Get system stats
        inbox_count = count_files(INBOX_PATH, "*.md")
        
        # Count active tasks
        active_tasks = 0
        if TASKS_PATH.exists():
            for task_file in TASKS_PATH.glob("*.md"):
                try:
                    with open(task_file, 'r') as f:
                        content = f.read()
                        if "status: active" in content:
                            active_tasks += 1
                except:
                    pass
        
        # Count active projects
        active_projects = 0
        if PROJECTS_PATH.exists():
            active_projects = len([d for d in PROJECTS_PATH.iterdir() if d.is_dir()])
        
        # Get habits due today (for morning check-in)
        habits_due = []
        if review_type == "morning" and HABITS_PATH.exists():
            today = datetime.now().strftime("%Y-%m-%d")
            for habit_file in HABITS_PATH.glob("*.md"):
                try:
                    with open(habit_file, 'r') as f:
                        content = f.read()
                        # Check if habit is active
                        if "status: active" in content or "status:" not in content:
                            # Check frequency and last completed
                            frequency = ""
                            last_completed = ""
                            for line in content.split('\n'):
                                if line.startswith("frequency:"):
                                    frequency = line.split(":", 1)[1].strip()
                                elif line.startswith("last_completed:"):
                                    last_completed = line.split(":", 1)[1].strip()
                            
                            # Get habit name
                            habit_name = habit_file.stem
                            for line in content.split('\n'):
                                if line.startswith("name:"):
                                    habit_name = line.split(":", 1)[1].strip()
                                    break
                            
                            # Check if due today
                            if frequency == "daily" and last_completed != today:
                                # Check time_of_day
                                time_of_day = ""
                                for line in content.split('\n'):
                                    if line.startswith("time_of_day:"):
                                        time_of_day = line.split(":", 1)[1].strip()
                                        break
                                
                                if time_of_day == "morning" or not time_of_day:
                                    habits_due.append(habit_name)
                except:
                    pass
        
        # Get AI suggestions (pre-generated morning suggestions)
        ai_suggestions = None
        if review_type == "morning":
            try:
                suggestions_dir = GTD_DATA_BASE / "checkin_suggestions"
                morning_suggestions_file = suggestions_dir / f"morning_{datetime.now().strftime('%Y-%m-%d')}.txt"
                if morning_suggestions_file.exists():
                    with open(morning_suggestions_file, 'r', encoding='utf-8') as f:
                        ai_suggestions = f.read().strip()
            except Exception as e:
                logger.debug(f"Could not get AI suggestions: {e}")
        
        # Get calendar info if available
        calendar_info = None
        try:
            calendar_cmd = Path.home() / "code" / "dotfiles" / "bin" / "gtd-calendar-info"
            if calendar_cmd.exists() and calendar_cmd.is_file():
                import subprocess
                if review_type == "morning":
                    result = subprocess.run(
                        [str(calendar_cmd), "overview", "today", "brief"],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                else:
                    # Evening - show tomorrow
                    from datetime import timedelta
                    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
                    result = subprocess.run(
                        [str(calendar_cmd), "overview", tomorrow, "brief"],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                if result.returncode == 0:
                    calendar_info = result.stdout.strip()
        except Exception as e:
            logger.debug(f"Could not get calendar info: {e}")
        
        # Check if review already exists for today
        today = datetime.now().strftime("%Y-%m-%d")
        review_file = WEEKLY_REVIEWS_PATH / f"daily-{today}-{review_type}.md"
        existing_review = None
        if review_file.exists():
            try:
                with open(review_file, 'r', encoding='utf-8') as f:
                    existing_review = f.read()
            except:
                pass
        
        return {
            "type": review_type,
            "date": today,
            "inbox_count": inbox_count,
            "active_tasks": active_tasks,
            "active_projects": active_projects,
            "habits_due": habits_due,
            "ai_suggestions": ai_suggestions,
            "calendar_info": calendar_info,
            "existing_review": existing_review is not None
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting daily review data: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/reviews/daily")
async def submit_daily_review(review: DailyReview):
    """Submit a daily review"""
    try:
        from datetime import datetime
        
        if review.type not in ["morning", "evening"]:
            raise HTTPException(status_code=400, detail="type must be 'morning' or 'evening'")
        
        today = datetime.now().strftime("%Y-%m-%d")
        now = datetime.now().strftime("%H:%M")
        
        # Ensure directory exists
        WEEKLY_REVIEWS_PATH.mkdir(parents=True, exist_ok=True)
        
        # Create review file
        review_file = WEEKLY_REVIEWS_PATH / f"daily-{today}-{review.type}.md"
        
        if review.type == "morning":
            content = f"""---
type: daily_review
time: morning
date: {today}
created: {today}T{now}
---

# Daily Morning Review - {today} 🌅

## How I'm Feeling
{review.morning_feeling or ''}

## Priorities Today
1. {review.priority1 or ''}
2. {review.priority2 or ''}
3. {review.priority3 or ''}

## Today's Goals
{review.today_goals or ''}

## Potential Blockers
{review.blockers or ''}

## Gratitude
{review.gratitude or ''}

## Yesterday's Accomplishments
{review.accomplishments or ''}

## Needs Attention
{review.attention_items or ''}
"""
        else:
            content = f"""---
type: daily_review
time: evening
date: {today}
created: {today}T{now}
---

# Daily Evening Review - {today} 🌙

## Today's Accomplishments
{review.accomplishments or ''}

## What Went Well
{review.what_went_well or ''}

## Blockers
{review.blockers or ''}

## Priorities Tomorrow
1. {review.priority1 or ''}
2. {review.priority2 or ''}
3. {review.priority3 or ''}

## Needs Attention
{review.attention_items or ''}
"""
        
        with open(review_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # Also write a marker to the daily log so CLI recognizes it
        # Get daily log directory using helper function
        daily_log_dir = get_daily_log_dir()
        
        # Write full check-in to daily log (matching CLI format)
        daily_log_file = daily_log_dir / f"{today}.md"
        try:
            daily_log_dir.mkdir(parents=True, exist_ok=True)
            # Create file with header if it doesn't exist
            if not daily_log_file.exists():
                with open(daily_log_file, 'w', encoding='utf-8') as f:
                    f.write(f"# Daily Log - {today}\n\n")
            
            # Write full check-in entry (matching CLI format)
            time_icon = "🌅" if review.type == "morning" else "🌙"
            checkin_entry = f"""━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{time_icon} {review.type.capitalize()} Check-In - {now}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"""
            
            if review.type == "morning":
                if review.morning_feeling:
                    checkin_entry += f"How I'm feeling: {review.morning_feeling}\n\n"
                if review.priority1 or review.priority2 or review.priority3:
                    checkin_entry += "Top 3 Priorities:\n"
                    if review.priority1:
                        checkin_entry += f"1. {review.priority1}\n"
                    if review.priority2:
                        checkin_entry += f"2. {review.priority2}\n"
                    if review.priority3:
                        checkin_entry += f"3. {review.priority3}\n"
                    checkin_entry += "\n"
                if review.today_goals:
                    checkin_entry += f"Today's Goals: {review.today_goals}\n\n"
                if review.blockers:
                    checkin_entry += f"Potential Blockers: {review.blockers}\n\n"
                if review.gratitude:
                    checkin_entry += f"Gratitude: {review.gratitude}\n\n"
            else:
                if review.accomplishments:
                    checkin_entry += f"Today's Accomplishments: {review.accomplishments}\n\n"
                if review.what_went_well:
                    checkin_entry += f"What Went Well: {review.what_went_well}\n\n"
                if review.blockers:
                    checkin_entry += f"Blockers: {review.blockers}\n\n"
                if review.priority1 or review.priority2 or review.priority3:
                    checkin_entry += "Priorities Tomorrow:\n"
                    if review.priority1:
                        checkin_entry += f"1. {review.priority1}\n"
                    if review.priority2:
                        checkin_entry += f"2. {review.priority2}\n"
                    if review.priority3:
                        checkin_entry += f"3. {review.priority3}\n"
                    checkin_entry += "\n"
            
            checkin_entry += "\n"
            
            with open(daily_log_file, 'a', encoding='utf-8') as f:
                f.write(checkin_entry)
            logger.info(f"Added check-in to daily log: {daily_log_file}")
            
            # Also log weather if requested
            if review.log_weather and review.type == "morning":
                try:
                    weather_cmd = Path.home() / "code" / "dotfiles" / "bin" / "gtd-log-weather"
                    if weather_cmd.exists() and weather_cmd.is_file():
                        import subprocess
                        # Run weather logging (non-interactive mode if possible)
                        subprocess.run([str(weather_cmd)], timeout=30, capture_output=True)
                except Exception as e:
                    logger.debug(f"Could not log weather: {e}")
        except Exception as e:
            logger.warning(f"Could not write to daily log {daily_log_file}: {e}")
            # Don't fail the request if daily log write fails
        
        # Broadcast update
        await manager.broadcast({
            "type": "status_update",
            "message": f"{review.type.capitalize()} review saved successfully"
        })
        
        return {
            "success": True,
            "message": f"{review.type.capitalize()} review saved successfully",
            "file": str(review_file.name)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error saving daily review: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/daily-log")
async def add_daily_log_entry(log_entry: DailyLogEntry):
    """Add an entry to the daily log"""
    try:
        from datetime import datetime
        
        if not log_entry.entry or not log_entry.entry.strip():
            raise HTTPException(status_code=400, detail="Entry cannot be empty")
        
        today = datetime.now().strftime("%Y-%m-%d")
        now = datetime.now().strftime("%H:%M")
        
        # Get daily log directory
        daily_log_dir = get_daily_log_dir()
        daily_log_file = daily_log_dir / f"{today}.md"
        
        # Create directory if it doesn't exist
        daily_log_dir.mkdir(parents=True, exist_ok=True)
        
        # Create file with header if it doesn't exist
        if not daily_log_file.exists():
            with open(daily_log_file, 'w', encoding='utf-8') as f:
                f.write(f"# Daily Log - {today}\n\n")
        
        # Append the entry with timestamp (matching CLI format)
        entry_text = f"{now} - {log_entry.entry.strip()}\n"
        
        with open(daily_log_file, 'a', encoding='utf-8') as f:
            f.write(entry_text)
        
        logger.info(f"Added daily log entry: {daily_log_file}")
        
        # Broadcast update
        await manager.broadcast({
            "type": "status_update",
            "message": "Daily log entry added"
        })
        
        return {
            "success": True,
            "message": "Daily log entry added successfully",
            "file": str(daily_log_file.name),
            "timestamp": now
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding daily log entry: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/habits/{habit_name}/complete")
async def complete_habit(habit_name: str):
    """Complete a habit (log it for today)"""
    try:
        from datetime import datetime
        
        # Find habit file
        habit_slug = habit_name.lower().replace(' ', '-')
        # Remove special characters
        import re
        habit_slug = re.sub(r'[^a-z0-9-]', '', habit_slug)
        habit_file = HABITS_PATH / f"{habit_slug}.md"
        
        if not habit_file.exists():
            # Try to find by name in habit files
            found = False
            if HABITS_PATH.exists():
                for h_file in HABITS_PATH.glob("*.md"):
                    try:
                        with open(h_file, 'r') as f:
                            content = f.read()
                            # Check if name matches
                            for line in content.split('\n'):
                                if line.startswith('name:'):
                                    file_name = line.split(':', 1)[1].strip()
                                    if file_name.lower() == habit_name.lower():
                                        habit_file = h_file
                                        found = True
                                        break
                        if found:
                            break
                    except:
                        continue
            
            if not found:
                raise HTTPException(status_code=404, detail=f"Habit '{habit_name}' not found")
        
        # Read habit file
        with open(habit_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Parse habit data
        today = datetime.now().strftime("%Y-%m-%d")
        now = datetime.now().strftime("%H:%M")
        
        # Check if already completed today
        for line in content.split('\n'):
            if line.startswith('last_completed:'):
                last_completed = line.split(':', 1)[1].strip()
                if last_completed == today:
                    return {"success": True, "message": f"Habit '{habit_name}' already logged for today"}
        
        # Update habit file using gtd-habit command
        try:
            import subprocess
            gtd_habit_cmd = Path.home() / "code" / "dotfiles" / "bin" / "gtd-habit"
            if not gtd_habit_cmd.exists():
                gtd_habit_cmd = Path.home() / "code" / "personal" / "dotfiles" / "bin" / "gtd-habit"
            
            if gtd_habit_cmd.exists():
                result = subprocess.run(
                    [str(gtd_habit_cmd), "log", habit_name],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                if result.returncode == 0:
                    return {"success": True, "message": f"Habit '{habit_name}' completed successfully"}
                else:
                    logger.warning(f"gtd-habit command failed: {result.stderr}")
            else:
                # Fallback: update file directly
                logger.warning("gtd-habit command not found, updating file directly")
                # This is a simplified version - full logic is in gtd-habit script
                # For now, just update last_completed
                updated_content = content
                if 'last_completed:' in content:
                    import re
                    updated_content = re.sub(
                        r'^last_completed:.*$',
                        f'last_completed: {today}',
                        updated_content,
                        flags=re.MULTILINE
                    )
                else:
                    # Add last_completed after frontmatter
                    if '---' in updated_content:
                        parts = updated_content.split('---', 2)
                        if len(parts) >= 3:
                            updated_content = f"{parts[0]}---{parts[1]}---\nlast_completed: {today}\n{parts[2]}"
                
                with open(habit_file, 'w', encoding='utf-8') as f:
                    f.write(updated_content)
                
                return {"success": True, "message": f"Habit '{habit_name}' completed successfully"}
        except Exception as e:
            logger.error(f"Error completing habit: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to complete habit: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing habit: {e}")
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
        
        # Get all JSON result files (exclude archived directory)
        archived_dir = ADVICE_RESULTS_DIR / "archived"
        for result_file in sorted(ADVICE_RESULTS_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
            # Skip if file is in archived directory (shouldn't happen with glob, but double-check)
            if archived_dir in result_file.parents:
                continue
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
                
                # Get thinking content if available (don't include in list view, only in detail view)
                result_item = {
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
                }
                
                # Add thinking flag (but not content in list view)
                thinking_file = ADVICE_RESULTS_DIR / f"{result_id}_thinking.txt"
                if thinking_file.exists() or "thinking" in data:
                    result_item["has_thinking"] = True
                
                results.append(result_item)
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
        
        # Get thinking content if available
        thinking_file = ADVICE_RESULTS_DIR / f"{result_id}_thinking.txt"
        thinking_text = ""
        if thinking_file.exists():
            with open(thinking_file, 'r', encoding='utf-8') as f:
                thinking_text = f.read()
        elif "thinking" in data:
            thinking_text = data.get("thinking", "")
        
        result = {
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
        
        # Add thinking if available
        if thinking_text:
            result["thinking"] = thinking_text
        
        return result
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

@app.get("/api/queue-status/{request_id}")
async def get_queue_status(request_id: str):
    """Get the queue status for an Ollama Controller request"""
    try:
        # Import the queue status function
        sys.path.insert(0, str(GTD_BASE / "zsh" / "functions"))
        from gtd_ai_helpers import get_queue_status, is_ollama_controller_url
        
        # Get the Ollama Controller URL from config
        ollama_url = os.getenv("OLLAMA_URL", "http://127.0.0.1:31080/v1/chat/completions")
        
        # Check if using Ollama Controller
        if not is_ollama_controller_url(ollama_url):
            return {
                "status": "not_applicable",
                "message": "Not using Ollama Controller",
                "request_id": request_id
            }
        
        # Extract base URL
        base_url = ollama_url.rsplit('/v1', 1)[0]
        
        # Get queue status
        queue_status = get_queue_status(request_id, base_url)
        
        return queue_status
    except Exception as e:
        logger.error(f"Error getting queue status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Advice Request Models
class AdviceRequest(BaseModel):
    persona: str
    question: str
    mode: str = "normal"  # normal, random, simple, all, daily-log
    web_search: bool = False
    background: bool = False  # If True, queue for background processing

class AdviceReadyNotification(BaseModel):
    request_id: str
    persona: str
    question: str

# Advice Endpoints
@app.post("/api/advice")
async def create_advice_request(request: AdviceRequest):
    """Create an advice request (foreground or background)"""
    try:
        if request.background:
            # Queue for background processing - try RabbitMQ first, fall back to file queue
            request_id = f"advice_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{os.getpid()}"
            
            request_data = {
                "id": request_id,
                "persona": request.persona,
                "question": request.question,
                "mode": request.mode,
                "web_search": str(request.web_search).lower(),
                "priority": 20,
                "created_at": datetime.now().isoformat() + "Z"
            }
            
            # Try RabbitMQ first
            queued_to_rabbitmq = False
            rabbitmq_error = None
            
            try:
                # Import pika for RabbitMQ
                import pika
                pika_available = True
            except ImportError:
                pika_available = False
                rabbitmq_error = "pika not installed"
                logger.warning("pika not available, cannot use RabbitMQ")
            
            if pika_available:
                # Read RabbitMQ config - try multiple paths
                config_paths = [
                    Path.home() / "code" / "dotfiles" / "zsh" / "functions",
                    Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions",
                    GTD_BASE / "zsh" / "functions",
                ]
                
                db_config = None
                for config_path in config_paths:
                    if config_path.exists():
                        sys.path.insert(0, str(config_path))
                        try:
                            from gtd_vector_db import read_database_config
                            db_config = read_database_config()
                            logger.info(f"✅ Read config from: {config_path}")
                            break
                        except Exception as e:
                            logger.debug(f"Could not read config from {config_path}: {e}")
                            continue
                
                if db_config:
                    rabbitmq_enabled = db_config.get("rabbitmq_enabled", False)
                    rabbitmq_url = db_config.get("rabbitmq_url", "amqp://localhost:5672")
                    logger.info(f"✅ RabbitMQ config loaded: enabled={rabbitmq_enabled}, url={rabbitmq_url}")
                else:
                    logger.warning("⚠️  Could not read database config from any path, using env vars")
                    rabbitmq_enabled = os.getenv("GTD_RABBITMQ_ENABLED", "false").lower() == "true"
                    rabbitmq_url = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
                    logger.info(f"Using env vars: enabled={rabbitmq_enabled}, url={rabbitmq_url}")
                
                # Log the decision
                if not rabbitmq_enabled:
                    logger.warning(f"⚠️  RabbitMQ is DISABLED in config (rabbitmq_enabled={rabbitmq_enabled})")
                    rabbitmq_error = f"RabbitMQ disabled in config (rabbitmq_enabled={rabbitmq_enabled})"
                
                if rabbitmq_enabled:
                    try:
                        logger.info(f"Attempting to connect to RabbitMQ at {rabbitmq_url}")
                        params = pika.URLParameters(rabbitmq_url)
                        params.blocked_connection_timeout = 5
                        connection = pika.BlockingConnection(params)
                        channel = connection.channel()
                        channel.queue_declare(queue="gtd_advice", durable=True)
                        
                        channel.basic_publish(
                            exchange='',
                            routing_key="gtd_advice",
                            body=json.dumps(request_data),
                            properties=pika.BasicProperties(
                                delivery_mode=2,  # Make message persistent
                            )
                        )
                        connection.close()
                        queued_to_rabbitmq = True
                        logger.info(f"✅ Advice request {request_id} queued to RabbitMQ successfully")
                    except Exception as e:
                        rabbitmq_error = str(e)
                        logger.error(f"❌ Failed to queue to RabbitMQ: {e}")
                        logger.error(f"   Error type: {type(e).__name__}")
                        logger.error(f"   URL attempted: {rabbitmq_url}")
                        import traceback
                        logger.error(f"   Traceback: {traceback.format_exc()}")
                        # Also log to stderr so it appears in console
                        print(f"ERROR: Failed to queue to RabbitMQ: {e}", file=sys.stderr)
                        print(f"  URL: {rabbitmq_url}", file=sys.stderr)
                else:
                    rabbitmq_error = "RabbitMQ not enabled in config"
                    logger.warning(f"RabbitMQ not enabled (rabbitmq_enabled={rabbitmq_enabled})")
            else:
                rabbitmq_error = "pika not installed"
            
            # Fallback to file queue if RabbitMQ failed
            if not queued_to_rabbitmq:
                queue_file = GTD_DATA_BASE / "advice_queue.jsonl"
                queue_file.parent.mkdir(parents=True, exist_ok=True)
                
                with open(queue_file, 'a') as f:
                    f.write(json.dumps(request_data) + '\n')
                
                logger.info(f"Advice request {request_id} queued to file queue")
            
            await manager.broadcast({
                "type": "status_update",
                "message": "Advice request queued"
            })
            
            queue_type = "RabbitMQ" if queued_to_rabbitmq else "file queue"
            message = f"Advice request queued for background processing ({queue_type})"
            
            # Include error info in response if RabbitMQ failed
            if not queued_to_rabbitmq and rabbitmq_error:
                logger.warning(f"Using file queue. Reason: {rabbitmq_error}")
                # Don't expose internal errors to user, but log them
            
            return {
                "success": True,
                "request_id": request_id,
                "message": message,
                "queue_type": queue_type,
                "rabbitmq_error": rabbitmq_error if not queued_to_rabbitmq else None
            }
        else:
            # Process immediately (foreground)
            gtd_advise_cmd = GTD_BASE / "bin" / "gtd-advise"
            if not gtd_advise_cmd.exists():
                gtd_advise_cmd = Path.home() / "code" / "personal" / "dotfiles" / "bin" / "gtd-advise"
            
            if not gtd_advise_cmd.exists():
                raise HTTPException(status_code=500, detail="gtd-advise command not found")
            
            # Build command based on mode
            cmd_args = []
            if request.mode == "random":
                cmd_args = ["--random"]
            elif request.mode == "simple":
                cmd_args = ["--simple"]
                if request.web_search:
                    cmd_args.append("--web-search")
                cmd_args.append(request.persona)
            elif request.mode == "all":
                cmd_args = ["--all"]
            elif request.mode == "daily-log":
                cmd_args = ["--daily-log"]
            else:
                cmd_args = [request.persona]
            
            # Execute command
            result = subprocess.run(
                [str(gtd_advise_cmd)] + cmd_args + [request.question],
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0:
                return {
                    "success": True,
                    "answer": result.stdout,
                    "message": "Advice received successfully"
                }
            else:
                raise HTTPException(
                    status_code=400,
                    detail=result.stderr or "Failed to get advice"
                )
    except HTTPException:
        raise
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="Advice request timed out")
    except Exception as e:
        logger.error(f"Error creating advice request: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/advice/config")
async def get_advice_config():
    """Get advice queue configuration (for diagnostics)"""
    try:
        config_info = {
            "pika_available": False,
            "rabbitmq_enabled": False,
            "rabbitmq_url": None,
            "queue_type": "unknown"
        }
        
        # Check if pika is available
        try:
            import pika
            config_info["pika_available"] = True
        except ImportError:
            pass
        
        # Try to read config
        config_paths = [
            Path.home() / "code" / "dotfiles" / "zsh" / "functions",
            Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions",
            GTD_BASE / "zsh" / "functions",
        ]
        
        for config_path in config_paths:
            if config_path.exists():
                sys.path.insert(0, str(config_path))
                try:
                    from gtd_vector_db import read_database_config
                    db_config = read_database_config()
                    config_info["rabbitmq_enabled"] = db_config.get("rabbitmq_enabled", False)
                    config_info["rabbitmq_url"] = db_config.get("rabbitmq_url", "amqp://localhost:5672")
                    config_info["config_source"] = str(config_path)
                    break
                except Exception as e:
                    logger.debug(f"Could not read config from {config_path}: {e}")
                    continue
        
        # Determine queue type
        if config_info["pika_available"] and config_info["rabbitmq_enabled"]:
            config_info["queue_type"] = "RabbitMQ"
        else:
            config_info["queue_type"] = "file queue"
            if not config_info["pika_available"]:
                config_info["reason"] = "pika not installed"
            elif not config_info["rabbitmq_enabled"]:
                config_info["reason"] = "rabbitmq_enabled=false in config"
        
        return config_info
    except Exception as e:
        logger.error(f"Error getting advice config: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/advice/personas")
async def get_personas():
    """Get list of available personas"""
    personas = [
        "hank", "david", "cal", "james", "marie", "warren", "sheryl", "tim",
        "george", "john", "jon", "bob", "fred", "louiza",
        "spiderman", "ironman", "squirrelgirl", "harley", "deadpool", "rogue",
        "esther", "gottman", "gary", "brene", "romance",
        "kettlebell", "maxfit", "dumbbell", "dipbar", "kelsey", "kent", "charity",
        "rich", "goggins", "dean", "bioneer", "harry", "murphy", "joe",
        "skippy", "sherlock", "picard", "sandy", "spongebob",
        "matt", "brennan", "chris", "aabria", "jeremy", "kingmaker-char"
    ]
    return {"personas": personas}

# Tool Execution Endpoint (for Ollama Controller callbacks)
class ToolExecutionRequest(BaseModel):
    type: str  # Should be "tool_execution"
    tool_calls: List[Dict[str, Any]]  # List of tool calls to execute
    request_id: Optional[str] = None  # Optional request ID for tracking

@app.post("/api/tools/execute")
async def execute_tools(request: ToolExecutionRequest):
    """Execute tools requested by Ollama Controller (tool_execution callback)"""
    try:
        if request.type != "tool_execution":
            raise HTTPException(status_code=400, detail=f"Invalid request type: {request.type}. Expected 'tool_execution'")
        
        if not request.tool_calls:
            raise HTTPException(status_code=400, detail="No tool calls provided")
        
        logger.info(f"Executing {len(request.tool_calls)} tool(s) for request {request.request_id or 'unknown'}")
        
        # Import tool registry
        functions_dir = GTD_BASE / "zsh" / "functions"
        if not functions_dir.exists():
            functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
        
        if not functions_dir.exists():
            raise HTTPException(status_code=500, detail="Tool registry not found")
        
        if str(functions_dir) not in sys.path:
            sys.path.insert(0, str(functions_dir))
        
        try:
            from gtd_tool_registry import execute_tool
        except ImportError:
            raise HTTPException(status_code=500, detail="Failed to import tool registry")
        
        # Execute each tool call
        tool_results = []
        for tool_call in request.tool_calls:
            # Extract tool call information
            function_info = tool_call.get("function", {})
            function_name = function_info.get("name", "")
            function_args = function_info.get("arguments", {})
            tool_call_id = tool_call.get("id", "")
            
            if not function_name:
                tool_results.append({
                    "role": "tool",
                    "tool_call_id": tool_call_id,
                    "name": "unknown",
                    "content": "Error: No function name provided"
                })
                continue
            
            # Parse arguments if they're a string
            if isinstance(function_args, str):
                try:
                    function_args = json.loads(function_args)
                except json.JSONDecodeError:
                    function_args = {}
            
            # Handle case where arguments might be wrapped in an "argument" key
            # This can happen if the Ollama Controller sends arguments in a different format
            if isinstance(function_args, dict) and "argument" in function_args and len(function_args) == 1:
                # Unwrap: {"argument": "{\"key\": \"value\"}"} -> {"key": "value"}
                argument_value = function_args["argument"]
                if isinstance(argument_value, str):
                    try:
                        function_args = json.loads(argument_value)
                    except json.JSONDecodeError:
                        # If parsing fails, try using the string as-is
                        function_args = {"argument": argument_value}
                else:
                    function_args = argument_value
            
            # Execute the tool
            try:
                logger.info(f"Executing tool: {function_name} with args: {function_args}")
                tool_result = execute_tool(function_name, function_args)
                
                tool_results.append({
                    "role": "tool",
                    "tool_call_id": tool_call_id,
                    "name": function_name,
                    "content": tool_result
                })
                logger.info(f"Tool {function_name} executed successfully ({len(tool_result)} chars)")
            except Exception as e:
                error_msg = f"Error executing tool '{function_name}': {str(e)}"
                logger.error(error_msg)
                tool_results.append({
                    "role": "tool",
                    "tool_call_id": tool_call_id,
                    "name": function_name,
                    "content": error_msg
                })
        
        # Return results in OpenAI-compatible format
        return {
            "type": "tool_execution_result",
            "request_id": request.request_id,
            "tool_results": tool_results
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error executing tools: {e}")
        raise HTTPException(status_code=500, detail=f"Error executing tools: {str(e)}")

@app.post("/api/advice/notify-ready")
async def notify_advice_ready(notification: AdviceReadyNotification):
    """Notify that an advice request has completed (called by advice worker)"""
    try:
        logger.info(f"Received advice ready notification for request {notification.request_id} from persona {notification.persona}")
        logger.info(f"Active WebSocket connections: {len(manager.active_connections)}")
        
        # Broadcast WebSocket message to all connected clients
        message = {
            "type": "advice_ready",
            "request_id": notification.request_id,
            "persona": notification.persona,
            "question": notification.question
        }
        await manager.broadcast(message)
        logger.info(f"Broadcasted advice_ready message to {len(manager.active_connections)} client(s)")
        
        # Also trigger a status update to refresh the advice count
        await manager.broadcast({
            "type": "status_update",
            "message": "New advice result available"
        })
        logger.info(f"Broadcasted status_update message")
        
        logger.info(f"✅ Successfully notified {len(manager.active_connections)} client(s) that advice {notification.request_id} is ready")
        return {
            "success": True,
            "message": "Notification sent",
            "clients_notified": len(manager.active_connections)
        }
    except Exception as e:
        logger.error(f"Error notifying advice ready: {e}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))

# Habits Endpoints
@app.get("/api/habits")
async def get_habits():
    """Get list of all habits"""
    try:
        from datetime import datetime
        habits = []
        today = datetime.now().strftime("%Y-%m-%d")
        
        if not HABITS_PATH.exists():
            return {"habits": []}
        
        for habit_file in HABITS_PATH.glob("*.md"):
            try:
                with open(habit_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Parse habit data
                habit_data = {
                    "name": habit_file.stem,
                    "slug": habit_file.stem,
                    "status": "active",
                    "frequency": "daily",
                    "time_of_day": "",
                    "last_completed": "",
                    "description": ""
                }
                
                for line in content.split('\n'):
                    if line.startswith("name:"):
                        habit_data["name"] = line.split(":", 1)[1].strip()
                    elif line.startswith("status:"):
                        habit_data["status"] = line.split(":", 1)[1].strip()
                    elif line.startswith("frequency:"):
                        habit_data["frequency"] = line.split(":", 1)[1].strip()
                    elif line.startswith("time_of_day:"):
                        habit_data["time_of_day"] = line.split(":", 1)[1].strip()
                    elif line.startswith("last_completed:"):
                        habit_data["last_completed"] = line.split(":", 1)[1].strip()
                    elif line.startswith("description:"):
                        habit_data["description"] = line.split(":", 1)[1].strip()
                
                # Check if due today
                habit_data["due_today"] = (
                    habit_data["status"] == "active" and
                    habit_data["frequency"] == "daily" and
                    habit_data["last_completed"] != today
                )
                
                habits.append(habit_data)
            except Exception as e:
                logger.warning(f"Error reading habit file {habit_file}: {e}")
                continue
        
        return {"habits": habits}
    except Exception as e:
        logger.error(f"Error getting habits: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# AI Suggestions Endpoint
@app.get("/api/ai-suggestions")
async def get_ai_suggestions():
    """Get AI suggestions based on recent logs"""
    try:
        from datetime import datetime
        suggestions_dir = GTD_DATA_BASE / "checkin_suggestions"
        today = datetime.now().strftime("%Y-%m-%d")
        
        morning_file = suggestions_dir / f"morning_{today}.txt"
        evening_file = suggestions_dir / f"evening_{today}.txt"
        
        suggestions = []
        
        if morning_file.exists():
            with open(morning_file, 'r', encoding='utf-8') as f:
                suggestions.append({
                    "type": "morning",
                    "date": today,
                    "content": f.read()
                })
        
        if evening_file.exists():
            with open(evening_file, 'r', encoding='utf-8') as f:
                suggestions.append({
                    "type": "evening",
                    "date": today,
                    "content": f.read()
                })
        
        # Also check for general suggestions
        suggestions_dir_general = GTD_DATA_BASE / "suggestions"
        if suggestions_dir_general.exists():
            for suggestion_file in sorted(suggestions_dir_general.glob("*.json"), reverse=True)[:10]:
                try:
                    with open(suggestion_file, 'r') as f:
                        data = json.load(f)
                        if data.get("status") != "accepted" and data.get("status") != "dismissed":
                            suggestions.append({
                                "type": "general",
                                "id": suggestion_file.stem,
                                "title": data.get("title", ""),
                                "content": data.get("content", ""),
                                "confidence": data.get("confidence", 0),
                                "created_at": data.get("created_at", "")
                            })
                except:
                    continue
        
        return {"suggestions": suggestions}
    except Exception as e:
        logger.error(f"Error getting AI suggestions: {e}")
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
    # Allow binding to all interfaces if TAILSCALE_DOMAIN is set (for direct access)
    # Otherwise, bind to localhost only (nginx will proxy)
    host = os.getenv("GTD_BIND_HOST", "127.0.0.1")
    port = int(os.getenv("GTD_BIND_PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
