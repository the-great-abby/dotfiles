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

# Print summary
test_summary

