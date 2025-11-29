# GTD Commands - Quick Reference

## ✅ All Phase 1 Commands Are Now Built!

### 1. `gtd-process` - Inbox Processing
Process items from your inbox using GTD methodology.

```bash
# Process next item in inbox
gtd-process

# Process all items in inbox
gtd-process --all
```

**What it does:**
- Guides you through GTD processing questions
- Helps decide: delete, reference, someday/maybe, project, or task
- Creates projects or tasks as needed
- Moves items to appropriate locations

---

### 2. `gtd-task` - Task Management
Manage your tasks: add, list, complete, update, move.

```bash
# Add a new task
gtd-task add "Fix the bug"

# List all active tasks
gtd-task list

# List tasks by context
gtd-task list --context=computer

# List tasks by energy level
gtd-task list --energy=low

# List tasks by priority
gtd-task list --priority=urgent_important

# Complete a task
gtd-task complete 20240101120000-task

# Update a task
gtd-task update 20240101120000-task

# Move task to project
gtd-task move 20240101120000-task website-redesign
```

**Filters for list:**
- `--context=<context>` - home, office, computer, phone, errands
- `--energy=<level>` - low, medium, high, creative, administrative
- `--priority=<priority>` - urgent_important, not_urgent_important, etc.
- `--project=<project>` - Filter by project
- `--status=<status>` - active, on-hold, done

---

### 3. `gtd-project` - Project Management
Create and manage projects.

```bash
# Create a new project
gtd-project create "Website Redesign"

# List all active projects
gtd-project list

# View project details
gtd-project view website-redesign

# Add task to project
gtd-project add-task website-redesign "Design homepage"

# Show project status
gtd-project status website-redesign

# Archive completed project
gtd-project archive website-redesign
```

**Project structure:**
- Each project has its own directory
- Contains README.md with project info
- Can contain multiple task files

---

### 4. `gtd-review` - Reviews
Daily and weekly reviews with structured questions.

```bash
# Daily review
gtd-review daily

# Weekly review
gtd-review weekly

# Review specific project
gtd-review project website-redesign
```

**Daily review includes:**
- Top 3 priorities
- Yesterday's accomplishments
- Blockers
- Needs attention
- Optional AI advice

**Weekly review includes:**
- Projects needing attention
- Inbox items
- Calendar for next week
- Waiting for follow-ups
- Someday/Maybe activation
- Areas of responsibility
- Optional AI advice from multiple personas

---

## Complete Workflow Example

### Morning Routine
```bash
# 1. Daily review
gtd-review daily

# 2. Process inbox
gtd-process --all

# 3. View tasks for today
gtd-task list --context=computer --energy=high
```

### Throughout the Day
```bash
# Quick capture
gtd-capture "Call John about project"

# Add task directly
gtd-task add "Review PR #123"
```

### End of Day
```bash
# Process any remaining inbox items
gtd-process

# Check what's left
gtd-task list --status=active
```

### Weekly Routine
```bash
# Weekly review
gtd-review weekly

# Review all projects
gtd-project list
for project in $(gtd-project list | grep -o '\[.*\]' | tr -d '[]'); do
  gtd-review project "$project"
done
```

---

## File Structure

All commands work with this structure:
```
~/Documents/gtd/
├── 0-inbox/              # Captured items (gtd-capture)
├── 1-projects/           # Projects (gtd-project)
│   └── project-name/
│       ├── README.md
│       └── tasks...
├── 2-areas/              # Areas of responsibility
├── 3-reference/          # Reference material
├── 4-someday-maybe/      # Future possibilities
├── 5-waiting-for/        # Waiting on others
├── 6-archive/            # Completed items
├── tasks/                # Standalone tasks (gtd-task)
└── weekly-reviews/       # Review files (gtd-review)
```

---

## Integration with Existing Commands

- `gtd-capture` → Creates items in inbox
- `gtd-process` → Processes inbox items
- `gtd-task` → Manages tasks
- `gtd-project` → Manages projects
- `gtd-review` → Structured reviews
- `gtd-advise` → Get AI advice from personas
- `addInfoToDailyLog` → Daily logging with AI advice

---

## Tips

1. **Start with capture** - Use `gtd-capture` throughout the day
2. **Process regularly** - Run `gtd-process` at least once daily
3. **Use contexts** - Tag tasks with contexts for better filtering
4. **Review weekly** - `gtd-review weekly` keeps you on track
5. **Get AI help** - Use `gtd-advise` for guidance

---

## Next Steps

All Phase 1 commands are complete! You can now:
- ✅ Capture items to inbox
- ✅ Process inbox items
- ✅ Manage tasks
- ✅ Manage projects
- ✅ Do daily/weekly reviews

Future enhancements (Phase 2):
- Advanced search and filtering
- Areas of responsibility management
- Context-based suggestions
- Analytics and reporting



