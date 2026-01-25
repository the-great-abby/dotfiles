---
name: Task Prioritization Guidance
description: Provides framework and guidance for task prioritization using Eisenhower Matrix and GTD principles. Analyzes tasks, suggests priority adjustments, and helps focus on what matters most.
version: 1.0.0
tags:
  - tasks
  - prioritization
  - productivity
  - gtd
  - focus
author: GTD System
---

# Task Prioritization Guidance

A comprehensive skill for prioritizing tasks using the Eisenhower Matrix and GTD principles. Helps you focus on what matters most by analyzing tasks, suggesting priorities, and providing prioritization framework.

## When to Use

Use this skill when you need to:
- **Prioritize tasks**: Determine what to focus on
- **Review priorities**: Check if current priorities are correct
- **Focus on important work**: Identify urgent vs. important tasks
- **Plan your day**: Set priorities for the day
- **Weekly planning**: Prioritize tasks for the week
- **Overwhelmed**: Too many tasks and need to focus

## How It Works

This skill uses the Eisenhower Matrix framework to categorize tasks by urgency and importance, then provides guidance on what to focus on based on GTD principles.

## Step-by-Step Workflow

### Step 1: Gather All Active Tasks

**Purpose:** Get complete picture of what needs to be done.

**Actions:**
1. Call `list_tasks(status="active")` to get all active tasks
2. Review the tasks to understand scope
3. Note total count and distribution

**MCP Tools:**
- `list_tasks(status="active")` - Get all active tasks
- `get_task_details(task_id)` - Get details for specific tasks

**What to note:**
- Total number of active tasks
- Tasks by project
- Tasks by context
- Tasks by priority (current)

---

### Step 2: Categorize by Eisenhower Matrix

**Purpose:** Organize tasks into priority quadrants.

**Actions:**
1. For each task, determine:
   - **Urgent**: Needs to be done soon (deadlines, time-sensitive)
   - **Important**: Matters for goals/projects/values
2. Categorize into quadrants:
   - **Urgent & Important** (Do First): Must do soon, matters
   - **Not Urgent & Important** (Schedule): Matters but can plan
   - **Urgent & Not Important** (Delegate/Delegate): Time-sensitive but lower value
   - **Not Urgent & Not Important** (Eliminate): Nice to have, low value

**Eisenhower Matrix:**
```
                Urgent          Not Urgent
Important    [Do First]      [Schedule]
Not Important [Delegate]     [Eliminate]
```

**Questions to ask:**
- Does this have a deadline or time constraint? → Urgent
- Does this matter for my goals/projects/values? → Important
- What happens if I don't do this? → Helps determine importance

**MCP Tools:**
- Review tasks using `get_task_details(task_id)` for context
- Use `list_tasks(priority="...")` to see current priorities

---

### Step 3: Review Urgent & Important Tasks

**Purpose:** Identify what must be done soon.

**Actions:**
1. List all tasks in "Urgent & Important" quadrant
2. For each task:
   - Verify it's truly urgent (deadline, consequence)
   - Verify it's truly important (goal/project/value)
   - Check if it can be broken down
   - Check if it can be delegated
3. Limit to 3-5 tasks maximum (cognitive load)
4. These become your top priorities

**MCP Tools:**
- `list_tasks(status="active")` - Filter for urgent & important
- `get_task_details(task_id)` - Check deadlines and importance
- `update_task(task_id, priority="urgent_important")` - Set priority

**Best practices:**
- Limit urgent & important to 3-5 items
- If more than 5, some may not be truly urgent
- Break large tasks into smaller ones
- Consider if deadlines are real or self-imposed

---

### Step 4: Review Not Urgent & Important Tasks

**Purpose:** Identify important work that can be scheduled.

**Actions:**
1. List all tasks in "Not Urgent & Important" quadrant
2. For each task:
   - Schedule time for it (time-blocking)
   - Set deadlines if needed
   - Break into smaller tasks if large
   - Link to goals/projects
3. These are your strategic priorities

**MCP Tools:**
- `list_tasks(status="active")` - Filter for not urgent & important
- `update_task(task_id, priority="not_urgent_important")` - Set priority
- Calendar integration (if available) - Schedule time

**Best practices:**
- These are often the most valuable tasks
- Schedule dedicated time for them
- Don't let urgent tasks crowd these out
- These build toward long-term goals

---

### Step 5: Handle Urgent & Not Important Tasks

**Purpose:** Deal with time-sensitive but lower-value tasks.

**Actions:**
1. List all tasks in "Urgent & Not Important" quadrant
2. For each task:
   - Can it be delegated?
   - Can it be automated?
   - Can it be simplified?
   - Is the urgency real or perceived?
3. Minimize time spent on these
4. Consider if they can be eliminated

**MCP Tools:**
- `list_tasks(status="active")` - Filter for urgent & not important
- `update_task(task_id, priority="urgent_not_important")` - Set priority
- `defer_task(task_id, until="...")` - Defer if possible

**Best practices:**
- Minimize these tasks
- Delegate when possible
- Question if urgency is real
- Don't let these crowd out important work

---

### Step 6: Eliminate or Defer Not Urgent & Not Important

**Purpose:** Remove low-value tasks from focus.

**Actions:**
1. List all tasks in "Not Urgent & Not Important" quadrant
2. For each task:
   - Can it be deleted?
   - Can it be deferred indefinitely?
   - Does it serve any purpose?
3. Delete or defer these tasks
4. Don't spend time on them

**MCP Tools:**
- `list_tasks(status="active")` - Filter for not urgent & not important
- Delete tasks that serve no purpose
- `defer_task(task_id, until="someday")` - Defer indefinitely

**Best practices:**
- Be ruthless - if it doesn't matter, don't do it
- Defer to "someday/maybe" if unsure
- Delete if clearly not needed
- Free up mental space

---

### Step 7: Consider Context and Energy

**Purpose:** Match tasks to your current situation.

**Actions:**
1. Determine your current context:
   - Where are you? (home, office, computer, phone, errands)
   - What's your energy level? (high, medium, low)
2. Filter tasks by context:
   - `get_context_tasks(context="...")` - Get tasks for context
   - `list_tasks(energy="...")` - Get tasks matching energy
3. Match priority tasks to context and energy

**MCP Tools:**
- `get_context_tasks(context="computer", energy="high")` - Filter by context and energy
- `list_tasks(context="...", energy="...")` - Combined filters

**Best practices:**
- Match high-energy tasks to high-energy times
- Match low-energy tasks to low-energy times
- Work on urgent & important in best context
- Batch tasks by context to reduce switching

---

### Step 8: Update Task Priorities

**Purpose:** Set priorities in the system.

**Actions:**
1. For tasks in each quadrant, update priority:
   - Urgent & Important: `update_task(task_id, priority="urgent_important")`
   - Not Urgent & Important: `update_task(task_id, priority="not_urgent_important")`
   - Urgent & Not Important: `update_task(task_id, priority="urgent_not_important")`
   - Not Urgent & Not Important: `update_task(task_id, priority="not_urgent_not_important")`
2. Verify priorities are set correctly
3. Review priority distribution

**MCP Tools:**
- `update_task(task_id, priority="...")` - Update task priority
- `list_tasks(priority="...")` - Verify priorities

**Priority values:**
- `urgent_important` - Do first
- `not_urgent_important` - Schedule
- `urgent_not_important` - Delegate/minimize
- `not_urgent_not_important` - Eliminate

---

### Step 9: Set Daily/Weekly Priorities

**Purpose:** Identify 1-3 top priorities for focus.

**Actions:**
1. From "Urgent & Important" quadrant, select 1-3 top priorities
2. These become your focus for today/this week
3. Ensure these tasks are actionable
4. Create or update tasks if needed

**MCP Tools:**
- `create_task(title="...", priority="urgent_important")` - Create priority task
- `update_task(task_id, priority="urgent_important")` - Update to priority

**Best practices:**
- Limit to 1-3 priorities maximum
- Be realistic about what can be done
- Focus on completion, not just starting
- Review priorities daily

---

## Detailed Workflow Examples

### Example 1: Daily Prioritization

**Scenario:** You have 20 active tasks and need to focus.

**Steps:**
1. **Gather tasks:** `list_tasks(status="active")` → 20 tasks
2. **Categorize:**
   - Urgent & Important: 3 tasks
   - Not Urgent & Important: 8 tasks
   - Urgent & Not Important: 4 tasks
   - Not Urgent & Not Important: 5 tasks
3. **Focus on Urgent & Important:** Select top 2 for today
4. **Schedule Not Urgent & Important:** Time-block 1-2 for this week
5. **Minimize others:** Delegate or defer

### Example 2: Weekly Prioritization

**Scenario:** Planning priorities for the week.

**Steps:**
1. **Gather all tasks:** `list_tasks(status="active")`
2. **Categorize by matrix**
3. **Set weekly focus:**
   - 3-5 Urgent & Important tasks
   - 5-7 Not Urgent & Important tasks (strategic work)
4. **Update priorities:** `update_task()` for each
5. **Schedule time:** Time-block important tasks

### Example 3: Context-Based Prioritization

**Scenario:** You're at home with low energy.

**Steps:**
1. **Get context tasks:** `get_context_tasks(context="home", energy="low")`
2. **Categorize by matrix** within context
3. **Focus on:**
   - Low-energy, important tasks
   - Defer high-energy tasks
4. **Match priorities to energy**

---

## Best Practices

### Eisenhower Matrix Usage

**Do First (Urgent & Important):**
- Limit to 3-5 items
- These get immediate attention
- Complete before moving on
- These are your daily priorities

**Schedule (Not Urgent & Important):**
- These are strategic priorities
- Schedule dedicated time
- Don't let urgent tasks crowd these out
- These build long-term value

**Delegate (Urgent & Not Important):**
- Minimize time on these
- Delegate when possible
- Question if urgency is real
- Automate if possible

**Eliminate (Not Urgent & Not Important):**
- Delete or defer indefinitely
- Don't spend time on these
- Free up mental space
- Focus on what matters

### Priority Setting

**Be realistic:**
- Not everything can be urgent & important
- Most tasks should be "not urgent & important"
- Limit urgent tasks to real deadlines
- Focus on important work

**Review regularly:**
- Priorities change
- Review daily or weekly
- Adjust as needed
- Don't let priorities get stale

**Consider goals:**
- Link priorities to goals
- Important = matters for goals
- Urgent = has deadline
- Balance urgent and important

### Context and Energy Matching

**Match to energy:**
- High energy → High-energy tasks
- Low energy → Low-energy tasks
- Don't fight your energy
- Work with your patterns

**Match to context:**
- Computer tasks → Computer context
- Phone tasks → Phone context
- Batch by context
- Reduce context switching

---

## Integration with Other Skills

This skill works well with:
- **`interactive-morning-review-runbook`**: Set daily priorities in morning
- **`evening-checkin`**: Review and adjust priorities
- **`weekly-review`**: Set weekly priorities
- **`energy-audit-planning`**: Match priorities to energy
- **`context-task-selection`**: Filter priorities by context

---

## Troubleshooting

### "Everything seems urgent and important"

**Solutions:**
- Question if deadlines are real
- Break large tasks into smaller ones
- Some may be "not urgent" if you're honest
- Limit to 3-5 truly urgent & important

### "I have too many not urgent & important tasks"

**Solutions:**
- This is normal - most tasks should be here
- Schedule time for them
- Don't let urgent tasks crowd them out
- Focus on 5-7 per week

### "I don't know what's important"

**Solutions:**
- Link to goals: Does this help achieve a goal?
- Link to projects: Does this move a project forward?
- Link to values: Does this align with values?
- If unsure, it's probably not urgent & important

### "Tasks keep becoming urgent"

**Solutions:**
- Plan better - schedule important work
- Don't procrastinate on important tasks
- Set deadlines for important work
- Work on "not urgent & important" regularly

---

## Success Criteria

Successful prioritization:
- ✓ Tasks categorized by Eisenhower Matrix
- ✓ 1-3 top priorities identified
- ✓ Priorities match context and energy
- ✓ Not urgent & important tasks scheduled
- ✓ Low-value tasks eliminated or deferred
- ✓ Focus is clear and actionable

---

## Commands Reference

### Task Management
```bash
# List tasks
list_tasks(status="active")
list_tasks(priority="urgent_important")
list_tasks(context="computer", energy="high")

# Get task details
get_task_details(task_id)

# Update priority
update_task(task_id, priority="urgent_important")

# Get context tasks
get_context_tasks(context="computer", energy="high")
```

---

## Workflow Summary

```
Task Prioritization Workflow
│
├─ 1. Gather All Active Tasks
│   └─ list_tasks(status="active")
│
├─ 2. Categorize by Eisenhower Matrix
│   ├─ Urgent & Important (Do First)
│   ├─ Not Urgent & Important (Schedule)
│   ├─ Urgent & Not Important (Delegate)
│   └─ Not Urgent & Not Important (Eliminate)
│
├─ 3. Review Urgent & Important
│   └─ Limit to 3-5, set as top priorities
│
├─ 4. Review Not Urgent & Important
│   └─ Schedule time, link to goals
│
├─ 5. Handle Urgent & Not Important
│   └─ Delegate, automate, minimize
│
├─ 6. Eliminate Not Urgent & Not Important
│   └─ Delete or defer indefinitely
│
├─ 7. Consider Context and Energy
│   └─ Match tasks to situation
│
├─ 8. Update Task Priorities
│   └─ update_task(priority="...")
│
└─ 9. Set Daily/Weekly Priorities
    └─ Identify 1-3 focus items
```

---

Remember: Prioritization is about focus. Not everything can be urgent & important. Most valuable work is often "not urgent & important" - schedule time for it. Eliminate or defer what doesn't matter. Focus on what moves you toward your goals.
