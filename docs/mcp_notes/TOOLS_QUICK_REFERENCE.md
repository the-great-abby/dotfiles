# MCP Tools Quick Reference

## All Available Tools

### Fast Commands (Gemma 1b - Quick)

#### Task Suggestions
- `suggest_tasks_from_text(text, context)` - Analyze text and suggest tasks
- `get_pending_suggestions()` - List pending suggestions
- `suggest_task(title, reason, confidence)` - Add a suggestion

#### Task Management
- `list_tasks(context, energy, priority, project, status, limit)` - List tasks with filters
- `get_task_details(task_id)` - Get full task info
- `create_task(title, project, context, priority, notes)` - Create task directly
- `update_task(task_id, ...)` - Update task properties
- `complete_task(task_id)` - Mark task complete
- `defer_task(task_id, until)` - Defer task

#### Project Management
- `list_projects(status)` - List all projects
- `create_project(name, description, repository)` - Create new project
- `get_project_details(project_name)` - Get project info
- `get_project_status(project_name)` - Get project progress

#### Area Management
- `list_areas()` - List all areas

#### Context & Discovery
- `get_context_tasks(context, energy, limit)` - Tasks in specific context
- `get_inbox_count()` - Count inbox items

#### Daily Logs
- `read_daily_log(date)` - Read specific date's log
- `read_recent_logs(days)` - Read past N days

### Deep Analysis Commands (GPT-OSS 20b - Background)

- `weekly_review(week_start)` - Weekly analysis
- `analyze_energy(days)` - Energy patterns
- `find_connections(scope)` - Find connections
- `generate_insights(focus)` - Generate insights

## Common Use Cases

### "Show me my tasks"
```
list_tasks(status="active")
```

### "What can I work on at home?"
```
get_context_tasks(context="home")
```

### "What projects am I working on?"
```
list_projects(status="active")
```

### "How many inbox items?"
```
get_inbox_count()
```

### "What did I log today?"
```
read_daily_log()
```

### "What high-energy tasks do I have?"
```
list_tasks(energy="high", status="active")
```

## Tool Count

**Total: 21 MCP Tools**
- 17 Fast tools (Gemma 1b)
- 4 Deep analysis tools (GPT-OSS 20b, background)

All tools are ready to use! 🎉

