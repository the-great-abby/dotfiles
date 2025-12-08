#!/bin/bash
# Unit tests for gtd-guides.sh

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"
source "$SCRIPT_DIR/../bin/gtd-guides.sh"

# Test suite
test_init "gtd-guides.sh"

echo "Testing guide functions..."
test_assert_success "gtd_show_areas_guide >/dev/null" "gtd_show_areas_guide should work"
test_assert_success "gtd_show_projects_guide >/dev/null" "gtd_show_projects_guide should work"
test_assert_success "gtd_show_tasks_guide >/dev/null" "gtd_show_tasks_guide should work"
test_assert_success "gtd_show_express_guide >/dev/null" "gtd_show_express_guide should work"
test_assert_success "gtd_show_moc_guide >/dev/null" "gtd_show_moc_guide should work"
test_assert_success "gtd_show_templates_guide >/dev/null" "gtd_show_templates_guide should work"
test_assert_success "gtd_show_zettelkasten_guide >/dev/null" "gtd_show_zettelkasten_guide should work"
test_assert_success "gtd_show_checkin_guide >/dev/null" "gtd_show_checkin_guide should work"
test_assert_success "gtd_show_organization_guide >/dev/null" "gtd_show_organization_guide should work"
test_assert_success "gtd_show_review_guide >/dev/null" "gtd_show_review_guide should work"
test_assert_success "gtd_show_capture_guide >/dev/null" "gtd_show_capture_guide should work"
test_assert_success "gtd_show_process_guide >/dev/null" "gtd_show_process_guide should work"
test_assert_success "gtd_show_sync_guide >/dev/null" "gtd_show_sync_guide should work"
test_assert_success "gtd_show_advice_guide >/dev/null" "gtd_show_advice_guide should work"
test_assert_success "gtd_show_daily_log_guide >/dev/null" "gtd_show_daily_log_guide should work"
test_assert_success "gtd_show_search_guide >/dev/null" "gtd_show_search_guide should work"
test_assert_success "gtd_show_status_guide >/dev/null" "gtd_show_status_guide should work"
test_assert_success "gtd_show_config_guide >/dev/null" "gtd_show_config_guide should work"
test_assert_success "gtd_show_second_brain_learning_guide >/dev/null" "gtd_show_second_brain_learning_guide should work"
test_assert_success "gtd_show_life_vision_guide >/dev/null" "gtd_show_life_vision_guide should work"
test_assert_success "gtd_show_diagram_guide >/dev/null" "gtd_show_diagram_guide should work"
test_assert_success "gtd_show_habits_guide >/dev/null" "gtd_show_habits_guide should work"
test_assert_success "gtd_show_learning_guide >/dev/null" "gtd_show_learning_guide should work"
test_assert_success "gtd_show_ai_suggestions_guide >/dev/null" "gtd_show_ai_suggestions_guide should work"
test_assert_success "gtd_show_goal_tracking_guide >/dev/null" "gtd_show_goal_tracking_guide should work"
test_assert_success "gtd_show_energy_audit_guide >/dev/null" "gtd_show_energy_audit_guide should work"
test_assert_success "gtd_show_gamification_guide >/dev/null" "gtd_show_gamification_guide should work"
test_assert_success "gtd_show_healthkit_guide >/dev/null" "gtd_show_healthkit_guide should work"
test_assert_success "gtd_show_calendar_guide >/dev/null" "gtd_show_calendar_guide should work"
test_assert_success "gtd_show_mood_tracking_guide >/dev/null" "gtd_show_mood_tracking_guide should work"
test_assert_success "gtd_show_metric_correlations_guide >/dev/null" "gtd_show_metric_correlations_guide should work"
test_assert_success "gtd_show_pattern_recognition_guide >/dev/null" "gtd_show_pattern_recognition_guide should work"
test_assert_success "gtd_show_energy_schedule_guide >/dev/null" "gtd_show_energy_schedule_guide should work"
test_assert_success "gtd_show_note_packets_guide >/dev/null" "gtd_show_note_packets_guide should work"
test_assert_success "gtd_show_connect_notes_guide >/dev/null" "gtd_show_connect_notes_guide should work"
test_assert_success "gtd_show_converge_notes_guide >/dev/null" "gtd_show_converge_notes_guide should work"
test_assert_success "gtd_show_discover_connections_guide >/dev/null" "gtd_show_discover_connections_guide should work"
test_assert_success "gtd_show_distill_guide >/dev/null" "gtd_show_distill_guide should work"
test_assert_success "gtd_show_diverge_guide >/dev/null" "gtd_show_diverge_guide should work"
test_assert_success "gtd_show_evergreen_notes_guide >/dev/null" "gtd_show_evergreen_notes_guide should work"

# Print summary
test_summary

