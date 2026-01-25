#!/bin/bash
# GTD System Complete Export Script
# This script runs the full export process: file copying and path updates

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_ROOT="${EXPORT_ROOT:-$HOME/code/gtd-organization-system}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main function
main() {
    log_info "Starting complete GTD system export..."
    log_info "Export destination: $EXPORT_ROOT"
    echo ""
    
    # Step 1: Export files
    log_info "Step 1: Exporting files..."
    if ! "$SCRIPT_DIR/export-gtd.sh"; then
        log_error "Export failed!"
        exit 1
    fi
    
    echo ""
    log_info "Step 2: Extracting Makefile targets..."
    if [[ -f "$SCRIPT_DIR/extract-makefile-targets.py" ]]; then
        if python3 "$SCRIPT_DIR/extract-makefile-targets.py"; then
            log_success "Makefile targets extracted"
        else
            log_warning "Makefile extraction failed (non-critical)"
        fi
    fi
    
    echo ""
    log_info "Step 3: Updating paths..."
    if ! "$SCRIPT_DIR/update-paths.sh"; then
        log_error "Path update failed!"
        exit 1
    fi
    
    echo ""
    log_success "Complete export finished successfully!"
    log_info "Exported GTD system is ready at: $EXPORT_ROOT"
    log_info ""
    log_info "Next steps:"
    echo "  1. Review the exported files"
    echo "  2. Create a git repository: cd $EXPORT_ROOT && git init"
    echo "  3. Create README.md (template available in projects/gtd-export/)"
    echo "  4. Test the system"
    echo "  5. Commit and push to new repository"
}

# Run main function
main "$@"
