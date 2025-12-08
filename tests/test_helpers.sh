#!/bin/bash
# GTD System Test Helpers
# Common testing utilities for GTD scripts

# Test framework colors
TEST_PASS="${GREEN}✓${NC}"
TEST_FAIL="${RED}✗${NC}"
TEST_INFO="${CYAN}ℹ${NC}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Initialize test suite
test_init() {
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0
  echo "🧪 Starting test suite: $1"
  echo ""
}

# Run a test
test_run() {
  local test_name="$1"
  local test_command="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  echo -n "  Testing: $test_name ... "
  
  if eval "$test_command" >/dev/null 2>&1; then
    echo -e "${TEST_PASS} PASS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${TEST_FAIL} FAIL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Assert two values are equal
test_assert_equal() {
  local expected="$1"
  local actual="$2"
  local test_name="${3:-Values should be equal}"
  
  if [[ "$expected" == "$actual" ]]; then
    test_run "$test_name" "true"
    return 0
  else
    echo -e "    Expected: $expected"
    echo -e "    Actual: $actual"
    test_run "$test_name" "false"
    return 1
  fi
}

# Assert a file exists
test_assert_file_exists() {
  local file="$1"
  local test_name="${2:-File should exist: $file}"
  
  test_run "$test_name" "[[ -f '$file' ]]"
}

# Assert a directory exists
test_assert_dir_exists() {
  local dir="$1"
  local test_name="${2:-Directory should exist: $dir}"
  
  test_run "$test_name" "[[ -d '$dir' ]]"
}

# Assert a command succeeds
test_assert_success() {
  local command="$1"
  local test_name="${2:-Command should succeed}"
  
  test_run "$test_name" "$command"
}

# Assert a command fails
test_assert_failure() {
  local command="$1"
  local test_name="${2:-Command should fail}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  echo -n "  Testing: $test_name ... "
  
  if ! eval "$command" >/dev/null 2>&1; then
    echo -e "${TEST_PASS} PASS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${TEST_FAIL} FAIL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Print test summary
test_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Summary:"
  echo "  Total: $TESTS_RUN"
  echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}✗ Some tests failed${NC}"
    return 1
  fi
}

