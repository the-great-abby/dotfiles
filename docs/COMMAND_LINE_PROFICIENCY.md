# Command Line Proficiency - GTD Scripts Reference

> **Master your GTD command line tools** - Comprehensive guide to all scripts in the `bin/` directory, organized by activity type and process.

## 📚 Table of Contents

- [Core GTD Workflow](#core-gtd-workflow)
- [Task Management](#task-management)
- [Project Management](#project-management)
- [Area Management](#area-management)
- [Daily Logging & Tracking](#daily-logging--tracking)
- [Reviews & Planning](#reviews--planning)
- [Second Brain & Knowledge](#second-brain--knowledge)
- [Advice & Suggestions](#advice--suggestions)
- [Learning & Study](#learning--study)
- [Health & Wellness](#health--wellness)
- [Calendar & Scheduling](#calendar--scheduling)
- [System Management](#system-management)
- [Workers & Background Tasks](#workers--background-tasks)
- [Utilities & Helpers](#utilities--helpers)

---

## Core GTD Workflow

### `gtd-capture`

Quick capture to inbox - Get things out of your head and into the system.

**Usage:**
```bash
gtd-capture "Call John about project"
gtd-capture --type=task "Review the report"
gtd-capture --interactive
```

**When to use:**
- Throughout the day when something comes to mind
- During meetings or conversations
- When you don't have time to fully process something
- Quick capture of ideas, tasks, or notes

**Tips:**
- Use it liberally - capture everything, process later
- Use `--interactive` mode for structured capture
- Process your inbox regularly with `gtd-process`

---

### `gtd-process`

Process inbox items using GTD methodology - Decide what to do with each item.

**Usage:**
```bash
gtd-process              # Process next item
gtd-process --all        # Process all items
```

**When to use:**
- Daily (recommended) or at least weekly
- When your inbox has items
- After capturing multiple items

**The GTD Process:**
1. Is it actionable?
   - Yes → Do it (if < 2 min), delegate it, or defer it
   - No → Trash it, incubate it (someday/maybe), or file it (reference)
2. If deferring → Create task, project, or add to calendar
3. If filing → Move to appropriate reference location

---

### `gtd-checkin`

Interactive check-in system - Review your system and get suggestions.

**Usage:**
```bash
gtd-checkin
```

**When to use:**
- Daily check-in routine
- When you need to refocus
- To get personalized suggestions

---

## Task Management

### `gtd-task`

Comprehensive task management - Create, view, update, and complete tasks.

**Usage:**
```bash
gtd-task add "task description"
gtd-task add "task" --priority=high --context=computer
gtd-task list
gtd-task list --context=computer
gtd-task list --priority=high
gtd-task complete <task-id>
gtd-task view <task-id>
gtd-task update <task-id> --priority=medium
```

**When to use:**
- After processing inbox items that are actionable
- When you need to track specific actions
- To organize work by context, priority, or energy level

**Task Properties:**
- **Priority**: low, medium, high
- **Context**: computer, phone, home, errands, etc.
- **Energy**: low, medium, high
- **Project**: Link to a project (optional)

---

## Project Management

### `gtd-project`

Project management - Create and manage multi-step projects.

**Usage:**
```bash
gtd-project create "Project Name"
gtd-project create "Project" --area="Work - SRE"
gtd-project list
gtd-project view <project-name>
gtd-project add-task <project-name> "task description"
gtd-project complete <project-name>
```

**When to use:**
- For outcomes that require multiple steps
- When tasks are related and have a clear outcome
- To organize work by larger goals

**Project Structure:**
- Projects contain multiple tasks
- Projects can belong to areas
- Projects have notes in `notes/` subdirectory
- Projects can be active, on-hold, or completed

---

## Area Management

### `gtd-area`

Areas of responsibility - Manage ongoing areas that require maintenance.

**Usage:**
```bash
gtd-area create "Area Name"
gtd-area list
gtd-area view <area-name>
gtd-area add-task <area-name> "task description"
gtd-area add-project <area-name> "project name"
```

**When to use:**
- For ongoing responsibilities (Health, Finances, Home, etc.)
- When you need to maintain standards
- To organize projects and tasks by life area

**Area Structure:**
- Areas contain projects and tasks
- Areas are ongoing (no completion date)
- Areas focus on standards and maintenance

---

## Daily Logging & Tracking

### `addInfoToDailyLog`

Log daily activities and get advice - Track your day and receive persona feedback.

**Usage:**
```bash
addInfoToDailyLog "Completed the report"
addInfoToDailyLog "Meeting with team about Q4 planning"
```

**When to use:**
- Throughout the day to track activities
- To log accomplishments
- To get random persona advice
- To maintain a record of your days

**Features:**
- Automatically creates daily log entries
- Triggers random persona advice
- Tracks your progress over time
- Integrates with task suggestions

---

### `gtd-daily-log`

View and manage daily logs.

**Usage:**
```bash
gtd-daily-log              # View today's log
gtd-daily-log 2024-01-15   # View specific date
gtd-daily-log list         # List all logs
```

---

### `gtd-log-stats`

View statistics about your daily logs.

**Usage:**
```bash
gtd-log-stats
```

---

## Reviews & Planning

### `gtd-review`

Conduct daily, weekly, or monthly reviews.

**Usage:**
```bash
gtd-review daily
gtd-review weekly
gtd-review monthly
```

**When to use:**
- **Daily**: Quick check-in (5-10 min)
- **Weekly**: Comprehensive review (30-60 min)
- **Monthly**: Strategic review (1-2 hours)

**Review Process:**
- Review completed tasks
- Review active projects
- Review areas of responsibility
- Review calendar and upcoming commitments
- Review someday/maybe list
- Plan next actions

---

### `gtd-morning`

Morning routine - Start your day with focus.

**Usage:**
```bash
gtd-morning
```

**When to use:**
- At the start of each workday
- To set daily priorities
- To review your calendar

---

### `gtd-evening`

Evening routine - End your day with reflection.

**Usage:**
```bash
gtd-evening
```

**When to use:**
- At the end of each workday
- To reflect on accomplishments
- To plan for tomorrow

---

### `gtd-afternoon`

Afternoon check-in - Midday refocus.

**Usage:**
```bash
gtd-afternoon
```

---

### `gtd-plan`

Planning and goal setting.

**Usage:**
```bash
gtd-plan
```

---

## Second Brain & Knowledge

### `gtd-brain`

Second Brain operations - Create and manage knowledge notes.

**Usage:**
```bash
gtd-brain create "Note Title"
gtd-brain link <item> <note>
gtd-brain search "query"
```

**When to use:**
- To create knowledge notes
- To link GTD items to Second Brain
- To search your knowledge base

---

### `gtd-brain-moc`

Maps of Content (MOC) - Create index notes for topics.

**Usage:**
```bash
gtd-brain-moc create "Topic"
gtd-brain-moc list
gtd-brain-moc view "Topic"
```

**When to use:**
- To organize notes by topic
- To create knowledge hubs
- To discover connections

---

### `gtd-brain-evergreen`

Evergreen notes - Manage notes that grow in value over time.

**Usage:**
```bash
gtd-brain-evergreen create "Note Title"
gtd-brain-evergreen list
```

**When to use:**
- For insights and learnings
- For principles and concepts
- For notes you'll revisit and refine

---

### `gtd-brain-sync`

Sync GTD items with Second Brain.

**Usage:**
```bash
gtd-brain-sync
```

**When to use:**
- After creating GTD items
- To keep systems in sync
- Automatically runs in background

---

### `gtd-brain-express`

Express phase - Create content from your Second Brain.

**Usage:**
```bash
gtd-brain-express create "Title" "notes.md,other.md" blog
```

**When to use:**
- To create blog posts, articles, presentations
- To share knowledge from your Second Brain

---

### `gtd-brain-distill`

Progressive summarization - Distill notes into key insights.

**Usage:**
```bash
gtd-brain-distill <note-file>
```

---

### `gtd-brain-diverge`

Divergence phase - Brainstorm ideas without judgment.

**Usage:**
```bash
gtd-brain-diverge "Topic"
```

---

### `gtd-brain-converge`

Convergence phase - Narrow down ideas to the best ones.

**Usage:**
```bash
gtd-brain-converge "Topic"
```

---

### `gtd-brain-connect`

Connection notes - Create explicit connections between ideas.

**Usage:**
```bash
gtd-brain-connect "Idea 1" "Idea 2"
```

---

### `gtd-brain-discover`

Discovery - Find connections and insights across your knowledge base.

**Usage:**
```bash
gtd-brain-discover
```

---

## Advice & Suggestions

### `gtd-advise`

Get advice from AI personas - Ask questions and get guidance.

**Usage:**
```bash
gtd-advise david "How should I organize my tasks?"
gtd-advise --list
gtd-advise --all "What should I focus on today?"
```

**Available Personas:**
- **david**: GTD expert (David Allen)
- **tiago**: Second Brain expert (Tiago Forte)
- **sonke**: Zettelkasten expert (Sönke Ahrens)
- **mistress-louiza**: Accountability partner
- And more...

**When to use:**
- When you need guidance
- When you're stuck
- To get different perspectives
- For accountability

---

### `gtd-auto-suggest`

Auto-suggestion system - Get intelligent suggestions for your GTD system.

**Usage:**
```bash
gtd-auto-suggest
```

**When to use:**
- To get task suggestions from daily logs
- To get project suggestions
- To get area assignment suggestions
- To discover insights

---

### `gtd-smart-suggestions`

Smart suggestions - Advanced suggestion system.

**Usage:**
```bash
gtd-smart-suggestions
```

---

## Learning & Study

### `gtd-learn`

Learn the GTD system with Mistress Louiza as instructor.

**Usage:**
```bash
gtd-learn
gtd-learn capture
gtd-learn tasks
```

**Topics:**
- Unified System Basics
- Capture & Inbox
- Processing
- Task Management
- Project Management
- Reviews
- Daily Logging
- Contexts
- Energy Levels
- Zettelkasten
- Second Brain
- And more...

---

### `gtd-learn-kubernetes`

Learn Kubernetes/CKA with Mistress Louiza.

**Usage:**
```bash
gtd-learn-kubernetes
gtd-learn-kubernetes pods
gtd-learn-kubernetes cka-exam
```

**When to use:**
- For CKA exam preparation
- To learn Kubernetes concepts
- For hands-on practice

---

### `gtd-learn-greek`

Learn Greek language with Mistress Louiza.

**Usage:**
```bash
gtd-learn-greek
gtd-learn-greek vocabulary
```

---

### `gtd-quiz`

Take quizzes on various topics.

**Usage:**
```bash
gtd-quiz
gtd-quiz organization-system
gtd-quiz second-brain
gtd-quiz cka-kubernetes
```

**Quiz Modes:**
- Practice Quiz (5 questions, untimed)
- Timed Quiz (10 questions, 2 min each)
- Pop Quiz (3 random questions)

---

### `gtd-study-plan`

Create study plans for learning topics.

**Usage:**
```bash
gtd-study-plan cka
```

---

## Health & Wellness

### `gtd-health-reminder`

Health reminders and tracking.

**Usage:**
```bash
gtd-health-reminder
```

---

### `gtd-food-reminder`

Food and meal reminders.

**Usage:**
```bash
gtd-food-reminder
```

---

### `gtd-lunch-reminder`

Lunch break reminder.

**Usage:**
```bash
gtd-lunch-reminder
```

---

### `gtd-healthkit-log`

Log HealthKit data.

**Usage:**
```bash
gtd-healthkit-log
```

---

### `gtd-log-mood`

Log mood and emotional state.

**Usage:**
```bash
gtd-log-mood
```

---

### `gtd-log-weather`

Log weather information.

**Usage:**
```bash
gtd-log-weather
```

---

## Calendar & Scheduling

### `gtd-calendar`

Calendar management and viewing.

**Usage:**
```bash
gtd-calendar
gtd-calendar today
gtd-calendar week
```

---

### `gtd-log-calendar`

Log calendar events to daily log.

**Usage:**
```bash
gtd-log-calendar
```

---

## System Management

### `gtd-context`

Context-based task suggestions.

**Usage:**
```bash
gtd-context
```

**When to use:**
- To see tasks for your current context
- To filter tasks by location/device
- To get context-aware suggestions

---

### `gtd-search`

Search across your GTD system.

**Usage:**
```bash
gtd-search "query"
gtd-search "project" --type=project
```

**When to use:**
- To find tasks, projects, areas, or notes
- To search by keyword
- To discover related items

---

### `gtd-find`

Find items in your GTD system.

**Usage:**
```bash
gtd-find "keyword"
```

---

### `gtd-dashboard`

View system dashboard.

**Usage:**
```bash
gtd-dashboard
```

---

### `gtd-now`

See what you should do now.

**Usage:**
```bash
gtd-now
```

---

### `gtd-config-split`

Split and manage GTD config files.

**Usage:**
```bash
gtd-config-split
```

---

### `gtd-diagnose-suggestions`

Diagnose suggestion system issues.

**Usage:**
```bash
gtd-diagnose-suggestions
```

---

### `gtd-worker-status`

Check status of background workers.

**Usage:**
```bash
gtd-worker-status
```

---

### `gtd-vector-db-status`

Check vector database status.

**Usage:**
```bash
gtd-vector-db-status
```

---

## Workers & Background Tasks

### `gtd-advice-worker`

Background worker for advice requests.

**Usage:**
```bash
gtd-advice-worker
```

---

### `gtd-advice-worker-python`

Python version of advice worker.

**Usage:**
```bash
gtd-advice-worker-python
```

---

### `gtd-deep-analysis-worker`

Background worker for deep analysis.

**Usage:**
```bash
gtd-deep-analysis-worker
```

---

### `gtd-task-org-worker`

Background worker for task organization.

**Usage:**
```bash
gtd-task-org-worker
```

---

### `gtd-vector-worker`

Background worker for vector operations.

**Usage:**
```bash
gtd-vector-worker
```

---

## Utilities & Helpers

### `gtd-help`

Interactive help system.

**Usage:**
```bash
gtd-help
```

**Features:**
- Quick start guide
- Command reference
- Example workflows
- Daily tips
- Interactive tutorial
- Command discovery
- System status check

---

### `gtd-tips`

Get random tips about using the system.

**Usage:**
```bash
gtd-tips
```

---

### `gtd-wizard`

Interactive wizard for GTD operations.

**Usage:**
```bash
gtd-wizard
```

**Features:**
- Guided workflows
- Interactive menus
- Context-aware suggestions
- Learning integration

---

### `gtd-aliases`

Suggest useful aliases.

**Usage:**
```bash
gtd-aliases
```

---

### `gtd-welcome`

Welcome message and quick start.

**Usage:**
```bash
gtd-welcome
```

---

## 🚀 Quick Reference

### Most Common Commands

```bash
# Capture something quickly
gtd-capture "your text here"

# Process your inbox
gtd-process

# Add a task
gtd-task add "task description"

# View tasks
gtd-task list

# Log your day
addInfoToDailyLog "what you did"

# Daily review
gtd-review daily

# Get advice
gtd-advise david "your question"

# Search
gtd-search "query"
```

### Learning Commands

```bash
# Learn GTD system
gtd-learn

# Learn Kubernetes/CKA
gtd-learn-kubernetes

# Learn Greek
gtd-learn-greek

# Take a quiz
gtd-quiz
```

### Second Brain Commands

```bash
# Create a note
gtd-brain create "note title"

# Create MOC
gtd-brain-moc create "topic"

# Sync with Second Brain
gtd-brain-sync
```

### Daily Workflow

```bash
# Morning
gtd-morning
gtd-process

# During the day
gtd-capture "ideas"
addInfoToDailyLog "activities"
gtd-task list

# Evening
gtd-evening
gtd-review daily
```

---

## 📖 Learning Path

### Beginner
1. Start with `gtd-capture` and `gtd-process`
2. Learn `gtd-task` basics
3. Use `addInfoToDailyLog` daily
4. Try `gtd-review daily`

### Intermediate
1. Learn `gtd-project` and `gtd-area`
2. Explore `gtd-brain` commands
3. Use `gtd-advise` for guidance
4. Try `gtd-learn` for system mastery

### Advanced
1. Master Second Brain workflows
2. Use auto-suggestions
3. Integrate learning systems
4. Customize with `gtd-wizard`

---

*Last updated: 2025-01-20*

