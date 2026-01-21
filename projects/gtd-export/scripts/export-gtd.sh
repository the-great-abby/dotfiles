#!/bin/bash
# GTD System Export Script
# This script exports all GTD-related files from the dotfiles repository
# to a new standalone repository structure.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EXPORT_ROOT="${EXPORT_ROOT:-$HOME/code/gtd-organization-system}"

# Counters
FILES_COPIED=0
FILES_SKIPPED=0
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

# Create directory structure
create_structure() {
    log_info "Creating export directory structure..."
    
    mkdir -p "$EXPORT_ROOT"/{bin,zsh/functions,zsh/quizzes,mcp/skills,docs/architecture,docs/mcp_notes,tests,launchd,web,scripts}
    
    log_success "Directory structure created"
}

# Copy file with path preservation
copy_file() {
    local src="$1"
    local dest="$2"
    local dest_dir
    
    if [[ ! -f "$src" ]]; then
        log_warning "Source file does not exist: $src"
        ((FILES_SKIPPED++))
        return 1
    fi
    
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    
    if cp "$src" "$dest"; then
        log_success "Copied: $src -> $dest"
        ((FILES_COPIED++))
        return 0
    else
        log_error "Failed to copy: $src"
        return 1
    fi
}

# Export bin scripts
export_bin_scripts() {
    log_info "Exporting bin scripts..."
    
    local bin_dir="$DOTFILES_ROOT/bin"
    local export_bin="$EXPORT_ROOT/bin"
    
    # Find all gtd-* scripts
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_bin/$basename_file"
    done < <(find "$bin_dir" -maxdepth 1 -name "gtd-*" -type f -print0 2>/dev/null)
    
    # Find gtd_* helper scripts
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_bin/$basename_file"
    done < <(find "$bin_dir" -maxdepth 1 -name "gtd_*" -type f -print0 2>/dev/null)
    
    # Copy gtd-common.sh (shared utility)
    if [[ -f "$bin_dir/gtd-common.sh" ]]; then
        copy_file "$bin_dir/gtd-common.sh" "$export_bin/gtd-common.sh"
    fi
    
    # Copy gtd-select-helper.sh
    if [[ -f "$bin_dir/gtd-select-helper.sh" ]]; then
        copy_file "$bin_dir/gtd-select-helper.sh" "$export_bin/gtd-select-helper.sh"
    fi
    
    log_success "Bin scripts exported"
}

# Export zsh configuration
export_zsh_config() {
    log_info "Exporting zsh configuration..."
    
    local zsh_dir="$DOTFILES_ROOT/zsh"
    local export_zsh="$EXPORT_ROOT/zsh"
    
    # Copy all .gtd_config* files
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_zsh/$basename_file"
    done < <(find "$zsh_dir" -maxdepth 1 -name ".gtd_*" -type f -print0 2>/dev/null)
    
    # Copy .daily_log_config
    if [[ -f "$zsh_dir/.daily_log_config" ]]; then
        copy_file "$zsh_dir/.daily_log_config" "$export_zsh/.daily_log_config"
    fi
    
    # Copy gtd-aliases.zsh
    if [[ -f "$zsh_dir/gtd-aliases.zsh" ]]; then
        copy_file "$zsh_dir/gtd-aliases.zsh" "$export_zsh/gtd-aliases.zsh"
    fi
    
    # Copy common_env.sh
    if [[ -f "$zsh_dir/common_env.sh" ]]; then
        copy_file "$zsh_dir/common_env.sh" "$export_zsh/common_env.sh"
    fi
    
    # Copy functions
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_zsh/functions/$basename_file"
    done < <(find "$zsh_dir/functions" -maxdepth 1 -name "gtd_*" -type f -print0 2>/dev/null)
    
    # Copy load_gtd_config.sh
    if [[ -f "$zsh_dir/functions/load_gtd_config.sh" ]]; then
        copy_file "$zsh_dir/functions/load_gtd_config.sh" "$export_zsh/functions/load_gtd_config.sh"
    fi
    
    # Copy helpers.sh if GTD-specific
    if [[ -f "$zsh_dir/functions/helpers.sh" ]]; then
        # Check if it's GTD-specific (contains gtd references)
        if grep -q "gtd\|GTD" "$zsh_dir/functions/helpers.sh" 2>/dev/null; then
            copy_file "$zsh_dir/functions/helpers.sh" "$export_zsh/functions/helpers.sh"
        fi
    fi
    
    # Copy quizzes
    if [[ -d "$zsh_dir/quizzes" ]]; then
        while IFS= read -r -d '' file; do
            local basename_file=$(basename "$file")
            copy_file "$file" "$export_zsh/quizzes/$basename_file"
        done < <(find "$zsh_dir/quizzes" -type f -print0 2>/dev/null)
    fi
    
    # Copy launchd plists
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$EXPORT_ROOT/launchd/$basename_file"
    done < <(find "$zsh_dir" -maxdepth 1 -name "com.abby.gtd.*.plist" -type f -print0 2>/dev/null)
    
    log_success "Zsh configuration exported"
}

# Export MCP server
export_mcp() {
    log_info "Exporting MCP server..."
    
    local mcp_dir="$DOTFILES_ROOT/mcp"
    local export_mcp="$EXPORT_ROOT/mcp"
    
    # Copy all gtd_*.py files
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_mcp/$basename_file"
    done < <(find "$mcp_dir" -maxdepth 1 -name "gtd_*.py" -type f -print0 2>/dev/null)
    
    # Copy claude_gtd_client.py
    if [[ -f "$mcp_dir/claude_gtd_client.py" ]]; then
        copy_file "$mcp_dir/claude_gtd_client.py" "$export_mcp/claude_gtd_client.py"
    fi
    
    # Copy claude_ollama_bridge.py
    if [[ -f "$mcp_dir/claude_ollama_bridge.py" ]]; then
        copy_file "$mcp_dir/claude_ollama_bridge.py" "$export_mcp/claude_ollama_bridge.py"
    fi
    
    # Copy requirements.txt
    if [[ -f "$mcp_dir/requirements.txt" ]]; then
        copy_file "$mcp_dir/requirements.txt" "$export_mcp/requirements.txt"
    fi
    
    # Copy README.md
    if [[ -f "$mcp_dir/README.md" ]]; then
        copy_file "$mcp_dir/README.md" "$export_mcp/README.md"
    fi
    
    # Copy setup.sh and deploy.sh
    for script in setup.sh deploy.sh check_mcp_cursor.sh check_worker.sh; do
        if [[ -f "$mcp_dir/$script" ]]; then
            copy_file "$mcp_dir/$script" "$export_mcp/$script"
        fi
    done
    
    # Copy Dockerfile if exists
    if [[ -f "$mcp_dir/Dockerfile" ]]; then
        copy_file "$mcp_dir/Dockerfile" "$export_mcp/Dockerfile"
    fi
    
    # Copy skills directory
    if [[ -d "$mcp_dir/skills" ]]; then
        log_info "Copying skills directory..."
        cp -r "$mcp_dir/skills" "$export_mcp/"
        log_success "Skills directory copied"
    fi
    
    # Copy kubernetes directory if exists
    if [[ -d "$mcp_dir/kubernetes" ]]; then
        log_info "Copying kubernetes directory..."
        cp -r "$mcp_dir/kubernetes" "$export_mcp/"
        log_success "Kubernetes directory copied"
    fi
    
    log_success "MCP server exported"
}

# Export documentation
export_docs() {
    log_info "Exporting documentation..."
    
    local docs_dir="$DOTFILES_ROOT/docs"
    local export_docs="$EXPORT_ROOT/docs"
    
    # Copy all GTD_*.md files
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_docs/$basename_file"
    done < <(find "$docs_dir" -maxdepth 1 -name "GTD_*.md" -type f -print0 2>/dev/null)
    
    # Copy files with GTD in name (case insensitive)
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        local rel_path="${file#$docs_dir/}"
        copy_file "$file" "$export_docs/$rel_path"
    done < <(find "$docs_dir" -maxdepth 1 -iname "*gtd*.md" -type f -print0 2>/dev/null)
    
    # Copy architecture docs
    if [[ -d "$docs_dir/architecture" ]]; then
        while IFS= read -r -d '' file; do
            local basename_file=$(basename "$file")
            copy_file "$file" "$export_docs/architecture/$basename_file"
        done < <(find "$docs_dir/architecture" -name "*gtd*" -type f -print0 2>/dev/null)
    fi
    
    # Copy mcp_notes if GTD-related
    if [[ -d "$docs_dir/mcp_notes" ]]; then
        while IFS= read -r -d '' file; do
            local basename_file=$(basename "$file")
            copy_file "$file" "$export_docs/mcp_notes/$basename_file"
        done < <(find "$docs_dir/mcp_notes" -type f -print0 2>/dev/null)
    fi
    
    log_success "Documentation exported"
}

# Export tests
export_tests() {
    log_info "Exporting tests..."
    
    local tests_dir="$DOTFILES_ROOT/tests"
    local export_tests="$EXPORT_ROOT/tests"
    
    # Copy all test_gtd_*.py files
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_tests/$basename_file"
    done < <(find "$tests_dir" -maxdepth 1 -name "test_gtd_*.py" -type f -print0 2>/dev/null)
    
    # Copy all test_gtd_*.sh files
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$export_tests/$basename_file"
    done < <(find "$tests_dir" -maxdepth 1 -name "test_gtd_*.sh" -type f -print0 2>/dev/null)
    
    log_success "Tests exported"
}

# Export launchd plists
export_launchd() {
    log_info "Exporting launchd plists..."
    
    local launchd_dir="$DOTFILES_ROOT/launchd"
    
    # Copy com.gtd.* plists
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        copy_file "$file" "$EXPORT_ROOT/launchd/$basename_file"
    done < <(find "$launchd_dir" -maxdepth 1 -name "com.gtd.*.plist" -type f -print0 2>/dev/null)
    
    log_success "Launchd plists exported"
}

# Main export function
main() {
    log_info "Starting GTD system export..."
    log_info "Export root: $EXPORT_ROOT"
    log_info "Dotfiles root: $DOTFILES_ROOT"
    
    # Verify dotfiles root
    if [[ ! -d "$DOTFILES_ROOT" ]]; then
        log_error "Dotfiles root does not exist: $DOTFILES_ROOT"
        exit 1
    fi
    
    # Create structure
    create_structure
    
    # Export components
    export_bin_scripts
    export_zsh_config
    export_mcp
    export_docs
    export_tests
    export_launchd
    
    # Summary
    echo ""
    log_info "Export Summary:"
    echo "  Files copied: $FILES_COPIED"
    echo "  Files skipped: $FILES_SKIPPED"
    echo "  Errors: $ERRORS"
    
    if [[ $ERRORS -eq 0 ]]; then
        log_success "Export completed successfully!"
        log_info "Next steps:"
        echo "  1. Review exported files in: $EXPORT_ROOT"
        echo "  2. Update paths in all files"
        echo "  3. Test the exported system"
        echo "  4. Create README.md and installation guide"
    else
        log_warning "Export completed with $ERRORS error(s)"
        exit 1
    fi
}

# Run main function
main "$@"
