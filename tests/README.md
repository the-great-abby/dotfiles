# GTD System Testing

This directory contains unit tests for the GTD system to ensure consistent behavior across all scripts.

## Running Tests

Run all tests:
```bash
./tests/run_tests.sh
```

Run individual test suites:
```bash
./tests/test_gtd_common.sh
./tests/test_gtd_guides.sh
./tests/test_wizard_functions.sh
```

## Test Structure

- `test_helpers.sh` - Common testing utilities and assertions
- `test_gtd_common.sh` - Tests for `gtd-common.sh` helper library
- `test_gtd_guides.sh` - Tests for `gtd-guides.sh` guide functions
- `test_wizard_functions.sh` - Tests that all wizard menu functions are defined and available
- `run_tests.sh` - Test runner that executes all test suites

## Adding New Tests

1. Create a new test file: `test_<module_name>.sh`
2. Source `test_helpers.sh` for testing utilities
3. Source the module you're testing
4. Use test functions like `test_assert_equal`, `test_assert_success`, etc.
5. Call `test_init` at the start and `test_summary` at the end

Example:
```bash
#!/bin/bash
source "$(dirname "$0")/test_helpers.sh"
source "$(dirname "$0")/../bin/gtd-common.sh"

test_init "my-module"
test_assert_success "[[ -n '$GTD_BASE_DIR' ]]" "GTD_BASE_DIR should be set"
test_summary
```

## Test Coverage

Current test coverage includes:

### gtd-common.sh Tests (38 tests)
- ✅ Configuration loading (GTD_BASE_DIR, PROJECTS_PATH, AREAS_PATH, etc.)
- ✅ Color definitions (CYAN, GREEN, YELLOW, RED, NC)
- ✅ Menu navigation (push, pop, breadcrumb display)
- ✅ Display helpers (print_divider, print_header, print_success, print_error, print_info, print_warning)
- ✅ Date/time helpers (get_today, get_current_time, get_date_cmd)
- ✅ Python helper (get_mcp_python)
- ✅ Frontmatter helper (get_frontmatter_value with test file)
- ✅ Path initialization (INBOX_PATH, REFERENCE_PATH, SOMEDAY_PATH, WAITING_PATH, ARCHIVE_PATH, SECOND_BRAIN)
- ✅ Second Brain helpers (get_moc_names, get_second_brain_notes)

### gtd-guides.sh Tests (40 tests)
- ✅ All guide functions (40 total guides including new Second Brain guides)

### Script Integration Tests (28 tests)
- ✅ Common helpers availability in scripts
- ✅ Script existence and executability
- ✅ Script syntax validation

### Common File Sourcing Tests (17 tests)
- ✅ Verification that key scripts source gtd-common.sh
- ✅ Verification that scripts using common functions properly source the common file

### gtd-wizard Modularity Tests (49 tests)
- ✅ Modularity verification (wizard dependencies on gtd-common.sh and gtd-guides.sh)
- ✅ Guide functions availability
- ✅ Menu navigation functions
- ✅ Wizard script syntax validation
- ✅ Source file verification (gtd-common.sh and gtd-guides.sh)
- ✅ Removed options verification (31, 32, 33, 42, 44, 45, 46, 47)
- ✅ Menu option numbering verification (milestone celebration is now 42)
- ✅ Dashboard function existence and integration
- ✅ 5 Horizons integration in capture wizard
- ✅ Common helper function usage

### Wizard Helper Functions Tests (19 tests)
- ✅ select_from_numbered_list function logic
- ✅ mark_suggestion functions (Python availability and JSON parsing)
- ✅ Dashboard data collection
- ✅ Horizon context parsing logic (project, area, goal, vision contexts)
- ✅ Guide function wrappers

### Wizard Menu Function Availability Tests (59 tests)
- ✅ Verification that all 59 wizard menu functions are defined and available
- ✅ Ensures all menu items in `gtd-wizard-core.sh` have corresponding function implementations
- ✅ Checks function availability after sourcing all wizard modules
- ✅ Validates proper file sourcing order (matches `gtd-wizard` entry point)
- ✅ Confirms no missing function implementations

**Total: 250 tests across 7 test suites**

