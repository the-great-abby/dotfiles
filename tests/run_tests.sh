#!/bin/bash
# Run all GTD system tests

# Source test helpers for colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}🧪 GTD System Test Suite${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track overall results
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

# Run each test file
for test_file in "$SCRIPT_DIR"/test_*.sh; do
  if [[ -f "$test_file" && "$(basename "$test_file")" != "test_helpers.sh" ]]; then
    echo -e "${YELLOW}Running: $(basename "$test_file")${NC}"
    echo ""
    
    if bash "$test_file"; then
      TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
      TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
  fi
done

# Print overall summary
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Overall Test Suite Summary:${NC}"
echo "  Test Suites Run: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $TOTAL_PASSED${NC}"
echo -e "  ${RED}Failed: $TOTAL_FAILED${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All test suites passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some test suites failed${NC}"
  exit 1
fi

