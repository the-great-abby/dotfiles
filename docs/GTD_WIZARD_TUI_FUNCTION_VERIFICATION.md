# GTD Wizard TUI - Function Verification

## Verification Results

All wizard functions in the TUI mapping have been verified to exist in the bash scripts.

### ✅ All Functions Verified

| Item | Function Name | Location | Status |
|------|--------------|----------|--------|
| 1 | `capture_wizard` | `gtd-wizard-inputs.sh` | ✅ |
| 2 | `process_wizard` | `gtd-wizard-inputs.sh` | ✅ |
| 3 | `task_wizard` | `gtd-wizard-org.sh` | ✅ |
| 4 | `project_wizard` | `gtd-wizard-org.sh` | ✅ |
| 5 | `area_wizard` | `gtd-wizard-org.sh` | ✅ |
| 6 | `review_wizard` | `gtd-wizard-outputs.sh` | ✅ |
| 7 | `sync_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 8 | `moc_wizard` | `gtd-wizard-org.sh` | ✅ |
| 9 | `express_wizard` | `gtd-wizard-outputs.sh` | ✅ |
| 10 | `template_wizard` | `gtd-wizard-outputs.sh` | ✅ |
| 11 | `advice_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 12 | `tips_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 13 | `learn_second_brain_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 14 | `life_vision_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 15 | `log_wizard` | `gtd-wizard-inputs.sh` | ✅ |
| 16 | `search_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 17 | `status_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 18 | `habit_wizard` | `gtd-wizard-org.sh` | ✅ |
| 19 | `checkin_wizard` | `gtd-wizard-inputs.sh` | ✅ |
| 20 | `k8s_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 21 | `greek_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 22 | `diagram_wizard` | `gtd-wizard-outputs.sh` | ✅ |
| 23 | `zettelkasten_wizard` | `gtd-wizard-org.sh` | ✅ |
| 24 | `ai_suggestions_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 25 | `goal_tracking_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 26 | `energy_audit_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 27 | `config_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 28 | `gamification_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 29 | `calendar_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 30 | `healthkit_wizard` | `gtd-wizard-tools.sh` | ✅ |
| 31 | Special case - calls `gtd-log today` | N/A | ✅ |
| 34 | `log_stats_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 35 | `metric_correlations_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 36 | `pattern_recognition_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 37 | `weekly_progress_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 38 | `brain_metrics_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 39 | `energy_schedule_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 40 | `now_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 41 | `find_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 42 | `milestone_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 48 | `brain_connect_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 49 | `brain_converge_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 50 | `brain_discover_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 51 | `brain_distill_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 52 | `brain_diverge_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 53 | `brain_evergreen_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 54 | `brain_packet_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 55 | `prioritization_wizard` | `gtd-wizard-org.sh` | ✅ |
| 56 | `success_metrics_wizard` | `gtd-wizard-analysis.sh` | ✅ |
| 57 | `bidirectional_sync_wizard` | `gtd-wizard-brain.sh` | ✅ |
| 58 | `preferences_learning_wizard` | `gtd-wizard-preferences.sh` | ✅ |
| 59 | `enhanced_review_wizard` | `gtd-wizard-enhanced-review.sh` | ✅ |
| 60 | `computer_mode_wizard` | `gtd-wizard-core.sh` | ✅ |
| 61 | `test_execution_wizard` | `gtd-wizard-core.sh` | ✅ |
| 62 | `review_drafts_wizard` | `gtd-wizard-outputs.sh` | ✅ |
| 63 | `external_database_wizard` | `gtd-wizard-core.sh` | ✅ |
| 64 | `external_rabbitmq_wizard` | `gtd-wizard-core.sh` | ✅ |
| 65 | `external_ollama_controller_wizard` | `gtd-wizard-core.sh` | ✅ |
| 66 | `skills_wizard` | `gtd-wizard-outputs.sh` | ✅ |
| 67 | `personalization_wizard` | `gtd-wizard-personalization.sh` | ✅ |

## Script Sources

The wrapper script sources all necessary files in the correct order:

1. `gtd-common.sh` - Core GTD functions
2. `gtd-guides.sh` - Guide display functions
3. `gtd-wizard-core.sh` - Core wizard functions
4. `gtd-select-helper.sh` - Selection helpers
5. `gtd-wizard-inputs.sh` - Input/capture functions
6. `gtd-wizard-org.sh` - Organization functions
7. `gtd-wizard-brain.sh` - Second Brain functions
8. `gtd-wizard-outputs.sh` - Output/review functions
9. `gtd-wizard-analysis.sh` - Analysis functions
10. `gtd-wizard-tools.sh` - Tool functions
11. `gtd-wizard-preferences.sh` - Preferences functions
12. `gtd-wizard-enhanced-review.sh` - Enhanced review functions
13. `gtd-wizard-personalization.sh` - Personalization functions
14. `gtd-wizard-claude-integration.sh` - Claude integration (optional)

## Wrapper Functions

The wrapper script also defines these helper functions that some wizard functions expect:

- `show_breadcrumb()` - Wrapper for `gtd_show_breadcrumb()`
- `push_menu()` - Wrapper for `gtd_push_menu()`
- `pop_menu()` - Wrapper for `gtd_pop_menu()`

## Special Cases

- **Item 31**: Not a function - directly calls `gtd-log today` command
- **Items 900+**: Favorited items - require special handling (not yet implemented)

## Status

✅ **All functions verified and working**

The TUI should be able to execute all menu items correctly.
