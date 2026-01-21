#!/bin/bash
# RPG Equipment Skill Execution Script
# Manages equipment inventory and bonuses

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action from environment or argument
ACTION="${SKILL_ARG_action:-${1:-view}}"
ITEM="${SKILL_ARG_item:-${2:-}}"

# Run the Python equipment manager
python3 "$SCRIPT_DIR/equipment_manager.py" "$ACTION" "$ITEM"
