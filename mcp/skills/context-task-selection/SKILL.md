---
name: Context-Based Task Selection
description: Helps select tasks based on current context using context filtering and provides guidance on context switching
version: 1.0.0
tags:
  - routine
  - productivity
  - task-selection
  - context
author: GTD System
---

# Context-Based Task Selection

A workflow skill that helps you select and work with tasks based on your current context. This skill uses context filtering to show only relevant tasks and provides guidance on effective context switching.

## When to Use

Use this skill when you:
- Want to see what tasks you can work on in your current location/situation
- Need to switch contexts and want to see what's available in the new context
- Are planning your day and want to review tasks by context
- Want to understand which contexts have the most tasks
- Need guidance on effective context switching strategies

## How It Works

This workflow uses MCP tools to filter and display tasks by context, helping you focus on what's actionable right now. It also provides guidance on context switching to maximize productivity.

### MCP Tools Used

- `get_context_tasks(context, energy, limit)`: Get tasks available in a specific context with optional energy level filtering
- `list_tasks(context, energy, priority, project, status, limit)`: List tasks with multiple filter options including context

## Workflow Steps

### Step 1: Determine Your Current Context

**Purpose:** Identify where you are or what context you're about to enter.

**Available Contexts:**
- **`computer`**: Tasks that require a computer (coding, writing, research, etc.)
- **`home`**: Tasks you can do at home (household chores, personal projects, etc.)
- **`office`**: Tasks for when you're at the office (meetings, collaboration, etc.)
- **`phone`**: Tasks that are phone calls or can be done via phone
- **`errands`**: Tasks that require you to be out and about (shopping, appointments, etc.)

**Actions:**
1. Identify your current physical location or situation
2. Determine which context best matches your current state
3. Consider if you'll be switching contexts soon (e.g., "I'm at home now but going to the office later")

**Tip:** You can check multiple contexts if you're planning ahead or transitioning between locations.

---

### Step 2: Get Tasks for Your Current Context

**Purpose:** See what tasks are available in your current context.

**Actions:**
1. Call `get_context_tasks(context="<your-context>")` with your identified context
   - Example: `get_context_tasks(context="computer")` if you're at your computer
   - Example: `get_context_tasks(context="home")` if you're at home
2. Review the returned tasks:
   - Note the count of available tasks
   - Review task titles, priorities, and energy levels
   - Identify which tasks are most relevant right now

**Optional Filters:**
- Add energy level: `get_context_tasks(context="computer", energy="high")` for high-energy tasks
- Limit results: `get_context_tasks(context="home", limit=5)` to see top 5 tasks

**What to look for:**
- Tasks that match your current energy level
- High-priority items that need attention
- Tasks you can make meaningful progress on
- Tasks that might need updating or deferring

---

### Step 3: Use Advanced Filtering with list_tasks

**Purpose:** Get more detailed task lists with multiple filter combinations.

**Actions:**
1. Use `list_tasks()` with context and other filters:
   - `list_tasks(context="computer", status="active", limit=20)` - All active computer tasks
   - `list_tasks(context="home", energy="low", priority="not_urgent_important")` - Low-energy home tasks
   - `list_tasks(context="phone", status="active")` - All phone calls to make

2. Combine filters based on your needs:
   - **Context + Energy**: Match tasks to your current energy level
   - **Context + Priority**: Focus on urgent/important items first
   - **Context + Project**: See tasks for a specific project in this context

**Common Filter Combinations:**
- High-energy computer tasks: `list_tasks(context="computer", energy="high", status="active")`
- Low-energy home tasks: `list_tasks(context="home", energy="low", status="active")`
- Urgent phone calls: `list_tasks(context="phone", priority="urgent_important", status="active")`

---

### Step 4: Review Other Contexts (Planning Ahead)

**Purpose:** See what's available in other contexts for planning and context switching.

**Actions:**
1. If you're planning to switch contexts, check what's available:
   - `get_context_tasks(context="errands")` if you're going out
   - `get_context_tasks(context="phone")` if you have time for calls
   - `get_context_tasks(context="home")` if you'll be home later

2. Compare task counts across contexts:
   - Which context has the most tasks?
   - Which context has high-priority items?
   - Which context matches your planned energy level?

**Planning Strategy:**
- Check contexts you'll be in later today
- Group errands together if you see multiple errand tasks
- Schedule phone calls when you have time for that context

---

### Step 5: Select Tasks to Work On

**Purpose:** Choose which tasks to focus on based on your context and current situation.

**Actions:**
1. From the tasks retrieved, select 1-3 tasks to focus on:
   - Consider your current energy level
   - Match task energy requirements to your energy
   - Prioritize urgent/important items
   - Choose tasks you can make meaningful progress on

2. If you need task details:
   - Use `get_task_details(task_id="<id>")` for any task you want more information about
   - Review notes, project context, and related information

3. Start working on selected tasks

**Selection Criteria:**
- **Energy Match**: High-energy tasks when you have energy, low-energy when tired
- **Priority**: Urgent/important items first
- **Progress**: Tasks you can actually complete or make progress on
- **Context Fit**: Tasks that truly fit your current context

---

## Context Switching Guidance

### When to Switch Contexts

**Switch contexts when:**
- You've completed all actionable tasks in your current context
- Your energy level changes and doesn't match available tasks
- You're physically moving to a new location
- You have a natural break (lunch, commute, etc.)

### Effective Context Switching

1. **Batch Similar Contexts**: Group errands together, make multiple phone calls at once
2. **Match Energy to Context**: 
   - High energy → Computer tasks, complex work
   - Medium energy → Phone calls, planning
   - Low energy → Errands, simple home tasks
3. **Plan Transitions**: Check next context before switching to prepare
4. **Minimize Switches**: Try to complete all tasks in a context before switching

### Context Switching Workflow

1. **Before leaving current context:**
   - Review what you've accomplished
   - Note any tasks you started but didn't finish
   - Check if there are urgent items you should handle first

2. **When entering new context:**
   - Use this skill to see what's available
   - Select tasks that match your energy and time available
   - Focus on high-priority items first

3. **After context switch:**
   - Update task status if needed
   - Log what you accomplished in the previous context
   - Set up for success in the new context

---

## Best Practices

- **Regular Context Checks**: Use this skill multiple times per day as you move between contexts
- **Energy Matching**: Always consider your energy level when selecting tasks
- **Batch Processing**: Group similar context tasks together (all errands, all phone calls)
- **Priority First**: Within a context, prioritize urgent/important tasks
- **Context Accuracy**: Ensure tasks are assigned to the correct context when creating them
- **Review Before Switching**: Always check what's available before leaving a context

---

## Integration with Other Skills

This skill works well with:
- **`morning-checkin`**: Use context task selection as part of morning routine
- **`daily-review`**: Review tasks by context during daily review
- **`inbox-processing`**: When processing inbox, assign correct contexts to new tasks
- **`task-prioritization`**: Combine with prioritization guidance for better task selection

---

## Troubleshooting

### "No tasks found in this context"

**Possible causes:**
- Tasks might be assigned to different contexts
- Tasks might be completed or deferred
- You might need to create tasks for this context

**Solutions:**
- Check other contexts: `get_context_tasks(context="computer")`, `get_context_tasks(context="home")`, etc.
- Review all active tasks: `list_tasks(status="active")` to see what contexts have tasks
- Consider if tasks need to be created or if context assignments need updating

### "Too many tasks in this context"

**Solutions:**
- Use filters to narrow down: `get_context_tasks(context="computer", energy="high", limit=5)`
- Use priority filter: `list_tasks(context="computer", priority="urgent_important")`
- Focus on top 3-5 tasks rather than trying to see everything

### "Tasks don't match my current situation"

**Solutions:**
- Verify tasks have correct context assignments
- Consider if tasks need to be moved to different contexts
- Use `update_task()` to correct context assignments if needed

---

## Success Criteria

A successful execution means:
- ✓ You have a clear view of tasks available in your current context
- ✓ You've selected 1-3 tasks to focus on that match your energy and situation
- ✓ You understand what's available in other contexts for planning
- ✓ You have a plan for context switching if needed
- ✓ Tasks selected are actionable and appropriate for your current context
