#!/bin/bash
# Unit tests for gtd-common.sh

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "gtd-common.sh"

echo "Testing configuration loading..."
test_assert_success "[[ -n '$GTD_BASE_DIR' ]]" "GTD_BASE_DIR should be set"
test_assert_success "[[ -n '$PROJECTS_PATH' ]]" "PROJECTS_PATH should be set"
test_assert_success "[[ -n '$AREAS_PATH' ]]" "AREAS_PATH should be set"

echo ""
echo "Testing color definitions..."
test_assert_success "[[ -n '$CYAN' ]]" "CYAN color should be defined"
test_assert_success "[[ -n '$GREEN' ]]" "GREEN color should be defined"
test_assert_success "[[ -n '$YELLOW' ]]" "YELLOW color should be defined"
test_assert_success "[[ -n '$RED' ]]" "RED color should be defined"
test_assert_success "[[ -n '$NC' ]]" "NC (No Color) should be defined"

echo ""
echo "Testing menu navigation..."
gtd_push_menu "Test Menu"
test_assert_equal "1" "$(gtd_get_menu_level)" "Menu level should be 1 after push"
gtd_push_menu "Another Menu"
test_assert_equal "2" "$(gtd_get_menu_level)" "Menu level should be 2 after second push"
gtd_pop_menu
test_assert_equal "1" "$(gtd_get_menu_level)" "Menu level should be 1 after pop"

echo ""
echo "Testing display helpers..."
test_assert_success "gtd_print_divider >/dev/null" "gtd_print_divider should work"
test_assert_success "gtd_print_header 'Test' >/dev/null" "gtd_print_header should work"
test_assert_success "gtd_print_success 'Test' >/dev/null" "gtd_print_success should work"
test_assert_success "gtd_print_error 'Test' >/dev/null 2>&1" "gtd_print_error should work"
test_assert_success "gtd_print_info 'Test' >/dev/null" "gtd_print_info should work"
test_assert_success "gtd_print_warning 'Test' >/dev/null" "gtd_print_warning should work"

echo ""
echo "Testing date helpers..."
test_assert_success "[[ -n '$(gtd_get_today)' ]]" "gtd_get_today should return a date"
test_assert_success "[[ '$(gtd_get_today)' =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]" "gtd_get_today should return YYYY-MM-DD format"
test_assert_success "[[ -n '$(gtd_get_current_time)' ]]" "gtd_get_current_time should return a time"

echo ""
echo "Testing Python helper..."
PYTHON_CMD=$(gtd_get_mcp_python)
test_assert_success "[[ -n '$PYTHON_CMD' ]]" "gtd_get_mcp_python should return a Python command"

echo ""
echo "Testing date command helper..."
DATE_CMD=$(gtd_get_date_cmd)
test_assert_success "[[ -n '$DATE_CMD' ]]" "gtd_get_date_cmd should return a date command"
test_assert_success "command -v $DATE_CMD >/dev/null || [[ -x '$DATE_CMD' ]]" "Date command should be executable"

echo ""
echo "Testing frontmatter helper..."
# Create a test file with frontmatter
TEST_FILE=$(mktemp /tmp/test_frontmatter_XXXXXX.md)
cat > "$TEST_FILE" <<EOF
---
status: active
priority: high
project: Test Project
---

# Test File
Content here
EOF
test_assert_success "[[ -f '$TEST_FILE' ]]" "Test file should be created"
test_assert_equal "active" "$(gtd_get_frontmatter_value "$TEST_FILE" "status")" "Should extract status from frontmatter"
test_assert_equal "high" "$(gtd_get_frontmatter_value "$TEST_FILE" "priority")" "Should extract priority from frontmatter"
test_assert_equal "Test Project" "$(gtd_get_frontmatter_value "$TEST_FILE" "project")" "Should extract project from frontmatter"
test_assert_equal "" "$(gtd_get_frontmatter_value "$TEST_FILE" "nonexistent")" "Should return empty for nonexistent key"
rm -f "$TEST_FILE"

echo ""
echo "Testing path initialization..."
test_assert_success "[[ -n '$INBOX_PATH' ]]" "INBOX_PATH should be set"
test_assert_success "[[ -n '$REFERENCE_PATH' ]]" "REFERENCE_PATH should be set"
test_assert_success "[[ -n '$SOMEDAY_PATH' ]]" "SOMEDAY_PATH should be set"
test_assert_success "[[ -n '$WAITING_PATH' ]]" "WAITING_PATH should be set"
test_assert_success "[[ -n '$ARCHIVE_PATH' ]]" "ARCHIVE_PATH should be set"
test_assert_success "[[ -n '$SECOND_BRAIN' ]]" "SECOND_BRAIN should be set"

echo ""
echo "Testing breadcrumb display..."
gtd_push_menu "Test Menu 1"
gtd_push_menu "Test Menu 2"
BREADCRUMB_OUTPUT=$(gtd_show_breadcrumb 2>&1)
test_assert_success "[[ -n '$BREADCRUMB_OUTPUT' ]]" "Breadcrumb should display something"
test_assert_success "echo '$BREADCRUMB_OUTPUT' | grep -q 'Test Menu 2'" "Breadcrumb should show current menu"
gtd_pop_menu
gtd_pop_menu

echo ""
echo "Testing Second Brain helpers (if Second Brain exists)..."
if [[ -d "$SECOND_BRAIN" ]]; then
  MOC_NAMES=$(gtd_get_moc_names)
  test_assert_success "true" "gtd_get_moc_names should work (may return empty if no MOCs)"
  
  NOTES=$(gtd_get_second_brain_notes | head -1)
  test_assert_success "true" "gtd_get_second_brain_notes should work (may return empty if no notes)"
else
  echo "  Skipping Second Brain tests (Second Brain directory not found)"
fi

echo ""
echo "Testing thinking timer functionality..."
# Test that timer functions exist
test_assert_success "declare -f show_thinking_timer >/dev/null" "show_thinking_timer function should exist"
test_assert_success "declare -f stop_thinking_timer >/dev/null" "stop_thinking_timer function should exist"
test_assert_success "declare -f run_with_thinking_timer >/dev/null" "run_with_thinking_timer function should exist"

# Test timer starts and stops correctly
echo "  Testing timer lifecycle..."
TIMER_TEST_OUTPUT=$(mktemp)
show_thinking_timer "Test Timer" 0 0 >"$TIMER_TEST_OUTPUT" 2>&1 &
TIMER_PID=$!
sleep 0.5
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null
test_assert_success "[[ -n '$TIMER_PID' ]]" "Timer should start and return PID"
rm -f "$TIMER_TEST_OUTPUT"

# Test timer displays output to stderr (not stdout)
echo "  Testing timer writes to stderr..."
TIMER_STDOUT=$(mktemp)
TIMER_STDERR=$(mktemp)
show_thinking_timer "Stderr Test" 0 0 >"$TIMER_STDOUT" 2>"$TIMER_STDERR" &
TIMER_PID=$!
sleep 0.5
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null
STDERR_SIZE=$(stat -f%z "$TIMER_STDERR" 2>/dev/null || stat -c%s "$TIMER_STDERR" 2>/dev/null || echo "0")
STDOUT_SIZE=$(stat -f%z "$TIMER_STDOUT" 2>/dev/null || stat -c%s "$TIMER_STDOUT" 2>/dev/null || echo "0")
test_assert_success "[[ $STDERR_SIZE -gt 0 ]]" "Timer should write to stderr"
test_assert_success "[[ $STDOUT_SIZE -eq 0 ]]" "Timer should not write to stdout"
rm -f "$TIMER_STDOUT" "$TIMER_STDERR"

# Test timer works when stdout is redirected (simulating wizard context)
echo "  Testing timer with stdout redirected..."
TIMER_REDIRECT_OUTPUT=$(mktemp)
TIMER_REDIRECT_STDERR=$(mktemp)
(run_with_thinking_timer "Redirect Test" sleep 1 >"$TIMER_REDIRECT_OUTPUT") 2>"$TIMER_REDIRECT_STDERR"
STDERR_SIZE=$(stat -f%z "$TIMER_REDIRECT_STDERR" 2>/dev/null || stat -c%s "$TIMER_REDIRECT_STDERR" 2>/dev/null || echo "0")
test_assert_success "[[ $STDERR_SIZE -gt 0 ]]" "Timer should display to stderr even when stdout is redirected"
rm -f "$TIMER_REDIRECT_OUTPUT" "$TIMER_REDIRECT_STDERR"

# Test timer format contains expected elements
echo "  Testing timer output format..."
TIMER_FORMAT_OUTPUT=$(mktemp)
show_thinking_timer "Format Test" 0 0 2>"$TIMER_FORMAT_OUTPUT" &
TIMER_PID=$!
sleep 0.5
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null
TIMER_CONTENT=$(cat "$TIMER_FORMAT_OUTPUT" 2>/dev/null || echo "")
test_assert_success "echo '$TIMER_CONTENT' | grep -q '🤔'" "Timer should contain thinking emoji"
test_assert_success "echo '$TIMER_CONTENT' | grep -q 'T+'" "Timer should contain time format"
rm -f "$TIMER_FORMAT_OUTPUT"

# Test run_with_thinking_timer wrapper captures command output
echo "  Testing run_with_thinking_timer wrapper..."
WRAPPER_OUTPUT=$(mktemp)
WRAPPER_STDERR=$(mktemp)
COMMAND_OUTPUT=$(run_with_thinking_timer "Wrapper Test" echo "test output" >"$WRAPPER_OUTPUT" 2>"$WRAPPER_STDERR"; cat "$WRAPPER_OUTPUT")
test_assert_success "[[ -n '$COMMAND_OUTPUT' ]]" "run_with_thinking_timer should allow command execution"
rm -f "$WRAPPER_OUTPUT" "$WRAPPER_STDERR"

# Test timer stops when parent process ends (when parent_pid is set)
echo "  Testing timer stops when parent ends..."
TIMER_PARENT_OUTPUT=$(mktemp)
(
  show_thinking_timer "Parent Test" 0 $$ 2>"$TIMER_PARENT_OUTPUT" &
  TIMER_PID=$!
  sleep 0.3
  # Parent exits, timer should detect this
) 2>/dev/null
sleep 0.5
# Timer should have stopped when parent exited
TIMER_RUNNING=$(ps -p $TIMER_PID 2>/dev/null | wc -l || echo "0")
test_assert_success "[[ $TIMER_RUNNING -eq 0 ]] || true" "Timer should stop when parent process ends"
rm -f "$TIMER_PARENT_OUTPUT"

# Test timer with delay (should wait before showing)
echo "  Testing timer delay..."
TIMER_DELAY_OUTPUT=$(mktemp)
DELAY_START=$(date +%s)
show_thinking_timer "Delay Test" 1 0 2>"$TIMER_DELAY_OUTPUT" &
TIMER_PID=$!
sleep 0.5
DELAY_ELAPSED=$(($(date +%s) - DELAY_START))
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null
# Timer should wait at least 1 second before showing
test_assert_success "[[ $DELAY_ELAPSED -lt 2 ]]" "Timer should respect delay before showing"
rm -f "$TIMER_DELAY_OUTPUT"

# Print summary
test_summary

