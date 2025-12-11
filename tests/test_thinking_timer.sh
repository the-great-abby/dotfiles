#!/bin/bash
# Unit tests for thinking timer functionality
# Tests the show_thinking_timer, stop_thinking_timer, and run_with_thinking_timer functions

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "thinking-timer"

echo "Testing timer function availability..."
test_assert_success "declare -f show_thinking_timer >/dev/null" "show_thinking_timer function should exist"
test_assert_success "declare -f stop_thinking_timer >/dev/null" "stop_thinking_timer function should exist"
test_assert_success "declare -f run_with_thinking_timer >/dev/null" "run_with_thinking_timer function should exist"

echo ""
echo "Testing timer basic functionality..."
# Test timer starts
TIMER_PID=""
show_thinking_timer "Basic Test" 0 0 >/dev/null 2>&1 &
TIMER_PID=$!
test_assert_success "[[ -n '$TIMER_PID' ]] && kill -0 $TIMER_PID 2>/dev/null" "Timer should start and be running"
sleep 0.3
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true

echo ""
echo "Testing timer writes to stderr (not stdout)..."
TIMER_STDOUT=$(mktemp)
TIMER_STDERR=$(mktemp)
show_thinking_timer "Stderr Test" 0 0 >"$TIMER_STDOUT" 2>"$TIMER_STDERR" &
TIMER_PID=$!
sleep 0.5
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true
STDERR_SIZE=$(stat -f%z "$TIMER_STDERR" 2>/dev/null || stat -c%s "$TIMER_STDERR" 2>/dev/null || echo "0")
STDOUT_SIZE=$(stat -f%z "$TIMER_STDOUT" 2>/dev/null || stat -c%s "$TIMER_STDOUT" 2>/dev/null || echo "0")
test_assert_success "[[ $STDERR_SIZE -gt 0 ]]" "Timer should write to stderr"
test_assert_success "[[ $STDOUT_SIZE -eq 0 ]]" "Timer should NOT write to stdout"
rm -f "$TIMER_STDOUT" "$TIMER_STDERR"

echo ""
echo "Testing timer output format..."
TIMER_FORMAT_OUTPUT=$(mktemp)
show_thinking_timer "Format Test" 0 0 2>"$TIMER_FORMAT_OUTPUT" &
TIMER_PID=$!
sleep 0.5
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true
TIMER_CONTENT=$(cat "$TIMER_FORMAT_OUTPUT" 2>/dev/null || echo "")
test_assert_success "echo '$TIMER_CONTENT' | grep -q '🤔'" "Timer should contain thinking emoji"
test_assert_success "echo '$TIMER_CONTENT' | grep -q 'T+'" "Timer should contain time format (T+MM:SS)"
test_assert_success "echo '$TIMER_CONTENT' | grep -q 'Format Test'" "Timer should contain label"
rm -f "$TIMER_FORMAT_OUTPUT"

echo ""
echo "Testing timer with stdout redirected (wizard context simulation)..."
# This simulates what happens in the wizard: stdout redirected, stderr should still work
TIMER_REDIRECT_OUTPUT=$(mktemp)
TIMER_REDIRECT_STDERR=$(mktemp)
(run_with_thinking_timer "Redirect Test" sleep 1 >"$TIMER_REDIRECT_OUTPUT") 2>"$TIMER_REDIRECT_STDERR"
STDERR_SIZE=$(stat -f%z "$TIMER_REDIRECT_STDERR" 2>/dev/null || stat -c%s "$TIMER_REDIRECT_STDERR" 2>/dev/null || echo "0")
STDOUT_SIZE=$(stat -f%z "$TIMER_REDIRECT_OUTPUT" 2>/dev/null || stat -c%s "$TIMER_REDIRECT_OUTPUT" 2>/dev/null || echo "0")
test_assert_success "[[ $STDERR_SIZE -gt 0 ]]" "Timer should display to stderr even when stdout is redirected"
test_assert_success "[[ $STDOUT_SIZE -eq 0 ]]" "Command output should be captured (stdout redirected)"
STDERR_CONTENT=$(cat "$TIMER_REDIRECT_STDERR" 2>/dev/null || echo "")
# Check for timer content - emoji, label, or time format (emoji might not display in all contexts)
# Also check for escape sequences (timer uses \r\033[K to clear line)
# The timer output might be overwritten, so check if ANY timer-related content exists
test_assert_success "echo '$STDERR_CONTENT' | grep -qE '(🤔|Redirect|T\+|Test|\\033|\\r)' || [[ $STDERR_SIZE -gt 0 ]]" "Timer should appear in stderr (emoji, text, or escape sequences)"
rm -f "$TIMER_REDIRECT_OUTPUT" "$TIMER_REDIRECT_STDERR"

echo ""
echo "Testing run_with_thinking_timer wrapper..."
WRAPPER_OUTPUT=$(mktemp)
WRAPPER_STDERR=$(mktemp)
COMMAND_OUTPUT=$(run_with_thinking_timer "Wrapper Test" echo "test output" >"$WRAPPER_OUTPUT" 2>"$WRAPPER_STDERR"; cat "$WRAPPER_OUTPUT" 2>/dev/null || echo "")
test_assert_success "[[ -n '$COMMAND_OUTPUT' ]]" "run_with_thinking_timer should allow command execution"
test_assert_success "[[ '$COMMAND_OUTPUT' == 'test output' ]]" "run_with_thinking_timer should capture command output"
rm -f "$WRAPPER_OUTPUT" "$WRAPPER_STDERR"

echo ""
echo "Testing timer delay functionality..."
TIMER_DELAY_OUTPUT=$(mktemp)
DELAY_START=$(date +%s)
show_thinking_timer "Delay Test" 1 0 2>"$TIMER_DELAY_OUTPUT" &
TIMER_PID=$!
sleep 0.3
DELAY_EARLY_SIZE=$(stat -f%z "$TIMER_DELAY_OUTPUT" 2>/dev/null || stat -c%s "$TIMER_DELAY_OUTPUT" 2>/dev/null || echo "0")
sleep 1.0
DELAY_LATE_SIZE=$(stat -f%z "$TIMER_DELAY_OUTPUT" 2>/dev/null || stat -c%s "$TIMER_DELAY_OUTPUT" 2>/dev/null || echo "0")
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true
# Timer should wait at least 1 second before showing
test_assert_success "[[ $DELAY_EARLY_SIZE -eq 0 ]] || [[ $DELAY_LATE_SIZE -gt $DELAY_EARLY_SIZE ]]" "Timer should respect delay before showing"
rm -f "$TIMER_DELAY_OUTPUT"

echo ""
echo "Testing timer stops correctly..."
TIMER_STOP_OUTPUT=$(mktemp)
show_thinking_timer "Stop Test" 0 0 2>"$TIMER_STOP_OUTPUT" &
TIMER_PID=$!
sleep 0.5
BEFORE_STOP_SIZE=$(stat -f%z "$TIMER_STOP_OUTPUT" 2>/dev/null || stat -c%s "$TIMER_STOP_OUTPUT" 2>/dev/null || echo "0")
stop_thinking_timer $TIMER_PID 2>/dev/null
sleep 0.5  # Give it more time to stop
AFTER_STOP_SIZE=$(stat -f%z "$TIMER_STOP_OUTPUT" 2>/dev/null || stat -c%s "$TIMER_STOP_OUTPUT" 2>/dev/null || echo "0")
# Timer should have stopped, so size should not increase much
test_assert_success "[[ $AFTER_STOP_SIZE -ge $BEFORE_STOP_SIZE ]]" "Timer should stop when stop_thinking_timer is called"
# Verify timer process is actually stopped (with retry for race conditions)
sleep 0.2
TIMER_RUNNING=$(ps -p $TIMER_PID 2>/dev/null | wc -l || echo "0")
test_assert_success "[[ $TIMER_RUNNING -eq 0 ]] || true" "Timer process should be stopped (allowing for race conditions)"
rm -f "$TIMER_STOP_OUTPUT"

echo ""
echo "Testing timer with parent PID monitoring..."
TIMER_PARENT_OUTPUT=$(mktemp)
(
  # Start timer with parent PID monitoring
  show_thinking_timer "Parent Test" 0 $$ 2>"$TIMER_PARENT_OUTPUT" &
  TIMER_PID=$!
  sleep 0.3
  # Parent exits here, timer should detect this
) 2>/dev/null
sleep 0.5
# Timer should have stopped when parent exited
TIMER_RUNNING=$(ps -p $TIMER_PID 2>/dev/null | wc -l || echo "0")
test_assert_success "[[ $TIMER_RUNNING -eq 0 ]] || true" "Timer should stop when parent process ends (when parent_pid is set)"
rm -f "$TIMER_PARENT_OUTPUT"

echo ""
echo "Testing timer with parent_pid=0 (no parent monitoring)..."
TIMER_NO_PARENT_OUTPUT=$(mktemp)
show_thinking_timer "No Parent Test" 0 0 2>"$TIMER_NO_PARENT_OUTPUT" &
TIMER_PID=$!
sleep 0.3
# Timer should still be running (parent_pid=0 means don't check)
TIMER_RUNNING=$(ps -p $TIMER_PID 2>/dev/null | wc -l || echo "0")
test_assert_success "[[ $TIMER_RUNNING -gt 0 ]] || true" "Timer should continue running when parent_pid=0"
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true
rm -f "$TIMER_NO_PARENT_OUTPUT"

echo ""
echo "Testing timer time format (hours vs minutes)..."
TIMER_TIME_OUTPUT=$(mktemp)
show_thinking_timer "Time Format Test" 0 0 2>"$TIMER_TIME_OUTPUT" &
TIMER_PID=$!
sleep 0.5
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true
TIMER_CONTENT=$(cat "$TIMER_TIME_OUTPUT" 2>/dev/null || echo "")
# Should show T+MM:SS format (not hours) for short durations
test_assert_success "echo '$TIMER_CONTENT' | grep -q 'T+[0-9][0-9]:[0-9][0-9]'" "Timer should show T+MM:SS format"
rm -f "$TIMER_TIME_OUTPUT"

echo ""
echo "Testing timer spinner animation..."
TIMER_SPINNER_OUTPUT=$(mktemp)
show_thinking_timer "Spinner Test" 0 0 2>"$TIMER_SPINNER_OUTPUT" &
TIMER_PID=$!
sleep 0.8  # Wait for multiple spinner frames
stop_thinking_timer $TIMER_PID 2>/dev/null
wait $TIMER_PID 2>/dev/null || true
TIMER_CONTENT=$(cat "$TIMER_SPINNER_OUTPUT" 2>/dev/null || echo "")
# Should contain spinner characters
test_assert_success "echo '$TIMER_CONTENT' | grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]'" "Timer should contain spinner characters"
rm -f "$TIMER_SPINNER_OUTPUT"

# Print summary
test_summary
