---
name: Auto Task Creation from Log
description: Automatically extract actionable items from daily log entries and create GTD tasks without asking. Proactive task creation based on logged activities, commitments, and identified next actions.
version: 1.0.0
type: runbook
tags:
  - runbook
  - task-creation
  - daily-log
  - automatic
  - proactive
  - gtd
author: GTD System
---

# Auto Task Creation from Log Runbook

A proactive runbook that automatically analyzes daily log entries, identifies actionable items, and creates GTD tasks without asking for permission. This runbook **takes action** instead of suggesting actions.

## Purpose

This runbook transforms daily log analysis from passive review to active task creation:
- Automatically extracts commitments, follow-ups, and next actions from log entries
- Creates tasks immediately based on identified patterns
- Sets appropriate priorities, contexts, and due dates
- Updates the daily log with created task references
- **No permission asking - just does the work**

## Prerequisites

- Daily log entries available for analysis
- Access to GTD task creation tools
- Clear patterns or keywords that indicate actionable items

## Runbook Steps

### Step 1: Load and Analyze Daily Log

**Action:** Call `gtd_read_daily_log(date="today")` to get today's log entries.

**Analysis Patterns to Look For:**
- **Commitment words**: "will", "need to", "should", "must", "have to"
- **Follow-up indicators**: "follow up", "check on", "remind", "schedule"
- **Decision points**: "decided to", "agreed to", "committed to"
- **Waiting indicators**: "waiting for", "pending", "blocked by"
- **Action verbs**: "call", "email", "write", "review", "complete", "finish"
- **Time references**: "tomorrow", "next week", "by Friday", "deadline"
- **People mentions**: "talk to [name]", "meet with [name]", "ask [name]"

**Next Step:** Extract actionable items without asking for permission.

---

### Step 2: Extract Actionable Items Automatically

**Action:** Parse log entries and automatically identify tasks to create.

**Extraction Rules:**
1. **Commitments** → High priority tasks
2. **Follow-ups** → Medium priority tasks with context @calls or @email
3. **Waiting items** → Waiting-for tasks with appropriate context
4. **Deadlines mentioned** → Tasks with due dates
5. **People interactions needed** → Tasks with @calls or @agenda context

**Automatic Processing:**
```
IF entry contains "need to [action]" → CREATE task: "[action]"
IF entry contains "follow up on [item]" → CREATE task: "Follow up on [item]" with @calls context
IF entry contains "email [person] about [topic]" → CREATE task: "Email [person] about [topic]" with @email context
IF entry contains "by [date]" → SET due date on created task
IF entry contains "urgent" or "ASAP" → SET high priority
```

**Next Step:** Create tasks immediately without confirmation.

---

### Step 3: Create Tasks Automatically

**Action:** Use `gtd_create_task()` to create each identified task immediately.

**Task Creation Logic:**

**For Commitments:**
```python
gtd_create_task(
    title="[extracted commitment]",
    priority="high",
    context="@action",  # or specific context if identified
    notes="Auto-created from daily log: [original log entry]"
)
```

**For Follow-ups:**
```python
gtd_create_task(
    title="Follow up: [item]",
    priority="medium", 
    context="@calls",  # or @email based on type
    notes="Follow-up from: [date] - [original context]"
)
```

**For Waiting Items:**
```python
gtd_create_task(
    title="Waiting for: [item/person]",
    priority="low",
    context="@waiting",
    notes="Waiting since: [date] - [details]"
)
```

**For Deadlines:**
```python
gtd_create_task(
    title="[action item]",
    priority="high",
    due_date="[extracted date]",
    context="@action",
    notes="Deadline task from log: [original entry]"
)
```

**Next Step:** Log created tasks and update daily log.

---

### Step 4: Update Daily Log with Task References

**Action:** Add references to created tasks back to the daily log.

**Format:**
```
[Original log entry]
→ Created task: [task_id] - "[task title]"
```

**Implementation:**
```python
for task in created_tasks:
    update_entry = f"→ Created task: {task['id']} - \"{task['title']}\""
    gtd_add_daily_log_entry(entry=update_entry)
```

**Next Step:** Provide summary of actions taken.

---

### Step 5: Provide Action Summary

**Action:** Report what was automatically created.

**Summary Format:**
```
🤖 **Auto Task Creation Complete**

📋 **Tasks Created:** {count}

✅ **High Priority:**
- [task 1]
- [task 2]

📞 **Follow-ups:**
- [task 3] (@calls)
- [task 4] (@email)

⏰ **With Deadlines:**
- [task 5] (due: [date])

⏳ **Waiting For:**
- [task 6] (@waiting)

💡 **Next:** These tasks are now in your GTD system and ready for processing.
```

**Next Step:** Complete runbook.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Daily log analyzed for actionable patterns
2. ✅ Tasks automatically created based on identified patterns
3. ✅ Appropriate priorities, contexts, and due dates assigned
4. ✅ Daily log updated with task references
5. ✅ Summary provided of actions taken

**Success Criteria:**
- Tasks created without requiring user permission
- All actionable items from log converted to tasks
- Appropriate task metadata assigned automatically
- Clear audit trail in daily log

## Automatic Patterns

### High-Confidence Auto-Creation (No Confirmation Needed)

**Commitment Patterns:**
- "I will [action]" → CREATE: "[action]"
- "Need to [action]" → CREATE: "[action]" 
- "Must [action] by [date]" → CREATE: "[action]" with due date

**Communication Patterns:**
- "Call [person] about [topic]" → CREATE: "Call [person] about [topic]" @calls
- "Email [person] re: [topic]" → CREATE: "Email [person] re: [topic]" @email
- "Follow up on [item]" → CREATE: "Follow up on [item]" @calls

**Deadline Patterns:**
- "[action] by [date]" → CREATE: "[action]" with due date
- "[action] due [date]" → CREATE: "[action]" with due date

### Medium-Confidence Creation (Still Auto-Create)

**Action Verb Patterns:**
- "Should [action]" → CREATE: "[action]" (medium priority)
- "Want to [action]" → CREATE: "[action]" (medium priority)
- "Planning to [action]" → CREATE: "[action]"

**Research/Learning Patterns:**
- "Research [topic]" → CREATE: "Research [topic]" @research
- "Learn about [topic]" → CREATE: "Learn about [topic]" @research
- "Look into [topic]" → CREATE: "Investigate [topic]" @research

## Context Assignment Rules

**Automatic Context Detection:**
- Call, phone, ring → @calls
- Email, message, write to → @email  
- Buy, purchase, get, pick up → @errands
- Online, website, search → @computer
- Meet, coffee, lunch → @agenda
- Read, review document → @read
- Think, consider, decide → @think

## Priority Assignment Rules

**High Priority Keywords:**
- urgent, ASAP, critical, important, deadline, due

**Medium Priority Keywords:**  
- should, want, plan, intend, goal

**Low Priority Keywords:**
- might, could, maybe, consider, someday

## Error Handling

**If no actionable items found:**
- Log: "No actionable items identified in daily log"
- Continue with normal operation

**If task creation fails:**
- Log the error but continue processing other items
- Report failed creations in summary

**If unclear patterns:**
- Default to medium priority @action context
- Create task with note requesting clarification

## Usage

**To use this runbook:**
1. "Auto-create tasks from my daily log"
2. "Process today's log for actionable items"  
3. "Convert my log entries to tasks automatically"

**Best Times:**
- End of day to capture today's commitments
- Morning to process yesterday's items
- After meetings or significant activities
- During weekly review process

## Advanced Features

**Pattern Learning:**
- Track which auto-created tasks get completed vs. deleted
- Refine patterns based on success rates
- User can add custom patterns

**Batch Processing:**
- Can process multiple days of logs at once
- Useful for backlog processing after time away

**Integration:**
- Works with other runbooks (morning review, weekly review)
- Can be triggered automatically on log updates
- Feeds into task prioritization runbooks

## Examples

### Example Log Entry:
```
10:30 - Meeting with Sarah about project timeline. Agreed to send her the updated specs by Wednesday. Need to call Jim about the delay. Also should research alternative vendors just in case.
```

### Auto-Created Tasks:
1. **"Send Sarah updated specs"** (due: Wednesday, @email, high priority)
2. **"Call Jim about delay"** (@calls, high priority)  
3. **"Research alternative vendors"** (@research, medium priority)

### Updated Log Entry:
```
10:30 - Meeting with Sarah about project timeline. Agreed to send her the updated specs by Wednesday. Need to call Jim about the delay. Also should research alternative vendors just in case.
→ Created task: #1234 - "Send Sarah updated specs"
→ Created task: #1235 - "Call Jim about delay"  
→ Created task: #1236 - "Research alternative vendors"
```

This runbook transforms passive log review into active task management, ensuring nothing falls through the cracks while maintaining full GTD methodology compliance.