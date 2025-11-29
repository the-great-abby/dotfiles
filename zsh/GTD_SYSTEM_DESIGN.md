# GTD Command-Line System Design

## Overview
A comprehensive Getting Things Done (GTD) system built around command-line tools, integrated with LM Studio for AI-powered advice from multiple personas, and designed to be your central productivity pipeline.

## Core Commands

### 1. Capture System
```bash
capture "Quick note or task"
capture --type=task "Fix the bug"
capture --type=idea "New feature idea"
capture --type=link "https://example.com"
capture --interactive  # Interactive mode with prompts
```

**Features:**
- Quick capture to inbox
- Multiple capture types (note, task, idea, reminder, link, meeting, email, call)
- Auto-tagging based on keywords
- Context detection
- Voice capture (future: via speech-to-text)
- Email forwarding to capture (future)

### 2. Inbox Processing
```bash
process              # Process next item in inbox
process --all        # Process all items
process --interactive # Interactive processing with questions
process --auto       # AI-suggested categorization
```

**GTD Processing Flow:**
1. What is it?
2. Is it actionable?
   - No → Delete, Reference, or Someday/Maybe
   - Yes → Continue
3. Will it take < 2 minutes?
   - Yes → Do it now
   - No → Continue
4. Does it require multiple steps?
   - Yes → Create project
   - No → Create next action
5. Assign context, energy level, priority
6. Schedule or defer

### 3. Task Management
```bash
task list                    # List all tasks
task list --context=home     # List tasks by context
task list --energy=low       # List tasks by energy level
task list --priority=high    # List tasks by priority
task list --project=myproject # List tasks in project
task add "Task description"  # Add new task
task complete <id>          # Mark task complete
task update <id>            # Update task
task move <id> --to=project # Move task to project
```

### 4. Project Management
```bash
project list                 # List all projects
project create "Project name" # Create new project
project view <name>          # View project details
project add-task <project> "Task" # Add task to project
project status <name>        # Show project status
project archive <name>       # Archive completed project
```

### 5. Review System
```bash
review daily                 # Daily review
review weekly                # Weekly review
review project <name>        # Review specific project
review area <name>           # Review area of responsibility
review --ai                  # AI-powered review with personas
```

### 6. Search and Filter
```bash
gtd search "keyword"         # Search across all GTD items
gtd search --tag=work        # Search by tag
gtd search --context=home    # Search by context
gtd search --status=active   # Search by status
gtd search --date=2024-01-01 # Search by date
gtd filter --overdue         # Find overdue items
gtd filter --blocked         # Find blocked items
gtd filter --waiting         # Find waiting-for items
```

### 7. Multi-Persona Advice
```bash
gtd advise                   # Get advice from default persona
gtd advise --persona=cal     # Get advice from Cal Newport
gtd advise --persona=david   # Get GTD advice from David Allen
gtd advise --all             # Get advice from all personas
gtd advise --context=project # Get project-specific advice
gtd advise --review          # Get review advice
```

## Advanced Features

### 1. Context-Aware Suggestions
- AI analyzes your tasks and suggests optimal work based on:
  - Current time/energy level
  - Available contexts
  - Deadlines and priorities
  - Dependencies

### 2. Dependency Tracking
```bash
task add "Task A" --depends-on="Task B"
task view-dependencies <id>
task unblock <id>  # Show what's blocking this task
```

### 3. Recurring Tasks
```bash
task add "Weekly review" --recur=weekly
task add "Monthly report" --recur=monthly
task add "Daily standup" --recur=daily
```

### 4. Time Tracking
```bash
task start <id>              # Start time tracking
task stop <id>               # Stop time tracking
task log-time <id> 2h       # Log time manually
gtd time-report              # Generate time report
```

### 5. Areas of Responsibility
```bash
area list                    # List all areas
area create "Health"         # Create area
area view "Health"           # View area details
area add-task "Health" "Exercise" # Add task to area
```

### 6. Waiting For
```bash
waiting add "Response from John" --from="john@example.com"
waiting list                 # List all waiting-for items
waiting followup <id>        # Send follow-up reminder
waiting check                # Check for overdue follow-ups
```

### 7. Someday/Maybe
```bash
someday add "Learn Spanish"  # Add to someday/maybe
someday list                 # Review someday/maybe
someday activate <id>        # Move to active project/task
someday review               # Review with AI suggestions
```

### 8. Reference System
```bash
reference add "Article title" --url="https://..." --tags="learning,productivity"
reference search "keyword"   # Search references
reference tag <id> --add="tag" # Tag reference
reference link <id>          # Open reference
```

### 9. Calendar Integration
```bash
gtd calendar sync            # Sync with calendar
gtd calendar view            # View calendar items
gtd calendar add "Meeting" --date="2024-01-01 10:00"
gtd calendar conflicts       # Check for scheduling conflicts
```

### 10. Weekly Reports
```bash
gtd report weekly            # Generate weekly report
gtd report productivity      # Productivity metrics
gtd report completion        # Completion rates
gtd report trends            # Trend analysis
```

## Data Structure

```
~/Documents/gtd/
├── 0-inbox/                 # Captured items (unprocessed)
│   ├── 20240101120000-note.md
│   └── 20240101120100-task.md
├── 1-projects/              # Active projects
│   ├── project-name/
│   │   ├── README.md
│   │   ├── tasks/
│   │   └── notes/
├── 2-areas/                 # Areas of responsibility
│   ├── health.md
│   ├── work.md
│   └── finance.md
├── 3-reference/             # Reference material
│   ├── articles/
│   ├── links/
│   └── documents/
├── 4-someday-maybe/         # Future possibilities
├── 5-waiting-for/           # Items waiting on others
├── 6-archive/               # Completed items
├── daily-logs/              # Daily logs
├── weekly-reviews/          # Weekly reviews
└── .gtd/                    # System files
    ├── config
    ├── database.json        # Task/project database
    └── templates/
```

## File Format (Markdown with Frontmatter)

```markdown
---
id: task-20240101-001
type: task
status: active
priority: high
context: computer
energy: medium
project: my-project
area: work
tags: [urgent, bug]
created: 2024-01-01T10:00:00Z
updated: 2024-01-01T10:30:00Z
due: 2024-01-05T17:00:00Z
estimated_time: 2h
actual_time: 1h30m
depends_on: [task-20240101-000]
blocked_by: []
waiting_for: john@example.com
---

# Fix login bug

## Description
The login form is not working correctly.

## Next Actions
- [ ] Reproduce the bug
- [ ] Identify root cause
- [ ] Write fix
- [ ] Test fix

## Notes
User reported issue this morning.
```

## Persona System

Each persona provides advice tailored to their expertise:

- **Hank Hill**: General productivity, practical reminders
- **David Allen**: GTD methodology, organization
- **Cal Newport**: Deep work, focus, eliminating distractions
- **James Clear**: Habit formation, systems thinking
- **Marie Kondo**: Organization, decluttering
- **Warren Buffett**: Strategic thinking, prioritization
- **Sheryl Sandberg**: Execution, leadership
- **Tim Ferriss**: Optimization, life hacks

## AI Integration Points

1. **Auto-categorization**: AI suggests category, project, area
2. **Next action generation**: AI breaks down projects into next actions
3. **Priority suggestions**: AI suggests priority based on deadlines, dependencies
4. **Context matching**: AI suggests best context for tasks
5. **Review insights**: AI analyzes patterns and provides insights
6. **Block detection**: AI identifies blocked tasks and suggests solutions
7. **Time estimation**: AI estimates task duration based on history
8. **Habit tracking**: AI identifies patterns and suggests improvements

## Integration with Existing Systems

- **Second Brain**: Sync with your existing Second Brain structure
- **Daily Logs**: Integrate with `addInfoToDailyLog`
- **Calendar**: Two-way sync with calendar systems
- **Email**: Capture actions from emails
- **Git**: Link tasks to commits, PRs, issues
- **Time Tracking**: Integrate with time tracking tools

## Workflow Examples

### Morning Routine
```bash
# 1. Review daily log
gtd review daily

# 2. Process inbox
process --all

# 3. Get advice on priorities
gtd advise --persona=david

# 4. View today's tasks
task list --context=computer --energy=high
```

### Weekly Review
```bash
# 1. Process all inbox items
process --all

# 2. Review all projects
project list --status=active
for project in $(project list --status=active --names); do
  project review $project
done

# 3. Review areas
area list
for area in $(area list --names); do
  area review $area
done

# 4. Review waiting-for
waiting list
waiting followup --overdue

# 5. Review someday/maybe
someday review

# 6. Get AI-powered review
gtd advise --review --all

# 7. Generate weekly report
gtd report weekly
```

### Capture Workflow
```bash
# Quick capture
capture "Call John about project"

# Process later
process

# Or process immediately with AI help
capture "Fix bug" --process --ai
```

## Future Enhancements

1. **Voice capture**: "Hey GTD, capture..."
2. **Mobile app**: Companion mobile app
3. **Web interface**: Web dashboard
4. **Team collaboration**: Share projects/tasks
5. **Automation**: IFTTT/Zapier integration
6. **Analytics dashboard**: Visual analytics
7. **Habit tracking**: Built-in habit tracker
8. **Goal setting**: Long-term goal tracking
9. **Mind mapping**: Visual project maps
10. **Pomodoro integration**: Built-in timer



