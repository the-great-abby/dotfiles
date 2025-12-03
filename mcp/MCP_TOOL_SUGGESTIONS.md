# Additional MCP Tools - Suggestions

Based on your GTD system, here are additional useful tools to expose via MCP:

## Current MCP Tools (Already Implemented)

✅ Task suggestions from text  
✅ Create tasks from suggestions  
✅ Get pending suggestions  
✅ Create tasks directly  
✅ Suggest tasks  
✅ Complete/defer tasks  
✅ Deep analysis (weekly review, energy, connections, insights)

## Suggested Additional Tools

### 1. **Task Management**

#### List Tasks
```python
list_tasks(
    context=None,      # Filter by context
    energy=None,       # Filter by energy level
    priority=None,     # Filter by priority
    project=None,      # Filter by project
    status="active",   # Filter by status
    limit=50          # Max results
)
```
**Use Case:** "Show me all my computer tasks" or "What high-energy tasks do I have?"

#### Get Task Details
```python
get_task(task_id)
```
**Returns:** Full task details including notes, history, etc.

#### Update Task
```python
update_task(
    task_id,
    title=None,
    context=None,
    energy=None,
    priority=None,
    project=None,
    status=None,
    notes=None
)
```

### 2. **Project Management**

#### List Projects
```python
list_projects(status="active")
```
**Returns:** All active projects with details

#### Create Project
```python
create_project(
    name,
    description=None,
    repository=None,
    area=None
)
```

#### Get Project Details
```python
get_project(project_name)
```
**Returns:** Project info, tasks, status, etc.

#### Add Task to Project
```python
add_task_to_project(project_name, task_title, context=None, priority=None)
```

#### Project Status
```python
get_project_status(project_name)
```
**Returns:** Progress, tasks completed, next actions, etc.

### 3. **Area Management**

#### List Areas
```python
list_areas()
```
**Returns:** All areas of responsibility

#### Create Area
```python
create_area(name, description=None)
```

#### Get Area Details
```python
get_area(area_name)
```
**Returns:** Area info, related projects, tasks, etc.

### 4. **Inbox Management**

#### List Inbox Items
```python
list_inbox_items(limit=10)
```
**Returns:** Recent inbox items that need processing

#### Get Inbox Count
```python
get_inbox_count()
```
**Returns:** Number of unprocessed items

#### Process Inbox Item
```python
process_inbox_item(item_id, action="task")  # task, project, reference, etc.
```

### 5. **Daily Logs**

#### Read Daily Log
```python
read_daily_log(date=None)  # Default: today
```
**Returns:** Full log entries for the day

#### Read Recent Logs
```python
read_recent_logs(days=7)
```
**Returns:** Logs from past N days

#### Search Daily Logs
```python
search_daily_logs(query, days=30)
```
**Returns:** Matching log entries

### 6. **Habit Management**

#### List Habits
```python
list_habits(status="active")
```
**Returns:** All active habits with streaks

#### Create Habit
```python
create_habit(
    name,
    frequency="daily",
    area=None,
    context=None
)
```

#### Log Habit
```python
log_habit(habit_name)
```
**Records completion and updates streak**

#### Get Habit Dashboard
```python
get_habit_dashboard()
```
**Returns:** Stats, streaks, due today, etc.

### 7. **Zettelkasten**

#### Create Zettel
```python
create_zettel(title, content=None, category="inbox")
```

#### Search Zettels
```python
search_zettels(query, category=None)
```

#### Link Zettels
```python
link_zettels(zettel1_id, zettel2_id, description=None)
```

### 8. **Reviews**

#### Daily Review Data
```python
get_daily_review_data(date=None)
```
**Returns:** Priorities, accomplishments, blockers, etc.

#### Weekly Review Data
```python
get_weekly_review_data(week_start=None)
```
**Returns:** Projects status, inbox count, calendar items, etc.

#### Start Daily Review
```python
start_daily_review(morning=True)
```
**Guides through review questions**

### 9. **Search & Discovery**

#### Search System
```python
search_gtd_system(query, scope="all")  # all, tasks, projects, logs, zettels
```

#### Find Related Items
```python
find_related_items(item_id, item_type="task")
```
**Finds related tasks, projects, zettels, etc.**

### 10. **Smart Suggestions**

#### Suggest Next Actions
```python
suggest_next_actions(context=None, energy=None, limit=5)
```
**AI-powered suggestions based on current context**

#### Suggest Project Breakdown
```python
suggest_project_breakdown(project_description)
```
**Breaks down a project into actionable tasks**

#### Suggest Task Grouping
```python
suggest_task_grouping(task_ids)
```
**Suggests which tasks should be grouped into projects**

### 11. **Context & Energy Management**

#### Get Context Tasks
```python
get_context_tasks(context, energy=None)
```
**Returns tasks available in current context**

#### Get Energy Match Tasks
```python
get_energy_match_tasks(energy_level, context=None)
```
**Returns tasks matching your current energy**

### 12. **Statistics & Insights**

#### Get Productivity Stats
```python
get_productivity_stats(days=7)
```
**Returns:** Tasks completed, projects progress, etc.

#### Get Task Stats
```python
get_task_stats(project=None, area=None, days=30)
```

#### Get Streak Info
```python
get_streak_info()
```
**Returns:** Habit streaks, completion streaks, etc.

### 13. **Calendar Integration**

#### Get Upcoming Events
```python
get_upcoming_events(days=7)
```

#### Schedule Task
```python
schedule_task(task_id, datetime)
```

### 14. **Tags & Organization**

#### List Tags
```python
list_tags()
```

#### Tag Item
```python
tag_item(item_id, item_type, tags)
```

### 15. **Second Brain Integration**

#### Sync to Second Brain
```python
sync_to_second_brain(scope="all")  # all, projects, areas, tasks
```

#### Link to PARA
```python
link_to_para(item_id, item_type, para_category)  # Projects, Areas, Resources, Archives
```

## Priority Recommendations

### High Priority (Most Useful)

1. **List Tasks** - Essential for task management
2. **List Projects** - Overview of all projects
3. **Read Daily Log** - Access to your daily activity
4. **Get Inbox Count** - Quick status check
5. **Search System** - Find anything quickly
6. **Get Context Tasks** - What can I do right now?

### Medium Priority (Very Useful)

7. **List Habits** - Track habit progress
8. **Create Project** - Project creation
9. **Get Project Status** - Project overview
10. **Suggest Next Actions** - AI-powered recommendations
11. **Read Recent Logs** - Context for suggestions

### Lower Priority (Nice to Have)

12. **Calendar Integration** - Future enhancement
13. **Tags Management** - Organizational tool
14. **Second Brain Sync** - Integration tool

## Implementation Suggestions

### Quick Wins (Easy to Add)

These can be added quickly by wrapping existing commands:

- `list_tasks()` → Wrap `gtd-task list`
- `list_projects()` → Wrap `gtd-project list`
- `get_inbox_count()` → Count files in inbox
- `read_daily_log()` → Read log file
- `list_habits()` → Wrap `gtd-habit list`

### Medium Effort (Need Some Work)

- `search_gtd_system()` → Implement search across directories
- `get_context_tasks()` → Filter tasks by context
- `get_habit_dashboard()` → Aggregate habit data

### Complex (Require More Development)

- `suggest_next_actions()` → AI analysis of current state
- `suggest_project_breakdown()` → AI project planning
- Calendar integration → Requires calendar API

## Example Use Cases

### "What can I work on at home with low energy?"
```python
list_tasks(context="home", energy="low")
```

### "Show me my project status"
```python
projects = list_projects()
for project in projects:
    status = get_project_status(project['name'])
    # Display status
```

### "What did I log today?"
```python
log = read_daily_log()
# AI can analyze and suggest tasks
```

### "What habits should I do today?"
```python
dashboard = get_habit_dashboard()
# Show due habits
```

## Next Steps

Would you like me to:
1. ✅ Implement the high-priority tools first?
2. ✅ Create a phased implementation plan?
3. ✅ Start with quick wins (wrapping existing commands)?

Let me know which tools are most important to you!

