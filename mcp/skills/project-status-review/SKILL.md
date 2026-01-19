---
name: Project Status Review
description: Comprehensive project review workflow that reviews project progress, uses status templates, and provides deep dive analysis
version: 1.0.0
tags:
  - review
  - projects
  - planning
  - productivity
  - weekly
author: GTD System
---

# Project Status Review

A structured workflow for reviewing all your projects, assessing their progress, and identifying next actions. This skill helps you maintain clarity on project status and ensures nothing falls through the cracks.

## When to Use

Use this skill when you:
- Need to review all active projects (weekly review, monthly review)
- Want to assess project progress and identify blockers
- Are planning your week/month and need project visibility
- Want to identify which projects need attention
- Need to prepare project status updates or reports
- Want to do a deep dive into specific projects

**Recommended frequency:**
- **Weekly**: Quick review of all active projects
- **Monthly**: Comprehensive review with deep dives
- **As needed**: When planning or when projects feel unclear

## How It Works

This workflow uses MCP tools to systematically review projects, assess their status, and identify next actions. It provides structured templates for consistent project reviews.

### MCP Tools Used

- `list_projects(status)`: Get all projects with their basic information
- `get_project_status(project_name)`: Get project progress, task counts, and active tasks
- `get_project_details(project_name)`: Get comprehensive project information including all tasks and metadata

## Workflow Steps

### Step 1: List All Projects

**Purpose:** Get an overview of all your projects to understand the full scope.

**Actions:**
1. Call `list_projects(status="active")` to see all active projects
   - This returns project names, status, creation dates, and basic metadata
   - Note the total count of active projects
2. Optionally, call `list_projects(status="all")` to see:
   - Active projects (in progress)
   - On-hold projects (paused)
   - Done projects (completed)
3. Review the list and identify:
   - Which projects are active
   - Which projects might need attention
   - Any projects that seem stuck or unclear

**What to look for:**
- Total number of active projects (too many = overwhelm, too few = might be missing something)
- Projects that haven't been updated recently
- Projects with unclear names or purposes

---

### Step 2: Review Project Status for Each Project

**Purpose:** Get a quick status overview for each project to identify which need attention.

**Actions:**
1. For each active project, call `get_project_status(project_name="<name>")`
2. Review the status information:
   - **Task counts**: How many active, on-hold, and done tasks
   - **Active tasks list**: What tasks are currently actionable
   - **Progress indicators**: Overall project health
3. Use the **Quick Status Template** (see below) to record key information

**Quick Status Template:**
```
Project: [Name]
Status: [Active/On-Hold/Done]
Tasks: [Active: X, On-Hold: Y, Done: Z]
Next Actions: [List 1-3 key next actions]
Blockers: [Any blockers or issues]
Health: [Green/Yellow/Red]
```

**Health Indicators:**
- **Green**: Active tasks, clear next actions, making progress
- **Yellow**: Some tasks but unclear next actions, or stalled
- **Red**: No active tasks, unclear purpose, or major blockers

**Efficiency Tip:** Start with projects that seem most important or most unclear. You don't need to review every project in detail - focus on what matters.

---

### Step 3: Deep Dive into Key Projects

**Purpose:** Get comprehensive information about projects that need attention or are unclear.

**Actions:**
1. Identify projects that need deep dive:
   - Projects with red/yellow health status
   - Projects that are important but unclear
   - Projects you haven't reviewed recently
   - Projects with blockers or issues
2. For each project needing deep dive, call `get_project_details(project_name="<name>")`
3. Review comprehensive information:
   - Full project metadata (description, repository, dates)
   - All tasks in the project (not just active)
   - Project README or notes
   - Task details and relationships
4. Use the **Deep Dive Template** (see below) to document findings

**Deep Dive Template:**
```
Project: [Name]
Purpose: [What is this project trying to achieve?]
Status: [Current state and progress]
Tasks Overview:
  - Active: [X tasks] - [Key active tasks]
  - On-Hold: [Y tasks] - [Why on hold?]
  - Done: [Z tasks] - [Recent completions]
Next Actions:
  1. [Most important next action]
  2. [Second priority]
  3. [Third priority]
Blockers/Issues:
  - [Issue 1]
  - [Issue 2]
Decisions Needed:
  - [Decision 1]
  - [Decision 2]
```

**Questions to ask during deep dive:**
- What is this project trying to achieve? (Is the purpose clear?)
- What's the next physical action? (GTD principle)
- Are there any blockers preventing progress?
- Is this project still relevant? (Should it be active, on-hold, or archived?)
- What would "done" look like? (Is the outcome clear?)

---

### Step 4: Identify Action Items

**Purpose:** Extract actionable items from the review to move projects forward.

**Actions:**
1. From your status reviews and deep dives, identify:
   - **Next actions** needed for each project
   - **Blockers** that need to be resolved
   - **Decisions** that need to be made
   - **Projects** that need status changes (activate, put on-hold, archive)
2. Create tasks or update existing tasks as needed:
   - Use `create_task()` for new next actions
   - Use `update_task()` to update existing tasks
   - Consider using `update_project()` if project status needs changing
3. Prioritize actions:
   - Which projects are most important right now?
   - Which next actions are most critical?
   - What can be deferred?

**Action Categories:**
- **Immediate**: Do this week
- **Soon**: Do this month
- **Someday**: Not urgent but important
- **Blocked**: Waiting on something/someone

---

### Step 5: Update Project Status and Documentation

**Purpose:** Ensure project information is current and accurate.

**Actions:**
1. Update project status if needed:
   - Projects that are actually done → mark as done
   - Projects that should be paused → mark as on-hold
   - Projects that should be active → ensure they're active
2. Update project documentation:
   - Add notes about blockers or decisions
   - Update project descriptions if purpose has changed
   - Document next actions in project README
3. Review and update tasks:
   - Ensure tasks have correct project assignments
   - Update task priorities based on project importance
   - Mark completed tasks as done

**GTD Principle:** Keep your system current. If project status in your system doesn't match reality, you won't trust your system.

---

## Status Templates

### Quick Status Template

Use this for a quick review of all projects:

```markdown
## Project: [Name]

- **Status**: [Active/On-Hold/Done]
- **Tasks**: Active: X | On-Hold: Y | Done: Z
- **Next Actions**: 
  - [Action 1]
  - [Action 2]
- **Health**: 🟢 Green / 🟡 Yellow / 🔴 Red
- **Notes**: [Brief notes]
```

### Comprehensive Status Template

Use this for projects that need detailed review:

```markdown
## Project: [Name]

### Purpose
[What is this project trying to achieve?]

### Current Status
- **Status**: [Active/On-Hold/Done]
- **Progress**: [X% complete or qualitative assessment]
- **Last Updated**: [Date]

### Tasks Breakdown
- **Active Tasks** (X):
  - [Task 1] - [Context, Priority]
  - [Task 2] - [Context, Priority]
- **On-Hold Tasks** (Y):
  - [Task 1] - [Reason for hold]
- **Completed Tasks** (Z):
  - [Recent completion 1]
  - [Recent completion 2]

### Next Actions
1. **[Priority 1]**: [Specific next action]
2. **[Priority 2]**: [Specific next action]
3. **[Priority 3]**: [Specific next action]

### Blockers & Issues
- [Blocker 1]: [Impact and potential resolution]
- [Blocker 2]: [Impact and potential resolution]

### Decisions Needed
- [Decision 1]: [Context and options]
- [Decision 2]: [Context and options]

### Health Assessment
- **Overall**: 🟢 Green / 🟡 Yellow / 🔴 Red
- **Reason**: [Why this health status]
- **Recommendation**: [What should happen next]
```

### Project Health Check Template

Use this to assess project health:

```markdown
## Health Check: [Project Name]

### Clarity
- [ ] Purpose is clear
- [ ] Outcome is defined
- [ ] Success criteria are known

### Progress
- [ ] Has active tasks
- [ ] Tasks are being completed
- [ ] Progress is visible

### Next Actions
- [ ] Next action is clear
- [ ] Next action is actionable
- [ ] No blockers on next action

### System Health
- [ ] Project status is accurate
- [ ] Tasks are properly assigned
- [ ] Documentation is current

**Overall Health**: 🟢 / 🟡 / 🔴
```

---

## Best Practices

- **Regular Reviews**: Review projects weekly or monthly to maintain clarity
- **Focus on Active**: Prioritize reviewing active projects over on-hold/done
- **Health Indicators**: Use green/yellow/red to quickly identify projects needing attention
- **Next Actions First**: Always identify the next physical action for each project
- **Document Decisions**: Record important decisions and blockers in project notes
- **Batch Reviews**: Do project reviews in dedicated time blocks (not scattered throughout day)
- **Update System**: Keep project status current - outdated info breaks trust in system
- **Deep Dive Selectively**: Not every project needs deep dive - focus on what matters

---

## Integration with Other Skills

This skill works well with:
- **`weekly-review`**: Use project status review as part of weekly review
- **`daily-review`**: Quick project check during daily review
- **`project-kickoff`**: Review new projects after kickoff to ensure they're set up correctly
- **`task-prioritization`**: Use project importance to prioritize tasks

---

## Troubleshooting

### "Too many projects to review"

**Solutions:**
- Focus on active projects only: `list_projects(status="active")`
- Review in batches (e.g., 5 projects per session)
- Prioritize by importance or recency
- Use quick status template for most, deep dive for key ones

### "Projects seem unclear or stuck"

**Solutions:**
- Use deep dive template to clarify purpose
- Ask: "What would done look like?" for each unclear project
- Consider if project should be on-hold or archived
- Break large projects into smaller sub-projects

### "Can't identify next actions"

**Solutions:**
- Review active tasks: `get_project_status()` shows active tasks
- Look at project details: `get_project_details()` shows all tasks
- Consider if project needs to be broken down further
- Ask: "What's the next physical action I can take?"

### "Projects have no active tasks"

**Solutions:**
- Review if project is actually active or should be on-hold
- Identify what next action is needed
- Consider if project needs to be broken down into tasks
- Check if tasks are assigned to wrong project

---

## Success Criteria

A successful project status review means:
- ✓ You have visibility into all active projects
- ✓ You know the status and health of each project
- ✓ You've identified next actions for key projects
- ✓ Blockers and issues are documented
- ✓ Project status in system matches reality
- ✓ You have a plan for moving projects forward
- ✓ You feel clear and confident about project status

---

## Example Workflow

### Quick Weekly Review (15-30 minutes)

1. `list_projects(status="active")` - See all active projects
2. For each project: `get_project_status(project_name="...")` - Quick status
3. Use quick status template to note key info
4. Identify 2-3 projects needing attention
5. For those: `get_project_details(project_name="...")` - Deep dive
6. Create/update tasks for next actions
7. Update project status if needed

### Comprehensive Monthly Review (1-2 hours)

1. `list_projects(status="all")` - See all projects
2. For each active project:
   - `get_project_status()` - Status overview
   - `get_project_details()` - Deep dive
   - Use comprehensive status template
3. Review on-hold projects - should they be active or archived?
4. Review done projects - archive or remove
5. Update all project documentation
6. Create action plan for next month
