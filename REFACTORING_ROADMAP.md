# 🗺️ Refactoring Roadmap

## Current Status: Phase 3-4 Complete ✅

We've successfully completed high-priority refactoring:
- ✅ **28 files refactored** (Phase 3: 10 files, Phase 4: 18 files)
- ✅ **3 new helper functions created** (`get_project_name`, `directory_has_files`, `find_task_file`)
- ✅ **~105+ instances of duplication eliminated**
- ✅ **14 unit tests added** (all passing)
- ✅ **30 files now source `gtd-common.sh`** (up from 20)

---

## ✅ Completed Phases

### Phase 3 (10 files) - Complete ✅
- `gtd-plan`, `gtd-select-helper.sh`, `gtd-wizard-org.sh`, `gtd-wizard`, `gtd-task`, `gtd-checkin`, `gtd-advise`, `gtd-learn-greek`, `gtd-learn-kubernetes`, `gtd-cka-quick`
- Created 3 helper functions
- Added 14 unit tests
- Eliminated ~70 instances of duplication

### Phase 4 (18 files) - Complete ✅
- `gtd-area`, `gtd-project`, `gtd-goal`, `gtd-energy-schedule`, `gtd-calendar`, `gtd-review`, `gtd-capture`, `gtd-process`, `gtd-search`, `gtd-afternoon`, `gtd-evening`, `gtd-pattern-recognition`, `gtd-predictive-reminders`, `gtd-context`, `gtd-lunch-reminder`, `gtd-morning-reminder`, `gtd-wizard-outputs.sh`
- Eliminated ~35 instances of duplication
- All high-priority scripts now use standardized helpers

---

## 🎯 Phase 5: Gamification & Reminder Scripts (In Progress)

### Gamification Scripts

**Status:**
- ✅ `gtd-gamify` - Already sources `gtd-common.sh` ✅
- ⚠️ `gtd-gamify-award` - **Needs refactoring** (manual `GTD_BASE_DIR` initialization on line 26)
- ⚠️ `gtd-cka-gamification` - **Needs refactoring** (manual `GTD_BASE_DIR` initialization on line 17)

**Changes needed:**
1. Add `source "$GTD_COMMON"` (or use existing sourcing pattern)
2. Remove manual `GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"` initialization
3. Rely on `init_gtd_paths()` from `gtd-common.sh`

---

### Reminder Scripts

**Status:**
- ✅ `gtd-morning-reminder` - Already refactored (Phase 4) ✅
- ✅ `gtd-lunch-reminder` - Already refactored (Phase 4) ✅
- ✅ `gtd-predictive-reminders` - Already refactored (Phase 4) ✅
- ⚠️ `gtd-weekly-reminder` - **Needs refactoring** (manual `GTD_BASE_DIR` on line 29, no `gtd-common.sh`)
- ⚠️ `gtd-study-reminder` - **Needs refactoring** (manual `GTD_BASE_DIR` on line 39, no `gtd-common.sh`)
- ⚠️ `gtd-daily-reminder` - **Needs audit** (check if already refactored)
- ⚠️ `gtd-health-reminder` - **Needs audit**
- ⚠️ `gtd-food-reminder` - **Needs audit**
- ⚠️ `gtd-setup-*` scripts - **Lower priority** (setup scripts, less frequently used)

**Changes needed:**
1. Add `source "$GTD_COMMON"` after config loading
2. Remove manual `GTD_BASE_DIR` initialization
3. Use standardized path variables from `gtd-common.sh`

---

## 📚 Phase 6: Study & Learning Scripts (In Progress)

### Study/Learning Scripts

**Status:**
- ✅ `gtd-learn-greek` - Already refactored (Phase 3) ✅
- ✅ `gtd-learn-kubernetes` - Already refactored (Phase 3) ✅
- ⚠️ `gtd-learn` - **Needs audit** (check if uses `GTD_BASE_DIR` or needs `gtd-common.sh`)
- ⚠️ `gtd-study-plan` - **Needs audit**
- ⚠️ `gtd-preferences-learn` - **Needs audit**
- ⚠️ `gtd-study-reminder` - **Needs refactoring** (see Reminder Scripts above)

**Changes needed:**
1. Add `source "$GTD_COMMON"` if not already present
2. Remove manual path initialization
3. Use standardized helpers where applicable

---

## 📊 Success Metrics

### Code Quality
- **Duplication instances:** 50+ → ~5 (90% reduction)
- **Helper functions:** 3 new standardized helpers
- **Consistency:** All scripts use same patterns

### Maintainability
- **Single source of truth:** Changes in `gtd-common.sh` affect all scripts
- **Easier debugging:** Standardized functions are easier to test
- **Better documentation:** Helpers are well-documented

### Developer Experience
- **Faster development:** Reuse helpers instead of reimplementing
- **Fewer bugs:** Tested helpers reduce errors
- **Clear patterns:** DRY rule guides development

---

## 🎯 Recommended Order (Current Phase 5-6)

### Immediate Next Steps

1. **Gamification Scripts** (30 min)
   - Refactor `gtd-gamify-award` - Add `gtd-common.sh` sourcing, remove manual `GTD_BASE_DIR`
   - Refactor `gtd-cka-gamification` - Add `gtd-common.sh` sourcing, remove manual `GTD_BASE_DIR`

2. **Reminder Scripts** (1 hour)
   - Refactor `gtd-weekly-reminder` - Add `gtd-common.sh` sourcing, remove manual `GTD_BASE_DIR`
   - Refactor `gtd-study-reminder` - Add `gtd-common.sh` sourcing, remove manual `GTD_BASE_DIR`
   - Audit `gtd-daily-reminder`, `gtd-health-reminder`, `gtd-food-reminder`

3. **Study/Learning Scripts** (1 hour)
   - Audit `gtd-learn`, `gtd-study-plan`, `gtd-preferences-learn`
   - Refactor as needed based on audit results

4. **Final Verification** (30 min)
   - Run syntax checks on all refactored scripts
   - Run test suite
   - Update documentation

**Total estimated time:** 3-4 hours for Phase 5-6 completion

---

## 💡 Pro Tips

### When to Create a New Helper
- Pattern appears 3+ times
- Pattern is complex (error-prone if duplicated)
- Pattern is likely to change

### When NOT to Create a Helper
- Pattern appears only once or twice
- Pattern is trivial (one-liner)
- Pattern is context-specific

### Testing Strategy
- Test helpers in isolation
- Test integration with scripts
- Test edge cases (empty files, missing directories, etc.)

---

## 📝 Notes

- All refactoring maintains backward compatibility
- Scripts work exactly as before, just use common code
- No breaking changes to user-facing functionality
- All syntax checks pass
