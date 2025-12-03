#!/usr/bin/env python3
"""
GTD MCP Server - Model Context Protocol server for GTD Unified System

This server provides MCP tools for:
- Quick task suggestions (Gemma 1b - fast)
- Background analysis (GPT-OSS 20b - deep)
- Task management
- Zettel/project management
- Intelligent suggestions with banter
"""

import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import uuid

try:
    from mcp.server import Server
    from mcp.server.models import InitializationOptions
    from mcp.server.stdio import stdio_server
    from mcp.types import (
        Resource,
        Tool,
        TextContent,
        ImageContent,
        EmbeddedResource,
    )
except ImportError:
    print("Error: mcp package not installed. Install with: pip install mcp")
    sys.exit(1)

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from zsh.functions.gtd_persona_helper import read_config, call_persona

# GTD Configuration
GTD_CONFIG_FILE = Path.home() / ".gtd_config"
if (Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config").exists():
    GTD_CONFIG_FILE = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config"

# Load GTD config
GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
GTD_INBOX_DIR = "0-inbox"
GTD_PROJECTS_DIR = "1-projects"
GTD_TASKS_DIR = "tasks"
GTD_SUGGESTIONS_DIR = "suggestions"
GTD_ARCHIVE_DIR = "6-archive"

if GTD_CONFIG_FILE.exists():
    with open(GTD_CONFIG_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key == "GTD_BASE_DIR":
                    GTD_BASE_DIR = Path(value.replace("$HOME", str(Path.home())))
                elif key == "GTD_INBOX_DIR":
                    GTD_INBOX_DIR = value
                elif key == "GTD_PROJECTS_DIR":
                    GTD_PROJECTS_DIR = value

# Ensure directories exist
GTD_BASE_DIR.mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_INBOX_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_PROJECTS_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_TASKS_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_SUGGESTIONS_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_ARCHIVE_DIR).mkdir(parents=True, exist_ok=True)

# LM Studio config - both models via LM Studio
LM_CONFIG = read_config()
FAST_MODEL_URL = LM_CONFIG.get("url", "http://localhost:1234/v1/chat/completions")
FAST_MODEL_NAME = LM_CONFIG.get("chat_model", "google/gemma-3-1b")

# Deep model also via LM Studio (can be same URL, different model name)
DEEP_MODEL_URL = os.getenv("GTD_DEEP_MODEL_URL", LM_CONFIG.get("url", "http://localhost:1234/v1/chat/completions"))
DEEP_MODEL_NAME = os.getenv("GTD_DEEP_MODEL_NAME", os.getenv("GTD_DEEP_MODEL", "gpt-oss-20b"))

# RabbitMQ config for background processing
RABBITMQ_URL = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_QUEUE", "gtd_deep_analysis")

# Initialize MCP server
server = Server("gtd-unified-system")


def load_suggestion(suggestion_id: str) -> Optional[Dict[str, Any]]:
    """Load a suggestion from disk."""
    suggestion_file = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR / f"{suggestion_id}.json"
    if suggestion_file.exists():
        with open(suggestion_file) as f:
            return json.load(f)
    return None


def save_suggestion(suggestion: Dict[str, Any]) -> str:
    """Save a suggestion to disk and return its ID."""
    if "id" not in suggestion:
        suggestion["id"] = str(uuid.uuid4())
    suggestion["created"] = datetime.now().isoformat()
    suggestion_file = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR / f"{suggestion['id']}.json"
    with open(suggestion_file, 'w') as f:
        json.dump(suggestion, f, indent=2)
    return suggestion["id"]


def get_pending_suggestions() -> List[Dict[str, Any]]:
    """Get all pending suggestions."""
    suggestions = []
    suggestions_dir = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR
    for suggestion_file in suggestions_dir.glob("*.json"):
        with open(suggestion_file) as f:
            suggestion = json.load(f)
            if suggestion.get("status") == "pending":
                suggestions.append(suggestion)
    return sorted(suggestions, key=lambda x: x.get("created", ""), reverse=True)


# Helper functions for reading GTD data
def extract_frontmatter(file_path: Path) -> Dict[str, Any]:
    """Extract frontmatter from a markdown file."""
    if not file_path.exists():
        return {}
    
    frontmatter = {}
    in_frontmatter = False
    frontmatter_lines = []
    
    with open(file_path, 'r') as f:
        for line in f:
            if line.strip() == "---":
                if in_frontmatter:
                    break
                in_frontmatter = True
                continue
            if in_frontmatter:
                frontmatter_lines.append(line.rstrip())
    
    for line in frontmatter_lines:
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            frontmatter[key] = value
    
    return frontmatter


def read_task_file(task_path: Path) -> Dict[str, Any]:
    """Read a task file and return structured data."""
    if not task_path.exists():
        return {}
    
    frontmatter = extract_frontmatter(task_path)
    
    # Read content (everything after frontmatter)
    content = ""
    in_frontmatter = False
    frontmatter_end = False
    with open(task_path, 'r') as f:
        for line in f:
            if line.strip() == "---":
                if not in_frontmatter:
                    in_frontmatter = True
                else:
                    frontmatter_end = True
                continue
            if frontmatter_end:
                content += line
    
    # Extract title (first # heading)
    title = ""
    for line in content.split('\n'):
        if line.startswith('# '):
            title = line[2:].strip()
            break
    
    task_data = {
        "id": task_path.stem,
        "path": str(task_path),
        "title": title,
        "type": frontmatter.get("type", "task"),
        "status": frontmatter.get("status", "active"),
        "created": frontmatter.get("created", ""),
        "context": frontmatter.get("context", ""),
        "energy": frontmatter.get("energy", ""),
        "priority": frontmatter.get("priority", ""),
        "project": frontmatter.get("project", ""),
        "repository": frontmatter.get("repository", ""),
        "recurring": frontmatter.get("recurring", "false"),
        "frequency": frontmatter.get("frequency", ""),
        "content": content
    }
    
    return task_data


def find_all_task_files() -> List[Path]:
    """Find all task files (in tasks directory and project directories)."""
    tasks = []
    tasks_dir = GTD_BASE_DIR / GTD_TASKS_DIR
    projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
    
    if tasks_dir.exists():
        tasks.extend(tasks_dir.glob("*.md"))
    
    if projects_dir.exists():
        for project_dir in projects_dir.iterdir():
            if project_dir.is_dir():
                tasks.extend(project_dir.glob("*.md"))
    
    return tasks


def read_project_file(project_path: Path) -> Dict[str, Any]:
    """Read a project README file and return structured data."""
    readme_path = project_path / "README.md"
    if not readme_path.exists():
        return {}
    
    frontmatter = extract_frontmatter(readme_path)
    
    # Count tasks
    task_count = len([f for f in project_path.glob("*.md") if f.name != "README.md"])
    
    project_data = {
        "name": project_path.name,
        "path": str(project_path),
        "type": frontmatter.get("type", "project"),
        "status": frontmatter.get("status", "active"),
        "created": frontmatter.get("created", ""),
        "repository": frontmatter.get("repository", ""),
        "task_count": task_count
    }
    
    return project_data


def read_area_file(area_path: Path) -> Dict[str, Any]:
    """Read an area file and return structured data."""
    if not area_path.exists():
        return {}
    
    frontmatter = extract_frontmatter(area_path)
    
    area_data = {
        "name": area_path.stem,
        "path": str(area_path),
        "type": frontmatter.get("type", "area"),
        "status": frontmatter.get("status", "active"),
        "created": frontmatter.get("created", ""),
    }
    
    return area_data


def read_daily_log_file(date: Optional[str] = None) -> str:
    """Read a daily log file."""
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")
    
    log_dir = Path.home() / "Documents" / "daily_logs"
    log_file = log_dir / f"{date}.txt"
    
    if log_file.exists():
        with open(log_file, 'r') as f:
            return f.read()
    return ""


def find_task_file_by_id(task_id: str) -> Optional[Path]:
    """Find a task file by ID (searches tasks dir and projects)."""
    tasks_dir = GTD_BASE_DIR / GTD_TASKS_DIR
    projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
    
    # Try in tasks directory
    task_file = tasks_dir / f"{task_id}.md"
    if task_file.exists():
        return task_file
    
    # Try in project directories
    if projects_dir.exists():
        for project_dir in projects_dir.iterdir():
            if project_dir.is_dir():
                task_file = project_dir / f"{task_id}.md"
                if task_file.exists():
                    return task_file
                # Also try partial match
                for tf in project_dir.glob(f"{task_id}*.md"):
                    if tf.name != "README.md":
                        return tf
    
    return None


def queue_deep_analysis(analysis_type: str, context: Dict[str, Any]) -> str:
    """Queue a deep analysis task for background processing."""
    try:
        import pika
        connection = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
        channel = connection.channel()
        channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
        
        message = {
            "type": analysis_type,
            "context": context,
            "timestamp": datetime.now().isoformat(),
            "model": DEEP_MODEL_NAME,
            "model_url": DEEP_MODEL_URL,
        }
        
        channel.basic_publish(
            exchange='',
            routing_key=RABBITMQ_QUEUE,
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=2,  # Make message persistent
            )
        )
        connection.close()
        return "queued"
    except ImportError:
        # RabbitMQ not available, log to file instead
        queue_file = GTD_BASE_DIR / "deep_analysis_queue.jsonl"
        message = {
            "type": analysis_type,
            "context": context,
            "timestamp": datetime.now().isoformat(),
            "model": DEEP_MODEL_NAME,
            "model_url": DEEP_MODEL_URL,
        }
        with open(queue_file, 'a') as f:
            f.write(json.dumps(message) + '\n')
        return "logged"
    except Exception as e:
        # Fallback: log to file
        queue_file = GTD_BASE_DIR / "deep_analysis_queue.jsonl"
        message = {
            "type": analysis_type,
            "context": context,
            "timestamp": datetime.now().isoformat(),
            "model": DEEP_MODEL_NAME,
            "model_url": DEEP_MODEL_URL,
            "error": str(e),
        }
        with open(queue_file, 'a') as f:
            f.write(json.dumps(message) + '\n')
        return f"logged (error: {e})"


def call_fast_ai(prompt: str, system_prompt: str = None) -> str:
    """Call the fast AI model (Gemma 1b) for quick responses."""
    import urllib.request
    
    if system_prompt is None:
        system_prompt = "You are a helpful GTD assistant. Provide concise, actionable suggestions."
    
    payload = {
        "model": FAST_MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": LM_CONFIG.get("max_tokens", 500),
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        FAST_MODEL_URL,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    timeout = LM_CONFIG.get("timeout", 30)  # Faster timeout for quick responses
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'error' in result:
                return f"Error: {result['error'].get('message', 'Unknown error')}"
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            return "No response from AI"
    except Exception as e:
        return f"Error calling AI: {e}"


@server.list_tools()
async def handle_list_tools() -> List[Tool]:
    """List all available MCP tools."""
    return [
        Tool(
            name="suggest_tasks_from_text",
            description="Analyze text and suggest tasks using fast AI. Returns task suggestions with reasons and confidence scores.",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "The text to analyze for task suggestions"
                    },
                    "context": {
                        "type": "string",
                        "description": "Optional context about where this text came from (e.g., 'daily_log', 'meeting', 'email')"
                    }
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="create_tasks_from_suggestion",
            description="Create a task from a pending suggestion. Use the suggestion_id from get_pending_suggestions.",
            inputSchema={
                "type": "object",
                "properties": {
                    "suggestion_id": {
                        "type": "string",
                        "description": "The ID of the suggestion to create a task from"
                    }
                },
                "required": ["suggestion_id"]
            }
        ),
        Tool(
            name="get_pending_suggestions",
            description="Get all pending task suggestions that haven't been acted on yet.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="create_task",
            description="Create a new task directly. Can specify title, project, context, priority, and notes.",
            inputSchema={
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
                        "description": "Optional context (home, office, computer, phone, errands)"
                    },
                    "priority": {
                        "type": "string",
                        "description": "Optional priority (urgent_important, not_urgent_important, urgent_not_important, not_urgent_not_important)"
                    },
                    "notes": {
                        "type": "string",
                        "description": "Optional notes or additional details"
                    }
                },
                "required": ["title"]
            }
        ),
        Tool(
            name="suggest_task",
            description="Suggest a task (adds to pending suggestions). Provides reason and confidence.",
            inputSchema={
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "Suggested task title"
                    },
                    "reason": {
                        "type": "string",
                        "description": "Reason why this task is suggested"
                    },
                    "confidence": {
                        "type": "number",
                        "description": "Confidence score (0.0 to 1.0)"
                    }
                },
                "required": ["title", "reason"]
            }
        ),
        Tool(
            name="complete_task",
            description="Mark a task as complete by its ID.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID to complete (from task filename)"
                    }
                },
                "required": ["task_id"]
            }
        ),
        Tool(
            name="defer_task",
            description="Defer a task until a specific date/time.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID to defer"
                    },
                    "until": {
                        "type": "string",
                        "description": "ISO datetime string or date string (e.g., '2025-01-15' or '2025-01-15T10:00:00')"
                    }
                },
                "required": ["task_id", "until"]
            }
        ),
        Tool(
            name="weekly_review",
            description="Trigger a deep weekly review analysis. This queues work for the 20b model in the background.",
            inputSchema={
                "type": "object",
                "properties": {
                    "week_start": {
                        "type": "string",
                        "description": "Optional start date for the week (ISO format). Defaults to current week."
                    }
                }
            }
        ),
        Tool(
            name="analyze_energy",
            description="Analyze energy patterns from daily logs. Queued for deep analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "days": {
                        "type": "number",
                        "description": "Number of days to analyze (default: 7)"
                    }
                }
            }
        ),
        Tool(
            name="find_connections",
            description="Find connections between tasks, projects, and zettels. Queued for deep analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "scope": {
                        "type": "string",
                        "description": "Scope of search: 'tasks', 'projects', 'zettels', or 'all' (default: 'all')"
                    }
                }
            }
        ),
        Tool(
            name="generate_insights",
            description="Generate insights from recent activity. Queued for deep analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "focus": {
                        "type": "string",
                        "description": "Focus area: 'productivity', 'habits', 'projects', or 'general' (default: 'general')"
                    }
                }
            }
        ),
        Tool(
            name="list_tasks",
            description="List tasks with optional filters. Returns structured task data.",
            inputSchema={
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
            }
        ),
        Tool(
            name="get_task_details",
            description="Get detailed information about a specific task by ID.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID (from task filename)"
                    }
                },
                "required": ["task_id"]
            }
        ),
        Tool(
            name="update_task",
            description="Update task properties (title, context, energy, priority, status, etc.).",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID to update"
                    },
                    "title": {
                        "type": "string",
                        "description": "New task title"
                    },
                    "context": {
                        "type": "string",
                        "description": "New context"
                    },
                    "energy": {
                        "type": "string",
                        "description": "New energy level"
                    },
                    "priority": {
                        "type": "string",
                        "description": "New priority"
                    },
                    "status": {
                        "type": "string",
                        "description": "New status (active, on-hold, done)"
                    },
                    "project": {
                        "type": "string",
                        "description": "Project to assign task to"
                    }
                },
                "required": ["task_id"]
            }
        ),
        Tool(
            name="list_projects",
            description="List all projects with their details and status.",
            inputSchema={
                "type": "object",
                "properties": {
                    "status": {
                        "type": "string",
                        "description": "Filter by status (active, on-hold, done, all). Default: active"
                    }
                }
            }
        ),
        Tool(
            name="create_project",
            description="Create a new project with optional repository link.",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Project name"
                    },
                    "description": {
                        "type": "string",
                        "description": "Optional project description"
                    },
                    "repository": {
                        "type": "string",
                        "description": "Optional repository URL (GitHub/GitLab)"
                    }
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="get_project_details",
            description="Get detailed information about a specific project.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_name": {
                        "type": "string",
                        "description": "Project name"
                    }
                },
                "required": ["project_name"]
            }
        ),
        Tool(
            name="get_project_status",
            description="Get project status including tasks, progress, and next actions.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_name": {
                        "type": "string",
                        "description": "Project name"
                    }
                },
                "required": ["project_name"]
            }
        ),
        Tool(
            name="list_areas",
            description="List all areas of responsibility.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="get_context_tasks",
            description="Get tasks available in a specific context and optional energy level.",
            inputSchema={
                "type": "object",
                "properties": {
                    "context": {
                        "type": "string",
                        "description": "Context (home, office, computer, phone, errands)"
                    },
                    "energy": {
                        "type": "string",
                        "description": "Optional energy level filter"
                    },
                    "limit": {
                        "type": "number",
                        "description": "Maximum number of tasks (default: 10)"
                    }
                },
                "required": ["context"]
            }
        ),
        Tool(
            name="get_inbox_count",
            description="Get the count of unprocessed items in the inbox.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="read_daily_log",
            description="Read daily log entries for a specific date or today.",
            inputSchema={
                "type": "object",
                "properties": {
                    "date": {
                        "type": "string",
                        "description": "Date in YYYY-MM-DD format (default: today)"
                    }
                }
            }
        ),
        Tool(
            name="read_recent_logs",
            description="Read daily log entries from the past N days.",
            inputSchema={
                "type": "object",
                "properties": {
                    "days": {
                        "type": "number",
                        "description": "Number of days to read (default: 7)"
                    }
                }
            }
        ),
    ]


@server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """Handle tool calls."""
    
    if name == "suggest_tasks_from_text":
        text = arguments.get("text", "")
        context = arguments.get("context", "")
        
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

        response = call_fast_ai(prompt, "You are a GTD task extraction expert. Return only valid JSON.")
        
        try:
            # Try to extract JSON from response
            import re
            json_match = re.search(r'\[.*\]', response, re.DOTALL)
            if json_match:
                suggestions = json.loads(json_match.group())
            else:
                suggestions = []
        except:
            suggestions = []
        
        # Save suggestions
        saved_suggestions = []
        for suggestion in suggestions:
            suggestion["status"] = "pending"
            suggestion["source_text"] = text
            suggestion["source_context"] = context
            suggestion_id = save_suggestion(suggestion)
            saved_suggestions.append({
                "id": suggestion_id,
                "title": suggestion.get("title", ""),
                "reason": suggestion.get("reason", ""),
                "confidence": suggestion.get("confidence", 0.5)
            })
        
        result = {
            "suggestions": saved_suggestions,
            "count": len(saved_suggestions),
            "raw_response": response
        }
        
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    
    elif name == "create_tasks_from_suggestion":
        suggestion_id = arguments.get("suggestion_id", "")
        suggestion = load_suggestion(suggestion_id)
        
        if not suggestion:
            return [TextContent(type="text", text=json.dumps({"error": f"Suggestion {suggestion_id} not found"}))]
        
        # Create task using gtd-task command
        import subprocess
        task_title = suggestion.get("title", "")
        context = suggestion.get("context", "computer")
        priority = suggestion.get("priority", "not_urgent_important")
        project = suggestion.get("project", "")
        notes = suggestion.get("reason", "")
        
        cmd = [
            "gtd-task", "add",
            "--context", context,
            "--priority", priority,
            "--non-interactive",
            task_title
        ]
        
        if project:
            cmd.extend(["--project", project])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(GTD_BASE_DIR.parent))
            if result.returncode == 0:
                # Mark suggestion as used
                suggestion["status"] = "accepted"
                suggestion["accepted_at"] = datetime.now().isoformat()
                save_suggestion(suggestion)
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": f"Task created from suggestion {suggestion_id}",
                    "output": result.stdout
                }))]
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Failed to create task: {result.stderr}",
                    "output": result.stdout
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({"error": str(e)}))]
    
    elif name == "get_pending_suggestions":
        suggestions = get_pending_suggestions()
        return [TextContent(type="text", text=json.dumps({
            "suggestions": suggestions,
            "count": len(suggestions)
        }, indent=2, default=str))]
    
    elif name == "create_task":
        title = arguments.get("title", "")
        project = arguments.get("project", "")
        context = arguments.get("context", "computer")
        priority = arguments.get("priority", "not_urgent_important")
        notes = arguments.get("notes", "")
        
        import subprocess
        cmd = [
            "gtd-task", "add",
            "--context", context,
            "--priority", priority,
            "--non-interactive",
            title
        ]
        
        if project:
            cmd.extend(["--project", project])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(GTD_BASE_DIR.parent))
            if result.returncode == 0:
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": "Task created successfully",
                    "output": result.stdout
                }))]
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Failed to create task: {result.stderr}"
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({"error": str(e)}))]
    
    elif name == "suggest_task":
        title = arguments.get("title", "")
        reason = arguments.get("reason", "")
        confidence = arguments.get("confidence", 0.5)
        
        suggestion = {
            "title": title,
            "reason": reason,
            "confidence": confidence,
            "status": "pending"
        }
        
        suggestion_id = save_suggestion(suggestion)
        
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "suggestion_id": suggestion_id,
            "message": "Suggestion saved"
        }))]
    
    elif name == "complete_task":
        task_id = arguments.get("task_id", "")
        import subprocess
        try:
            result = subprocess.run(
                ["gtd-task", "complete", task_id],
                capture_output=True,
                text=True,
                cwd=str(GTD_BASE_DIR.parent)
            )
            if result.returncode == 0:
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": f"Task {task_id} completed",
                    "output": result.stdout
                }))]
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Failed to complete task: {result.stderr}"
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({"error": str(e)}))]
    
    elif name == "defer_task":
        task_id = arguments.get("task_id", "")
        until = arguments.get("until", "")
        # TODO: Implement defer logic (update task file with defer_until field)
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "message": f"Task {task_id} deferred until {until}",
            "note": "Defer functionality to be implemented"
        }))]
    
    elif name == "weekly_review":
        week_start = arguments.get("week_start", "")
        status = queue_deep_analysis("weekly_review", {"week_start": week_start})
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "message": "Weekly review analysis queued for background processing"
        }))]
    
    elif name == "analyze_energy":
        days = arguments.get("days", 7)
        status = queue_deep_analysis("analyze_energy", {"days": days})
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "message": f"Energy analysis for {days} days queued for background processing"
        }))]
    
    elif name == "find_connections":
        scope = arguments.get("scope", "all")
        status = queue_deep_analysis("find_connections", {"scope": scope})
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "message": f"Connection analysis for {scope} queued for background processing"
        }))]
    
    elif name == "generate_insights":
        focus = arguments.get("focus", "general")
        status = queue_deep_analysis("generate_insights", {"focus": focus})
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "message": f"Insight generation for {focus} queued for background processing"
        }))]
    
    elif name == "list_tasks":
        context_filter = arguments.get("context")
        energy_filter = arguments.get("energy")
        priority_filter = arguments.get("priority")
        project_filter = arguments.get("project")
        status_filter = arguments.get("status", "active")
        limit = arguments.get("limit", 50)
        
        tasks = []
        task_files = find_all_task_files()
        
        for task_file in task_files:
            task_data = read_task_file(task_file)
            
            # Apply filters
            if task_data.get("status") != status_filter:
                continue
            if context_filter and task_data.get("context") != context_filter:
                continue
            if energy_filter and task_data.get("energy") != energy_filter:
                continue
            if priority_filter and task_data.get("priority") != priority_filter:
                continue
            if project_filter:
                task_project = task_data.get("project", "")
                if not task_project or task_project != project_filter:
                    continue
            
            # Remove content for list view (keep it small)
            task_list_item = {k: v for k, v in task_data.items() if k != "content"}
            tasks.append(task_list_item)
            
            if len(tasks) >= limit:
                break
        
        return [TextContent(type="text", text=json.dumps({
            "tasks": tasks,
            "count": len(tasks),
            "filters": {
                "context": context_filter,
                "energy": energy_filter,
                "priority": priority_filter,
                "project": project_filter,
                "status": status_filter
            }
        }, default=str))]
    
    elif name == "get_task_details":
        task_id = arguments.get("task_id", "")
        task_file = find_task_file_by_id(task_id)
        
        if not task_file or not task_file.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Task {task_id} not found"
            }))]
        
        task_data = read_task_file(task_file)
        return [TextContent(type="text", text=json.dumps(task_data, default=str))]
    
    elif name == "update_task":
        task_id = arguments.get("task_id", "")
        task_file = find_task_file_by_id(task_id)
        
        if not task_file or not task_file.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Task {task_id} not found"
            }))]
        
        # Use gtd-task update command via subprocess
        import subprocess
        
        # For now, use the existing gtd-task command
        # We could implement direct file updates later
        result = subprocess.run(
            ["gtd-task", "update", task_id],
            capture_output=True,
            text=True,
            cwd=str(GTD_BASE_DIR.parent)
        )
        
        if result.returncode == 0:
            return [TextContent(type="text", text=json.dumps({
                "success": True,
                "message": f"Task {task_id} updated",
                "output": result.stdout
            }))]
        else:
            return [TextContent(type="text", text=json.dumps({
                "error": f"Failed to update task: {result.stderr}"
            }))]
    
    elif name == "list_projects":
        status_filter = arguments.get("status", "active")
        
        projects = []
        projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
        
        if projects_dir.exists():
            for project_dir in projects_dir.iterdir():
                if project_dir.is_dir():
                    project_data = read_project_file(project_dir)
                    if project_data:
                        if status_filter == "all" or project_data.get("status") == status_filter:
                            projects.append(project_data)
        
        return [TextContent(type="text", text=json.dumps({
            "projects": projects,
            "count": len(projects),
            "status_filter": status_filter
        }, default=str))]
    
    elif name == "create_project":
        project_name = arguments.get("name", "")
        description = arguments.get("description", "")
        repository = arguments.get("repository", "")
        
        import subprocess
        
        cmd = ["gtd-project", "create", project_name]
        if repository:
            cmd.extend(["--repository", repository])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(GTD_BASE_DIR.parent),
            input=description if description else None
        )
        
        if result.returncode == 0:
            return [TextContent(type="text", text=json.dumps({
                "success": True,
                "message": f"Project '{project_name}' created",
                "output": result.stdout
            }))]
        else:
            return [TextContent(type="text", text=json.dumps({
                "error": f"Failed to create project: {result.stderr}"
            }))]
    
    elif name == "get_project_details":
        project_name = arguments.get("project_name", "")
        project_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR / project_name.lower().replace(" ", "-")
        
        if not project_dir.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Project '{project_name}' not found"
            }))]
        
        project_data = read_project_file(project_dir)
        
        # Get tasks in project
        tasks = []
        for task_file in project_dir.glob("*.md"):
            if task_file.name != "README.md":
                task_data = read_task_file(task_file)
                if task_data:
                    tasks.append({k: v for k, v in task_data.items() if k != "content"})
        
        project_data["tasks"] = tasks
        
        return [TextContent(type="text", text=json.dumps(project_data, default=str))]
    
    elif name == "get_project_status":
        project_name = arguments.get("project_name", "")
        project_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR / project_name.lower().replace(" ", "-")
        
        if not project_dir.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Project '{project_name}' not found"
            }))]
        
        project_data = read_project_file(project_dir)
        
        # Count tasks by status
        tasks_by_status = {"active": 0, "on-hold": 0, "done": 0}
        active_tasks = []
        
        for task_file in project_dir.glob("*.md"):
            if task_file.name != "README.md":
                task_data = read_task_file(task_file)
                if task_data:
                    status = task_data.get("status", "active")
                    tasks_by_status[status] = tasks_by_status.get(status, 0) + 1
                    if status == "active":
                        active_tasks.append({
                            "id": task_data.get("id"),
                            "title": task_data.get("title"),
                            "context": task_data.get("context"),
                            "priority": task_data.get("priority")
                        })
        
        status_info = {
            "project": project_data,
            "tasks_by_status": tasks_by_status,
            "total_tasks": sum(tasks_by_status.values()),
            "active_tasks": active_tasks[:10]  # Top 10 active tasks
        }
        
        return [TextContent(type="text", text=json.dumps(status_info, default=str))]
    
    elif name == "list_areas":
        areas = []
        areas_dir = GTD_BASE_DIR / "2-areas"
        
        if areas_dir.exists():
            for area_file in areas_dir.glob("*.md"):
                area_data = read_area_file(area_file)
                if area_data:
                    areas.append(area_data)
        
        return [TextContent(type="text", text=json.dumps({
            "areas": areas,
            "count": len(areas)
        }, default=str))]
    
    elif name == "get_context_tasks":
        context = arguments.get("context", "")
        energy = arguments.get("energy")
        limit = arguments.get("limit", 10)
        
        tasks = []
        task_files = find_all_task_files()
        
        for task_file in task_files:
            task_data = read_task_file(task_file)
            
            if task_data.get("status") != "active":
                continue
            if task_data.get("context") != context:
                continue
            if energy and task_data.get("energy") != energy:
                continue
            
            tasks.append({
                "id": task_data.get("id"),
                "title": task_data.get("title"),
                "context": task_data.get("context"),
                "energy": task_data.get("energy"),
                "priority": task_data.get("priority"),
                "project": task_data.get("project")
            })
            
            if len(tasks) >= limit:
                break
        
        return [TextContent(type="text", text=json.dumps({
            "tasks": tasks,
            "count": len(tasks),
            "context": context,
            "energy": energy
        }, default=str))]
    
    elif name == "get_inbox_count":
        inbox_dir = GTD_BASE_DIR / GTD_INBOX_DIR
        count = 0
        
        if inbox_dir.exists():
            count = len(list(inbox_dir.glob("*.md")))
        
        return [TextContent(type="text", text=json.dumps({
            "count": count,
            "inbox_path": str(inbox_dir)
        }))]
    
    elif name == "read_daily_log":
        date = arguments.get("date")
        log_content = read_daily_log_file(date)
        
        return [TextContent(type="text", text=json.dumps({
            "date": date or datetime.now().strftime("%Y-%m-%d"),
            "content": log_content,
            "entry_count": len([l for l in log_content.split('\n') if l.strip() and not l.strip().startswith('#')]) if log_content else 0
        }))]
    
    elif name == "read_recent_logs":
        days = arguments.get("days", 7)
        logs = []
        log_dir = Path.home() / "Documents" / "daily_logs"
        
        for i in range(days):
            date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
            log_file = log_dir / f"{date}.txt"
            
            if log_file.exists():
                with open(log_file, 'r') as f:
                    content = f.read()
                    logs.append({
                        "date": date,
                        "content": content,
                        "entry_count": len([l for l in content.split('\n') if l.strip() and not l.strip().startswith('#')])
                    })
        
        return [TextContent(type="text", text=json.dumps({
            "logs": logs,
            "count": len(logs),
            "days": days
        }, default=str))]
    
    else:
        return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]


async def main():
    """Run the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="gtd-unified-system",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=None,
                    experimental_capabilities=None,
                ),
            ),
        )


if __name__ == "__main__":
    asyncio.run(main())

