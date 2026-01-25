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

def _list_agent_skills_handler(query: Optional[str] = None, tags: Optional[List[str]] = None, runbooks_only: bool = False) -> str:
    """Handler for listing agent skills and optionally runbooks."""
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
                skills = registry.search_skills(query=query, tags=tags, runbooks_only=runbooks_only)
            else:
                skills = registry.list_skills(runbooks_only=runbooks_only)
            
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
    description="List all available Agent Skills and Runbooks. Skills are reusable workflows that guide how to use GTD tools to accomplish goals. Runbooks are interactive, step-by-step guides that ask questions and wait for responses. Use this to discover what skills/runbooks are available, then use get_agent_skill to read their instructions. Set runbooks_only=true to list only runbooks (interactive workflows).",
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
            },
            "runbooks_only": {
                "type": "boolean",
                "description": "If true, only return runbooks (interactive workflows). If false or omitted, return both skills and runbooks."
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
        import sys
        
        # Import TOON helper (same approach as update handler)
        sys.path.insert(0, str(Path(__file__).parent))
        try:
            from gtd_toon_helper import load_toon_file, get_personalization_file_path
            personalization_file = get_personalization_file_path()
            use_toon = True
        except ImportError:
            # Fallback to JSON
            personalization_file = Path.home() / ".gtd_personalization.json"
            use_toon = False
        
        # Check if file exists (try TOON first, then JSON fallback)
        if not personalization_file.exists():
            # If TOON doesn't exist, try JSON fallback
            json_file = Path.home() / ".gtd_personalization.json"
            if json_file.exists():
                personalization_file = json_file
                use_toon = False
            else:
                return json.dumps({
                    "error": "Personalization file not found",
                    "message": "User has not set up personalization yet. Suggest running: gtd-wizard → option 67",
                    "file_path": str(personalization_file)
                })
        
        # Load data using appropriate format
        if use_toon:
            data = load_toon_file(personalization_file)
        else:
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
                    "available_categories": list(data.keys()),
                    "message": f"The personalization file exists but doesn't contain a '{category}' category. Available categories: {', '.join(list(data.keys()))}"
                })
        
        # Return full data
        return json.dumps(data, indent=2)
    
    except json.JSONDecodeError as e:
        return json.dumps({
            "error": "Invalid JSON in personalization file",
            "message": str(e),
            "file_path": str(personalization_file) if 'personalization_file' in locals() else "unknown"
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
        import sys
        
        # Import TOON helper
        sys.path.insert(0, str(Path(__file__).parent))
        try:
            from gtd_toon_helper import load_toon_file, save_toon_file, get_personalization_file_path
            personalization_file = get_personalization_file_path()
            use_toon = True
        except ImportError:
            # Fallback to JSON
            personalization_file = Path.home() / ".gtd_personalization.json"
            use_toon = False
        
        # Load existing data or create new
        if use_toon:
            data = load_toon_file(personalization_file)
        else:
            if personalization_file.exists():
                with open(personalization_file, 'r') as f:
                    data = json.load(f)
            else:
                data = {}
        
        # Initialize with basic structure if data is empty or missing required fields
        if not data or "created" not in data:
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
                # Special handling for relationships.partner to preserve object structure
                if category == "relationships" and field == "partner":
                    # If value is a string, convert to object structure
                    if isinstance(value, str):
                        # Preserve existing structure if it exists, otherwise create new
                        if field in data[category] and isinstance(data[category][field], dict):
                            data[category][field]["name"] = value
                            if "relationship_type" not in data[category][field]:
                                data[category][field]["relationship_type"] = "partner"
                        else:
                            data[category][field] = {
                                "name": value,
                                "relationship_type": "partner"
                            }
                    # If value is already an object/dict, merge with existing structure
                    elif isinstance(value, dict):
                        # Initialize partner object if it doesn't exist
                        if field not in data[category] or not isinstance(data[category][field], dict):
                            data[category][field] = {"relationship_type": "partner"}
                        # Merge new data into existing structure (preserve existing fields)
                        data[category][field].update(value)
                    else:
                        data[category][field] = value
                
                # Special handling for relationships fields to support detailed information
                elif category == "relationships" and isinstance(data[category], dict):
                    # If updating a sub-field of a relationship (e.g., partner.interests, partner.birthday)
                    if "." in field:
                        # Split field like "partner.interests" into "partner" and "interests"
                        parts = field.split(".", 1)
                        person_field = parts[0]
                        detail_field = parts[1]
                        
                        # Initialize person object if it doesn't exist
                        if person_field not in data[category]:
                            data[category][person_field] = {}
                        if not isinstance(data[category][person_field], dict):
                            data[category][person_field] = {}
                        
                        # Handle list fields (interests, gift_ideas, notes) vs single values (birthday, etc.)
                        if detail_field in ["interests", "gift_ideas", "notes", "preferences"]:
                            # These are list fields - append or set as list
                            if detail_field not in data[category][person_field]:
                                data[category][person_field][detail_field] = []
                            if not isinstance(data[category][person_field][detail_field], list):
                                data[category][person_field][detail_field] = [data[category][person_field][detail_field]]
                            
                            # If value is a list, extend; if single value, append
                            if isinstance(value, list):
                                for item in value:
                                    if item not in data[category][person_field][detail_field]:
                                        data[category][person_field][detail_field].append(item)
                            else:
                                if value not in data[category][person_field][detail_field]:
                                    data[category][person_field][detail_field].append(value)
                        else:
                            # Single value field (birthday, favorite_color, etc.)
                            data[category][person_field][detail_field] = value
                    else:
                        # Regular field update
                        data[category][field] = value
                else:
                    # For other fields, set directly
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
        
        # Save back to file
        if use_toon:
            save_toon_file(personalization_file, data)
        else:
            # Update timestamp
            data["last_updated"] = datetime.now().isoformat()
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
# Second Brain Tools
# ============================================================================

def _get_spelling_variations(word: str) -> list:
    """Generate spelling variations for a word (e.g., rakshasa <-> rakasha)"""
    variations = []
    word_lower = word.lower()
    
    if len(word_lower) <= 3:
        return variations
    
    # Handle "rakshasa" <-> "rakasha" 
    # "rakshasa" = r-a-k-s-h-a-s-a (8 chars)
    # "rakasha" = r-a-k-a-s-h-a (7 chars)
    # The difference: after "rak", "rakshasa" has "shasa" while "rakasha" has "asha"
    # So "ksh" in "rakshasa" corresponds to "ka" in "rakasha"
    if 'rakshasa' in word_lower:
        # Direct mapping for this specific case
        variations.append('rakasha')
    elif 'rakasha' in word_lower:
        variations.append('rakshasa')
    
    # Also try simpler variations: remove 's' after 'k' (for other cases)
    if 'ks' in word_lower and 'ksh' not in word_lower:
        variant = word_lower.replace('ks', 'k', 1)
        if variant != word_lower and len(variant) >= 3:
            variations.append(variant)
    
    return variations


def _gtd_search_second_brain_handler(topic: str, max_results: int = 10) -> str:
    """Handler for searching Second Brain notes."""
    try:
        from pathlib import Path
        import os
        
        # Get Second Brain directory
        second_brain_dir = Path.home() / "Documents" / "obsidian" / "Second Brain"
        
        # Check if directory exists
        if not second_brain_dir.exists():
            # Try to get from environment or config
            second_brain_env = os.getenv("SECOND_BRAIN")
            if second_brain_env:
                second_brain_dir = Path(second_brain_env)
            if not second_brain_dir.exists():
                return json.dumps({
                    "error": "Second Brain directory not found",
                    "message": f"Second Brain directory does not exist: {second_brain_dir}",
                    "topic": topic,
                    "suggestion": "Check if your Second Brain is located elsewhere or set SECOND_BRAIN environment variable"
                })
        
        # Search for files matching the topic in filename
        results = []
        search_pattern = f"*{topic}*"
        count = 0
        
        # First, search by filename (case-insensitive)
        for note_file in second_brain_dir.rglob("*.md"):
            # Skip MOCs and .obsidian directories
            if "MOCs" in note_file.parts or ".obsidian" in note_file.parts:
                continue
            
            # Check if filename contains topic (case-insensitive)
            if topic.lower() in note_file.name.lower():
                if count >= max_results:
                    break
                
                try:
                    note_title = note_file.stem
                    note_path = str(note_file.relative_to(second_brain_dir))
                    
                    # Read preview (first 100 lines)
                    with open(note_file, 'r', encoding='utf-8', errors='ignore') as f:
                        preview_lines = [f.readline() for _ in range(100)]
                        preview = ''.join(preview_lines).strip()
                    
                    results.append({
                        "title": note_title,
                        "path": note_path,
                        "content": preview
                    })
                    count += 1
                except Exception as e:
                    # Skip files that can't be read
                    continue
        
        # If we haven't found enough, search in content
        if count < max_results:
            # Split topic into words for more flexible matching
            topic_words = topic.split()
            
            for note_file in second_brain_dir.rglob("*.md"):
                # Skip MOCs and .obsidian directories
                if "MOCs" in note_file.parts or ".obsidian" in note_file.parts:
                    continue
                
                # Skip if already included
                if any(r["path"] == str(note_file.relative_to(second_brain_dir)) for r in results):
                    continue
                
                if count >= max_results:
                    break
                
                try:
                    with open(note_file, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        content_lower = content.lower()
                        
                        # For multi-word queries, match if ANY word (with variations) is found
                        # For single-word queries, match the word or its variations
                        topic_found = False
                        
                        if len(topic_words) > 1:
                            # Multi-word: match if any word is found
                            for word in topic_words:
                                word_lower = word.lower()
                                if word_lower in content_lower:
                                    topic_found = True
                                    break
                                
                                # Try spelling variations for this word
                                variations = _get_spelling_variations(word_lower)
                                for variant in variations:
                                    if variant in content_lower:
                                        topic_found = True
                                        break
                                if topic_found:
                                    break
                        else:
                            # Single word: exact match or variations
                            topic_lower = topic.lower()
                            topic_found = topic_lower in content_lower
                            
                            if not topic_found:
                                variations = _get_spelling_variations(topic_lower)
                                for variant in variations:
                                    if variant in content_lower:
                                        topic_found = True
                                        break
                        
                        if topic_found:
                            note_title = note_file.stem
                            note_path = str(note_file.relative_to(second_brain_dir))
                            
                            # Get preview (first 100 lines)
                            preview_lines = content.split('\n')[:100]
                            preview = '\n'.join(preview_lines).strip()
                            
                            results.append({
                                "title": note_title,
                                "path": note_path,
                                "content": preview
                            })
                            count += 1
                except Exception as e:
                    # Skip files that can't be read
                    continue
        
        # Return results
        if results:
            return json.dumps({
                "results": results,
                "count": len(results),
                "topic": topic
            }, indent=2)
        else:
            return json.dumps({
                "results": [],
                "count": 0,
                "topic": topic,
                "message": f"No notes found containing '{topic}'"
            })
    
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error searching Second Brain: {str(e)}",
            "traceback": traceback.format_exc(),
            "topic": topic
        })


register_tool(
    name="gtd_search_second_brain",
    description="Search the user's Second Brain (personal knowledge base) for notes containing a topic. This searches both filenames and content. Useful for finding Pathfinder campaign notes, session write-ups, character information, or any other personal notes. Returns note titles, paths, and content previews.",
    parameters={
        "type": "object",
        "properties": {
            "topic": {
                "type": "string",
                "description": "Topic or search term to find in Second Brain notes (e.g., 'rakshasa', 'Pathfinder', 'wondrous items', 'Session 10')"
            },
            "max_results": {
                "type": "integer",
                "description": "Maximum number of results to return. Default: 10",
                "default": 10
            }
        },
        "required": ["topic"]
    },
    handler=_gtd_search_second_brain_handler,
    category="gtd"
)


# ============================================================================
# Vector Database Tools
# ============================================================================

def _gtd_search_vector_database_handler(
    query: str,
    content_type: Optional[str] = None,
    limit: int = 10,
    threshold: float = 0.7,
    max_chars_per_result: int = 500
) -> str:
    """Handler for searching the vector database."""
    try:
        import sys
        from pathlib import Path
        
        # Import vectorization module
        functions_dir = Path(__file__).parent
        if str(functions_dir) not in sys.path:
            sys.path.insert(0, str(functions_dir))
        
        try:
            from gtd_vectorization import search_similar, read_database_config
            VECTOR_DB_AVAILABLE = True
        except ImportError:
            return json.dumps({
                "error": "Vector database not available",
                "message": "Vector database modules not installed or configured",
                "query": query
            })
        
        if not query:
            return json.dumps({
                "error": "Query is required",
                "message": "Please provide a search query"
            })
        
        # Validate content_type
        valid_content_types = ["daily_log", "task", "project", "note", "file", None, ""]
        if content_type and content_type not in valid_content_types:
            return json.dumps({
                "error": f"Invalid content_type: {content_type}",
                "message": f"Valid content types: {', '.join([ct for ct in valid_content_types if ct])}",
                "query": query
            })
        
        if content_type == "":
            content_type = None
        
        # Cap limit at 50
        limit = min(limit, 50)
        
        try:
            results = search_similar(
                query_text=query,
                content_type=content_type,
                limit=limit,
                threshold=threshold
            )
            
            # Format results
            formatted_results = []
            for result in results:
                content_text = result.get("content_text", "")
                if max_chars_per_result and len(content_text) > max_chars_per_result:
                    content_text = content_text[:max_chars_per_result] + "..."
                
                formatted_results.append({
                    "content_type": result.get("content_type", "unknown"),
                    "content_id": result.get("content_id", ""),
                    "content_text": content_text,
                    "similarity": round(result.get("similarity", 0.0), 3),
                    "metadata": result.get("metadata", {})
                })
            
            return json.dumps({
                "query": query,
                "results": formatted_results,
                "count": len(formatted_results),
                "content_type_filter": content_type,
                "threshold": threshold
            }, indent=2)
        except Exception as e:
            import traceback
            return json.dumps({
                "error": f"Error searching vector database: {str(e)}",
                "message": "Failed to search vector database. Check database connection and configuration.",
                "query": query,
                "traceback": traceback.format_exc()
            })
    
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error in vector database search handler: {str(e)}",
            "traceback": traceback.format_exc(),
            "query": query
        })


def _gtd_get_vector_database_stats_handler() -> str:
    """Handler for getting vector database statistics."""
    try:
        import sys
        from pathlib import Path
        
        # Import vectorization module
        functions_dir = Path(__file__).parent
        if str(functions_dir) not in sys.path:
            sys.path.insert(0, str(functions_dir))
        
        try:
            from gtd_vectorization import read_database_config
            from gtd_vector_db import VectorDatabase
            VECTOR_DB_AVAILABLE = True
        except ImportError:
            return json.dumps({
                "error": "Vector database not available",
                "message": "Vector database modules not installed or configured"
            })
        
        try:
            db_config = read_database_config()
            db = VectorDatabase(db_config)
            
            if not db.connect():
                return json.dumps({
                    "error": "Cannot connect to database",
                    "message": "Failed to connect to vector database. Check database configuration."
                })
            
            # Get stats
            stats = {}
            
            # Count by content type
            content_types = ["daily_log", "task", "project", "note", "file"]
            counts_by_type = {}
            total_count = 0
            
            for ct in content_types:
                count = db.count_embeddings(ct)
                counts_by_type[ct] = count
                total_count += count
            
            stats["total_embeddings"] = total_count
            stats["by_content_type"] = counts_by_type
            
            # Try to get system stats if available
            try:
                system_stats = db.get_system_stats()
                if system_stats:
                    stats["system_stats"] = system_stats
            except:
                pass  # get_system_stats might not be available
            
            db.disconnect()
            
            return json.dumps(stats, indent=2, default=str)
        except Exception as e:
            import traceback
            return json.dumps({
                "error": f"Error getting vector database stats: {str(e)}",
                "message": "Failed to get vector database statistics.",
                "traceback": traceback.format_exc()
            })
    
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error in vector database stats handler: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_search_vector_database",
    description="Search the vector database for semantically similar content. Use this to find relevant information from your notes, tasks, projects, daily logs, and other vectorized content. Returns content with similarity scores. This is more powerful than direct file access because it uses semantic search to find related content even if exact keywords don't match.",
    parameters={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Search query - what information you're looking for (e.g., 'energy patterns', 'Kubernetes learning', 'morning routine')"
            },
            "content_type": {
                "type": "string",
                "description": "Optional filter by content type: 'daily_log', 'task', 'project', 'note', 'file', or empty string for all types",
                "enum": ["daily_log", "task", "project", "note", "file", ""]
            },
            "limit": {
                "type": "integer",
                "description": "Maximum number of results to return (default: 10, max: 50)",
                "default": 10
            },
            "threshold": {
                "type": "number",
                "description": "Minimum similarity threshold (0.0-1.0, default: 0.7). Higher = more relevant results only.",
                "default": 0.7
            },
            "max_chars_per_result": {
                "type": "integer",
                "description": "Maximum characters per result to return (default: 500). Use to limit response size.",
                "default": 500
            }
        },
        "required": ["query"]
    },
    handler=_gtd_search_vector_database_handler,
    category="knowledge_organization"
)

register_tool(
    name="gtd_get_vector_database_stats",
    description="Get statistics about what's in the vector database - total items, breakdown by content type (daily_log, task, project, note, file), last update time, etc. Useful for understanding what content is available for semantic search.",
    parameters={
        "type": "object",
        "properties": {}
    },
    handler=_gtd_get_vector_database_stats_handler,
    category="knowledge_organization"
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


def _gtd_get_calendar_overview_handler(date: Optional[str] = None, brief: bool = False) -> str:
    """Handler for getting calendar overview."""
    try:
        import subprocess
        import json
        from pathlib import Path
        
        # Default to today if not specified
        target_date = date or "today"
        
        # Find gtd-calendar-info script - check both possible locations
        bin_dir1 = Path.home() / "code" / "dotfiles" / "bin"
        bin_dir2 = Path.home() / "code" / "personal" / "dotfiles" / "bin"
        
        calendar_script = None
        if (bin_dir1 / "gtd-calendar-info").exists():
            calendar_script = bin_dir1 / "gtd-calendar-info"
        elif (bin_dir2 / "gtd-calendar-info").exists():
            calendar_script = bin_dir2 / "gtd-calendar-info"
        
        if not calendar_script or not calendar_script.exists():
            return json.dumps({
                "error": "gtd-calendar-info script not found",
                "message": "Calendar functionality is not available. Make sure gtd-calendar-info is installed."
            })
        
        # Build command - the script expects: overview <date> [brief]
        # brief is passed as "true" or "false" string, not as a flag
        cmd = ["bash", str(calendar_script), "overview", target_date, "true" if brief else "false"]
        
        # Get GTD base directory for cwd
        gtd_base_dir = Path.home() / "Documents" / "gtd"
        if not gtd_base_dir.exists():
            gtd_base_dir = Path.home() / "code" / "dotfiles"
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(gtd_base_dir.parent)
        )
        
        if result.returncode == 0:
            return json.dumps({
                "success": True,
                "date": target_date,
                "overview": result.stdout.strip()
            })
        else:
            # If there's an error, check if it's just authentication
            error_msg = result.stderr.strip()
            if "not authenticated" in error_msg.lower() or "authentication" in error_msg.lower():
                return json.dumps({
                    "error": "Calendar not authenticated",
                    "message": "Calendar authentication is required. Run 'gcalcli init' or use gtd-calendar menu to authenticate.",
                    "overview": ""
                })
            return json.dumps({
                "error": f"Failed to get calendar overview: {error_msg}",
                "overview": result.stdout.strip()
            })
    except Exception as e:
        import traceback
        return json.dumps({
            "error": f"Error getting calendar overview: {str(e)}",
            "traceback": traceback.format_exc()
        })


register_tool(
    name="gtd_get_calendar_overview",
    description="Get today's calendar overview showing all upcoming events and meetings. This uses gcalcli/gtd-calendar to fetch calendar information. Useful for morning check-ins to see what's scheduled for the day. Returns formatted calendar information including event times, titles, locations, and descriptions.",
    parameters={
        "type": "object",
        "properties": {
            "date": {
                "type": "string",
                "description": "Date to get calendar for. Use 'today' (default), 'tomorrow', or YYYY-MM-DD format (e.g., '2026-01-20')"
            },
            "brief": {
                "type": "boolean",
                "description": "If true, return a brief summary instead of full details. Default: false"
            }
        }
    },
    handler=_gtd_get_calendar_overview_handler,
    category="gtd"
)

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


# Sequential Thinking MCP Tools
# These wrap the Sequential Thinking MCP server to make it available in Claude API calls
def _sequential_thinking_handler(tool_name: str, **kwargs) -> str:
    """Handler for Sequential Thinking MCP tools via subprocess."""
    try:
        import subprocess
        import json as json_module
        import os
        
        # Try to use MCP Python SDK if available
        try:
            from mcp import ClientSession, StdioServerParameters
            from mcp.client.stdio import stdio_client
            import asyncio
            
            # Try Docker first
            server_params = StdioServerParameters(
                command="docker",
                args=["run", "--rm", "-i", "mcp/sequentialthinking"]
            )
            
            async def call_mcp_tool():
                async with stdio_client(server_params) as (read, write):
                    async with ClientSession(read, write) as session:
                        await session.initialize()
                        result = await session.call_tool(tool_name, kwargs)
                        return result
            
            result = asyncio.run(call_mcp_tool())
            if result:
                return json_module.dumps(result, default=str)
        except ImportError:
            # MCP SDK not available, fall back to subprocess
            pass
        except Exception as e:
            # Docker/npx might not be available, try subprocess fallback
            pass
        
        # Fallback: Use subprocess with proper MCP protocol
        # Try Docker first
        docker_cmd = ["docker", "run", "--rm", "-i", "mcp/sequentialthinking"]
        
        # Build MCP JSON-RPC request
        mcp_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": kwargs
            }
        }
        
        try:
            # Try Docker
            result = subprocess.run(
                docker_cmd,
                input=json_module.dumps(mcp_request) + "\n",
                text=True,
                capture_output=True,
                timeout=30,
                check=False
            )
            
            if result.returncode == 0 and result.stdout:
                # Parse MCP response
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        try:
                            response = json_module.loads(line)
                            if "result" in response:
                                return json_module.dumps(response["result"], default=str)
                            elif "error" in response:
                                return json_module.dumps({"error": response["error"]}, default=str)
                        except json_module.JSONDecodeError:
                            continue
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # Fallback to npx
        try:
            npx_cmd = ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
            result = subprocess.run(
                npx_cmd,
                input=json_module.dumps(mcp_request) + "\n",
                text=True,
                capture_output=True,
                timeout=30,
                check=False
            )
            
            if result.returncode == 0 and result.stdout:
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        try:
                            response = json_module.loads(line)
                            if "result" in response:
                                return json_module.dumps(response["result"], default=str)
                            elif "error" in response:
                                return json_module.dumps({"error": response["error"]}, default=str)
                        except json_module.JSONDecodeError:
                            continue
        except Exception:
            pass
        
        # If all else fails, return helpful error
        return json_module.dumps({
            "error": "Sequential Thinking MCP server not available",
            "tool": tool_name,
            "solutions": [
                "Install Docker image: docker pull mcp/sequentialthinking",
                "Or ensure npx is available: which npx",
                "Or install MCP Python SDK: pip install mcp",
                "Note: Sequential Thinking tools work best when configured in Cursor IDE MCP settings"
            ],
            "hint": "These tools are also available in Cursor IDE when Sequential Thinking MCP is configured"
        })
        
    except Exception as e:
        import traceback
        return json_module.dumps({
            "error": f"Error calling Sequential Thinking tool: {str(e)}",
            "tool": tool_name,
            "traceback": traceback.format_exc()
        })


def _create_thoughts_handler(thought: str, nextThoughtNeeded: bool = True, thoughtNumber: int = 1, totalThoughts: int = 5) -> str:
    """Create thoughts in Sequential Thinking process."""
    return _sequential_thinking_handler("create_thoughts", thought=thought, nextThoughtNeeded=nextThoughtNeeded, thoughtNumber=thoughtNumber, totalThoughts=totalThoughts)


def _revise_thought_handler(thought: str, revisesThought: int, thoughtNumber: int, totalThoughts: int, nextThoughtNeeded: bool = True) -> str:
    """Revise a previous thought."""
    return _sequential_thinking_handler("revise_thought", thought=thought, revisesThought=revisesThought, thoughtNumber=thoughtNumber, totalThoughts=totalThoughts, nextThoughtNeeded=nextThoughtNeeded)


def _branch_thought_handler(thought: str, branchFromThought: int, branchId: str, thoughtNumber: int, totalThoughts: int, nextThoughtNeeded: bool = True) -> str:
    """Create a branch from a previous thought."""
    return _sequential_thinking_handler("branch_thought", thought=thought, branchFromThought=branchFromThought, branchId=branchId, thoughtNumber=thoughtNumber, totalThoughts=totalThoughts, nextThoughtNeeded=nextThoughtNeeded)


def _summarize_thoughts_handler() -> str:
    """Summarize all thoughts in the thinking process."""
    return _sequential_thinking_handler("summarize_thoughts")


# Register Sequential Thinking tools
register_tool(
    name="create_thoughts",
    description="Start a structured thinking process with initial thoughts. Use this for complex problems that need step-by-step analysis. Helps break down problems into manageable steps and reduces hallucination.",
    parameters={
        "type": "object",
        "properties": {
            "thought": {
                "type": "string",
                "description": "The current thinking step or initial thought"
            },
            "nextThoughtNeeded": {
                "type": "boolean",
                "description": "Whether another thought step is needed. Default: true",
                "default": True
            },
            "thoughtNumber": {
                "type": "integer",
                "description": "Current thought number (1-based). Default: 1",
                "default": 1
            },
            "totalThoughts": {
                "type": "integer",
                "description": "Total number of thoughts planned. Can be adjusted dynamically. Default: 5",
                "default": 5
            }
        },
        "required": ["thought"]
    },
    handler=_create_thoughts_handler,
    category="sequential_thinking"
)

register_tool(
    name="revise_thought",
    description="Revise a previous thought and update subsequent thoughts. Use this when you realize a previous step needs correction or refinement.",
    parameters={
        "type": "object",
        "properties": {
            "thought": {
                "type": "string",
                "description": "The revised thought"
            },
            "revisesThought": {
                "type": "integer",
                "description": "The thought number being revised (1-based)"
            },
            "thoughtNumber": {
                "type": "integer",
                "description": "Current thought number"
            },
            "totalThoughts": {
                "type": "integer",
                "description": "Total number of thoughts (may be adjusted)"
            },
            "nextThoughtNeeded": {
                "type": "boolean",
                "description": "Whether another thought is needed. Default: true",
                "default": True
            }
        },
        "required": ["thought", "revisesThought", "thoughtNumber", "totalThoughts"]
    },
    handler=_revise_thought_handler,
    category="sequential_thinking"
)

register_tool(
    name="branch_thought",
    description="Create an alternative reasoning path from a previous thought. Use this to explore different approaches or solutions.",
    parameters={
        "type": "object",
        "properties": {
            "thought": {
                "type": "string",
                "description": "The thought for this branch"
            },
            "branchFromThought": {
                "type": "integer",
                "description": "The thought number to branch from (1-based)"
            },
            "branchId": {
                "type": "string",
                "description": "Unique identifier for this branch (e.g., 'branch-1', 'alternative-approach')"
            },
            "thoughtNumber": {
                "type": "integer",
                "description": "Current thought number in this branch"
            },
            "totalThoughts": {
                "type": "integer",
                "description": "Total thoughts in this branch"
            },
            "nextThoughtNeeded": {
                "type": "boolean",
                "description": "Whether another thought is needed. Default: true",
                "default": True
            }
        },
        "required": ["thought", "branchFromThought", "branchId", "thoughtNumber", "totalThoughts"]
    },
    handler=_branch_thought_handler,
    category="sequential_thinking"
)

register_tool(
    name="summarize_thoughts",
    description="Get a summary of all thoughts in the thinking process. Use this at the end of a thinking process to get a concise summary.",
    parameters={
        "type": "object",
        "properties": {}
    },
    handler=_summarize_thoughts_handler,
    category="sequential_thinking"
)


# Knowledge Organization Tools
# These wrap the Knowledge Organization system to make it available in Claude API calls

def _knowledge_org_handler(tool_name: str, **kwargs) -> str:
    """Handler for Knowledge Organization tools."""
    try:
        import json
        
        mcp_dir = Path(__file__).parent.parent.parent / "mcp"
        sys.path.insert(0, str(mcp_dir))
        
        if tool_name == "queue_knowledge_organization":
            from gtd_mcp_server import _queue_knowledge_organization_impl
            scan_type = kwargs.get("scan_type", "full")
            
            result = _queue_knowledge_organization_impl(scan_type)
            return json.dumps({
                "status": result,
                "scan_type": scan_type,
                "message": f"Knowledge organization scan ({scan_type}) has been queued for background processing.",
                "tool": tool_name
            })
        
        elif tool_name == "implement_knowledge_suggestions":
            from knowledge_org_implement import implement_suggestions
            
            result_file = kwargs.get("result_file")
            indices = kwargs.get("indices", None)
            
            if result_file:
                result_file_path = Path(result_file)
                stats = implement_suggestions(result_file_path, indices)
                return json.dumps({
                    "implemented": stats,
                    "message": f"Implemented {sum(stats.values())} suggestions",
                    "tool": tool_name
                })
            else:
                return json.dumps({
                    "error": "result_file parameter is required",
                    "tool": tool_name
                })
        
        elif tool_name == "knowledge_org_stats":
            from knowledge_org_learning import get_stats_summary
            
            stats = get_stats_summary()
            return json.dumps({
                "stats": stats,
                "tool": tool_name
            })
            
        else:
            return json.dumps({
                "error": f"Unknown knowledge organization tool: {tool_name}",
                "available_tools": [
                    "queue_knowledge_organization",
                    "implement_knowledge_suggestions", 
                    "knowledge_org_stats"
                ]
            })
            
    except ImportError as e:
        return json.dumps({
            "error": "Knowledge Organization system not available",
            "details": str(e),
            "setup_instructions": [
                "Ensure knowledge organization modules are in mcp/ directory",
                "Check that GTD MCP server is properly configured"
            ],
            "tool": tool_name
        })
    except Exception as e:
        return json.dumps({
            "error": f"Error calling Knowledge Organization tool: {str(e)}",
            "tool": tool_name
        })


def _queue_knowledge_org_handler(**kwargs) -> str:
    """Handler wrapper for queue_knowledge_organization."""
    return _knowledge_org_handler("queue_knowledge_organization", **kwargs)


def _implement_knowledge_suggestions_handler(**kwargs) -> str:
    """Handler wrapper for implement_knowledge_suggestions."""
    return _knowledge_org_handler("implement_knowledge_suggestions", **kwargs)


def _knowledge_org_stats_handler(**kwargs) -> str:
    """Handler wrapper for knowledge_org_stats."""
    return _knowledge_org_handler("knowledge_org_stats", **kwargs)


# Register Knowledge Organization tools
register_tool(
    name="queue_knowledge_organization",
    description="Queue a knowledge organization scan for background processing. Analyzes your GTD system and suggests MoCs (Maps of Content), Areas of Responsibility, and organizational improvements.",
    parameters={
        "type": "object",
        "properties": {
            "scan_type": {
                "type": "string",
                "description": "Type of scan to perform",
                "enum": ["full", "areas", "mocs", "themes"],
                "default": "full"
            }
        }
    },
    handler=_queue_knowledge_org_handler,
    category="knowledge_organization"
)

register_tool(
    name="implement_knowledge_suggestions",
    description="Implement knowledge organization suggestions from a result file. Creates areas, assigns projects, and sets up organizational structure.",
    parameters={
        "type": "object",
        "properties": {
            "result_file": {
                "type": "string",
                "description": "Path to the results file from knowledge organization scan"
            },
            "indices": {
                "type": "array",
                "items": {"type": "integer"},
                "description": "Specific suggestion indices to implement (optional, default: all)"
            }
        },
        "required": ["result_file"]
    },
    handler=_implement_knowledge_suggestions_handler,
    category="knowledge_organization"
)

register_tool(
    name="knowledge_org_stats",
    description="Get knowledge organization learning statistics and patterns. Shows acceptance rates, learning patterns, and system insights.",
    parameters={
        "type": "object",
        "properties": {}
    },
    handler=_knowledge_org_stats_handler,
    category="knowledge_organization"
)


# Export for use in other modules
__all__ = [
    "register_tool",
    "get_tool_definitions",
    "execute_tool",
    "get_available_tools_by_category",
    "list_all_tools",
    "TOOL_REGISTRY"
]
