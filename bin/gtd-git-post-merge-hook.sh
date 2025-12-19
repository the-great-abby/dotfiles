#!/bin/bash
# Git Post-Merge Hook for GTD Computer Mode Restoration
# This hook restores the computer mode after git pull/merge operations
#
# To install:
#   cp bin/gtd-git-post-merge-hook.sh .git/hooks/post-merge
#   chmod +x .git/hooks/post-merge

# Source common environment (PATH setup)
COMMON_ENV="$HOME/code/dotfiles/zsh/common_env.sh"
if [[ ! -f "$COMMON_ENV" && -f "$HOME/code/personal/dotfiles/zsh/common_env.sh" ]]; then
  COMMON_ENV="$HOME/code/personal/dotfiles/zsh/common_env.sh"
fi
if [[ -f "$COMMON_ENV" ]]; then
  source "$COMMON_ENV"
fi

# Source GTD common functions
GTD_COMMON="$HOME/code/dotfiles/bin/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON"
fi

# Check if .gtd_config was modified in this merge
if [[ -f "zsh/.gtd_config" ]] || [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]] || [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
  # Restore computer mode if it was changed
  if declare -f gtd_preserve_computer_mode &>/dev/null; then
    # We're after the merge, so use "after" phase
    gtd_preserve_computer_mode "after"
  fi
fi

