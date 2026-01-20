#!/usr/bin/env python3
"""
Read personalization data from ~/.gtd_personalization.toon (TOON format)
Can filter by category if provided.
"""

import json
import os
import sys
from pathlib import Path

# Import TOON helper
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent / "zsh" / "functions"))
try:
    from gtd_toon_helper import load_toon_file, get_personalization_file_path
except ImportError:
    # Fallback if helper not available
    def get_personalization_file_path():
        return Path.home() / ".gtd_personalization.toon"
    def load_toon_file(path):
        import json
        json_path = path.with_suffix('.json')
        if json_path.exists():
            with open(json_path, 'r') as f:
                return json.load(f)
        return {}

# Get personalization file path
PERSONALIZATION_FILE = get_personalization_file_path()

def read_personalization(category=None):
    """Read personalization data, optionally filtered by category."""
    try:
        data = load_toon_file(PERSONALIZATION_FILE)
        
        # If data is empty, file doesn't exist
        if not data:
            return {
                "error": "Personalization file not found",
                "message": "User has not set up personalization yet. Suggest running: gtd-wizard → option 67",
                "file_path": str(PERSONALIZATION_FILE)
            }
        
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
