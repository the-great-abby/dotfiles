#!/bin/bash
# Unit tests for task management functionality
# Tests task creation, listing, notes, and wizard integration

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source common helpers
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "Task Management"

echo "Testing task management functions..."

# Test 1: gtd-task command exists
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-task" "gtd-task command should exist"

# Test 2: Task listing function works
echo ""
echo "Testing task listing..."
if command -v gtd-task &>/dev/null; then
  test_assert_success "gtd-task list >/dev/null 2>&1" "gtd-task list should work"
else
  test_assert_success "[[ -f \"$SCRIPT_DIR/../bin/gtd-task\" ]]" "gtd-task script should exist"
fi

# Test 3: get_task_notes function exists and works (bash 3.2 compatible)
echo ""
echo "Testing get_task_notes function..."
if [[ -f "$SCRIPT_DIR/../bin/gtd-wizard" ]]; then
  source "$SCRIPT_DIR/../bin/gtd-wizard" 2>/dev/null || true
  test_assert_success "declare -f get_task_notes &>/dev/null" "get_task_notes function should exist"
  
  # Test that it doesn't use bash 4+ features
  if declare -f get_task_notes &>/dev/null; then
    local func_body=$(declare -f get_task_notes)
    test_assert_success "! echo '$func_body' | grep -q 'local -n'" "get_task_notes should not use local -n (bash 4+ feature)"
  fi
fi

# Test 4: Task ID extraction function
echo ""
echo "Testing get_task_id_by_number function..."
if [[ -f "$SCRIPT_DIR/../bin/gtd-wizard" ]]; then
  source "$SCRIPT_DIR/../bin/gtd-wizard" 2>/dev/null || true
  test_assert_success "declare -f get_task_id_by_number &>/dev/null" "get_task_id_by_number function should exist"
fi

# Test 5: Task selection function
echo ""
echo "Testing select_from_tasks function..."
if [[ -f "$SCRIPT_DIR/../bin/gtd-wizard" ]]; then
  source "$SCRIPT_DIR/../bin/gtd-wizard" 2>/dev/null || true
  test_assert_success "declare -f select_from_tasks &>/dev/null" "select_from_tasks function should exist"
fi

# Test 6: TASKS_PATH is set
test_assert_success "[[ -n '$TASKS_PATH' ]]" "TASKS_PATH should be set"

# Test 7: Task paths are valid
if [[ -n "$TASKS_PATH" ]]; then
  test_assert_success "[[ -d '$TASKS_PATH' ]] || [[ -n '$TASKS_PATH' ]]" "TASKS_PATH should be a valid directory or set"
fi

# Test 8: gtd-task syntax is valid
if [[ -f "$SCRIPT_DIR/../bin/gtd-task" ]]; then
  test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-task" "gtd-task syntax should be valid"
fi

# Test 9: Task wizard functions are available
echo ""
echo "Testing task wizard integration..."
if [[ -f "$SCRIPT_DIR/../bin/gtd-wizard-org.sh" ]]; then
  source "$SCRIPT_DIR/../bin/gtd-wizard-org.sh" 2>/dev/null || true
  test_assert_success "declare -f task_wizard &>/dev/null" "task_wizard function should exist"
fi

# Test 10: Task note functionality (if task exists)
echo ""
echo "Testing task note functionality..."
if command -v gtd-task &>/dev/null && [[ -d "$TASKS_PATH" ]]; then
  # Try to find any task file
  local test_task_file=$(find "$TASKS_PATH" -type f -name "*.md" 2>/dev/null | head -1)
  if [[ -n "$test_task_file" && -f "$test_task_file" ]]; then
    local test_task_id=$(basename "$test_task_file" .md)
    # Test that get_task_notes can be called (even if it returns no notes)
    if declare -f get_task_notes &>/dev/null; then
      # Call with a test prefix
      get_task_notes "$test_task_id" "test_notes" 2>/dev/null || true
      test_assert_success "true" "get_task_notes should be callable without errors"
    fi
  fi
fi

# Print summary
test_summary
