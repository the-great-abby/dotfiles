#!/bin/bash
# Integration hook for daily log auto-suggestions
# Add this to your daily log workflow to enable auto-suggestions

AUTO_SUGGEST_SCRIPT="$(dirname "$0")/gtd_auto_suggest.py"

# Check if auto-suggest script exists
if [[ ! -f "$AUTO_SUGGEST_SCRIPT" ]]; then
    echo "⚠️  Auto-suggest script not found: $AUTO_SUGGEST_SCRIPT"
    exit 1
fi

# Get the log entry from arguments or stdin
if [[ $# -gt 0 ]]; then
    LOG_ENTRY="$*"
else
    # Read from stdin
    LOG_ENTRY=$(cat)
fi

if [[ -z "$LOG_ENTRY" ]]; then
    echo "Usage: $0 'your log entry'"
    exit 1
fi

# Run auto-suggestion in background (don't block logging)
python3 "$AUTO_SUGGEST_SCRIPT" entry "$LOG_ENTRY" > /dev/null 2>&1 &

echo "✓ Auto-suggestion queued in background"

