# MCP Tools Implementation Plan

Based on the GTD system analysis, here's a prioritized implementation plan for additional MCP tools.

## Phase 1: Quick Wins (Wrapping Existing Commands)

These are easy because they wrap existing bash scripts:

### Task Management
- [ ] `list_tasks()` - Wrap `gtd-task list` with filters
- [ ] `get_task_details()` - Read task file and return structured data
- [ ] `update_task()` - Update task properties

### Project Management
- [ ] `list_projects()` - Wrap `gtd-project list`
- [ ] `create_project()` - Wrap `gtd-project create`
- [ ] `get_project_details()` - Read project README

### Area Management
- [ ] `list_areas()` - Wrap `gtd-area list`
- [ ] `create_area()` - Wrap `gtd-area create`

### Inbox Management
- [ ] `list_inbox_items()` - List files in inbox directory
- [ ] `get_inbox_count()` - Count inbox files

### Daily Logs
- [ ] `read_daily_log()` - Read today's or specific date's log
- [ ] `read_recent_logs()` - Read last N days

### Habits
- [ ] `list_habits()` - Wrap `gtd-habit list`
- [ ] `get_habit_dashboard()` - Aggregate habit stats

## Phase 2: Medium Effort (Some Development)

### Search & Discovery
- [ ] `search_gtd_system()` - Search across all GTD files
- [ ] `get_context_tasks()` - Filter tasks by context/energy

### Smart Suggestions
- [ ] `suggest_next_actions()` - AI-powered next action suggestions
- [ ] `suggest_project_breakdown()` - Break down projects into tasks

## Phase 3: Advanced Features

### Calendar Integration
- [ ] `get_upcoming_events()`
- [ ] `schedule_task()`

### Statistics
- [ ] `get_productivity_stats()`
- [ ] `get_task_stats()`

### Second Brain Integration
- [ ] `sync_to_second_brain()`
- [ ] `link_to_para()`

## Recommended Starting Point

I suggest starting with **Phase 1** tools, as they:
- ✅ Provide immediate value
- ✅ Are easy to implement
- ✅ Wrap existing functionality
- ✅ Don't require complex logic

Which tools would you like me to implement first?

