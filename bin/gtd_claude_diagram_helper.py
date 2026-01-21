#!/usr/bin/env python3
"""
Claude Diagram Helper - Generate diagrams using Claude API

This script uses the Claude API (via claude_ollama_bridge) to generate
diagrams in various formats (Mermaid, PlantUML, DOT, Text).
Enhanced to gather GTD data before calling Claude for more accurate diagrams.
"""

import sys
import os
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

# Add parent directory to path to import claude_ollama_bridge
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp"))

try:
    from claude_ollama_bridge import SmartAIRouter
except ImportError:
    print("❌ Error: Could not import SmartAIRouter from claude_ollama_bridge", file=sys.stderr)
    print("   Make sure mcp/claude_ollama_bridge.py exists", file=sys.stderr)
    sys.exit(1)

# Load GTD configuration
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
                    if key == "GTD_BASE_DIR":
                        GTD_CONFIG["gtd_base_dir"] = value.replace("$HOME", str(Path.home()))
                    elif key == "GTD_PROJECTS_DIR":
                        GTD_CONFIG["gtd_projects_dir"] = value
                    elif key == "GTD_TASKS_DIR":
                        GTD_CONFIG["gtd_tasks_dir"] = value
                    elif key == "GTD_AREAS_DIR":
                        GTD_CONFIG["gtd_areas_dir"] = value

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
# GTD Data Gathering Functions (from gtd_deep_model_helper.py)
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


def generate_diagram_with_claude(prompt: str, system_prompt: str = None, max_tokens: int = 4000, enhance_with_gtd_data: bool = True) -> str:
    """Generate a diagram using Claude API.
    
    Args:
        prompt: The user prompt for diagram generation
        system_prompt: Optional system prompt (defaults to diagram expert)
        max_tokens: Maximum tokens for response
        enhance_with_gtd_data: Whether to enhance prompt with GTD data (default: True)
        
    Returns:
        The generated diagram code as a string
    """
    
    # Enhance prompt with GTD data if enabled
    if enhance_with_gtd_data:
        enhanced_prompt = enhance_prompt_with_gtd_data(prompt)
        if enhanced_prompt != prompt:
            print("📊 Gathering GTD data to enhance diagram...", file=sys.stderr)
        prompt = enhanced_prompt
    
    # Initialize router
    router = SmartAIRouter()
    
    # Check if Claude API is available
    if not router.anthropic_api_key:
        return "❌ Error: Claude API key not configured. Set ANTHROPIC_API_KEY environment variable or configure in .gtd_config_ai"
    
    # Default system prompt for diagram generation
    if system_prompt is None:
        system_prompt = """You are an expert at creating visual diagrams and mindmaps. You understand diagram syntax perfectly and generate correct, well-structured diagrams. 

CRITICAL REQUIREMENTS:
- Pay special attention to proper syntax and structure
- For DOT/Graphviz: use simple node IDs (alphanumeric only), define nodes first with [label="..."], connect with simple edges (Node1 -- Node2). Never use colons, brackets, or text directly in edges.
- For Mermaid: use valid Mermaid syntax, ensure proper indentation for mindmaps
- For PlantUML: use proper @startuml/@enduml tags and valid PlantUML syntax
- Output ONLY the diagram code in a code block, no explanations outside the code block
- When provided with real GTD data, use it accurately in the diagram"""
    
    # Build context
    context = {
        "max_tokens": max_tokens,
        "request_type": "diagram_generation"
    }
    
    # Call Claude API
    result, error = router._call_claude(
        request_type="diagram_generation",
        content=prompt,
        persona=None,  # No persona for diagram generation
        context=context
    )
    
    if error:
        return f"❌ Error calling Claude API: {error}"
    
    if not result:
        return "❌ No response from Claude API"
    
    # Extract response text
    response_text = result.get("response", "")
    
    if not response_text:
        return "❌ Empty response from Claude API"
    
    return response_text


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: gtd_claude_diagram_helper.py <prompt> [system_prompt]", file=sys.stderr)
        sys.exit(1)
    
    prompt = sys.argv[1]
    system_prompt = sys.argv[2] if len(sys.argv) > 2 else None
    
    result = generate_diagram_with_claude(prompt, system_prompt)
    print(result)
