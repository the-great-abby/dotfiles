#!/bin/bash
# Extract GTD-related Makefile targets and create a new Makefile for the exported repository

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EXPORT_ROOT="${EXPORT_ROOT:-$HOME/code/gtd-organization-system}"
MAKEFILE_SRC="$DOTFILES_ROOT/Makefile"
MAKEFILE_DEST="$EXPORT_ROOT/Makefile"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Extract GTD-related targets from Makefile
extract_gtd_targets() {
    log_info "Extracting GTD-related Makefile targets..."
    
    if [[ ! -f "$MAKEFILE_SRC" ]]; then
        log_error "Source Makefile not found: $MAKEFILE_SRC"
        return 1
    fi
    
    # Create output directory
    mkdir -p "$(dirname "$MAKEFILE_DEST")"
    
    # Start new Makefile with header
    cat > "$MAKEFILE_DEST" << 'EOF'
# GTD Organization System Makefile
# This Makefile contains all GTD-related commands and targets

# Configuration
GTD_BASE_DIR ?= $(HOME)/code/gtd-organization-system
GTD_BIN_DIR = $(GTD_BASE_DIR)/bin
GTD_MCP_DIR = $(GTD_BASE_DIR)/mcp
GTD_ZSH_DIR = $(GTD_BASE_DIR)/zsh

# Default variables
QUESTION ?= "Help review my daily log using daily log review runbook."
GTD_REVIEW_CMD ?= "gtd read-daily-log today"
CMD ?=

# GTD System Commands
.PHONY: gtd-wizard gtd-wizard-2col gtd-wizard-fuzzy gtd-wizard-full gtd-capture gtd-process gtd-review gtd-sync gtd-advise gtd-learn gtd-status gtd-diagram
.PHONY: worker-deep-start worker-deep-stop worker-vector-start worker-vector-stop worker-task-org-start worker-task-org-stop worker-brain-sync-start worker-brain-sync-stop worker-status worker-deep-status worker-vector-status worker-task-org-status rabbitmq-status filewatcher-start filewatcher-stop filewatcher-status filewatcher-scan scheduler-start scheduler-stop scheduler-status scheduler-run verify-nodeport diagnose-nodeport vector-db-init-extension vector-db-init-schema
.PHONY: gtd-cli gtd-cli-help gtd-setup-completion gtd-test-tui-bypass gtd-check-ollama gtd-test-priority gtd-ollama-status gtd-ollama-list gtd-tui
.PHONY: advice-worker-start advice-worker-stop advice-worker-status
.PHONY: claude-ask-interactive claude-ask-interactive-debug claude-ask-interactive-force-ollama claude-ask-interactive-force-ollama-8b claude-ask-interactive-force-ollama-3b claude-ask-tui
.PHONY: services-deploy-rabbitmq services-deploy-database services-deploy-all services-start-rabbitmq services-start-database services-start-all

EOF

    # Extract GTD command targets (lines starting with gtd-)
    log_info "Extracting GTD command targets..."
    awk '
    /^gtd-wizard:/,/^[^[:space:]]/ {
        if (/^gtd-wizard:/ || /^gtd-wizard-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-capture:/,/^[^[:space:]]/ {
        if (/^gtd-capture:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-process:/,/^[^[:space:]]/ {
        if (/^gtd-process:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-review:/,/^[^[:space:]]/ {
        if (/^gtd-review:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-sync:/,/^[^[:space:]]/ {
        if (/^gtd-sync:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-advise:/,/^[^[:space:]]/ {
        if (/^gtd-advise:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-learn:/,/^[^[:space:]]/ {
        if (/^gtd-learn:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-status:/,/^[^[:space:]]/ {
        if (/^gtd-status:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^gtd-diagram:/,/^[^[:space:]]/ {
        if (/^gtd-diagram:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    ' "$MAKEFILE_SRC" >> "$MAKEFILE_DEST"
    
    # Extract worker targets
    log_info "Extracting worker targets..."
    awk '
    /^worker-/,/^[^[:space:]]/ {
        if (/^worker-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^worker-/ && !/^filewatcher-/ && !/^scheduler-/ && !/^vector-db-/ && !/^rabbitmq-/ && !/^verify-/ && !/^diagnose-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    ' "$MAKEFILE_SRC" >> "$MAKEFILE_DEST"
    
    # Extract filewatcher, scheduler, and other targets
    log_info "Extracting filewatcher, scheduler, and other targets..."
    awk '
    /^filewatcher-/,/^[^[:space:]]/ {
        if (/^filewatcher-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^filewatcher-/ && !/^scheduler-/ && !/^vector-db-/ && !/^rabbitmq-/ && !/^verify-/ && !/^diagnose-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^scheduler-/,/^[^[:space:]]/ {
        if (/^scheduler-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^scheduler-/ && !/^vector-db-/ && !/^rabbitmq-/ && !/^verify-/ && !/^diagnose-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^vector-db-/,/^[^[:space:]]/ {
        if (/^vector-db-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^vector-db-/ && !/^rabbitmq-/ && !/^verify-/ && !/^diagnose-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^rabbitmq-status:/,/^[^[:space:]]/ {
        if (/^rabbitmq-status:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^verify-/ && !/^diagnose-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^verify-nodeport:/,/^[^[:space:]]/ {
        if (/^verify-nodeport:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^diagnose-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^diagnose-nodeport:/,/^[^[:space:]]/ {
        if (/^diagnose-nodeport:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-cli/ && !/^gtd-setup/ && !/^gtd-test/ && !/^gtd-check/ && !/^gtd-ollama/ && !/^gtd-tui/ && !/^advice-worker/ && !/^claude-ask/ && !/^services-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    ' "$MAKEFILE_SRC" >> "$MAKEFILE_DEST"
    
    # Extract GTD CLI and other GTD-related targets
    log_info "Extracting GTD CLI and other targets..."
    awk '
    /^gtd-cli/,/^[^[:space:]]/ {
        if (/^gtd-cli/ || /^gtd-setup-completion/ || /^gtd-test-tui-bypass/ || /^gtd-check-ollama/ || /^gtd-test-priority/ || /^gtd-ollama-status/ || /^gtd-ollama-list/ || /^gtd-tui:/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^gtd-cli/ && !/^gtd-setup/ && !/^gtd-test/ && !/^gtd-check/ && !/^gtd-ollama/ && !/^gtd-tui/ && !/^advice-worker/ && !/^claude-ask/ && !/^services-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^advice-worker-/,/^[^[:space:]]/ {
        if (/^advice-worker-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^advice-worker/ && !/^claude-ask/ && !/^services-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^claude-ask-/,/^[^[:space:]]/ {
        if (/^claude-ask-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^claude-ask/ && !/^services-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    /^services-/,/^[^[:space:]]/ {
        if (/^services-/) {
            in_target = 1
            print
            next
        }
        if (in_target && /^[^[:space:]]/ && !/^services-/) {
            in_target = 0
        }
        if (in_target) {
            gsub(/\$\(HOME\)\/code\/dotfiles/, "$(GTD_BASE_DIR)")
            gsub(/\$\(HOME\)\/code\/personal\/dotfiles/, "$(GTD_BASE_DIR)")
            print
        }
    }
    ' "$MAKEFILE_SRC" >> "$MAKEFILE_DEST"
    
    # Update all remaining paths in the Makefile
    log_info "Updating paths in Makefile..."
    sed -i.bak \
        -e "s|\$(HOME)/code/dotfiles|\$(GTD_BASE_DIR)|g" \
        -e "s|\$(HOME)/code/personal/dotfiles|\$(GTD_BASE_DIR)|g" \
        -e "s|code/dotfiles|code/gtd-organization-system|g" \
        "$MAKEFILE_DEST"
    
    rm -f "${MAKEFILE_DEST}.bak"
    
    log_success "Makefile extracted and created at: $MAKEFILE_DEST"
    return 0
}

# Main function
main() {
    log_info "Extracting GTD Makefile targets..."
    log_info "Source: $MAKEFILE_SRC"
    log_info "Destination: $MAKEFILE_DEST"
    
    if extract_gtd_targets; then
        log_success "Makefile extraction completed successfully!"
        log_info "Review the Makefile and test targets with: make help"
    else
        log_error "Makefile extraction failed!"
        exit 1
    fi
}

# Run main function
main "$@"
