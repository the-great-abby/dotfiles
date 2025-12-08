#!/bin/bash
# Helper script to get Python executable for MCP scripts
# Checks for virtualenv first, falls back to system Python

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="${SCRIPT_DIR}/venv"
VENV_PYTHON="${VENV_DIR}/bin/python3"

# Check if virtualenv exists and has Python
if [[ -d "$VENV_DIR" ]] && [[ -f "$VENV_PYTHON" ]]; then
    echo "$VENV_PYTHON"
    exit 0
fi

# Fallback to system Python
if [[ -f "/opt/homebrew/bin/python3" ]]; then
    echo "/opt/homebrew/bin/python3"
elif command -v python3 &>/dev/null; then
    echo "python3"
else
    echo "❌ Python3 not found" >&2
    exit 1
fi

