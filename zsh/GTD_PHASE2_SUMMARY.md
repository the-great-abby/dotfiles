# GTD Phase 2 Commands - Summary

## ✅ All Phase 2 Commands Are Now Built!

### 1. `gtd-advise` (8.8KB) - Multi-Persona Advice Wrapper
Enhanced wrapper for getting advice from AI personas.

```bash
# Get advice from specific persona
gtd-advise hank "What should I focus on today?"
gtd-advise david "Help me organize my tasks"
gtd-advise george "I'm overwhelmed with productivity systems"

# Get advice from all personas
gtd-advise --all "Review my daily log"

# Auto-select persona based on context
gtd-advise --context=project "Review my project plan"
gtd-advise --context=focus "Help with distractions"

# Get review advice
gtd-advise --review

# Random persona
gtd-advise --random "Give me advice"

# List all personas
gtd-advise --list
```

**Features:**
- All 11 personas available
- Context-based auto-selection
- Review-specific advice
- Random selection
- Pipe input support

---

### 2. `gtd-search` (16KB) - Advanced Search & Filtering
Powerful search across all GTD items.

```bash
# Keyword search
gtd-search "bug"
gtd-search "meeting" --scope=tasks

# Search by tag
gtd-search --tag=urgent

# Search by context
gtd-search --context=computer

# Search by status
gtd-search --status=active

# Search by date
gtd-search --date=2024-01-01

# Filter overdue items
gtd-search --overdue

# Filter blocked items
gtd-search --blocked

# Filter waiting-for items
gtd-search --waiting
```

**Features:**
- Full-text search across all files
- Metadata filtering (tag, context, status, date)
- Special filters (overdue, blocked, waiting)
- Scope filtering (inbox, tasks, projects, etc.)
- Uses ripgrep/ag if available for faster search

---

### 3. `gtd-context` (9.9KB) - Context-Based Task Suggestions
Intelligent task suggestions based on current context and energy.

```bash
# Get task suggestions (auto-detects context/energy)
gtd-context

# Get suggestions with specific context
gtd-context suggest --context=home

# Get suggestions with specific energy
gtd-context suggest --energy=high

# Get more suggestions
gtd-context suggest --limit=10

# Set current context
gtd-context set home
gtd-context set computer

# Set current energy level
gtd-context set-energy high
gtd-context set-energy low

# Show current settings
gtd-context show
```

**Features:**
- Auto-detects context and energy based on time of day
- Scores tasks based on:
  - Context match
  - Energy match
  - Priority
  - Due dates
- Suggests top N tasks
- Manual context/energy override

**Scoring Algorithm:**
- Context match: +10 points
- Energy match: +5 points
- Urgent & Important: +8 points
- Due today: +10 points
- Overdue: +15 points
- Due soon (3 days): +5 points

---

### 4. `gtd-area` (13KB) - Areas of Responsibility Management
Manage ongoing areas of responsibility (separate from projects).

```bash
# Create area
gtd-area create "Health"
gtd-area create "Finance"

# List all areas
gtd-area list

# View area details
gtd-area view health

# Add task to area
gtd-area add-task health "Exercise daily"

# Add project to area
gtd-area add-project health "Fitness Program"

# Review area
gtd-area review health
```

**Features:**
- Create and manage areas
- Link projects to areas
- Link tasks to areas
- Area reviews
- Track projects and tasks per area

**Areas vs Projects:**
- **Areas**: Ongoing responsibilities (Health, Finance, Work, Family)
- **Projects**: Specific outcomes with end dates (Website Redesign, Book Writing)

---

## Complete Command Suite

### Phase 1 (Core GTD)
- ✅ `gtd-capture` - Quick capture to inbox
- ✅ `gtd-process` - Inbox processing
- ✅ `gtd-task` - Task management
- ✅ `gtd-project` - Project management
- ✅ `gtd-review` - Daily/weekly reviews

### Phase 2 (Advanced Features)
- ✅ `gtd-advise` - Multi-persona advice
- ✅ `gtd-search` - Advanced search
- ✅ `gtd-context` - Context-based suggestions
- ✅ `gtd-area` - Areas of responsibility

---

## Example Workflows

### Morning Routine with Phase 2
```bash
# 1. Check current context
gtd-context show

# 2. Get task suggestions
gtd-context suggest

# 3. Get advice on priorities
gtd-advise david "What should I focus on today?"

# 4. Process inbox
gtd-process

# 5. Search for urgent items
gtd-search --tag=urgent
```

### Weekly Review with Phase 2
```bash
# 1. Weekly review
gtd-review weekly

# 2. Review all areas
gtd-area list
for area in $(gtd-area list | grep -o '\[.*\]' | tr -d '[]'); do
  gtd-area review "$area"
done

# 3. Check for overdue items
gtd-search --overdue

# 4. Check blocked items
gtd-search --blocked

# 5. Get strategic advice
gtd-advise warren "Review my weekly priorities"
```

### Context-Aware Work Session
```bash
# 1. Set context (e.g., working from home)
gtd-context set home
gtd-context set-energy high

# 2. Get suggestions for this context
gtd-context suggest --limit=5

# 3. Work on suggested tasks
# ... do work ...

# 4. When energy drops
gtd-context set-energy low
gtd-context suggest  # Get low-energy tasks
```

### Area Management
```bash
# 1. Create areas for life domains
gtd-area create "Health"
gtd-area create "Finance"
gtd-area create "Career"
gtd-area create "Relationships"

# 2. Add projects to areas
gtd-area add-project health "Fitness Program"
gtd-area add-project finance "Investment Strategy"

# 3. Add tasks to areas
gtd-area add-task health "Exercise 3x per week"
gtd-area add-task finance "Review budget monthly"

# 4. Review areas regularly
gtd-area review health
gtd-area review finance
```

---

## Integration Points

All Phase 2 commands integrate with Phase 1:

- **gtd-advise** works with `gtd-review` for review advice
- **gtd-search** searches all items created by other commands
- **gtd-context** suggests tasks from `gtd-task` and `gtd-project`
- **gtd-area** organizes projects and tasks from Phase 1

---

## Tips

1. **Use gtd-context regularly** - Get suggestions based on where you are and how you feel
2. **Set context/energy** - Export in your shell config for persistence:
   ```bash
   export GTD_CURRENT_CONTEXT="computer"
   export GTD_CURRENT_ENERGY="high"
   ```
3. **Search before creating** - Use `gtd-search` to avoid duplicates
4. **Review areas weekly** - Keep areas of responsibility balanced
5. **Get multiple perspectives** - Use `gtd-advise --all` for complex decisions

---

## Next Steps

All Phase 1 and Phase 2 commands are complete! You now have a full-featured GTD system.

Future enhancements (Phase 3):
- Calendar integration
- Email integration
- Analytics and reporting
- Dependency tracking
- Time tracking
- Recurring tasks



