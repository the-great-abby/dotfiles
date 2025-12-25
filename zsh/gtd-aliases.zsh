# ============================================
# GTD Quick Aliases & Functions
# Add this to your ~/.zshrc or source it:
#   source ~/code/dotfiles/zsh/gtd-aliases.zsh
# ============================================

# Core aliases (always set)
alias log="addInfoToDailyLog"
alias idea="zet"
alias task="gtd-capture"
alias status="make gtd-status"

# Quick routines
alias now="gtd-now"
alias today="gtd-today"
alias morning="gtd-morning"
alias evening="gtd-evening"

# Navigation
alias inbox="cd ~/Documents/gtd/0-inbox"
alias projects="cd ~/Documents/gtd/1-projects"
alias brain="cd ~/Documents/obsidian/Second\ Brain"

# Context switching
alias work="gtd-task list --context=computer --priority=urgent_important"
alias home="gtd-task list --context=home"
alias calls="gtd-task list --context=calls"
alias errands="gtd-task list --context=errands"

# Ultra-quick capture functions (with arguments)
# Note: Using functions instead of aliases to support arguments
gtd-c() {
  if [[ -z "$1" ]]; then
    gtd-capture
  else
    gtd-capture "$*"
  fi
}

gtd-i() {
  if [[ -z "$1" ]]; then
    zet
  else
    zet "$*"
  fi
}

gtd-l() {
  if [[ -z "$1" ]]; then
    addInfoToDailyLog
  else
    addInfoToDailyLog "$*"
  fi
}

# Dashboard cache worker management
gtd-restart-dashboard-worker() {
  local worker_script="gtd_dashboard_cache_worker.py"
  local worker_wrapper="gtd-dashboard-cache-worker"
  local pid
  
  echo "🔄 Restarting Dashboard Cache Worker..."
  echo ""
  
  # Check if running and kill if needed
  if pid=$(pgrep -f "$worker_script" 2>/dev/null | head -1); then
    echo "  Stopping existing worker (PID: $pid)..."
    kill "$pid" 2>/dev/null
    sleep 2
    
    # Force kill if still running
    if pgrep -f "$worker_script" >/dev/null; then
      echo "  Force killing stuck process..."
      pkill -9 -f "$worker_script" 2>/dev/null
      sleep 1
    fi
  else
    echo "  No running worker found"
  fi
  
  # Start worker
  echo "  Starting new worker..."
  if command -v "$worker_wrapper" &>/dev/null; then
    "$worker_wrapper" 2>/dev/null
  elif [[ -f "$HOME/code/dotfiles/bin/$worker_wrapper" ]]; then
    "$HOME/code/dotfiles/bin/$worker_wrapper" 2>/dev/null
  else
    echo "  ❌ Error: Worker script not found"
    return 1
  fi
  
  # Verify it started
  sleep 1
  if pid=$(pgrep -f "$worker_script" 2>/dev/null | head -1); then
    echo ""
    echo "  ✅ Dashboard cache worker restarted (PID: $pid)"
    echo ""
    echo "📋 Useful Commands:"
    echo "  • Check status:    pgrep -f gtd_dashboard_cache_worker.py"
    echo "  • View logs:       tail -f /tmp/dashboard-cache-worker.log"
    echo "  • Stop worker:     pkill -f gtd_dashboard_cache_worker.py"
    echo "  • Restart again:   gtd-restart-dashboard-worker"
    echo "  • Check cache:     cat ~/Documents/gtd/.dashboard_cache.json | jq"
    echo ""
  else
    echo ""
    echo "  ❌ Failed to start worker"
    echo "  Check logs: tail -20 /tmp/dashboard-cache-worker.log"
    echo ""
    return 1
  fi
}

# Short aliases (only if not already defined - protects against Oh My Zsh conflicts)
if ! alias p &>/dev/null; then
  alias p="gtd-process"
fi
if ! alias t &>/dev/null; then
  alias t="gtd-task list"
fi
if ! alias w &>/dev/null; then
  alias w="make gtd-wizard"
fi
if ! alias c &>/dev/null; then
  alias c="gtd-c"
fi
if ! alias i &>/dev/null; then
  alias i="gtd-i"
fi
# Note: 'l' is typically aliased to 'ls -lah' by Oh My Zsh
# Use 'log' for logging instead, or unalias l first if you want l for logging
if ! alias l &>/dev/null; then
  alias l="gtd-l"
fi

