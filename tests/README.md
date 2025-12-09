# GTD System Testing

This directory contains unit tests for the GTD system to ensure consistent behavior across all scripts.

## Running Tests

### From the Wizard (Recommended)

You can run tests directly from the GTD Wizard:
1. Run `gtd-wizard`
2. Select option **61) 🧪 Run Unit Tests**
3. Choose which test suite to run

This provides an interactive menu to run:
- All bash tests
- Individual bash test suites
- All Python tests
- Individual Python test suites
- Complete test suite (all tests)

### From Command Line

Run all tests:
```bash
./tests/run_tests.sh
```

Run individual test suites:
```bash
# Bash tests
./tests/test_gtd_common.sh
./tests/test_gtd_guides.sh
./tests/test_wizard_functions.sh
./tests/test_wizard_core_functions.sh
./tests/test_zettelkasten_wizard.sh

# Python tests
python3 tests/test_enhanced_search.py
python3 tests/test_gtd_persona_helper.py
python3 tests/test_gtd_tool_registry.py
python3 tests/test_lmstudio_helper.py
```

## Test Structure

- `test_helpers.sh` - Common testing utilities and assertions (bash)
- `test_gtd_common.sh` - Tests for `gtd-common.sh` helper library
- `test_gtd_guides.sh` - Tests for `gtd-guides.sh` guide functions
- `test_wizard_functions.sh` - Tests that all wizard menu functions are defined and available
- `test_wizard_core_functions.sh` - Tests for wizard core utility functions (computer mode, time of day, etc.)
- `test_zettelkasten_wizard.sh` - Tests for Zettelkasten wizard improvements (GTD item selection)
- `test_enhanced_search.py` - Python unit tests for enhanced search system
- `test_gtd_persona_helper.py` - Python unit tests for persona helper functions
- `test_gtd_tool_registry.py` - Python unit tests for tool registry system
- `test_lmstudio_helper.py` - Python unit tests for LM Studio helper functions
- `run_tests.sh` - Test runner that executes all test suites (bash and Python)

## Adding New Tests

### Bash Tests

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

### Python Tests

1. Create a new test file: `test_<module_name>.py`
2. Use Python's `unittest` framework
3. Use `unittest.mock` for mocking external dependencies
4. Follow the existing test structure

Example:
```python
#!/usr/bin/env python3
import unittest
from unittest.mock import Mock, patch
import sys
from pathlib import Path

# Add module to path
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
from my_module import my_function

class TestMyModule(unittest.TestCase):
    def test_my_function_happy_path(self):
        result = my_function("input")
        self.assertEqual(result, "expected")
    
    @patch('my_module.external_dependency')
    def test_my_function_with_mock(self, mock_dep):
        mock_dep.return_value = "mocked"
        result = my_function("input")
        self.assertEqual(result, "mocked")

if __name__ == '__main__':
    unittest.main()
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

### Zettelkasten Wizard Tests (15 tests)
- ✅ GTD item selection functionality
- ✅ select_from_list and select_from_numbered_list availability
- ✅ Path resolution for areas, projects, tasks, goals
- ✅ SECOND_BRAIN path handling
- ✅ Enhanced search integration verification

### Enhanced Search System Tests (Python - 20+ tests)
- ✅ EnhancedSearchSystem initialization
- ✅ Query enhancement detection (should_enhance_query)
- ✅ Query generation (generate_queries) with and without context
- ✅ Result synthesis (synthesize_results)
- ✅ LLM integration with mocks
- ✅ Error handling and fallbacks
- ✅ Query extraction logic
- ✅ enhance_search_query function integration

### Persona Helper Tests (Python - 30+ tests)
- ✅ Config reading (read_config) with various backends
- ✅ AI server checking (check_ai_server) with success and error cases
- ✅ User context extraction (_extract_user_context)
- ✅ Acronym reading and filtering (read_acronyms, filter_relevant_acronyms)
- ✅ Web search execution (execute_web_search)
- ✅ Persona calling (call_persona) with various flags
- ✅ Persona definitions validation
- ✅ Error handling for invalid personas and server failures

### Tool Registry Tests (Python - 20+ tests)
- ✅ Tool registration (register_tool) with and without handlers
- ✅ Tool definition retrieval (get_tool_definitions) with category filtering
- ✅ Tool execution (execute_tool) with success and error cases
- ✅ Tool categorization (get_available_tools_by_category)
- ✅ Tool listing (list_all_tools)
- ✅ Default registered tools validation (web search, GTD tools)

### LM Studio Helper Tests (Python - 20+ tests)
- ✅ Config reading (read_config) for LM Studio and Ollama
- ✅ Daily goal extraction (get_daily_goal)
- ✅ AI server checking (check_ai_server)
- ✅ LM Studio API calls (call_lm_studio) with various scenarios
- ✅ Error handling for server failures, timeouts, and model errors
- ✅ Goal-based prompt generation

### Wizard Core Functions Tests (Bash - 31 tests)
- ✅ Computer mode functions (get_computer_mode, set_computer_mode)
- ✅ Time of day detection (get_time_of_day)
- ✅ Check-in tracking (checkin_done_today)
- ✅ Day utilities (get_day_of_week, get_day_name)
- ✅ Weekly review tracking (weekly_review_done_this_week)
- ✅ Task completion counting (tasks_completed_today)
- ✅ Feature usage tracking (feature_rarely_used, features_used_together)
- ✅ Smart defaults generation (get_smart_defaults, show_smart_defaults)
- ✅ Dashboard and menu functions (show_dashboard, show_main_menu, etc.)

**Total: 400+ tests across 13 test suites (8 bash, 5 Python)**

