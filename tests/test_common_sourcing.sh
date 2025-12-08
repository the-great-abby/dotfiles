#!/bin/bash
# Test that scripts properly source gtd-common.sh

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Test suite
test_init "Common File Sourcing"

echo "Testing that key scripts source gtd-common.sh..."

# Scripts that should source gtd-common.sh
SCRIPTS_TO_CHECK=(
  "bin/gtd-wizard"
  "bin/gtd-task"
  "bin/gtd-project"
  "bin/gtd-area"
  "bin/gtd-process"
  "bin/gtd-checkin"
  "bin/gtd-context"
  "bin/gtd-advise"
  "bin/gtd-daily-log"
  "bin/gtd-guides.sh"
)

for script in "${SCRIPTS_TO_CHECK[@]}"; do
  script_path="$SCRIPT_DIR/../$script"
  if [[ -f "$script_path" ]]; then
    # Check if script sources gtd-common.sh
    if grep -q "gtd-common.sh" "$script_path" || grep -q "GTD_COMMON" "$script_path"; then
      test_run "$(basename "$script") sources common file" "true"
    else
      test_run "$(basename "$script") sources common file" "false"
    fi
  else
    test_run "$(basename "$script") exists" "false"
  fi
done

echo ""
echo "Testing that scripts using common functions have common file sourced..."

# Check scripts that use common functions
SCRIPTS_USING_COMMON=(
  "bin/gtd-wizard:PROJECTS_PATH"
  "bin/gtd-task:gtd_get_today"
  "bin/gtd-project:gtd_get_today"
  "bin/gtd-area:gtd_get_today"
  "bin/gtd-process:GTD_BASE_DIR"
  "bin/gtd-checkin:gtd_print_"
  "bin/gtd-context:get_frontmatter_value"
)

for script_pattern in "${SCRIPTS_USING_COMMON[@]}"; do
  script="${script_pattern%%:*}"
  pattern="${script_pattern##*:}"
  script_path="$SCRIPT_DIR/../$script"
  
  if [[ -f "$script_path" ]]; then
    # Check if script uses the pattern
    if grep -q "$pattern" "$script_path"; then
      # Check if it also sources common
      if grep -q "gtd-common.sh\|GTD_COMMON" "$script_path"; then
        test_run "$(basename "$script") uses '$pattern' and sources common" "true"
      else
        test_run "$(basename "$script") uses '$pattern' but may not source common" "false"
      fi
    fi
  fi
done

# Print summary
test_summary
