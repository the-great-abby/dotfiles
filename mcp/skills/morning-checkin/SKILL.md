---
name: Morning Check-In
description: Complete morning routine workflow using GTD methodology and MCP tools. Guides through reviewing recent activity, processing inbox, and setting daily priorities.
version: 1.0.0
tags:
  - routine
  - morning
  - checkin
  - daily
  - productivity
author: GTD System
---

# Morning Check-In Workflow

A comprehensive morning routine that helps you start your day organized and focused using GTD principles and system capabilities.

## When to Use

Use this skill at the beginning of each day (typically morning, but adapt to your schedule) to:
- Review what happened recently
- Process any items in your inbox
- Set priorities for the day
- Generate AI-powered suggestions based on your activity
- Get clarity on what to focus on

## How It Works

This workflow uses multiple MCP tools in sequence to provide a complete morning check-in experience. Follow these steps in order:

### Step 1: Review Recent Activity

**Purpose:** Get context on what's been happening in your life.

**Actions:**
1. Call `read_recent_logs(days=3)` to see daily log entries from the past 3 days
2. Review the entries to understand recent patterns and activities
3. Note any incomplete items, recurring themes, or important events

**What to look for:**
- Tasks mentioned but not yet created
- Projects that need attention
- Patterns in your activity (energy levels, focus areas, etc.)

---

### Step 2: Check Inbox Status

**Purpose:** Ensure your inbox is clear (GTD principle: empty inbox = clear mind).

**Actions:**
1. Call `get_inbox_count()` to check how many unprocessed items are in your inbox
2. If count > 0:
   - Option A: Use the `inbox-processing` skill to process all items now
   - Option B: Note the count and plan to process during dedicated time
3. If count = 0: ✓ Inbox is clear, proceed to next step

**GTD Principle:** Your inbox should be processed regularly, ideally daily. Morning is a great time to ensure it's empty.

---

### Step 3: Review Today's Tasks by Context

**Purpose:** See what tasks are available for your current context.

**Actions:**
1. Determine your current context (typically "computer" in the morning)
2. Call `get_context_tasks(context="computer")` or your current context
3. Review tasks and note:
   - High-priority items that need attention today
   - Tasks you can make progress on
   - Tasks that might need updating or deferring

**Tip:** Also check other contexts you might be in today:
- `get_context_tasks(context="home")` if working from home
- `get_context_tasks(context="errands")` if you'll be out
- `get_context_tasks(context="phone")` for calls to make

---

### Step 4: Generate AI-Powered Suggestions

**Purpose:** Get intelligent suggestions based on your recent activity.

**Actions:**
1. Summarize your recent activity (from Step 1) into a text prompt
2. Call `suggest_tasks_from_text(text="<your summary>", context="daily_log", mode="review")`
3. Review the suggestions provided:
   - Check confidence scores (high = likely actionable, low = may need more info)
   - Review reasons provided for each suggestion
4. For high-confidence suggestions you want to act on:
   - Use `create_tasks_from_suggestion(suggestion_id="<id>")` to create tasks
   - Or use `create_task()` directly if you want to customize

**Example summary text:**
"Recent activity: [summarize key points from recent logs]. Focus areas: [mention recurring themes]. I'm looking to [your goal for today/this week]."

---

### Step 5: Set Daily Priorities

**Purpose:** Clarify what matters most today.

**Actions:**
1. Based on the review above, identify 1-3 top priorities for today
2. If these are tasks, ensure they're created and marked as high priority:
   - Use `create_task(title="<task>", priority="urgent_important")` if needed
   - Or use `update_task(task_id="<id>", priority="urgent_important")` to update existing
3. Write a brief daily focus statement (optional, but helpful)

**Questions to ask yourself:**
- What MUST get done today?
- What would make today feel successful?
- What's the most important thing for your projects/areas?

---

### Step 6: Quick Morning Log Entry

**Purpose:** Document your morning intentions and state.

**Actions:**
1. Call `read_daily_log(date="today")` to see if there's already a morning entry
2. Create a morning log entry with:
   - Today's focus/priorities
   - Energy level or mood
   - Any important notes for the day
   - Plan for the day

**Note:** You can use `addInfoToDailyLog` function or call the MCP tool if available. This step helps track your daily patterns over time.

---

## Best Practices

### Morning Check-In Timing
- **Best time:** Within first hour of your workday
- **Duration:** 10-15 minutes (don't rush, but keep it focused)
- **Frequency:** Daily (consistency is key)

### Inbox Processing
- If inbox has > 5 items, consider processing separately using `inbox-processing` skill
- If inbox is large (> 10 items), you may want to schedule dedicated processing time
- Remember: Inbox processing is about quick decisions, not deep work

### Task Priority Setting
- Limit daily priorities to 1-3 items (cognitive load management)
- Use the Eisenhower Matrix (urgent_important, not_urgent_important, etc.)
- Be realistic about what can actually be accomplished

### AI Suggestions
- Review all suggestions, but don't create tasks for everything
- High-confidence suggestions are usually worth creating
- Low-confidence suggestions might need more context or clarification

---

## Workflow Summary

```
Morning Check-In Workflow
│
├─ 1. Review Recent Activity (read_recent_logs)
│   └─ Get context on past 3 days
│
├─ 2. Check Inbox (get_inbox_count)
│   ├─ If > 0 → Process using inbox-processing skill
│   └─ If 0 → Continue
│
├─ 3. Review Today's Tasks (get_context_tasks)
│   └─ See what's available in current context
│
├─ 4. Generate Suggestions (suggest_tasks_from_text)
│   ├─ Summarize recent activity
│   ├─ Get AI suggestions
│   └─ Create high-priority tasks
│
├─ 5. Set Daily Priorities
│   ├─ Identify 1-3 top priorities
│   └─ Ensure tasks are created/updated
│
└─ 6. Morning Log Entry (read_daily_log, addInfoToDailyLog)
    └─ Document intentions for the day
```

---

## Common Variations

### Quick Morning Check-In (5 minutes)
If short on time, focus on:
1. Check inbox (`get_inbox_count`)
2. Get today's focus (`get_context_tasks`)
3. Create morning log entry

### Deep Morning Review (20-30 minutes)
For more thorough planning, add:
- Review all pending suggestions (`get_pending_suggestions`)
- Review project status (`list_projects`, `get_project_status`)
- Review weekly/monthly goals
- Energy planning (when to do what based on energy levels)

### Weekend/Non-Work Morning
Adapt the workflow for personal time:
- Focus on personal projects and areas
- Review habits and routines
- Plan for personal development activities

---

## Integration with Other Skills

This skill works well with:
- **`inbox-processing`**: Process inbox items discovered in Step 2
- **`daily-review`**: For evening reflection on how the day went
- **`task-prioritization`**: For guidance on setting priorities (Step 5)
- **`project-status-review`**: For deeper project planning

---

## Troubleshooting

### "I don't have time for this"
- Start with the Quick Morning Check-In variation (5 minutes)
- Focus on inbox + daily priorities only
- Gradually expand as the routine becomes habit

### "Suggestions aren't helpful"
- Provide better context in your summary text
- Review recent logs more carefully
- Focus on high-confidence suggestions only

### "My inbox is always full"
- Schedule dedicated inbox processing time (not during check-in)
- Use `inbox-processing` skill more frequently
- Consider capturing less (reduce input)

---

## Success Metrics

A successful morning check-in means:
- ✓ Inbox is clear or you have a plan to process it
- ✓ You know your 1-3 top priorities for today
- ✓ You've reviewed recent activity and patterns
- ✓ Tasks are created/updated based on insights
- ✓ You've documented your morning intentions

Remember: The goal isn't perfection, it's clarity and organization.
