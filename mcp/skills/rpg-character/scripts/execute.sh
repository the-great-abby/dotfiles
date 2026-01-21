#!/bin/bash
# RPG Character Skill Execution Script
# Displays your GTD productivity as an RPG character

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get action from environment or argument
ACTION="${SKILL_ARG_action:-${1:-full}}"

# Run the Python display script
python3 "$SCRIPT_DIR/display_character.py" "$ACTION"
