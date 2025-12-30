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

# Run bash test files
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

# Get MCP Python (virtualenv if available, otherwise system Python)
# Source gtd-common.sh to get gtd_get_mcp_python function
GTD_COMMON="$HOME/code/dotfiles/bin/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON" 2>/dev/null || true
fi

# Get Python command (prefer MCP virtualenv)
if command -v gtd_get_mcp_python &>/dev/null; then
  PYTHON_CMD=$(gtd_get_mcp_python)
else
  # Fallback: check for MCP virtualenv directly
  MCP_VENV_PYTHON="$HOME/code/dotfiles/mcp/venv/bin/python3"
  if [[ ! -f "$MCP_VENV_PYTHON" ]]; then
    MCP_VENV_PYTHON="$HOME/code/personal/dotfiles/mcp/venv/bin/python3"
  fi
  if [[ -f "$MCP_VENV_PYTHON" ]]; then
    PYTHON_CMD="$MCP_VENV_PYTHON"
  else
    PYTHON_CMD="python3"
  fi
fi

# Run Python test files
# Skip memory-intensive database tests in full test suite - run them individually if needed
SKIP_TESTS=("test_gtd_vectorization.py" "test_gtd_vectorization_db.py")

for test_file in "$SCRIPT_DIR"/test_*.py; do
  if [[ -f "$test_file" ]]; then
    test_basename=$(basename "$test_file")
    
    # Skip memory-intensive tests
    skip_test=false
    for skip_pattern in "${SKIP_TESTS[@]}"; do
      if [[ "$test_basename" == "$skip_pattern" ]]; then
        skip_test=true
        break
      fi
    done
    
    if [[ "$skip_test" == true ]]; then
      echo -e "${YELLOW}Skipping: $test_basename${NC} (memory-intensive, run individually if needed)"
      echo ""
      continue
    fi
    
    echo -e "${YELLOW}Running: $test_basename${NC}"
    echo -e "${GRAY}Using: $PYTHON_CMD${NC}"
    echo ""
    
    if "$PYTHON_CMD" "$test_file" 2>&1; then
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

