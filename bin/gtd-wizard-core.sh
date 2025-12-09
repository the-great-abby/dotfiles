#!/bin/bash
# GTD Wizard Core Functions
# Core dashboard, menu, and navigation functions for the wizard

# ============================================================================
# Computer Mode Functions
# ============================================================================

# Get current computer mode (work/home)
get_computer_mode() {
  # Load config if not already loaded
  if [[ -z "${GTD_COMPUTER_MODE:-}" ]]; then
    local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
    if [[ ! -f "$gtd_config" ]]; then
      gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
    fi
    if [[ -f "$gtd_config" ]]; then
      source "$gtd_config" 2>/dev/null || true
    fi
  fi
  
  echo "${GTD_COMPUTER_MODE:-home}"
}

# Set computer mode (work/home)
set_computer_mode() {
  local mode="${1:-}"
  
  if [[ -z "$mode" ]]; then
    echo "Usage: set_computer_mode <work|home>" >&2
    return 1
  fi
  
  if [[ "$mode" != "work" && "$mode" != "home" ]]; then
    echo "Error: Mode must be 'work' or 'home'" >&2
    return 1
  fi
  
  # Update config file
  local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config" ]]; then
    gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  if [[ -f "$gtd_config" ]]; then
    # Update or add the setting
    if grep -q "^GTD_COMPUTER_MODE=" "$gtd_config" 2>/dev/null; then
      # Update existing line
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^GTD_COMPUTER_MODE=.*/GTD_COMPUTER_MODE=\"$mode\"/" "$gtd_config"
      else
        sed -i "s/^GTD_COMPUTER_MODE=.*/GTD_COMPUTER_MODE=\"$mode\"/" "$gtd_config"
      fi
    else
      # Add new line after GTD_USER_NAME
      if grep -q "^GTD_USER_NAME=" "$gtd_config" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
          sed -i '' "/^GTD_USER_NAME=.*/a\\
GTD_COMPUTER_MODE=\"$mode\"
" "$gtd_config"
        else
          sed -i "/^GTD_USER_NAME=.*/a GTD_COMPUTER_MODE=\"$mode\"" "$gtd_config"
        fi
      else
        # Just append to file
        echo "GTD_COMPUTER_MODE=\"$mode\"" >> "$gtd_config"
      fi
    fi
    
    # Update current session
    export GTD_COMPUTER_MODE="$mode"
    echo "Computer mode set to: $mode"
    return 0
  else
    echo "Error: Config file not found: $gtd_config" >&2
    return 1
  fi
}

# ============================================================================
# Smart Defaults Functions
# ============================================================================

# Auto-detect time of day (morning/afternoon/evening)
get_time_of_day() {
  local hour=$(date +"%H" 2>/dev/null || echo "12")
  hour=$((10#$hour))  # Force base 10 interpretation
  
  if [[ $hour -ge 5 && $hour -lt 12 ]]; then
    echo "morning"
  elif [[ $hour -ge 12 && $hour -lt 17 ]]; then
    echo "afternoon"
  elif [[ $hour -ge 17 && $hour -lt 21 ]]; then
    echo "evening"
  else
    echo "evening"  # Default to evening for late night
  fi
}

# Check if morning check-in was done today
checkin_done_today() {
  local checkin_type="${1:-morning}"  # morning or evening
  local today=$(gtd_get_today)
  local today_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  
  if [[ ! -f "$today_log" ]]; then
    return 1  # No log file = no check-in
  fi
  
  # Check for check-in markers in daily log
  if [[ "$checkin_type" == "morning" ]]; then
    # Look for morning check-in patterns
    if grep -qiE "(morning check-in|morning checkin|🌅|morning intentions|top 3 priorities for today)" "$today_log" 2>/dev/null; then
      return 0
    fi
  else
    # Look for evening check-in patterns
    if grep -qiE "(evening check-in|evening checkin|🌙|evening reflection|what did i accomplish)" "$today_log" 2>/dev/null; then
      return 0
    fi
  fi
  
  return 1
}

# Get day of week (0=Sunday, 1=Monday, etc.)
get_day_of_week() {
  date +"%w" 2>/dev/null || echo "0"
}

# Get day name (Monday, Tuesday, etc.)
get_day_name() {
  date +"%A" 2>/dev/null || echo ""
}

# Check if weekly review was done this week
weekly_review_done_this_week() {
  # Ensure GTD_BASE_DIR is set
  if [[ -z "${GTD_BASE_DIR:-}" ]]; then
    if command -v init_gtd_paths &>/dev/null; then
      init_gtd_paths
    else
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    fi
  fi
  
  local weekly_reviews_dir="${GTD_BASE_DIR}/weekly-reviews"
  local this_week_start=$(date -v-monday +"%Y-%m-%d" 2>/dev/null || date -d "last monday" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d")
  
  # Check if there's a review file created this week
  if [[ -d "$weekly_reviews_dir" ]]; then
    if find "$weekly_reviews_dir" -name "*.md" -newermt "$this_week_start" 2>/dev/null | grep -q .; then
      return 0  # Review found
    fi
  fi
  
  return 1  # No review found
}

# Count tasks completed today
tasks_completed_today() {
  # Ensure paths are initialized
  if [[ -z "${TASKS_PATH:-}" ]]; then
    if command -v init_gtd_paths &>/dev/null; then
      init_gtd_paths
    else
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
      TASKS_PATH="${GTD_BASE_DIR}/tasks"
    fi
  fi
  
  local today=$(gtd_get_today)
  local tasks_path="${TASKS_PATH}"
  local count=0
  
  if [[ -d "$tasks_path" ]]; then
    # Look for tasks marked done/completed today
    while IFS= read -r task_file; do
      if [[ -f "$task_file" ]]; then
        # Check if task has completion date today
        if grep -qiE "(completed|done|finished).*${today}" "$task_file" 2>/dev/null; then
          ((count++))
        fi
      fi
    done < <(find "$tasks_path" -name "*.md" -type f 2>/dev/null)
  fi
  
  echo "$count"
}

# Check if feature is rarely used (should stop suggesting)
feature_rarely_used() {
  local feature_option="$1"
  local preferences_file="${HOME}/.gtd_preferences.json"
  
  if [[ ! -f "$preferences_file" ]]; then
    return 1  # No data = can't determine, so suggest it
  fi
  
  # Get usage count for this wizard option
  local usage_count=$(python3 2>/dev/null <<EOF
import json
from pathlib import Path

prefs_file = Path("$preferences_file")
if not prefs_file.exists():
    print("0")
    exit(0)

with open(prefs_file) as f:
    prefs = json.load(f)

option = "$feature_option"
wizard_options = prefs.get("feature_usage", {}).get("wizard_options", {})
count = wizard_options.get(option, 0)
print(count)
EOF
)
  
  # If used less than 3 times total, consider it rarely used
  if [[ "${usage_count:-0}" -lt 3 ]]; then
    return 0  # Rarely used
  fi
  
  return 1  # Used enough
}

# Check if feature is commonly used together with another
features_used_together() {
  local feature1="$1"
  local feature2="$2"
  
  # This would require more sophisticated tracking
  # For now, return false (not implemented yet)
  return 1
}

# Get smart default suggestions based on context
get_smart_defaults() {
  local time_of_day=$(get_time_of_day)
  local computer_mode=$(get_computer_mode)
  
  # Ensure paths are initialized
  if [[ -z "${INBOX_PATH:-}" ]]; then
    if command -v init_gtd_paths &>/dev/null; then
      init_gtd_paths
    else
      # Fallback initialization
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
      INBOX_PATH="${GTD_BASE_DIR}/${GTD_INBOX_DIR:-0-inbox}"
    fi
  fi
  
  local inbox_count=0
  if [[ -d "${INBOX_PATH}" ]]; then
    inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  local today=$(gtd_get_today)
  local today_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  local today_entries=0
  if [[ -f "$today_log" ]]; then
    today_entries=$(grep -c "^[0-9][0-9]:[0-9][0-9] -" "$today_log" 2>/dev/null || echo "0")
  fi
  
  local suggestions=()
  local priorities=()
  
  # Get additional context
  local day_name=$(get_day_name)
  local day_of_week=$(get_day_of_week)
  local morning_checkin_done=false
  local evening_checkin_done=false
  local weekly_review_done=false
  local tasks_completed=0
  
  if checkin_done_today "morning"; then
    morning_checkin_done=true
  fi
  
  if checkin_done_today "evening"; then
    evening_checkin_done=true
  fi
  
  if weekly_review_done_this_week; then
    weekly_review_done=true
  fi
  
  tasks_completed=$(tasks_completed_today)
  
  # ============================================================================
  # Morning Context Logic
  # ============================================================================
  if [[ "$time_of_day" == "morning" ]]; then
    # Haven't done check-in yet today → Suggest 19
    if [[ "$morning_checkin_done" == false ]]; then
      priorities+=("19|Morning Check-In|Start your day with intention")
    fi
    
    # Inbox not empty → Suggest 2 (process)
    if [[ $inbox_count -gt 0 ]]; then
      priorities+=("2|Process inbox|${inbox_count} item(s) waiting")
    fi
    
    # No log entries today → Suggest 15
    if [[ $today_entries -eq 0 ]]; then
      suggestions+=("15|Log to daily log|Start tracking your day")
    fi
    
    # Monday/Friday → Suggest 6 (weekly review prep/wrap)
    if [[ "$day_name" == "Monday" ]]; then
      if [[ "$weekly_review_done" == false ]]; then
        suggestions+=("6|Weekly Review|Plan your week")
      fi
    elif [[ "$day_name" == "Friday" ]]; then
      if [[ "$weekly_review_done" == false ]]; then
        suggestions+=("6|Weekly Review|Wrap up your week")
      fi
    fi
    
    # Always suggest capture in morning
    suggestions+=("1|Capture to inbox|Capture thoughts and ideas")
  fi
  
  # ============================================================================
  # Afternoon Context Logic
  # ============================================================================
  if [[ "$time_of_day" == "afternoon" ]]; then
    suggestions+=("1|Capture to inbox|Capture thoughts and ideas")
    
    if [[ $inbox_count -gt 0 ]]; then
      priorities+=("2|Process inbox|${inbox_count} item(s) waiting")
    fi
    
    suggestions+=("40|What should I do now?|Get context-aware suggestions")
  fi
  
  # ============================================================================
  # Evening Context Logic
  # ============================================================================
  if [[ "$time_of_day" == "evening" ]]; then
    # Logged today but no evening check-in → Suggest 19
    if [[ $today_entries -gt 0 && "$evening_checkin_done" == false ]]; then
      priorities+=("19|Evening Check-In|Reflect on your day")
    elif [[ "$evening_checkin_done" == false ]]; then
      suggestions+=("19|Evening Check-In|Reflect on your day")
    fi
    
    # Tasks marked done today → Suggest 42 (celebrate)
    if [[ $tasks_completed -gt 0 ]]; then
      suggestions+=("42|Celebrate milestones|You completed ${tasks_completed} task(s) today!")
    fi
    
    # No weekly review this week → Remind gently
    if [[ "$weekly_review_done" == false ]]; then
      suggestions+=("6|Weekly Review|Haven't done weekly review yet this week")
    fi
    
    suggestions+=("6|Daily Review|Review accomplishments and plan tomorrow")
    
    if [[ $inbox_count -gt 0 ]]; then
      priorities+=("2|Process inbox|Clear ${inbox_count} item(s) before tomorrow")
    fi
  fi
  
  # ============================================================================
  # Work Computer Mode Logic
  # ============================================================================
  if [[ "$computer_mode" == "work" ]]; then
    # Suggest capture (1) and log (15) heavily
    if [[ ! " ${suggestions[@]} " =~ " 1|" ]]; then
      suggestions+=("1|Capture to inbox|Capture work thoughts")
    fi
    if [[ ! " ${suggestions[@]} " =~ " 15|" && $today_entries -lt 3 ]]; then
      suggestions+=("15|Log to daily log|Track your work day")
    fi
    
    # Show calendar (29) prominently
    suggestions+=("29|Calendar|View schedule and check conflicts")
    
    # Don't suggest AI-heavy features (unless rarely used check passes)
    # Only suggest AI features if they're actually used
    if ! feature_rarely_used "11"; then
      suggestions+=("11|Get advice|Get personalized guidance")
    fi
    
    # Work-focused tasks
    if [[ ! " ${suggestions[@]} " =~ " 3|" ]]; then
      suggestions+=("3|Manage tasks|Review work tasks")
    fi
    if [[ ! " ${suggestions[@]} " =~ " 4|" ]]; then
      suggestions+=("4|Manage projects|Check active projects")
    fi
    
    if [[ $inbox_count -gt 0 && ! " ${priorities[@]} " =~ " 2|" ]]; then
      priorities+=("2|Process inbox|Clear work items")
    fi
  fi
  
  # ============================================================================
  # Home Computer Mode Logic
  # ============================================================================
  if [[ "$computer_mode" == "home" ]]; then
    # More flexible, personal tasks
    if [[ $today_entries -eq 0 && ! " ${suggestions[@]} " =~ " 15|" ]]; then
      suggestions+=("15|Log to daily log|Capture thoughts and activities")
    fi
    
    # AI features are fine at home
    if [[ ! " ${suggestions[@]} " =~ " 11|" ]]; then
      suggestions+=("11|Get advice|Get personalized guidance")
    fi
  fi
  
  # ============================================================================
  # Usage Pattern Learning
  # ============================================================================
  # Remove suggestions for rarely used features (unless they're priorities)
  local filtered_suggestions=()
  for suggestion in "${suggestions[@]}"; do
    if [[ -n "$suggestion" ]]; then
      IFS='|' read -r option title reason <<< "$suggestion"
      # Skip if feature is rarely used (but keep priorities and essential features)
      if feature_rarely_used "$option"; then
        # Skip rarely used features (except essential ones like 1, 2, 15, 19)
        if [[ "$option" =~ ^(1|2|15|19)$ ]]; then
          filtered_suggestions+=("$suggestion")  # Keep essential features
        fi
        # Skip others
      else
        filtered_suggestions+=("$suggestion")
      fi
    fi
  done
  suggestions=("${filtered_suggestions[@]}")
  
  # ============================================================================
  # System State Based Suggestions
  # ============================================================================
  if [[ $inbox_count -gt 0 && ! " ${priorities[@]} " =~ " 2|" ]]; then
    priorities+=("2|Process inbox|${inbox_count} item(s) need attention")
  fi
  
  # Output suggestions
  echo "SUGGESTIONS_START"
  for suggestion in "${suggestions[@]}"; do
    echo "$suggestion"
  done
  echo "SUGGESTIONS_END"
  
  echo "PRIORITIES_START"
  for priority in "${priorities[@]}"; do
    echo "$priority"
  done
  echo "PRIORITIES_END"
}

# Show smart defaults section in dashboard
show_smart_defaults() {
  local time_of_day=$(get_time_of_day)
  local computer_mode=$(get_computer_mode)
  
  # Get suggestions
  local suggestions_output=$(get_smart_defaults)
  local suggestions=()
  local priorities=()
  
  local in_suggestions=false
  local in_priorities=false
  
  while IFS= read -r line; do
    if [[ "$line" == "SUGGESTIONS_START" ]]; then
      in_suggestions=true
      in_priorities=false
      continue
    elif [[ "$line" == "SUGGESTIONS_END" ]]; then
      in_suggestions=false
      continue
    elif [[ "$line" == "PRIORITIES_START" ]]; then
      in_priorities=true
      in_suggestions=false
      continue
    elif [[ "$line" == "PRIORITIES_END" ]]; then
      in_priorities=false
      continue
    fi
    
    if [[ "$in_suggestions" == true && -n "$line" ]]; then
      suggestions+=("$line")
    elif [[ "$in_priorities" == true && -n "$line" ]]; then
      priorities+=("$line")
    fi
  done <<< "$suggestions_output"
  
  # Display smart defaults section
  echo -e "${BOLD}🎯 Smart Suggestions${NC}"
  echo ""
  
  # Show context
  local time_emoji=""
  case "$time_of_day" in
    morning) time_emoji="🌅" ;;
    afternoon) time_emoji="☀️" ;;
    evening) time_emoji="🌙" ;;
    *) time_emoji="🕐" ;;
  esac
  
  local mode_emoji=""
  case "$computer_mode" in
    work) mode_emoji="💼" ;;
    home) mode_emoji="🏠" ;;
    *) mode_emoji="💻" ;;
  esac
  
  # Capitalize first letter (compatible with all bash versions)
  # Simple approach: get first char, uppercase it, append rest
  local time_first="${time_of_day:0:1}"
  local time_rest="${time_of_day:1}"
  local time_display="$(echo "$time_first" | tr '[:lower:]' '[:upper:]')$time_rest"
  
  local mode_first="${computer_mode:0:1}"
  local mode_rest="${computer_mode:1}"
  local mode_display="$(echo "$mode_first" | tr '[:lower:]' '[:upper:]')$mode_rest"
  
  echo -e "  ${CYAN}Context: ${time_emoji} ${time_display} | ${mode_emoji} ${mode_display}${NC}"
  echo ""
  
  # Show priorities first (if any)
  if [[ ${#priorities[@]} -gt 0 ]]; then
    echo -e "  ${BOLD}${RED}⚠️  Priority Actions:${NC}"
    for priority in "${priorities[@]}"; do
      if [[ -n "$priority" ]]; then
        IFS='|' read -r option title reason <<< "$priority"
        echo -e "    ${BOLD}${RED}→${NC} Press ${BOLD}${GREEN}${option}${NC} to ${title}"
        if [[ -n "$reason" ]]; then
          echo -e "      ${YELLOW}${reason}${NC}"
        fi
      fi
    done
    echo ""
  fi
  
  # Show suggestions
  if [[ ${#suggestions[@]} -gt 0 ]]; then
    echo -e "  ${BOLD}💡 Suggested Actions:${NC}"
    for suggestion in "${suggestions[@]}"; do
      if [[ -n "$suggestion" ]]; then
        IFS='|' read -r option title reason <<< "$suggestion"
        echo -e "    ${CYAN}→${NC} Press ${BOLD}${GREEN}${option}${NC} to ${title}"
        if [[ -n "$reason" ]]; then
          echo -e "      ${GRAY}${reason}${NC}"
        fi
      fi
    done
    echo ""
  fi
  
  # If no suggestions or priorities, show a helpful message
  if [[ ${#priorities[@]} -eq 0 && ${#suggestions[@]} -eq 0 ]]; then
    echo -e "  ${GRAY}No specific suggestions at this time. Check your inbox and tasks!${NC}"
    echo ""
  fi
}

# Computer Mode Wizard
computer_mode_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💻 Switch Computer Mode${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local current_mode=$(get_computer_mode)
  local mode_emoji=""
  local mode_desc=""
  
  case "$current_mode" in
    work)
      mode_emoji="💼"
      mode_desc="Work computer - Focus on work tasks and projects"
      ;;
    home)
      mode_emoji="🏠"
      mode_desc="Home computer - Personal tasks and flexible activities"
      ;;
  esac
  
  echo -e "Current mode: ${BOLD}${mode_emoji} ${current_mode^}${NC}"
  echo -e "  ${GRAY}${mode_desc}${NC}"
  echo ""
  echo "Switch to:"
  echo ""
  if [[ "$current_mode" == "work" ]]; then
    echo -e "  ${GREEN}1)${NC} 🏠 Home mode"
    echo -e "     Personal tasks, flexible activities, learning"
  else
    echo -e "  ${GREEN}1)${NC} 💼 Work mode"
    echo -e "     Work tasks, projects, professional focus"
  fi
  echo ""
  echo -e "  ${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      if [[ "$current_mode" == "work" ]]; then
        set_computer_mode "home"
      else
        set_computer_mode "work"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
  esac
}

# Test execution wizard
test_execution_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🧪 Run Unit Tests${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Run unit tests to verify the GTD system is working correctly."
  echo ""
  echo "Available test suites:"
  echo ""
  echo -e "${BOLD}${CYAN}Bash Tests:${NC}"
  echo -e "  ${GREEN}1)${NC} Run all bash tests"
  echo -e "  ${GREEN}2)${NC} Test gtd-common.sh helpers"
  echo -e "  ${GREEN}3)${NC} Test gtd-guides.sh guides"
  echo -e "  ${GREEN}4)${NC} Test wizard functions"
  echo -e "  ${GREEN}5)${NC} Test wizard core functions"
  echo -e "  ${GREEN}6)${NC} Test zettelkasten wizard"
  echo ""
  echo -e "${BOLD}${CYAN}Python Tests:${NC}"
  echo -e "  ${GREEN}7)${NC} Run all Python tests"
  echo -e "  ${GREEN}8)${NC} Test enhanced search system"
  echo -e "  ${GREEN}9)${NC} Test persona helper"
  echo -e "  ${GREEN}10)${NC} Test tool registry"
  echo -e "  ${GREEN}11)${NC} Test LM Studio helper"
  echo ""
  echo -e "${BOLD}${CYAN}All Tests:${NC}"
  echo -e "  ${GREEN}12)${NC} Run complete test suite (all bash + Python)"
  echo ""
  echo -e "  ${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read choice
  
  # Get test directory
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local tests_dir="$script_dir/../tests"
  if [[ ! -d "$tests_dir" && -d "$HOME/code/personal/dotfiles/tests" ]]; then
    tests_dir="$HOME/code/personal/dotfiles/tests"
  fi
  
  case "$choice" in
    1)
      echo ""
      echo -e "${CYAN}Running all bash tests...${NC}"
      echo ""
      if [[ -f "$tests_dir/run_tests.sh" ]]; then
        bash "$tests_dir/run_tests.sh" 2>&1 | grep -E "(test_|Running:|Test|PASS|FAIL|Summary)" || bash "$tests_dir/run_tests.sh"
      else
        echo -e "${RED}Test runner not found: $tests_dir/run_tests.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    2)
      echo ""
      echo -e "${CYAN}Testing gtd-common.sh...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_common.sh" ]]; then
        bash "$tests_dir/test_gtd_common.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_common.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    3)
      echo ""
      echo -e "${CYAN}Testing gtd-guides.sh...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_guides.sh" ]]; then
        bash "$tests_dir/test_gtd_guides.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_guides.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    4)
      echo ""
      echo -e "${CYAN}Testing wizard functions...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_wizard_functions.sh" ]]; then
        bash "$tests_dir/test_wizard_functions.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_wizard_functions.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    5)
      echo ""
      echo -e "${CYAN}Testing wizard core functions...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_wizard_core_functions.sh" ]]; then
        bash "$tests_dir/test_wizard_core_functions.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_wizard_core_functions.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    6)
      echo ""
      echo -e "${CYAN}Testing zettelkasten wizard...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_zettelkasten_wizard.sh" ]]; then
        bash "$tests_dir/test_zettelkasten_wizard.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_zettelkasten_wizard.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    7)
      echo ""
      echo -e "${CYAN}Running all Python tests...${NC}"
      echo ""
      for test_file in "$tests_dir"/test_*.py; do
        if [[ -f "$test_file" ]]; then
          echo -e "${YELLOW}Running: $(basename "$test_file")${NC}"
          python3 "$test_file" 2>&1 | head -50
          echo ""
        fi
      done
      echo "Press Enter to continue..."
      read
      ;;
    8)
      echo ""
      echo -e "${CYAN}Testing enhanced search system...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_enhanced_search.py" ]]; then
        python3 "$tests_dir/test_enhanced_search.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_enhanced_search.py${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    9)
      echo ""
      echo -e "${CYAN}Testing persona helper...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_persona_helper.py" ]]; then
        python3 "$tests_dir/test_gtd_persona_helper.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_persona_helper.py${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    10)
      echo ""
      echo -e "${CYAN}Testing tool registry...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_tool_registry.py" ]]; then
        python3 "$tests_dir/test_gtd_tool_registry.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_tool_registry.py${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    11)
      echo ""
      echo -e "${CYAN}Testing LM Studio helper...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_lmstudio_helper.py" ]]; then
        python3 "$tests_dir/test_lmstudio_helper.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_lmstudio_helper.py${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    12)
      echo ""
      echo -e "${CYAN}Running complete test suite...${NC}"
      echo ""
      if [[ -f "$tests_dir/run_tests.sh" ]]; then
        bash "$tests_dir/run_tests.sh"
      else
        echo -e "${RED}Test runner not found: $tests_dir/run_tests.sh${NC}"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
  esac
}

# Show organization techniques guide
show_organization_guide() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${YELLOW}📚 Organization Techniques & Quick Guides${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}🎯 GTD (Getting Things Done):${NC}"
  echo "  • Capture → Process → Organize → Review → Do"
  echo "  • 5 Horizons: Runway → 10k → 20k → 30k → 40k"
  echo "  • 2-Minute Rule: Do it now if < 2 minutes"
  echo "  • Weekly Review: Critical for system health"
  echo ""
  echo -e "${BOLD}📁 PARA Method:${NC}"
  echo "  • Projects: Multi-step outcomes with deadlines"
  echo "  • Areas: Ongoing responsibilities to maintain"
  echo "  • Resources: Topics of ongoing interest"
  echo "  • Archives: Inactive items from other categories"
  echo ""
  echo -e "${BOLD}🧠 Second Brain (CODE):${NC}"
  echo "  • Capture: Keep what resonates"
  echo "  • Organize: Save by actionability (PARA)"
  echo "  • Distill: Progressive summarization (3 levels)"
  echo "  • Express: Create content from notes"
  echo ""
  echo -e "${BOLD}🔗 Zettelkasten:${NC}"
  echo "  • Atomic Notes: One idea per note"
  echo "  • Permanent Notes: Core insights"
  echo "  • Literature Notes: From external sources"
  echo "  • Link Everything: Build knowledge graph"
  echo ""
  echo -e "${BOLD}🗺️  Maps of Content (MOCs):${NC}"
  echo "  • Organize notes by topic/theme"
  echo "  • Dynamic indexes that evolve"
  echo "  • Create when you have 3+ related notes"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Show process reminders and frequencies
show_process_reminders() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${YELLOW}📋 Quick Reference: How Often to Visit Each Section${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}🔄 Daily (Multiple times):${NC}"
  echo -e "  ${GREEN}1)${NC} Capture to inbox - As needed (whenever something comes to mind)"
  echo -e "  ${GREEN}15)${NC} Log to daily log - Multiple times throughout the day"
  echo ""
  echo -e "${BOLD}📅 Daily (1-2 times):${NC}"
  echo -e "  ${GREEN}2)${NC} Process inbox - Morning & evening (keep it empty!)"
  echo -e "  ${GREEN}19)${NC} Morning/Evening Check-In - Start & end of day (5-10 min)"
  echo -e "  ${GREEN}6)${NC} Daily review - Morning or evening (5-10 min)"
  echo ""
  echo -e "${BOLD}⚡ Daily (As needed):${NC}"
  echo -e "  ${GREEN}3)${NC} Manage tasks - When selecting what to work on"
  echo -e "  ${GREEN}4)${NC} Manage projects - When working on active projects"
  echo -e "  ${GREEN}16)${NC} Search GTD system - When looking for something"
  echo -e "  ${GREEN}11)${NC} Get advice from personas - When stuck or need perspective"
  echo ""
  echo -e "${BOLD}📆 Weekly (Once):${NC}"
  echo -e "  ${GREEN}6)${NC} Weekly review - Sunday morning or Friday afternoon (1-2 hours) ⚠️  CRITICAL"
  echo -e "  ${GREEN}7)${NC} Sync with Second Brain - After weekly review"
  echo -e "  ${GREEN}25)${NC} Goal Tracking & Progress - Weekly goal check-in"
  echo ""
  echo -e "${BOLD}📅 Monthly (Once):${NC}"
  echo -e "  ${GREEN}6)${NC} Monthly review - Last/first weekend (2-3 hours)"
  echo -e "  ${GREEN}5)${NC} Review areas - Monthly area review"
  echo ""
  echo -e "${BOLD}🔄 Quarterly/Yearly:${NC}"
  echo -e "  ${GREEN}6)${NC} Quarterly review - Every 3 months (3-4 hours)"
  echo -e "  ${GREEN}6)${NC} Yearly review - Once per year (4-6 hours)"
  echo ""
  echo -e "${BOLD}💡 As Needed / Ongoing:${NC}"
  echo -e "  ${GREEN}17)${NC} System status - Check health periodically"
  echo -e "  ${GREEN}18)${NC} Manage habits - Track daily/weekly habits"
  echo -e "  ${GREEN}8)${NC} Manage MOCs - When organizing knowledge"
  echo -e "  ${GREEN}9)${NC} Express Phase - When creating from notes"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Dashboard - Show system status and quick stats
show_dashboard() {
  # Get current date/time
  local current_date=$(gtd_get_today)
  local current_time=$(gtd_get_current_time)
  local day_name=$(date +"%A" 2>/dev/null || echo "")
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 GTD Command Center${NC}"
  if [[ -n "$day_name" ]]; then
    echo -e "${CYAN}   ${day_name}, ${current_date} ${current_time}${NC}"
  else
    echo -e "${CYAN}   ${current_date} ${current_time}${NC}"
  fi
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # System Status Section
  echo -e "${BOLD}📊 System Status${NC}"
  echo ""
  
  # Inbox count
  local inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  if [[ $inbox_count -gt 0 ]]; then
    echo -e "  ${RED}📥 Inbox: ${inbox_count} item(s)${NC} ${YELLOW}→ Process first! (option 2)${NC}"
  else
    echo -e "  ${GREEN}✓ Inbox: Empty${NC}"
  fi
  
  # Active tasks count
  local tasks_count=0
  if [[ -d "${TASKS_PATH}" ]]; then
    tasks_count=$(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  echo -e "  ${CYAN}✅ Active Tasks: ${tasks_count}${NC}"
  
  # Active projects count
  local projects_count=0
  if [[ -d "${PROJECTS_PATH}" ]]; then
    projects_count=$(ls -1 "${PROJECTS_PATH}"/*/README.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  echo -e "  ${CYAN}📁 Active Projects: ${projects_count}${NC}"
  
  # Areas count
  local areas_count=0
  if [[ -d "${AREAS_PATH}" ]]; then
    areas_count=$(ls -1 "${AREAS_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  echo -e "  ${CYAN}🎯 Areas: ${areas_count}${NC}"
  
  echo ""
  
  # Quick Stats Section
  echo -e "${BOLD}📈 Quick Stats${NC}"
  echo ""
  
  # Logging streak
  local streak_script=""
  if command -v gtd-log-stats &>/dev/null; then
    streak_script="gtd-log-stats"
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/dotfiles/bin/gtd-log-stats"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/personal/dotfiles/bin/gtd-log-stats"
  fi
  
  if [[ -n "$streak_script" ]]; then
    local current_streak=$("$streak_script" streak 2>/dev/null || echo "0")
    current_streak=$(echo "$current_streak" | tr -d '[:space:]')
    if [[ ! "$current_streak" =~ ^[0-9]+$ ]]; then
      current_streak=0
    fi
    if [[ $current_streak -gt 0 ]]; then
      echo -e "  ${GREEN}🔥 Logging Streak: ${current_streak} day(s)${NC}"
    else
      echo -e "  ${YELLOW}📝 Logging Streak: Start logging!${NC}"
    fi
  fi
  
  # Today's log entries
  local today=$(gtd_get_today)
  local today_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  local today_entries=0
  if [[ -f "$today_log" ]]; then
    today_entries=$(grep -c "^[0-9][0-9]:[0-9][0-9] -" "$today_log" 2>/dev/null || echo "0")
  fi
  echo -e "  ${CYAN}📝 Today's Entries: ${today_entries}${NC}"
  
  # Waiting for items
  local waiting_count=0
  if [[ -d "${WAITING_PATH}" ]]; then
    waiting_count=$(ls -1 "${WAITING_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⏳ Waiting For: ${waiting_count} item(s)${NC}"
  fi
  
  # Someday/Maybe items
  local someday_count=0
  if [[ -d "${SOMEDAY_PATH}" ]]; then
    someday_count=$(ls -1 "${SOMEDAY_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [[ $someday_count -gt 0 ]]; then
    echo -e "  ${MAGENTA}💭 Someday/Maybe: ${someday_count} item(s)${NC}"
  fi
  
  echo ""
  
  # Smart Defaults Section
  show_smart_defaults
  
  # Quick Actions Section
  echo -e "${BOLD}⚡ Quick Actions${NC}"
  echo ""
  if [[ $inbox_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⚠️  ${BOLD}${inbox_count}${NC}${YELLOW} inbox item(s) need processing → Press ${BOLD}2${NC}${YELLOW}${NC}"
  fi
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⏳ ${waiting_count} item(s) waiting → Review with option 6 (Review)${NC}"
  fi
  echo -e "  ${CYAN}💡 Press ${BOLD}40${NC}${CYAN} for 'What should I do now?'${NC}"
  echo -e "  ${CYAN}📝 Press ${BOLD}15${NC}${CYAN} to log to daily log${NC}"
  echo -e "  ${CYAN}📊 Press ${BOLD}17${NC}${CYAN} for full system status${NC}"
  echo ""
  
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Show earned badges
show_earned_badges() {
  # Get GTD base directory - try multiple sources
  local gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
  if [[ -z "$GTD_BASE_DIR" ]]; then
    # Try loading from config
    local gtd_config="$HOME/.gtd_config"
    if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
      gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
    elif [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
      gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
    fi
    if [[ -f "$gtd_config" ]]; then
      source "$gtd_config" 2>/dev/null
      gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    fi
  fi
  
  local gamification_file="${gtd_base}/.gtd/gamification/gamification.json"
  
  # Check if gamification file exists
  if [[ ! -f "$gamification_file" ]]; then
    return 0
  fi
  
  # Use Python to parse and display badges with descriptions and status
  python3 2>/dev/null <<PYTHON_SCRIPT
import json
import sys
import os

try:
    gamification_file = "$gamification_file"
    if not os.path.exists(gamification_file):
        sys.exit(0)
    
    with open(gamification_file, "r") as f:
        data = json.load(f)
    
    badges = data.get("badges", {})
    badges_lost = data.get("badges_lost", [])
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    
    # Build current stats for maintenance checking (match badge definition format)
    current_stats = {
        "daily_logging_streak": streaks.get("daily_logging", 0),
        "task_streak": streaks.get("task_completion", 0),  # Note: badge defs use "task_streak"
        "exercise_streak": streaks.get("exercise", 0),
        "review_streak": streaks.get("review", 0),
        "tasks_completed": stats.get("tasks_completed", 0),
        "habits_completed": stats.get("habits_completed", 0),
        "projects_completed": stats.get("projects_completed", 0),
        "exercise_sessions": stats.get("exercise_sessions", 0),
        "reviews_completed": stats.get("reviews_completed", 0),
        "wizard_uses": stats.get("wizard_uses", 0),
    }
    
    # Helper function to check maintenance requirements (matches gtd-gamify logic)
    def check_maintenance_requirement(maint_req, current_stats):
        if not maint_req or not isinstance(maint_req, dict) or len(maint_req) == 0:
            return True, 100  # No requirement means always maintained
        
        # Check all requirements in the dict (typically just one)
        for key, required_value in maint_req.items():
            current_value = current_stats.get(key, 0)
            
            if required_value <= 0:
                continue  # Skip invalid requirements
            
            # For streaks and counts, check if current meets required
            if current_value < required_value:
                progress = (current_value / required_value * 100) if required_value > 0 else 100
                return False, progress
        
        # All requirements met
        return True, 100
    
    earned_badges = []
    at_risk_badges = []
    lost_badges_list = []
    
    # Process earned badges
    for badge_id, badge_info in badges.items():
        if isinstance(badge_info, dict):
            is_earned = badge_info.get("earned", False)
            is_lost = badge_id in badges_lost
            
            if is_lost:
                # Collect lost badges
                name = badge_info.get("name", badge_id)
                desc = badge_info.get("description", "No description")
                lost_badges_list.append((name, desc))
            elif is_earned:
                # Check earned badges for maintenance status
                name = badge_info.get("name", badge_id)
                desc = badge_info.get("description", "No description")
                maint_req = badge_info.get("maintenance_requirement", {})
                
                maint_met, progress = check_maintenance_requirement(maint_req, current_stats)
                
                if maint_met:
                    earned_badges.append((name, desc))
                else:
                    # Badge is at risk - maintenance requirement not met
                    at_risk_badges.append((name, desc, progress))
    
    # Display section if there are any badges to show
    if earned_badges or at_risk_badges or lost_badges_list:
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎖️  Your Badges")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        # Show summary warning if there are at-risk or lost badges
        if at_risk_badges or lost_badges_list:
            warning_count = len(at_risk_badges) + len(lost_badges_list)
            if at_risk_badges and lost_badges_list:
                print(f"  ⚠️  WARNING: You have {len(at_risk_badges)} badge(s) at risk and {len(lost_badges_list)} badge(s) lost!")
            elif at_risk_badges:
                print(f"  ⚠️  WARNING: You have {len(at_risk_badges)} badge(s) at risk!")
            elif lost_badges_list:
                print(f"  ⚠️  WARNING: You have {len(lost_badges_list)} badge(s) lost!")
            print("")
        
        # Show earned badges (maintained)
        if earned_badges:
            for name, desc in earned_badges:
                print(f"  🎖️  {name}")
                print(f"     {desc}")
                print("")
        
        # Show at-risk badges with warning
        if at_risk_badges:
            print("  ⚠️  BADGES AT RISK (Need action to maintain!)")
            print("  " + "-" * 64)
            print("")
            for name, desc, progress in at_risk_badges:
                progress_int = int(progress)
                print(f"  ⚠️  {name}")
                print(f"     {desc}")
                print(f"     Maintenance Progress: {progress_int}% - Take action soon!")
                print("")
        
        # Show lost badges with warning
        if lost_badges_list:
            print("  ❌ LOST BADGES (Build streak to regain!)")
            print("  " + "-" * 64)
            print("")
            for name, desc in lost_badges_list:
                print(f"  ❌ {name}")
                print(f"     {desc}")
                print("")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
except Exception:
    pass
PYTHON_SCRIPT
}

# Main menu display
show_main_menu() {
  # Show organization techniques guide (helper text at top)
  show_organization_guide
  
  # Show process reminders (helper text at top)
  show_process_reminders
  
  # Show earned badges
  show_earned_badges
  
  echo -e "${BOLD}What would you like to do?${NC}"
  echo ""
  
  echo -e "${BOLD}${CYAN}📥 INPUTS - Capture & Process:${NC}"
  echo -e "${GREEN}1)${NC} 📥 Capture something to inbox"
  echo -e "${GREEN}2)${NC} 📋 Process inbox items"
  echo -e "${GREEN}15)${NC} 📝 Log to daily log"
  echo -e "${GREEN}31)${NC} 👁️  View daily log"
  echo -e "${GREEN}19)${NC} 🌅 Morning/Evening Check-In"
  echo ""
  
  echo -e "${BOLD}${CYAN}🗂️  ORGANIZATION - Manage Your System:${NC}"
  echo -e "${GREEN}3)${NC} ✅ Manage tasks"
  echo -e "${GREEN}4)${NC} 📁 Manage projects"
  echo -e "${GREEN}5)${NC} 🎯 Manage areas of responsibility"
  echo -e "${GREEN}8)${NC} 🗺️  Manage MOCs (Maps of Content)"
  echo -e "${GREEN}23)${NC} 🔗 Zettelkasten (atomic notes)"
  echo -e "${GREEN}55)${NC} 🎯 Prioritization Review"
  echo ""
  echo -e "${BOLD}${CYAN}🧠 SECOND BRAIN - Advanced Operations:${NC}"
  echo -e "${GREEN}48)${NC} 🔗 Connect notes"
  echo -e "${GREEN}49)${NC} 📊 Converge/consolidate notes"
  echo -e "${GREEN}50)${NC} 🔍 Discover connections"
  echo -e "${GREEN}51)${NC} 📝 Distill (progressive summarization)"
  echo -e "${GREEN}52)${NC} 💡 Diverge (expand ideas)"
  echo -e "${GREEN}53)${NC} 🌲 Evergreen notes"
  echo -e "${GREEN}54)${NC} 📦 Note packets"
  echo ""
  
  echo -e "${BOLD}${CYAN}📤 OUTPUTS - Reviews & Creation:${NC}"
  echo -e "${GREEN}6)${NC} 📊 Review (daily/weekly/monthly)"
  echo -e "${GREEN}7)${NC} 🧠 Sync with Second Brain"
  echo -e "${GREEN}57)${NC} 🔄 Bidirectional Obsidian Sync"
  echo -e "${GREEN}59)${NC} 📊 Enhanced Review System"
  echo -e "${GREEN}9)${NC} ✍️  Express Phase (create content from notes)"
  echo -e "${GREEN}10)${NC} 📋 Use Templates"
  echo -e "${GREEN}22)${NC} 🎨 Create diagrams & mindmaps"
  echo ""
  
  echo -e "${BOLD}${CYAN}📚 LEARNING - Guides & Discovery:${NC}"
  echo -e "${GREEN}12)${NC} 📚 Learn Organization System (GTD + Second Brain + Zettelkasten)"
  echo -e "${GREEN}13)${NC} 🧠 Learn Second Brain (where to start)"
  echo -e "${GREEN}14)${NC} 🎯 Discover Life Vision (if you don't have a plan)"
  echo -e "${GREEN}20)${NC} ☸️  Learn Kubernetes/CKA"
  echo -e "${GREEN}21)${NC} 🇬🇷 Learn Greek (Language)"
  echo ""
  
  echo -e "${BOLD}${CYAN}🔍 ANALYSIS - Insights & Tracking:${NC}"
  echo -e "${GREEN}16)${NC} 🔍 Search GTD system"
  echo -e "${GREEN}17)${NC} 📊 System status"
  echo -e "${GREEN}25)${NC} 🎯 Goal Tracking & Progress"
  echo -e "${GREEN}26)${NC} ⚡ Energy Audit (drains & boosts)"
  echo -e "${GREEN}30)${NC} 💪 HealthKit & Health Data (disabled)"
  echo -e "${GREEN}34)${NC} 📈 Log statistics & streaks"
  echo -e "${GREEN}35)${NC} 🔗 Metric correlations"
  echo -e "${GREEN}36)${NC} 🔍 Pattern recognition"
  echo -e "${GREEN}37)${NC} 📊 Weekly progress report"
  echo -e "${GREEN}38)${NC} 🧠 Second Brain metrics"
  echo -e "${GREEN}56)${NC} 📊 Success metrics (usage & effectiveness)"
  echo -e "${GREEN}58)${NC} 📚 Learning System Preferences"
  echo ""
  
  echo -e "${BOLD}${CYAN}🛠️  TOOLS & SUPPORT:${NC}"
  echo -e "${GREEN}11)${NC} 🤖 Get advice from personas"
  echo -e "${GREEN}18)${NC} 🔁 Manage habits & recurring tasks"
  echo -e "${GREEN}24)${NC} 🤖 AI Suggestions & MCP Tools"
  echo -e "${GREEN}29)${NC} 📅 Calendar (view, sync tasks, check conflicts)"
  echo -e "${GREEN}39)${NC} ⚡ Energy-aware scheduling"
  echo -e "${GREEN}40)${NC} 🎯 What should I do now? (context-aware)"
  echo -e "${GREEN}41)${NC} 🔍 Find items (advanced search)"
  echo -e "${GREEN}42)${NC} 🎉 Celebrate milestones"
  echo ""
  
  echo -e "${BOLD}${CYAN}⚙️  SETTINGS:${NC}"
  echo -e "${GREEN}27)${NC} ⚙️  Configuration & Setup"
  echo -e "${GREEN}28)${NC} 🎮 Gamification & Habitica"
  echo -e "${GREEN}60)${NC} 💻 Switch Computer Mode (work/home)"
  echo -e "${GREEN}61)${NC} 🧪 Run Unit Tests"
  echo ""
  echo -e "${YELLOW}0)${NC} Exit"
  echo ""
  
  # Show dashboard (command center) at the bottom
  show_dashboard
  
  echo -n "Choose: "
}

# Main function - entry point for the wizard
main() {
  # Award XP for opening wizard (first time in this session)
  award_wizard_xp "wizard_use" "Opened GTD wizard"
  
  # Track daily usage
  if command -v gtd-success-metrics &>/dev/null; then
    gtd-success-metrics track "gtd-wizard" 2>/dev/null || true
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-success-metrics" ]]; then
    "$HOME/code/dotfiles/bin/gtd-success-metrics" track "gtd-wizard" 2>/dev/null || true
  fi
  
  while true; do
    show_main_menu
    read choice
    
    # Track wizard option usage for preferences learning
    if [[ "$choice" =~ ^[0-9]+$ ]] && command -v gtd-preferences-learn &>/dev/null; then
      gtd-preferences-learn track-feature "wizard_option" "$choice" 2>/dev/null || true
    fi
    
    case "$choice" in
      1)
        award_wizard_xp "wizard_productive" "Used wizard: Capture"
        capture_wizard
        ;;
      2)
        award_wizard_xp "wizard_productive" "Used wizard: Process inbox"
        process_wizard
        ;;
      3)
        award_wizard_xp "wizard_productive" "Used wizard: Manage tasks"
        task_wizard
        ;;
      4)
        award_wizard_xp "wizard_productive" "Used wizard: Manage projects"
        project_wizard
        ;;
      5)
        award_wizard_xp "wizard_action" "Used wizard: Manage areas"
        area_wizard
        ;;
      6)
        award_wizard_xp "wizard_productive" "Used wizard: Review"
        review_wizard
        ;;
      7)
        award_wizard_xp "wizard_productive" "Used wizard: Sync Second Brain"
        sync_wizard
        ;;
      57)
        award_wizard_xp "wizard_action" "Used wizard: Bidirectional Obsidian Sync"
        bidirectional_sync_wizard
        ;;
      59)
        award_wizard_xp "wizard_action" "Used wizard: Enhanced Review System"
        enhanced_review_wizard
        ;;
      8)
        award_wizard_xp "wizard_productive" "Used wizard: Manage MOCs"
        moc_wizard
        ;;
      9)
        award_wizard_xp "wizard_productive" "Used wizard: Express Phase"
        express_wizard
        ;;
      10)
        award_wizard_xp "wizard_productive" "Used wizard: Templates"
        template_wizard
        ;;
      11)
        award_wizard_xp "wizard_action" "Used wizard: Get advice"
        advice_wizard
        ;;
      12)
        award_wizard_xp "wizard_action" "Used wizard: Learn Organization System"
        tips_wizard
        ;;
      13)
        award_wizard_xp "wizard_action" "Used wizard: Learn Second Brain"
        learn_second_brain_wizard
        ;;
      14)
        award_wizard_xp "wizard_action" "Used wizard: Life Vision"
        life_vision_wizard
        ;;
      15)
        award_wizard_xp "wizard_productive" "Used wizard: Daily Log"
        log_wizard
        ;;
      16)
        award_wizard_xp "wizard_action" "Used wizard: Search"
        search_wizard
        ;;
      17)
        award_wizard_xp "wizard_action" "Used wizard: System Status"
        status_wizard
        ;;
      18)
        award_wizard_xp "wizard_productive" "Used wizard: Habits"
        habit_wizard
        ;;
      19)
        award_wizard_xp "wizard_productive" "Used wizard: Check-In"
        checkin_wizard
        ;;
      31)
        award_wizard_xp "wizard_productive" "Used wizard: View Daily Log"
        clear
        echo ""
        if command -v gtd-log &>/dev/null; then
          gtd-log today
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-log" today
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-log" today
        else
          echo "❌ gtd-log command not found"
          echo "Press Enter to continue..."
          read
          continue
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      20)
        award_wizard_xp "wizard_action" "Used wizard: Learn Kubernetes"
        k8s_wizard
        ;;
      21)
        award_wizard_xp "wizard_action" "Used wizard: Learn Greek"
        greek_wizard
        ;;
      22)
        award_wizard_xp "wizard_productive" "Used wizard: Diagrams"
        diagram_wizard
        ;;
      23)
        award_wizard_xp "wizard_productive" "Used wizard: Zettelkasten"
        zettelkasten_wizard
        ;;
      24)
        award_wizard_xp "wizard_action" "Used wizard: AI Suggestions"
        ai_suggestions_wizard
        ;;
      25)
        award_wizard_xp "wizard_action" "Used wizard: Goal Tracking"
        goal_tracking_wizard
        ;;
      26)
        award_wizard_xp "wizard_action" "Used wizard: Energy Audit"
        energy_audit_wizard
        ;;
      27)
        award_wizard_xp "wizard_action" "Used wizard: Configuration"
        config_wizard
        ;;
      28)
        award_wizard_xp "wizard_action" "Used wizard: Gamification"
        gamification_wizard
        ;;
      29)
        award_wizard_xp "wizard_action" "Used wizard: Calendar"
        calendar_wizard
        ;;
      30)
        award_wizard_xp "wizard_action" "Used wizard: HealthKit"
        healthkit_wizard
        ;;
      31)
        award_wizard_xp "wizard_productive" "Used wizard: Morning Routine"
        morning_routine_wizard
        ;;
      32)
        award_wizard_xp "wizard_productive" "Used wizard: Afternoon Routine"
        afternoon_routine_wizard
        ;;
      33)
        award_wizard_xp "wizard_productive" "Used wizard: Evening Routine"
        evening_routine_wizard
        ;;
      34)
        award_wizard_xp "wizard_action" "Used wizard: Log Stats"
        log_stats_wizard
        ;;
      35)
        award_wizard_xp "wizard_action" "Used wizard: Metric Correlations"
        metric_correlations_wizard
        ;;
      36)
        award_wizard_xp "wizard_action" "Used wizard: Pattern Recognition"
        pattern_recognition_wizard
        ;;
      37)
        award_wizard_xp "wizard_action" "Used wizard: Weekly Progress"
        weekly_progress_wizard
        ;;
      38)
        award_wizard_xp "wizard_action" "Used wizard: Brain Metrics"
        brain_metrics_wizard
        ;;
      39)
        award_wizard_xp "wizard_action" "Used wizard: Energy Schedule"
        energy_schedule_wizard
        ;;
      40)
        award_wizard_xp "wizard_action" "Used wizard: What Should I Do Now"
        now_wizard
        ;;
      41)
        award_wizard_xp "wizard_action" "Used wizard: Find Items"
        find_wizard
        ;;
      42)
        award_wizard_xp "wizard_action" "Used wizard: Milestone Celebration"
        milestone_wizard
        ;;
      43)
        award_wizard_xp "wizard_productive" "Used wizard: Evening Summary"
        evening_summary_wizard
        ;;
      44)
        award_wizard_xp "wizard_action" "Used wizard: Deployment"
        deployment_wizard
        ;;
      45)
        award_wizard_xp "wizard_productive" "Used wizard: Collect All"
        collect_all_wizard
        ;;
      46)
        award_wizard_xp "wizard_productive" "Used wizard: Quick Complete Habits"
        quick_complete_habits
        ;;
      47)
        award_wizard_xp "wizard_productive" "Used wizard: Mood Log"
        mood_log_wizard
        ;;
      48)
        award_wizard_xp "wizard_productive" "Used wizard: Connect Notes"
        brain_connect_wizard
        ;;
      49)
        award_wizard_xp "wizard_productive" "Used wizard: Converge Notes"
        brain_converge_wizard
        ;;
      50)
        award_wizard_xp "wizard_productive" "Used wizard: Discover Notes"
        brain_discover_wizard
        ;;
      51)
        award_wizard_xp "wizard_productive" "Used wizard: Distill Notes"
        brain_distill_wizard
        ;;
      52)
        award_wizard_xp "wizard_productive" "Used wizard: Diverge Notes"
        brain_diverge_wizard
        ;;
      53)
        award_wizard_xp "wizard_productive" "Used wizard: Evergreen Notes"
        brain_evergreen_wizard
        ;;
      54)
        award_wizard_xp "wizard_productive" "Used wizard: Note Packets"
        brain_packet_wizard
        ;;
      55)
        award_wizard_xp "wizard_action" "Used wizard: Prioritization Review"
        prioritization_wizard
        ;;
      56)
        award_wizard_xp "wizard_action" "Used wizard: Success Metrics"
        success_metrics_wizard
        ;;
      58)
        award_wizard_xp "wizard_action" "Used wizard: Learning System Preferences"
        preferences_learning_wizard
        ;;
      60)
        award_wizard_xp "wizard_action" "Used wizard: Switch Computer Mode"
        computer_mode_wizard
        ;;
      61)
        award_wizard_xp "wizard_action" "Used wizard: Run Unit Tests"
        test_execution_wizard
        ;;
      0|"")
        clear
        echo "Goodbye! Use 'gtd-wizard' anytime you need help organizing."
        exit 0
        ;;
      *)
        echo "Invalid choice. Press Enter..."
        read
        ;;
    esac
  done
}
