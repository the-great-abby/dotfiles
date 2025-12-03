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

