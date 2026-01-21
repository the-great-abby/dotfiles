#!/bin/bash
# RPG Quest Tracker Skill Execution Script
# Tracks quest progress and provides recommendations

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action from environment or argument
ACTION="${SKILL_ARG_action:-${1:-view}}"
QUEST_ID="${SKILL_ARG_quest_id:-${2:-}}"

# Run the Python quest tracker
python3 "$SCRIPT_DIR/quest_tracker.py" "$ACTION" "$QUEST_ID"
