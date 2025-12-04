#!/bin/bash
# Script to update all gtd-* bash scripts to source common_env.sh
# This ensures all gtd commands have access to the PATH configuration

COMMON_ENV_SNIPPET='# Source common environment (PATH setup)
COMMON_ENV="$HOME/code/dotfiles/zsh/common_env.sh"
if [[ ! -f "$COMMON_ENV" && -f "$HOME/code/personal/dotfiles/zsh/common_env.sh" ]]; then
  COMMON_ENV="$HOME/code/personal/dotfiles/zsh/common_env.sh"
fi
if [[ -f "$COMMON_ENV" ]]; then
  source "$COMMON_ENV"
fi

'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATED=0
SKIPPED=0

for script in "$SCRIPT_DIR"/gtd-*; do
  # Skip if not a file or not executable/bash script
  [[ ! -f "$script" ]] && continue
  [[ ! "$script" =~ \.(sh|bash)$ ]] && [[ "$(head -1 "$script")" != "#!/bin/bash" ]] && continue
  
  # Skip if already has common_env sourcing
  if grep -q "common_env.sh" "$script" 2>/dev/null; then
    echo "⏭️  Skipping $(basename "$script") - already has common_env sourcing"
    ((SKIPPED++))
    continue
  fi
  
  # Find the line after the shebang and description
  # Look for "# Load GTD config" or similar patterns
  if grep -q "^# Load GTD config" "$script" 2>/dev/null || grep -q "^# Load config" "$script" 2>/dev/null; then
    # Use sed to insert after the first comment block and before "Load GTD config"
    # This is a bit tricky, so we'll use a temp file
    temp_file=$(mktemp)
    
    # Find the line number of "# Load GTD config" or "# Load config"
    load_line=$(grep -n "^# Load" "$script" | head -1 | cut -d: -f1)
    
    if [[ -n "$load_line" ]]; then
      # Copy everything before that line
      head -n $((load_line - 1)) "$script" > "$temp_file"
      # Add the common env snippet
      echo "$COMMON_ENV_SNIPPET" >> "$temp_file"
      # Copy everything from that line onwards
      tail -n +$load_line "$script" >> "$temp_file"
      # Replace the original
      mv "$temp_file" "$script"
      echo "✅ Updated $(basename "$script")"
      ((UPDATED++))
    else
      echo "⚠️  Could not find insertion point in $(basename "$script")"
      rm -f "$temp_file"
    fi
  else
    echo "⚠️  Skipping $(basename "$script") - unexpected format"
    ((SKIPPED++))
  fi
done

echo ""
echo "Summary: $UPDATED updated, $SKIPPED skipped"

