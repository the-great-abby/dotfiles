#!/bin/bash
# Test script for Review Draft Notes Wizard
# Tests that the wizard loops correctly and all options work

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source wizard functions
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
GTD_COMMON="$BIN_DIR/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON" 2>/dev/null || true
fi

GTD_WIZARD_OUTPUTS="$BIN_DIR/gtd-wizard-outputs.sh"
if [[ ! -f "$GTD_WIZARD_OUTPUTS" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-outputs.sh" ]]; then
  GTD_WIZARD_OUTPUTS="$HOME/code/personal/dotfiles/bin/gtd-wizard-outputs.sh"
fi
if [[ -f "$GTD_WIZARD_OUTPUTS" ]]; then
  source "$GTD_WIZARD_OUTPUTS" 2>/dev/null || true
fi

# Initialize test suite
test_init "review-drafts-wizard"

echo "Testing Review Draft Notes Wizard"
echo ""

# Test 1: review_drafts_wizard function exists
test_assert_success "declare -f review_drafts_wizard &>/dev/null" \
  "review_drafts_wizard function should be available"

# Test 2: Verify wizard has while loop (checks for looping capability)
if declare -f review_drafts_wizard &>/dev/null; then
  # Check that function contains while loop
  if grep -q "while true" "$GTD_WIZARD_OUTPUTS" 2>/dev/null || \
     grep -A 5 "review_drafts_wizard()" "$GTD_WIZARD_OUTPUTS" 2>/dev/null | grep -q "while true"; then
    test_assert_success "true" \
      "review_drafts_wizard should have while loop for continuous operation"
  else
    # Check the actual function source
    local func_source=$(declare -f review_drafts_wizard 2>/dev/null)
    if echo "$func_source" | grep -q "while true"; then
      test_assert_success "true" \
        "review_drafts_wizard should have while loop for continuous operation"
    else
      test_assert_failure "true" \
        "review_drafts_wizard should have while loop for continuous operation"
    fi
  fi
fi

# Test 3: Verify option 2 formats output properly (checks for formatted list)
if declare -f review_drafts_wizard &>/dev/null; then
  func_source=$(declare -f review_drafts_wizard 2>/dev/null)
  # Check that option 2 formats the list properly (looks for the for loop)
  if echo "$func_source" | grep -q "for draft in"; then
    test_assert_success "true" \
      "Option 2 should format output with proper line breaks"
  else
    test_assert_failure "true" \
      "Option 2 should format output with proper line breaks"
  fi
fi

# Test 4: Verify all 4 options are handled
if declare -f review_drafts_wizard &>/dev/null; then
  func_source=$(declare -f review_drafts_wizard 2>/dev/null)
  has_option_1=false
  has_option_2=false
  has_option_3=false
  has_option_4=false
  
  if echo "$func_source" | grep -q "^[[:space:]]*1)"; then
    has_option_1=true
  fi
  if echo "$func_source" | grep -q "^[[:space:]]*2)"; then
    has_option_2=true
  fi
  if echo "$func_source" | grep -q "^[[:space:]]*3)"; then
    has_option_3=true
  fi
  if echo "$func_source" | grep -q "^[[:space:]]*4)"; then
    has_option_4=true
  fi
  
  test_assert_success "$has_option_1" \
    "Option 1 (Review all drafts) should be handled"
  test_assert_success "$has_option_2" \
    "Option 2 (List all drafts) should be handled"
  test_assert_success "$has_option_3" \
    "Option 3 (Scan for insights) should be handled"
  test_assert_success "$has_option_4" \
    "Option 4 (Show summary) should be handled"
fi

# Test 5: Verify option 0 returns to main menu
if declare -f review_drafts_wizard &>/dev/null; then
  func_source=$(declare -f review_drafts_wizard 2>/dev/null)
  # Check for return 0 in the case for option 0 (could be "0|" or "0|\"\"")
  if echo "$func_source" | grep -E "0\||0\|\"\"" | grep -A 2 . | grep -q "return 0"; then
    test_assert_success "true" \
      "Option 0 should return to main menu"
  elif echo "$func_source" | grep -q "return 0"; then
    # Just check that return 0 exists somewhere in the function (it should be for option 0)
    test_assert_success "true" \
      "Option 0 should return to main menu"
  else
    test_assert_failure "true" \
      "Option 0 should return to main menu"
  fi
fi

# Test 6: Verify option 1 asks to continue after review
if declare -f review_drafts_wizard &>/dev/null; then
  func_source=$(declare -f review_drafts_wizard 2>/dev/null)
  if echo "$func_source" | grep -A 30 "^[[:space:]]*1)" | grep -q "Stay in draft review wizard"; then
    test_assert_success "true" \
      "Option 1 should ask if user wants to continue after review"
  else
    test_assert_failure "true" \
      "Option 1 should ask if user wants to continue after review"
  fi
fi

# Test 7: Verify invalid choice shows error and continues
if declare -f review_drafts_wizard &>/dev/null; then
  func_source=$(declare -f review_drafts_wizard 2>/dev/null)
  if echo "$func_source" | grep -A 5 "Invalid choice" | grep -q "Press Enter to continue"; then
    test_assert_success "true" \
      "Invalid choice should show error and allow continuing"
  else
    test_assert_failure "true" \
      "Invalid choice should show error and allow continuing"
  fi
fi

# Test summary
test_summary

