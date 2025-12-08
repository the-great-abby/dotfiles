#!/bin/bash
# Helper function to get Python executable for MCP scripts
# Checks for virtualenv first, falls back to system Python
# 
# Usage: source this file, then call get_mcp_python()
#   source "$HOME/code/dotfiles/mcp/get_mcp_python.sh"
#   PYTHON=$(get_mcp_python)
#   "$PYTHON" script.py

get_mcp_python() {
  local mcp_dir="$HOME/code/dotfiles/mcp"
  if [[ ! -d "$mcp_dir" ]]; then
    mcp_dir="$HOME/code/personal/dotfiles/mcp"
  fi
  
  local venv_dir="${mcp_dir}/venv"
  local venv_python="${venv_dir}/bin/python3"
  
  # Check if virtualenv exists and has Python
  if [[ -d "$venv_dir" ]] && [[ -f "$venv_python" ]]; then
    echo "$venv_python"
    return 0
  fi
  
  # Fallback to system Python
  if [[ -f "/opt/homebrew/bin/python3" ]]; then
    echo "/opt/homebrew/bin/python3"
  elif command -v python3 &>/dev/null; then
    echo "python3"
  else
    echo "❌ Python3 not found" >&2
    return 1
  fi
}

