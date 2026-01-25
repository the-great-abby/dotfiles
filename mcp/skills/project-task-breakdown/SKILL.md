---
name: Project Task Breakdown
description: Automatically break down projects into actionable tasks with proper sequencing, dependencies, and GTD contexts. Creates complete task hierarchies without asking permission.
version: 1.0.0
type: runbook  
tags:
  - runbook
  - project-management
  - task-creation
  - automatic
  - gtd
  - breakdown
author: GTD System
---

# Project Task Breakdown Runbook

A proactive runbook that automatically takes any project and breaks it down into a complete set of actionable tasks with proper sequencing, contexts, and priorities. **Creates tasks immediately** without asking for permission.

## Purpose

This runbook transforms high-level project ideas into complete, actionable task sets:
- Automatically analyzes project scope and creates comprehensive task breakdown
- Assigns appropriate GTD contexts, priorities, and dependencies  
- Creates logical task sequences and milestones
- Sets up project structure with next actions clearly identified
- **No permission asking - immediately creates the full task structure**

## Prerequisites

- Project name or description provided
- Access to GTD task and project creation tools
- Understanding of GTD contexts and methodology

## Runbook Steps

### Step 1: Analyze Project Scope

**Action:** Break down the project into major phases and work streams.

**Project Analysis Framework:**
1. **Planning Phase** - Research, requirements, design
2. **Preparation Phase** - Setup, resources, prerequisites  
3. **Execution Phase** - Main work, implementation, delivery
4. **Completion Phase** - Testing, review, documentation, handoff

**Automatic Phase Detection:**
```
IF project involves "website" or "app" → Add design, development, testing phases
IF project involves "event" → Add planning, promotion, execution, cleanup phases  
IF project involves "research" → Add discovery, analysis, synthesis, reporting phases
IF project involves "process" → Add design, pilot, rollout, optimization phases
```

**Next Step:** Create project structure automatically.

---

### Step 2: Create Project and Initial Structure

**Action:** Use `gtd_create_project()` to create the main project and initial framework.

**Project Creation:**
```python
# Create main project
project = gtd_create_project(
    name=f"[PROJECT_NAME]",
    description="Auto-generated project breakdown",
    status="active",
    priority="medium"  # Will be adjusted based on urgency indicators
)

# Create phase subprojects if complex
for phase in identified_phases:
    gtd_create_project(
        name=f"[PROJECT_NAME] - {phase}",
        parent_project=project['id'],
        description=f"{phase} phase of {project_name}"
    )
```

**Next Step:** Generate task breakdown automatically.

---

### Step 3: Auto-Generate Task Breakdown

**Action:** Create comprehensive task list based on project type and phases.

**Task Generation Rules by Project Type:**

**For "Website/App Projects":**
```python
tasks = [
    {"title": "Define requirements and scope", "context": "@think", "priority": "high"},
    {"title": "Research competitor solutions", "context": "@research", "priority": "medium"},
    {"title": "Create wireframes/mockups", "context": "@design", "priority": "high"},
    {"title": "Set up development environment", "context": "@computer", "priority": "medium"},
    {"title": "Implement core functionality", "context": "@code", "priority": "high"},
    {"title": "Create test cases", "context": "@computer", "priority": "medium"},
    {"title": "Conduct user testing", "context": "@agenda", "priority": "high"},
    {"title": "Deploy to production", "context": "@computer", "priority": "high"},
    {"title": "Create documentation", "context": "@write", "priority": "medium"},
    {"title": "Set up monitoring", "context": "@computer", "priority": "low"}
]
```

**For "Event Projects":**
```python
tasks = [
    {"title": "Define event goals and success metrics", "context": "@think", "priority": "high"},
    {"title": "Research and book venue", "context": "@calls", "priority": "high"},
    {"title": "Create guest list and invitations", "context": "@computer", "priority": "medium"},
    {"title": "Plan catering and logistics", "context": "@calls", "priority": "medium"},
    {"title": "Create promotional materials", "context": "@design", "priority": "medium"},
    {"title": "Send invitations", "context": "@email", "priority": "high"},
    {"title": "Coordinate day-of logistics", "context": "@agenda", "priority": "high"},
    {"title": "Execute event", "context": "@action", "priority": "high"},
    {"title": "Follow up with attendees", "context": "@email", "priority": "medium"},
    {"title": "Conduct post-event review", "context": "@think", "priority": "low"}
]
```

**For "Research Projects":**
```python
tasks = [
    {"title": "Define research questions", "context": "@think", "priority": "high"},
    {"title": "Identify key sources and databases", "context": "@research", "priority": "high"},
    {"title": "Create research methodology", "context": "@write", "priority": "medium"},
    {"title": "Conduct literature review", "context": "@read", "priority": "medium"},
    {"title": "Gather primary data", "context": "@research", "priority": "high"},
    {"title": "Analyze findings", "context": "@computer", "priority": "high"},
    {"title": "Create visual representations", "context": "@design", "priority": "medium"},
    {"title": "Write research report", "context": "@write", "priority": "high"},
    {"title": "Present findings to stakeholders", "context": "@agenda", "priority": "medium"},
    {"title": "Archive research materials", "context": "@computer", "priority": "low"}
]
```

**Next Step:** Create all tasks with dependencies.

---

### Step 4: Create Tasks with Smart Sequencing

**Action:** Use `gtd_create_task()` for each identified task with proper sequencing.

**Task Creation with Dependencies:**
```python
previous_task_id = None
for index, task_info in enumerate(generated_tasks):
    task = gtd_create_task(
        title=task_info['title'],
        project=project['id'],
        context=task_info['context'],
        priority=task_info['priority'],
        notes=f"Auto-generated task {index+1} of {len(generated_tasks)} for project: {project_name}",
        depends_on=previous_task_id if index > 0 else None
    )
    
    # First task becomes "next action"
    if index == 0:
        task['status'] = 'next_action'
        
    previous_task_id = task['id']
```

**Smart Sequencing Rules:**
- First task always marked as "next action"
- Logical dependencies created (design before development, etc.)
- Parallel tasks identified and marked appropriately
- Critical path tasks get high priority

**Next Step:** Set up project milestones.

---

### Step 5: Create Milestones and Reviews

**Action:** Automatically create milestone tasks and review checkpoints.

**Milestone Creation:**
```python
milestone_points = [0.25, 0.5, 0.75, 1.0]  # 25%, 50%, 75%, 100%
total_tasks = len(generated_tasks)

for percentage in milestone_points:
    milestone_index = int(total_tasks * percentage) - 1
    milestone_name = f"{project_name} - {int(percentage*100)}% Milestone Review"
    
    gtd_create_task(
        title=milestone_name,
        project=project['id'],
        context="@review",
        priority="medium",
        notes=f"Review project progress and adjust plan if needed. Target: {int(percentage*100)}% complete"
    )
```

**Review Tasks Created:**
- 25% Review - Early progress check
- 50% Review - Mid-project assessment  
- 75% Review - Pre-completion verification
- 100% Review - Project retrospective and closure

**Next Step:** Update project with next actions.

---

### Step 6: Set Initial Next Actions

**Action:** Identify and mark immediate next actions for project momentum.

**Next Action Logic:**
```python
# Find tasks without dependencies
next_actions = [task for task in created_tasks if not task.get('depends_on')]

# Mark up to 3 tasks as next actions (GTD best practice)
for task in next_actions[:3]:
    update_task_status(task['id'], status='next_action')
    
# If only 1 next action, check if any others can be parallel
if len(next_actions) == 1:
    parallel_tasks = identify_parallel_tasks(created_tasks)
    for task in parallel_tasks[:2]:  # Add up to 2 more
        update_task_status(task['id'], status='next_action')
```

**Next Step:** Create project summary and completion report.

---

### Step 7: Generate Project Breakdown Summary

**Action:** Provide comprehensive summary of created project structure.

**Summary Format:**
```
🚀 **Project Breakdown Complete: [PROJECT_NAME]**

📊 **Project Structure Created:**
- Main Project: [project_id]
- Total Tasks: {task_count}
- Phases: {phase_count}
- Milestones: {milestone_count}

🎯 **Next Actions (Ready to Start):**
1. [next_action_1] ({context})
2. [next_action_2] ({context})  
3. [next_action_3] ({context})

📋 **Task Breakdown by Phase:**

**Planning Phase:**
- [task] ({context}, {priority})
- [task] ({context}, {priority})

**Execution Phase:**  
- [task] ({context}, {priority})
- [task] ({context}, {priority})

**Completion Phase:**
- [task] ({context}, {priority})

⏰ **Milestones:**
- 25% Review - After task #{n}
- 50% Review - After task #{n}  
- 75% Review - After task #{n}
- Project Complete - All tasks done

💡 **Project is now ready for execution! Next actions are identified and ready to work on.**
```

**Next Step:** Complete runbook.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Complete project created in GTD system
2. ✅ All tasks generated with proper contexts and priorities
3. ✅ Task dependencies and sequencing established
4. ✅ Next actions clearly identified
5. ✅ Milestone reviews scheduled
6. ✅ Project ready for immediate execution

**Success Criteria:**
- Project fully broken down without user input required
- All tasks actionable with clear contexts
- Logical sequence and dependencies established
- Next actions immediately available for work

## Project Type Detection

**Automatic Detection Patterns:**
```python
project_patterns = {
    'website': ['site', 'web', 'app', 'interface', 'UI', 'frontend'],
    'event': ['party', 'meeting', 'conference', 'workshop', 'ceremony'],
    'research': ['study', 'analyze', 'investigate', 'research', 'report'],
    'process': ['workflow', 'procedure', 'system', 'process', 'method'],
    'learning': ['learn', 'study', 'course', 'skill', 'training'],
    'creative': ['write', 'design', 'create', 'art', 'content'],
    'business': ['launch', 'product', 'marketing', 'sales', 'strategy']
}
```

## Context Assignment Intelligence

**Smart Context Detection:**
- Communication tasks → @calls, @email, @agenda
- Technical work → @computer, @code, @design
- Thinking work → @think, @review, @plan  
- Physical tasks → @errands, @office, @home
- Research tasks → @research, @read, @online

## Priority Assignment Logic

**Automatic Priority Rules:**
- First tasks in sequence → High (removes blockers)
- Dependencies for high-priority tasks → High
- Milestone reviews → Medium
- Documentation tasks → Low (unless specified)
- Testing tasks → Medium-High
- Final delivery tasks → High

## Usage

**To use this runbook:**
1. "Break down project: [project description]"
2. "Create task structure for [project name]"
3. "Auto-generate project plan for [project idea]"

**Works with:**
- Simple project names: "Build personal website"
- Complex descriptions: "Launch new employee onboarding process with training materials and feedback system"
- Existing partial projects: "Complete the marketing campaign project"

## Examples

### Input: "Build personal website"
### Auto-Generated Output:

**Project Created:** "Build Personal Website" (#4567)

**Tasks Created (12 total):**
1. ✅ Define website goals and target audience (@think, high) - NEXT ACTION
2. Research personal website examples (@research, medium)  
3. Choose domain name and hosting (@computer, high)
4. Create site wireframes and layout (@design, high)
5. Write website content (@write, medium)
6. Set up development environment (@computer, medium)
7. Implement website design (@code, high)
8. Add content management system (@code, medium)
9. Test website functionality (@computer, high)
10. Deploy website to hosting (@computer, high)
11. Set up analytics and monitoring (@computer, low)
12. Create website maintenance plan (@think, low)

**Milestones:**
- 25% Review (after task 3)
- 50% Review (after task 6)  
- 75% Review (after task 9)
- Project Complete (after task 12)

This runbook eliminates the "What should I do first?" paralysis by providing immediate, actionable project structure with clear next steps.