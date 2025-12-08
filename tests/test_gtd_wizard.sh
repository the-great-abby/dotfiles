#!/bin/bash
# Unit tests for gtd-wizard modularity and helper functions

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"
source "$SCRIPT_DIR/../bin/gtd-guides.sh"

# Test suite
test_init "gtd-wizard Modularity & Functions"

echo "Testing modularity - wizard dependencies..."
test_assert_success "[[ -n '$GTD_BASE_DIR' ]]" "GTD_BASE_DIR should be available from gtd-common.sh"
test_assert_success "[[ -n '$PROJECTS_PATH' ]]" "PROJECTS_PATH should be available from gtd-common.sh"
test_assert_success "[[ -n '$AREAS_PATH' ]]" "AREAS_PATH should be available from gtd-common.sh"
test_assert_success "[[ -n '$CYAN' ]]" "Colors should be available from gtd-common.sh"
test_assert_success "[[ -n '$GREEN' ]]" "Colors should be available from gtd-common.sh"

echo ""
echo "Testing that guide functions are available..."
test_assert_success "command -v gtd_show_areas_guide >/dev/null || type gtd_show_areas_guide >/dev/null 2>&1" "gtd_show_areas_guide should be available"
test_assert_success "command -v gtd_show_projects_guide >/dev/null || type gtd_show_projects_guide >/dev/null 2>&1" "gtd_show_projects_guide should be available"
test_assert_success "command -v gtd_show_tasks_guide >/dev/null || type gtd_show_tasks_guide >/dev/null 2>&1" "gtd_show_tasks_guide should be available"
test_assert_success "command -v gtd_show_capture_guide >/dev/null || type gtd_show_capture_guide >/dev/null 2>&1" "gtd_show_capture_guide should be available"
test_assert_success "command -v gtd_show_organization_guide >/dev/null || type gtd_show_organization_guide >/dev/null 2>&1" "gtd_show_organization_guide should be available"

echo ""
echo "Testing menu navigation functions..."
test_assert_success "command -v gtd_push_menu >/dev/null || type gtd_push_menu >/dev/null 2>&1" "gtd_push_menu should be available"
test_assert_success "command -v gtd_pop_menu >/dev/null || type gtd_pop_menu >/dev/null 2>&1" "gtd_pop_menu should be available"
test_assert_success "command -v gtd_get_menu_level >/dev/null || type gtd_get_menu_level >/dev/null 2>&1" "gtd_get_menu_level should be available"
test_assert_success "command -v gtd_show_breadcrumb >/dev/null || type gtd_show_breadcrumb >/dev/null 2>&1" "gtd_show_breadcrumb should be available"

# Test menu navigation
gtd_push_menu "Test Menu 1"
test_assert_equal "1" "$(gtd_get_menu_level)" "Menu level should be 1 after first push"
gtd_push_menu "Test Menu 2"
test_assert_equal "2" "$(gtd_get_menu_level)" "Menu level should be 2 after second push"
gtd_pop_menu
test_assert_equal "1" "$(gtd_get_menu_level)" "Menu level should be 1 after pop"
gtd_pop_menu

echo ""
echo "Testing wizard script syntax..."
WIZARD_SCRIPT="$SCRIPT_DIR/../bin/gtd-wizard"
test_assert_file_exists "$WIZARD_SCRIPT" "gtd-wizard script should exist"
test_assert_success "bash -n $WIZARD_SCRIPT" "gtd-wizard syntax should be valid"

echo ""
echo "Testing that wizard sources common files..."
test_assert_success "grep -qi 'GTD_COMMON.*gtd-common' $WIZARD_SCRIPT || grep -qi 'source.*gtd-common' $WIZARD_SCRIPT" "gtd-wizard should source gtd-common.sh"
test_assert_success "grep -qi 'GTD_GUIDES.*gtd-guides' $WIZARD_SCRIPT || grep -qi 'source.*gtd-guides' $WIZARD_SCRIPT" "gtd-wizard should source gtd-guides.sh"

echo ""
echo "Testing that removed options are not in menu..."
WIZARD_CORE="$SCRIPT_DIR/../bin/gtd-wizard-core.sh"
test_assert_file_exists "$WIZARD_CORE" "gtd-wizard-core.sh should exist"
test_assert_failure "grep -q '31).*Log mood' $WIZARD_CORE" "Option 31 (Log mood) should be removed"
test_assert_failure "grep -q '32).*Log calendar' $WIZARD_CORE" "Option 32 (Log calendar) should be removed"
test_assert_failure "grep -q '33).*Collect all metrics' $WIZARD_CORE" "Option 33 (Collect all metrics) should be removed"
test_assert_failure "grep -q '42).*Daily tips' $WIZARD_CORE" "Option 42 (Daily tips) should be removed"
test_assert_failure "grep -q '44).*Morning routine' $WIZARD_CORE" "Option 44 (Morning routine) should be removed"
test_assert_failure "grep -q '45).*Afternoon routine' $WIZARD_CORE" "Option 45 (Afternoon routine) should be removed"
test_assert_failure "grep -q '46).*Evening routine' $WIZARD_CORE" "Option 46 (Evening routine) should be removed"
test_assert_failure "grep -q '47).*Evening summary' $WIZARD_CORE" "Option 47 (Evening summary) should be removed"

echo ""
echo "Testing that removed options are not in case statements..."
# Check that old functionality was removed (cases were renumbered/reused for new features)
test_assert_failure "grep -q 'Log mood\|Log Mood' $WIZARD_CORE" "Log mood functionality should be removed"
test_assert_failure "grep -q 'Log calendar\|Log Calendar' $WIZARD_CORE" "Log calendar functionality should be removed"
test_assert_failure "grep -q 'Collect all metrics\|Collect All Metrics' $WIZARD_CORE" "Collect all metrics functionality should be removed"
test_assert_failure "grep -q 'Daily tips\|Daily Tips' $WIZARD_CORE" "Daily tips option should be removed"
# Verify cases 31-33 exist but for different functionality (Morning/Afternoon/Evening Routine)
test_assert_success "grep -q '^      31)' $WIZARD_CORE" "Case 31 should exist for Morning Routine"
test_assert_success "grep -q '^      32)' $WIZARD_CORE" "Case 32 should exist for Afternoon Routine"
test_assert_success "grep -q '^      33)' $WIZARD_CORE" "Case 33 should exist for Evening Routine"
# Verify cases 44-47 exist but for different functionality
test_assert_success "grep -q '^      44)' $WIZARD_CORE" "Case 44 should exist for Deployment"
test_assert_success "grep -q '^      45)' $WIZARD_CORE" "Case 45 should exist for Collect All"
test_assert_success "grep -q '^      46)' $WIZARD_CORE" "Case 46 should exist for Quick Complete Habits"
test_assert_success "grep -q '^      47)' $WIZARD_CORE" "Case 47 should exist for Mood Log"

echo ""
echo "Testing that milestone celebration is now option 42..."
test_assert_success "grep -qi '42).*milestone' $WIZARD_CORE" "Option 42 should be Milestone celebration"
test_assert_success "grep -qi 'milestone_wizard' $WIZARD_CORE" "Case 42 should call milestone_wizard"

echo ""
echo "Testing dashboard function exists..."
test_assert_success "grep -q '^show_dashboard()' $WIZARD_CORE" "show_dashboard function should exist"
test_assert_success "grep -q 'show_dashboard' $WIZARD_CORE" "show_dashboard should be called in menu"

echo ""
echo "Testing 5 horizons integration in capture wizard..."
WIZARD_INPUTS="$SCRIPT_DIR/../bin/gtd-wizard-inputs.sh"
test_assert_file_exists "$WIZARD_INPUTS" "gtd-wizard-inputs.sh should exist"
test_assert_success "grep -q '5 Horizons of Focus' $WIZARD_INPUTS" "5 Horizons should be in capture wizard"
test_assert_success "grep -q 'horizon_context' $WIZARD_INPUTS" "horizon_context variable should be used"
test_assert_success "grep -qi '10,000.*ft\|10k.*ft' $WIZARD_INPUTS" "10k ft horizon should be mentioned"
test_assert_success "grep -qi '20,000.*ft\|20k.*ft' $WIZARD_INPUTS" "20k ft horizon should be mentioned"
test_assert_success "grep -qi '30,000.*ft\|30k.*ft' $WIZARD_INPUTS" "30k ft horizon should be mentioned"
test_assert_success "grep -qi '40,000.*ft\|40k.*ft' $WIZARD_INPUTS" "40k ft horizon should be mentioned"

echo ""
echo "Testing that wizard uses common helper functions..."
test_assert_success "grep -q 'gtd_get_today\|get_today' $WIZARD_CORE" "Wizard should use date helper"
test_assert_success "grep -q 'gtd_get_current_time\|get_current_time' $WIZARD_CORE" "Wizard should use time helper"

# Print summary
test_summary
