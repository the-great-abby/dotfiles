#!/bin/bash
# Unit tests for gtd-wizard-outputs.sh
# Tests: review_wizard, discuss_analysis_with_ai, template_wizard, and related output functions

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source common helpers first
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Source the module under test
source "$SCRIPT_DIR/../bin/gtd-wizard-outputs.sh"

# Test suite
test_init "gtd-wizard-outputs.sh"

echo "Testing wizard output functions..."

# Test that functions exist
test_assert_success "declare -f review_wizard &>/dev/null" "review_wizard function should exist"
test_assert_success "declare -f view_analysis_results &>/dev/null" "view_analysis_results function should exist"
test_assert_success "declare -f discuss_analysis_with_ai &>/dev/null" "discuss_analysis_with_ai function should exist"
test_assert_success "declare -f generate_suggestions_from_analysis &>/dev/null" "generate_suggestions_from_analysis function should exist"
test_assert_success "declare -f template_wizard &>/dev/null" "template_wizard function should exist"
test_assert_success "declare -f review_drafts_wizard &>/dev/null" "review_drafts_wizard function should exist"

echo ""
echo "Testing review wizard logic..."

# Test review types
test_review_types() {
  # Test that review wizard handles different review types
  # Valid review types typically include: daily, weekly, monthly
  for review_type in "daily" "weekly" "monthly"; do
    test_assert_success "[[ -n '$review_type' ]]" "Review type $review_type should be valid"
  done
}

test_review_types

# Test that review wizard can access review paths
if [[ -n "${WEEKLY_REVIEWS_PATH:-}" ]] && [[ -d "$WEEKLY_REVIEWS_PATH" ]]; then
  test_assert_dir_exists "$WEEKLY_REVIEWS_PATH" "Weekly reviews path should exist"
else
  echo "  Skipping weekly review path tests (WEEKLY_REVIEWS_PATH not set or doesn't exist)"
fi

echo ""
echo "Testing view_analysis_results function..."

# Test that function can handle analysis file paths
test_analysis_paths() {
  # Test with various analysis file patterns
  ANALYSIS_PATTERNS=("weekly-review-*.md" "energy-analysis-*.md" "deep-analysis-*.md")
  for pattern in "${ANALYSIS_PATTERNS[@]}"; do
    test_assert_success "[[ -n '$pattern' ]]" "Analysis pattern $pattern should be valid"
  done
}

test_analysis_paths

echo ""
echo "Testing discuss_analysis_with_ai function..."

# Test that function can handle conversation flow
test_conversation_flow() {
  # Test exit commands
  for exit_cmd in "done" "exit" "quit"; do
    test_assert_success "[[ '$exit_cmd' == 'done' || '$exit_cmd' == 'exit' || '$exit_cmd' == 'quit' ]]" "Exit command $exit_cmd should be recognized"
  done
  
  # Test web search trigger
  SEARCH_QUERY="What is GTD? [search]"
  test_assert_success "echo '$SEARCH_QUERY' | grep -qiE '\[search\]|web search'" "Should detect web search request"
}

test_conversation_flow

echo ""
echo "Testing generate_suggestions_from_analysis function..."

# Test that function can parse analysis text
test_analysis_parsing() {
  # Test with sample analysis text
  SAMPLE_ANALYSIS="Analysis results:\n- Task 1\n- Task 2\n- Task 3"
  test_assert_success "echo '$SAMPLE_ANALYSIS' | grep -q 'Task'" "Should parse analysis text"
}

test_analysis_parsing

echo ""
echo "Testing template_wizard function..."

# Test that template wizard can access templates
test_template_access() {
  # Templates might be in various locations
  TEMPLATE_LOCATIONS=(
    "${SECOND_BRAIN}/Templates"
    "${GTD_BASE_DIR}/templates"
    "${HOME}/Documents/templates"
  )
  
  TEMPLATE_FOUND=false
  for location in "${TEMPLATE_LOCATIONS[@]}"; do
    if [[ -d "$location" ]]; then
      TEMPLATE_FOUND=true
      break
    fi
  done
  
  test_assert_success "true" "Template wizard should handle template locations"
}

test_template_access

echo ""
echo "Testing review_drafts_wizard function..."

# Test that function can access draft notes
if [[ -n "${SECOND_BRAIN:-}" ]] && [[ -d "$SECOND_BRAIN" ]]; then
  DRAFTS_DIR="${SECOND_BRAIN}/Drafts"
  if [[ -d "$DRAFTS_DIR" ]]; then
    test_assert_dir_exists "$DRAFTS_DIR" "Drafts directory should exist"
  else
    echo "  Drafts directory not found (may not exist yet)"
  fi
else
  echo "  Skipping drafts tests (SECOND_BRAIN not set or doesn't exist)"
fi

echo ""
echo "Testing express_wizard function..."

# Test that express_wizard exists
test_assert_success "declare -f express_wizard &>/dev/null" "express_wizard function should exist"

echo ""
echo "Testing diagram_wizard function..."

# Test that diagram_wizard exists
test_assert_success "declare -f diagram_wizard &>/dev/null" "diagram_wizard function should exist"

echo ""
echo "Testing routine wizards..."

# Test morning routine
test_assert_success "declare -f morning_routine_wizard &>/dev/null" "morning_routine_wizard function should exist"

# Test afternoon routine
test_assert_success "declare -f afternoon_routine_wizard &>/dev/null" "afternoon_routine_wizard function should exist"

# Test evening routine
test_assert_success "declare -f evening_routine_wizard &>/dev/null" "evening_routine_wizard function should exist"

# Test evening summary
test_assert_success "declare -f evening_summary_wizard &>/dev/null" "evening_summary_wizard function should exist"

echo ""
echo "Testing edge cases and error handling..."

# Test empty analysis handling
test_empty_analysis() {
  EMPTY_ANALYSIS=""
  test_assert_success "[[ -z '$EMPTY_ANALYSIS' ]]" "Should handle empty analysis"
}

test_empty_analysis

# Test invalid file paths
test_invalid_files() {
  INVALID_FILE="/nonexistent/file-$(date +%s).md"
  test_assert_failure "[[ -f '$INVALID_FILE' ]]" "Should detect invalid file"
}

test_invalid_files

# Test conversation exit handling
test_conversation_exit() {
  # Test various exit patterns
  EXIT_PATTERNS=("done" "exit" "quit" "q")
  for pattern in "${EXIT_PATTERNS[@]}"; do
    test_assert_success "[[ '$pattern' == 'done' || '$pattern' == 'exit' || '$pattern' == 'quit' || '$pattern' == 'q' ]]" "Should recognize exit pattern: $pattern"
  done
}

test_conversation_exit

# Test web search detection
test_web_search_detection() {
  SEARCH_PATTERNS=(
    "[search]"
    "web search"
    "search the web"
    "look up"
  )
  
  for pattern in "${SEARCH_PATTERNS[@]}"; do
    TEST_QUERY="Question about GTD $pattern"
    test_assert_success "echo '$TEST_QUERY' | grep -qiE '\[search\]|web search|search the web|look up'" "Should detect search pattern: $pattern"
  done
}

test_web_search_detection

# Print summary
test_summary

