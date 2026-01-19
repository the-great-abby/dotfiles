#!/bin/bash
# Daily Review Skill Execution Script
# Executes the daily review workflow using existing GTD commands

# Use the existing review command
if command -v gtd-review &>/dev/null; then
  gtd-review "daily"
elif [[ -f "$HOME/code/dotfiles/bin/gtd-review" ]]; then
  "$HOME/code/dotfiles/bin/gtd-review" "daily"
elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-review" ]]; then
  "$HOME/code/personal/dotfiles/bin/gtd-review" "daily"
else
  echo "Error: gtd-review command not found"
  exit 1
fi
