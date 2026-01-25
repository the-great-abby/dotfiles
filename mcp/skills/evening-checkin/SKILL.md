---
name: Evening Check-In
description: Complete evening routine workflow using GTD methodology and MCP tools. Guides through reviewing the day, processing remaining items, reflecting on accomplishments, and setting priorities for tomorrow.
version: 1.0.0
tags:
  - routine
  - evening
  - checkin
  - daily
  - reflection
  - productivity
author: GTD System
---

# Evening Check-In Workflow

A comprehensive evening routine that helps you end your day with reflection, closure, and preparation for tomorrow using GTD principles and system capabilities.

## When to Use

Use this skill at the end of each day (typically evening, but adapt to your schedule) to:
- Review what you accomplished today
- Process any remaining inbox items
- Reflect on the day's activities
- Complete or defer tasks as needed
- Set priorities for tomorrow
- Create evening log entry
- Prepare for a good start tomorrow

## How It Works

This workflow uses multiple MCP tools in sequence to provide a complete evening check-in experience. Follow these steps in order:

### Step 1: Review Today's Accomplishments

**Purpose:** Acknowledge what you've done and get closure on the day.

**Actions:**
1. Call `read_daily_log(date="today")` to see today's log entries
2. Review what you accomplished:
   - Tasks completed
   - Progress made on projects
   - Important activities or events
   - Insights or learnings
3. Call `list_tasks(status="active")` and identify tasks you worked on today
4. For tasks you completed, use `complete_task(task_id)` to mark them done

**What to look for:**
- Tasks that are actually done but not marked complete
- Progress made (even if tasks aren't fully complete)
- Patterns in what you accomplished
- What went well today

**MCP Tools:**
- `read_daily_log(date="today")` - See today's log
- `list_tasks(status="active")` - Review active tasks
- `complete_task(task_id)` - Mark completed tasks

---

### Step 2: Process Remaining Inbox Items

**Purpose:** Ensure inbox is clear before ending the day (or plan to process tomorrow).

**Actions:**
1. Call `get_inbox_count()` to check how many unprocessed items are in your inbox
2. If count > 0:
   - **Option A:** Process now using `inbox-processing` skill (if you have energy)
   - **Option B:** Note the count and plan to process in morning
   - **Option C:** Quick process - handle 2-minute items only
3. If count = 0: ✓ Inbox is clear, proceed to next step

**GTD Principle:** Your inbox should be processed regularly. Evening is a good time to clear it, but don't force it if you're tired - morning processing is also effective.

**MCP Tools:**
- `get_inbox_count()` - Check inbox status
- Use `inbox-processing` skill if processing now

---

### Step 3: Review and Update Active Tasks

**Purpose:** Ensure task status reflects reality and plan for tomorrow.

**Actions:**
1. Call `list_tasks(status="active")` to see all active tasks
2. For each task you worked on today:
   - Update notes if you made progress: `update_task(task_id, notes="...")`
   - Defer if needed: `defer_task(task_id, until="tomorrow")`
   - Complete if done: `complete_task(task_id)`
3. Review tasks planned for today that didn't get done:
   - Were they realistic?
   - Should they be deferred?
   - Do priorities need adjustment?

**Questions to ask:**
- What tasks did I actually work on today?
- What tasks were planned but not touched?
- What needs to happen tomorrow?

**MCP Tools:**
- `list_tasks(status="active")` - Get active tasks
- `update_task(task_id, notes="...")` - Update task notes
- `defer_task(task_id, until="...")` - Defer tasks
- `complete_task(task_id)` - Mark tasks complete

---

### Step 4: Reflect on the Day

**Purpose:** Learn from the day and identify patterns.

**Actions:**
1. Review today's log entries and activities
2. Consider:
   - What went well?
   - What didn't go as planned?
   - What did you learn?
   - What patterns do you notice?
   - How was your energy?
3. Note insights for future reference

**Reflection questions:**
- Did I accomplish what I set out to do?
- What was the most important thing I did today?
- What would I do differently?
- What am I grateful for today?

**MCP Tools:**
- `read_daily_log(date="today")` - Review today's entries
- `read_recent_logs(days=3)` - See patterns over past few days

---

### Step 5: Generate Suggestions for Tomorrow

**Purpose:** Get AI-powered suggestions for tomorrow based on today's activity.

**Actions:**
1. Summarize today's activity and accomplishments
2. Call `suggest_tasks_from_text(text="<your summary>", context="evening_review", mode="planning")`
3. Review the suggestions provided:
   - Check confidence scores
   - Review reasons provided
4. For high-confidence suggestions you want to act on:
   - Use `create_tasks_from_suggestion(suggestion_id="<id>")` to create tasks
   - Or use `create_task()` directly if you want to customize

**Example summary text:**
"Today I completed [tasks]. I made progress on [projects]. Tomorrow I need to [goals]. I'm feeling [energy/mood]. I want to focus on [priorities]."

**MCP Tools:**
- `suggest_tasks_from_text(text="...", context="evening_review", mode="planning")` - Get suggestions
- `create_tasks_from_suggestion(suggestion_id="...")` - Create from suggestion
- `create_task(title="...", priority="...")` - Create task directly

---

### Step 6: Set Tomorrow's Priorities

**Purpose:** Clarify what matters most for tomorrow.

**Actions:**
1. Based on today's review and suggestions, identify 1-3 top priorities for tomorrow
2. Ensure these are created as tasks if they aren't already:
   - Use `create_task(title="<priority>", priority="urgent_important")` if needed
   - Or use `update_task(task_id="...", priority="urgent_important")` to update existing
3. Consider context and energy:
   - What context will you be in tomorrow?
   - What energy level do you expect?
   - Match tasks to context and energy

**Questions to ask:**
- What MUST get done tomorrow?
- What would make tomorrow feel successful?
- What's the most important thing for my projects/areas?
- What can I realistically accomplish?

**MCP Tools:**
- `create_task(title="...", priority="urgent_important", context="...")` - Create priority task
- `update_task(task_id="...", priority="urgent_important")` - Update priority
- `get_context_tasks(context="...")` - See tasks for tomorrow's context

---

### Step 7: Create Evening Log Entry

**Purpose:** Document evening reflections and tomorrow's intentions.

**Actions:**
1. Call `read_daily_log(date="today")` to see if there's already an evening entry
2. Create an evening log entry with:
   - Today's accomplishments (summary)
   - Reflections on the day
   - Energy level or mood
   - Tomorrow's priorities (1-3 items)
   - Any important notes for tomorrow
   - Gratitude or positive notes

**Note:** You can use `addInfoToDailyLog` function or add directly to daily log file. This helps track daily patterns over time.

**Log entry structure:**
```
Evening Reflection - [Date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Accomplishments:
- [What you completed today]

Reflections:
- [What went well]
- [What you learned]
- [What to improve]

Tomorrow's Priorities:
1. [Top priority]
2. [Second priority]
3. [Third priority]

Energy/Mood: [How you're feeling]
Notes: [Any important notes for tomorrow]
```

---

## Best Practices

### Evening Check-In Timing

- **Best time:** End of workday or before bed
- **Duration:** 10-15 minutes (don't rush, but keep it focused)
- **Frequency:** Daily (consistency is key)
- **Flexibility:** Adapt timing to your schedule

### Task Completion

- **Mark tasks complete:** Don't leave tasks hanging if they're done
- **Update progress:** Note progress even if task isn't complete
- **Be realistic:** Not everything needs to be done today
- **Defer appropriately:** It's okay to defer tasks to tomorrow

### Inbox Processing

- **Don't force it:** If you're tired, process in morning
- **Quick wins:** Handle 2-minute items if you have energy
- **Plan for morning:** Note inbox count if not processing now
- **Remember:** Empty inbox = clear mind

### Reflection

- **Be honest:** Acknowledge what actually happened
- **Be kind:** Don't judge yourself harshly
- **Learn:** What can you learn from today?
- **Celebrate:** Acknowledge accomplishments, even small ones

### Tomorrow's Planning

- **Limit priorities:** 1-3 items maximum
- **Be realistic:** Don't overcommit
- **Consider energy:** Match tasks to expected energy level
- **Set yourself up:** Make tomorrow easier with good planning

---

## Workflow Summary

```
Evening Check-In Workflow
│
├─ 1. Review Today's Accomplishments
│   ├─ read_daily_log(date="today")
│   ├─ list_tasks(status="active")
│   └─ complete_task() for done items
│
├─ 2. Process Remaining Inbox
│   ├─ get_inbox_count()
│   └─ Process or plan for morning
│
├─ 3. Review and Update Active Tasks
│   ├─ list_tasks(status="active")
│   ├─ update_task() for progress
│   ├─ defer_task() if needed
│   └─ complete_task() for done items
│
├─ 4. Reflect on the Day
│   ├─ Review log entries
│   └─ Identify patterns and learnings
│
├─ 5. Generate Suggestions for Tomorrow
│   ├─ Summarize today's activity
│   ├─ suggest_tasks_from_text()
│   └─ create_task() from suggestions
│
├─ 6. Set Tomorrow's Priorities
│   ├─ Identify 1-3 top priorities
│   ├─ create_task() or update_task()
│   └─ Consider context and energy
│
└─ 7. Create Evening Log Entry
    └─ Document reflections and tomorrow's plan
```

---

## Common Variations

### Quick Evening Check-In (5 minutes)
If short on time, focus on:
1. Review accomplishments (`read_daily_log`, `list_tasks`)
2. Mark completed tasks (`complete_task`)
3. Set 1-2 priorities for tomorrow (`create_task` or `update_task`)
4. Quick log entry

### Deep Evening Review (20-30 minutes)
For more thorough planning, add:
- Review all pending suggestions (`get_pending_suggestions`)
- Review project status (`list_projects`, `get_project_status`)
- Analyze energy patterns (`analyze_energy`)
- Plan week ahead if it's Sunday

### Weekend Evening
Adapt the workflow for personal time:
- Focus on personal projects and areas
- Review habits and routines
- Plan for personal development activities
- More reflection time

---

## Integration with Other Skills

This skill works well with:
- **`interactive-morning-review-runbook`**: Evening sets up morning, morning review reviews evening
- **`daily-review`**: Evening check-in is part of daily review cycle
- **`inbox-processing`**: Process inbox items discovered in Step 2
- **`task-prioritization`**: For guidance on setting priorities (Step 6)
- **`weekly-review`**: Evening check-in on Sunday can transition to weekly review

---

## Troubleshooting

### "I don't have time for this"

**Solutions:**
- Start with Quick Evening Check-In (5 minutes)
- Focus on accomplishments + tomorrow's priorities only
- Gradually expand as the routine becomes habit
- Do it right after work, not right before bed

### "I didn't accomplish much today"

**Solutions:**
- Acknowledge what you did do (even small things)
- Reflect on why (energy, interruptions, priorities)
- Adjust tomorrow's plan to be more realistic
- Remember: some days are just maintenance days

### "My inbox is always full"

**Solutions:**
- Schedule dedicated inbox processing time (not during check-in)
- Use `inbox-processing` skill more frequently
- Consider capturing less (reduce input)
- Process inbox in morning if evening is too busy

### "I can't decide on tomorrow's priorities"

**Solutions:**
- Use `suggest_tasks_from_text()` for AI suggestions
- Review active projects to see what's most important
- Consider deadlines and commitments
- Start with just 1 priority if 3 feels overwhelming

---

## Success Criteria

A successful evening check-in means:
- ✓ You've reviewed what you accomplished today
- ✓ Tasks are updated to reflect reality
- ✓ Inbox is processed or planned for processing
- ✓ You know your 1-3 top priorities for tomorrow
- ✓ You've reflected on the day and learned from it
- ✓ You've documented your evening intentions
- ✓ You feel closure on today and prepared for tomorrow

---

## Example Evening Check-In

```
Evening Check-In - Tuesday, 2026-01-20
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Accomplishments
- Completed: Review oncall handoff notes
- Completed: Troubleshoot AI suggestions feature
- Progress: Made progress on Kubernetes learning module
- Logged: 4 daily log entries

Step 2: Inbox
- Count: 2 items
- Plan: Process in morning (too tired now)

Step 3: Tasks Updated
- Marked 3 tasks complete
- Updated 2 tasks with progress notes
- Deferred 1 task to tomorrow

Step 4: Reflection
- Went well: Made good progress on technical learning
- Challenge: Interrupted by meetings
- Learning: Need to block more focused time

Step 5: Tomorrow's Suggestions
- AI suggests: Continue Kubernetes learning
- AI suggests: Review weekly goals
- Created 2 tasks from suggestions

Step 6: Tomorrow's Priorities
1. Complete Kubernetes module (urgent_important)
2. Process inbox items (not_urgent_important)
3. Review weekly goals (not_urgent_important)

Step 7: Evening Log Entry Created
- Documented accomplishments
- Noted reflections
- Set tomorrow's priorities
```

---

Remember: The goal of evening check-in is closure and preparation. You're ending today well and setting tomorrow up for success. Don't aim for perfection - aim for clarity and organization.
