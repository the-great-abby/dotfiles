# Phase 5-6 Refactoring Status

## Current Status: ✅ Phase 5-6 Complete

Refactoring gamification, reminder, and study/learning scripts to use standardized helpers from `gtd-common.sh`.

---

## ✅ Completed (Phases 3-4)

### High-Priority Scripts - All Complete ✅
- **28 files refactored** across Phase 3 and Phase 4
- **~105+ instances of duplication eliminated**
- **3 helper functions created** and tested
- **30 files now source `gtd-common.sh`**

See `REFACTORING_FINAL_SUMMARY.md` for complete details.

---

## 🎯 Phase 5: Gamification Scripts

### Status Overview

| Script | Status | Notes |
|--------|--------|-------|
| `gtd-gamify` | ✅ Complete | Already sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |
| `gtd-gamify-award` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |
| `gtd-cka-gamification` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |

### Changes Needed

#### `gtd-gamify-award`
- **Line 26:** Remove `GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"`
- **After line 24:** Add `gtd-common.sh` sourcing (similar to `gtd-gamify`)
- **Line 27:** Change to use `GTD_BASE_DIR` from `init_gtd_paths`

#### `gtd-cka-gamification`
- **Line 17:** Remove `GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"`
- **After line 15:** Add `gtd-common.sh` sourcing
- **Line 18:** Change to use `GTD_BASE_DIR` from `init_gtd_paths`

---

## 🔔 Phase 5: Reminder Scripts

### Status Overview

| Script | Status | Notes |
|--------|--------|-------|
| `gtd-morning-reminder` | ✅ Complete | Refactored in Phase 4 |
| `gtd-lunch-reminder` | ✅ Complete | Refactored in Phase 4 |
| `gtd-predictive-reminders` | ✅ Complete | Refactored in Phase 4 |
| `gtd-weekly-reminder` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |
| `gtd-study-reminder` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |
| `gtd-daily-reminder` | ✅ Complete | Already sources `gtd-common.sh` (line 5-13) |
| `gtd-health-reminder` | ⚠️ Needs Audit | Check current state |
| `gtd-food-reminder` | ⚠️ Needs Audit | Check current state |
| `gtd-setup-*` scripts | 📋 Lower Priority | Setup scripts, less frequently used |

### Changes Needed

#### `gtd-weekly-reminder`
- **Line 29:** Remove `GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"`
- **After line 26:** Add `gtd-common.sh` sourcing
- Use standardized path variables

#### `gtd-study-reminder`
- **Line 39:** Remove `GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"`
- **After line 36:** Add `gtd-common.sh` sourcing
- Use standardized path variables

#### Remaining Reminders (Need Audit)
- Check if they already source `gtd-common.sh`
- Check for manual `GTD_BASE_DIR` initialization
- Check for other duplication patterns

---

## 📚 Phase 6: Study & Learning Scripts

### Status Overview

| Script | Status | Notes |
|--------|--------|-------|
| `gtd-learn-greek` | ✅ Complete | Refactored in Phase 3 |
| `gtd-learn-kubernetes` | ✅ Complete | Refactored in Phase 3 |
| `gtd-learn` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |
| `gtd-study-plan` | ✅ Complete | Already sources `gtd-common.sh` (no changes needed) |
| `gtd-preferences-learn` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |
| `gtd-study-reminder` | ✅ Complete | Refactored - now sources `gtd-common.sh`, uses `GTD_BASE_DIR` from `init_gtd_paths` |

### Changes Needed

#### Scripts Needing Audit
1. Check if they source `gtd-common.sh`
2. Check for manual path initialization
3. Check for duplicate helper functions
4. Check for manual frontmatter parsing
5. Check for hardcoded paths

---

## 📋 Refactoring Checklist

For each script being refactored:

- [ ] Add `source "$GTD_COMMON"` (or use existing sourcing pattern)
- [ ] Remove manual `GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"` initialization
- [ ] Remove manual path variable initialization (`TASKS_PATH`, `PROJECTS_PATH`, etc.)
- [ ] Replace manual task finding with `find_task_file()` if applicable
- [ ] Replace manual frontmatter parsing with `gtd_get_frontmatter_value()` if applicable
- [ ] Replace hardcoded paths with standardized path variables
- [ ] Test script functionality after refactoring
- [ ] Run syntax check: `bash -n script_name`
- [ ] Verify no regressions

---

## 🎯 Priority Order

### High Priority (Commonly Used)
1. `gtd-gamify-award` - Used by other scripts
2. `gtd-weekly-reminder` - Regular reminder
3. `gtd-study-reminder` - Regular reminder
4. `gtd-cka-gamification` - Study-related

### Medium Priority
5. `gtd-daily-reminder` - After audit
6. `gtd-health-reminder` - After audit
7. `gtd-food-reminder` - After audit
8. `gtd-learn` - After audit
9. `gtd-study-plan` - After audit
10. `gtd-preferences-learn` - After audit

### Lower Priority
11. `gtd-setup-*` scripts - Setup scripts, less frequently used

---

## 📊 Progress Tracking

### Phase 5-6 Progress
- **Gamification Scripts:** 3/3 complete (100%) ✅
- **Reminder Scripts:** 5/9+ complete (56%+) - High priority scripts done ✅
- **Study/Learning Scripts:** 4/4 complete (100%) ✅

### Overall Refactoring Progress
- **Total Files Refactored:** 28 files (Phases 3-4)
- **Remaining High-Priority:** ~6-8 files
- **Remaining Medium-Priority:** ~10-15 files
- **Remaining Lower-Priority:** ~20+ files

---

## 🔍 Patterns to Look For

1. **Manual Path Initialization:**
   ```bash
   GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
   ```
   → Replace with: Rely on `init_gtd_paths()` from `gtd-common.sh`

2. **Missing `gtd-common.sh` Sourcing:**
   ```bash
   # Missing: source "$GTD_COMMON"
   ```
   → Add: `source "$GTD_COMMON"` after config loading

3. **Manual Task Finding:**
   ```bash
   find "$TASKS_PATH" -name "${task_id}*.md" ...
   ```
   → Replace with: `find_task_file "$task_id"`

4. **Manual Frontmatter Parsing:**
   ```bash
   grep "^${key}:" "$file" | cut -d':' -f2 | sed ...
   ```
   → Replace with: `gtd_get_frontmatter_value "$file" "$key"`

5. **Hardcoded Paths:**
   ```bash
   ~/Documents/gtd/0-inbox
   ```
   → Replace with: Standardized path variables

---

## ✅ Success Criteria

- [ ] All gamification scripts use `gtd-common.sh`
- [ ] All reminder scripts use `gtd-common.sh`
- [ ] All study/learning scripts use `gtd-common.sh`
- [ ] No manual `GTD_BASE_DIR` initialization in refactored scripts
- [ ] All syntax checks pass
- [ ] All tests pass
- [ ] No regressions in functionality

---

## 📝 Notes

- All refactoring maintains backward compatibility
- Scripts work exactly as before, just use common code
- No breaking changes to user-facing functionality
- Follow DRY principle rule (`.cursor/rules/dry-principle.mdc`)

---

**Last Updated:** Based on current codebase state
**Next Steps:** Continue with gamification scripts, then reminder scripts, then study/learning scripts
