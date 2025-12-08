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
        from datetime import datetime
        from pathlib import Path
        
        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")
        
        log_dir = Path.home() / "Documents" / "daily_logs"
        log_file = log_dir / f"{date}.txt"
        
        if log_file.exists():
            with open(log_file, 'r') as f:
                content = f.read()
            return json.dumps({
                "date": date,
                "content": content,
                "entry_count": len([l for l in content.split('\n') if l.strip() and not l.strip().startswith('#')])
            })
        else:
            return json.dumps({
                "date": date,
                "content": "",
                "entry_count": 0,
                "note": "Log file not found"
            })
    except Exception as e:
        return f"Error reading daily log: {str(e)}"


register_tool(
    name="gtd_read_daily_log",
    description="Read daily log entries for a specific date or today. Use this to understand what the user has been working on, their recent activities, or to analyze patterns in their daily activities.",
    parameters={
        "type": "object",
        "properties": {
            "date": {
                "type": "string",
                "description": "Date in YYYY-MM-DD format (default: today)"
            }
        }
    },
    handler=_gtd_read_daily_log_handler,
    category="gtd"
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
