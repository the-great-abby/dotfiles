---
name: Daily Review
description: Comprehensive daily review workflow following GTD methodology. Reviews inbox, tasks, projects, and provides structured reflection questions. Can be done morning or evening.
version: 1.0.0
tags:
  - review
  - daily
  - gtd
  - reflection
  - planning
author: GTD System
---

# Daily Review Workflow

A structured daily review process that ensures your GTD system stays current, nothing falls through cracks, and you maintain clarity on priorities and progress.

## When to Use

Use this skill once per day, ideally at a consistent time:
- **Morning:** Set up for the day ahead, review yesterday
- **Evening:** Reflect on the day, prepare for tomorrow
- **Transition times:** End of workday, start of workday

**GTD Principle:** Daily review maintains system integrity and keeps you aligned with your priorities.

---

## How It Works

This workflow guides you through a complete daily review using MCP tools, following GTD's "trusted system" principles. The review ensures your system is current and reliable.

### Step 1: Process Your Inbox

**Purpose:** Empty your inbox (GTD fundamental - inbox is not a storage place).

**Actions:**
1. Call `get_inbox_count()` to see how many items need processing
2. If count > 0:
   - Use `inbox-processing` skill to systematically process all items
   - Apply GTD's 2-minute rule: if action takes < 2 minutes, do it now
   - For each item: trash, reference, someday/maybe, or convert to task/project
3. If count = 0: ✓ Proceed to next step

**Questions to ask for each inbox item:**
- Is it actionable?
- What's the next action?
- Will it take < 2 minutes? (Do it now)
- Is it a project? (Multiple steps = project)

---

### Step 2: Review Pending Suggestions

**Purpose:** Review AI-generated task suggestions and decide what to act on.

**Actions:**
1. Call `get_pending_suggestions()` to see all pending suggestions
2. Review each suggestion:
   - Check confidence score (high = likely good, low = may need context)
   - Read the reason provided
   - Evaluate if it aligns with your priorities
3. For suggestions you want to act on:
   - Use `create_tasks_from_suggestion(suggestion_id="<id>")` to create tasks
4. For suggestions you don't want:
   - Use `dismiss_suggestion(suggestion_id="<id>")` to dismiss (system learns from this)
5. Optional: Filter by confidence:
   - `get_immediate_suggestions()` - High confidence only
   - `get_review_mode_suggestions()` - Medium confidence for review

**Decision criteria:**
- Does this move me toward my goals/projects?
- Is this the right time for this task?
- Do I have capacity for this?

---

### Step 3: Review Active Tasks

**Purpose:** Ensure all tasks are current, accurate, and actionable.

**Actions:**
1. Call `list_tasks(status="active")` to see all active tasks
2. For each task, ask:
   - Is this still relevant?
   - Is the next action clear?
   - Does it have the right context?
   - Is the priority correct?
3. Update tasks as needed using `update_task()`:
   - Change status, priority, context, or notes
   - Defer tasks: `defer_task(task_id="<id>", until="<date>")`
   - Complete tasks: `complete_task(task_id="<id>")` if done
4. Review by context: `get_context_tasks(context="computer")` etc.

**GTD Principle:** Tasks should be reviewable at a glance - clear next actions, right context.

---

### Step 4: Review Projects

**Purpose:** Ensure all active projects have clear next actions and are making progress.

**Actions:**
1. Call `list_projects(status="active")` to see all active projects
2. For each project:
   - Call `get_project_status(project_name="<name>")` to see current state
   - Verify there's a next action (task) for the project
   - Check if project is stalled or needs attention
3. For stalled projects:
   - Identify the next action and create a task: `create_task(project="<name>", ...)`
   - Or move to someday/maybe if not current
4. For projects needing attention:
   - Use `plan_with_ai(plan_type="project", item_name="<name>")` for planning help
   - Review project details: `get_project_details(project_name="<name>")`

**Signs a project needs attention:**
- No next action defined
- No progress in recent weeks
- Unclear what success looks like

---

### Step 5: Review Daily Log

**Purpose:** Reflect on the day, identify patterns, capture insights.

**Actions:**
1. Read today's log: `read_daily_log(date="today")`
2. If doing evening review, also check yesterday: `read_daily_log(date="yesterday")`
3. Review entries and ask:
   - What got accomplished?
   - What didn't get done? (Should it be a task?)
   - What patterns do I notice?
   - What insights or learnings?
4. Extract any tasks from log entries that weren't created:
   - Use `suggest_tasks_from_text(text="<log entry>", context="daily_log")` if helpful
   - Or create tasks directly for clear action items

**Reflection questions:**
- What went well today?
- What could have gone better?
- What did I learn?
- What should I remember for tomorrow?

---

### Step 6: Review Recent Logs for Patterns

**Purpose:** Identify patterns and trends over the past week.

**Actions:**
1. Call `read_recent_logs(days=7)` to see the past week
2. Look for patterns:
   - Energy levels and when you're most productive
   - Recurring themes or concerns
   - Tasks/projects that keep appearing but not progressing
   - Accomplishments and wins
3. Use insights to inform:
   - Task prioritization
   - Energy planning (when to do what)
   - Habit adjustments
   - System improvements

**Pattern analysis:**
- What time of day am I most productive?
- What types of tasks do I consistently avoid?
- What activities give me energy vs. drain it?
- What keeps appearing in logs but not getting done?

---

### Step 7: Plan Tomorrow (Evening Review)

**Purpose:** Set up tomorrow for success (if doing evening review).

**Actions:**
1. Identify 1-3 priorities for tomorrow based on today's review
2. Create or update tasks for tomorrow:
   - Use `create_task()` for new priorities
   - Use `update_task()` to adjust priorities on existing tasks
3. Check context availability:
   - `get_context_tasks(context="computer")` - what can you do at your desk?
   - `get_context_tasks(context="home")` - what can you do at home?
4. Optional: Generate suggestions for tomorrow:
   - Use `suggest_tasks_from_text()` with summary of what you want to accomplish

**Tomorrow planning questions:**
- What MUST get done tomorrow?
- What meetings or appointments do I have?
- What context will I be in?
- What would make tomorrow feel successful?

---

### Step 8: Weekly Preview (Optional, End of Week)

**Purpose:** If doing Friday review, preview next week.

**Actions:**
1. Review upcoming week's calendar (if calendar integration available)
2. Review active projects that need attention next week
3. Identify weekly priorities and goals
4. Schedule tasks accordingly

---

## Structured Review Questions

Use these GTD review questions systematically:

### Inbox Questions
1. What's in my inbox? (`get_inbox_count`)
2. What needs processing? (`inbox-processing` skill)
3. Is my inbox empty? ✓

### Tasks Questions
1. Do all my tasks have clear next actions?
2. Are tasks in the right context?
3. Are priorities correct?
4. What can I complete or defer?

### Projects Questions
1. Does every project have a next action?
2. Are projects making progress?
3. Are there stalled projects to address?
4. Are there projects that should be archived?

### Areas Questions
1. Are all areas of responsibility covered?
2. Do areas need attention this week?
3. Are there new areas to consider?

### Log Reflection Questions
1. What did I accomplish today?
2. What patterns do I notice?
3. What should I do differently?
4. What am I grateful for?

---

## Best Practices

### Review Timing
- **Consistency:** Same time each day
- **Duration:** 10-15 minutes for daily, up to 30 for comprehensive
- **Environment:** Quiet, focused time (not rushed)

### System Maintenance
- **Inbox:** Should be empty after review
- **Tasks:** All should be current and actionable
- **Projects:** All should have next actions
- **Calendar:** Review upcoming appointments

### Reflection Quality
- **Be honest:** About what's working and what's not
- **Be specific:** "I didn't finish X" not "I was unproductive"
- **Be kind:** Recognize accomplishments, learn from challenges

### Action Focus
- **Create tasks:** If something needs doing, make it a task
- **Update tasks:** Keep tasks accurate and current
- **Complete tasks:** Mark done items as complete
- **Defer tasks:** If not current, defer appropriately

---

## Workflow Variations

### Quick Daily Review (5 minutes)
For busy days:
1. Check inbox (`get_inbox_count`, process if > 0)
2. Review top 5 tasks (`list_tasks`, limit=5)
3. Quick log entry

### Comprehensive Daily Review (30 minutes)
For deeper planning:
1. All standard steps (1-8)
2. Project deep dive (`get_project_status` for each)
3. Pattern analysis (`read_recent_logs`, days=14)
4. Energy planning (when to do what)
5. Weekly preview (if end of week)

### Morning Review
Focus on:
- Processing yesterday's inbox
- Setting today's priorities
- Reviewing today's tasks

### Evening Review
Focus on:
- Reflecting on the day
- Completing done tasks
- Planning tomorrow
- Pattern identification

---

## Integration with Other Skills

This skill works with:
- **`inbox-processing`**: Called in Step 1
- **`morning-checkin`**: Complements morning routine
- **`evening-checkin`**: Complements evening routine
- **`weekly-review`**: Prepares for weekly review

---

## Troubleshooting

### "I don't have time for daily review"
- Start with 5-minute quick review
- Use structured time (calendar block)
- Make it a habit (same time daily)
- Gradually expand duration

### "Review takes too long"
- Use quick review variation
- Focus on inbox + top tasks only
- Delegate detailed review to weekly
- Process inbox separately if needed

### "I keep finding things I forgot"
- This is normal and valuable
- It's why review exists
- Better to find now than later
- System is working as intended

### "Tasks feel overwhelming"
- Limit daily priorities (1-3 items)
- Use context filtering
- Defer non-urgent items
- Focus on what matters now

---

## Success Criteria

A successful daily review means:
- ✓ Inbox is empty (or scheduled for processing)
- ✓ All tasks are current and actionable
- ✓ Active projects have next actions
- ✓ You've reflected on the day
- ✓ Tomorrow's priorities are clear (evening review)
- ✓ System feels trusted and reliable

**Remember:** The goal is system reliability. If you trust your system, you can relax knowing nothing important is forgotten.
