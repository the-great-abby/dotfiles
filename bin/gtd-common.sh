#!/bin/bash
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
    source "$GTD_CONFIG_FILE"
  fi
}

# Initialize GTD directories and paths
init_gtd_paths() {
  GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
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
  
  SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
}

# Auto-load everything on source
load_common_env
load_gtd_config
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
  local parent_pid="${3:-$$}"  # Optional parent PID to monitor
  local start_time=$(date +%s)
  
  # Truncate label if too long (max 40 chars to avoid wrapping)
  if [[ ${#label} -gt 40 ]]; then
    label="${label:0:37}..."
  fi
  
  # Wait for delay, then start spinner if still needed
  sleep "$delay"
  
  # Check if we should still show the timer (parent process might have finished)
  if ! kill -0 "$parent_pid" 2>/dev/null; then
    return 0
  fi
  
  local spinner_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local idx=0
  
  while true; do
    # Check if parent process is still running
    if ! kill -0 "$parent_pid" 2>/dev/null; then
      break
    fi
    
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    
    # Clear line and print timer (use \033[K to clear to end of line)
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
    kill "$timer_pid" 2>/dev/null
    # Wait with timeout to avoid hanging
    (sleep 0.5; kill -9 "$timer_pid" 2>/dev/null) &
    wait "$timer_pid" 2>/dev/null
    kill %1 2>/dev/null  # Kill the timeout watcher
  fi
  # Clear the entire line and move cursor to beginning
  # Use multiple methods to ensure display is cleared
  printf "\r\033[K" >&2
  echo -ne "\r\033[K" >&2
  # Also print a newline to ensure we're on a fresh line
  printf "\n" >&2
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
  # Pass current shell PID so timer can monitor when command finishes
  show_thinking_timer "$label" 2 $$ &
  local timer_pid=$!
  
  # Run the command and capture output if needed
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
  show_thinking_timer "$label" 2 &
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

