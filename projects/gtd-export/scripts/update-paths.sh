#!/bin/bash
# GTD System Path Update Script
# This script updates all hardcoded paths in the exported GTD system
# to point to the new repository location.

set -uo pipefail  # Don't exit on errors, just track them

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_ROOT="${EXPORT_ROOT:-$HOME/code/gtd-organization-system}"
OLD_DOTFILES_PATH="${OLD_DOTFILES_PATH:-$HOME/code/dotfiles}"
OLD_PERSONAL_PATH="${OLD_PERSONAL_PATH:-$HOME/code/personal/dotfiles}"

# Counters
FILES_UPDATED=0
PATHS_UPDATED=0
ERRORS=0

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
    ((ERRORS++))
}

# Update paths in a file
update_file_paths() {
    local file="$1"
    local temp_file="${file}.tmp"
    local updated=false
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Skip binary files
    if ! file "$file" 2>/dev/null | grep -q "text"; then
        return 0
    fi
    
    # Create backup
    cp "$file" "${file}.bak" 2>/dev/null || return 1
    
    # Update paths using macOS-compatible sed
    # Use a temporary file approach for better compatibility
    if sed \
        -e "s|$OLD_DOTFILES_PATH|$EXPORT_ROOT|g" \
        -e "s|$OLD_PERSONAL_PATH|$EXPORT_ROOT|g" \
        -e "s|code/dotfiles|code/gtd-organization-system|g" \
        -e "s|code/personal/dotfiles|code/gtd-organization-system|g" \
        "$file" > "$temp_file" 2>/dev/null; then
        
        # Check if file was actually changed
        if ! cmp -s "$file" "$temp_file" 2>/dev/null; then
            updated=true
            ((PATHS_UPDATED++))
            # Replace original with updated version
            mv "$temp_file" "$file" 2>/dev/null || {
                log_warning "Could not replace: $file"
                rm -f "$temp_file" "${file}.bak"
                return 1
            }
        else
            # No changes, remove temp file
            rm -f "$temp_file"
        fi
        
        # Remove backup file
        rm -f "${file}.bak"
        
        if [[ "$updated" == "true" ]]; then
            log_success "Updated paths in: $file"
            ((FILES_UPDATED++))
            return 0
        fi
    else
        log_warning "Could not update: $file (may be binary or read-only)"
        rm -f "$temp_file" "${file}.bak"
        return 0  # Don't count as error, just skip
    fi
    
    return 0
}

# Update paths in all files
update_all_paths() {
    log_info "Updating paths in exported files..."
    log_info "Old path: $OLD_DOTFILES_PATH"
    log_info "New path: $EXPORT_ROOT"
    
    # Update shell scripts
    log_info "Updating shell scripts..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT/bin" -type f \( -name "*.sh" -o -name "gtd-*" -o -name "gtd_*" -o -name "gtd" -o -name "gtd-cli" -o -name "gtd-runbook*" \) -print0 2>/dev/null)
    
    # Update Python files
    log_info "Updating Python files..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT" -type f -name "*.py" -print0 2>/dev/null)
    
    # Update configuration files
    log_info "Updating configuration files..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT/zsh" -type f \( -name ".gtd_*" -o -name "*.zsh" -o -name "*.sh" \) -print0 2>/dev/null)
    
    # Update MCP files
    log_info "Updating MCP files..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT/mcp" -type f \( -name "*.py" -o -name "*.sh" -o -name "*.md" \) -print0 2>/dev/null)
    
    # Update web files
    log_info "Updating web files..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT/web" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.vue" -o -name "*.svelte" -o -name "*.conf" -o -name "*.service" -o -name "*.sh" -o -name "*.md" \) -print0 2>/dev/null)
    
    # Update documentation
    log_info "Updating documentation..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT/docs" -type f -name "*.md" -print0 2>/dev/null)
    
    # Update Makefile if exists (paths should already be updated by extract script, but double-check)
    if [[ -f "$EXPORT_ROOT/Makefile" ]]; then
        log_info "Verifying Makefile paths..."
        update_file_paths "$EXPORT_ROOT/Makefile" || true
    fi
    
    # Update plist files
    log_info "Updating plist files..."
    while IFS= read -r -d '' file; do
        update_file_paths "$file" || true  # Continue even if one file fails
    done < <(find "$EXPORT_ROOT/launchd" -type f -name "*.plist" -print0 2>/dev/null)
    
    # Update web launchd plists
    if [[ -d "$EXPORT_ROOT/web/launchd" ]]; then
        while IFS= read -r -d '' file; do
            update_file_paths "$file" || true  # Continue even if one file fails
        done < <(find "$EXPORT_ROOT/web/launchd" -type f -name "*.plist" -print0 2>/dev/null)
    fi
    
    log_success "Path updates completed"
}

# Main function
main() {
    log_info "Starting path update process..."
    log_info "Export root: $EXPORT_ROOT"
    
    # Verify export root exists
    if [[ ! -d "$EXPORT_ROOT" ]]; then
        log_error "Export root does not exist: $EXPORT_ROOT"
        log_info "Run export-gtd.sh first to create the export"
        exit 1
    fi
    
    # Update all paths
    update_all_paths
    
    # Summary
    echo ""
    log_info "Path Update Summary:"
    echo "  Files updated: $FILES_UPDATED"
    echo "  Path replacements: $PATHS_UPDATED"
    echo "  Errors: $ERRORS"
    
    if [[ $ERRORS -eq 0 ]]; then
        log_success "Path update completed successfully!"
        log_info "Next steps:"
        echo "  1. Review updated files"
        echo "  2. Test the system"
        echo "  3. Create README.md and installation guide"
    else
        log_warning "Path update completed with $ERRORS error(s) (some files may have been skipped)"
        log_info "This is usually non-critical - most files were updated successfully"
        log_info "Next steps:"
        echo "  1. Review any warnings above"
        echo "  2. Manually check any files that failed"
        echo "  3. Test the system"
    fi
}

# Run main function
main "$@"
