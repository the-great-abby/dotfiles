#!/bin/bash
# IMPORTANT: This script must be compatible with bash 3.2 (macOS default)
# See .cursorrules for bash compatibility guidelines
# DO NOT use associative arrays (declare -A) or bash 4+ features
# GTD Common Helper Library
# Source this file in your GTD scripts to get consistent behavior
#
# Usage:
#   source "$HOME/code/dotfiles/bin/gtd-common.sh"
#   # or
#   source "$(dirname "$0")/gtd-common.sh"

# ============================================================================
# Configuration Loading
# ============================================================================

# Load common environment (PATH setup)
load_common_env() {
  local COMMON_ENV="$HOME/code/dotfiles/zsh/common_env.sh"
  if [[ ! -f "$COMMON_ENV" && -f "$HOME/code/personal/dotfiles/zsh/common_env.sh" ]]; then
    COMMON_ENV="$HOME/code/personal/dotfiles/zsh/common_env.sh"
  fi
  if [[ -f "$COMMON_ENV" ]]; then
    source "$COMMON_ENV"
  fi
}

# Load GTD config
load_gtd_config() {
  local GTD_CONFIG_FILE="$HOME/.gtd_config"
  if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
    GTD_CONFIG_FILE="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
    GTD_CONFIG_FILE="$HOME/code/dotfiles/zsh/.gtd_config"
  fi
  
  if [[ -f "$GTD_CONFIG_FILE" ]]; then
    # Use set +e to prevent script from exiting on errors in sourced file
    set +e
    source "$GTD_CONFIG_FILE" 2>/dev/null || true
    set -e
  fi
}

# Load daily log config with mode-specific directory support
load_daily_log_config() {
  local DAILY_LOG_CONFIG="$HOME/.daily_log_config"
  if [[ -f "$HOME/code/dotfiles/zsh/.daily_log_config" ]]; then
    DAILY_LOG_CONFIG="$HOME/code/dotfiles/zsh/.daily_log_config"
  elif [[ -f "$HOME/code/personal/dotfiles/zsh/.daily_log_config" ]]; then
    DAILY_LOG_CONFIG="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
  fi
  
  if [[ -f "$DAILY_LOG_CONFIG" ]]; then
    # Use set +e to prevent script from exiting on errors in sourced file
    set +e
    source "$DAILY_LOG_CONFIG" 2>/dev/null || true
    set -e
  fi
  
  # Apply mode-specific DAILY_LOG_DIR if it exists
  local current_mode="${GTD_COMPUTER_MODE:-home}"
  local mode_upper=$(echo "$current_mode" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')
  
  # Safety check: ensure mode_upper is valid
  if [[ -z "$mode_upper" ]] || [[ ! "$mode_upper" =~ ^(HOME|WORK)$ ]]; then
    mode_upper="HOME"
  fi
  
  local mode_daily_log="DAILY_LOG_DIR_${mode_upper}"
  
  # Use indirect variable expansion safely
  if [[ -n "${!mode_daily_log:-}" ]]; then
    DAILY_LOG_DIR="${!mode_daily_log}"
    export DAILY_LOG_DIR
  fi
}

# Initialize GTD directories and paths
init_gtd_paths() {
  # Get current computer mode
  local current_mode="${GTD_COMPUTER_MODE:-home}"
  if [[ -z "${GTD_COMPUTER_MODE:-}" ]]; then
    # Try to load from config
    local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
    if [[ ! -f "$gtd_config" ]]; then
      gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
    fi
    if [[ -f "$gtd_config" ]]; then
      # Source config with error handling to prevent bad substitution errors
      # Use eval in a subshell to completely isolate any errors
      set +e
      # Run sourcing in a completely isolated subshell that can't affect the parent
      (bash -c "source '$gtd_config' 2>&1" 2>/dev/null | grep -v "bad substitution" >/dev/null 2>&1) || true
      set -e
      
      # Re-read GTD_COMPUTER_MODE from file (more reliable than sourced variable)
      if [[ -f "$gtd_config" ]]; then
        local file_mode=$(grep "^GTD_COMPUTER_MODE=" "$gtd_config" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
        if [[ -n "$file_mode" ]]; then
          current_mode="$file_mode"
        fi
      fi
      current_mode="${current_mode:-home}"
    fi
  fi
  
  # Normalize and validate mode
  local mode_upper=$(echo "$current_mode" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')
  
  # Safety check: ensure mode_upper is valid and not empty
  if [[ -z "$mode_upper" ]] || [[ ! "$mode_upper" =~ ^(HOME|WORK)$ ]]; then
    mode_upper="HOME"
  fi
  
  # Check for mode-specific directories by reading from config files directly
  # This avoids issues with indirect variable expansion
  local gtd_config_file="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config_file" ]]; then
    gtd_config_file="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  # Check for mode-specific GTD_BASE_DIR
  if [[ -f "$gtd_config_file" ]]; then
    local mode_gtd_base=$(grep "^GTD_BASE_DIR_${mode_upper}=" "$gtd_config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | sed "s|\$HOME|$HOME|g")
    if [[ -n "$mode_gtd_base" ]]; then
      GTD_BASE_DIR="$mode_gtd_base"
    else
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    fi
    
    # Check for mode-specific SECOND_BRAIN
    local mode_second_brain=$(grep "^SECOND_BRAIN_${mode_upper}=" "$gtd_config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | sed "s|\$HOME|$HOME|g")
    if [[ -n "$mode_second_brain" ]]; then
      SECOND_BRAIN="$mode_second_brain"
    else
      SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
    fi
  else
    GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
  fi
  
  # Load daily log config to check for mode-specific DAILY_LOG_DIR
  local daily_log_config="$HOME/code/dotfiles/zsh/.daily_log_config"
  if [[ ! -f "$daily_log_config" ]]; then
    daily_log_config="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
  fi
  if [[ -f "$daily_log_config" ]]; then
    # Use set +e to prevent script from exiting on errors in sourced file
    set +e
    source "$daily_log_config" 2>/dev/null || true
    set -e
    # Check for mode-specific DAILY_LOG_DIR by reading from config file
    local mode_daily_log=$(grep "^DAILY_LOG_DIR_${mode_upper}=" "$daily_log_config" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | sed "s|\$HOME|$HOME|g")
    if [[ -n "$mode_daily_log" ]]; then
      DAILY_LOG_DIR="$mode_daily_log"
    fi
  fi
  
  PROJECTS_PATH="${GTD_BASE_DIR}/${GTD_PROJECTS_DIR:-1-projects}"
  AREAS_PATH="${GTD_BASE_DIR}/${GTD_AREAS_DIR:-2-areas}"
  TASKS_PATH="${GTD_BASE_DIR}/tasks"
  INBOX_PATH="${GTD_BASE_DIR}/${GTD_INBOX_DIR:-0-inbox}"
  REFERENCE_PATH="${GTD_BASE_DIR}/${GTD_REFERENCE_DIR:-3-reference}"
  SOMEDAY_PATH="${GTD_BASE_DIR}/${GTD_SOMEDAY_DIR:-4-someday-maybe}"
  WAITING_PATH="${GTD_BASE_DIR}/${GTD_WAITING_DIR:-5-waiting-for}"
  ARCHIVE_PATH="${GTD_BASE_DIR}/${GTD_ARCHIVE_DIR:-6-archive}"
  DAILY_LOGS_PATH="${GTD_BASE_DIR}/${GTD_DAILY_LOGS_DIR:-daily-logs}"
  WEEKLY_REVIEWS_PATH="${GTD_BASE_DIR}/${GTD_WEEKLY_REVIEWS_DIR:-weekly-reviews}"
}

# Auto-load everything on source
load_common_env
load_gtd_config
load_daily_log_config
init_gtd_paths

# ============================================================================
# Color Definitions (Consistent across all GTD scripts)
# ============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# Selection Helper Integration
# ============================================================================

# Load selection helper if available
load_selection_helper() {
  local SELECT_HELPER="$HOME/code/dotfiles/bin/gtd-select-helper.sh"
  if [[ ! -f "$SELECT_HELPER" && -f "$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh" ]]; then
    SELECT_HELPER="$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh"
  fi
  if [[ -f "$SELECT_HELPER" ]]; then
    source "$SELECT_HELPER"
  fi
}

# Auto-load selection helper
load_selection_helper

# ============================================================================
# Menu Navigation Stack
# ============================================================================

# Menu navigation stack (for back navigation)
declare -a GTD_MENU_STACK=()

# Push menu onto stack
gtd_push_menu() {
  GTD_MENU_STACK+=("$1")
}

# Pop menu from stack (go back)
gtd_pop_menu() {
  if [[ ${#GTD_MENU_STACK[@]} -gt 0 ]]; then
    unset 'GTD_MENU_STACK[${#GTD_MENU_STACK[@]}-1]'
  fi
}

# Get current menu level
gtd_get_menu_level() {
  echo ${#GTD_MENU_STACK[@]}
}

# Wrapper functions (aliases don't work in all contexts like process substitutions)
# These ensure functions are available even if aliases fail
pop_menu() {
  gtd_pop_menu "$@"
}

push_menu() {
  gtd_push_menu "$@"
}

# Show breadcrumb navigation
gtd_show_breadcrumb() {
  if [[ ${#GTD_MENU_STACK[@]} -gt 0 ]]; then
    local last_index=$((${#GTD_MENU_STACK[@]} - 1))
    echo -e "${YELLOW}← Back to: ${GTD_MENU_STACK[$last_index]}${NC}"
    echo ""
  fi
}

# ============================================================================
# Display Helpers
# ============================================================================

# Print a divider line
gtd_print_divider() {
  local char="${1:-━}"
  local length="${2:-70}"
  local color="${3:-$YELLOW}"
  printf "${color}%*s${NC}\n" "$length" | tr ' ' "$char"
}

# Print a header
gtd_print_header() {
  local title="$1"
  local icon="${2:-}"
  local color="${3:-$CYAN}"
  
  gtd_print_divider "━" 70 "$color"
  if [[ -n "$icon" ]]; then
    echo -e "${BOLD}${color}${icon} ${title}${NC}"
  else
    echo -e "${BOLD}${color}${title}${NC}"
  fi
  gtd_print_divider "━" 70 "$color"
  echo ""
}

# Print a section title
gtd_print_section() {
  local title="$1"
  echo -e "${BOLD}${title}${NC}"
}

# Print success message
gtd_print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

# Print error message
gtd_print_error() {
  echo -e "${RED}❌${NC} $1" >&2
}

# Print info message
gtd_print_info() {
  echo -e "${CYAN}ℹ${NC} $1"
}

# Print warning message
gtd_print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Print items in two columns
# Usage: gtd_print_two_columns "item1" "item2" "item3" ...
# Or: gtd_print_two_columns "${array[@]}"
# Optional: gtd_print_two_columns --width=35 "${array[@]}"
gtd_print_two_columns() {
  local column_width=35
  local items=()
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --width=*)
        column_width="${1#*=}"
        shift
        ;;
      *)
        items+=("$1")
        shift
        ;;
    esac
  done
  
  if [[ ${#items[@]} -eq 0 ]]; then
    return 0
  fi
  
  # Get terminal width (default to 80 if not available)
  local term_width=80
  if command -v tput &>/dev/null; then
    term_width=$(tput cols 2>/dev/null || echo "80")
  elif [[ -n "${COLUMNS:-}" ]]; then
    term_width="$COLUMNS"
  fi
  
  # Calculate column width (leave space for separator)
  local separator_width=4
  local available_width=$((term_width - separator_width))
  local calculated_width=$((available_width / 2))
  
  # Use provided width or calculated, whichever is smaller
  if [[ $calculated_width -lt $column_width ]]; then
    column_width=$calculated_width
  fi
  
  # Display items in two columns
  local i=0
  local total=${#items[@]}
  
  while [[ $i -lt $total ]]; do
    local left_item="${items[$i]}"
    local right_item=""
    
    # Get right column item if it exists
    local right_idx=$((i + 1))
    if [[ $right_idx -lt $total ]]; then
      right_item="${items[$right_idx]}"
    fi
    
    # Truncate items if needed (bash 3.2 compatible)
    local left_display="$left_item"
    if [[ ${#left_display} -gt $column_width ]]; then
      left_display="${left_display:0:$((column_width - 3))}..."
    fi
    
    local right_display="$right_item"
    if [[ -n "$right_item" ]]; then
      if [[ ${#right_display} -gt $column_width ]]; then
        right_display="${right_display:0:$((column_width - 3))}..."
      fi
      # Print both columns
      printf "  %-${column_width}s    %-${column_width}s\n" "$left_display" "$right_display"
      i=$((i + 2))
    else
      # Only left column
      printf "  %-${column_width}s\n" "$left_display"
      i=$((i + 1))
    fi
  done
}

# Print items in two columns with custom formatting
# Usage: gtd_print_two_columns_formatted "prefix" "item1" "item2" ...
# Each item will be prefixed with the prefix string
gtd_print_two_columns_formatted() {
  local prefix="$1"
  shift
  local items=("$@")
  
  if [[ ${#items[@]} -eq 0 ]]; then
    return 0
  fi
  
  # Format items with prefix
  local formatted_items=()
  for item in "${items[@]}"; do
    formatted_items+=("${prefix}${item}")
  done
  
  gtd_print_two_columns "${formatted_items[@]}"
}

# Print menu items in two columns (for wizard menus)
# Usage: gtd_print_menu_items_two_columns "item1" "item2" ...
# Handles ANSI color codes in items properly
gtd_print_menu_items_two_columns() {
  local items=("$@")
  
  if [[ ${#items[@]} -eq 0 ]]; then
    return 0
  fi
  
  # Get terminal width (default to 80 if not available)
  local term_width=80
  if command -v tput &>/dev/null; then
    term_width=$(tput cols 2>/dev/null || echo "80")
  elif [[ -n "${COLUMNS:-}" ]]; then
    term_width="$COLUMNS"
  fi
  
  # Calculate column width (leave space for separator)
  # Use a fixed reasonable width for two columns (bash 3.2 compatible)
  local separator_width=4
  local available_width=$((term_width - separator_width))
  local column_width=$((available_width / 2))
  
  # Ensure minimum column width for readability (at least 35 chars per column)
  local min_column_width=35
  if [[ $column_width -lt $min_column_width ]]; then
    column_width=$min_column_width
  fi
  
  # Helper function to strip ANSI codes for width calculation (bash 3.2 compatible)
  # Handles both actual ANSI codes and variable names like ${GREEN}, ${NC}
  strip_ansi_codes() {
    local text="$1"
    # Remove actual ANSI escape sequences
    text=$(echo "$text" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\\033\[[0-9;]*m//g')
    # Remove common color variable patterns (they don't contribute to visible width)
    text=$(echo "$text" | sed 's/\${GREEN}//g' | sed 's/\${CYAN}//g' | sed 's/\${YELLOW}//g' | sed 's/\${RED}//g' | sed 's/\${BOLD}//g' | sed 's/\${NC}//g' | sed 's/\${GRAY}//g')
    echo "$text"
  }
  
  # Display items in two columns
  local i=0
  local total=${#items[@]}
  
  while [[ $i -lt $total ]]; do
    local left_item="${items[$i]}"
    local right_item=""
    
    # Get right column item if it exists
    local right_idx=$((i + 1))
    if [[ $right_idx -lt $total ]]; then
      right_item="${items[$right_idx]}"
    fi
    
    if [[ -n "$right_item" ]]; then
      # Calculate visible width (without ANSI codes) for proper alignment
      local left_visible=$(strip_ansi_codes "$left_item")
      local right_visible=$(strip_ansi_codes "$right_item")
      local left_len=${#left_visible}
      local right_len=${#right_visible}
      
      # Truncate if needed - preserve ANSI codes/variables properly
      if [[ $left_len -gt $column_width ]]; then
        local truncate_at=$((column_width - 3))
        
        # Extract prefix (ANSI codes or color variables at start)
        local left_prefix=""
        # Check for variable patterns like ${GREEN} at start
        if [[ "$left_item" =~ ^(\$\{[A-Z]+\}) ]]; then
          left_prefix="${BASH_REMATCH[1]}"
        # Check for actual ANSI escape sequence
        elif [[ "$left_item" =~ ^($'\033'\[[0-9;]*m) ]]; then
          left_prefix="${BASH_REMATCH[1]}"
        fi
        
        # Always add NC at end for truncated items to reset color
        local left_suffix="${NC}"
        
        # Truncate the visible text and rebuild with codes
        local truncated_text="${left_visible:0:$truncate_at}..."
        left_item="${left_prefix}${truncated_text}${left_suffix}"
        left_len=$((truncate_at + 3))
      fi
      
      if [[ $right_len -gt $column_width ]]; then
        local truncate_at=$((column_width - 3))
        
        # Extract prefix (same logic as left)
        local right_prefix=""
        if [[ "$right_item" =~ ^(\$\{[A-Z]+\}) ]]; then
          right_prefix="${BASH_REMATCH[1]}"
        elif [[ "$right_item" =~ ^($'\033'\[[0-9;]*m) ]]; then
          right_prefix="${BASH_REMATCH[1]}"
        fi
        
        # Always add NC at end for truncated items
        local right_suffix="${NC}"
        
        local truncated_text="${right_visible:0:$truncate_at}..."
        right_item="${right_prefix}${truncated_text}${right_suffix}"
        right_len=$((truncate_at + 3))
      fi
      
      # Calculate padding needed for left column
      local left_pad=$((column_width - left_len))
      if [[ $left_pad -lt 0 ]]; then
        left_pad=0
      fi
      
      # Build padding string
      local pad_str=""
      local j=0
      while [[ $j -lt $left_pad ]]; do
        pad_str="${pad_str} "
        ((j++))
      done
      
      # Print both columns using echo -e to interpret ANSI codes
      # Use printf for padding, then echo -e for the actual content
      printf "  "
      echo -ne "${left_item}"
      printf "%*s" $left_pad ""
      printf "    "
      echo -e "${right_item}"
      i=$((i + 2))
    else
      # Only left column
      echo -e "  ${left_item}"
      i=$((i + 1))
    fi
  done
}

# ============================================================================
# Polished UX Helpers
# ============================================================================

# Smart "press enter" with optional timeout and auto-continue
# Usage: gtd_pause [timeout_seconds] [message]
#   - If timeout_seconds is 0 or not provided, waits for user input
#   - If timeout_seconds > 0, auto-continues after that time
#   - User can press Enter early to continue immediately
gtd_pause() {
  local timeout="${1:-0}"
  local message="${2:-Press Enter to continue...}"
  
  if [[ "$timeout" == "0" ]]; then
    # Traditional pause - wait for user
    echo -e "${GRAY}${message}${NC}"
    read -r
  else
    # Auto-continue after timeout, but allow early exit
    echo -e "${GRAY}${message} (auto-continue in ${timeout}s)${NC}"
    read -r -t "$timeout" || true
  fi
}

# Quick pause for non-critical operations (2 second auto-continue)
# Use for: Quick error messages, simple confirmations, brief status updates
# DO NOT use for: Reports, reviews, lists, or any information users need to read
gtd_quick_pause() {
  gtd_pause 2 "Press Enter to continue..."
}

# Enter to continue - waits for user to press Enter (no auto-continue)
# Use this when displaying information that users need time to review
# Use for: Reports, reviews, task lists, analysis results, summaries, dashboards
# Rule: If it's information the user needs to READ → use this function
gtd_enter_to_continue() {
  gtd_pause 0 "Press Enter to continue..."
}

# Silent pause - no message, just wait briefly for visual processing
gtd_silent_pause() {
  local timeout="${1:-1}"
  read -r -t "$timeout" 2>/dev/null || true
}

# Print a clean section divider
gtd_section_divider() {
  local color="${1:-$CYAN}"
  echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Print a compact status line
gtd_status_line() {
  local icon="$1"
  local label="$2"
  local value="$3"
  local color="${4:-$CYAN}"
  echo -e "  ${color}${icon}${NC} ${BOLD}${label}:${NC} ${value}"
}

# Print a compact menu item
gtd_menu_item() {
  local number="$1"
  local icon="$2"
  local description="$3"
  echo -e "${GREEN}${number})${NC} ${icon} ${description}"
}

# Clear screen and show header (polished version)
gtd_clear_and_header() {
  clear
  local title="$1"
  local icon="${2:-}"
  gtd_print_header "$title" "$icon"
}

# Print compact success/error/info with consistent formatting
gtd_feedback() {
  local type="$1"  # success, error, info, warning
  local message="$2"
  
  case "$type" in
    success)
      echo -e "${GREEN}✓${NC} ${message}"
      ;;
    error)
      echo -e "${RED}✗${NC} ${message}" >&2
      ;;
    info)
      echo -e "${CYAN}ℹ${NC} ${message}"
      ;;
    warning)
      echo -e "${YELLOW}⚠${NC} ${message}"
      ;;
    *)
      echo "$message"
      ;;
  esac
}

# ============================================================================
# Performance Optimization - Caching
# ============================================================================

# Get cache file path for dashboard counts
gtd_get_cache_file() {
  local cache_dir="${GTD_CACHE_DIR:-/tmp/gtd_cache}"
  mkdir -p "$cache_dir" 2>/dev/null
  echo "${cache_dir}/dashboard_counts"
}

# Get cached count or compute and cache it
# Usage: gtd_get_cached_count "inbox" "${INBOX_PATH}" "*.md"
# Returns: count (always a number, defaults to 0 on error)
gtd_get_cached_count() {
  local cache_key="$1"
  local path="$2"
  local pattern="${3:-*.md}"
  local cache_age="${4:-5}"  # Cache for 5 seconds by default
  
  # Validate inputs - return 0 if cache_key or path is empty
  if [[ -z "$cache_key" ]] || [[ -z "$path" ]]; then
    echo "0"
    return 0
  fi
  
  local cache_file=$(gtd_get_cache_file)
  local cache_time=$(stat -f "%m" "$cache_file" 2>/dev/null || echo "0")
  local current_time=$(date +%s 2>/dev/null || echo "0")
  local age=$((current_time - cache_time))
  
  # If cache is fresh, use it
  if [[ -f "$cache_file" ]] && [[ $age -lt $cache_age ]] && [[ $age -ge 0 ]]; then
    # Try to get cached value
    local cached_value=$(grep "^${cache_key}=" "$cache_file" 2>/dev/null | cut -d'=' -f2)
    if [[ -n "$cached_value" ]] && [[ "$cached_value" =~ ^[0-9]+$ ]]; then
      echo "$cached_value"
      return 0
    fi
  fi
  
  # Compute count - default to 0 on any error
  local count=0
  if [[ -n "$path" ]] && [[ -d "$path" ]]; then
    if [[ "$pattern" == "*.md" ]]; then
      # Simple file count
      count=$(ls -1 "${path}"/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
      # Ensure count is numeric
      [[ "$count" =~ ^[0-9]+$ ]] || count=0
    elif [[ "$pattern" == "projects" ]]; then
      # Project count (README.md in subdirectories) - special case
      count=$(ls -1 "${path}"/*/README.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
      # Ensure count is numeric
      [[ "$count" =~ ^[0-9]+$ ]] || count=0
    else
      # Use find for complex patterns
      count=$(find "$path" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
      # Ensure count is numeric
      [[ "$count" =~ ^[0-9]+$ ]] || count=0
    fi
  fi
  
  # Update cache (only if cache_file path is valid)
  if [[ -n "$cache_file" ]]; then
    local cache_dir=$(dirname "$cache_file")
    if [[ -n "$cache_dir" ]]; then
      mkdir -p "$cache_dir" 2>/dev/null
    fi
    
    if [[ -f "$cache_file" ]]; then
      # Update existing entry or add new one
      if grep -q "^${cache_key}=" "$cache_file" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
          sed -i '' "s/^${cache_key}=.*/${cache_key}=${count}/" "$cache_file" 2>/dev/null
        else
          sed -i "s/^${cache_key}=.*/${cache_key}=${count}/" "$cache_file" 2>/dev/null
        fi
      else
        echo "${cache_key}=${count}" >> "$cache_file" 2>/dev/null
      fi
    else
      # Create new cache file
      echo "${cache_key}=${count}" > "$cache_file" 2>/dev/null
    fi
  fi
  
  # Always return a number (default to 0 if something went wrong)
  echo "${count:-0}"
}

# Invalidate dashboard cache (call after operations that change counts)
gtd_invalidate_cache() {
  local cache_file=$(gtd_get_cache_file)
  rm -f "$cache_file" 2>/dev/null
}

# ============================================================================
# Additional Polish Helpers
# ============================================================================

# Show success confirmation after actions
# Usage: gtd_action_success "created" "task" "Review Greek Vocabulary"
gtd_action_success() {
  local action="$1"  # "created", "updated", "deleted", "completed"
  local item_type="$2"  # "task", "project", "area", "note"
  local item_name="$3"
  
  # Capitalize first letter of item type (bash 3.2 compatible)
  local item_type_cap=$(echo "$item_type" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  
  gtd_feedback success "${item_type_cap} '$item_name' ${action}"
  gtd_invalidate_cache  # Refresh dashboard counts
  gtd_silent_pause 0.3  # Brief pause for visual feedback
}

# Format list items for better readability
# Usage: gtd_format_list_item number "Item name" [max_width] [truncate]
gtd_format_list_item() {
  local number="$1"
  local item="$2"
  local max_width="${3:-60}"
  local truncate="${4:-true}"
  
  # Truncate if too long
  if [[ "$truncate" == "true" ]] && [[ ${#item} -gt $max_width ]]; then
    item="${item:0:$((max_width-3))}..."
  fi
  
  echo -e "  ${GREEN}${number})${NC} ${item}"
}

# Show empty state with helpful guidance
# Usage: gtd_empty_state "tasks" "Press 1 to add your first task"
gtd_empty_state() {
  local item_type="$1"  # "tasks", "projects", "areas"
  local action_hint="$2"  # "Press 1 to add"
  
  echo ""
  gtd_feedback info "No ${item_type} found"
  if [[ -n "$action_hint" ]]; then
    echo -e "  ${CYAN}💡${NC} ${action_hint}"
  fi
  echo ""
}

# Show progress indicator for batch operations
# Usage: gtd_show_progress current total "Processing tasks"
gtd_show_progress() {
  local current="$1"
  local total="$2"
  local label="${3:-Processing}"
  local percentage=$((current * 100 / total))
  
  # Use \r to overwrite same line
  echo -ne "\r${CYAN}${label}: ${current}/${total} (${percentage}%)${NC}"
  
  # If complete, add newline
  if [[ $current -eq $total ]]; then
    echo ""
  fi
}

# ============================================================================
# Python/MCP Helpers
# ============================================================================

# Get Python executable for MCP scripts (checks virtualenv first)
gtd_get_mcp_python() {
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
    gtd_print_error "Python3 not found"
    return 1
  fi
}

# ============================================================================
# Second Brain Helpers
# ============================================================================

# Get MOC names from file system (returns array via output)
gtd_get_moc_names() {
  local MOC_DIR="${SECOND_BRAIN}/MOCs"
  
  if [[ -d "$MOC_DIR" ]]; then
    while IFS= read -r moc_file; do
      local topic=$(basename "$moc_file" .md | sed 's/^MOC - //')
      if [[ -n "$topic" ]]; then
        echo "$topic"
      fi
    done < <(find "$MOC_DIR" -name "MOC - *.md" -type f 2>/dev/null | sort)
  fi
}

# Get MOC content by name (returns full content of MOC file)
gtd_get_moc_content() {
  local moc_name="$1"
  local MOC_DIR="${SECOND_BRAIN}/MOCs"
  
  if [[ -z "$moc_name" ]]; then
    return 1
  fi
  
  # Try exact match first
  local moc_file="${MOC_DIR}/MOC - ${moc_name}.md"
  if [[ -f "$moc_file" ]]; then
    cat "$moc_file"
    return 0
  fi
  
  # Try case-insensitive search
  local found_file=$(find "$MOC_DIR" -iname "MOC - ${moc_name}.md" -type f 2>/dev/null | head -1)
  if [[ -n "$found_file" && -f "$found_file" ]]; then
    cat "$found_file"
    return 0
  fi
  
  # Try partial match (contains the name)
  found_file=$(find "$MOC_DIR" -iname "*${moc_name}*.md" -type f 2>/dev/null | head -1)
  if [[ -n "$found_file" && -f "$found_file" ]]; then
    cat "$found_file"
    return 0
  fi
  
  return 1
}

# Find session notes or notes related to a topic in Second Brain
gtd_find_related_notes() {
  local topic="$1"
  local max_results="${2:-10}"
  
  if [[ -z "$topic" ]]; then
    return 1
  fi
  
  local SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
  if [[ ! -d "$SECOND_BRAIN" ]]; then
    return 1
  fi
  
  # Search for notes that contain the topic in filename or content
  # Priority: filename matches > content matches
  local results=""
  local count=0
  
  # First, try filename matches (most relevant)
  # For multi-word topics, search for files containing any of the words (more flexible)
  # Then verify content matches the full topic
  local search_words=()
  if [[ "$topic" =~ [[:space:]] ]]; then
    # Split topic into words for flexible searching
    read -a search_words <<< "$topic"
    # Use first word for initial filename search (most common word)
    search_pattern="*${search_words[0]}*"
  else
    search_pattern="*${topic}*"
    search_words=("$topic")
  fi
  
  while IFS= read -r note_file && [[ $count -lt $max_results ]]; do
    # For multi-word topics, check if file content contains the topic
    # This is more flexible than requiring all words in filename
    local topic_in_content=false
    if [[ "$topic" =~ [[:space:]] ]]; then
      # Check if content contains the full topic phrase (case-insensitive)
      if grep -qi "$topic" "$note_file" 2>/dev/null; then
        topic_in_content=true
      fi
      # Also check if filename contains key words
      local filename_match=false
      for word in "${search_words[@]}"; do
        if echo "$(basename "$note_file")" | grep -qi "$word"; then
          filename_match=true
          break
        fi
      done
      # Include if either filename or content matches
      if [[ "$topic_in_content" != "true" && "$filename_match" != "true" ]]; then
        continue
      fi
    else
      # Single word - check filename
      if ! echo "$(basename "$note_file")" | grep -qi "$topic"; then
        continue
      fi
    fi
    
    local note_title=$(basename "$note_file" .md)
    local note_path="${note_file#$SECOND_BRAIN/}"
    
    # Get more lines for session notes (up to 100 lines for better context)
    local preview=$(head -100 "$note_file" 2>/dev/null)
    
    results="${results}---\n"
    results="${results}Note: ${note_title}\n"
    results="${results}Path: ${note_path}\n"
    results="${results}Content:\n${preview}\n"
    results="${results}---\n"
    results="${results}\n"
    
    ((count++))
  done < <(find "$SECOND_BRAIN" -type f -name "*.md" \
    ! -path "*/MOCs/*" \
    ! -path "*/.obsidian/*" \
    -iname "$search_pattern" \
    2>/dev/null | head -$max_results)
  
  # If we haven't found enough, search in content
  if [[ $count -lt $max_results ]]; then
    while IFS= read -r note_file && [[ $count -lt $max_results ]]; do
      # Skip if already included
      if echo "$results" | grep -q "$(basename "$note_file")"; then
        continue
      fi
      
      # Check if content contains the topic (case-insensitive)
      # For multi-word topics, prefer exact phrase match, but also accept all words present
      local topic_matches=false
      if [[ "$topic" =~ [[:space:]] ]]; then
        # First try exact phrase match (more relevant)
        if grep -qi "$topic" "$note_file" 2>/dev/null; then
          topic_matches=true
        else
          # Fallback: check if all words are present (more flexible)
          local all_words_present=true
          for word in $topic; do
            if ! grep -qi "$word" "$note_file" 2>/dev/null; then
              all_words_present=false
              break
            fi
          done
          if [[ "$all_words_present" == "true" ]]; then
            topic_matches=true
          fi
        fi
      else
        if grep -qi "$topic" "$note_file" 2>/dev/null; then
          topic_matches=true
        fi
      fi
      
      if [[ "$topic_matches" == "true" ]]; then
        local note_title=$(basename "$note_file" .md)
        local note_path="${note_file#$SECOND_BRAIN/}"
        # Get more content for session notes (up to 100 lines for better context)
        local preview=$(head -100 "$note_file" 2>/dev/null)
        
        results="${results}---\n"
        results="${results}Note: ${note_title}\n"
        results="${results}Path: ${note_path}\n"
        results="${results}Content:\n${preview}\n"
        results="${results}---\n"
        results="${results}\n"
        
        ((count++))
      fi
    done < <(find "$SECOND_BRAIN" -type f -name "*.md" \
      ! -path "*/MOCs/*" \
      ! -path "*/.obsidian/*" \
      2>/dev/null)
  fi
  
  if [[ -n "$results" ]]; then
    echo -e "$results"
    return 0
  fi
  
  return 1
}

# Get all notes from Second Brain (returns array of "category|path|name" via output)
gtd_get_second_brain_notes() {
  local SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
  
  if [[ ! -d "$SECOND_BRAIN" ]]; then
    return 1
  fi
  
  find "$SECOND_BRAIN" -type f -name "*.md" \
    ! -path "*/MOCs/*" \
    ! -path "*/.obsidian/*" \
    ! -name "MOC - *.md" \
    2>/dev/null | while IFS= read -r note_path; do
    local category=""
    local relative_path="${note_path#$SECOND_BRAIN/}"
    
    if [[ "$relative_path" == Projects/* ]]; then
      category="Projects"
    elif [[ "$relative_path" == Areas/* ]]; then
      category="Areas"
    elif [[ "$relative_path" == Resources/* ]]; then
      category="Resources"
    elif [[ "$relative_path" == Archives/* ]]; then
      category="Archives"
    else
      category="Resources"
    fi
    
    local note_name=$(basename "$note_path" .md)
    echo "${category}|${note_path}|${note_name}"
  done | sort -t'|' -k1,1 -k3,3
}

# Wrapper functions for common helpers (aliases don't work in process substitutions)
# These must come after the functions they wrap
get_moc_names_array() {
  gtd_get_moc_names
}

get_second_brain_notes() {
  gtd_get_second_brain_notes
}

# ============================================================================
# Frontmatter Helpers
# ============================================================================

# Extract frontmatter value from a markdown file
gtd_get_frontmatter_value() {
  local file="$1"
  local key="$2"
  grep "^${key}:" "$file" 2>/dev/null | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

# Get project name from README (checks project:, name:, then directory name)
# Usage: get_project_name <readme_file>
get_project_name() {
  local readme_file="$1"
  [[ -z "$readme_file" || ! -f "$readme_file" ]] && return 1
  
  local name=$(gtd_get_frontmatter_value "$readme_file" "project")
  [[ -z "$name" ]] && name=$(gtd_get_frontmatter_value "$readme_file" "name")
  [[ -z "$name" ]] && name=$(basename "$(dirname "$readme_file")")
  echo "$name"
}

# Check if directory has files matching pattern
# Usage: directory_has_files <directory> [pattern]
# Returns: 0 if files found, 1 if not
directory_has_files() {
  local dir="$1"
  local pattern="${2:-*.md}"
  [[ -d "$dir" ]] && [[ -n "$(find "$dir" -type f -name "$pattern" 2>/dev/null | head -1)" ]]
}

# Find task file by ID (searches TASKS_PATH and PROJECTS_PATH)
# Usage: find_task_file <task_id>
# Returns: task file path via stdout, empty if not found
find_task_file() {
  local task_id="$1"
  [[ -z "$task_id" ]] && return 1
  
  # Search in tasks directory
  local task_file=$(find "$TASKS_PATH" -name "${task_id}*.md" 2>/dev/null | head -1)
  
  # If not found, search in project directories
  if [[ -z "$task_file" ]] && [[ -d "$PROJECTS_PATH" ]]; then
    task_file=$(find "$PROJECTS_PATH" -name "${task_id}*.md" ! -name "README.md" 2>/dev/null | head -1)
  fi
  
  if [[ -n "$task_file" && -f "$task_file" ]]; then
    echo "$task_file"
    return 0
  fi
  
  return 1
}

# ============================================================================
# Date/Time Helpers
# ============================================================================

# Get date command (handles different systems)
gtd_get_date_cmd() {
  if [[ -x "/usr/bin/date" ]]; then
    echo "/usr/bin/date"
  elif [[ -x "/bin/date" ]]; then
    echo "/bin/date"
  else
    echo "date"
  fi
}

# Get today's date in YYYY-MM-DD format
gtd_get_today() {
  local DATE_CMD=$(gtd_get_date_cmd)
  $DATE_CMD +"%Y-%m-%d"
}

# Get current time in HH:MM format
gtd_get_current_time() {
  local DATE_CMD=$(gtd_get_date_cmd)
  $DATE_CMD +"%H:%M"
}

# ============================================================================
# Thinking Timer Helper
# ============================================================================

# Show thinking timer for long-running operations (> 2 seconds)
# Usage:
#   show_thinking_timer "Thinking" &
#   timer_pid=$!
#   # Your long-running command
#   your_command
#   stop_thinking_timer $timer_pid
show_thinking_timer() {
  local label="${1:-Thinking}"
  local delay="${2:-2}"  # Wait 2 seconds before showing timer
  local parent_pid="${3:-$$}"  # Optional parent PID to monitor (0 = don't check, run until stopped)
  local start_time=$(date +%s)
  
  # Timer writes to stderr - ensure it's not redirected
  
  # Truncate label if too long (max 40 chars to avoid wrapping)
  if [[ ${#label} -gt 40 ]]; then
    label="${label:0:37}..."
  fi
  
  # Wait for delay, then start spinner if still needed
  sleep "$delay"
  
  # Check if we should still show the timer (parent process might have finished)
  # Skip check if parent_pid is 0 (means "run until explicitly stopped")
  if [[ "$parent_pid" != "0" ]]; then
    if ! kill -0 "$parent_pid" 2>/dev/null; then
      return 0
    fi
  fi
  
  local spinner_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local idx=0
  
  while true; do
    # Check if parent process is still running (skip if parent_pid is 0)
    if [[ "$parent_pid" != "0" ]]; then
      if ! kill -0 "$parent_pid" 2>/dev/null; then
        break
      fi
    fi
    
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    
    # Clear line and print timer (use \033[K to clear to end of line)
    # Always write to stderr - it displays to terminal unless explicitly redirected
    if [[ $hours -gt 0 ]]; then
      printf "\r\033[K🤔 %s %s T+%02d:%02d:%02d" "$label" "${spinner_chars[$idx]}" "$hours" "$minutes" "$seconds" >&2
    else
      printf "\r\033[K🤔 %s %s T+%02d:%02d" "$label" "${spinner_chars[$idx]}" "$minutes" "$seconds" >&2
    fi
    
    idx=$(( (idx + 1) % ${#spinner_chars[@]} ))
    sleep 0.1
  done
  
  # Clear the timer line when exiting normally
  printf "\r\033[K" >&2
}

# Stop thinking timer and clear the line
stop_thinking_timer() {
  local timer_pid="$1"
  if [[ -n "$timer_pid" ]]; then
    # Kill the timer process and wait for it
    kill "$timer_pid" 2>/dev/null || true
    # Wait with timeout to avoid hanging
    # Note: wait can return 143 (SIGTERM) when process is killed, so we ignore exit code
    (sleep 0.5; kill -9 "$timer_pid" 2>/dev/null) &
    wait "$timer_pid" 2>/dev/null || true
    kill %1 2>/dev/null || true  # Kill the timeout watcher
  fi
  # Clear the entire line and move cursor to beginning
  printf "\r\033[K" >&2
  echo -ne "\r\033[K" >&2
  # Also print a newline to ensure we're on a fresh line
  printf "\n" >&2
  # Always return success to prevent scripts with set -e from exiting
  return 0
}

# Run a command with timeout (macOS-compatible)
# Usage:
#   run_with_timeout 5 command arg1 arg2  # Run with 5 second timeout
#   output=$(run_with_timeout 10 command arg1 arg2)  # Capture output
#   exit_code=$?  # 124 = timeout, otherwise command's exit code
# Returns: exit code (124 if timeout, otherwise command's exit code)
# Output: command's stdout/stderr (unless redirected)
run_with_timeout() {
  local timeout_seconds="$1"
  shift
  local command=("$@")
  
  if [[ -z "$timeout_seconds" || $timeout_seconds -le 0 ]]; then
    # No timeout requested, just run the command
    "${command[@]}"
    return $?
  fi
  
  # Try to use timeout/gtimeout if available (most reliable)
  if command -v timeout &>/dev/null || command -v gtimeout &>/dev/null; then
    local timeout_cmd=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null)
    $timeout_cmd "$timeout_seconds" "${command[@]}"
    local exit_code=$?
    # timeout returns 124 on timeout
    return $exit_code
  fi
  
  # Fallback for macOS without timeout: run in background with kill
  local temp_file=$(mktemp)
  local output_file="${temp_file}.out"
  local done_file="${temp_file}.done"
  
  # Run command in background, write output and done marker
  (
    "${command[@]}" > "$output_file" 2>&1
    echo "done" > "$done_file"
  ) &
  local pid=$!
  
  # Start killer process that will terminate after timeout
  (
    sleep "$timeout_seconds"
    if [[ ! -f "$done_file" ]]; then
      # Process still running - kill it
      kill -TERM "$pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$pid" 2>/dev/null || true
    fi
  ) &
  local killer_pid=$!
  
  # Wait for command to finish
  wait "$pid" 2>/dev/null
  local wait_exit=$?
  
  # Kill the killer process
  kill "$killer_pid" 2>/dev/null || true
  wait "$killer_pid" 2>/dev/null || true
  
  # Determine exit code
  local exit_code=0
  if [[ -f "$done_file" ]]; then
    # Command finished normally
    cat "$output_file" 2>/dev/null || true
    exit_code=0
  else
    # Timeout occurred
    cat "$output_file" 2>/dev/null || true
    exit_code=124  # Standard timeout exit code
  fi
  
  # Cleanup
  rm -f "$output_file" "$done_file" 2>/dev/null || true
  
  return $exit_code
}

# Wrapper function to run a command with automatic thinking timer
# Usage:
#   run_with_thinking_timer "Processing" your_command arg1 arg2
#   output=$(run_with_thinking_timer "Processing" your_command arg1 arg2)  # Captures output
run_with_thinking_timer() {
  local label="${1:-Processing}"
  shift
  local command=("$@")
  
  # Start timer in background (waits 2 seconds before showing)
  # Pass 0 as parent PID to disable parent monitoring (timer will run until explicitly stopped)
  show_thinking_timer "$label" 2 0 &
  local timer_pid=$!
  
  # Run the command normally (not in background so we can capture output/errors)
  local exit_code=0
  "${command[@]}" || exit_code=$?
  
  # Stop timer (this will also clear the line)
  stop_thinking_timer $timer_pid
  
  return $exit_code
}

# Wrapper function to run a command with automatic thinking timer and capture output
# Usage:
#   output=$(run_with_thinking_timer_capture "Processing" your_command arg1 arg2)
run_with_thinking_timer_capture() {
  local label="${1:-Processing}"
  shift
  local command=("$@")
  
  # Start timer in background (waits 2 seconds before showing)
  # Pass 0 as parent PID to disable parent monitoring (timer will run until explicitly stopped)
  show_thinking_timer "$label" 2 0 &
  local timer_pid=$!
  
  # Run the command and capture output
  local output
  output=$("${command[@]}" 2>&1)
  local exit_code=$?
  
  # Stop timer
  stop_thinking_timer $timer_pid
  
  # Output the result (so it can be captured)
  echo -n "$output"
  return $exit_code
}

# ============================================================================
# Daily Log Statistics (Shared across all reminder scripts)
# ============================================================================

# Get daily log statistics (shared function for all reminders)
# Returns: "Entries: X" and optionally "Goals: Y"
gtd_get_log_stats() {
  local today="${1:-$(gtd_get_today)}"
  local log_file="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  
  if [[ ! -f "$log_file" ]]; then
    echo "No log entries today"
    return
  fi
  
  # Try to use gtd-log-stats script first for consistency with other systems
  local stats_script="gtd-log-stats"
  # Try to find it in common locations
  if [[ -f "$HOME/code/dotfiles/bin/gtd-log-stats" ]]; then
    stats_script="$HOME/code/dotfiles/bin/gtd-log-stats"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-stats" ]]; then
    stats_script="$HOME/code/personal/dotfiles/bin/gtd-log-stats"
  fi
  
  if command -v "$stats_script" &>/dev/null || [[ -f "$stats_script" ]]; then
    # Ensure DAILY_LOG_DIR is exported so gtd-log-stats can use it
    export DAILY_LOG_DIR
    local entry_count=$("$stats_script" today 2>/dev/null | tr -d '[:space:]' || echo "0")
    # gtd-log-stats today returns just the number
    if [[ "$entry_count" =~ ^[0-9]+$ ]] && [[ "$entry_count" != "0" ]]; then
      local goal_count=$(grep -ci "goal" "$log_file" 2>/dev/null || echo "0")
      echo "Entries: $entry_count"
      if [[ $goal_count -gt 0 ]]; then
        echo "Goals: $goal_count"
      fi
      return
    fi
    # If gtd-log-stats returned 0, fall through to pattern matching
  fi
  
  # Fallback: use the same pattern as other systems (gtd-log-stats, gtd-brain-sync-daily-logs)
  # Pattern matches: "HH:MM - entry" format (exactly 2 digits for hours and minutes)
  local entry_count=$(grep -c "^[0-9][0-9]:[0-9][0-9] -" "$log_file" 2>/dev/null || echo "0")
  
  # Fallback: try alternative patterns if the standard format doesn't match
  if [[ "$entry_count" == "0" ]] || [[ -z "$entry_count" ]]; then
    # Pattern 2: "HH:MM -" (with 1-2 digits for hours, space before dash)
    entry_count=$(grep -cE "^[0-9]{1,2}:[0-9]{2}[[:space:]]*-" "$log_file" 2>/dev/null || echo "0")
  fi
  if [[ "$entry_count" == "0" ]] || [[ -z "$entry_count" ]]; then
    # Pattern 3: Any line starting with time-like pattern (1-2 digits:2 digits)
    entry_count=$(grep -cE "^[0-9]{1,2}:[0-9]{2}" "$log_file" 2>/dev/null | grep -v "^#" | wc -l | tr -d ' ' || echo "0")
  fi
  
  # Ensure entry_count is numeric
  if [[ ! "$entry_count" =~ ^[0-9]+$ ]]; then
    entry_count=0
  fi
  
  local goal_count=$(grep -ci "goal" "$log_file" 2>/dev/null || echo "0")
  
  echo "Entries: $entry_count"
  if [[ $goal_count -gt 0 ]]; then
    echo "Goals: $goal_count"
  fi
}

# Extract entry count from stats string
# Usage: entry_count=$(gtd_extract_entry_count "$stats")
gtd_extract_entry_count() {
  local stats="$1"
  echo "$stats" | grep -oE "Entries: [0-9]+" | grep -oE "[0-9]+" || echo "0"
}

# ============================================================================
# Computer Mode Preservation (for sync operations)
# ============================================================================

# Get local computer mode preference file path (gitignored, per-computer)
gtd_get_computer_mode_file() {
  local mode_file="$HOME/.gtd_computer_mode"
  # Try dotfiles location first
  if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
    mode_file="$HOME/code/dotfiles/.gtd_computer_mode"
  elif [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
    mode_file="$HOME/code/personal/dotfiles/.gtd_computer_mode"
  fi
  echo "$mode_file"
}

# Detect which computer this is (work or home) based on hostname or user
# Returns: "work" or "home"
gtd_detect_computer_type() {
  local hostname=$(hostname 2>/dev/null || echo "")
  local username=$(whoami 2>/dev/null || echo "")
  
  # Check hostname for work-related keywords
  if echo "$hostname" | grep -qiE "(work|office|corp|company|business|workstation|desktop.*work)"; then
    echo "work"
    return 0
  fi
  
  # Check username for work-related patterns
  if echo "$username" | grep -qiE "(work|office|corp|company|business)"; then
    echo "work"
    return 0
  fi
  
  # Default to home if we can't detect
  echo "home"
}

# Save current computer mode preference (for this specific computer)
# This creates a local file that won't be synced via git
gtd_save_computer_mode_preference() {
  local mode="${1:-}"
  if [[ -z "$mode" ]]; then
    # Try to detect
    mode=$(gtd_detect_computer_type)
  fi
  
  local mode_file=$(gtd_get_computer_mode_file)
  echo "$mode" > "$mode_file" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    gtd_print_info "Saved computer mode preference: $mode (stored locally, won't sync)"
  fi
}

# Get saved computer mode preference for this computer
gtd_get_computer_mode_preference() {
  local mode_file=$(gtd_get_computer_mode_file)
  
  if [[ -f "$mode_file" ]]; then
    local saved_mode=$(cat "$mode_file" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [[ "$saved_mode" == "work" || "$saved_mode" == "home" ]]; then
      echo "$saved_mode"
      return 0
    fi
  fi
  
  # No saved preference - try to detect
  gtd_detect_computer_type
}

# Preserve and restore computer mode during sync operations
# Call this before sync to save current mode, and after sync to restore if needed
# Usage: gtd_preserve_computer_mode [before|after]
gtd_preserve_computer_mode() {
  local phase="${1:-before}"
  
  # Find config file
  local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config" ]]; then
    gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  if [[ ! -f "$gtd_config" ]]; then
    return 0  # No config file, nothing to do
  fi
  
  if [[ "$phase" == "before" ]]; then
    # Before sync: save current mode and this computer's preference
    local current_mode=$(grep "^GTD_COMPUTER_MODE=" "$gtd_config" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    if [[ -n "$current_mode" ]]; then
      # Save current mode to temp file
      echo "$current_mode" > "/tmp/gtd_mode_before_sync" 2>/dev/null
    fi
    
    # Ensure we have a saved preference for this computer
    local mode_file=$(gtd_get_computer_mode_file)
    if [[ ! -f "$mode_file" ]]; then
      # No preference saved yet - detect and save it
      local preferred_mode=$(gtd_detect_computer_type)
      gtd_save_computer_mode_preference "$preferred_mode"
    fi
  elif [[ "$phase" == "after" ]]; then
    # After sync: check if mode changed and restore if needed
    local mode_before=""
    if [[ -f "/tmp/gtd_mode_before_sync" ]]; then
      mode_before=$(cat "/tmp/gtd_mode_before_sync" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
      rm -f "/tmp/gtd_mode_before_sync" 2>/dev/null
    fi
    
    local mode_after=$(grep "^GTD_COMPUTER_MODE=" "$gtd_config" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    
    # Get this computer's preferred mode
    local preferred_mode=$(gtd_get_computer_mode_preference)
    
    # If mode changed and doesn't match this computer's preference, restore it
    if [[ -n "$mode_after" && "$mode_after" != "$preferred_mode" ]]; then
      # Mode was changed by sync - restore to this computer's preference
      if [[ -f "$gtd_config" ]]; then
        # Source wizard core to get set_computer_mode function
        local wizard_core="$HOME/code/dotfiles/bin/gtd-wizard-core.sh"
        if [[ ! -f "$wizard_core" ]]; then
          wizard_core="$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh"
        fi
        
        if [[ -f "$wizard_core" ]]; then
          # Source wizard core to get the function
          source "$wizard_core" 2>/dev/null || true
          if declare -f set_computer_mode &>/dev/null; then
            set_computer_mode "$preferred_mode" >/dev/null 2>&1
            gtd_print_info "Restored computer mode to: $preferred_mode (after sync)"
          fi
        else
          # Fallback: directly update the config file
          if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/^GTD_COMPUTER_MODE=.*/GTD_COMPUTER_MODE=\"$preferred_mode\"/" "$gtd_config" 2>/dev/null
          else
            sed -i "s/^GTD_COMPUTER_MODE=.*/GTD_COMPUTER_MODE=\"$preferred_mode\"/" "$gtd_config" 2>/dev/null
          fi
          gtd_print_info "Restored computer mode to: $preferred_mode (after sync)"
        fi
      fi
    fi
  fi
}

