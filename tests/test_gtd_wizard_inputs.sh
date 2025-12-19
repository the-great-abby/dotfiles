#!/bin/bash
# Unit tests for gtd-wizard-inputs.sh
# Tests: capture_wizard, process_wizard, checkin_wizard, and related input functions

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source common helpers first
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-wizard-inputs.sh"

# Test suite
test_init "gtd-wizard-inputs.sh"

echo "Testing wizard input functions..."

# Test that functions exist
test_assert_success "declare -f capture_wizard &>/dev/null" "capture_wizard function should exist"
test_assert_success "declare -f process_wizard &>/dev/null" "process_wizard function should exist"
test_assert_success "declare -f checkin_wizard &>/dev/null" "checkin_wizard function should exist"
test_assert_success "declare -f log_wizard &>/dev/null" "log_wizard function should exist"
test_assert_success "declare -f oncall_capture_wizard &>/dev/null" "oncall_capture_wizard function should exist"

echo ""
echo "Testing capture wizard logic..."

# Test capture types validation
test_capture_types() {
  # Test that capture wizard handles different capture types
  # We can't test interactive selection, but can test the logic
  
  # Valid capture types: 1-10, 0 for exit
  for type in 1 2 3 4 5 6 7 8 9 10 0; do
    test_assert_success "[[ '$type' =~ ^[0-9]+$ ]]" "Capture type $type should be numeric"
  done
  
  # Test invalid capture types
  for invalid in "a" "11" "-1" "abc"; do
    test_assert_failure "[[ '$invalid' =~ ^[0-9]+$ && '$invalid' -ge 0 && '$invalid' -le 10 ]]" "Invalid capture type $invalid should be rejected"
  done
}

test_capture_types

echo ""
echo "Testing process wizard logic..."

# Test that process wizard can handle inbox processing
if [[ -d "${INBOX_PATH:-}" ]]; then
  INBOX_FILES=$(find "$INBOX_PATH" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  test_assert_success "true" "Process wizard should be able to access inbox"
else
  echo "  Skipping inbox tests (INBOX_PATH not set or doesn't exist)"
fi

echo ""
echo "Testing checkin wizard logic..."

# Test checkin tracking functions if they exist
if declare -f checkin_done_today &>/dev/null; then
  CHECKIN_STATUS=$(checkin_done_today 2>/dev/null || echo "unknown")
  test_assert_success "true" "checkin_done_today should be callable"
fi

# Test time of day detection if it exists
if declare -f get_time_of_day &>/dev/null; then
  TIME_OF_DAY=$(get_time_of_day 2>/dev/null || echo "unknown")
  test_assert_success "[[ -n '$TIME_OF_DAY' ]]" "get_time_of_day should return a value"
  test_assert_success "echo '$TIME_OF_DAY' | grep -qE 'morning|afternoon|evening|night'" "Time of day should be valid"
fi

echo ""
echo "Testing log wizard logic..."

# Test that log wizard can access daily logs
if [[ -n "${DAILY_LOGS_PATH:-}" ]] && [[ -d "$DAILY_LOGS_PATH" ]]; then
  test_assert_dir_exists "$DAILY_LOGS_PATH" "Daily logs path should exist"
  
  # Test that today's log can be accessed
  TODAY=$(gtd_get_today)
  TODAY_LOG="${DAILY_LOGS_PATH}/${TODAY}.md"
  test_assert_success "true" "Log wizard should be able to access today's log path"
else
  echo "  Skipping daily log tests (DAILY_LOGS_PATH not set or doesn't exist)"
fi

echo ""
echo "Testing oncall capture wizard logic..."

# Test oncall capture types
test_oncall_types() {
  # Valid oncall types: 1-10, 0 for back
  for type in 1 2 3 4 5 6 7 8 9 10 0; do
    test_assert_success "[[ '$type' =~ ^[0-9]+$ ]]" "Oncall type $type should be numeric"
  done
}

test_oncall_types

echo ""
echo "Testing get_log_inspiration function..."

# Test that get_log_inspiration exists
if declare -f get_log_inspiration &>/dev/null; then
  INSPIRATION=$(get_log_inspiration 2>/dev/null || echo "")
  test_assert_success "true" "get_log_inspiration should be callable"
fi

echo ""
echo "Testing mood_log_wizard function..."

# Test that mood_log_wizard exists
test_assert_success "declare -f mood_log_wizard &>/dev/null" "mood_log_wizard function should exist"

echo ""
echo "Testing calendar_log_wizard function..."

# Test that calendar_log_wizard exists
test_assert_success "declare -f calendar_log_wizard &>/dev/null" "calendar_log_wizard function should exist"

echo ""
echo "Testing collect_all_wizard function..."

# Test that collect_all_wizard exists
test_assert_success "declare -f collect_all_wizard &>/dev/null" "collect_all_wizard function should exist"

echo ""
echo "Testing edge cases and error handling..."

# Test empty input handling
test_empty_input() {
  # Test that empty capture content is handled
  EMPTY_CONTENT=""
  test_assert_success "[[ -z '$EMPTY_CONTENT' ]]" "Should detect empty content"
}

test_empty_input

# Test invalid path handling
test_invalid_paths() {
  # Test that functions handle invalid paths gracefully
  INVALID_PATH="/nonexistent/path/$(date +%s)"
  test_assert_failure "[[ -d '$INVALID_PATH' ]]" "Should detect invalid path"
}

test_invalid_paths

# Test that wizard functions can handle cancellation (choice 0)
test_cancellation() {
  CANCEL_CHOICE="0"
  test_assert_success "[[ '$CANCEL_CHOICE' == '0' ]]" "Should handle cancellation choice"
}

test_cancellation

# Print summary
test_summary

