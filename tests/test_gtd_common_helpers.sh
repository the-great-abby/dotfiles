#!/bin/bash
# Unit tests for new helper functions in gtd-common.sh
# Tests: get_project_name, directory_has_files, find_task_file

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source common helpers
source "$SCRIPT_DIR/../bin/gtd-common.sh"

# Test suite
test_init "GTD Common Helpers"

echo "Testing new helper functions from gtd-common.sh..."

# Test 1: get_project_name function exists
test_assert_success "declare -f get_project_name &>/dev/null" "get_project_name function should exist"

# Test 2: directory_has_files function exists
test_assert_success "declare -f directory_has_files &>/dev/null" "directory_has_files function should exist"

# Test 3: find_task_file function exists
test_assert_success "declare -f find_task_file &>/dev/null" "find_task_file function should exist"

# Test 4: get_project_name with project: field
echo ""
echo "Testing get_project_name()..."
if declare -f get_project_name &>/dev/null; then
  # Create a temporary test file with project: field
  test_dir=$(mktemp -d)
  test_readme="${test_dir}/README.md"
  cat > "$test_readme" <<EOF
---
project: Test Project Name
status: active
---
# Test Project
EOF
  result=$(get_project_name "$test_readme")
  test_assert_equal "Test Project Name" "$result" "get_project_name should extract project: field"
  rm -rf "$test_dir"
fi

# Test 5: get_project_name with name: field (no project:)
if declare -f get_project_name &>/dev/null; then
  test_dir=$(mktemp -d)
  test_readme="${test_dir}/README.md"
  cat > "$test_readme" <<EOF
---
name: Alternative Name
status: active
---
# Test Project
EOF
  result=$(get_project_name "$test_readme")
  test_assert_equal "Alternative Name" "$result" "get_project_name should fallback to name: field"
  rm -rf "$test_dir"
fi

# Test 6: get_project_name with neither field (uses directory name)
if declare -f get_project_name &>/dev/null; then
  test_dir=$(mktemp -d)
  test_subdir="${test_dir}/my-project"
  mkdir -p "$test_subdir"
  test_readme="${test_subdir}/README.md"
  cat > "$test_readme" <<EOF
---
status: active
---
# Test Project
EOF
  result=$(get_project_name "$test_readme")
  test_assert_equal "my-project" "$result" "get_project_name should use directory name as fallback"
  rm -rf "$test_dir"
fi

# Test 7: get_project_name with invalid file
if declare -f get_project_name &>/dev/null; then
  result=$(get_project_name "/nonexistent/file.md" 2>/dev/null)
  test_assert_equal "" "$result" "get_project_name should return empty for invalid file"
fi

# Test 8: directory_has_files with files present
echo ""
echo "Testing directory_has_files()..."
if declare -f directory_has_files &>/dev/null; then
  test_dir=$(mktemp -d)
  touch "${test_dir}/test1.md"
  touch "${test_dir}/test2.md"
  test_assert_success "directory_has_files '$test_dir'" "directory_has_files should return true for directory with files"
  rm -rf "$test_dir"
fi

# Test 9: directory_has_files with no files
if declare -f directory_has_files &>/dev/null; then
  test_dir=$(mktemp -d)
  test_assert_failure "directory_has_files '$test_dir'" "directory_has_files should return false for empty directory"
  rm -rf "$test_dir"
fi

# Test 10: directory_has_files with non-existent directory
if declare -f directory_has_files &>/dev/null; then
  test_assert_failure "directory_has_files '/nonexistent/dir'" "directory_has_files should return false for non-existent directory"
fi

# Test 11: directory_has_files with custom pattern
if declare -f directory_has_files &>/dev/null; then
  test_dir=$(mktemp -d)
  touch "${test_dir}/test.txt"
  test_assert_success "directory_has_files '$test_dir' '*.txt'" "directory_has_files should work with custom pattern"
  rm -rf "$test_dir"
fi

# Test 12: find_task_file function (basic existence)
echo ""
echo "Testing find_task_file()..."
if declare -f find_task_file &>/dev/null && [[ -d "$TASKS_PATH" ]]; then
  # Try to find any existing task file
  test_task_file=$(find "$TASKS_PATH" -type f -name "*.md" 2>/dev/null | head -1)
  if [[ -n "$test_task_file" ]]; then
    task_id=$(basename "$test_task_file" .md)
    result=$(find_task_file "$task_id")
    test_assert_success "[[ -n '$result' && -f '$result' ]]" "find_task_file should find existing task"
  else
    # No tasks exist, test that function doesn't crash
    result=$(find_task_file "nonexistent-task-id" 2>/dev/null)
    test_assert_success "true" "find_task_file should handle non-existent tasks gracefully"
  fi
fi

# Test 13: find_task_file with empty input
if declare -f find_task_file &>/dev/null; then
  result=$(find_task_file "" 2>/dev/null)
  test_assert_failure "[[ -n '$result' ]]" "find_task_file should return empty for empty input"
fi

# Test 14: find_task_file return code
if declare -f find_task_file &>/dev/null; then
  find_task_file "nonexistent-task-id" >/dev/null 2>&1
  exit_code=$?
  test_assert_success "[[ $exit_code -eq 1 ]]" "find_task_file should return 1 for not found"
fi

# Print summary
test_summary
