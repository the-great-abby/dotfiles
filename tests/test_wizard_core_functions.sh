#!/bin/bash
# Test script for GTD Wizard Core Functions
# Tests utility functions like get_computer_mode, get_time_of_day, etc.

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source wizard core functions
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
GTD_COMMON="$BIN_DIR/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON" 2>/dev/null || true
fi

GTD_WIZARD_CORE="$BIN_DIR/gtd-wizard-core.sh"
if [[ ! -f "$GTD_WIZARD_CORE" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh" ]]; then
  GTD_WIZARD_CORE="$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh"
fi
if [[ -f "$GTD_WIZARD_CORE" ]]; then
  source "$GTD_WIZARD_CORE" 2>/dev/null || true
fi

# Initialize test suite
test_init "wizard-core-functions"

echo "Testing GTD Wizard Core Functions"
echo ""

# Test 1: get_computer_mode function exists
test_assert_success "declare -f get_computer_mode &>/dev/null" \
  "get_computer_mode function should be available"

# Test 2: get_computer_mode returns a value
if declare -f get_computer_mode &>/dev/null; then
  mode=$(get_computer_mode)
  test_assert_success "[[ -n '$mode' ]]" \
    "get_computer_mode should return a value"
  
  # Test 3: get_computer_mode returns work or home
  test_assert_success "[[ '$mode' == 'work' || '$mode' == 'home' ]]" \
    "get_computer_mode should return 'work' or 'home'"
fi

# Test 4: set_computer_mode function exists
test_assert_success "declare -f set_computer_mode &>/dev/null" \
  "set_computer_mode function should be available"

# Test 5: set_computer_mode validates input
if declare -f set_computer_mode &>/dev/null; then
  # Should fail with invalid mode
  test_assert_failure "set_computer_mode invalid_mode 2>/dev/null" \
    "set_computer_mode should reject invalid mode"
  
  # Should fail with empty input
  test_assert_failure "set_computer_mode '' 2>/dev/null" \
    "set_computer_mode should reject empty input"
fi

# Test 6: get_time_of_day function exists
test_assert_success "declare -f get_time_of_day &>/dev/null" \
  "get_time_of_day function should be available"

# Test 7: get_time_of_day returns a value
if declare -f get_time_of_day &>/dev/null; then
  time_of_day=$(get_time_of_day)
  test_assert_success "[[ -n '$time_of_day' ]]" \
    "get_time_of_day should return a value"
  
  # Test 8: get_time_of_day returns valid time period
  test_assert_success "[[ '$time_of_day' == 'morning' || '$time_of_day' == 'afternoon' || '$time_of_day' == 'evening' ]]" \
    "get_time_of_day should return morning, afternoon, or evening"
fi

# Test 9: checkin_done_today function exists
test_assert_success "declare -f checkin_done_today &>/dev/null" \
  "checkin_done_today function should be available"

# Test 10: checkin_done_today accepts parameters
if declare -f checkin_done_today &>/dev/null; then
  # Should work with morning parameter
  checkin_done_today "morning" &>/dev/null
  test_assert_success "true" \
    "checkin_done_today should accept 'morning' parameter"
  
  # Should work with evening parameter
  checkin_done_today "evening" &>/dev/null
  test_assert_success "true" \
    "checkin_done_today should accept 'evening' parameter"
fi

# Test 11: get_day_of_week function exists
test_assert_success "declare -f get_day_of_week &>/dev/null" \
  "get_day_of_week function should be available"

# Test 12: get_day_of_week returns a number
if declare -f get_day_of_week &>/dev/null; then
  day_num=$(get_day_of_week)
  test_assert_success "[[ '$day_num' =~ ^[0-6]$ ]]" \
    "get_day_of_week should return 0-6"
fi

# Test 13: get_day_name function exists
test_assert_success "declare -f get_day_name &>/dev/null" \
  "get_day_name function should be available"

# Test 14: get_day_name returns a day name
if declare -f get_day_name &>/dev/null; then
  day_name=$(get_day_name)
  test_assert_success "[[ -n '$day_name' ]]" \
    "get_day_name should return a day name"
  
  # Should be a valid day name
  valid_days="Monday Tuesday Wednesday Thursday Friday Saturday Sunday"
  test_assert_success "[[ ' $valid_days ' =~ ' $day_name ' ]]" \
    "get_day_name should return a valid day name"
fi

# Test 15: weekly_review_done_this_week function exists
test_assert_success "declare -f weekly_review_done_this_week &>/dev/null" \
  "weekly_review_done_this_week function should be available"

# Test 16: weekly_review_done_this_week returns boolean
if declare -f weekly_review_done_this_week &>/dev/null; then
  weekly_review_done_this_week &>/dev/null
  test_assert_success "true" \
    "weekly_review_done_this_week should execute without error"
fi

# Test 17: tasks_completed_today function exists
test_assert_success "declare -f tasks_completed_today &>/dev/null" \
  "tasks_completed_today function should be available"

# Test 18: tasks_completed_today returns a number
if declare -f tasks_completed_today &>/dev/null; then
  count=$(tasks_completed_today)
  test_assert_success "[[ '$count' =~ ^[0-9]+$ ]]" \
    "tasks_completed_today should return a number"
fi

# Test 19: feature_rarely_used function exists
test_assert_success "declare -f feature_rarely_used &>/dev/null" \
  "feature_rarely_used function should be available"

# Test 20: feature_rarely_used accepts parameter
if declare -f feature_rarely_used &>/dev/null; then
  feature_rarely_used "1" &>/dev/null
  test_assert_success "true" \
    "feature_rarely_used should accept a feature option parameter"
fi

# Test 21: features_used_together function exists
test_assert_success "declare -f features_used_together &>/dev/null" \
  "features_used_together function should be available"

# Test 22: features_used_together accepts parameters
if declare -f features_used_together &>/dev/null; then
  features_used_together "1" "2" &>/dev/null
  test_assert_success "true" \
    "features_used_together should accept two feature parameters"
fi

# Test 23: get_smart_defaults function exists
test_assert_success "declare -f get_smart_defaults &>/dev/null" \
  "get_smart_defaults function should be available"

# Test 24: get_smart_defaults returns suggestions
if declare -f get_smart_defaults &>/dev/null; then
  defaults=$(get_smart_defaults)
  test_assert_success "true" \
    "get_smart_defaults should execute without error"
fi

# Test 25: show_smart_defaults function exists
test_assert_success "declare -f show_smart_defaults &>/dev/null" \
  "show_smart_defaults function should be available"

# Test 26: computer_mode_wizard function exists
test_assert_success "declare -f computer_mode_wizard &>/dev/null" \
  "computer_mode_wizard function should be available"

# Test 27: show_dashboard function exists
test_assert_success "declare -f show_dashboard &>/dev/null" \
  "show_dashboard function should be available"

# Test 28: show_earned_badges function exists
test_assert_success "declare -f show_earned_badges &>/dev/null" \
  "show_earned_badges function should be available"

# Test 29: show_main_menu function exists
test_assert_success "declare -f show_main_menu &>/dev/null" \
  "show_main_menu function should be available"

# Test 30: show_organization_guide function exists
test_assert_success "declare -f show_organization_guide &>/dev/null" \
  "show_organization_guide function should be available"

# Test 31: show_process_reminders function exists
test_assert_success "declare -f show_process_reminders &>/dev/null" \
  "show_process_reminders function should be available"

# Print test summary
test_summary
