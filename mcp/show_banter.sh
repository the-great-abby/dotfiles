#!/bin/bash
# Show banter for the most recent log entry
# This is called after a short delay to show auto-suggestion banter

AUTO_SUGGEST_SCRIPT="$HOME/code/dotfiles/mcp/gtd_auto_suggest.py"
if [[ ! -f "$AUTO_SUGGEST_SCRIPT" ]]; then
  AUTO_SUGGEST_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_auto_suggest.py"
fi

if [[ ! -f "$AUTO_SUGGEST_SCRIPT" ]]; then
  exit 0
fi

# Get the most recent log entry
DAILY_LOG_DIR="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
today=$(date +"%Y-%m-%d")
log_file="${DAILY_LOG_DIR}/${today}.txt"

if [[ ! -f "$log_file" ]]; then
  exit 0
fi

# Get the last entry (format: "HH:MM - entry text")
last_entry=$(tail -1 "$log_file" | sed 's/^[0-9:]* - //')

if [[ -z "$last_entry" ]]; then
  exit 0
fi

# Generate banter
banter=$(python3 "$AUTO_SUGGEST_SCRIPT" banter "$last_entry" 2>/dev/null)

if [[ -n "$banter" ]]; then
  echo ""
  echo "💬 $banter"
fi

