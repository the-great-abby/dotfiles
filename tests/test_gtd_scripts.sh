#!/bin/bash
# Integration tests for updated GTD scripts

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source common helpers
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "GTD Scripts Integration"

echo "Testing that updated scripts can source common helpers..."
test_assert_success "[[ -n '$GTD_BASE_DIR' ]]" "GTD_BASE_DIR should be set"
test_assert_success "[[ -n '$PROJECTS_PATH' ]]" "PROJECTS_PATH should be set"
test_assert_success "[[ -n '$AREAS_PATH' ]]" "AREAS_PATH should be set"
test_assert_success "[[ -n '$CYAN' ]]" "Colors should be available"
test_assert_success "[[ -n '$GREEN' ]]" "Colors should be available"

echo ""
echo "Testing common helper functions..."
test_assert_success "gtd_get_today >/dev/null" "gtd_get_today should work"
test_assert_success "gtd_get_current_time >/dev/null" "gtd_get_current_time should work"
test_assert_success "gtd_get_mcp_python >/dev/null" "gtd_get_mcp_python should work"

echo ""
echo "Testing that scripts exist and are executable..."
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-process" "gtd-process should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-context" "gtd-context should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-help" "gtd-help should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-project" "gtd-project should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-task" "gtd-task should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-area" "gtd-area should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-checkin" "gtd-checkin should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-advise" "gtd-advise should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-daily-log" "gtd-daily-log should exist"
test_assert_file_exists "$SCRIPT_DIR/../bin/gtd-daily-reminder" "gtd-daily-reminder should exist"

echo ""
echo "Testing that scripts can be sourced without errors..."
# Test that scripts can at least be parsed (syntax check)
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-process" "gtd-process syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-context" "gtd-context syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-help" "gtd-help syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-project" "gtd-project syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-task" "gtd-task syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-area" "gtd-area syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-checkin" "gtd-checkin syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-advise" "gtd-advise syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-daily-log" "gtd-daily-log syntax should be valid"
test_assert_success "bash -n $SCRIPT_DIR/../bin/gtd-daily-reminder" "gtd-daily-reminder syntax should be valid"

# Print summary
test_summary

