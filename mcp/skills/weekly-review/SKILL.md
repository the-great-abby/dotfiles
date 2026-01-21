---
name: Weekly Review
description: Comprehensive weekly review workflow using GTD methodology and MCP tools. Guides through getting clear, getting current, and getting creative. Uses deep analysis tools for insights and patterns.
version: 1.0.0
tags:
  - review
  - weekly
  - gtd
  - planning
  - productivity
  - analysis
author: GTD System
---

# Weekly Review Workflow

A comprehensive weekly review that helps you get clear, get current, and get creative. This is the cornerstone of GTD - your time to review your entire system, identify what needs attention, and plan for the week ahead.

## When to Use

Use this skill:
- **Weekly:** Every week, no exceptions (critical GTD practice)
- **Best time:** Sunday morning (fresh start) or Friday afternoon (wrap up)
- **Duration:** 1-2 hours (set aside dedicated time)
- **Frequency:** Non-negotiable - consistency is key

## How It Works

This workflow uses multiple MCP tools in sequence, including deep analysis tools, to provide a comprehensive weekly review. Follow these phases in order:

## Phase 1: Get Clear (15-20 minutes)

### Step 1: Process Your Inbox

**Purpose:** Clear your mind by processing all inbox items to zero.

**Actions:**
1. Call `get_inbox_count()` to check inbox status
2. If count > 0:
   - Use `inbox-processing` skill to process all items
   - Or process manually using GTD methodology
   - Goal: Get inbox to zero
3. If count = 0: ✓ Inbox is clear, proceed

**GTD Principle:** Empty inbox = clear mind. This is the foundation of getting clear.

**MCP Tools:**
- `get_inbox_count()` - Check inbox status
- Use `inbox-processing` skill for processing

**Questions to ask:**
- What is it?
- Is it actionable?
- What's the next action?
- Where does it belong?

---

### Step 2: Review Your Calendar

**Purpose:** See what happened last week and what's coming up.

**Actions:**
1. Review past week's calendar:
   - What did I commit to?
   - What actually happened?
   - Any missed commitments?
2. Review upcoming week's calendar:
   - What's on my calendar?
   - Any conflicts or overload?
   - What preparation is needed?
3. Review next week:
   - What's coming up?
   - Any deadlines or important dates?
   - What needs preparation?

**MCP Tools:**
- Calendar integration tools (if available)
- `read_recent_logs(days=7)` - Review past week's activity

**What to check:**
- Last week: Commitments vs. reality
- This week: Calendar conflicts, preparation needed
- Next week: Upcoming deadlines, preparation

---

### Step 3: Review Waiting For List

**Purpose:** Follow up on items you're waiting on from others.

**Actions:**
1. Review all tasks/projects where you're waiting on others
2. For each waiting item:
   - Check status - is it still waiting?
   - Should you follow up?
   - Can you unblock it?
   - Should it be archived?
3. Send follow-ups if needed
4. Update task status accordingly

**MCP Tools:**
- `list_tasks(status="active")` - Review active tasks
- `get_task_details(task_id)` - Check waiting items
- `update_task(task_id, ...)` - Update status

**Questions to ask:**
- What am I waiting on?
- Should I follow up?
- Is anything overdue?
- Can I unblock anything?

---

### Step 4: Review Someday/Maybe List

**Purpose:** Activate items that are now relevant or archive what's no longer interesting.

**Actions:**
1. Review someday/maybe items (if you maintain this list)
2. For each item:
   - Is it ready to become a project?
   - Is it no longer interesting?
   - Should it be archived?
3. Activate relevant items as projects
4. Archive or delete items no longer relevant

**MCP Tools:**
- `list_projects(status="on-hold")` - Review on-hold projects
- `create_project(name="...")` - Activate as project
- Archive or delete items as needed

**Questions to ask:**
- What's ready to activate?
- What should be archived?
- What new ideas do I have?
- What's no longer interesting?

---

## Phase 2: Get Current (30-45 minutes)

### Step 5: Review All Active Projects

**Purpose:** Ensure each project has a next action and is moving forward.

**Actions:**
1. Call `list_projects(status="active")` to get all active projects
2. For each project:
   - Call `get_project_status(project_name="...")` for status
   - Call `get_project_details(project_name="...")` for details
   - Check: Does it have a next action?
   - Check: Is it stuck or blocked?
   - Check: Should it be archived or put on hold?
3. Update projects as needed:
   - Add next actions if missing
   - Update status if needed
   - Archive completed projects
   - Put stuck projects on hold

**MCP Tools:**
- `list_projects(status="active")` - Get all active projects
- `get_project_status(project_name="...")` - Get project status
- `get_project_details(project_name="...")` - Get project details
- `update_task()` - Add/update next actions

**Questions to ask:**
- What projects need attention?
- What projects are stuck?
- What projects should be archived?
- What new projects should I start?

---

### Step 6: Review Active Tasks

**Purpose:** Ensure tasks are current and actionable.

**Actions:**
1. Call `list_tasks(status="active")` to get all active tasks
2. Review tasks by context:
   - `get_context_tasks(context="computer")`
   - `get_context_tasks(context="home")`
   - `get_context_tasks(context="errands")`
   - `get_context_tasks(context="phone")`
3. For each task:
   - Is it still relevant?
   - Is it actionable?
   - Does it have a clear next action?
   - Should it be completed, deferred, or deleted?
4. Update tasks as needed:
   - Complete done tasks: `complete_task(task_id)`
   - Defer tasks: `defer_task(task_id, until="...")`
   - Update priorities: `update_task(task_id, priority="...")`
   - Delete irrelevant tasks

**MCP Tools:**
- `list_tasks(status="active")` - Get all active tasks
- `get_context_tasks(context="...")` - Get tasks by context
- `get_task_details(task_id)` - Get task details
- `complete_task(task_id)` - Mark complete
- `defer_task(task_id, until="...")` - Defer task
- `update_task(task_id, ...)` - Update task

**Questions to ask:**
- What tasks are overdue?
- What tasks are blocked?
- What tasks can I delete?
- What new tasks do I need?

---

### Step 7: Review Areas of Responsibility

**Purpose:** Ensure all areas of your life are getting attention.

**Actions:**
1. Call `list_areas()` to get all areas
2. For each area:
   - Is it getting adequate attention?
   - Are there projects/tasks in this area?
   - Does it need more focus?
   - Are there any issues or concerns?
3. Identify areas needing attention
4. Create projects or tasks for areas that need work

**MCP Tools:**
- `list_areas()` - Get all areas
- `list_projects()` - Check projects per area
- `list_tasks()` - Check tasks per area
- `create_project()` or `create_task()` - Add items to areas

**Questions to ask:**
- What areas need attention?
- Are all areas still relevant?
- What areas are doing well?
- What areas need improvement?

---

## Phase 3: Get Creative (20-30 minutes)

### Step 8: Request Deep Analysis

**Purpose:** Get AI-powered insights about your week and patterns.

**Actions:**
1. Determine week start date (typically Monday of current week)
2. Call `weekly_review(week_start="YYYY-MM-DD")` for comprehensive weekly analysis
   - This queues deep analysis in background
   - Results will be available for review
3. Call `analyze_energy(days=7)` to analyze energy patterns
4. Call `find_connections(scope="week")` to discover connections
5. Call `generate_insights(focus="weekly_patterns")` for insights

**MCP Tools:**
- `weekly_review(week_start="YYYY-MM-DD")` - Comprehensive weekly analysis (deep analysis)
- `analyze_energy(days=7)` - Energy pattern analysis (deep analysis)
- `find_connections(scope="week")` - Find connections (deep analysis)
- `generate_insights(focus="weekly_patterns")` - Generate insights (deep analysis)

**Note:** Deep analysis tools run in background. Results may take a few minutes. Check back later or continue with other steps.

**What to look for:**
- Patterns in your activity
- Energy highs and lows
- Connections between projects/tasks
- Insights about your work style
- Areas for improvement

---

### Step 9: Review Recent Logs

**Purpose:** Understand what actually happened this week.

**Actions:**
1. Call `read_recent_logs(days=7)` to see past week's logs
2. Review entries to understand:
   - What you actually did
   - What you accomplished
   - Patterns in activity
   - Energy levels
   - Challenges or obstacles
3. Note insights and patterns
4. Identify what went well and what didn't

**MCP Tools:**
- `read_recent_logs(days=7)` - Get past week's logs
- `read_daily_log(date="...")` - Get specific day's log

**What to look for:**
- Accomplishments and progress
- Patterns in activity
- Energy patterns
- Challenges or obstacles
- Learnings or insights

---

### Step 10: Review Pending Suggestions

**Purpose:** Review AI-generated suggestions and act on them.

**Actions:**
1. Call `get_pending_suggestions()` to see all pending suggestions
2. Review each suggestion:
   - Check confidence score
   - Review reason provided
   - Decide if it's actionable
3. For high-confidence suggestions:
   - Use `create_tasks_from_suggestion(suggestion_id="...")` to create tasks
   - Or use `create_task()` directly
4. For low-confidence or irrelevant suggestions:
   - Use `dismiss_suggestion(suggestion_id="...")` to dismiss

**MCP Tools:**
- `get_pending_suggestions()` - Get all pending suggestions
- `create_tasks_from_suggestion(suggestion_id="...")` - Create from suggestion
- `create_task(...)` - Create task directly
- `dismiss_suggestion(suggestion_id="...")` - Dismiss suggestion

---

### Step 11: Review Goals and Progress

**Purpose:** Check progress on goals and adjust as needed.

**Actions:**
1. Review your goals (if you maintain a goals system)
2. For each goal:
   - What progress did you make this week?
   - Is the goal still relevant?
   - What adjustments are needed?
   - What actions are needed next week?
3. Update goals or create tasks for goal-related work

**MCP Tools:**
- Goal tracking tools (if available)
- `create_task()` - Create goal-related tasks
- `create_project()` - Create goal-related projects

**Questions to ask:**
- What progress did I make?
- What goals need attention?
- Are my goals still relevant?
- What adjustments are needed?

---

### Step 12: Review Habits and Streaks

**Purpose:** Check habit performance and maintain streaks.

**Actions:**
1. Review your habits (if you track habits)
2. Check habit streaks and performance
3. Identify habits needing attention
4. Celebrate habit wins
5. Adjust habits as needed

**MCP Tools:**
- Habit tracking tools (if available)
- `read_recent_logs(days=7)` - Check habit entries in logs

**Questions to ask:**
- How are my habits doing?
- What habits need attention?
- Are my habits still relevant?
- What new habits should I consider?

---

## Phase 4: Plan Ahead (15-20 minutes)

### Step 13: Set Next Week's Priorities

**Purpose:** Identify what matters most for the coming week.

**Actions:**
1. Based on the review above, identify 3-5 top priorities for next week
2. Ensure these are created as tasks or projects:
   - Use `create_task(title="...", priority="urgent_important")` for priorities
   - Or use `update_task(task_id="...", priority="urgent_important")` to update existing
3. Consider:
   - Deadlines and commitments
   - Project next actions
   - Areas needing attention
   - Goals and objectives

**MCP Tools:**
- `create_task(title="...", priority="urgent_important")` - Create priority task
- `update_task(task_id="...", priority="urgent_important")` - Update priority
- `list_projects(status="active")` - Review projects for priorities

**Questions to ask:**
- What MUST get done next week?
- What would make next week feel successful?
- What's the most important thing for my projects/areas?
- What deadlines or commitments are coming up?

---

### Step 14: Schedule Important Tasks

**Purpose:** Time-block or schedule important tasks for next week.

**Actions:**
1. Review next week's calendar
2. Identify time blocks for important tasks
3. Schedule or time-block priority tasks
4. Consider energy levels when scheduling
5. Leave buffer time for unexpected items

**MCP Tools:**
- Calendar integration tools (if available)
- `get_context_tasks(context="...")` - See tasks for scheduling
- `update_task(task_id="...", notes="Scheduled: ...")` - Note scheduling

**Best practices:**
- Schedule high-priority tasks first
- Match tasks to energy levels
- Leave buffer time
- Be realistic about capacity

---

### Step 15: Create Weekly Review Summary

**Purpose:** Document your review and insights.

**Actions:**
1. Create a summary of your weekly review:
   - What you reviewed
   - Key insights and patterns
   - Accomplishments this week
   - Priorities for next week
   - Areas needing attention
2. Save to weekly reviews directory or daily log
3. Note any follow-up items

**Review summary structure:**
```
Weekly Review - Week of [Date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Get Clear
- Inbox: [status]
- Calendar: [reviewed]
- Waiting For: [items reviewed]
- Someday/Maybe: [items reviewed]

Phase 2: Get Current
- Projects Reviewed: [count]
- Tasks Reviewed: [count]
- Areas Reviewed: [count]

Phase 3: Get Creative
- Deep Analysis: [requested/reviewed]
- Insights: [key insights]
- Patterns: [patterns identified]

Phase 4: Plan Ahead
- Next Week's Priorities:
  1. [priority]
  2. [priority]
  3. [priority]

Key Insights:
- [insight 1]
- [insight 2]
- [insight 3]

Follow-Up Items:
- [item 1]
- [item 2]
```

---

## Best Practices

### Timing

- **Best day:** Sunday morning (fresh start for the week)
- **Alternative:** Friday afternoon (wrap up the week)
- **Duration:** 1-2 hours (don't rush)
- **Frequency:** Every week, no exceptions
- **Consistency:** Same day/time each week builds habit

### Environment

- **Quiet space:** Minimize distractions
- **All materials:** Have everything you need
- **Comfortable:** Set up for focused work
- **Time block:** Protect this time in your calendar

### Mindset

- **Be present:** Focus on the review
- **Be honest:** Acknowledge reality
- **Be kind:** Don't judge yourself harshly
- **Be strategic:** Think about what matters

### Process

- **Follow phases:** Don't skip steps
- **Be thorough:** Review everything
- **Take your time:** Rushing defeats the purpose
- **Stay focused:** One phase at a time

### Follow-Through

- **Save review:** Document your review
- **Set priorities:** Identify next week's focus
- **Schedule tasks:** Time-block important items
- **Follow up:** Act on insights and priorities

---

## Workflow Summary

```
Weekly Review Workflow
│
├─ Phase 1: Get Clear (15-20 min)
│   ├─ 1. Process Inbox (get_inbox_count, inbox-processing)
│   ├─ 2. Review Calendar (read_recent_logs)
│   ├─ 3. Review Waiting For (list_tasks, update_task)
│   └─ 4. Review Someday/Maybe (list_projects)
│
├─ Phase 2: Get Current (30-45 min)
│   ├─ 5. Review All Projects (list_projects, get_project_status)
│   ├─ 6. Review Active Tasks (list_tasks, get_context_tasks)
│   └─ 7. Review Areas (list_areas)
│
├─ Phase 3: Get Creative (20-30 min)
│   ├─ 8. Request Deep Analysis (weekly_review, analyze_energy, find_connections, generate_insights)
│   ├─ 9. Review Recent Logs (read_recent_logs)
│   ├─ 10. Review Pending Suggestions (get_pending_suggestions)
│   ├─ 11. Review Goals (goal tracking tools)
│   └─ 12. Review Habits (habit tracking tools)
│
└─ Phase 4: Plan Ahead (15-20 min)
    ├─ 13. Set Next Week's Priorities (create_task, update_task)
    ├─ 14. Schedule Important Tasks (calendar integration)
    └─ 15. Create Weekly Review Summary (document review)
```

---

## Integration with Other Skills

This skill works well with:
- **`inbox-processing`**: Process inbox items in Phase 1
- **`morning-checkin`**: Weekly review sets up the week, morning check-in starts each day
- **`evening-checkin`**: Evening check-in wraps up days, weekly review wraps up weeks
- **`project-status-review`**: Deep dive into projects during Phase 2
- **`task-prioritization`**: For guidance on setting priorities in Phase 4
- **`progressive-summarization`**: Distill notes as part of review

---

## Troubleshooting

### "I don't have 1-2 hours"

**Solutions:**
- Start with 30 minutes and expand gradually
- Focus on Phase 1 and Phase 2 first
- Do Phase 3 and Phase 4 in separate sessions
- Break into multiple shorter sessions

### "I keep skipping weekly review"

**Solutions:**
- Schedule it in your calendar (recurring event)
- Set a reminder
- Make it a non-negotiable appointment
- Start with shorter reviews and build habit
- Do it same day/time each week

### "I don't know what to review"

**Solutions:**
- Follow the phases in order
- Use the checklist in this skill
- Review everything systematically
- Don't skip steps - each phase is important

### "Deep analysis takes too long"

**Solutions:**
- Request deep analysis early in review
- Continue with other steps while it processes
- Review results later or in follow-up session
- Deep analysis is optional - you can skip if needed

---

## Success Criteria

A successful weekly review means:
- ✓ Inbox is processed to zero
- ✓ All projects reviewed and have next actions
- ✓ All tasks reviewed and are current
- ✓ All areas reviewed
- ✓ Deep analysis requested (or reviewed if available)
- ✓ Next week's priorities identified (3-5 items)
- ✓ Important tasks scheduled
- ✓ Review documented
- ✓ You feel clear, current, and creative

---

## Example Weekly Review

```
Weekly Review - Week of 2026-01-13 to 2026-01-19
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Get Clear ✓
- Inbox: Processed 5 items → 0 items
- Calendar: Reviewed past week, upcoming week, next week
- Waiting For: 2 items - sent follow-ups
- Someday/Maybe: 1 item activated as project

Phase 2: Get Current ✓
- Projects Reviewed: 18 active projects
  - 3 projects need next actions → added
  - 1 project completed → archived
  - 1 project stuck → put on hold
- Tasks Reviewed: 44 active tasks
  - 5 tasks completed → marked done
  - 3 tasks deferred → scheduled
  - 2 tasks deleted → no longer relevant
- Areas Reviewed: 10 areas
  - All areas have projects/tasks
  - 2 areas need more attention → created tasks

Phase 3: Get Creative ✓
- Deep Analysis: Requested weekly_review, analyze_energy, find_connections
- Insights: High energy in mornings, most productive on computer tasks
- Patterns: Interruptions peak on Tuesdays, focus best on Thursdays

Phase 4: Plan Ahead ✓
- Next Week's Priorities:
  1. Complete Kubernetes learning module (urgent_important)
  2. Review oncall handoff notes (urgent_important)
  3. Process inbox daily (not_urgent_important)
  4. Continue CKA exam preparation (not_urgent_important)
  5. Weekly goal check-in (not_urgent_important)

Key Insights:
- Morning energy is best for deep work
- Need to block more focused time
- Interruptions are impacting productivity

Follow-Up Items:
- Review deep analysis results when available
- Schedule focused time blocks for next week
- Set up interruption management
```

---

Remember: Weekly review is the cornerstone of GTD. It's your time to get clear, get current, and get creative. Don't skip it - consistency is key. Even a shorter review is better than no review.
