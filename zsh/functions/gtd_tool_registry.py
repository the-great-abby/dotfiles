#!/usr/bin/env python3
"""
GTD Tool Registry - Centralized tool definitions for AI tool calling

This module provides a registry of available tools that can be called by
thinking models with tool call support. Tools are organized by category
and can be extended by other parts of the GTD system.
"""

from typing import Dict, List, Any, Callable, Optional
import json
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Tool registry - maps tool names to their definitions and handlers
TOOL_REGISTRY: Dict[str, Dict[str, Any]] = {}


def register_tool(
    name: str,
    description: str,
    parameters: Dict[str, Any],
    handler: Optional[Callable] = None,
    category: str = "general"
):
    """
    Register a tool that can be called by AI models.
    
    Args:
        name: Tool name (e.g., "perform_web_search")
        description: Tool description for the AI model
        parameters: JSON Schema for parameters
        handler: Optional function to handle tool calls (if None, must be handled externally)
        category: Tool category (e.g., "gtd", "web", "research")
    """
    TOOL_REGISTRY[name] = {
        "name": name,
        "description": description,
        "parameters": parameters,
        "handler": handler,
        "category": category
    }


def get_tool_definitions(categories: Optional[List[str]] = None) -> List[Dict[str, Any]]:
    """
    Get OpenAI-compatible tool definitions for specified categories.
    
    Args:
        categories: List of categories to include (None = all)
    
    Returns:
        List of tool definitions in OpenAI format
    """
    tools = []
    for tool_name, tool_info in TOOL_REGISTRY.items():
        if categories is None or tool_info["category"] in categories:
            tools.append({
                "type": "function",
                "function": {
                    "name": tool_name,
                    "description": tool_info["description"],
                    "parameters": tool_info["parameters"]
                }
            })
    return tools


def execute_tool(tool_name: str, arguments: Dict[str, Any]) -> str:
    """
    Execute a registered tool.
    
    Args:
        tool_name: Name of the tool to execute
        arguments: Tool arguments
    
    Returns:
        Tool result as string
    """
    if tool_name not in TOOL_REGISTRY:
        return f"Error: Unknown tool '{tool_name}'"
    
    tool_info = TOOL_REGISTRY[tool_name]
    handler = tool_info.get("handler")
    
    if handler:
        try:
            result = handler(**arguments)
            return result if isinstance(result, str) else json.dumps(result)
        except Exception as e:
            return f"Error executing tool '{tool_name}': {str(e)}"
    else:
        return f"Error: Tool '{tool_name}' has no handler registered"


# Register web search tool
def _web_search_handler(query: str) -> str:
    """Handler for web search tool."""
    from zsh.functions.gtd_persona_helper import execute_web_search, read_config, _extract_user_context
    # Get config and context for enhanced search
    config = read_config()
    context = _extract_user_context(config)
    return execute_web_search(query, use_enhanced_search=True, context=context)


register_tool(
    name="perform_web_search",
    description="Perform a web search to get current, accurate information. Use this tool to answer factual questions that require up-to-date data. ALWAYS use this tool when asked about historical events, sports results, current facts, or any information that might change over time.",
    parameters={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "The search query to perform (e.g., 'who won the 1967 world series')"
            }
        },
        "required": ["query"]
    },
    handler=_web_search_handler,
    category="web"
)


# Register GTD tools - these will call MCP server functions
def _gtd_list_tasks_handler(context: Optional[str] = None, 
                           energy: Optional[str] = None,
                           priority: Optional[str] = None,
                           project: Optional[str] = None,
                           status: str = "active",
                           limit: int = 50) -> str:
    """Handler for listing GTD tasks."""
    try:
        # Import MCP server helper functions directly
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_mcp_server.py"
        if not mcp_path.exists():
            # Try alternative path
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_mcp_server.py"
        
        if mcp_path.exists():
            # Import functions from MCP server module
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_mcp_server", mcp_path)
            mcp_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mcp_module)
            
            find_all_task_files = mcp_module.find_all_task_files
            read_task_file = mcp_module.read_task_file
        else:
            # Fallback: implement basic task reading
            def find_all_task_files():
                gtd_base_dir = Path.home() / "Documents" / "gtd"
                tasks_dir = gtd_base_dir / "tasks"
                projects_dir = gtd_base_dir / "1-projects"
                tasks = []
                if tasks_dir.exists():
                    tasks.extend(tasks_dir.glob("*.md"))
                if projects_dir.exists():
                    for project_dir in projects_dir.iterdir():
                        if project_dir.is_dir():
                            tasks.extend(project_dir.glob("*.md"))
                return tasks
            
            def read_task_file(task_path):
                if not task_path.exists():
                    return {}
                # Simple frontmatter extraction
                frontmatter = {}
                content_lines = []
                in_frontmatter = False
                with open(task_path, 'r') as f:
                    for line in f:
                        if line.strip() == "---":
                            in_frontmatter = not in_frontmatter
                            continue
                        if in_frontmatter and ':' in line:
                            key, value = line.split(':', 1)
                            frontmatter[key.strip()] = value.strip().strip('"').strip("'")
                        elif not in_frontmatter:
                            content_lines.append(line)
                
                # Extract title from content
                title = ""
                for line in content_lines:
                    if line.startswith('# '):
                        title = line[2:].strip()
                        break
                
                return {
                    "id": task_path.stem,
                    "path": str(task_path),
                    "title": title,
                    "type": frontmatter.get("type", "task"),
                    "status": frontmatter.get("status", "active"),
                    "context": frontmatter.get("context", ""),
                    "energy": frontmatter.get("energy", ""),
                    "priority": frontmatter.get("priority", ""),
                    "project": frontmatter.get("project", ""),
                }
        
        # Call the functions
        tasks = []
        task_files = find_all_task_files()
        
        for task_file in task_files:
            task_data = read_task_file(task_file)
            
            # Apply filters
            if task_data.get("status") != status:
                continue
            if context and task_data.get("context") != context:
                continue
            if energy and task_data.get("energy") != energy:
                continue
            if priority and task_data.get("priority") != priority:
                continue
            if project:
                task_project = task_data.get("project", "")
                if not task_project or task_project != project:
                    continue
            
            tasks.append({k: v for k, v in task_data.items() if k != "content"})
            
            if len(tasks) >= limit:
                break
        
        return json.dumps({
            "tasks": tasks,
            "count": len(tasks),
            "filters": {
                "context": context,
                "energy": energy,
                "priority": priority,
                "project": project,
                "status": status
            }
        }, default=str)
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error listing tasks: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_list_tasks",
    description="List tasks from the GTD system with optional filters. Use this to see what tasks are available, check task status, or find tasks by context, energy level, priority, or project.",
    parameters={
        "type": "object",
        "properties": {
            "context": {
                "type": "string",
                "description": "Filter by context (home, office, computer, phone, errands)"
            },
            "energy": {
                "type": "string",
                "description": "Filter by energy level (low, medium, high, creative, administrative)"
            },
            "priority": {
                "type": "string",
                "description": "Filter by priority (urgent_important, not_urgent_important, etc.)"
            },
            "project": {
                "type": "string",
                "description": "Filter by project name"
            },
            "status": {
                "type": "string",
                "description": "Filter by status (active, on-hold, done). Default: active"
            },
            "limit": {
                "type": "number",
                "description": "Maximum number of tasks to return (default: 50)"
            }
        }
    },
    handler=_gtd_list_tasks_handler,
    category="gtd"
)


def _gtd_create_task_handler(title: str,
                            project: Optional[str] = None,
                            context: str = "computer",
                            priority: str = "not_urgent_important",
                            notes: Optional[str] = None) -> str:
    """Handler for creating a GTD task."""
    try:
        import subprocess
        from pathlib import Path
        
        # Get GTD base dir from config
        gtd_base_dir = Path.home() / "Documents" / "gtd"
        config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config"
        if config_file.exists():
            with open(config_file) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        if key == "GTD_BASE_DIR":
                            gtd_base_dir = Path(value.replace("$HOME", str(Path.home())))
                            break
        
        cmd = [
            "gtd-task", "add",
            "--context", context,
            "--priority", priority,
            "--non-interactive",
            title
        ]
        
        if project:
            cmd.extend(["--project", project])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(gtd_base_dir.parent)
        )
        
        if result.returncode == 0:
            return json.dumps({
                "success": True,
                "message": "Task created successfully",
                "output": result.stdout
            })
        else:
            return json.dumps({
                "error": f"Failed to create task: {result.stderr}",
                "output": result.stdout
            })
    except Exception as e:
        return f"Error creating task: {str(e)}"


register_tool(
    name="gtd_create_task",
    description="Create a new task in the GTD system. Use this when the user wants to add a task, when processing suggestions, or when breaking down projects into actionable items.",
    parameters={
        "type": "object",
        "properties": {
            "title": {
                "type": "string",
                "description": "Task title/description"
            },
            "project": {
                "type": "string",
                "description": "Optional project name to assign task to"
            },
            "context": {
                "type": "string",
                "description": "Optional context (home, office, computer, phone, errands). Default: computer"
            },
            "priority": {
                "type": "string",
                "description": "Optional priority (urgent_important, not_urgent_important, urgent_not_important, not_urgent_not_important). Default: not_urgent_important"
            },
            "notes": {
                "type": "string",
                "description": "Optional notes or additional details"
            }
        },
        "required": ["title"]
    },
    handler=_gtd_create_task_handler,
    category="gtd"
)


def _gtd_list_projects_handler(status: str = "active") -> str:
    """Handler for listing GTD projects."""
    try:
        # Try to import from MCP server, with fallback
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_mcp_server.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_mcp_server.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_mcp_server", mcp_path)
            mcp_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mcp_module)
            read_project_file = mcp_module.read_project_file
        else:
            # Fallback implementation
            def read_project_file(project_path):
                readme_path = project_path / "README.md"
                if not readme_path.exists():
                    return {}
                frontmatter = {}
                in_frontmatter = False
                with open(readme_path, 'r') as f:
                    for line in f:
                        if line.strip() == "---":
                            in_frontmatter = not in_frontmatter
                            continue
                        if in_frontmatter and ':' in line:
                            key, value = line.split(':', 1)
                            frontmatter[key.strip()] = value.strip().strip('"').strip("'")
                
                task_count = len([f for f in project_path.glob("*.md") if f.name != "README.md"])
                return {
                    "name": project_path.name,
                    "path": str(project_path),
                    "type": frontmatter.get("type", "project"),
                    "status": frontmatter.get("status", "active"),
                    "created": frontmatter.get("created", ""),
                    "repository": frontmatter.get("repository", ""),
                    "task_count": task_count
                }
        
        gtd_base_dir = Path.home() / "Documents" / "gtd"
        projects_dir = gtd_base_dir / "1-projects"
        
        projects = []
        if projects_dir.exists():
            for project_dir in projects_dir.iterdir():
                if project_dir.is_dir():
                    project_data = read_project_file(project_dir)
                    if project_data:
                        if status == "all" or project_data.get("status") == status:
                            projects.append(project_data)
        
        return json.dumps({
            "projects": projects,
            "count": len(projects),
            "status_filter": status
        }, default=str)
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error listing projects: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_list_projects",
    description="List all projects in the GTD system. Use this to see what projects are active, check project status, or understand the user's current project portfolio.",
    parameters={
        "type": "object",
        "properties": {
            "status": {
                "type": "string",
                "description": "Filter by status (active, on-hold, done, all). Default: active"
            }
        }
    },
    handler=_gtd_list_projects_handler,
    category="gtd"
)


def _gtd_read_daily_log_handler(date: Optional[str] = None) -> str:
    """Handler for reading daily logs."""
    try:
        from datetime import datetime, timedelta
        from pathlib import Path
        import re
        
        # Parse date - handle relative dates like "3 days ago", "yesterday", "today"
        actual_date_str = None
        if date is None:
            actual_date_str = datetime.now().strftime("%Y-%m-%d")
        elif date.strip().lower() == "today":
            actual_date_str = datetime.now().strftime("%Y-%m-%d")
        elif date.strip().lower() == "yesterday":
            yesterday = datetime.now() - timedelta(days=1)
            actual_date_str = yesterday.strftime("%Y-%m-%d")
        elif re.match(r'^\d+ days? ago$', date.strip().lower()):
            # Parse "3 days ago" or "3 day ago"
            match = re.match(r'^(\d+) days? ago$', date.strip().lower())
            if match:
                days_ago = int(match.group(1))
                target_date = datetime.now() - timedelta(days=days_ago)
                actual_date_str = target_date.strftime("%Y-%m-%d")
            else:
                actual_date_str = datetime.now().strftime("%Y-%m-%d")
        elif re.match(r'^\d{4}-\d{2}-\d{2}$', date.strip()):
            # Already in YYYY-MM-DD format
            actual_date_str = date.strip()
        else:
            # Try to parse as relative date using datetime calculation
            # If it doesn't match known patterns, default to today
            actual_date_str = datetime.now().strftime("%Y-%m-%d")
        
        log_dir = Path.home() / "Documents" / "daily_logs"
        
        # Also check for config file that might specify a different directory
        config_file = Path.home() / ".daily_log_config"
        if not config_file.exists():
            config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".daily_log_config"
        if not config_file.exists():
            config_file = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".daily_log_config"
        
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    for line in f:
                        if line.strip().startswith("DAILY_LOG_DIR="):
                            log_dir_str = line.split("=", 1)[1].strip().strip('"').strip("'")
                            log_dir_str = log_dir_str.replace("$HOME", str(Path.home()))
                            log_dir = Path(log_dir_str)
                            break
            except Exception:
                pass  # Use default if config read fails
        
        # Try both .md and .txt extensions (check .md first as it's more common)
        log_file = None
        for ext in [".md", ".txt"]:
            candidate = log_dir / f"{actual_date_str}{ext}"
            if candidate.exists():
                log_file = candidate
                break
        
        if log_file and log_file.exists():
            with open(log_file, 'r', encoding='utf-8') as f:
                content = f.read()
            return json.dumps({
                "date": actual_date_str,
                "original_date_request": date,
                "content": content,
                "entry_count": len([l for l in content.split('\n') if l.strip() and not l.strip().startswith('#')]),
                "file_found": str(log_file.name),
                "file_path": str(log_file)
            })
        else:
            # Check if directory exists
            if not log_dir.exists():
                return json.dumps({
                    "date": actual_date_str,
                    "original_date_request": date,
                    "content": "",
                    "entry_count": 0,
                    "error": f"Log directory not found: {log_dir}"
                })
            # Check what files exist for debugging - show recent files
            existing_files = sorted(log_dir.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)[:5]
            # This is not necessarily an error - the log file might just not exist yet for this date
            return json.dumps({
                "date": actual_date_str,
                "original_date_request": date,
                "content": "",
                "entry_count": 0,
                "note": f"Log file not found for {actual_date_str} (requested: {date}). This is normal if no log was created for this date. Tried: {actual_date_str}.md and {actual_date_str}.txt",
                "log_directory": str(log_dir),
                "recent_log_files": [f.name for f in existing_files] if existing_files else [],
                "is_error": False  # Not an error, just informational
            })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error reading daily log: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_read_daily_log",
    description="Read daily log entries for a specific date. Supports multiple date formats: YYYY-MM-DD (e.g., '2026-01-19'), relative dates like 'today', 'yesterday', '3 days ago', or '1 week ago'. Use this to understand what the user has been working on, their recent activities, or to analyze patterns in their daily activities.",
    parameters={
        "type": "object",
        "properties": {
            "date": {
                "type": "string",
                "description": "Date in YYYY-MM-DD format (e.g., '2026-01-19'), or relative date like 'today', 'yesterday', '3 days ago', '1 week ago'. Default: 'today'"
            }
        }
    },
    handler=_gtd_read_daily_log_handler,
    category="gtd"
)


def _gtd_add_daily_log_entry_handler(entry: str, date: Optional[str] = None) -> str:
    """Handler for adding a daily log entry."""
    try:
        from datetime import datetime, timedelta
        from pathlib import Path
        import re
        import subprocess
        
        # Parse date - handle relative dates like "3 days ago", "yesterday", "today"
        actual_date_str = None
        if date is None:
            actual_date_str = datetime.now().strftime("%Y-%m-%d")
        elif date.strip().lower() == "today":
            actual_date_str = datetime.now().strftime("%Y-%m-%d")
        elif date.strip().lower() == "yesterday":
            yesterday = datetime.now() - timedelta(days=1)
            actual_date_str = yesterday.strftime("%Y-%m-%d")
        elif re.match(r'^\d+ days? ago$', date.strip().lower()):
            # Parse "3 days ago" or "3 day ago"
            match = re.match(r'^(\d+) days? ago$', date.strip().lower())
            if match:
                days_ago = int(match.group(1))
                target_date = datetime.now() - timedelta(days=days_ago)
                actual_date_str = target_date.strftime("%Y-%m-%d")
            else:
                actual_date_str = datetime.now().strftime("%Y-%m-%d")
        elif re.match(r'^\d{4}-\d{2}-\d{2}$', date.strip()):
            # Already in YYYY-MM-DD format
            actual_date_str = date.strip()
        else:
            # Try to parse as relative date using datetime calculation
            # If it doesn't match known patterns, default to today
            actual_date_str = datetime.now().strftime("%Y-%m-%d")
        
        # Get daily log directory from config
        log_dir = Path.home() / "Documents" / "daily_logs"
        
        # Check for config file that might specify a different directory
        config_file = Path.home() / ".daily_log_config"
        if not config_file.exists():
            config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".daily_log_config"
        if not config_file.exists():
            config_file = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".daily_log_config"
        
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    for line in f:
                        if line.strip().startswith("DAILY_LOG_DIR="):
                            log_dir_str = line.split("=", 1)[1].strip().strip('"').strip("'")
                            log_dir_str = log_dir_str.replace("$HOME", str(Path.home()))
                            log_dir = Path(log_dir_str)
                            break
            except Exception:
                pass  # Use default if config read fails
        
        # Create directory if it doesn't exist
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # Get current time
        current_time = datetime.now().strftime("%H:%M")
        
        # Determine log file path
        log_file = log_dir / f"{actual_date_str}.md"
        
        # Check if this is the first entry today (before adding the new entry)
        is_first_entry_today = False
        if not log_file.exists():
            is_first_entry_today = True
        else:
            # Count existing entries
            try:
                with open(log_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    entry_count = len([l for l in content.split('\n') 
                                     if re.match(r'^\d{2}:\d{2} -', l.strip())])
                    if entry_count == 0:
                        is_first_entry_today = True
            except Exception:
                is_first_entry_today = True
        
        # Create file with header if it doesn't exist
        if not log_file.exists():
            with open(log_file, 'w', encoding='utf-8') as f:
                f.write(f"# Daily Log - {actual_date_str}\n\n")
        
        # Append the entry with timestamp
        entry_text = f"{current_time} - {entry.strip()}\n"
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(entry_text)
        
        # Award gamification for daily log entry (only once per day, on first entry)
        # This runs in background to not slow down the response
        if is_first_entry_today:
            gamify_script = Path.home() / "code" / "dotfiles" / "bin" / "gtd-gamify-award"
            if not gamify_script.exists():
                gamify_script = Path.home() / "code" / "personal" / "dotfiles" / "bin" / "gtd-gamify-award"
            
            if gamify_script.exists():
                # Run in background
                subprocess.Popen(
                    [str(gamify_script), "daily_log", "", "Daily log entry", "daily_logging"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
        
        # Check if this is a workout/exercise entry and award additional XP
        exercise_keywords = ["workout", "exercise", "kettlebell", "walk", "run", "weight", 
                           "lifting", "gym", "fitness", "training", "cardio", "strength",
                           "squat", "deadlift", "press", "swing", "snatch", "clean", "row",
                           "bike", "cycling", "yoga", "stretch", "active", "movement"]
        
        entry_lower = entry.lower()
        if any(keyword in entry_lower for keyword in exercise_keywords):
            exercise_type = "exercise"
            if any(word in entry_lower for word in ["run", "running", "sprint", "intense", "hard", "heavy", "cardio"]):
                exercise_type = "exercise_intense"
            
            gamify_script = Path.home() / "code" / "dotfiles" / "bin" / "gtd-gamify-award"
            if not gamify_script.exists():
                gamify_script = Path.home() / "code" / "personal" / "dotfiles" / "bin" / "gtd-gamify-award"
            
            if gamify_script.exists():
                # Run in background
                subprocess.Popen(
                    [str(gamify_script), exercise_type, "", f"Logged exercise: {entry}", "exercise"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
        
        return json.dumps({
            "success": True,
            "message": "Daily log entry added successfully",
            "date": actual_date_str,
            "time": current_time,
            "entry": entry.strip(),
            "file": str(log_file.name),
            "file_path": str(log_file),
            "is_first_entry_today": is_first_entry_today
        })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error adding daily log entry: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_add_daily_log_entry",
    description="Add an entry to the daily log. Use this when the user wants to log an activity, thought, reflection, or any information to their daily log. Supports optional date parameter to add entries to past or future dates. The entry will be timestamped automatically.",
    parameters={
        "type": "object",
        "properties": {
            "entry": {
                "type": "string",
                "description": "The log entry text to add (e.g., 'Worked on project X', 'Had a great meeting with team', 'Feeling productive today')"
            },
            "date": {
                "type": "string",
                "description": "Optional date in YYYY-MM-DD format (e.g., '2026-01-19'), or relative date like 'today', 'yesterday', '3 days ago'. Default: 'today'"
            }
        },
        "required": ["entry"]
    },
    handler=_gtd_add_daily_log_entry_handler,
    category="gtd"
)


def _gtd_get_datetime_handler(relative_date: Optional[str] = None) -> str:
    """Handler for getting date and time, with optional relative date calculation.
    
    Args:
        relative_date: Optional relative date string like "3 days ago", "yesterday", 
                       "today", "1 week ago", etc. If None, returns current date/time.
    
    Returns:
        JSON string with date/time information
    """
    try:
        from datetime import datetime, timedelta, time as dt_time
        import re
        
        now = datetime.now()
        is_today = True
        
        # If relative_date is provided, parse it
        if relative_date and relative_date.strip():
            relative_date_str = relative_date.strip().lower()
            
            # Handle common cases
            if relative_date_str == "today":
                target_date = now
                is_today = True
            elif relative_date_str == "yesterday":
                target_date = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=1)
                is_today = False
            elif relative_date_str == "tomorrow":
                target_date = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
                is_today = False
            else:
                # Parse patterns like "3 days ago", "2 weeks ago", "1 month ago"
                # Pattern: <number> <unit> ago
                match = re.match(r'(\d+)\s+(day|days|week|weeks|month|months)\s+ago', relative_date_str)
                if match:
                    number = int(match.group(1))
                    unit = match.group(2)
                    
                    # Start from midnight of today, then subtract
                    base_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
                    
                    if unit in ('day', 'days'):
                        target_date = base_date - timedelta(days=number)
                    elif unit in ('week', 'weeks'):
                        target_date = base_date - timedelta(weeks=number)
                    elif unit in ('month', 'months'):
                        # Approximate months as 30 days
                        target_date = base_date - timedelta(days=number * 30)
                    is_today = False
                else:
                    # If we can't parse it, return current date and include the request in response
                    target_date = now
                    is_today = True
        else:
            target_date = now
            is_today = True
        
        return json.dumps({
            "date": target_date.strftime("%Y-%m-%d"),
            "time": target_date.strftime("%H:%M:%S") if is_today else "00:00:00",
            "datetime": target_date.isoformat(),
            "day_of_week": target_date.strftime("%A"),
            "day_of_month": target_date.day,
            "month": target_date.strftime("%B"),
            "year": target_date.year,
            "timestamp": target_date.timestamp(),
            "relative_date_requested": relative_date if relative_date and relative_date.strip().lower() != "today" else None,
            "is_current_date": is_today
        })
    except Exception as e:
        return json.dumps({"error": f"Error getting datetime: {str(e)}"})


register_tool(
    name="gtd_get_datetime",
    description="Get date and time information. Can return the current date/time, or calculate relative dates like '3 days ago', 'yesterday', '1 week ago', etc. Use this tool when the user asks about dates, 'today', 'yesterday', 'past X days', or any date-related questions. You can pass a relative date string like '3 days ago' to get that specific date calculated automatically. Examples: call with no arguments for today, or '3 days ago' for a date 3 days in the past.",
    parameters={
        "type": "object",
        "properties": {
            "relative_date": {
                "type": "string",
                "description": "Optional relative date string. Examples: 'today', 'yesterday', '3 days ago', '1 week ago', '2 months ago'. If not provided, returns current date/time."
            }
        }
    },
    handler=_gtd_get_datetime_handler,
    category="gtd"
)


# ============================================================================
# Agent Skills Tools
# ============================================================================

def _list_agent_skills_handler(query: Optional[str] = None, tags: Optional[List[str]] = None) -> str:
    """Handler for listing agent skills."""
    try:
        from pathlib import Path
        import sys
        
        # Import skills registry
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_skills.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_skills.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_skills", mcp_path)
            skills_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(skills_module)
            
            registry = skills_module.get_registry()
            
            if query or tags:
                skills = registry.search_skills(query=query, tags=tags)
            else:
                skills = registry.list_skills()
            
            return json.dumps({
                "skills": skills,
                "count": len(skills)
            }, default=str)
        else:
            return json.dumps({
                "error": "Skills module not found",
                "skills": [],
                "count": 0
            })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error listing skills: {str(e)}",
            "traceback": traceback.format_exc(),
            "skills": [],
            "count": 0
        })


def _get_agent_skill_handler(skill_name: str) -> str:
    """Handler for getting a specific skill."""
    try:
        from pathlib import Path
        import sys
        
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_skills.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_skills.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_skills", mcp_path)
            skills_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(skills_module)
            
            registry = skills_module.get_registry()
            skill = registry.get_skill(skill_name)
            
            if skill:
                return json.dumps({
                    "skill": skill.to_dict(),
                    "instructions": skill.instructions,
                    "metadata": skill.metadata
                }, default=str)
            else:
                available_skills = registry.list_skills()
                return json.dumps({
                    "error": f"Skill not found: {skill_name}",
                    "available_skills": [s["id"] for s in available_skills],
                    "available_skill_names": [s.get("metadata", {}).get("name", "") for s in available_skills]
                })
        else:
            return json.dumps({
                "error": "Skills module not found"
            })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error getting skill: {str(e)}",
            "traceback": traceback.format_exc()
        })


def _execute_agent_skill_handler(
    skill_name: str,
    method: str = "instructions",
    args: Optional[Dict[str, Any]] = None
) -> str:
    """Handler for executing an agent skill."""
    try:
        from pathlib import Path
        import sys
        
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_skills.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_skills.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_skills", mcp_path)
            skills_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(skills_module)
            
            registry = skills_module.get_registry()
            success, output, metadata = registry.execute_skill(
                skill_name=skill_name,
                method=method,
                args=args or {}
            )
            
            return json.dumps({
                "success": success,
                "output": output,
                "metadata": metadata
            }, default=str)
        else:
            return json.dumps({
                "error": "Skills module not found",
                "success": False
            })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error executing skill: {str(e)}",
            "traceback": traceback.format_exc(),
            "success": False
        })


# Register skill tools
register_tool(
    name="list_agent_skills",
    description="List all available Agent Skills. Skills are reusable workflows that guide how to use GTD tools to accomplish goals. Use this to discover what skills are available, then use get_agent_skill to read their instructions. Skills are particularly useful for complex workflows like morning check-ins, inbox processing, or daily reviews.",
    parameters={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Optional search query to filter skills by name or description (e.g., 'morning', 'review', 'inbox')"
            },
            "tags": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Optional list of tags to filter skills (e.g., ['morning', 'routine', 'productivity'])"
            }
        }
    },
    handler=_list_agent_skills_handler,
    category="skills"
)

register_tool(
    name="get_agent_skill",
    description="Get detailed information about a specific Agent Skill including its full instructions. Skills provide step-by-step workflows for using GTD tools. Use this to understand how to accomplish a goal using available tools. After getting the skill, follow its instructions step-by-step using the appropriate GTD tools.",
    parameters={
        "type": "object",
        "properties": {
            "skill_name": {
                "type": "string",
                "description": "Name of the skill to retrieve. Can be the skill folder name (e.g., 'morning-checkin') or the skill's display name (e.g., 'Morning Check-In'). Use list_agent_skills first to see available skills."
            }
        },
        "required": ["skill_name"]
    },
    handler=_get_agent_skill_handler,
    category="skills"
)

register_tool(
    name="execute_agent_skill",
    description="Execute an Agent Skill. Skills can return instructions (for AI to follow), execute scripts, or render templates. Most commonly, use method='instructions' to get the skill's workflow steps, then follow those steps using GTD tools. For script execution, use method='script:<script_name>'. For templates, use method='template:<template_name>'.",
    parameters={
        "type": "object",
        "properties": {
            "skill_name": {
                "type": "string",
                "description": "Name of the skill to execute (e.g., 'morning-checkin', 'inbox-processing')"
            },
            "method": {
                "type": "string",
                "description": "Execution method: 'instructions' (returns skill instructions for AI to follow - most common), 'script:<script_name>' (executes a script from the skill's scripts/ directory), or 'template:<template_name>' (renders a template from the skill's templates/ directory). Default: 'instructions'",
                "default": "instructions"
            },
            "args": {
                "type": "object",
                "description": "Optional arguments to pass to the skill (for scripts or templates). Not used for 'instructions' method."
            }
        },
        "required": ["skill_name"]
    },
    handler=_execute_agent_skill_handler,
    category="skills"
)


# ============================================================================
# Personalization Tools
# ============================================================================

def _gtd_get_personalization_handler(category: Optional[str] = None) -> str:
    """Handler for getting personalization data."""
    try:
        from pathlib import Path
        import json
        
        personalization_file = Path.home() / ".gtd_personalization.json"
        
        if not personalization_file.exists():
            return json.dumps({
                "error": "Personalization file not found",
                "message": "User has not set up personalization yet. Suggest running: gtd-wizard → option 67",
                "file_path": str(personalization_file)
            })
        
        with open(personalization_file, 'r') as f:
            data = json.load(f)
        
        # If category specified, return only that category
        if category:
            if category in data:
                return json.dumps({
                    "category": category,
                    "data": data[category],
                    "last_updated": data.get("last_updated")
                }, indent=2)
            else:
                return json.dumps({
                    "error": f"Category '{category}' not found",
                    "available_categories": list(data.keys())
                })
        
        # Return full data
        return json.dumps(data, indent=2)
    
    except json.JSONDecodeError as e:
        return json.dumps({
            "error": "Invalid JSON in personalization file",
            "message": str(e),
            "file_path": str(personalization_file)
        })
    except Exception as e:
        return json.dumps({
            "error": "Error reading personalization file",
            "message": str(e),
            "file_path": str(personalization_file) if 'personalization_file' in locals() else "unknown"
        })


def _gtd_update_personalization_handler(category: str, field: str, value: Any, operation: str = "set") -> str:
    """Handler for updating personalization data."""
    try:
        from pathlib import Path
        import json
        from datetime import datetime
        
        personalization_file = Path.home() / ".gtd_personalization.json"
        
        # Load existing data or create new
        if personalization_file.exists():
            with open(personalization_file, 'r') as f:
                data = json.load(f)
        else:
            # Initialize with basic structure
            data = {
                "created": datetime.now().isoformat(),
                "last_updated": datetime.now().isoformat(),
                "relationships": {},
                "goals": {"career": [], "personal": [], "financial": [], "learning": []},
                "values": [],
                "energy_patterns": {},
                "work_patterns": {},
                "health_routines": {},
                "communication_style": {},
                "learning_style": {},
                "knowledge_areas": {},
                "decision_making": {},
                "problem_solving": {},
                "stress_indicators": {},
                "coping_mechanisms": {},
                "interests": {},
                "professional": {},
                "tools": {},
                "lessons_learned": {}
            }
        
        # Ensure category exists
        if category not in data:
            data[category] = {}
        
        # Handle different operations
        if operation == "set":
            # Set a field value
            if isinstance(data[category], dict):
                data[category][field] = value
            elif isinstance(data[category], list):
                # For list categories, append if not exists
                if value not in data[category]:
                    data[category].append(value)
            else:
                # Replace entire category if it's not a dict/list
                data[category] = {field: value}
        
        elif operation == "append":
            # Append to a list field
            if isinstance(data[category], dict):
                if field not in data[category]:
                    data[category][field] = []
                if not isinstance(data[category][field], list):
                    data[category][field] = [data[category][field]]
                if value not in data[category][field]:
                    data[category][field].append(value)
            elif isinstance(data[category], list):
                if value not in data[category]:
                    data[category].append(value)
        
        elif operation == "remove":
            # Remove from a list field
            if isinstance(data[category], dict):
                if field in data[category]:
                    if isinstance(data[category][field], list):
                        if value in data[category][field]:
                            data[category][field].remove(value)
                    else:
                        del data[category][field]
            elif isinstance(data[category], list):
                if value in data[category]:
                    data[category].remove(value)
        
        # Update timestamp
        data["last_updated"] = datetime.now().isoformat()
        
        # Save back to file
        with open(personalization_file, 'w') as f:
            json.dump(data, f, indent=2)
        
        return json.dumps({
            "success": True,
            "message": f"Personalization updated: {category}.{field}",
            "category": category,
            "field": field,
            "value": value,
            "operation": operation,
            "last_updated": data["last_updated"]
        })
    
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error updating personalization: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_get_personalization",
    description="Get personalization data about the user. This includes relationships (partner, family), goals, values, work patterns, energy management, communication preferences, learning style, and more. Use this to understand the user's context, goals, and preferences to provide personalized assistance. If category is provided, returns only that category (e.g., 'relationships', 'goals', 'energy_patterns').",
    parameters={
        "type": "object",
        "properties": {
            "category": {
                "type": "string",
                "description": "Optional category to filter by (e.g., 'relationships', 'goals', 'energy_patterns', 'communication_style', 'professional'). If not provided, returns all personalization data."
            }
        }
    },
    handler=_gtd_get_personalization_handler,
    category="gtd"
)

register_tool(
    name="gtd_update_personalization",
    description="Update personalization data based on insights learned about the user. Use this when you discover new information about the user that should be remembered for future interactions. Examples: learning their partner's name, discovering their goals, noticing energy patterns, understanding communication preferences. Only update when you have clear, reliable information - don't guess or assume. Use 'set' to set/replace a value, 'append' to add to a list, 'remove' to remove from a list.",
    parameters={
        "type": "object",
        "properties": {
            "category": {
                "type": "string",
                "description": "Category to update (e.g., 'relationships', 'goals', 'energy_patterns', 'communication_style', 'professional', 'lessons_learned')"
            },
            "field": {
                "type": "string",
                "description": "Field name within the category (e.g., 'partner' for relationships, 'career' for goals, 'peak_hours' for energy_patterns)"
            },
            "value": {
                "description": "Value to set/append/remove. Can be a string, number, array, or object depending on the field type."
            },
            "operation": {
                "type": "string",
                "description": "Operation to perform: 'set' (set/replace value), 'append' (add to list), 'remove' (remove from list). Default: 'set'",
                "enum": ["set", "append", "remove"],
                "default": "set"
            }
        },
        "required": ["category", "field", "value"]
    },
    handler=_gtd_update_personalization_handler,
    category="gtd"
)


# ============================================================================
# Additional GTD Tools
# ============================================================================

def _gtd_get_inbox_count_handler() -> str:
    """Handler for getting inbox count."""
    try:
        from pathlib import Path
        
        # Get GTD base directory from config
        gtd_base_dir = Path.home() / "Documents" / "gtd"
        config_file = Path.home() / ".gtd_config"
        if not config_file.exists():
            config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config"
        if not config_file.exists():
            config_file = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config"
        
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    for line in f:
                        if line.strip().startswith("GTD_BASE_DIR="):
                            gtd_base_dir_str = line.split("=", 1)[1].strip().strip('"').strip("'")
                            gtd_base_dir_str = gtd_base_dir_str.replace("$HOME", str(Path.home()))
                            gtd_base_dir = Path(gtd_base_dir_str)
                            break
            except Exception:
                pass
        
        inbox_dir = gtd_base_dir / "0-inbox"
        count = 0
        
        if inbox_dir.exists():
            count = len(list(inbox_dir.glob("*.md")))
        
        return json.dumps({
            "count": count,
            "inbox_path": str(inbox_dir),
            "status": "empty" if count == 0 else "has_items"
        })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error getting inbox count: {str(e)}",
            "traceback": traceback.format_exc(),
            "count": 0
        })


def _gtd_suggest_tasks_from_text_handler(text: str, context: Optional[str] = None, mode: str = "review") -> str:
    """Handler for suggesting tasks from text."""
    try:
        from pathlib import Path
        import sys
        
        # Call MCP server's suggest_tasks_from_text function
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_mcp_server.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_mcp_server.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_mcp_server", mcp_path)
            mcp_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mcp_module)
            
            # Import the function that calls the tool handler
            # The MCP server has handle_call_tool which is async, so we need to call it differently
            # For now, let's use a simpler approach - call the underlying logic directly
            
            # Import the AI helper
            try:
                from zsh.functions.gtd_ai_helpers import call_fast_ai
            except ImportError:
                try:
                    sys.path.insert(0, str(Path(__file__).parent))
                    from gtd_ai_helpers import call_fast_ai
                except ImportError:
                    # Fallback: return a simple response
                    return json.dumps({
                        "suggestions": [],
                        "count": 0,
                        "note": "AI helper not available - cannot generate suggestions",
                        "error": "gtd_ai_helpers module not found"
                    })
            
            prompt = f"""Analyze the following text and suggest actionable tasks.

Text: {text}
Context: {context if context else 'general'}

For each task you identify, provide:
1. A clear, actionable task title
2. A brief reason why this task is important
3. A confidence score (0.0 to 1.0)
4. Suggested context (home, office, computer, phone, errands)
5. Suggested priority (urgent_important, not_urgent_important, urgent_not_important, not_urgent_not_important)

Format your response as JSON array of objects with keys: title, reason, confidence, context, priority.

Only suggest tasks that are clearly actionable. If no tasks are found, return an empty array."""

            response = call_fast_ai(prompt, "You are a GTD task extraction expert. Return only valid JSON.", use_instruct=True)
            
            # Parse JSON from response
            import re
            try:
                json_match = re.search(r'\[.*\]', response, re.DOTALL)
                if json_match:
                    suggestions = json.loads(json_match.group())
                else:
                    suggestions = []
            except Exception:
                suggestions = []
            
            return json.dumps({
                "suggestions": suggestions,
                "count": len(suggestions),
                "mode": mode,
                "context": context or "general"
            }, default=str)
        else:
            return json.dumps({
                "error": "MCP server module not found",
                "suggestions": [],
                "count": 0
            })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error suggesting tasks: {str(e)}",
            "traceback": traceback.format_exc(),
            "suggestions": [],
            "count": 0
        })


# Register additional GTD tools
register_tool(
    name="gtd_get_inbox_count",
    description="Get the count of items in the GTD inbox. Returns the number of unprocessed items in the inbox. Use this to check if the inbox needs processing. Returns 0 if inbox is empty.",
    parameters={
        "type": "object",
        "properties": {}
    },
    handler=_gtd_get_inbox_count_handler,
    category="gtd"
)

register_tool(
    name="gtd_suggest_tasks_from_text",
    description="Analyze text and suggest actionable tasks. This tool extracts potential tasks from text content (like daily logs, notes, or conversations) and suggests them as tasks. Use this to identify tasks from unstructured text. Returns a list of suggested tasks with confidence scores.",
    parameters={
        "type": "object",
        "properties": {
            "text": {
                "type": "string",
                "description": "The text to analyze for task suggestions (e.g., daily log entries, notes, conversation)"
            },
            "context": {
                "type": "string",
                "description": "Optional context for the text (e.g., 'daily_log', 'meeting_notes', 'conversation')"
            },
            "mode": {
                "type": "string",
                "description": "Mode: 'review' (save suggestions for review) or 'immediate' (auto-create high-confidence tasks). Default: 'review'",
                "default": "review"
            }
        },
        "required": ["text"]
    },
    handler=_gtd_suggest_tasks_from_text_handler,
    category="gtd"
)


def _list_available_tools_handler(category: Optional[str] = None) -> str:
    """Handler for listing available tools."""
    try:
        tools_list = []
        for tool_name, tool_info in TOOL_REGISTRY.items():
            if category is None or tool_info["category"] == category:
                tools_list.append({
                    "name": tool_name,
                    "description": tool_info["description"],
                    "category": tool_info["category"]
                })
        
        return json.dumps({
            "tools": tools_list,
            "count": len(tools_list),
            "category_filter": category,
            "categories": list(set(t["category"] for t in TOOL_REGISTRY.values()))
        }, default=str)
    except Exception as e:
        return json.dumps({
            "error": f"Error listing tools: {str(e)}",
            "tools": [],
            "count": 0
        })


register_tool(
    name="list_available_tools",
    description="List all available tools that can be called. Use this to discover what tools are available when you're unsure what to use. Can filter by category (e.g., 'gtd', 'skills', 'web').",
    parameters={
        "type": "object",
        "properties": {
            "category": {
                "type": "string",
                "description": "Optional category filter (e.g., 'gtd', 'skills', 'web'). If not provided, returns all tools."
            }
        }
    },
    handler=_list_available_tools_handler,
    category="system"
)


def get_available_tools_by_category() -> Dict[str, List[str]]:
    """Get list of available tools grouped by category."""
    categories = {}
    for tool_name, tool_info in TOOL_REGISTRY.items():
        category = tool_info["category"]
        if category not in categories:
            categories[category] = []
        categories[category].append(tool_name)
    return categories


def list_all_tools() -> List[str]:
    """Get list of all registered tool names."""
    return list(TOOL_REGISTRY.keys())


# Export for use in other modules
__all__ = [
    "register_tool",
    "get_tool_definitions",
    "execute_tool",
    "get_available_tools_by_category",
    "list_all_tools",
    "TOOL_REGISTRY"
]
