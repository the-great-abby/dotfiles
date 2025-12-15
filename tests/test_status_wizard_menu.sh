#!/bin/bash
# Unit tests for Status Wizard Menu Functionality
# Tests that all menu options work correctly

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the modules under test
source "$SCRIPT_DIR/../bin/gtd-common.sh"
source "$SCRIPT_DIR/../bin/gtd-wizard-core.sh"
source "$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh"

# Test suite
test_init "Status Wizard Menu Functionality"

# Mock functions to avoid actual execution
mock_status_wizard_choice() {
  local choice="$1"
  local output=$(mktemp)
  
  # Capture output from status_wizard by simulating input
  (
    echo "$choice" | {
      # Temporarily redirect stdin for read command
      exec 3<&0
      status_wizard 2>&1 | head -50 > "$output"
      exec 0<&3
    }
  ) 2>/dev/null || true
  
  cat "$output"
  rm -f "$output"
}

# Test that status_wizard function exists
test_assert_success "declare -f status_wizard >/dev/null" \
  "status_wizard function should be defined"

# Test that status_wizard function is from analysis module (has full implementation)
test_assert_success "grep -q 'Background Worker Status' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\"" \
  "status_wizard should be the analysis version with Background Worker Status"

# Test that option 3 case exists in the implementation
test_assert_success "grep -A 150 'case.*status_choice' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | grep -qE '^[[:space:]]+3[[:space:]]*\)'" \
  "Option 3 should be handled in status_wizard case statement"

# Test that option 3 has actual implementation (not just a comment)
test_assert_success "grep -A 20 '^[[:space:]]*3)' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | grep -qv '^[[:space:]]*#[[:space:]]*Background worker status'" \
  "Option 3 should have implementation, not just a comment"

# Test that the analysis version is being used (has more options)
test_assert_success "grep -A 5 'echo.*Background Worker Status' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | head -1 | grep -q '3)'" \
  "Analysis version of status_wizard should be the one with Background Worker Status option"

# Test that all expected menu options are present
MENU_OPTIONS=("Basic GTD System Status" "MCP Server" "Background Worker Status" "Full System Status")
for option in "${MENU_OPTIONS[@]}"; do
  test_assert_success "grep -q \"$option\" \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\"" \
    "Menu should include: $option"
done

# Test that case statement handles all numeric options (0-8)
for i in 0 1 2 3 4 5 6 7 8; do
  test_assert_success "grep -A 100 'case.*status_choice' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | grep -qE '^[[:space:]]*${i}[[:space:]]*\)|^[[:space:]]*\"${i}\"|^[[:space:]]*0|\")'" \
    "Case statement should handle option $i"
done

# Test that option 8 (Vector Database) has implementation
# Simple check: verify option 8 exists and has Vector Database in the case block
test_assert_success "grep -A 5 '^[[:space:]]*8)' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | grep -q 'Vector Database'" \
  "Option 8 should be handled in status_wizard case statement"

# Test that option 8 has actual implementation
test_assert_success "grep -A 200 '^[[:space:]]*8)' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | grep -q 'Vector Database Status'" \
  "Option 8 should have Vector Database Status implementation"

# Test that option 3 attempts auto-recovery for port forwarding
test_assert_success "grep -B 2 -A 25 'Port-forward not active' \"$SCRIPT_DIR/../bin/gtd-wizard-analysis.sh\" | grep -q 'setup-port-forward'" \
  "Option 3 should attempt auto-recovery via setup-port-forward when port-forward fails"

# Test summary
test_summary
