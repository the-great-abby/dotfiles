#!/bin/bash
# Inbox Processing Skill Execution Script
# Executes the inbox processing workflow using existing GTD commands

# Use the existing process command which already implements GTD inbox processing
if command -v gtd-process &>/dev/null; then
  gtd-process
elif [[ -f "$HOME/code/dotfiles/bin/gtd-process" ]]; then
  "$HOME/code/dotfiles/bin/gtd-process"
elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-process" ]]; then
  "$HOME/code/personal/dotfiles/bin/gtd-process"
else
  echo "Error: gtd-process command not found"
  exit 1
fi
