#!/bin/bash
# Morning Check-In Skill Execution Script
# Executes the morning check-in workflow using existing GTD commands

# Source common GTD helpers
GTD_COMMON="$HOME/code/dotfiles/bin/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON"
fi

# Use the existing check-in command which already does this workflow
if command -v gtd-checkin &>/dev/null; then
  gtd-checkin "morning"
elif [[ -f "$HOME/code/dotfiles/bin/gtd-checkin" ]]; then
  "$HOME/code/dotfiles/bin/gtd-checkin" "morning"
elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-checkin" ]]; then
  "$HOME/code/personal/dotfiles/bin/gtd-checkin" "morning"
else
  echo "Error: gtd-checkin command not found"
  exit 1
fi
