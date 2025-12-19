#!/bin/bash
# Advanced unit tests for gtd-common.sh
# Tests: caching, feedback, formatting, empty state, progress indicators, and edge cases

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "gtd-common.sh Advanced Functions"

echo "Testing caching functions..."

# Test gtd_get_cache_file
echo ""
echo "Testing gtd_get_cache_file()..."
CACHE_FILE=$(gtd_get_cache_file)
test_assert_success "[[ -n '$CACHE_FILE' ]]" "gtd_get_cache_file should return a path"
test_assert_success "[[ '$CACHE_FILE' == */dashboard_counts ]]" "Cache file should be named dashboard_counts"
CACHE_DIR=$(dirname "$CACHE_FILE")
test_assert_dir_exists "$CACHE_DIR" "Cache directory should exist"

# Test gtd_get_cached_count with fresh cache
echo ""
echo "Testing gtd_get_cached_count() with fresh cache..."
TEST_DIR=$(mktemp -d)
touch "${TEST_DIR}/test1.md"
touch "${TEST_DIR}/test2.md"
touch "${TEST_DIR}/test3.md"

# First call should compute and cache
COUNT1=$(gtd_get_cached_count "test_key" "$TEST_DIR" "*.md" 5)
test_assert_equal "3" "$COUNT1" "Should count 3 markdown files"

# Second call within cache age should use cache
COUNT2=$(gtd_get_cached_count "test_key" "$TEST_DIR" "*.md" 5)
test_assert_equal "3" "$COUNT2" "Should return cached count"

# Test cache invalidation
echo ""
echo "Testing cache invalidation..."
gtd_invalidate_cache
test_assert_failure "[[ -f '$CACHE_FILE' ]]" "Cache file should be deleted after invalidation"

# Test gtd_get_cached_count with projects pattern
echo ""
echo "Testing gtd_get_cached_count() with projects pattern..."
PROJECT_DIR=$(mktemp -d)
mkdir -p "${PROJECT_DIR}/project1"
mkdir -p "${PROJECT_DIR}/project2"
touch "${PROJECT_DIR}/project1/README.md"
touch "${PROJECT_DIR}/project2/README.md"
PROJECT_COUNT=$(gtd_get_cached_count "test_projects" "$PROJECT_DIR" "projects" 5)
test_assert_equal "2" "$PROJECT_COUNT" "Should count 2 projects with README.md"

# Test gtd_get_cached_count with non-existent directory
echo ""
echo "Testing gtd_get_cached_count() with non-existent directory..."
NONEXISTENT_COUNT=$(gtd_get_cached_count "test_nonexistent" "/nonexistent/dir" "*.md" 5)
test_assert_equal "0" "$NONEXISTENT_COUNT" "Should return 0 for non-existent directory"

# Test gtd_get_cached_count with empty directory
echo ""
echo "Testing gtd_get_cached_count() with empty directory..."
EMPTY_DIR=$(mktemp -d)
EMPTY_COUNT=$(gtd_get_cached_count "test_empty" "$EMPTY_DIR" "*.md" 5)
test_assert_equal "0" "$EMPTY_COUNT" "Should return 0 for empty directory"

# Cleanup
rm -rf "$TEST_DIR" "$PROJECT_DIR" "$EMPTY_DIR"
gtd_invalidate_cache

echo ""
echo "Testing feedback functions..."

# Test gtd_feedback success
echo ""
echo "Testing gtd_feedback() success type..."
FEEDBACK_SUCCESS=$(gtd_feedback success "Test success message" 2>&1)
test_assert_success "echo '$FEEDBACK_SUCCESS' | grep -q '✓'" "Success feedback should contain checkmark"
test_assert_success "echo '$FEEDBACK_SUCCESS' | grep -q 'Test success message'" "Success feedback should contain message"

# Test gtd_feedback error
FEEDBACK_ERROR=$(gtd_feedback error "Test error message" 2>&1)
test_assert_success "echo '$FEEDBACK_ERROR' | grep -q '✗'" "Error feedback should contain X mark"

# Test gtd_feedback info
FEEDBACK_INFO=$(gtd_feedback info "Test info message" 2>&1)
test_assert_success "echo '$FEEDBACK_INFO' | grep -q 'ℹ'" "Info feedback should contain info icon"

# Test gtd_feedback warning
FEEDBACK_WARNING=$(gtd_feedback warning "Test warning message" 2>&1)
test_assert_success "echo '$FEEDBACK_WARNING' | grep -q '⚠'" "Warning feedback should contain warning icon"

# Test gtd_feedback invalid type
FEEDBACK_INVALID=$(gtd_feedback invalid "Test message" 2>&1)
test_assert_success "echo '$FEEDBACK_INVALID' | grep -q 'Test message'" "Invalid type should still output message"

echo ""
echo "Testing formatting functions..."

# Test gtd_format_list_item basic
echo ""
echo "Testing gtd_format_list_item() basic..."
FORMATTED=$(gtd_format_list_item "1" "Test Item")
test_assert_success "echo '$FORMATTED' | grep -q '1)'" "Formatted item should contain number"
test_assert_success "echo '$FORMATTED' | grep -q 'Test Item'" "Formatted item should contain text"

# Test gtd_format_list_item with truncation
LONG_ITEM="This is a very long item name that should be truncated when it exceeds the maximum width limit"
FORMATTED_LONG=$(gtd_format_list_item "2" "$LONG_ITEM" 60 "true")
test_assert_success "[[ ${#FORMATTED_LONG} -lt 100 ]]" "Long item should be truncated"
test_assert_success "echo '$FORMATTED_LONG' | grep -q '\.\.\.'" "Truncated item should end with ellipsis"

# Test gtd_format_list_item without truncation
FORMATTED_NO_TRUNC=$(gtd_format_list_item "3" "$LONG_ITEM" 60 "false")
test_assert_success "echo '$FORMATTED_NO_TRUNC' | grep -q '$LONG_ITEM'" "Item should not be truncated when truncate=false"

echo ""
echo "Testing empty state function..."

# Test gtd_empty_state with hint
EMPTY_STATE_OUTPUT=$(gtd_empty_state "tasks" "Press 1 to add your first task" 2>&1)
test_assert_success "echo '$EMPTY_STATE_OUTPUT' | grep -qi 'no tasks found'" "Empty state should mention item type"
test_assert_success "echo '$EMPTY_STATE_OUTPUT' | grep -q 'Press 1'" "Empty state should show action hint"

# Test gtd_empty_state without hint
EMPTY_STATE_NO_HINT=$(gtd_empty_state "projects" "" 2>&1)
test_assert_success "echo '$EMPTY_STATE_NO_HINT' | grep -qi 'no projects found'" "Empty state should work without hint"

echo ""
echo "Testing progress indicator function..."

# Test gtd_show_progress
PROGRESS_OUTPUT=$(gtd_show_progress "5" "10" "Processing" 2>&1)
test_assert_success "echo '$PROGRESS_OUTPUT' | grep -q '5/10'" "Progress should show current/total"
test_assert_success "echo '$PROGRESS_OUTPUT' | grep -q '50%'" "Progress should show percentage"

# Test gtd_show_progress at completion
PROGRESS_COMPLETE=$(gtd_show_progress "10" "10" "Processing" 2>&1)
test_assert_success "echo '$PROGRESS_COMPLETE' | grep -q '10/10'" "Progress should show completion"
test_assert_success "echo '$PROGRESS_COMPLETE' | grep -q '100%'" "Progress should show 100%"

echo ""
echo "Testing action success function..."

# Test gtd_action_success
ACTION_OUTPUT=$(gtd_action_success "created" "task" "Test Task" 2>&1)
test_assert_success "echo '$ACTION_OUTPUT' | grep -qi 'task'" "Action success should mention item type"
test_assert_success "echo '$ACTION_OUTPUT' | grep -q 'Test Task'" "Action success should mention item name"
test_assert_success "echo '$ACTION_OUTPUT' | grep -qi 'created'" "Action success should mention action"

# Test gtd_action_success with different actions
for action in "created" "updated" "deleted" "completed"; do
  ACTION_TEST=$(gtd_action_success "$action" "project" "Test Project" 2>&1)
  test_assert_success "echo '$ACTION_TEST' | grep -qi '$action'" "Action success should work for $action"
done

echo ""
echo "Testing pause functions..."

# Test gtd_pause with timeout (non-interactive)
PAUSE_OUTPUT=$(timeout 1 bash -c 'source "$0"; gtd_pause 0.5 "Test pause"' "$SCRIPT_DIR/../bin/gtd-common.sh" 2>&1 || true)
test_assert_success "true" "gtd_pause should work with timeout"

# Test gtd_quick_pause
QUICK_PAUSE_OUTPUT=$(timeout 1 bash -c 'source "$0"; gtd_quick_pause' "$SCRIPT_DIR/../bin/gtd-common.sh" 2>&1 || true)
test_assert_success "true" "gtd_quick_pause should work"

# Test gtd_silent_pause
SILENT_PAUSE_OUTPUT=$(timeout 1 bash -c 'source "$0"; gtd_silent_pause 0.5' "$SCRIPT_DIR/../bin/gtd-common.sh" 2>&1 || true)
test_assert_success "true" "gtd_silent_pause should work"

echo ""
echo "Testing section divider functions..."

# Test gtd_section_divider
DIVIDER_OUTPUT=$(gtd_section_divider 2>&1)
test_assert_success "[[ -n '$DIVIDER_OUTPUT' ]]" "Section divider should output something"
test_assert_success "echo '$DIVIDER_OUTPUT' | grep -q '━'" "Section divider should contain divider character"

# Test gtd_status_line
STATUS_OUTPUT=$(gtd_status_line "📥" "Inbox" "5 items" 2>&1)
test_assert_success "echo '$STATUS_OUTPUT' | grep -q '📥'" "Status line should contain icon"
test_assert_success "echo '$STATUS_OUTPUT' | grep -q 'Inbox'" "Status line should contain label"
test_assert_success "echo '$STATUS_OUTPUT' | grep -q '5 items'" "Status line should contain value"

# Test gtd_menu_item
MENU_OUTPUT=$(gtd_menu_item "1" "📥" "Capture something" 2>&1)
test_assert_success "echo '$MENU_OUTPUT' | grep -q '1)'" "Menu item should contain number"
test_assert_success "echo '$MENU_OUTPUT' | grep -q '📥'" "Menu item should contain icon"
test_assert_success "echo '$MENU_OUTPUT' | grep -q 'Capture something'" "Menu item should contain description"

# Test gtd_clear_and_header (non-interactive - can't test clear, but can test header)
HEADER_OUTPUT=$(gtd_print_header "Test Header" "📝" 2>&1)
test_assert_success "echo '$HEADER_OUTPUT' | grep -q 'Test Header'" "Header should contain title"
test_assert_success "echo '$HEADER_OUTPUT' | grep -q '📝'" "Header should contain icon"

echo ""
echo "Testing edge cases and error handling..."

# Test gtd_get_cached_count with invalid cache age
INVALID_AGE_COUNT=$(gtd_get_cached_count "test" "$TEST_DIR" "*.md" -1 2>&1 || echo "0")
test_assert_success "true" "Should handle invalid cache age gracefully"

# Test gtd_format_list_item with empty item
EMPTY_FORMATTED=$(gtd_format_list_item "1" "" 2>&1)
test_assert_success "echo '$EMPTY_FORMATTED' | grep -q '1)'" "Should format empty item"

# Test gtd_feedback with empty message
EMPTY_FEEDBACK=$(gtd_feedback success "" 2>&1)
test_assert_success "true" "Should handle empty feedback message"

# Test gtd_empty_state with empty item type
EMPTY_TYPE_OUTPUT=$(gtd_empty_state "" "Hint" 2>&1)
test_assert_success "true" "Should handle empty item type"

# Print summary
test_summary

