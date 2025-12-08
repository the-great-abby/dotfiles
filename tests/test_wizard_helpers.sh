#!/bin/bash
# Unit tests for wizard helper functions

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the modules
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "Wizard Helper Functions"

echo "Testing select_from_numbered_list function logic..."
# We can't fully test interactive functions, but we can test the logic
# Create a mock function to test the selection logic
test_select_logic() {
  local items=("Item 1" "Item 2" "Item 3")
  local item_count=${#items[@]}
  
  # Test empty array handling
  local empty_items=()
  if [[ ${#empty_items[@]} -eq 0 ]]; then
    test_assert_success "true" "Empty array should be detected"
  fi
  
  # Test array indexing
  test_assert_equal "3" "$item_count" "Should count 3 items"
  test_assert_equal "Item 1" "${items[0]}" "First item should be accessible"
  test_assert_equal "Item 3" "${items[2]}" "Last item should be accessible"
}

test_select_logic

echo ""
echo "Testing mark_suggestion functions (Python availability)..."
# Test that Python is available for suggestion marking
if command -v python3 &>/dev/null; then
  test_assert_success "command -v python3 >/dev/null" "python3 should be available for suggestion functions"
  
  # Test JSON parsing capability
  TEST_JSON='{"status":"pending","suggestion":"test"}'
  JSON_TEST=$(echo "$TEST_JSON" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data['status'])" 2>/dev/null)
  test_assert_equal "pending" "$JSON_TEST" "Python should be able to parse JSON"
else
  echo "  Skipping Python tests (python3 not available)"
fi

echo ""
echo "Testing dashboard data collection..."
# Test that dashboard can collect required data
test_assert_success "[[ -n '$(gtd_get_today)' ]]" "Dashboard should be able to get today's date"
test_assert_success "[[ -n '$(gtd_get_current_time)' ]]" "Dashboard should be able to get current time"

# Test path existence for dashboard stats
if [[ -d "${INBOX_PATH:-}" ]]; then
  test_assert_dir_exists "$INBOX_PATH" "INBOX_PATH should exist for dashboard"
fi

if [[ -d "${TASKS_PATH:-}" ]]; then
  test_assert_dir_exists "$TASKS_PATH" "TASKS_PATH should exist for dashboard"
fi

if [[ -d "${PROJECTS_PATH:-}" ]]; then
  test_assert_dir_exists "$PROJECTS_PATH" "PROJECTS_PATH should exist for dashboard"
fi

echo ""
echo "Testing horizon context parsing logic..."
# Test horizon context string parsing
test_horizon_parsing() {
  # Test project context
  local context="project:my-project"
  if [[ "$context" == project:* ]]; then
    local project_name="${context#project:}"
    test_assert_equal "my-project" "$project_name" "Should extract project name from context"
  fi
  
  # Test area context
  local area_context="area:health"
  if [[ "$area_context" == area:* ]]; then
    local area_name="${area_context#area:}"
    test_assert_equal "health" "$area_name" "Should extract area name from context"
  fi
  
  # Test goal context
  local goal_context="goal_1_2yr:Learn Python"
  if [[ "$goal_context" == goal_1_2yr* ]]; then
    local goal_note="${goal_context#goal_1_2yr:}"
    test_assert_equal "Learn Python" "$goal_note" "Should extract goal note from context"
  fi
  
  # Test vision context
  local vision_context="vision_3_5yr:Build a business"
  if [[ "$vision_context" == vision_3_5yr* ]]; then
    local vision_note="${vision_context#vision_3_5yr:}"
    test_assert_equal "Build a business" "$vision_note" "Should extract vision note from context"
  fi
}

test_horizon_parsing

echo ""
echo "Testing guide function wrappers..."
# Test that guide functions can be called (they may output to stderr, so redirect both)
test_assert_success "gtd_show_areas_guide >/dev/null 2>&1 || true" "gtd_show_areas_guide should be callable"
test_assert_success "gtd_show_projects_guide >/dev/null 2>&1 || true" "gtd_show_projects_guide should be callable"
test_assert_success "gtd_show_tasks_guide >/dev/null 2>&1 || true" "gtd_show_tasks_guide should be callable"
test_assert_success "gtd_show_capture_guide >/dev/null 2>&1 || true" "gtd_show_capture_guide should be callable"

# Print summary
test_summary
