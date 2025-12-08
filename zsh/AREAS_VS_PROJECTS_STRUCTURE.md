# Areas vs Projects: Understanding the Structure

## 🎯 Quick Answer

**Areas** can have:
- ✅ **Tasks** (via `gtd-area add-task`)
- ✅ **Projects** (via `gtd-area add-project`)
- ✅ **Notes section** (exists in template, but no command yet to add notes)

**Projects** can have:
- ✅ **Tasks** (multiple tasks per project)
- ✅ **Notes** (in a `notes/` subdirectory)
- ✅ **Area assignment** (projects belong to an area)

## 📋 The Hierarchical Structure

```
Areas (Ongoing responsibilities)
│
├── Projects (Time-bound with outcomes)
│   ├── Tasks (Actionable items)
│   └── Notes (Project-specific documentation)
│
└── Tasks (Standalone tasks in the area)
    └── Notes (Task-specific notes)
```

## 🔍 Key Differences

### Areas of Responsibility
- **Purpose**: Ongoing maintenance areas that never "complete"
- **Examples**: Health & Wellness, Finances, Relationships, Home & Living Space
- **Characteristics**:
  - No end date
  - Require regular attention
  - Focus on standards and maintenance
  - Can contain multiple projects and standalone tasks

### Projects
- **Purpose**: Time-bound initiatives with specific outcomes
- **Examples**: "Complete Kubernetes certification", "Redesign website", "Plan wedding"
- **Characteristics**:
  - Has a clear outcome/goal
  - Has a completion date
  - Can belong to an area (optional)
  - Contains multiple tasks and notes

## 📁 Current Structure in Your System

### Area File Structure
When you create an area, it includes:

```markdown
---
type: area
status: active
area: area-name
---

# Area Name

## Description
[Your description]

## Goals
[Long-term goals for this area]

## Current Focus
[What you're focusing on right now]

## Projects in this Area
[Links to projects - auto-populated when you add projects]

## Tasks in this Area
[Links to tasks - auto-populated when you add tasks]

## Notes
[Notes section - currently manual, no command to add yet]
```

### Project File Structure
When you create a project, it includes:

```markdown
---
type: project
status: active
project: project-name
area: area-name (optional)
---

# Project Name

## Description
[Project description]

## Goals
[Project goals]

## Next Actions
[Actionable next steps]

## Tasks
[Links to tasks in the project]
```

Plus a `notes/` subdirectory for project-specific notes.

## 🔗 What Can Be Attached

### To Areas:

1. **Tasks** ✅
   ```bash
   gtd-area add-task "health-&-wellness" "Exercise daily"
   ```
   - Creates a standalone task assigned to the area
   - Tasks show up in area view

2. **Projects** ✅
   ```bash
   gtd-area add-project "health-&-wellness" "Fitness Program"
   ```
   - Creates or assigns a project to the area
   - Projects show up in area view

3. **Notes** ⚠️ (Partially)
   - There's a "## Notes" section in the area template
   - **BUT**: There's currently no command to add notes to areas
   - You can manually edit the area file to add notes
   - Notes can be added to the Notes section manually

### To Projects:

1. **Tasks** ✅
   ```bash
   gtd-task create "Task description" --project="project-name"
   ```
   - Multiple tasks per project
   - Tasks are tracked in the project

2. **Notes** ✅
   - Projects have a `notes/` subdirectory
   - You can create note files there
   - Notes are project-specific documentation

3. **Area Assignment** ✅
   - Projects can belong to an area
   - Assigned when creating a project or via `gtd-area add-project`

## 💡 Practical Examples

### Example 1: Health & Wellness Area

**Area**: Health & Wellness

**Contains**:
- **Projects**:
  - "Complete Couch to 5K" (3-month project)
  - "Improve Sleep Hygiene" (2-month project)
- **Standalone Tasks**:
  - "Take vitamins daily"
  - "Schedule annual checkup"
  - "Track water intake"
- **Notes**:
  - "Medication schedule"
  - "Exercise routine notes"
  - "Health metrics tracking"

### Example 2: Personal Development Area

**Area**: Personal Development

**Contains**:
- **Projects**:
  - "Complete Kubernetes Certification" (time-bound)
  - "Read 12 books this year" (time-bound)
- **Standalone Tasks**:
  - "Daily reading habit"
  - "Weekly reflection"
- **Notes**:
  - "Learning resources"
  - "Skill development plan"

## 🤔 When to Use What?

### Use an Area when:
- It's an ongoing responsibility
- It requires regular maintenance
- It doesn't have a specific end date
- Examples: Health, Finances, Relationships, Home Maintenance

### Use a Project when:
- It has a clear outcome/goal
- It has a completion date
- It requires multiple steps/tasks
- Examples: "Complete certification", "Plan wedding", "Redesign website"

### Use a Task when:
- It's a single actionable item
- It can be done in one sitting or workflow
- It belongs to a project or area
- Examples: "Call dentist", "Update resume", "Review budget"

### Use Notes when:
- You need to document information
- You want to capture thoughts/ideas
- You need reference material
- Currently: Projects have notes/, Areas have Notes section (manual)

## 🔧 What's Missing?

Currently, areas have a Notes section but **no command to add notes to areas**. You can:

1. **Manually edit** the area file and add notes to the Notes section
2. **Use Second Brain** integration - areas sync to Second Brain where you can add notes
3. **Use the Notes section** in the area template directly

Would you like me to add a command like `gtd-area add-note` to make it easier to attach notes to areas?

## 🔄 Integration with Second Brain

Areas automatically sync to Second Brain:

```bash
gtd-brain-sync areas
```

This creates corresponding notes in `Second Brain/Areas/` where you can:
- Add more detailed notes
- Link to resources
- Use progressive summarization
- Build knowledge over time

The GTD area file and Second Brain area note stay linked bidirectionally.

## 📚 Summary

**Areas can have:**
- ✅ Tasks (via command)
- ✅ Projects (via command)  
- ⚠️ Notes (manual editing or via Second Brain)

**Projects can have:**
- ✅ Tasks (via command)
- ✅ Notes (in notes/ subdirectory)
- ✅ Area assignment (optional)

The key difference: **Areas are ongoing, Projects are time-bound with outcomes.**

