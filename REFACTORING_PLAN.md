# File Size Management & Refactoring Plan

## Current File Sizes

```
gtd-wizard:     10,785 lines  ⚠️  VERY LARGE
gtd-guides.sh:   1,274 lines  ⚠️  Large but manageable
gtd-common.sh:     298 lines  ✅  Reasonable
```

## Why File Size Matters

### For AI Models (2024-2025)
- **Context Limits**: Even with large context windows (100k-200k tokens), processing 10k+ lines is:
  - **Slower**: More tokens to process = slower responses
  - **More Expensive**: Token costs scale with size
  - **Less Focused**: Harder to find relevant code sections
  - **Context Pollution**: Unrelated code dilutes focus

### For Human Developers
- **Readability**: Hard to navigate and understand
- **Merge Conflicts**: Large files = more conflicts
- **Performance**: Slower to load/parse in editors
- **Maintainability**: Hard to locate specific functionality

### Recommended Limits
- **Ideal**: < 500 lines per file
- **Acceptable**: < 1,000 lines
- **Warning**: 1,000 - 2,000 lines
- **Critical**: > 2,000 lines (refactor needed)

## Refactoring Strategy for gtd-wizard

### Current Structure
The wizard has ~50+ wizard functions, each handling a menu option. These can be grouped into logical modules.

### Proposed Module Structure

```
bin/
├── gtd-wizard              # Main orchestrator (~200 lines)
├── gtd-wizard-core.sh      # Core functions (dashboard, menu, navigation)
├── gtd-wizard-inputs.sh    # Input/capture wizards
├── gtd-wizard-org.sh       # Organization wizards (tasks, projects, areas)
├── gtd-wizard-brain.sh     # Second Brain wizards
├── gtd-wizard-outputs.sh   # Review/creation wizards
├── gtd-wizard-analysis.sh  # Analysis/insights wizards
└── gtd-wizard-tools.sh     # Tools/support wizards
```

### Module Breakdown

#### 1. `gtd-wizard-core.sh` (~300 lines)
- `show_dashboard()`
- `show_main_menu()`
- `show_organization_guide()`
- `show_process_reminders()`
- Menu navigation helpers
- Main loop logic

#### 2. `gtd-wizard-inputs.sh` (~400 lines)
- `capture_wizard()` (with 5 horizons)
- `process_wizard()`
- `log_wizard()`
- `checkin_wizard()`
- `mood_log_wizard()`
- `calendar_log_wizard()`
- `collect_all_wizard()`

#### 3. `gtd-wizard-org.sh` (~600 lines)
- `task_wizard()`
- `project_wizard()`
- `area_wizard()`
- `moc_wizard()`
- `zettelkasten_wizard()`
- `habit_wizard()`

#### 4. `gtd-wizard-brain.sh` (~800 lines)
- `brain_connect_wizard()`
- `brain_converge_wizard()`
- `brain_discover_wizard()`
- `brain_distill_wizard()`
- `brain_diverge_wizard()`
- `brain_evergreen_wizard()`
- `brain_packet_wizard()`
- `sync_wizard()`

#### 5. `gtd-wizard-outputs.sh` (~500 lines)
- `review_wizard()`
- `express_wizard()`
- `template_wizard()`
- `diagram_wizard()`
- `morning_routine_wizard()`
- `afternoon_routine_wizard()`
- `evening_routine_wizard()`
- `evening_summary_wizard()`

#### 6. `gtd-wizard-analysis.sh` (~600 lines)
- `status_wizard()`
- `search_wizard()`
- `goal_tracking_wizard()`
- `energy_audit_wizard()`
- `log_stats_wizard()`
- `metric_correlations_wizard()`
- `pattern_recognition_wizard()`
- `weekly_progress_wizard()`
- `brain_metrics_wizard()`
- `energy_schedule_wizard()`
- `now_wizard()`
- `find_wizard()`
- `milestone_wizard()`

#### 7. `gtd-wizard-tools.sh` (~400 lines)
- `advice_wizard()`
- `ai_suggestions_wizard()`
- `calendar_wizard()`
- `config_wizard()`
- `gamification_wizard()`
- `healthkit_wizard()`
- `tips_wizard()`
- `k8s_wizard()`
- `greek_wizard()`
- `learn_second_brain_wizard()`
- `life_vision_wizard()`

## Implementation Plan

### Phase 1: Extract Core Functions
1. Create `gtd-wizard-core.sh`
2. Move dashboard, menu, and navigation functions
3. Update `gtd-wizard` to source core module

### Phase 2: Extract by Category
1. Extract one category at a time (start with smallest)
2. Test after each extraction
3. Update wizard to source new modules

### Phase 3: Clean Up
1. Remove duplicate code
2. Ensure all functions are properly exported
3. Update tests
4. Update documentation

## Benefits

### For AI Models
- ✅ Faster processing (smaller context)
- ✅ Lower costs (fewer tokens)
- ✅ Better focus (relevant code only)
- ✅ Easier to understand structure

### For Development
- ✅ Easier navigation
- ✅ Fewer merge conflicts
- ✅ Better code organization
- ✅ Easier to test individual modules
- ✅ Faster editor performance

## Migration Strategy

1. **Backward Compatibility**: Keep `gtd-wizard` as main entry point
2. **Gradual Migration**: Extract one module at a time
3. **Test After Each Step**: Ensure nothing breaks
4. **Update Tests**: Add tests for new module structure

## File Size Targets

After refactoring:
```
gtd-wizard:           ~200 lines  ✅
gtd-wizard-core.sh:   ~300 lines  ✅
gtd-wizard-inputs.sh: ~400 lines  ✅
gtd-wizard-org.sh:    ~600 lines  ✅
gtd-wizard-brain.sh:  ~800 lines  ⚠️  (could split further)
gtd-wizard-outputs.sh: ~500 lines  ✅
gtd-wizard-analysis.sh: ~600 lines  ✅
gtd-wizard-tools.sh:  ~400 lines  ✅
```

## Next Steps

1. Create module structure
2. Extract core functions first
3. Test and verify
4. Continue with other modules incrementally
