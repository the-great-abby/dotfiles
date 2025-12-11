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
    kill "$timer_pid" 2>/dev/null
    # Wait with timeout to avoid hanging
    (sleep 0.5; kill -9 "$timer_pid" 2>/dev/null) &
    wait "$timer_pid" 2>/dev/null
    kill %1 2>/dev/null  # Kill the timeout watcher
  fi
  # Clear the entire line and move cursor to beginning
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

