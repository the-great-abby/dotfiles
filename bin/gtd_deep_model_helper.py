#!/usr/bin/env python3
"""
GTD Deep Model Helper - Call the deep analysis model directly for diagram generation
Uses the deep model (GPT-OSS 20b) which handles visual information better
Enhanced to gather GTD data before calling the model for more accurate diagrams
"""

import json
import sys
import os
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

# Load configuration
GTD_CONFIG = {}
config_paths = [
    Path.home() / ".gtd_config_ai",
    Path.home() / ".gtd_config",
    Path(__file__).parent.parent / "zsh" / ".gtd_config_ai",
    Path(__file__).parent.parent / "zsh" / ".gtd_config",
]

for config_path in config_paths:
    if config_path.exists():
        with open(config_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    # Remove variable expansion syntax like ${VAR:-default}
                    if value.startswith("${") and ":-" in value:
                        value = value.split(":-", 1)[1].rstrip("}")
                    if key == "LM_STUDIO_URL":
                        GTD_CONFIG["url"] = value
                    elif key == "GTD_DEEP_MODEL_NAME":
                        GTD_CONFIG["deep_model_name"] = value
                    elif key == "GTD_DEEP_MODEL_URL":
                        GTD_CONFIG["deep_model_url"] = value
                    elif key == "DEEP_MODEL_TIMEOUT":
                        try:
                            GTD_CONFIG["deep_model_timeout"] = int(value)
                        except (ValueError, TypeError):
                            GTD_CONFIG["deep_model_timeout"] = 120
                    elif key == "GTD_BASE_DIR":
                        GTD_CONFIG["gtd_base_dir"] = value.replace("$HOME", str(Path.home()))
                    elif key == "GTD_PROJECTS_DIR":
                        GTD_CONFIG["gtd_projects_dir"] = value
                    elif key == "GTD_TASKS_DIR":
                        GTD_CONFIG["gtd_tasks_dir"] = value
                    elif key == "GTD_AREAS_DIR":
                        GTD_CONFIG["gtd_areas_dir"] = value
        # Don't break - read from all config files, later ones override earlier ones

# Get deep model configuration
# Priority: env var > config file > default
DEEP_MODEL_URL = os.getenv("GTD_DEEP_MODEL_URL", GTD_CONFIG.get("deep_model_url", GTD_CONFIG.get("url", "http://localhost:1234/v1/chat/completions")))
DEEP_MODEL_NAME = os.getenv("GTD_DEEP_MODEL_NAME") or os.getenv("GTD_DEEP_MODEL") or GTD_CONFIG.get("deep_model_name") or "gpt-oss-20b"

# GTD Directory Structure
GTD_BASE_DIR = Path(GTD_CONFIG.get("gtd_base_dir", str(Path.home() / "Documents" / "gtd")))
GTD_PROJECTS_DIR = GTD_CONFIG.get("gtd_projects_dir", "1-projects")
GTD_TASKS_DIR = GTD_CONFIG.get("gtd_tasks_dir", "tasks")
GTD_AREAS_DIR = GTD_CONFIG.get("gtd_areas_dir", "2-areas")
DAILY_LOG_DIR = Path.home() / "Documents" / "daily_logs"

# GTD Data Keywords for Detection
GTD_KEYWORDS = {
    "projects": ["project", "projects", "my projects", "all projects", "active projects"],
    "tasks": ["task", "tasks", "my tasks", "all tasks", "todo", "todos", "active tasks"],
    "areas": ["area", "areas", "responsibilities", "areas of responsibility"],
    "goals": ["goal", "goals", "my goals", "active goals"],
    "logs": ["daily log", "log", "recent", "past week", "daily logs"],
    "gtd": ["gtd", "getting things done", "gtd system", "gtd workflow"],
}

# ============================================================================
# GTD Data Gathering Functions
# ============================================================================

def extract_frontmatter(file_path: Path) -> Dict[str, Any]:
    """Extract frontmatter from a markdown file."""
    if not file_path.exists():
        return {}
    
    frontmatter = {}
    in_frontmatter = False
    frontmatter_lines = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip() == "---":
                    if in_frontmatter:
                        break
                    in_frontmatter = True
                    continue
                if in_frontmatter:
                    frontmatter_lines.append(line.rstrip())
    except Exception:
        return {}
    
    for line in frontmatter_lines:
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            frontmatter[key] = value
    
    return frontmatter


def gather_projects_data(status_filter: str = "active") -> List[Dict[str, Any]]:
    """Gather project data from GTD system."""
    projects = []
    projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
    
    if not projects_dir.exists():
        return projects
    
    for project_dir in projects_dir.iterdir():
        if not project_dir.is_dir():
            continue
        
        readme_path = project_dir / "README.md"
        if not readme_path.exists():
            continue
        
        frontmatter = extract_frontmatter(readme_path)
        project_status = frontmatter.get("status", "active")
        
        if status_filter != "all" and project_status != status_filter:
            continue
        
        # Count tasks in project
        task_count = len([f for f in project_dir.glob("*.md") if f.name != "README.md"])
        
        projects.append({
            "name": project_dir.name.replace("-", " ").title(),
            "status": project_status,
            "task_count": task_count,
            "created": frontmatter.get("created", ""),
        })
    
    return projects


def gather_tasks_data(status_filter: str = "active", limit: int = 50) -> List[Dict[str, Any]]:
    """Gather task data from GTD system."""
    tasks = []
    tasks_dir = GTD_BASE_DIR / GTD_TASKS_DIR
    projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
    
    # Collect from tasks directory
    if tasks_dir.exists():
        for task_file in tasks_dir.glob("*.md"):
            if len(tasks) >= limit:
                break
            frontmatter = extract_frontmatter(task_file)
            if frontmatter.get("status", "active") == status_filter:
                tasks.append({
                    "title": frontmatter.get("title", task_file.stem),
                    "status": frontmatter.get("status", "active"),
                    "context": frontmatter.get("context", ""),
                    "priority": frontmatter.get("priority", ""),
                    "project": frontmatter.get("project", ""),
                })
    
    # Collect from project directories
    if projects_dir.exists():
        for project_dir in projects_dir.iterdir():
            if not project_dir.is_dir() or len(tasks) >= limit:
                break
            for task_file in project_dir.glob("*.md"):
                if task_file.name == "README.md" or len(tasks) >= limit:
                    continue
                frontmatter = extract_frontmatter(task_file)
                if frontmatter.get("status", "active") == status_filter:
                    tasks.append({
                        "title": frontmatter.get("title", task_file.stem),
                        "status": frontmatter.get("status", "active"),
                        "context": frontmatter.get("context", ""),
                        "priority": frontmatter.get("priority", ""),
                        "project": project_dir.name.replace("-", " ").title(),
                    })
    
    return tasks


def gather_areas_data() -> List[Dict[str, Any]]:
    """Gather area data from GTD system."""
    areas = []
    areas_dir = GTD_BASE_DIR / GTD_AREAS_DIR
    
    if not areas_dir.exists():
        return areas
    
    for area_file in areas_dir.glob("*.md"):
        frontmatter = extract_frontmatter(area_file)
        if frontmatter.get("status", "active") == "active":
            areas.append({
                "name": area_file.stem.replace("-", " ").title(),
                "status": frontmatter.get("status", "active"),
            })
    
    return areas


def gather_goals_data() -> List[Dict[str, Any]]:
    """Gather goal data from GTD system."""
    goals = []
    goals_dir = GTD_BASE_DIR / "goals"
    
    if not goals_dir.exists():
        return goals
    
    for goal_file in goals_dir.glob("*.md"):
        frontmatter = extract_frontmatter(goal_file)
        if frontmatter.get("status", "active") == "active":
            goals.append({
                "name": frontmatter.get("name", goal_file.stem.replace("-", " ").title()),
                "status": frontmatter.get("status", "active"),
                "progress": frontmatter.get("progress", "0"),
            })
    
    return goals


def gather_daily_logs_data(days: int = 7) -> str:
    """Gather daily log data from the past N days."""
    logs_content = []
    today = datetime.now()
    
    for i in range(days):
        date = today - timedelta(days=i)
        date_str = date.strftime("%Y-%m-%d")
        log_file = DAILY_LOG_DIR / f"{date_str}.txt"
        
        if log_file.exists():
            try:
                with open(log_file, 'r', encoding='utf-8') as f:
                    content = f.read().strip()
                    if content:
                        logs_content.append(f"--- {date_str} ---\n{content}")
            except Exception:
                continue
    
    return "\n\n".join(logs_content)


def detect_gtd_data_needs(prompt: str) -> Dict[str, bool]:
    """Detect what GTD data should be gathered based on prompt keywords."""
    prompt_lower = prompt.lower()
    needs = {
        "projects": False,
        "tasks": False,
        "areas": False,
        "goals": False,
        "logs": False,
        "gtd": False,
    }
    
    for category, keywords in GTD_KEYWORDS.items():
        for keyword in keywords:
            if keyword.lower() in prompt_lower:
                needs[category] = True
                break
    
    return needs


def enhance_prompt_with_gtd_data(prompt: str) -> str:
    """Enhance a prompt with actual GTD data if relevant."""
    needs = detect_gtd_data_needs(prompt)
    
    # If no GTD keywords detected, return original prompt
    if not any(needs.values()):
        return prompt
    
    enhancements = []
    
    # Gather projects data
    if needs["projects"] or needs["gtd"]:
        projects = gather_projects_data("active")
        if projects:
            enhancements.append("ACTIVE PROJECTS:")
            for project in projects[:10]:  # Limit to 10 for prompt size
                enhancements.append(f"- {project['name']} (status: {project['status']}, {project['task_count']} tasks)")
            enhancements.append("")
    
    # Gather tasks data
    if needs["tasks"] or needs["gtd"]:
        tasks = gather_tasks_data("active", limit=20)
        if tasks:
            # Group by context for better organization
            by_context = {}
            for task in tasks:
                context = task.get("context", "uncategorized")
                if context not in by_context:
                    by_context[context] = []
                by_context[context].append(task["title"])
            
            enhancements.append("ACTIVE TASKS:")
            for context, task_list in by_context.items():
                enhancements.append(f"- {context}: {len(task_list)} tasks")
                for task_title in task_list[:5]:  # Max 5 per context
                    enhancements.append(f"  * {task_title}")
            enhancements.append("")
    
    # Gather areas data
    if needs["areas"] or needs["gtd"]:
        areas = gather_areas_data()
        if areas:
            enhancements.append("AREAS OF RESPONSIBILITY:")
            for area in areas:
                enhancements.append(f"- {area['name']}")
            enhancements.append("")
    
    # Gather goals data
    if needs["goals"]:
        goals = gather_goals_data()
        if goals:
            enhancements.append("ACTIVE GOALS:")
            for goal in goals:
                enhancements.append(f"- {goal['name']} (progress: {goal.get('progress', '0')}%)")
            enhancements.append("")
    
    # Gather daily logs
    if needs["logs"]:
        logs = gather_daily_logs_data(days=7)
        if logs:
            # Summarize logs instead of full content (to avoid token limits)
            enhancements.append("RECENT DAILY LOG SUMMARY (past 7 days):")
            enhancements.append("(Daily logs contain health data, activities, and notes)")
            enhancements.append("")
    
    # If we have enhancements, prepend them to the prompt
    if enhancements:
        enhanced_prompt = "\n".join(enhancements)
        enhanced_prompt += "\n\n" + prompt
        
        # Add format-specific syntax reminders
        prompt_lower = prompt.lower()
        if "dot" in prompt_lower or "graphviz" in prompt_lower:
            enhanced_prompt += "\n\nCRITICAL FOR DOT SYNTAX: When using the GTD data above, create simple node IDs (Proj1, Task1, Area1) and put the actual names/descriptions in [label=\"...\"] attributes. Define all nodes first, then add edges using only node IDs (Node1 -- Node2). Never put text directly after -- in edges."
        else:
            enhanced_prompt += "\n\nUse the actual GTD data provided above to create an accurate diagram based on my real system structure."
        
        return enhanced_prompt
    
    return prompt


def call_deep_model(prompt: str, system_prompt: str = None, max_tokens: int = 4000, enhance_with_gtd_data: bool = True) -> str:
    """Call the deep AI model for diagram generation.
    
    Args:
        prompt: The user prompt for diagram generation
        system_prompt: Optional system prompt (defaults to diagram expert)
        max_tokens: Maximum tokens for response
        enhance_with_gtd_data: Whether to enhance prompt with GTD data (default: True)
    """
    
    # Enhance prompt with GTD data if enabled
    if enhance_with_gtd_data:
        enhanced_prompt = enhance_prompt_with_gtd_data(prompt)
        if enhanced_prompt != prompt:
            print("📊 Gathering GTD data to enhance diagram...", file=sys.stderr)
        prompt = enhanced_prompt
    
    if system_prompt is None:
        system_prompt = "You are an expert at creating visual diagrams and mindmaps. You understand diagram syntax perfectly and generate correct, well-structured diagrams. Pay special attention to using real data when provided. For DOT/Graphviz format: node IDs must be simple (alphanumeric + underscore only), define all nodes first with [label=\"...\"] attributes, then connect with simple edges (Node1 -- Node2). Never use colons, brackets, or text directly in edge syntax."
    
    # Check if model URL is accessible and find matching model
    actual_model_name = DEEP_MODEL_NAME
    try:
        base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
        test_req = urllib.request.Request(f"{base_url}/v1/models", headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(test_req, timeout=5) as test_response:
            models_data = json.loads(test_response.read().decode('utf-8'))
            available_models = [m.get('id', '') for m in models_data.get('data', [])]
            
            # Check for exact match first
            if DEEP_MODEL_NAME in available_models:
                actual_model_name = DEEP_MODEL_NAME
            else:
                # Try partial match
                matched = False
                for model_id in available_models:
                    if DEEP_MODEL_NAME in model_id or model_id.endswith(DEEP_MODEL_NAME) or model_id in DEEP_MODEL_NAME:
                        actual_model_name = model_id
                        matched = True
                        break
                
                if not matched and available_models:
                    # Use first available model if exact match not found
                    actual_model_name = available_models[0]
                    print(f"⚠️  Model '{DEEP_MODEL_NAME}' not found. Using '{actual_model_name}' instead.", file=sys.stderr)
    except Exception as e:
        print(f"⚠️  Could not check available models: {e}. Using configured model name.", file=sys.stderr)
    
    payload = {
        "model": actual_model_name,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": max_tokens,
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        DEEP_MODEL_URL,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    # Get timeout from config, environment variable, or default to 120
    timeout = int(os.getenv("DEEP_MODEL_TIMEOUT", 
                            GTD_CONFIG.get("deep_model_timeout", 120)))
    
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'error' in result:
                error_msg = result['error'].get('message', 'Unknown error')
                return f"Error from AI: {error_msg}"
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            return "No response from AI"
    except urllib.error.URLError as e:
        # Check if it's a timeout error
        if hasattr(e, 'reason') and isinstance(e.reason, Exception):
            error_str = str(e.reason).lower()
            if 'timed out' in error_str or 'timeout' in error_str:
                return f"Error calling deep AI: timed out after {timeout}s. Model: {DEEP_MODEL_NAME}, URL: {DEEP_MODEL_URL}\n\nThinking models need more time. Increase DEEP_MODEL_TIMEOUT in config."
        return f"Error connecting to AI: {e}. Check that the deep model is running at {DEEP_MODEL_URL}"
    except Exception as e:
        error_str = str(e).lower()
        if 'timed out' in error_str or 'timeout' in error_str:
            return f"Error calling deep AI: timed out after {timeout}s. Model: {DEEP_MODEL_NAME}, URL: {DEEP_MODEL_URL}\n\nThinking models need more time. Increase DEEP_MODEL_TIMEOUT in config."
        return f"Error calling deep AI: {e}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: gtd_deep_model_helper.py '<prompt>' [system_prompt] [--no-gtd-data]", file=sys.stderr)
        sys.exit(1)
    
    prompt = sys.argv[1]
    # If system prompt provided as second arg, use it; otherwise use default
    system_prompt = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    
    # Check for --no-gtd-data flag
    enhance_with_gtd_data = "--no-gtd-data" not in sys.argv
    
    response = call_deep_model(prompt, system_prompt, max_tokens=4000, enhance_with_gtd_data=enhance_with_gtd_data)
    print(response)

