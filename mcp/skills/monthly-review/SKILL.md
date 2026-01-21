---
name: Monthly Review
description: Comprehensive monthly review process covering system cleanup, strategic assessment, area review, goal progress, habit analysis, and planning for the next month. Higher-level review than weekly review.
version: 1.0.0
tags:
  - review
  - monthly
  - strategic
  - planning
  - assessment
author: GTD System
---

# Monthly Review Workflow

A comprehensive monthly review process that goes deeper than weekly reviews, focusing on strategic assessment, system cleanup, area maintenance, and planning for the month ahead.

## When to Use

Use this skill when you need to:
- **Monthly strategic review**: Step back and assess progress
- **System cleanup**: Archive completed items
- **Area review**: Review all areas of responsibility
- **Goal assessment**: Check progress on monthly goals
- **Pattern analysis**: Identify monthly patterns
- **Next month planning**: Plan for the month ahead

## How It Works

This workflow combines system cleanup, strategic assessment, area review, and planning using MCP tools and deep analysis capabilities.

## Step-by-Step Workflow

### Phase 1: System Cleanup (30-45 minutes)

#### Step 1: Archive Completed Projects

**Purpose:** Keep system clean and focused.

**Actions:**
1. List all projects:
   ```python
   list_projects(status="all")
   ```
2. For each project:
   - Review project status
   - Check if project is complete
   - Archive completed projects
   - Update project status

**MCP Tools:**
- `list_projects(status="all")` - Get all projects
- `get_project_status(project_name)` - Check project status

**Commands:**
- `gtd-project list` - List all projects
- `gtd-project archive "project-name"` - Archive project

**Questions to ask:**
- Is this project truly complete?
- Are all outcomes achieved?
- Should it be archived or kept active?

---

#### Step 2: Archive Completed Tasks

**Purpose:** Remove clutter from active lists.

**Actions:**
1. List completed tasks:
   ```python
   list_tasks(status="completed")
   ```
2. Review and archive:
   - Archive completed tasks
   - Delete obsolete tasks
   - Update task status

**MCP Tools:**
- `list_tasks(status="completed")` - Get completed tasks

**What to archive:**
- Tasks completed this month
- Tasks no longer relevant
- Tasks that became obsolete

---

#### Step 3: Review and Clean Inbox

**Purpose:** Ensure inbox is truly empty.

**Actions:**
1. Check inbox count:
   ```python
   get_inbox_count()
   ```
2. Process all items:
   - Use `inbox-processing` skill if needed
   - Delete obsolete items
   - Archive reference items
   - Ensure zero items

**MCP Tools:**
- `get_inbox_count()` - Check inbox status

**Goal:**
- Inbox should be empty
- All items processed
- Nothing left hanging

---

#### Step 4: Review Waiting For List

**Purpose:** Follow up on overdue items.

**Actions:**
1. Review all waiting items
2. For each item:
   - Check if still waiting
   - Follow up if overdue
   - Archive if resolved
   - Update status

**What to do:**
- Follow up on overdue items
- Archive resolved items
- Update waiting status
- Create tasks for follow-ups

---

### Phase 2: Strategic Assessment (45-60 minutes)

#### Step 5: Comprehensive Project Review

**Purpose:** Ensure projects align with goals.

**Actions:**
1. List all active projects:
   ```python
   list_projects(status="active")
   ```
2. For each project:
   - Get project status: `get_project_status(project_name)`
   - Review progress
   - Assess alignment with goals
   - Determine next steps

**MCP Tools:**
- `list_projects(status="active")` - Active projects
- `get_project_status(project_name)` - Project details

**Questions to ask:**
- Is it still relevant?
- Is it making progress?
- Should it be on hold?
- Does it need more resources?
- What's the next milestone?

---

#### Step 6: Review All Areas of Responsibility

**Purpose:** Ensure all areas get attention.

**Actions:**
1. List all areas:
   ```python
   list_areas()
   ```
2. For each area:
   - Review area status
   - Check related projects
   - Check related tasks
   - Assess area health
   - Identify improvements

**MCP Tools:**
- `list_areas()` - All areas
- `list_projects()` - Filter by area
- `list_tasks()` - Filter by area

**Questions to ask:**
- Is this area getting attention?
- Are standards being met?
- What needs improvement?
- Should it be archived or merged?

**Use `area-review` skill for detailed review.**

---

#### Step 7: Review Monthly Goals

**Purpose:** Assess progress on monthly goals.

**Actions:**
1. Review goals set at start of month
2. For each goal:
   - Check progress
   - Assess completion
   - Identify blockers
   - Plan adjustments

**Commands:**
- `gtd-goal list` - List all goals
- `gtd-goal status` - Check goal progress

**Questions to ask:**
- Which goals were achieved?
- Which goals need more work?
- What blocked progress?
- What should be adjusted?

---

#### Step 8: Analyze Monthly Patterns

**Purpose:** Identify patterns and trends.

**Actions:**
1. Request deep analysis:
   ```python
   generate_insights(focus="monthly_patterns")
   analyze_energy(days=30)
   find_connections(scope="monthly")
   ```
2. Review analysis results:
   - Energy patterns
   - Task completion patterns
   - Project progress patterns
   - Habit consistency patterns

**MCP Tools:**
- `generate_insights(focus="monthly_patterns")` - Monthly insights
- `analyze_energy(days=30)` - Energy patterns
- `find_connections(scope="monthly")` - Connections

**What to look for:**
- What worked well this month?
- What didn't work?
- What patterns emerged?
- What needs to change?

---

### Phase 3: Review & Assessment (30-45 minutes)

#### Step 9: Review Daily Logs for Month

**Purpose:** Understand what actually happened.

**Actions:**
1. Read past month's logs:
   ```python
   read_recent_logs(days=30)
   ```
2. Review patterns:
   - What activities dominated?
   - What was accomplished?
   - What was missed?
   - What patterns emerged?

**MCP Tools:**
- `read_recent_logs(days=30)` - Past month's logs

**What to review:**
- Accomplishments
- Challenges
- Time allocation
- Energy patterns

---

#### Step 10: Review Habit Performance

**Purpose:** Assess habit consistency.

**Actions:**
1. Review habit statistics:
   - Completion rates
   - Streak lengths
   - Patterns
2. Identify:
   - Habits doing well
   - Habits struggling
   - Habits to adjust

**Commands:**
- `gtd-habit list` - All habits
- `gtd-habit dashboard` - Statistics

**Use `habit-checkin` skill for detailed review.**

---

#### Step 11: Review Second Brain

**Purpose:** Assess knowledge building.

**Actions:**
1. Review Second Brain activity:
   - Notes created
   - MOCs maintained
   - Progressive summarization
   - Evergreen notes
2. Assess:
   - Knowledge growth
   - Organization quality
   - Connection building

**Commands:**
- `gtd-brain list` - All notes
- `gtd-brain-moc list` - All MOCs
- `gtd-brain-metrics dashboard` - Quality metrics

---

### Phase 4: Planning Ahead (30-45 minutes)

#### Step 12: Set Next Month Goals

**Purpose:** Define focus for next month.

**Actions:**
1. Based on review, set 3-5 monthly goals:
   - What do you want to achieve?
   - What projects need focus?
   - What areas need attention?
2. Create goals:
   ```bash
   gtd-goal create "Goal Name" "Description"
   ```

**Commands:**
- `gtd-goal create "Goal Name" "Description"` - Create goal

**Best practices:**
- Limit to 3-5 goals
- Make them specific
- Link to projects/areas
- Set measurable outcomes

---

#### Step 13: Plan Project Priorities

**Purpose:** Identify focus projects for next month.

**Actions:**
1. From project review, identify:
   - Projects to focus on
   - Projects to pause
   - Projects to activate
2. Update project priorities
3. Create initial tasks for focus projects

**MCP Tools:**
- `list_projects(status="active")` - Active projects
- `create_task()` - Initial tasks

---

#### Step 14: Plan Area Improvements

**Purpose:** Identify area improvements needed.

**Actions:**
1. From area review, identify:
   - Areas needing attention
   - Standards to adjust
   - Projects to create
   - Tasks to add
2. Create action items:
   - Projects for area improvements
   - Tasks for area maintenance
   - Standards to update

**MCP Tools:**
- `list_areas()` - All areas
- `create_project()` - Area projects
- `create_task()` - Area tasks

---

#### Step 15: Create Monthly Review Summary

**Purpose:** Document review insights.

**Actions:**
1. Create summary document:
   - Accomplishments
   - Challenges
   - Patterns identified
   - Goals for next month
   - Action items
2. Log to daily log or create note

**What to include:**
- Key accomplishments
- Projects completed
- Goals achieved
- Patterns identified
- Next month focus
- Action items

---

## Detailed Workflow Examples

### Example 1: Full Monthly Review

**Scenario:** Complete monthly review process.

**Steps:**
1. **System cleanup (45 min):**
   - Archive 3 completed projects
   - Archive 15 completed tasks
   - Process 2 inbox items
   - Clean waiting for list

2. **Strategic assessment (60 min):**
   - Review 12 active projects
   - Review 8 areas
   - Assess 5 monthly goals (3 achieved, 2 in progress)
   - Request deep analysis

3. **Review & assessment (45 min):**
   - Review past month's logs
   - Review habit performance (7/8 habits consistent)
   - Review Second Brain (12 notes created, 2 MOCs updated)

4. **Planning ahead (45 min):**
   - Set 4 goals for next month
   - Identify 3 focus projects
   - Plan 2 area improvements
   - Create review summary

### Example 2: Quick Monthly Review

**Scenario:** Time-constrained monthly review.

**Steps:**
1. **Essential cleanup (20 min):**
   - Archive completed projects
   - Clean inbox
   - Review active projects

2. **Quick assessment (20 min):**
   - Review areas
   - Check goal progress
   - Review logs

3. **Quick planning (20 min):**
   - Set 3 monthly goals
   - Identify focus projects
   - Create action items

---

## Best Practices

### Time Management

**Allocate sufficient time:**
- Full review: 2-3 hours
- Quick review: 1 hour minimum
- Don't rush - quality over speed

**Schedule appropriately:**
- Last weekend of month
- First weekend of new month
- Block calendar time
- Minimize interruptions

### Review Depth

**Be thorough:**
- Don't skip phases
- Review all areas
- Check all projects
- Assess all goals

**Be honest:**
- Acknowledge what didn't work
- Identify real blockers
- Don't make excuses
- Focus on improvement

### Planning

**Set realistic goals:**
- 3-5 monthly goals maximum
- Link to projects/areas
- Make them specific
- Set measurable outcomes

**Focus on priorities:**
- Identify 3-5 focus projects
- Don't try to do everything
- Balance across areas
- Maintain sustainability

---

## Integration with Other Skills

This skill works well with:
- **`weekly-review`**: Monthly review builds on weekly reviews
- **`area-review`**: Detailed area review during monthly review
- **`habit-checkin`**: Review habit performance
- **`project-status-review`**: Review all projects
- **`energy-audit-planning`**: Analyze monthly energy patterns

---

## Troubleshooting

### "Monthly review takes too long"

**Solutions:**
- Do quick review (1 hour) if time-constrained
- Spread across multiple days
- Focus on essential items
- Use templates for efficiency

### "I don't know what to review"

**Solutions:**
- Follow the phases systematically
- Use the questions provided
- Review all areas and projects
- Request deep analysis for insights

### "I keep forgetting to do monthly review"

**Solutions:**
- Schedule in calendar
- Set reminder
- Make it a habit
- Do it same time each month

---

## Success Criteria

Successful monthly review:
- ✓ System cleaned (projects/tasks archived)
- ✓ All areas reviewed
- ✓ Goals assessed
- ✓ Patterns identified
- ✓ Next month goals set
- ✓ Focus projects identified
- ✓ Action items created
- ✓ Review summary documented

---

## Commands Reference

### Project Management
```python
# List all projects
list_projects(status="all")

# Get project status
get_project_status(project_name)
```

### Area Management
```python
# List all areas
list_areas()
```

### Task Management
```python
# List completed tasks
list_tasks(status="completed")
```

### Daily Logs
```python
# Read past month's logs
read_recent_logs(days=30)
```

### Deep Analysis
```python
# Monthly insights
generate_insights(focus="monthly_patterns")

# Energy patterns
analyze_energy(days=30)

# Connections
find_connections(scope="monthly")
```

### Goals
```bash
# Create monthly goal
gtd-goal create "Goal Name" "Description"

# List goals
gtd-goal list
```

---

## Workflow Summary

```
Monthly Review Workflow
│
├─ Phase 1: System Cleanup (30-45 min)
│   ├─ 1. Archive Completed Projects
│   ├─ 2. Archive Completed Tasks
│   ├─ 3. Review and Clean Inbox
│   └─ 4. Review Waiting For List
│
├─ Phase 2: Strategic Assessment (45-60 min)
│   ├─ 5. Comprehensive Project Review
│   ├─ 6. Review All Areas
│   ├─ 7. Review Monthly Goals
│   └─ 8. Analyze Monthly Patterns
│
├─ Phase 3: Review & Assessment (30-45 min)
│   ├─ 9. Review Daily Logs for Month
│   ├─ 10. Review Habit Performance
│   └─ 11. Review Second Brain
│
└─ Phase 4: Planning Ahead (30-45 min)
    ├─ 12. Set Next Month Goals
    ├─ 13. Plan Project Priorities
    ├─ 14. Plan Area Improvements
    └─ 15. Create Monthly Review Summary
```

---

Remember: Monthly review is about stepping back, assessing progress, and planning ahead. Take time to reflect honestly, identify patterns, and set clear direction for the next month. Quality review leads to better planning and execution.
