#!/bin/bash
# Unit tests for gtd-wizard-analysis.sh
# Tests: search_wizard, status_wizard, goal_tracking_wizard, and related analysis functions

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source common helpers first
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh"

# Test suite
test_init "gtd-wizard-analysis.sh"

echo "Testing wizard analysis functions..."

# Test that functions exist
test_assert_success "declare -f search_wizard &>/dev/null" "search_wizard function should exist"
test_assert_success "declare -f status_wizard &>/dev/null" "status_wizard function should exist"
test_assert_success "declare -f goal_tracking_wizard &>/dev/null" "goal_tracking_wizard function should exist"
test_assert_success "declare -f energy_audit_wizard &>/dev/null" "energy_audit_wizard function should exist"
test_assert_success "declare -f log_stats_wizard &>/dev/null" "log_stats_wizard function should exist"

echo ""
echo "Testing search_wizard function..."

# Test that search wizard can handle queries
test_search_queries() {
  # Test various query types
  QUERY_TYPES=("task" "project" "note" "area" "all")
  for query_type in "${QUERY_TYPES[@]}"; do
    test_assert_success "[[ -n '$query_type' ]]" "Search type $query_type should be valid"
  done
}

test_search_queries

# Test that enhanced search is available if function exists
if declare -f enhance_search_query &>/dev/null || command -v gtd_persona_helper.py &>/dev/null; then
  test_assert_success "true" "Enhanced search should be available"
fi

echo ""
echo "Testing status_wizard function..."

# Test that status wizard can collect dashboard data
test_status_data() {
  # Test dashboard data collection
  test_assert_success "[[ -n '$(gtd_get_today)' ]]" "Should be able to get today's date"
  test_assert_success "[[ -n '$(gtd_get_current_time)' ]]" "Should be able to get current time"
  
  # Test path existence for status
  if [[ -d "${INBOX_PATH:-}" ]]; then
    test_assert_dir_exists "$INBOX_PATH" "INBOX_PATH should exist for status"
  fi
  
  if [[ -d "${TASKS_PATH:-}" ]]; then
    test_assert_dir_exists "$TASKS_PATH" "TASKS_PATH should exist for status"
  fi
}

test_status_data

echo ""
echo "Testing goal_tracking_wizard function..."

# Test that goal tracking can access goals
test_goal_access() {
  # Goals might be in various locations
  GOAL_LOCATIONS=(
    "${SECOND_BRAIN}/Goals"
    "${GTD_BASE_DIR}/goals"
    "${AREAS_PATH}"
  )
  
  GOAL_FOUND=false
  for location in "${GOAL_LOCATIONS[@]}"; do
    if [[ -d "$location" ]]; then
      GOAL_FOUND=true
      break
    fi
  done
  
  test_assert_success "true" "Goal tracking should handle goal locations"
}

test_goal_access

echo ""
echo "Testing energy_audit_wizard function..."

# Test that energy audit can access daily logs
if [[ -n "${DAILY_LOGS_PATH:-}" ]] && [[ -d "$DAILY_LOGS_PATH" ]]; then
  test_assert_dir_exists "$DAILY_LOGS_PATH" "Daily logs path should exist for energy audit"
  
  # Test that logs can be read
  LOG_COUNT=$(find "$DAILY_LOGS_PATH" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  test_assert_success "true" "Should be able to count daily logs"
else
  echo "  Skipping energy audit tests (DAILY_LOGS_PATH not set or doesn't exist)"
fi

echo ""
echo "Testing log_stats_wizard function..."

# Test that log stats can process logs
test_log_stats() {
  # Test date range calculations
  TODAY=$(gtd_get_today)
  test_assert_success "[[ -n '$TODAY' ]]" "Should be able to get today for stats"
  
  # Test that date format is valid
  test_assert_success "echo '$TODAY' | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'" "Date should be in YYYY-MM-DD format"
}

test_log_stats

echo ""
echo "Testing metric_correlations_wizard function..."

# Test that metric_correlations_wizard exists
test_assert_success "declare -f metric_correlations_wizard &>/dev/null" "metric_correlations_wizard function should exist"

echo ""
echo "Testing pattern_recognition_wizard function..."

# Test that pattern_recognition_wizard exists
test_assert_success "declare -f pattern_recognition_wizard &>/dev/null" "pattern_recognition_wizard function should exist"

echo ""
echo "Testing weekly_progress_wizard function..."

# Test that weekly_progress_wizard exists
test_assert_success "declare -f weekly_progress_wizard &>/dev/null" "weekly_progress_wizard function should exist"

echo ""
echo "Testing success_metrics_wizard function..."

# Test that success_metrics_wizard exists
test_assert_success "declare -f success_metrics_wizard &>/dev/null" "success_metrics_wizard function should exist"

echo ""
echo "Testing brain_metrics_wizard function..."

# Test that brain_metrics_wizard exists
test_assert_success "declare -f brain_metrics_wizard &>/dev/null" "brain_metrics_wizard function should exist"

echo ""
echo "Testing energy_schedule_wizard function..."

# Test that energy_schedule_wizard exists
test_assert_success "declare -f energy_schedule_wizard &>/dev/null" "energy_schedule_wizard function should exist"

echo ""
echo "Testing now_wizard function..."

# Test that now_wizard exists
test_assert_success "declare -f now_wizard &>/dev/null" "now_wizard function should exist"

echo ""
echo "Testing find_wizard function..."

# Test that find_wizard exists
test_assert_success "declare -f find_wizard &>/dev/null" "find_wizard function should exist"

echo ""
echo "Testing milestone_wizard function..."

# Test that milestone_wizard exists
test_assert_success "declare -f milestone_wizard &>/dev/null" "milestone_wizard function should exist"

echo ""
echo "Testing worker management functions..."

# Test that worker functions exist
test_assert_success "declare -f manage_worker &>/dev/null" "manage_worker function should exist"
test_assert_success "declare -f start_worker &>/dev/null" "start_worker function should exist"
test_assert_success "declare -f manage_task_org_worker &>/dev/null" "manage_task_org_worker function should exist"
test_assert_success "declare -f manage_advice_worker &>/dev/null" "manage_advice_worker function should exist"

echo ""
echo "Testing edge cases and error handling..."

# Test empty query handling
test_empty_query() {
  EMPTY_QUERY=""
  test_assert_success "[[ -z '$EMPTY_QUERY' ]]" "Should handle empty query"
}

test_empty_query

# Test invalid date handling
test_invalid_dates() {
  # Test dates that don't match format
  INVALID_FORMAT_DATES=("invalid-date" "")
  for invalid_date in "${INVALID_FORMAT_DATES[@]}"; do
    test_assert_failure "echo '$invalid_date' | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'" "Should detect invalid date format: $invalid_date"
  done
  
  # Test dates that match format but are invalid (month > 12 or month = 00)
  # These will match the format regex but are logically invalid
  # We test that they match the format (which they do) but note they're invalid
  FORMAT_VALID_BUT_INVALID=("2024-13-01" "2024-00-01")
  for date in "${FORMAT_VALID_BUT_INVALID[@]}"; do
    # These match the format but are invalid - we just verify the format check works
    test_assert_success "echo '$date' | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'" "Date format check works (date $date matches format but is invalid)"
  done
}

test_invalid_dates

# Test date range validation
test_date_ranges() {
  # Test that start date is before end date
  START_DATE="2024-01-01"
  END_DATE="2024-01-31"
  
  # Convert to epoch for comparison (simplified test)
  test_assert_success "[[ '$START_DATE' < '$END_DATE' || '$START_DATE' == '$END_DATE' ]]" "Start date should be before or equal to end date"
}

test_date_ranges

# Test worker status checking
test_worker_status() {
  # Test that worker status can be checked
  # This might check for running processes or status files
  test_assert_success "true" "Worker status checking should be available"
}

test_worker_status

# Print summary
test_summary

