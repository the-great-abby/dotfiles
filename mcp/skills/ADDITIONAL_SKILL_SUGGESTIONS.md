# Additional Skill Suggestions Based on System Capabilities

Based on analysis of your GTD system's full capabilities, here are additional skills that would be valuable:

## High-Priority Skills (Core Workflows)

### 1. **Evening Check-In** ⭐
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Guides through evening wrap-up routine
- Reviews accomplishments from the day
- Processes any remaining inbox items
- Sets priorities for tomorrow
- Creates reflection log entry

**MCP Tools Used:**
- `read_daily_log(date="today")`
- `list_tasks(status="active")`
- `complete_task()` for completed items
- `get_inbox_count()` to check inbox
- `suggest_tasks_from_text()` for tomorrow's planning

**Why it's valuable:**
- Completes the daily routine (morning + evening)
- Provides closure and reflection
- Sets up next day for success

---

### 2. **Weekly Review** ⭐
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Comprehensive weekly review workflow
- Reviews all projects and their status
- Analyzes task completion patterns
- Identifies areas needing attention
- Plans for upcoming week
- Uses deep analysis for insights

**MCP Tools Used:**
- `weekly_review(week_start)` - Deep analysis
- `list_projects(status="all")`
- `get_project_status()` for each project
- `list_tasks(status="active")`
- `find_connections(scope="week")`
- `generate_insights(focus="weekly_patterns")`
- `read_recent_logs(days=7)`

**Why it's valuable:**
- Critical GTD practice
- Provides comprehensive system overview
- Identifies patterns and improvements

---

### 3. **Project Kickoff** ⭐
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Guides through project initialization
- Creates project structure
- Defines initial tasks
- Sets up project documentation
- Links to Second Brain if needed
- Uses AI for project planning

**MCP Tools Used:**
- `create_project(name, description)`
- `create_task()` for initial tasks
- `plan_with_ai()` if available
- `gtd_search_second_brain()` for related notes
- `gtd_create_note()` for project documentation

**Why it's valuable:**
- Standardizes project creation
- Ensures nothing is missed
- Sets projects up for success

---

### 4. **Log-to-Tasks Conversion** ⭐
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Analyzes daily log entries for actionable items
- Suggests tasks based on log content
- Creates tasks from log insights
- Identifies patterns in logs

**MCP Tools Used:**
- `read_recent_logs(days=7)`
- `suggest_tasks_from_text(text="<log content>")`
- `create_task()` for high-confidence suggestions
- `gtd_search_second_brain()` for context

**Why it's valuable:**
- Captures tasks from daily activity
- Prevents losing actionable items
- Connects logs to task system

---

## Second Brain Skills (Knowledge Management)

### 5. **Progressive Summarization Workflow**
**Status:** New suggestion

**What it does:**
- Guides through progressive summarization process
- Helps identify key insights in notes
- Creates summary layers
- Marks notes for further distillation
- Tracks summarization progress

**Commands Used:**
- `gtd-brain-distill <note>`
- `gtd-brain summarize <note> <level>`
- `gtd-brain-evergreen mark <note>`

**Why it's valuable:**
- Core Second Brain practice
- Builds knowledge systematically
- Makes notes more valuable over time

---

### 6. **MOC Creation & Maintenance**
**Status:** New suggestion

**What it does:**
- Guides creation of Maps of Content
- Helps organize notes by topic
- Auto-populates MOCs from tags
- Maintains MOC structure
- Discovers connections for MOCs

**Commands Used:**
- `gtd-brain-moc create "Topic"`
- `gtd-brain-moc add "Topic" <note>`
- `gtd-brain-moc auto "Topic" <tag>`
- `gtd-brain-discover <note>` for connections

**Why it's valuable:**
- Organizes knowledge by topic
- Makes Second Brain more navigable
- Discovers relationships

---

### 7. **Evergreen Note Development**
**Status:** New suggestion

**What it does:**
- Identifies notes worth developing as evergreen
- Guides progressive refinement
- Tracks evergreen note growth
- Connects evergreen notes
- Maintains evergreen note quality

**Commands Used:**
- `gtd-brain-evergreen mark <note>`
- `gtd-brain-evergreen refine <note>`
- `gtd-brain-evergreen connections <note>`
- `gtd-brain-connect create <note1> <note2>`

**Why it's valuable:**
- Builds high-value knowledge
- Creates notes that improve over time
- Forms knowledge network

---

### 8. **Express Phase - Content Creation**
**Status:** New suggestion

**What it does:**
- Guides content creation from Second Brain
- Identifies notes suitable for content
- Creates drafts from multiple notes
- Tracks content ideas
- Manages content pipeline

**Commands Used:**
- `gtd-brain-express create "Title" "notes" <type>`
- `gtd-brain-express drafts`
- `gtd-brain-express idea "Description"`
- `gtd-brain-packet create <note> <name>`

**Why it's valuable:**
- Turns knowledge into shareable content
- Leverages Second Brain for creation
- Builds content pipeline

---

## Learning & Development Skills

### 9. **Learning Session Workflow**
**Status:** New suggestion

**What it does:**
- Guides structured learning sessions
- Creates notes from learning materials
- Links learning to projects/areas
- Tracks learning progress
- Creates practice tasks

**Commands Used:**
- `gtd-learn` for learning system
- `gtd-brain create "Learning Note" Resources`
- `create_task()` for practice exercises
- `gtd-brain-moc add "Learning" <note>`

**Why it's valuable:**
- Structures learning process
- Connects learning to GTD system
- Tracks learning progress

---

### 10. **Knowledge Discovery Session**
**Status:** New suggestion

**What it does:**
- Guides exploration of Second Brain
- Discovers connections between notes
- Identifies knowledge gaps
- Suggests new connections
- Creates connection notes

**Commands Used:**
- `gtd-brain-discover <note>`
- `gtd-brain-connect create <note1> <note2>`
- `gtd-brain search "query"`
- `gtd_search_second_brain(query)`

**Why it's valuable:**
- Uncovers hidden connections
- Builds knowledge network
- Identifies areas for exploration

---

## Planning & Review Skills

### 11. **Monthly Review**
**Status:** New suggestion

**What it does:**
- Comprehensive monthly review
- Reviews all areas of responsibility
- Analyzes monthly patterns
- Sets monthly goals
- Plans for next month

**MCP Tools Used:**
- `list_areas()`
- `list_projects(status="all")`
- `read_recent_logs(days=30)`
- `generate_insights(focus="monthly_patterns")`
- `analyze_energy(days=30)`

**Why it's valuable:**
- Higher-level review than weekly
- Reviews areas of responsibility
- Sets monthly direction

---

### 12. **Area Review**
**Status:** New suggestion

**What it does:**
- Reviews specific area of responsibility
- Lists all projects in area
- Reviews area-related tasks
- Identifies area improvements
- Sets area goals

**MCP Tools Used:**
- `list_areas()`
- `list_projects()` filtered by area
- `list_tasks()` filtered by area
- `get_project_status()` for area projects

**Why it's valuable:**
- Focuses on specific life areas
- Maintains balance across areas
- Ensures areas get attention

---

## Energy & Health Skills

### 13. **Energy Audit & Planning**
**Status:** New suggestion

**What it does:**
- Analyzes energy patterns
- Matches tasks to energy levels
- Plans day based on energy
- Tracks energy drains and boosts
- Suggests energy-optimized schedules

**MCP Tools Used:**
- `analyze_energy(days=7)`
- `list_tasks(energy="high")` / `energy="low"`
- `get_context_tasks(context, energy)`
- Health data integration (if available)

**Why it's valuable:**
- Optimizes productivity
- Matches work to energy
- Prevents burnout

---

### 14. **Habit Check-In**
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Guides daily habit check-in
- Tracks habit completion
- Identifies habit patterns
- Suggests habit improvements
- Links habits to tasks

**MCP Tools Used:**
- Habit tracking tools (if available)
- `read_daily_log(date="today")` for habit entries
- `create_task()` for habit-related tasks

**Why it's valuable:**
- Maintains habit tracking
- Connects habits to GTD system
- Builds consistency

---

## Task Management Skills

### 15. **Task Prioritization Guidance**
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Provides prioritization framework
- Analyzes task priorities
- Suggests priority adjustments
- Uses Eisenhower Matrix
- Considers context and energy

**MCP Tools Used:**
- `list_tasks(status="active")`
- `get_task_details()` for analysis
- `update_task(priority=...)` for adjustments
- `get_context_tasks()` for context-based prioritization

**Why it's valuable:**
- Ensures focus on important tasks
- Provides prioritization framework
- Optimizes task selection

---

### 16. **Context Switching Workflow**
**Status:** New suggestion

**What it does:**
- Helps transition between contexts
- Reviews tasks for new context
- Closes out current context work
- Prepares for context switch
- Minimizes context switching overhead

**MCP Tools Used:**
- `get_context_tasks(context="current")`
- `get_context_tasks(context="next")`
- `complete_task()` for finished items
- `update_task()` for context changes

**Why it's valuable:**
- Reduces context switching cost
- Smooth transitions
- Better focus management

---

## Analysis & Insights Skills

### 17. **Deep Analysis Request**
**Status:** Suggested in SKILL_SUGGESTIONS.md, not yet implemented

**What it does:**
- Guides when to request deep analysis
- Explains different analysis types
- Requests appropriate analysis
- Reviews analysis results
- Acts on insights

**MCP Tools Used:**
- `weekly_review(week_start)`
- `analyze_energy(days)`
- `find_connections(scope)`
- `generate_insights(focus)`

**Why it's valuable:**
- Leverages deep analysis capabilities
- Provides insights when needed
- Guides analysis usage

---

### 18. **Pattern Recognition Session**
**Status:** New suggestion

**What it does:**
- Analyzes patterns across system
- Identifies recurring themes
- Finds connections between items
- Suggests system improvements
- Creates insights from patterns

**MCP Tools Used:**
- `find_connections(scope="all")`
- `generate_insights(focus="patterns")`
- `read_recent_logs(days=30)`
- `list_tasks()` for task patterns

**Why it's valuable:**
- Discovers system insights
- Identifies improvement opportunities
- Builds self-awareness

---

## Integration Skills

### 19. **GTD-Second Brain Sync Workflow**
**Status:** New suggestion

**What it does:**
- Guides bidirectional sync process
- Links GTD items to Second Brain notes
- Creates notes from GTD items
- Maintains link integrity
- Reviews sync status

**Commands Used:**
- `gtd-brain-sync`
- `gtd-brain link <item> <note>`
- `gtd-brain create` from GTD items
- `gtd-brain search` for related notes

**Why it's valuable:**
- Maintains system integration
- Connects action and knowledge
- Ensures nothing is lost

---

### 20. **Calendar-Task Integration**
**Status:** New suggestion

**What it does:**
- Syncs tasks with calendar
- Schedules time for tasks
- Reviews calendar for task opportunities
- Creates tasks from calendar events
- Manages time-blocking

**MCP Tools Used:**
- Calendar integration tools (if available)
- `list_tasks()` for scheduling
- `create_task()` from calendar events
- `update_task()` for time blocks

**Why it's valuable:**
- Connects tasks to time
- Better time management
- Realistic scheduling

---

## Priority Recommendations

### Phase 1: Complete Core Workflows (Week 1-2)
1. **evening-checkin** - Complete daily routine
2. **weekly-review** - Critical GTD practice
3. **project-kickoff** - Standardize project creation

### Phase 2: Second Brain Integration (Week 3-4)
4. **progressive-summarization** - Core knowledge building
5. **moc-creation** - Organize knowledge
6. **gtd-second-brain-sync** - Maintain integration

### Phase 3: Planning & Analysis (Week 5-6)
7. **monthly-review** - Higher-level planning
8. **energy-audit** - Optimize productivity
9. **pattern-recognition** - System insights

### Phase 4: Specialized Workflows (Week 7-8)
10. **express-phase** - Content creation
11. **learning-session** - Structured learning
12. **task-prioritization** - Focus management

---

## Skills Already Implemented ✅

- ✅ interactive-morning-review-runbook (interactive runbook, replaces morning-checkin)
- ✅ daily-review
- ✅ inbox-processing
- ✅ task-summary
- ✅ context-task-selection
- ✅ project-status-review
- ✅ personalization-info
- ✅ personalization-learning
- ✅ diagram-generation (just added)

---

## Next Steps

Would you like me to:
1. **Create specific skill implementations** for any of these?
2. **Prioritize based on your usage patterns**?
3. **Create a batch of high-priority skills**?

Let me know which skills you'd like implemented first!
