# Refactoring Next Steps

## ✅ Completed (Phase 1 & 2)

### High Priority Refactoring - DONE
- ✅ Replaced manual frontmatter parsing with `gtd_get_frontmatter_value`
- ✅ Removed manual path initialization (using `init_gtd_paths`)
- ✅ Extracted `find_task_file` to `gtd-common.sh`
- ✅ Created `get_project_name()` helper
- ✅ Created `directory_has_files()` helper

### Files Refactored
- ✅ `bin/gtd-plan`
- ✅ `bin/gtd-select-helper.sh`
- ✅ `bin/gtd-wizard-org.sh`
- ✅ `bin/gtd-wizard`

---

## 🎯 Phase 3: Code Review & Cleanup (NEXT)

### 3.1 Clean Up Remaining Path Initialization

**Status:** `gtd-wizard-org.sh` still has some manual path setup in a few places

**Files to fix:**
- `bin/gtd-wizard-org.sh` (lines 8-10, 1155-1156, 2352, 2750-2752)
  - These should rely on `init_gtd_paths` from `gtd-common.sh`

**Action:**
```bash
# Remove these manual initializations - they're redundant since gtd-common.sh is sourced
GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
PROJECTS_PATH="${PROJECTS_PATH:-${GTD_BASE_DIR}/projects}"
```

---

### 3.2 Add Unit Tests for New Helper Functions

**New functions to test:**
- `get_project_name()` - Test with various frontmatter combinations
- `directory_has_files()` - Test with empty/non-empty directories
- `find_task_file()` - Test finding tasks in TASKS_PATH and PROJECTS_PATH

**Create:** `tests/test_gtd_common_helpers.sh`

**Test cases needed:**
1. `get_project_name()`:
   - File with `project:` field
   - File with `name:` field (no project)
   - File with neither (should use directory name)
   - Invalid file path

2. `directory_has_files()`:
   - Directory with .md files
   - Directory with no files
   - Non-existent directory
   - Custom pattern matching

3. `find_task_file()`:
   - Task in TASKS_PATH
   - Task in PROJECTS_PATH
   - Task not found
   - Partial ID match

---

### 3.3 Update DRY Principle Rule

**File:** `.cursor/rules/dry-principle.mdc`

**Add to "Common Functions Available" section:**
```markdown
### Helper Functions (NEW)
- **`get_project_name <readme_file>`** - Get project name (checks project:, name:, then directory)
- **`directory_has_files <directory> [pattern]`** - Check if directory has files matching pattern
- **`find_task_file <task_id>`** - Find task file in TASKS_PATH or PROJECTS_PATH
```

**Add examples:**
```markdown
### Finding Task Files
```bash
# ✅ GOOD: Use standardized helper
task_file=$(find_task_file "$task_id")

# ❌ BAD: Manual find commands
task_file=$(find "$TASKS_PATH" -name "${task_id}*.md" 2>/dev/null | head -1)
if [[ -z "$task_file" ]]; then
  task_file=$(find "$PROJECTS_PATH" -name "${task_id}*.md" ! -name "README.md" 2>/dev/null | head -1)
fi
```

### Checking Directories
```bash
# ✅ GOOD: Use standardized helper
if directory_has_files "$AREAS_PATH"; then
  # ...
fi

# ❌ BAD: Manual find check
if [[ -d "$AREAS_PATH" ]] && [[ -n "$(find "$AREAS_PATH" -type f -name "*.md" 2>/dev/null)" ]]; then
  # ...
fi
```
```

---

## 🚀 Phase 4: Remaining Scripts (Future)

### Scripts Still Using Old Patterns

From `SCRIPT_REFACTORING_COMPLETE.md`, these scripts may still need updating:

**High Priority:**
- `bin/gtd-project` - Verify uses `init_gtd_paths`
- `bin/gtd-task` - Verify uses `find_task_file` from common
- `bin/gtd-area` - Check for manual frontmatter parsing

**Medium Priority:**
- `bin/gtd-habit`
- `bin/gtd-energy-schedule`
- `bin/gtd-pattern-recognition`
- `bin/gtd-predictive-reminders`
- `bin/gtd-lunch-reminder`
- `bin/gtd-morning-reminder`
- `bin/gtd-afternoon`
- `bin/gtd-evening`

**Action:** Audit each script to ensure:
1. Sources `gtd-common.sh`
2. Uses `init_gtd_paths` (or relies on auto-initialization)
3. Uses `gtd_get_frontmatter_value` instead of manual parsing
4. Uses standardized helpers where applicable

---

## 📋 Phase 5: Additional Opportunities

### 5.1 Area Name Extraction

**Pattern found:** Similar to project name extraction, areas might benefit from a helper

**Create:** `get_area_name()` in `gtd-common.sh` (if needed)

### 5.2 Goal Name Extraction

**Pattern found:** Goals also use frontmatter parsing

**Create:** `get_goal_name()` in `gtd-common.sh` (if needed)

### 5.3 File Existence Checks

**Pattern found:** Many scripts check `[[ -f "$file" ]]` before operations

**Consider:** Helper function for common file operations (if pattern is complex enough)

---

## 🧪 Testing Strategy

### Immediate Tests Needed
1. **Unit tests for new helpers** (`test_gtd_common_helpers.sh`)
2. **Integration tests** - Verify refactored scripts still work
3. **Regression tests** - Ensure no functionality broke

### Test Coverage Goals
- ✅ New helper functions: 100% coverage
- ✅ Refactored scripts: Verify existing functionality
- ✅ Edge cases: Empty directories, missing files, etc.

---

## 📊 Progress Tracking

### Completed ✅
- [x] Phase 1: High priority refactoring (4 files)
- [x] Phase 2: Helper function creation (3 functions)

### In Progress 🚧
- [ ] Phase 3.1: Clean up remaining path initialization
- [ ] Phase 3.2: Add unit tests for new helpers
- [ ] Phase 3.3: Update DRY principle rule

### Planned 📅
- [ ] Phase 4: Update remaining scripts
- [ ] Phase 5: Additional helper functions

---

## 🎯 Recommended Next Actions (Priority Order)

1. **Add unit tests** for new helper functions (Phase 3.2)
   - Ensures helpers work correctly
   - Prevents regressions
   - Documents expected behavior

2. **Clean up path initialization** in `gtd-wizard-org.sh` (Phase 3.1)
   - Quick win
   - Removes remaining duplication
   - Ensures consistency

3. **Update DRY principle rule** (Phase 3.3)
   - Documents new helpers
   - Prevents future duplication
   - Helps AI understand available functions

4. **Audit remaining scripts** (Phase 4)
   - Systematic review
   - Identify additional opportunities
   - Plan batch updates

---

## 💡 Quick Wins (Can Do Now)

### 1. Fix Remaining Path Initialization
**Time:** 5 minutes
**Files:** `bin/gtd-wizard-org.sh`
**Impact:** Removes 4-5 instances of duplication

### 2. Add Helper Function Tests
**Time:** 30 minutes
**File:** `tests/test_gtd_common_helpers.sh`
**Impact:** Ensures quality, prevents regressions

### 3. Update DRY Rule Documentation
**Time:** 10 minutes
**File:** `.cursor/rules/dry-principle.mdc`
**Impact:** Prevents future duplication

---

## 📈 Metrics

### Code Reduction
- **Before:** ~50+ instances of duplication
- **After Phase 1-2:** ~40 instances eliminated
- **After Phase 3:** ~45 instances eliminated (estimated)
- **After Phase 4:** ~50+ instances eliminated (estimated)

### Maintainability
- **Before:** Changes required updates in 4+ files
- **After:** Changes in one place (`gtd-common.sh`) affect all scripts

### Consistency
- **Before:** Inconsistent patterns across scripts
- **After:** Standardized helpers used everywhere
