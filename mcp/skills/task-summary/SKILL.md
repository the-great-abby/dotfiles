---
name: Task Summary Generator
description: Generate comprehensive summaries of tasks grouped by priority, project, context, or status. Provides formatted reports that help users understand their task landscape at a glance.
version: 2.0.0
tags:
  - tasks
  - summary
  - productivity
  - reports
  - organization
author: GTD System
---

# Task Summary Generator

A comprehensive skill for generating formatted task summaries that help users understand their task landscape at a glance. Supports multiple grouping methods and summary formats.

## When to Use

Use this skill when you need to:
- **Generate task reports**: Create formatted summaries of tasks
- **Review task landscape**: Get an overview of all active tasks
- **Group by criteria**: Organize tasks by priority, project, context, or status
- **Identify patterns**: See where tasks cluster (which projects, priorities, etc.)
- **Quick overview**: Get a high-level view before diving into specifics
- **Share status**: Generate summaries for handoffs or reviews

## How It Works

This skill uses GTD tools to retrieve tasks and then organizes them into meaningful summaries using various grouping and formatting approaches.

## Summary Formats

### 1. **By Priority** (Eisenhower Matrix)

Groups tasks into priority quadrants:
- **Urgent & Important**: Must do soon
- **Not Urgent & Important**: Important but can plan
- **Urgent & Not Important**: Time-sensitive but lower importance
- **Not Urgent & Not Important**: Nice to have

### 2. **By Project**

Groups tasks by their project, showing:
- Project name
- Task count per project
- Tasks within each project
- Project progress indicators

### 3. **By Context**

Groups tasks by where/when they can be done:
- **Computer**: Tasks requiring a computer
- **Home**: Tasks at home
- **Office**: Tasks at office
- **Phone**: Calls to make
- **Errands**: Tasks while out

### 4. **By Status**

Groups tasks by their current status:
- **Active**: Currently in progress
- **On Hold**: Paused or waiting
- **Done**: Completed
- **Archived**: Historical

### 5. **Combined View** (Priority within Projects)

Shows projects with tasks organized by priority within each project. This provides both project context and priority information.

## Step-by-Step Workflow

### Step 1: Retrieve Tasks

Use `gtd_list_tasks` to get tasks:
- Specify filters (context, priority, project, status)
- Set limit if needed (default: 50)

**Examples:**
```python
# Get all active tasks
tasks = gtd_list_tasks(status="active")

# Get high-priority tasks
tasks = gtd_list_tasks(priority="urgent_important", status="active")

# Get tasks for a specific context
tasks = gtd_list_tasks(context="computer", status="active")
```

### Step 2: Group Tasks

Organize tasks by your chosen grouping method:

**By Priority:**
1. Separate tasks into priority categories
2. Count tasks in each category
3. List tasks within each category

**By Project:**
1. Group tasks by project field
2. Count tasks per project
3. Show tasks within each project group
4. Handle tasks without projects separately

**By Context:**
1. Group tasks by context field
2. Count tasks per context
3. List tasks within each context
4. Show which contexts have the most tasks

### Step 3: Format Summary

Create a formatted summary that includes:

**Header:**
- Total task count
- Grouping method used
- Date/time of summary

**For Each Group:**
- Group name (priority/project/context)
- Task count in group
- List of tasks (title, priority if not grouping by priority)
- Optional: Brief descriptions

**Footer:**
- Summary statistics
- Insights (e.g., "Most tasks are in Project X", "High priority tasks: 5")

### Step 4: Present Summary

Format the summary clearly:
- Use headers and sections
- Use bullet points or numbering
- Group related information
- Highlight important information
- Keep it scannable

## Detailed Workflow Examples

### Example 1: Summary by Priority

```python
# 1. Get all active tasks
tasks = gtd_list_tasks(status="active")

# 2. Group by priority
urgent_important = [t for t in tasks if t.get("priority") == "urgent_important"]
not_urgent_important = [t for t in tasks if t.get("priority") == "not_urgent_important"]
# ... etc

# 3. Format summary
summary = f"""
Task Summary by Priority
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Active Tasks: {len(tasks)}

🔥 Urgent & Important ({len(urgent_important)} tasks):
{format_task_list(urgent_important)}

⭐ Not Urgent & Important ({len(not_urgent_important)} tasks):
{format_task_list(not_urgent_important)}

[... etc ...]
"""
```

### Example 2: Summary by Project

```python
# 1. Get tasks
tasks = gtd_list_tasks(status="active")

# 2. Group by project
projects = {}
for task in tasks:
    project = task.get("project", "_no_project")
    if project not in projects:
        projects[project] = []
    projects[project].append(task)

# 3. Format summary
summary = f"""
Task Summary by Project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Active Tasks: {len(tasks)}

"""
for project, project_tasks in sorted(projects.items()):
    summary += f"""
📁 {project} ({len(project_tasks)} tasks):
{format_task_list(project_tasks)}
"""
```

### Example 3: Combined View (Priority within Projects)

```python
# 1. Get tasks
tasks = gtd_list_tasks(status="active")

# 2. Group by project, then by priority within each project
projects = {}
for task in tasks:
    project = task.get("project", "_no_project")
    if project not in projects:
        projects[project] = {
            "urgent_important": [],
            "not_urgent_important": [],
            # ... etc
        }
    priority = task.get("priority", "no_priority")
    if priority in projects[project]:
        projects[project][priority].append(task)

# 3. Format with nested structure
summary = f"""
Task Summary: Priority within Projects
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
for project, priorities in sorted(projects.items()):
    total = sum(len(tasks) for tasks in priorities.values())
    summary += f"""
📁 {project} ({total} total tasks):
"""
    for priority, priority_tasks in priorities.items():
        if priority_tasks:
            summary += f"  🔥 {priority}: {len(priority_tasks)} tasks\n"
            for task in priority_tasks:
                summary += f"     • {task.get('title')}\n"
```

## Formatting Functions

When creating summaries, consider these formatting helpers:

**Task List Format:**
- Show task title
- Include priority (if not grouping by priority)
- Include project (if not grouping by project)
- Include context (if not grouping by context)
- Optional: Include brief notes or descriptions

**Statistics:**
- Total task count
- Count per group
- Percentage distribution
- Insights (e.g., "5 urgent tasks need attention")

**Visual Organization:**
- Use emojis/icons for visual scanning
- Use headers and sections
- Use consistent indentation
- Group related information

## Best Practices

### Choose the Right Grouping

- **By Priority**: When user wants to focus on what's most important
- **By Project**: When user wants to see project progress
- **By Context**: When user wants to know what they can do in a specific location
- **Combined**: When user wants both project and priority context

### Keep Summaries Scannable

- Use clear headers
- Use bullet points or numbering
- Limit detail per task (title + key metadata)
- Group related information
- Highlight important items

### Provide Insights

Beyond just listing tasks, provide:
- **Statistics**: "You have 12 active tasks across 5 projects"
- **Observations**: "Most tasks are in Project X"
- **Recommendations**: "Consider focusing on urgent_important tasks first"

### Handle Edge Cases

- Tasks without projects: Group as "No Project" or "Standalone Tasks"
- Tasks without priority: Group separately or assign default
- Empty groups: Either omit or show "No tasks in this category"

## Integration with Other Skills

This skill works well with:
- **`morning-checkin`**: Generate task summary for morning review
- **`daily-review`**: Include task summary in daily review
- **`project-status-review`**: Combine with project status information

## Example Output

```
Task Summary by Priority
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Active Tasks: 23
Generated: 2025-01-19 13:45:00

🔥 Urgent & Important (3 tasks):
  • Review oncall handoff notes (project: oncall-tasks)
  • Troubleshoot AI suggestions feature (project: ai-enhanced)
  • Complete Kubernetes learning module (project: cka-exam-preparation)

⭐ Not Urgent & Important (12 tasks):
  • Learn Kubernetes concepts (project: cka-exam-preparation)
  • Update CKA exam preparation plan (project: cka-exam-preparation)
  • Schedule time for 12-factor agents (project: ai-enhanced)
  [... 9 more tasks ...]

⚡ Urgent & Not Important (2 tasks):
  • Review email backlog
  • Update calendar

📋 Not Urgent & Not Important (6 tasks):
  • Clean room
  • Update system preferences
  [... 4 more tasks ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Insights:
- Most tasks (12) are "Not Urgent & Important" - good balance
- 3 urgent tasks need immediate attention
- Tasks span 4 projects: oncall-tasks, ai-enhanced, cka-exam-preparation, and personal
```

## Usage

### Via Skill Instructions

```python
# Get instructions on how to generate summaries
execute_agent_skill(
    skill_name="task-summary",
    method="instructions"
)
```

### Direct Tool Usage

The skill guides you to use GTD tools directly:

```python
# Generate summary by priority
tasks = gtd_list_tasks(status="active")
# Then group and format as shown in examples above

# Generate summary by project
tasks = gtd_list_tasks(status="active")
# Then group by project and format

# Generate combined view
tasks = gtd_list_tasks(status="active")
# Then group by project, then by priority
```

## Success Criteria

A good task summary:
- ✓ Shows total task count
- ✓ Groups tasks meaningfully
- ✓ Is easy to scan visually
- ✓ Provides insights or observations
- ✓ Helps user prioritize or organize
- ✓ Identifies patterns or clusters

Remember: The goal is to help users quickly understand their task landscape and make informed decisions about what to focus on.
