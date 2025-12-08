#!/bin/bash
# GTD Config Loader - Loads modular configuration files
# This script sources all GTD config modules in the correct order
# 
# Usage: source this file to load all modular configs
# Note: This does NOT load .gtd_config itself (to avoid circular dependency)
#       Scripts should source .gtd_config first, which will then call this loader

# Find config directory
GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
  GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
fi

# If config directory doesn't exist, try home directory
if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
  GTD_CONFIG_DIR="$HOME"
fi

# Load modular config files in order (if they exist)
# Order matters - later files can override earlier ones
MODULAR_CONFIGS=(
  ".gtd_config_core"           # Core settings (user, directories)
  ".gtd_config_ai"             # AI backend and personas
  ".gtd_config_capture"        # Capture and processing
  ".gtd_config_reviews"         # Review system
  ".gtd_config_integrations"    # Second Brain, calendar, etc.
  ".gtd_config_calendar"       # Calendar integration
  ".gtd_config_notifications"  # Notifications and reminders
  ".gtd_config_advanced"       # Advanced features and analytics
  ".gtd_config_custom"         # Custom user overrides (loaded last)
)

for config_file in "${MODULAR_CONFIGS[@]}"; do
  config_path="$GTD_CONFIG_DIR/$config_file"
  if [[ -f "$config_path" ]]; then
    source "$config_path"
  fi
done

# Load acronyms (if not already loaded)
if [[ -z "${GTD_ACRONYMS:-}" ]]; then
  GTD_ACRONYMS_FILE="${GTD_ACRONYMS_FILE:-$GTD_CONFIG_DIR/.gtd_acronyms}"
  if [[ -f "$GTD_ACRONYMS_FILE" ]]; then
    source "$GTD_ACRONYMS_FILE"
  elif [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_acronyms" ]]; then
    source "$HOME/code/personal/dotfiles/zsh/.gtd_acronyms"
  elif [[ -f "$HOME/.gtd_acronyms" ]]; then
    source "$HOME/.gtd_acronyms"
  fi
fi

