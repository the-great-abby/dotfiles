#!/usr/bin/env python3
"""
Simple project suggestion script using fast AI model.

This script suggests which project a task belongs to, using the fast AI model
instead of the deep thinking model for quick, concise responses.
"""

import sys
import json
import re
from pathlib import Path

# Add parent directories to path
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent
sys.path.insert(0, str(dotfiles_dir))

try:
    from mcp.gtd_mcp_server import call_fast_ai
except ImportError:
    # Try alternative import path
    sys.path.insert(0, str(dotfiles_dir / "mcp"))
    try:
        from gtd_mcp_server import call_fast_ai
    except ImportError:
        print("Error: Could not import call_fast_ai", file=sys.stderr)
        sys.exit(1)


def suggest_project(task_name: str, task_content: str, projects_list: str) -> str:
    """Suggest which project a task belongs to.
    
    Args:
        task_name: The task title/name
        task_content: The full task content
        projects_list: Comma-separated list of available projects
        
    Returns:
        Suggested project name (or 'none')
    """
    # Build a clear, focused prompt
    prompt = f"""Task: {task_name}

Task content:
{task_content[:1000]}

Available projects: {projects_list}

Which project does this task belong to? 

IMPORTANT: Return ONLY the project name from the list above, or 'none' if it doesn't fit any project. 
Do not include any explanation, reasoning, or additional text. Just the project name."""
    
    system_prompt = "You are a GTD organization assistant. Your job is to match tasks to projects. Return only the project name, nothing else."
    
    try:
        response = call_fast_ai(prompt, system_prompt)
        
        if not response or response.startswith("Error"):
            return "none"
        
        # Clean up response - extract just the project name
        # Remove any leading/trailing whitespace
        response = response.strip()
        
        # Try to extract just the project name
        # Remove common prefixes/suffixes that models might add
        response = re.sub(r'^(project|suggested project|recommended project|belongs to|should be|is):?\s*', '', response, flags=re.IGNORECASE)
        response = re.sub(r'\s*(project|\.|,|;|:).*$', '', response, flags=re.IGNORECASE)
        
        # Convert to lowercase and replace spaces with hyphens
        suggested_project = response.lower().strip().replace(' ', '-')
        
        # Remove any non-alphanumeric except hyphens
        suggested_project = re.sub(r'[^a-z0-9-]', '', suggested_project)
        
        # Check if it matches any project in the list
        projects = [p.strip().lower() for p in projects_list.split(',') if p.strip()]
        
        # Try exact match first
        for project in projects:
            if project == suggested_project:
                return project
        
        # Try partial match (in case of slight variations)
        for project in projects:
            if project in suggested_project or suggested_project in project:
                return project
        
        # If it's "none" or empty, return "none"
        if not suggested_project or suggested_project == "none":
            return "none"
        
        # If it doesn't match any project, return "none"
        return "none"
        
    except Exception as e:
        print(f"Error calling AI: {e}", file=sys.stderr)
        return "none"


def main():
    """Main entry point for command-line usage."""
    if len(sys.argv) < 4:
        print("Usage: gtd_project_suggest.py <task_name> <task_content_file> <projects_list>", file=sys.stderr)
        sys.exit(1)
    
    task_name = sys.argv[1]
    task_content_file = sys.argv[2]
    projects_list = sys.argv[3]
    
    # Read task content
    try:
        with open(task_content_file, 'r', encoding='utf-8') as f:
            task_content = f.read()
    except Exception as e:
        print(f"Error reading task file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Get suggestion
    suggested = suggest_project(task_name, task_content, projects_list)
    print(suggested)
    
    sys.exit(0 if suggested != "none" else 1)


if __name__ == "__main__":
    main()

