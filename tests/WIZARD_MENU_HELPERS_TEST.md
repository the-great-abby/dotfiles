# GTD Wizard Menu Helpers Test Suite

## Overview

This test suite validates that all menus, submenus, and sub-submenus in the GTD Wizard have proper section headers and helper functions. This ensures consistent user experience and helpful guidance throughout the wizard interface.

## What Gets Tested

### 1. Main Menu Helpers
- ✅ Main menu calls `show_organization_guide()` - displays organization techniques
- ✅ Main menu calls `show_process_reminders()` - displays process frequency guide
- ✅ Main menu has section headers for all categories:
  - 📥 INPUTS - Capture & Process
  - 🗂️ ORGANIZATION - Manage Your System
  - 🧠 SECOND BRAIN - Advanced Operations
  - 📤 OUTPUTS - Reviews & Creation
  - 📚 LEARNING - Guides & Discovery
  - 🔍 ANALYSIS - Insights & Tracking
  - 🛠️ TOOLS & SUPPORT
  - ⚙️ SETTINGS

### 2. Submenu (Wizard) Helpers
Each wizard function should call its corresponding guide function:

**Input Wizards:**
- `capture_wizard` → `show_capture_guide`
- `process_wizard` → `show_process_guide`
- `log_wizard` → `show_daily_log_guide`
- `checkin_wizard` → `show_checkin_guide`

**Organization Wizards:**
- `task_wizard` → `show_tasks_guide`
- `project_wizard` → `show_projects_guide`
- `area_wizard` → `show_areas_guide`
- `moc_wizard` → `show_moc_guide`
- `zettelkasten_wizard` → `show_zettelkasten_guide`

**Second Brain Wizards:**
- `sync_wizard` → `show_sync_guide`
- `brain_connect_wizard` → `show_connect_notes_guide`
- `brain_converge_wizard` → `show_converge_notes_guide`
- `brain_discover_wizard` → `show_discover_connections_guide`
- `brain_distill_wizard` → `show_distill_guide`
- `brain_diverge_wizard` → `show_diverge_guide`
- `brain_evergreen_wizard` → `show_evergreen_notes_guide`
- `brain_packet_wizard` → `show_note_packets_guide`

**Output Wizards:**
- `template_wizard` → `show_templates_guide`
- `diagram_wizard` → `show_diagram_guide`

**Analysis Wizards:**
- `search_wizard` → `show_search_guide`
- `status_wizard` → `show_status_guide`
- `goal_tracking_wizard` → `show_goal_tracking_guide`
- `energy_audit_wizard` → `show_energy_audit_guide`
- `metric_correlations_wizard` → `show_metric_correlations_guide`
- `pattern_recognition_wizard` → `show_pattern_recognition_guide`
- `energy_schedule_wizard` → `show_energy_schedule_guide`

**Tools Wizards:**
- `advice_wizard` → `show_advice_guide`
- `config_wizard` → `show_config_guide`
- `ai_suggestions_wizard` → `show_ai_suggestions_guide`
- `gamification_wizard` → `show_gamification_guide`
- `healthkit_wizard` → `show_healthkit_guide`
- `calendar_wizard` → `show_calendar_guide`

### 3. Sub-Submenu (Nested Menu) Structure
Validates that nested menus within wizards have:
- Menu structure with options
- Clear navigation paths
- Proper organization

### 4. Guide Function Availability
Verifies that all expected guide functions are defined in `gtd-guides.sh`:
- All 40+ guide functions exist
- Functions are properly defined
- Functions can be called from wizards

### 5. Menu Structure Consistency
Checks that wizards have proper menu structure:
- Title/header (with CYAN/BOLD styling)
- Guide function call
- Menu options (numbered)
- Back option (return to previous menu)

## Running the Tests

### Run all tests:
```bash
cd /Users/abby/code/dotfiles
./tests/run_tests.sh
```

### Run just this test suite:
```bash
cd /Users/abby/code/dotfiles
./tests/test_wizard_menu_helpers.sh
```

## Test Results

The test suite will report:
- Total tests run
- Number of passed tests
- Number of failed tests
- Detailed output for each validation

## Expected Behavior

When all tests pass, it means:
1. ✅ Main menu has organization guide and process reminders
2. ✅ Main menu has all section headers
3. ✅ All wizard functions call their guide functions
4. ✅ All guide functions are defined
5. ✅ Menu structures are consistent

## Adding New Wizards

When adding a new wizard function:

1. **Create the guide function** in `bin/gtd-guides.sh`:
   ```bash
   gtd_show_my_wizard_guide() {
     echo "Guide content here..."
   }
   ```

2. **Call the guide in your wizard**:
   ```bash
   my_wizard() {
     show_my_wizard_guide
     # ... rest of wizard
   }
   ```

3. **Add a test** in `test_wizard_menu_helpers.sh`:
   ```bash
   test_assert_success \
     "wizard_calls_guide '$WIZARD_FILE' 'my_wizard' 'show_my_wizard_guide'" \
     "my_wizard should call show_my_wizard_guide"
   ```

## Notes

- Tests use pattern matching to find guide function calls within wizard functions
- Tests validate both function existence and proper usage
- Menu structure tests check for visual consistency (colors, formatting)
- All tests are non-destructive (read-only validation)

