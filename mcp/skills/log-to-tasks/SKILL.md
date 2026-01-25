---
name: Log-to-Tasks Conversion
description: Analyze daily log entries to identify actionable items and create tasks. Prevents losing actionable items mentioned in logs and connects daily activity to the task system.
version: 1.0.0
tags:
  - tasks
  - logs
  - conversion
  - capture
  - productivity
author: GTD System
---

# Log-to-Tasks Conversion Workflow

A comprehensive skill for analyzing daily log entries to identify actionable items and convert them into tasks. Prevents losing actionable items mentioned in logs and ensures everything that needs to be done gets into your task system.

## When to Use

Use this skill when you need to:
- **Capture tasks from logs**: Extract actionable items from daily logs
- **Process log entries**: Review logs for things that need to be done
- **Prevent task loss**: Ensure nothing actionable is lost
- **Connect logs to tasks**: Link daily activity to task system
- **Weekly review**: Process past week's logs for tasks
- **Evening review**: Extract tasks from today's log

## How It Works

This workflow analyzes log entries, identifies actionable items using AI suggestions, and creates tasks from high-confidence suggestions.

## Step-by-Step Workflow

### Step 1: Select Logs to Review

**Purpose:** Choose which logs to analyze for tasks.

**Actions:**
1. **Option A: Today's log**
   - Call `read_daily_log(date="today")` to get today's entries
   - Review for actionable items

2. **Option B: Recent logs**
   - Call `read_recent_logs(days=7)` to get past week's logs
   - Review for actionable items mentioned

3. **Option C: Specific date**
   - Call `read_daily_log(date="YYYY-MM-DD")` for specific date
   - Useful for catching up on missed days

**MCP Tools:**
- `read_daily_log(date="today")` - Get today's log
- `read_recent_logs(days=7)` - Get past week's logs
- `read_daily_log(date="YYYY-MM-DD")` - Get specific date

**What to look for:**
- Mentions of things to do
- Commitments made
- Ideas that need action
- Follow-ups needed
- Items to research or learn

---

### Step 2: Extract Log Content

**Purpose:** Get log text ready for analysis.

**Actions:**
1. Read the log entries
2. Extract text content (not just metadata)
3. Note any patterns or recurring themes
4. Identify sections that might contain actionable items

**MCP Tools:**
- `read_daily_log(date="...")` - Returns log content
- `read_recent_logs(days=...)` - Returns multiple days' content

**Log content typically includes:**
- Activities done
- Thoughts and ideas
- Commitments
- Things to follow up on
- Learning notes
- Health/wellness entries

---

### Step 3: Generate Task Suggestions from Logs

**Purpose:** Use AI to identify actionable items in logs.

**Actions:**
1. **Summarize log content:**
   - Create a summary of log entries
   - Include key activities, thoughts, commitments
   - Note any patterns or themes

2. **Request suggestions:**
   ```python
   suggest_tasks_from_text(
       text="<log summary>",
       context="daily_log",
       mode="review"
   )
   ```

3. **Review suggestions:**
   - Check confidence scores (high = likely actionable)
   - Review reasons provided
   - Verify suggestions make sense

**MCP Tools:**
- `suggest_tasks_from_text(text="...", context="daily_log", mode="review")` - Get AI suggestions

**Example log summary:**
```
"Today I worked on Kubernetes learning, completed the pods module. 
I mentioned wanting to set up a local cluster for practice. 
I also noted that I should review the CKA exam prep materials. 
Had a conversation about project planning - need to follow up on that."
```

**What AI will identify:**
- "Set up local Kubernetes cluster" (actionable)
- "Review CKA exam prep materials" (actionable)
- "Follow up on project planning conversation" (actionable)

---

### Step 4: Review and Filter Suggestions

**Purpose:** Select which suggestions to convert to tasks.

**Actions:**
1. Review all suggestions from Step 3
2. For each suggestion:
   - **High confidence (0.8+)**: Usually worth creating
   - **Medium confidence (0.5-0.8)**: Review carefully
   - **Low confidence (<0.5)**: May need more context
3. Filter suggestions:
   - Already have task? → Skip or update existing
   - Not actionable? → Dismiss
   - Actionable and new? → Create task

**Questions to ask:**
- Is this truly actionable?
- Do I already have a task for this?
- Is this something I want to do?
- Does this need to be a task?

**MCP Tools:**
- `get_pending_suggestions()` - Review all suggestions
- `dismiss_suggestion(suggestion_id="...")` - Dismiss irrelevant ones

---

### Step 5: Create Tasks from Suggestions

**Purpose:** Convert high-confidence suggestions into tasks.

**Actions:**
1. **For high-confidence suggestions:**
   - Use `create_tasks_from_suggestion(suggestion_id="...")` to create
   - Or use `create_task()` directly if you want to customize

2. **Customize tasks as needed:**
   - Set appropriate priority
   - Set context
   - Link to project if relevant
   - Add notes for context

**MCP Tools:**
- `create_tasks_from_suggestion(suggestion_id="...")` - Create from suggestion
- `create_task(title="...", project="...", priority="...", context="...", notes="...")` - Create directly

**Task creation best practices:**
- Make tasks specific and actionable
- Set appropriate priority
- Link to projects if relevant
- Add notes explaining source (from log)

**Example:**
```python
# From suggestion
create_tasks_from_suggestion(suggestion_id="sug_123")

# Or create directly with customization
create_task(
    title="Set up local Kubernetes cluster for practice",
    project="CKA Exam Preparation",
    priority="not_urgent_important",
    context="computer",
    notes="Mentioned in daily log 2026-01-20"
)
```

---

### Step 6: Link Tasks to Source Logs (Optional)

**Purpose:** Maintain connection between logs and tasks.

**Actions:**
1. Note which log entry generated which task
2. Add reference in task notes:
   - "From daily log 2026-01-20"
   - Link to log entry if possible
3. Add task reference in log (optional):
   - Note that task was created
   - Link to task if system supports it

**Benefits:**
- Track where tasks came from
- Understand context
- Review if needed
- Maintain audit trail

---

### Step 7: Review Created Tasks

**Purpose:** Verify tasks were created correctly.

**Actions:**
1. List newly created tasks:
   ```python
   list_tasks(status="active")
   ```
2. Review tasks:
   - Are they actionable?
   - Do priorities make sense?
   - Are they linked to projects?
   - Do they have proper context?
3. Adjust as needed:
   - Update priorities
   - Add to projects
   - Set contexts
   - Add notes

**MCP Tools:**
- `list_tasks(status="active")` - Review all tasks
- `get_task_details(task_id)` - Check specific task
- `update_task(task_id, ...)` - Adjust task

---

## Detailed Workflow Examples

### Example 1: Process Today's Log

**Scenario:** Extract tasks from today's daily log.

**Steps:**
1. **Read today's log:**
   ```python
   read_daily_log(date="today")
   ```
   - Found entries about Kubernetes learning, project planning, health check

2. **Generate suggestions:**
   ```python
   suggest_tasks_from_text(
       text="Today I completed Kubernetes pods module. Need to set up local cluster. 
             Also mentioned reviewing CKA exam materials. Had project planning discussion - 
             need to follow up on action items.",
       context="daily_log",
       mode="review"
   )
   ```

3. **Review suggestions:**
   - "Set up local Kubernetes cluster" (confidence: 0.9) → Create
   - "Review CKA exam materials" (confidence: 0.8) → Create
   - "Follow up on project planning" (confidence: 0.7) → Review

4. **Create tasks:**
   ```python
   create_task(
       title="Set up local Kubernetes cluster",
       project="CKA Exam Preparation",
       priority="not_urgent_important",
       context="computer"
   )
   create_task(
       title="Review CKA exam prep materials",
       project="CKA Exam Preparation",
       priority="not_urgent_important",
       context="computer"
   )
   ```

### Example 2: Process Past Week's Logs

**Scenario:** Weekly review - extract tasks from past week.

**Steps:**
1. **Read past week's logs:**
   ```python
   read_recent_logs(days=7)
   ```
   - Multiple days of entries

2. **Summarize week:**
   - Key activities
   - Commitments made
   - Ideas mentioned
   - Follow-ups needed

3. **Generate suggestions:**
   ```python
   suggest_tasks_from_text(text="<week summary>", context="daily_log", mode="review")
   ```

4. **Review and create:**
   - High-confidence suggestions → Create tasks
   - Medium-confidence → Review and decide
   - Low-confidence → Dismiss or clarify

### Example 3: Process Specific Log Entry

**Scenario:** You remember mentioning something in a log and want to create a task.

**Steps:**
1. **Read specific log:**
   ```python
   read_daily_log(date="2026-01-15")
   ```

2. **Find relevant entry:**
   - Locate the entry mentioning the action

3. **Generate suggestion:**
   ```python
   suggest_tasks_from_text(
       text="<specific log entry>",
       context="daily_log",
       mode="review"
   )
   ```

4. **Create task:**
   - If suggestion is good → Create
   - Or create manually from the entry

---

## Best Practices

### When to Process Logs

**Process logs:**
- **Daily**: Evening check-in (process today's log)
- **Weekly**: During weekly review (process past week)
- **As needed**: When you remember mentioning something

**Don't over-process:**
- Not every log entry needs a task
- Focus on actionable items
- Some entries are just notes/reflections

### Log Summary Creation

**Good summaries:**
- ✅ Include key activities and commitments
- ✅ Note things mentioned that need action
- ✅ Include context (when, why)
- ✅ Be concise but complete

**Poor summaries:**
- ❌ Too vague: "Did stuff"
- ❌ Too detailed: Every single activity
- ❌ Missing context: No when/why

### Task Creation

**Create tasks for:**
- ✅ Commitments made
- ✅ Things you said you'd do
- ✅ Ideas that need action
- ✅ Follow-ups needed
- ✅ Learning that needs practice

**Don't create tasks for:**
- ❌ Things already done
- ❌ Thoughts/reflections (unless actionable)
- ❌ Things you're just considering
- ❌ Already have task for it

### Suggestion Review

**High confidence (0.8+):**
- Usually worth creating
- Review quickly to verify
- Create if makes sense

**Medium confidence (0.5-0.8):**
- Review carefully
- May need more context
- Create if truly actionable

**Low confidence (<0.5):**
- May not be actionable
- May need clarification
- Dismiss if not relevant

---

## Integration with Other Skills

This skill works well with:
- **`evening-checkin`**: Process today's log in evening
- **`weekly-review`**: Process past week's logs
- **`inbox-processing`**: Logs are another source of inputs
- **`task-prioritization`**: Prioritize created tasks
- **`interactive-morning-review-runbook`**: Review tasks created from logs

---

## Troubleshooting

### "AI suggestions aren't accurate"

**Solutions:**
- Provide better log summary (more context)
- Review logs more carefully before summarizing
- Focus on high-confidence suggestions
- Create tasks manually if needed

### "I'm creating too many tasks"

**Solutions:**
- Be selective - only create truly actionable items
- Review suggestions carefully
- Some items can be notes, not tasks
- Focus on high-confidence suggestions

### "I forget to process logs"

**Solutions:**
- Add to evening check-in routine
- Process during weekly review
- Set reminder to process logs
- Make it a habit

### "Tasks from logs aren't clear"

**Solutions:**
- Add notes explaining source
- Clarify task when creating
- Review and refine after creation
- Link to original log entry if possible

---

## Success Criteria

Successful log-to-tasks conversion:
- ✓ Logs reviewed for actionable items
- ✓ High-confidence suggestions identified
- ✓ Tasks created from suggestions
- ✓ Tasks are clear and actionable
- ✓ Tasks linked to projects/contexts
- ✓ Nothing actionable is lost

---

## Commands Reference

### Reading Logs
```bash
# Read today's log
read_daily_log(date="today")

# Read recent logs
read_recent_logs(days=7)

# Read specific date
read_daily_log(date="YYYY-MM-DD")
```

### Generating Suggestions
```python
# From log content
suggest_tasks_from_text(
    text="<log summary>",
    context="daily_log",
    mode="review"
)
```

### Creating Tasks
```python
# From suggestion
create_tasks_from_suggestion(suggestion_id="...")

# Direct creation
create_task(
    title="...",
    project="...",
    priority="...",
    context="...",
    notes="From daily log YYYY-MM-DD"
)
```

---

## Workflow Summary

```
Log-to-Tasks Conversion Workflow
│
├─ 1. Select Logs to Review
│   ├─ read_daily_log(date="today")
│   ├─ read_recent_logs(days=7)
│   └─ read_daily_log(date="YYYY-MM-DD")
│
├─ 2. Extract Log Content
│   └─ Get text from log entries
│
├─ 3. Generate Task Suggestions
│   └─ suggest_tasks_from_text(text="<log summary>", context="daily_log")
│
├─ 4. Review and Filter Suggestions
│   ├─ Check confidence scores
│   ├─ Verify actionable
│   └─ Filter relevant suggestions
│
├─ 5. Create Tasks from Suggestions
│   ├─ create_tasks_from_suggestion(suggestion_id)
│   └─ Or create_task() with customization
│
├─ 6. Link Tasks to Source Logs (Optional)
│   └─ Add notes referencing log entry
│
└─ 7. Review Created Tasks
    ├─ list_tasks(status="active")
    └─ Verify and adjust as needed
```

---

Remember: The goal is to capture actionable items from logs before they're forgotten. Not every log entry needs a task - focus on things that are truly actionable. Process logs regularly (daily or weekly) to prevent task loss.
