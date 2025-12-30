#!/bin/bash
# Check if GTD Wizard Web Interface is running
# Returns status information about the web service

# Find GTD base directory
GTD_BASE="${HOME}/code/dotfiles"
if [[ ! -d "$GTD_BASE" ]]; then
    GTD_BASE="${HOME}/code/personal/dotfiles"
fi

# Check if backend API is running
check_web_backend() {
    # Try to connect to the API health endpoint
    if curl -s --max-time 2 http://localhost:8000/api/health >/dev/null 2>&1; then
        return 0  # Backend is running
    else
        return 1  # Backend is not running
    fi
}

# Check if service is installed (systemd or launchd)
check_service_installed() {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: Check for launchd service
        PLIST_FILE="${HOME}/Library/LaunchAgents/com.gtd.wizard-api.plist"
        if [[ -f "$PLIST_FILE" ]]; then
            return 0
        fi
    else
        # Linux: Check for systemd service
        SERVICE_FILE="/etc/systemd/system/gtd-wizard-api.service"
        if [[ -f "$SERVICE_FILE" ]]; then
            return 0
        fi
    fi
    return 1
}

# Get web service status
get_web_service_status() {
    if check_web_backend; then
        echo "running"
    elif check_service_installed; then
        echo "installed_not_running"
    else
        echo "not_installed"
    fi
}

# Main - output status
STATUS=$(get_web_service_status)
echo "$STATUS"

