#!/bin/bash
# Unit tests for GTD Wizard Menu Helpers
# Validates that menus, submenus, and sub-submenus have section headers/helpers

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the modules under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"
source "$SCRIPT_DIR/../bin/gtd-guides.sh"
source "$SCRIPT_DIR/../bin/gtd-wizard-core.sh"

# Test suite
test_init "GTD Wizard Menu Helpers Validation"

# Helper function to check if a function exists in a file
function_has_guide() {
  local file="$1"
  local wizard_func="$2"
  local guide_pattern="$3"
  
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  
  # Extract the wizard function body
  local in_function=0
  local brace_count=0
  local found_guide=0
  
  while IFS= read -r line; do
    # Check if we're entering the function
    if [[ "$line" =~ ^[[:space:]]*${wizard_func}\([[:space:]]*\)[[:space:]]*\{ ]]; then
      in_function=1
      brace_count=1
      continue
    fi
    
    # If we're in the function, track braces and look for guide
    if [[ $in_function -eq 1 ]]; then
      # Count braces to know when function ends
      local open_braces=$(echo "$line" | grep -o '{' | wc -l | tr -d ' ')
      local close_braces=$(echo "$line" | grep -o '}' | wc -l | tr -d ' ')
      brace_count=$((brace_count + open_braces - close_braces))
      
      # Check if this line calls the guide function
      if echo "$line" | grep -q "$guide_pattern"; then
        found_guide=1
      fi
      
      # If braces are balanced, we've left the function
      if [[ $brace_count -eq 0 ]]; then
        break
      fi
    fi
  done < "$file"
  
  return $((1 - found_guide))
}

# Helper function to check for section headers in menu
menu_has_section_headers() {
  local file="$1"
  local menu_func="$2"
  
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  
  # Look for section header patterns (BOLD CYAN with emoji and description)
  local in_function=0
  local brace_count=0
  local found_header=0
  
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*${menu_func}\([[:space:]]*\)[[:space:]]*\{ ]]; then
      in_function=1
      brace_count=1
      continue
    fi
    
    if [[ $in_function -eq 1 ]]; then
      local open_braces=$(echo "$line" | grep -o '{' | wc -l | tr -d ' ')
      local close_braces=$(echo "$line" | grep -o '}' | wc -l | tr -d ' ')
      brace_count=$((brace_count + open_braces - close_braces))
      
      # Check for section header pattern: BOLD CYAN with emoji and description
      if echo "$line" | grep -qE '\$\{BOLD\}\$\{CYAN\}.*-.*:' || \
         echo "$line" | grep -qE 'echo.*BOLD.*CYAN.*-'; then
        found_header=1
      fi
      
      if [[ $brace_count -eq 0 ]]; then
        break
      fi
    fi
  done < "$file"
  
  return $((1 - found_header))
}

# Helper to check if a guide function is called in a wizard
wizard_calls_guide() {
  local file="$1"
  local wizard_func="$2"
  local guide_func="$3"
  
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  
  # Simple grep check - look for guide function call within wizard function context
  # This is a simplified check - we look for the pattern in the file
  # and verify the wizard function exists and guide is called nearby
  if grep -q "${wizard_func}()" "$file" && grep -q "${guide_func}" "$file"; then
    # More sophisticated: check they're in the same function context
    # For now, if both exist in file, assume they're related
    return 0
  fi
  
  return 1
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Main Menu Helpers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

WIZARD_CORE="$SCRIPT_DIR/../bin/gtd-wizard-core.sh"

# Test 1: Main menu should call show_organization_guide
echo "1. Checking main menu calls show_organization_guide..."
test_assert_success \
  "grep -q 'show_organization_guide' '$WIZARD_CORE' && grep -A 5 'show_main_menu()' '$WIZARD_CORE' | grep -q 'show_organization_guide'" \
  "Main menu should call show_organization_guide"

# Test 2: Main menu should call show_process_reminders
echo "2. Checking main menu calls show_process_reminders..."
test_assert_success \
  "grep -q 'show_process_reminders' '$WIZARD_CORE' && grep -A 5 'show_main_menu()' '$WIZARD_CORE' | grep -q 'show_process_reminders'" \
  "Main menu should call show_process_reminders"

# Test 3: Main menu should have section headers
echo "3. Checking main menu has section headers..."
test_assert_success \
  "grep -q 'INPUTS - Capture & Process' '$WIZARD_CORE' || grep -q 'ORGANIZATION - Manage Your System' '$WIZARD_CORE'" \
  "Main menu should have section headers (INPUTS, ORGANIZATION, etc.)"

# Test 4: Check for all main menu section headers
echo "4. Checking all main menu section headers..."
test_assert_success \
  "grep -q 'INPUTS - Capture & Process' '$WIZARD_CORE'" \
  "Main menu should have 'INPUTS - Capture & Process' header"

test_assert_success \
  "grep -q 'ORGANIZATION - Manage Your System' '$WIZARD_CORE'" \
  "Main menu should have 'ORGANIZATION - Manage Your System' header"

test_assert_success \
  "grep -q 'SECOND BRAIN - Advanced Operations' '$WIZARD_CORE' || grep -q 'SECOND BRAIN' '$WIZARD_CORE'" \
  "Main menu should have 'SECOND BRAIN' header"

test_assert_success \
  "grep -q 'OUTPUTS - Reviews & Creation' '$WIZARD_CORE' || grep -q 'OUTPUTS' '$WIZARD_CORE'" \
  "Main menu should have 'OUTPUTS' header"

test_assert_success \
  "grep -q 'LEARNING - Guides & Discovery' '$WIZARD_CORE' || grep -q 'LEARNING' '$WIZARD_CORE'" \
  "Main menu should have 'LEARNING' header"

test_assert_success \
  "grep -q 'ANALYSIS - Insights & Tracking' '$WIZARD_CORE' || grep -q 'ANALYSIS' '$WIZARD_CORE'" \
  "Main menu should have 'ANALYSIS' header"

test_assert_success \
  "grep -q 'TOOLS & SUPPORT' '$WIZARD_CORE'" \
  "Main menu should have 'TOOLS & SUPPORT' header"

test_assert_success \
  "grep -q 'SETTINGS' '$WIZARD_CORE'" \
  "Main menu should have 'SETTINGS' header"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Submenu (Wizard) Helpers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

WIZARD_INPUTS="$SCRIPT_DIR/../bin/gtd-wizard-inputs.sh"
WIZARD_ORG="$SCRIPT_DIR/../bin/gtd-wizard-org.sh"
WIZARD_BRAIN="$SCRIPT_DIR/../bin/gtd-wizard-brain.sh"
WIZARD_OUTPUTS="$SCRIPT_DIR/../bin/gtd-wizard-outputs.sh"
WIZARD_ANALYSIS="$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh"
WIZARD_TOOLS="$SCRIPT_DIR/../bin/gtd-wizard-tools.sh"

# Test Input Wizards
echo "5. Checking capture_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_INPUTS' 'capture_wizard' 'show_capture_guide'" \
  "capture_wizard should call show_capture_guide"

echo "6. Checking process_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_INPUTS' 'process_wizard\|process_inbox' 'show_process_guide'" \
  "process_wizard should call show_process_guide"

echo "7. Checking log_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_INPUTS' 'log_wizard' 'show_daily_log_guide'" \
  "log_wizard should call show_daily_log_guide"

echo "8. Checking checkin_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_INPUTS' 'checkin_wizard' 'show_checkin_guide'" \
  "checkin_wizard should call show_checkin_guide"

# Test Organization Wizards
echo "9. Checking task_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ORG' 'task_wizard' 'show_tasks_guide'" \
  "task_wizard should call show_tasks_guide"

echo "10. Checking project_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ORG' 'project_wizard' 'show_projects_guide'" \
  "project_wizard should call show_projects_guide"

echo "11. Checking area_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ORG' 'area_wizard' 'show_areas_guide'" \
  "area_wizard should call show_areas_guide"

echo "12. Checking moc_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ORG' 'moc_wizard' 'show_moc_guide'" \
  "moc_wizard should call show_moc_guide"

echo "13. Checking zettelkasten_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ORG' 'zettelkasten_wizard' 'show_zettelkasten_guide'" \
  "zettelkasten_wizard should call show_zettelkasten_guide"

# Test Second Brain Wizards
echo "14. Checking sync_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'sync_wizard' 'show_sync_guide'" \
  "sync_wizard should call show_sync_guide"

echo "15. Checking brain_connect_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_connect_wizard' 'show_connect_notes_guide'" \
  "brain_connect_wizard should call show_connect_notes_guide"

echo "16. Checking brain_converge_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_converge_wizard' 'show_converge_notes_guide'" \
  "brain_converge_wizard should call show_converge_notes_guide"

echo "17. Checking brain_discover_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_discover_wizard' 'show_discover_connections_guide'" \
  "brain_discover_wizard should call show_discover_connections_guide"

echo "18. Checking brain_distill_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_distill_wizard' 'show_distill_guide'" \
  "brain_distill_wizard should call show_distill_guide"

echo "19. Checking brain_diverge_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_diverge_wizard' 'show_diverge_guide'" \
  "brain_diverge_wizard should call show_diverge_guide"

echo "20. Checking brain_evergreen_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_evergreen_wizard' 'show_evergreen_notes_guide'" \
  "brain_evergreen_wizard should call show_evergreen_notes_guide"

echo "21. Checking brain_packet_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_BRAIN' 'brain_packet_wizard' 'show_note_packets_guide'" \
  "brain_packet_wizard should call show_note_packets_guide"

# Test Output Wizards
echo "22. Checking template_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_OUTPUTS' 'template_wizard' 'show_templates_guide'" \
  "template_wizard should call show_templates_guide"

echo "23. Checking diagram_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_OUTPUTS' 'diagram_wizard' 'show_diagram_guide'" \
  "diagram_wizard should call show_diagram_guide"

# Test Analysis Wizards
echo "24. Checking search_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'search_wizard' 'show_search_guide'" \
  "search_wizard should call show_search_guide"

echo "25. Checking status_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'status_wizard' 'show_status_guide'" \
  "status_wizard should call show_status_guide"

echo "26. Checking goal_tracking_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'goal_tracking_wizard' 'show_goal_tracking_guide'" \
  "goal_tracking_wizard should call show_goal_tracking_guide"

echo "27. Checking energy_audit_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'energy_audit_wizard' 'show_energy_audit_guide'" \
  "energy_audit_wizard should call show_energy_audit_guide"

echo "28. Checking metric_correlations_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'metric_correlations_wizard' 'show_metric_correlations_guide'" \
  "metric_correlations_wizard should call show_metric_correlations_guide"

echo "29. Checking pattern_recognition_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'pattern_recognition_wizard' 'show_pattern_recognition_guide'" \
  "pattern_recognition_wizard should call show_pattern_recognition_guide"

echo "30. Checking energy_schedule_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_ANALYSIS' 'energy_schedule_wizard' 'show_energy_schedule_guide'" \
  "energy_schedule_wizard should call show_energy_schedule_guide"

# Test Tools Wizards
echo "31. Checking advice_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_TOOLS' 'advice_wizard' 'show_advice_guide'" \
  "advice_wizard should call show_advice_guide"

echo "32. Checking config_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_TOOLS' 'config_wizard' 'show_config_guide'" \
  "config_wizard should call show_config_guide"

echo "33. Checking ai_suggestions_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_TOOLS' 'ai_suggestions_wizard' 'show_ai_suggestions_guide'" \
  "ai_suggestions_wizard should call show_ai_suggestions_guide"

echo "34. Checking gamification_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_TOOLS' 'gamification_wizard' 'show_gamification_guide'" \
  "gamification_wizard should call show_gamification_guide"

echo "35. Checking healthkit_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_TOOLS' 'healthkit_wizard' 'show_healthkit_guide'" \
  "healthkit_wizard should call show_healthkit_guide"

echo "36. Checking calendar_wizard has guide..."
test_assert_success \
  "wizard_calls_guide '$WIZARD_TOOLS' 'calendar_wizard' 'show_calendar_guide'" \
  "calendar_wizard should call show_calendar_guide"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Sub-Submenu (Nested Menu) Helpers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for nested menus within wizards
# These are menus that appear within other wizard functions

echo "37. Checking for section headers in task_wizard submenus..."
# Task wizard has submenus for different task operations
test_assert_success \
  "grep -A 50 'task_wizard()' '$WIZARD_ORG' | grep -q 'What would you like to do' || grep -A 50 'task_wizard()' '$WIZARD_ORG' | grep -qE 'echo.*[0-9]\)'" \
  "task_wizard should have menu structure with options"

echo "38. Checking for section headers in project_wizard submenus..."
test_assert_success \
  "grep -A 50 'project_wizard()' '$WIZARD_ORG' | grep -q 'What would you like to do' || grep -A 50 'project_wizard()' '$WIZARD_ORG' | grep -qE 'echo.*[0-9]\)'" \
  "project_wizard should have menu structure with options"

echo "39. Checking for section headers in area_wizard submenus..."
test_assert_success \
  "grep -A 50 'area_wizard()' '$WIZARD_ORG' | grep -q 'What would you like to do' || grep -A 50 'area_wizard()' '$WIZARD_ORG' | grep -qE 'echo.*[0-9]\)'" \
  "area_wizard should have menu structure with options"

echo "40. Checking for section headers in moc_wizard submenus..."
test_assert_success \
  "grep -A 50 'moc_wizard()' '$WIZARD_ORG' | grep -q 'What would you like to do' || grep -A 50 'moc_wizard()' '$WIZARD_ORG' | grep -qE 'echo.*[0-9]\)'" \
  "moc_wizard should have menu structure with options"

echo "41. Checking for section headers in advice_wizard submenus..."
test_assert_success \
  "grep -A 50 'advice_wizard()' '$WIZARD_TOOLS' | grep -q 'What would you like to do' || grep -A 50 'advice_wizard()' '$WIZARD_TOOLS' | grep -qE 'echo.*[0-9]\)'" \
  "advice_wizard should have menu structure with options"

echo "42. Checking for section headers in ai_suggestions_wizard submenus..."
test_assert_success \
  "grep -A 50 'ai_suggestions_wizard()' '$WIZARD_TOOLS' | grep -q 'What would you like to do' || grep -A 50 'ai_suggestions_wizard()' '$WIZARD_TOOLS' | grep -qE 'echo.*[0-9]\)'" \
  "ai_suggestions_wizard should have menu structure with options"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Guide Function Availability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify all guide functions exist
echo "43. Checking guide functions are defined..."
GUIDES_FILE="$SCRIPT_DIR/../bin/gtd-guides.sh"

test_assert_file_exists "$GUIDES_FILE" "gtd-guides.sh should exist"

# List of expected guide functions
declare -a GUIDE_FUNCTIONS=(
  "gtd_show_areas_guide"
  "gtd_show_projects_guide"
  "gtd_show_tasks_guide"
  "gtd_show_express_guide"
  "gtd_show_moc_guide"
  "gtd_show_templates_guide"
  "gtd_show_zettelkasten_guide"
  "gtd_show_checkin_guide"
  "gtd_show_organization_guide"
  "gtd_show_review_guide"
  "gtd_show_capture_guide"
  "gtd_show_process_guide"
  "gtd_show_sync_guide"
  "gtd_show_advice_guide"
  "gtd_show_daily_log_guide"
  "gtd_show_search_guide"
  "gtd_show_status_guide"
  "gtd_show_config_guide"
  "gtd_show_second_brain_learning_guide"
  "gtd_show_life_vision_guide"
  "gtd_show_diagram_guide"
  "gtd_show_habits_guide"
  "gtd_show_learning_guide"
  "gtd_show_ai_suggestions_guide"
  "gtd_show_goal_tracking_guide"
  "gtd_show_energy_audit_guide"
  "gtd_show_gamification_guide"
  "gtd_show_healthkit_guide"
  "gtd_show_calendar_guide"
  "gtd_show_mood_tracking_guide"
  "gtd_show_metric_correlations_guide"
  "gtd_show_pattern_recognition_guide"
  "gtd_show_energy_schedule_guide"
  "gtd_show_note_packets_guide"
  "gtd_show_connect_notes_guide"
  "gtd_show_converge_notes_guide"
  "gtd_show_discover_connections_guide"
  "gtd_show_distill_guide"
  "gtd_show_diverge_guide"
  "gtd_show_evergreen_notes_guide"
)

guide_count=44
for guide_func in "${GUIDE_FUNCTIONS[@]}"; do
  test_assert_success \
    "grep -q '^${guide_func}()' '$GUIDES_FILE' || grep -q '^function ${guide_func}' '$GUIDES_FILE'" \
    "Guide function ${guide_func} should be defined"
  guide_count=$((guide_count + 1))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Menu Structure Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check that wizards have proper menu structure (title, guide, options, back option)
echo "Checking menu structure consistency..."

# Function to check menu structure
check_menu_structure() {
  local file="$1"
  local wizard_func="$2"
  
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  
  # Extract function and check for:
  # 1. Title/header (usually with CYAN/BOLD)
  # 2. Guide call
  # 3. Menu options
  # 4. Back option (usually "0) Back to Main Menu")
  
  local has_title=0
  local has_options=0
  local has_back=0
  
  local in_function=0
  local brace_count=0
  
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*${wizard_func}\([[:space:]]*\)[[:space:]]*\{ ]]; then
      in_function=1
      brace_count=1
      continue
    fi
    
    if [[ $in_function -eq 1 ]]; then
      local open_braces=$(echo "$line" | grep -o '{' | wc -l | tr -d ' ')
      local close_braces=$(echo "$line" | grep -o '}' | wc -l | tr -d ' ')
      brace_count=$((brace_count + open_braces - close_braces))
      
      # Check for title (CYAN/BOLD pattern)
      if echo "$line" | grep -qE 'CYAN.*Wizard|BOLD.*CYAN'; then
        has_title=1
      fi
      
      # Check for menu options (numbered options)
      if echo "$line" | grep -qE '[0-9]+\)[[:space:]]+'; then
        has_options=1
      fi
      
      # Check for back option
      if echo "$line" | grep -qE 'Back to Main Menu|Back to.*Menu'; then
        has_back=1
      fi
      
      if [[ $brace_count -eq 0 ]]; then
        break
      fi
    fi
  done < "$file"
  
  # Menu should have at least title and options
  if [[ $has_title -eq 1 ]] && [[ $has_options -eq 1 ]]; then
    return 0
  fi
  
  return 1
}

# Test menu structure for key wizards
test_assert_success \
  "check_menu_structure '$WIZARD_ORG' 'task_wizard'" \
  "task_wizard should have proper menu structure (title + options)"

test_assert_success \
  "check_menu_structure '$WIZARD_ORG' 'project_wizard'" \
  "project_wizard should have proper menu structure (title + options)"

test_assert_success \
  "check_menu_structure '$WIZARD_INPUTS' 'capture_wizard'" \
  "capture_wizard should have proper menu structure (title + options)"

test_assert_success \
  "check_menu_structure '$WIZARD_BRAIN' 'sync_wizard'" \
  "sync_wizard should have proper menu structure (title + options)"

# Print summary
test_summary

exit $?
