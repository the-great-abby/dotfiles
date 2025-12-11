#!/usr/bin/env python3
"""
GTD Progress Analyzer - Analyzes daily logs to identify completed work
that hasn't been recorded as tasks or projects in the GTD system.
"""

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Set

# Import AI helper from MCP server (with graceful error handling)
sys.path.insert(0, str(Path(__file__).parent))
try:
    from gtd_mcp_server import call_fast_ai
    MCP_AVAILABLE = True
except (ImportError, SystemExit):
    # MCP server not available - define a fallback function
    MCP_AVAILABLE = False
    def call_fast_ai(prompt: str, system_prompt: str = None) -> str:
        """Fallback when MCP server is not available."""
        return "MCP server not available - cannot analyze with AI"

# Import config from persona helper
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
from gtd_persona_helper import read_config

# Default paths
GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
DAILY_LOG_DIR = Path.home() / "Documents" / "daily_logs"

# Load config
config = read_config()
USER_NAME = os.getenv("GTD_USER_NAME", "Abby")

# Override paths from config if available
if "GTD_BASE_DIR" in os.environ:
    GTD_BASE_DIR = Path(os.environ["GTD_BASE_DIR"])
if "DAILY_LOG_DIR" in os.environ:
    DAILY_LOG_DIR = Path(os.environ["DAILY_LOG_DIR"])


def get_existing_tasks() -> Set[str]:
    """Get all existing task descriptions from the GTD system."""
    tasks_path = GTD_BASE_DIR / "tasks"
    projects_path = GTD_BASE_DIR / "1-projects"
    
    existing = set()
    
    # Get tasks
    if tasks_path.exists():
        for task_file in tasks_path.glob("*.md"):
            try:
                content = task_file.read_text()
                # Extract title (first line after frontmatter or first # heading)
                title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
                if title_match:
                    existing.add(title_match.group(1).lower().strip())
            except:
                pass
    
    # Get projects
    if projects_path.exists():
        for project_file in projects_path.rglob("*.md"):
            if project_file.name == "README.md":
                continue
            try:
                content = project_file.read_text()
                title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
                if title_match:
                    existing.add(title_match.group(1).lower().strip())
            except:
                pass
    
    return existing


def read_daily_log(date: Optional[str] = None) -> str:
    """Read a daily log file."""
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")
    
    log_file = DAILY_LOG_DIR / f"{date}.md"
    if not log_file.exists():
        log_file = DAILY_LOG_DIR / f"{date}.txt"
    
    if log_file.exists():
        return log_file.read_text()
    return ""


def read_recent_logs(days: int = 7) -> List[Dict[str, Any]]:
    """Read recent daily logs."""
    logs = []
    for i in range(days):
        date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
        content = read_daily_log(date)
        if content:
            logs.append({
                "date": date,
                "content": content
            })
    return logs


def extract_completion_indicators(text: str) -> List[Dict[str, Any]]:
    """
    Extract completed work from log text using AI analysis.
    
    Returns list of completed items with:
    - description: What was completed
    - date: When it was completed
    - confidence: 0.0-1.0
    - type: "task" or "project"
    """
    
    prompt = f"""Analyze this daily log content and identify work that appears to be COMPLETED but might not be recorded in a task/project system.

Look for indicators like:
- "finished", "completed", "done", "finished working on", "wrapped up"
- "deployed", "shipped", "launched", "published"
- "fixed", "resolved", "solved"
- Past tense accomplishments: "I built", "I created", "I fixed"

Daily log content:
{text}

Return ONLY a valid JSON array of completed items. Format:
[
  {{
    "description": "Clear description of what was completed",
    "date": "YYYY-MM-DD",
    "confidence": 0.8,
    "type": "task",
    "context": "Brief context from the log"
  }}
]

Set "type" to "project" if it sounds like a multi-step effort, "task" for single actions.
Return empty array [] if no completed work found.

IMPORTANT: Return ONLY the JSON array, no other text, no markdown, no explanations."""

    system_prompt = f"""You are {USER_NAME}'s GTD assistant. You analyze daily logs to find completed work that should be tracked. Be thorough but accurate - only suggest items that clearly indicate completion."""

    # Check if MCP is available before calling
    if not MCP_AVAILABLE:
        # Return empty list if MCP is not available
        return []
    
    response = call_fast_ai(prompt, system_prompt)
    
    # Check if we got the fallback error message
    if response and "MCP server not available" in response:
        return []
    
    # Extract JSON array
    completed_items = []
    try:
        json_match = re.search(r'\[\s*\{.*?\}\s*\]', response, re.DOTALL)
        if json_match:
            json_str = json_match.group().strip()
            json_str = json_str.replace('\n', ' ').replace('\r', '')
            json_str = re.sub(r'```json\s*', '', json_str)
            json_str = re.sub(r'```\s*', '', json_str)
            completed_items = json.loads(json_str)
        else:
            completed_items = []
    except:
        completed_items = []
    
    return completed_items


def analyze_progress(days: int = 7) -> Dict[str, Any]:
    """
    Analyze recent daily logs to find completed work not in the system.
    
    Returns:
    - unrecorded_completions: List of completed items not found in system
    - progress_summary: Summary of work completed
    - suggestions: Suggestions to record items
    """
    
    logs = read_recent_logs(days)
    existing_tasks = get_existing_tasks()
    
    all_completions = []
    unrecorded_completions = []
    
    for log in logs:
        completed_items = extract_completion_indicators(log["content"])
        
        for item in completed_items:
            # Check if this matches an existing task/project
            description_lower = item.get("description", "").lower().strip()
            
            # Check for matches (simple substring matching)
            is_recorded = False
            for existing in existing_tasks:
                if description_lower in existing or existing in description_lower:
                    is_recorded = True
                    break
            
            if not is_recorded:
                item["date"] = log["date"]
                unrecorded_completions.append(item)
            
            all_completions.append(item)
    
    # Generate suggestions
    suggestions = []
    for item in unrecorded_completions[:10]:  # Limit to 10 most recent
        suggestions.append({
            "type": "record_completion",
            "item": item,
            "action": f"Record this completed {item.get('type', 'task')} in your GTD system",
            "reason": "This work was completed but not tracked in your task/project system"
        })
    
    return {
        "days_analyzed": days,
        "total_completions_found": len(all_completions),
        "unrecorded_completions": unrecorded_completions,
        "unrecorded_count": len(unrecorded_completions),
        "suggestions": suggestions,
        "analysis_date": datetime.now().isoformat()
    }


def generate_progress_summary(days: int = 7) -> str:
    """Generate a human-readable progress summary."""
    analysis = analyze_progress(days)
    
    if analysis["unrecorded_count"] == 0:
        return f"Great work! All completed work from the last {days} days appears to be properly recorded in your GTD system."
    
    summary = f"Progress Update - Last {days} Days:\n\n"
    summary += f"Found {analysis['total_completions_found']} completed items in your logs.\n"
    summary += f"{analysis['unrecorded_count']} of them are not recorded in your task/project system.\n\n"
    
    if analysis["unrecorded_completions"]:
        summary += "Unrecorded Completions:\n"
        for item in analysis["unrecorded_completions"][:5]:  # Top 5
            summary += f"  • {item.get('description', 'Unknown')} ({item.get('date', 'Unknown date')})\n"
        if analysis["unrecorded_count"] > 5:
            summary += f"  ... and {analysis['unrecorded_count'] - 5} more\n"
        summary += "\n"
        summary += "Consider recording these in your GTD system to maintain accurate progress tracking!"
    
    return summary


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "analyze":
            days = int(sys.argv[2]) if len(sys.argv) > 2 else 7
            result = analyze_progress(days)
            print(json.dumps(result, indent=2, default=str))
        elif sys.argv[1] == "summary":
            days = int(sys.argv[2]) if len(sys.argv) > 2 else 7
            summary = generate_progress_summary(days)
            print(summary)
    else:
        print("Usage:")
        print("  gtd_progress_analyzer.py analyze [days]  - Analyze and return JSON")
        print("  gtd_progress_analyzer.py summary [days]  - Generate human-readable summary")

