#!/usr/bin/env python3
"""
Read personalization data from ~/.gtd_personalization.json
Can filter by category if provided.
"""

import json
import os
import sys
from pathlib import Path

# Get personalization file path
PERSONALIZATION_FILE = Path.home() / ".gtd_personalization.json"

def read_personalization(category=None):
    """Read personalization data, optionally filtered by category."""
    if not PERSONALIZATION_FILE.exists():
        return {
            "error": "Personalization file not found",
            "message": "User has not set up personalization yet. Suggest running: gtd-wizard → option 67",
            "file_path": str(PERSONALIZATION_FILE)
        }
    
    try:
        with open(PERSONALIZATION_FILE, 'r') as f:
            data = json.load(f)
        
        # If category specified, return only that category
        if category:
            if category in data:
                return {
                    "category": category,
                    "data": data[category],
                    "last_updated": data.get("last_updated")
                }
            else:
                return {
                    "error": f"Category '{category}' not found",
                    "available_categories": list(data.keys())
                }
        
        # Return full data
        return data
    
    except json.JSONDecodeError as e:
        return {
            "error": "Invalid JSON in personalization file",
            "message": str(e),
            "file_path": str(PERSONALIZATION_FILE)
        }
    except Exception as e:
        return {
            "error": "Error reading personalization file",
            "message": str(e),
            "file_path": str(PERSONALIZATION_FILE)
        }

def main():
    """Main entry point for script execution."""
    # Get category from args if provided
    category = None
    if len(sys.argv) > 1:
        category = sys.argv[1]
    
    # Check for SKILL_ARGS environment variable (from execute_agent_skill)
    skill_args = os.environ.get("SKILL_ARGS")
    if skill_args:
        try:
            args = json.loads(skill_args)
            category = args.get("category", category)
        except json.JSONDecodeError:
            pass
    
    # Read and return personalization data
    result = read_personalization(category)
    
    # Output as JSON
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
