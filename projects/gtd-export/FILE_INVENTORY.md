# GTD System File Inventory

This document catalogs all files that need to be exported from the dotfiles repository.

## File Categories

### 1. Core Scripts (`bin/`)

#### Wizard Scripts
- `bin/gtd-wizard` - Main wizard entry point
- `bin/gtd-wizard-core.sh` - Core wizard functionality
- `bin/gtd-wizard-inputs.sh` - Input/capture functions
- `bin/gtd-wizard-outputs.sh` - Output/review functions
- `bin/gtd-wizard-org.sh` - Organization functions
- `bin/gtd-wizard-analysis.sh` - Analysis functions
- `bin/gtd-wizard-brain.sh` - Second Brain functions
- `bin/gtd-wizard-enhanced-review.sh` - Enhanced review
- `bin/gtd-wizard-claude-integration.sh` - Claude integration
- `bin/gtd-wizard-tools.sh` - Tools and utilities
- `bin/gtd-wizard-personalization.sh` - Personalization wizard
- `bin/gtd-wizard-preferences.sh` - Preferences wizard
- `bin/gtd-guides.sh` - Guides and help

#### Core Commands
- `bin/gtd-capture` - Capture to inbox
- `bin/gtd-process` - Process inbox
- `bin/gtd-review` - Review system
- `bin/gtd-task` - Task management
- `bin/gtd-project` - Project management
- `bin/gtd-area` - Area management
- `bin/gtd-moc` - MOC management
- `bin/gtd-brain-*` - Second Brain commands
- `bin/gtd-calendar*` - Calendar integration
- `bin/gtd-daily-log` - Daily logging
- `bin/gtd-advise` - AI advice
- `bin/gtd-diagram` - Diagram generation
- `bin/gtd-learn` - Learning system
- `bin/gtd-quiz*` - Quiz system
- `bin/gtd-habit` - Habit tracking
- `bin/gtd-gamify*` - Gamification
- `bin/gtd-energy-*` - Energy management
- `bin/gtd-now` - Context-aware suggestions
- `bin/gtd-dashboard` - Dashboard
- `bin/gtd-status` - System status

#### Worker Scripts
- `bin/gtd-advice-worker*` - Advice worker
- `bin/gtd-deep-analysis-worker` - Deep analysis worker
- `bin/gtd-vector-worker` - Vector worker
- `bin/gtd-task-org-worker` - Task organization worker
- `bin/gtd-second-brain-sync-worker` - Second Brain sync worker
- `bin/gtd-calendar-reminder-worker` - Calendar reminder worker
- `bin/gtd-dashboard-cache-worker` - Dashboard cache worker
- `bin/gtd-badge-suggestion-worker` - Badge suggestion worker
- `bin/gtd-vector-filewatcher` - Vector filewatcher
- `bin/gtd-deep-analysis-scheduler*` - Deep analysis scheduler

#### Utility Scripts
- `bin/gtd-common.sh` - Common functions
- `bin/gtd-select-helper.sh` - Selection helpers
- `bin/gtd-check-web-service.sh` - Web service checker
- `bin/gtd-worker-status` - Worker status
- `bin/gtd-queue-status` - Queue status
- `bin/gtd-request-status` - Request status
- `bin/gtd-vector-db-status` - Vector DB status
- `bin/gtd-rabbitmq-*` - RabbitMQ utilities
- `bin/gtd-mode-*` - Mode management
- `bin/gtd-set-*` - Computer mode settings
- `bin/gtd-config-split` - Config splitter
- `bin/gtd-script-docs-generator` - Documentation generator

#### Helper Scripts
- `bin/gtd_claude_diagram_helper.py` - Diagram helper
- `bin/gtd_deep_model_helper.py` - Deep model helper
- `bin/gtd_web_search_helper.py` - Web search helper
- `bin/gtd_even_glasses.py` - Even glasses integration
- `bin/gtd-extract-log-from-note.py` - Log extractor

#### Reminder Scripts
- `bin/gtd-morning-reminder`
- `bin/gtd-daily-reminder`
- `bin/gtd-weekly-reminder`
- `bin/gtd-food-reminder`
- `bin/gtd-health-reminder`
- `bin/gtd-lunch-reminder`
- `bin/gtd-study-reminder`
- `bin/gtd-setup-*` - Setup scripts

#### Learning Scripts
- `bin/gtd-learn-kubernetes`
- `bin/gtd-learn-greek`
- `bin/gtd-cka-*` - CKA exam prep

### 2. Configuration Files (`zsh/`)

#### Main Config Files
- `zsh/.gtd_config` - Main configuration
- `zsh/.gtd_config_advanced` - Advanced settings
- `zsh/.gtd_config_ai` - AI configuration
- `zsh/.gtd_config_calendar` - Calendar configuration
- `zsh/.gtd_config_capture` - Capture configuration
- `zsh/.gtd_config_core` - Core settings
- `zsh/.gtd_config_custom` - Custom settings
- `zsh/.gtd_config_database` - Database configuration
- `zsh/.gtd_config_integrations` - Integration settings
- `zsh/.gtd_config_notifications` - Notification settings
- `zsh/.gtd_config_reviews` - Review settings
- `zsh/.gtd_preferences_config` - Preferences
- `zsh/.gtd_acronyms` - Acronyms
- `zsh/.daily_log_config` - Daily log config

#### Functions
- `zsh/functions/gtd_ai_async.py` - Async AI functions
- `zsh/functions/gtd_ai_helpers.py` - AI helpers
- `zsh/functions/gtd_enhanced_search.py` - Enhanced search
- `zsh/functions/gtd_ollama_web_search.py` - Ollama web search
- `zsh/functions/gtd_panel_discussion.py` - Panel discussion
- `zsh/functions/gtd_persona_helper.py` - Persona helper
- `zsh/functions/gtd_persona_helper_deep.py` - Deep persona helper
- `zsh/functions/gtd_quiz_helper.py` - Quiz helper
- `zsh/functions/gtd_tool_registry.py` - Tool registry
- `zsh/functions/gtd_toon_helper.py` - TOON helper
- `zsh/functions/gtd_vector_db.py` - Vector database
- `zsh/functions/gtd_vectorization.py` - Vectorization
- `zsh/functions/load_gtd_config.sh` - Config loader
- `zsh/functions/helpers.sh` - Helper functions
- `zsh/functions/lmstudio_helper.py` - LM Studio helper

#### Other Files
- `zsh/gtd-aliases.zsh` - GTD aliases
- `zsh/common_env.sh` - Common environment
- `zsh/quizzes/organization-system-questions.json` - Quiz questions
- `zsh/quizzes/second-brain-questions.json` - Quiz questions

#### Launchd Plists
- `zsh/com.abby.gtd.daily.plist`
- `zsh/com.abby.gtd.food.plist`
- `zsh/com.abby.gtd.health.plist`
- `zsh/com.abby.gtd.lunch.plist`
- `zsh/com.abby.gtd.morning.plist`
- `zsh/com.abby.gtd.study.plist`
- `zsh/com.abby.gtd.weekly.plist`

### 3. MCP Server (`mcp/`)

#### Core MCP Files
- `mcp/gtd_mcp_server.py` - Main MCP server
- `mcp/gtd_skills.py` - Skills system
- `mcp/claude_gtd_client.py` - Claude client
- `mcp/claude_ollama_bridge.py` - Ollama bridge
- `mcp/requirements.txt` - Python dependencies
- `mcp/README.md` - MCP documentation

#### Workers
- `mcp/gtd_advice_worker.py` - Advice worker
- `mcp/gtd_deep_analysis_worker.py` - Deep analysis worker
- `mcp/gtd_vector_worker.py` - Vector worker
- `mcp/gtd_task_organize_worker.py` - Task organization worker
- `mcp/gtd_second_brain_sync_worker.py` - Second Brain sync worker
- `mcp/gtd_calendar_reminder_worker.py` - Calendar reminder worker
- `mcp/gtd_dashboard_cache_worker.py` - Dashboard cache worker
- `mcp/gtd_badge_suggestion_worker.py` - Badge suggestion worker
- `mcp/gtd_vector_filewatcher.py` - Vector filewatcher
- `mcp/gtd_deep_analysis_scheduler.py` - Deep analysis scheduler
- `mcp/gtd_vector_scan_existing.py` - Vector scanner

#### Analysis & Suggestions
- `mcp/gtd_auto_suggest.py` - Auto suggestions
- `mcp/gtd_smart_suggestions.py` - Smart suggestions
- `mcp/gtd_task_suggestions_unified.py` - Task suggestions
- `mcp/gtd_project_suggest.py` - Project suggestions
- `mcp/gtd_explain_suggestions.py` - Explanation system
- `mcp/gtd_progress_analyzer.py` - Progress analyzer
- `mcp/gtd_task_completion_review.py` - Task completion review
- `mcp/gtd_knowledge_organize_worker.py` - Knowledge organization
- `mcp/gtd_unified_learning.py` - Unified learning
- `mcp/gtd_two_model_loop.py` - Two model loop

#### Utilities
- `mcp/gtd_mcp_status.sh` - MCP status
- `mcp/check_mcp_cursor.sh` - MCP checker
- `mcp/check_worker.sh` - Worker checker
- `mcp/setup.sh` - Setup script
- `mcp/deploy.sh` - Deployment script
- `mcp/Dockerfile` - Docker configuration

#### Skills Directory
- `mcp/skills/` - All skill directories and files
  - See `mcp/skills/` for complete list

### 4. Documentation (`docs/`)

#### Main Guides
- `docs/GTD_*.md` - All GTD guides
- `docs/*GTD*.md` - GTD-related documentation
- `docs/architecture/gtd_*.md` - Architecture documentation

#### Specific Documentation
- See `docs/` directory for complete list
- Focus on files with "GTD" in name or GTD-related content

### 5. Web Interface (`web/`)

#### GTD-Specific Web Files
- GTD API endpoints
- GTD frontend components
- GTD-specific configuration

**Note**: Need to identify which web files are GTD-specific vs general dotfiles

### 6. Tests (`tests/`)

#### GTD Tests
- `tests/test_gtd_*.py` - Python tests
- `tests/test_gtd_*.sh` - Shell script tests

### 7. Launchd (`launchd/`)

- `launchd/com.gtd.*.plist` - macOS launchd configurations

### 8. Makefile Targets

All GTD-related targets in `Makefile`:
- `gtd-wizard*` targets
- `gtd-*` command targets
- Worker management targets
- Status targets

## Files to Exclude

### Shared Utilities (Keep in dotfiles)
- General shell utilities not GTD-specific
- General configuration files
- Non-GTD aliases and functions

### External Dependencies
- External service repositories (documented, not copied)
- System-level dependencies (documented, not copied)

## File Count Summary

- **Core Scripts**: ~150+ files
- **Configuration**: ~20+ files
- **MCP Server**: ~30+ files
- **Documentation**: ~50+ files
- **Tests**: ~10+ files
- **Launchd**: ~5 files
- **Web**: TBD

**Total**: ~265+ files (estimated)

## Next Steps

1. Verify file inventory completeness
2. Identify any missing files
3. Categorize shared vs GTD-specific files
4. Create export script based on this inventory
