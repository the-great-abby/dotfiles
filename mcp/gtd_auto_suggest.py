#!/usr/bin/env python3
"""
GTD Auto-Suggestion System with Intelligent Banter

Analyzes daily log entries and generates smart task suggestions with
contextual, engaging banter/responses.
"""

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional

# Import the suggestion system from MCP server  
sys.path.insert(0, str(Path(__file__).parent))
from gtd_mcp_server import call_fast_ai, save_suggestion, GTD_BASE_DIR

# Import read_config from persona helper
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
from gtd_persona_helper import read_config

# Daily log directory
DAILY_LOG_DIR = Path.home() / "Documents" / "daily_logs"
if not DAILY_LOG_DIR.exists():
    # Check config
    config = read_config()
    if "DAILY_LOG_DIR" in os.environ:
        DAILY_LOG_DIR = Path(os.environ["DAILY_LOG_DIR"])

LM_CONFIG = read_config()
USER_NAME = os.getenv("GTD_USER_NAME", "Abby")


def read_daily_log(date: Optional[str] = None) -> str:
    """Read today's daily log or a specific date."""
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")
    
    log_file = DAILY_LOG_DIR / f"{date}.txt"
    if log_file.exists():
        with open(log_file, 'r') as f:
            return f.read()
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


def analyze_log_entry(entry: str, context: str = "daily_log") -> List[Dict[str, Any]]:
    """
    Analyze a log entry and generate task suggestions with banter.
    
    Returns list of suggestions with:
    - title: Task title
    - reason: Why this task matters
    - confidence: 0.0-1.0
    - banter: Engaging, contextual response
    - context: Suggested context
    - priority: Suggested priority
    """
    
    prompt = f"""Analyze this daily log entry and extract actionable tasks. Return ONLY a valid JSON array.

Log entry: {entry}

If you find actionable tasks, return a JSON array like this:
[
  {{
    "title": "Clear actionable task",
    "reason": "Why this matters",
    "confidence": 0.8,
    "context": "computer",
    "priority": "not_urgent_important"
  }}
]

If no tasks found, return: []

IMPORTANT: Return ONLY the JSON array, no other text, no explanations, no markdown formatting."""

    system_prompt = f"""You are {USER_NAME}'s thoughtful GTD assistant. You read their daily logs and suggest tasks with warm, contextual banter. You understand their work style, challenges, and goals. Your suggestions are practical, actionable, and your banter feels like a helpful friend checking in."""

    response = call_fast_ai(prompt, system_prompt)
    
    # Extract JSON array with better error handling
    suggestions = []
    try:
        # Try to find JSON array in response
        # Look for array that might be in code blocks or plain text
        json_match = re.search(r'\[\s*\{.*?\}\s*\]', response, re.DOTALL)
        if not json_match:
            # Try without strict formatting
            json_match = re.search(r'\[.*?\]', response, re.DOTALL)
        
        if json_match:
            json_str = json_match.group().strip()
            # Clean up common issues
            json_str = json_str.replace('\n', ' ').replace('\r', '')
            # Remove markdown code blocks if present
            json_str = re.sub(r'```json\s*', '', json_str)
            json_str = re.sub(r'```\s*', '', json_str)
            suggestions = json.loads(json_str)
        else:
            # No array found, try to parse any JSON objects
            suggestions = []
    except json.JSONDecodeError as e:
        # Try to extract individual task objects if array parsing fails
        try:
            # Look for individual objects
            obj_matches = re.findall(r'\{[^{}]*\}', response)
            for obj_str in obj_matches:
                try:
                    obj = json.loads(obj_str)
                    if 'title' in obj or 'task' in obj.lower():
                        suggestions.append(obj)
                except:
                    pass
        except:
            pass
    except Exception as e:
        # If all parsing fails, return empty
        suggestions = []
    
    return suggestions


def process_log_entry_with_banter(entry: str, timestamp: str = None) -> Dict[str, Any]:
    """
    Process a single log entry and create suggestions with banter.
    
    Returns dict with:
    - suggestions: List of suggestion dicts
    - banter: Overall response to the log entry
    - analyzed: True if analysis was done
    """
    
    if timestamp is None:
        timestamp = datetime.now().isoformat()
    
    # Analyze for tasks
    suggestions = analyze_log_entry(entry)
    
    # Generate overall banter/response
    banter_prompt = f"""You're {USER_NAME}'s GTD assistant. They just logged:

{entry}

Provide a brief, warm, contextual response (2-3 sentences max). 
- If they mentioned completing something, celebrate it
- If they're stuck, offer encouragement
- If they're planning, show excitement
- Be conversational and natural
- Reference specific things from their entry

Just give the response text, no JSON or formatting."""

    banter = call_fast_ai(banter_prompt, f"You are {USER_NAME}'s encouraging, supportive GTD assistant.")
    
    # Save suggestions
    saved_suggestion_ids = []
    for suggestion in suggestions:
        suggestion["status"] = "pending"
        suggestion["source_entry"] = entry
        suggestion["source_timestamp"] = timestamp
        suggestion["banter"] = suggestion.get("banter", banter)
        suggestion_id = save_suggestion(suggestion)
        saved_suggestion_ids.append(suggestion_id)
    
    return {
        "suggestions": saved_suggestion_ids,
        "banter": banter,
        "suggestion_count": len(saved_suggestion_ids),
        "timestamp": timestamp
    }


def auto_suggest_from_recent_logs(days: int = 1) -> Dict[str, Any]:
    """Analyze recent daily logs and generate suggestions."""
    logs = read_recent_logs(days)
    
    all_results = []
    for log in logs:
        # Parse entries (assume format: "HH:MM - entry text")
        entries = re.findall(r'\d{2}:\d{2}\s*-\s*(.+)', log["content"])
        
        for entry in entries:
            if entry.strip():
                result = process_log_entry_with_banter(entry, f"{log['date']}T00:00:00")
                all_results.append(result)
    
    return {
        "processed_logs": len(logs),
        "results": all_results,
        "total_suggestions": sum(r["suggestion_count"] for r in all_results)
    }


def generate_banter_for_log(entry: str) -> str:
    """Generate banter for a log entry without creating suggestions."""
    banter_prompt = f"""You're {USER_NAME}'s GTD assistant. They just logged:

{entry}

Provide a brief, warm, contextual response (2-3 sentences max). 
- If they mentioned completing something, celebrate it
- If they're stuck, offer encouragement  
- If they're planning, show excitement
- Be conversational and natural
- Reference specific things from their entry

Just give the response text, no JSON or formatting."""

    return call_fast_ai(banter_prompt, f"You are {USER_NAME}'s encouraging, supportive GTD assistant.")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "analyze":
            # Analyze recent logs
            days = int(sys.argv[2]) if len(sys.argv) > 2 else 1
            results = auto_suggest_from_recent_logs(days)
            print(json.dumps(results, indent=2))
        elif sys.argv[1] == "entry":
            # Process a single entry
            entry = " ".join(sys.argv[2:])
            result = process_log_entry_with_banter(entry)
            # Always output full JSON, caller can extract banter
            print(json.dumps(result, indent=2, default=str))
        elif sys.argv[1] == "banter":
            # Just generate banter
            entry = " ".join(sys.argv[2:])
            banter = generate_banter_for_log(entry)
            print(banter)
    else:
        print("Usage:")
        print("  gtd_auto_suggest.py analyze [days]  - Analyze recent logs")
        print("  gtd_auto_suggest.py entry <text>    - Process single entry")
        print("  gtd_auto_suggest.py banter <text>   - Generate banter only")

