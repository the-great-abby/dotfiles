---
name: Project Kickoff
description: Guide through project initialization workflow. Standardizes project creation with outcome definition, initial tasks, documentation setup, and kickoff checklist. Ensures projects start with clear structure and next actions.
version: 1.0.0
tags:
  - project
  - planning
  - kickoff
  - gtd
  - productivity
author: GTD System
---

# Project Kickoff Workflow

A comprehensive skill for guiding through project initialization, ensuring projects start with clear outcomes, structure, and next actions. Standardizes project creation and sets projects up for success.

## When to Use

Use this skill when:
- **Starting a new project**: You have an idea and want to formalize it
- **Converting idea to project**: Moving from someday/maybe to active project
- **Standardizing project setup**: Ensuring all projects follow best practices
- **Defining project structure**: Setting up documentation and initial tasks
- **Running kickoff checklist**: Going through formal project kickoff process

## How It Works

This workflow guides through project creation, outcome definition, initial task setup, documentation, and kickoff checklist. Follow these steps in order:

### Step 1: Define Project Basics

**Purpose:** Establish the foundation of the project.

**Actions:**
1. Determine project name
2. Define project outcome (what "done" looks like)
3. Optionally link to a goal (if you maintain goals)
4. Optionally link to a repository (if code-related)

**Questions to answer:**
- What is this project called?
- What does "done" look like? (Clear outcome definition)
- Does this relate to a goal?
- Is there a code repository?

**MCP Tools:**
- `create_project(name="...", description="...", repository="...")` - Create project
- Goal tracking tools (if available)

**Outcome definition examples:**
- "A fully redesigned website launched with new branding"
- "CKA exam passed with score above 80%"
- "Wedding planned and executed successfully"
- "Kubernetes learning module completed with all exercises"

---

### Step 2: Create Project Structure

**Purpose:** Set up the project directory and initial files.

**Actions:**
1. Project is created via `create_project()` which:
   - Creates project directory
   - Creates README.md with frontmatter
   - Sets up basic structure
2. Verify project was created successfully
3. Check project directory structure

**MCP Tools:**
- `create_project(name="...", description="...", repository="...")` - Creates structure
- `get_project_details(project_name="...")` - Verify creation

**Project structure created:**
- Project directory: `~/Documents/gtd/1-projects/<project-name>/`
- README.md with frontmatter (type, status, outcome, etc.)
- Ready for tasks and notes

---

### Step 3: Define Goals and Success Criteria

**Purpose:** Clarify what success looks like for this project.

**Actions:**
1. Define main goals (what you want to achieve)
2. Define success criteria (how you'll measure success)
3. Document in project README or kickoff checklist

**Questions to answer:**
- What are the main goals of this project?
- How will you measure success?
- What does "done" look like?
- What are the key milestones?

**Documentation:**
- Add to project README
- Or use `gtd-project kickoff <name>` to run kickoff checklist

**Commands:**
- `gtd-project kickoff <project-name>` - Runs interactive kickoff checklist
- Or manually edit project README

---

### Step 4: Identify Stakeholders

**Purpose:** Know who is involved and who needs to be informed.

**Actions:**
1. List key stakeholders (people involved or affected)
2. Identify decision-makers
3. Identify people who need updates
4. Document in kickoff checklist

**Questions to answer:**
- Who are the key stakeholders?
- Who makes decisions?
- Who needs to be kept informed?
- Who is responsible for what?

**Commands:**
- `gtd-project kickoff <project-name>` - Includes stakeholder identification
- Or manually document in project notes

---

### Step 5: Set Timeline and Milestones

**Purpose:** Establish timeline and key milestones.

**Actions:**
1. Set target completion date
2. Identify key milestones
3. Break project into phases if needed
4. Document timeline in project

**Questions to answer:**
- What's the target completion date?
- What are the key milestones?
- What are the phases of this project?
- Are there any dependencies or deadlines?

**Commands:**
- `gtd-project kickoff <project-name>` - Includes timeline setup
- Or manually document in project README

**Timeline considerations:**
- Be realistic about timelines
- Consider dependencies
- Account for other commitments
- Build in buffer time

---

### Step 6: Create Initial Tasks

**Purpose:** Define the first actions needed to move the project forward.

**Actions:**
1. Identify the first 3-5 tasks needed
2. For each task:
   - Use `create_task(title="...", project="...", priority="...")` to create
   - Set appropriate priority
   - Set appropriate context
   - Add any relevant notes
3. Ensure at least one task is actionable immediately

**MCP Tools:**
- `create_task(title="...", project="...", priority="...", context="...", notes="...")` - Create tasks
- `list_tasks(project="...")` - Verify tasks created

**Task creation best practices:**
- Start with next actions (what can be done now)
- Make tasks specific and actionable
- Set appropriate priorities
- Consider context (where/when can this be done)
- Add notes for context if needed

**Questions to ask:**
- What's the very first thing that needs to happen?
- What are the immediate next actions?
- What can be done right now?
- What needs to happen to get started?

---

### Step 7: Set Up Project Documentation

**Purpose:** Create initial project documentation and structure.

**Actions:**
1. Review project README created by `create_project()`
2. Add additional documentation as needed:
   - Project goals and outcomes
   - Timeline and milestones
   - Stakeholders
   - Resources and references
   - Notes and ideas
3. Consider creating project notes in Second Brain:
   - Link project to Second Brain note
   - Create project documentation note

**Commands:**
- `gtd-project view <name>` - View project README
- `gtd-brain-sync projects` - Sync to Second Brain
- `gtd-brain create "<Project Name>" Projects` - Create Second Brain note
- `gtd-brain link <gtd-project> <second-brain-note>` - Link them

**Documentation to include:**
- Project outcome (what "done" looks like)
- Goals and success criteria
- Timeline and milestones
- Stakeholders
- Resources and references
- Initial tasks and next actions

---

### Step 8: Run Kickoff Checklist

**Purpose:** Go through formal kickoff checklist to ensure nothing is missed.

**Actions:**
1. Run the kickoff checklist:
   ```bash
   gtd-project kickoff <project-name>
   ```
2. Answer the interactive prompts:
   - Goals and success criteria
   - Stakeholders
   - Timeline and milestones
   - Initial tasks
   - Tracking method
3. Review the generated kickoff checklist file
4. Ensure all items are addressed

**Commands:**
- `gtd-project kickoff <project-name>` - Runs interactive checklist
- Creates `kickoff-checklist.md` in project directory

**Checklist covers:**
- Goals and success criteria
- Stakeholders
- Timeline and milestones
- Initial tasks
- Tracking method

---

### Step 9: Link to Second Brain (Optional)

**Purpose:** Connect project to Second Brain for knowledge management.

**Actions:**
1. Sync project to Second Brain:
   ```bash
   gtd-brain-sync projects
   ```
2. Or manually create Second Brain note:
   ```bash
   gtd-brain create "<Project Name>" Projects
   ```
3. Link GTD project to Second Brain note:
   ```bash
   gtd-brain link <gtd-project-path> <second-brain-note-path>
   ```

**Commands:**
- `gtd-brain-sync projects` - Auto-sync all projects
- `gtd-brain create "<Name>" Projects` - Create Second Brain note
- `gtd-brain link <path1> <path2>` - Link GTD to Second Brain

**Benefits:**
- Project documentation in Second Brain
- Can link to related notes
- Can create project MOC
- Better knowledge organization

---

### Step 10: Review and Verify

**Purpose:** Ensure project is set up correctly and ready to go.

**Actions:**
1. Call `get_project_details(project_name="...")` to verify project
2. Call `get_project_status(project_name="...")` to check status
3. Call `list_tasks(project="...")` to verify tasks
4. Review project README
5. Ensure next actions are clear

**MCP Tools:**
- `get_project_details(project_name="...")` - Get full project info
- `get_project_status(project_name="...")` - Get project status
- `list_tasks(project="...")` - List project tasks

**What to verify:**
- Project exists and has correct structure
- Outcome is clearly defined
- Initial tasks are created
- Next actions are clear
- Documentation is in place

---

## Detailed Workflow Examples

### Example 1: Simple Project Kickoff

**Scenario:** Starting a new learning project.

**Steps:**
1. **Define basics:**
   - Name: "Learn Kubernetes"
   - Outcome: "Complete Kubernetes fundamentals course and pass practice exam"
2. **Create project:**
   ```python
   create_project(name="Learn Kubernetes", description="Learn Kubernetes fundamentals")
   ```
3. **Create initial tasks:**
   ```python
   create_task(title="Research Kubernetes courses", project="Learn Kubernetes", priority="not_urgent_important")
   create_task(title="Set up local Kubernetes cluster", project="Learn Kubernetes", priority="not_urgent_important")
   create_task(title="Complete first module", project="Learn Kubernetes", priority="not_urgent_important")
   ```
4. **Run kickoff:**
   ```bash
   gtd-project kickoff learn-kubernetes
   ```
5. **Link to Second Brain:**
   ```bash
   gtd-brain-sync projects
   ```

### Example 2: Complex Project Kickoff

**Scenario:** Starting a major project with multiple stakeholders.

**Steps:**
1. **Define basics:**
   - Name: "Website Redesign"
   - Outcome: "Fully redesigned website launched with new branding, improved UX, and mobile responsiveness"
   - Repository: "https://github.com/org/website"
2. **Create project:**
   ```python
   create_project(name="Website Redesign", description="Complete website redesign", repository="https://github.com/org/website")
   ```
3. **Run kickoff checklist:**
   ```bash
   gtd-project kickoff website-redesign
   ```
   - Define goals: "Improve UX, modernize design, mobile-first"
   - Identify stakeholders: "Design team, dev team, marketing"
   - Set timeline: "3 months, milestones: design, development, launch"
   - Create initial tasks: "Research competitors, create design brief, set up dev environment"
4. **Create detailed tasks:**
   ```python
   create_task(title="Research competitor websites", project="Website Redesign", priority="urgent_important")
   create_task(title="Create design brief", project="Website Redesign", priority="urgent_important")
   create_task(title="Set up development environment", project="Website Redesign", priority="not_urgent_important")
   ```
5. **Link to Second Brain:**
   ```bash
   gtd-brain create "Website Redesign" Projects
   gtd-brain link ~/Documents/gtd/1-projects/website-redesign/README.md ~/Documents/obsidian/Second\ Brain/Projects/website-redesign.md
   ```

---

## Best Practices

### Outcome Definition

**Good outcomes:**
- ✅ Specific and measurable
- ✅ Clear completion criteria
- ✅ Time-bound (when possible)
- ✅ Achievable

**Poor outcomes:**
- ❌ Vague: "Make website better"
- ❌ Unclear: "Learn stuff"
- ❌ Too broad: "Be successful"

**Example transformation:**
- Poor: "Learn Kubernetes"
- Good: "Complete Kubernetes fundamentals course, pass practice exam, deploy sample application"

### Initial Tasks

**Create tasks that:**
- ✅ Are immediately actionable
- ✅ Are specific and clear
- ✅ Move the project forward
- ✅ Have appropriate priority
- ✅ Match your context and energy

**Avoid:**
- ❌ Vague tasks: "Work on project"
- ❌ Tasks that depend on other tasks (unless you create the dependency)
- ❌ Too many tasks at once (start with 3-5)

### Project Structure

**Ensure project has:**
- ✅ Clear outcome definition
- ✅ Initial tasks with next actions
- ✅ Documentation (README, notes)
- ✅ Timeline or milestones
- ✅ Links to related items (goals, Second Brain, etc.)

### Kickoff Checklist

**Use kickoff checklist to:**
- ✅ Ensure nothing is missed
- ✅ Standardize project setup
- ✅ Document project basics
- ✅ Set up tracking method

---

## Integration with Other Skills

This skill works well with:
- **`project-status-review`**: Review project after kickoff
- **`weekly-review`**: Include new projects in weekly review
- **`task-prioritization`**: For guidance on setting task priorities
- **`inbox-processing`**: Process project ideas from inbox
- **`diagram-generation`**: Create project workflow diagrams

---

## Troubleshooting

### "I don't know what the outcome should be"

**Solutions:**
- Ask: "What does 'done' look like?"
- Think about the end state
- Consider what success means
- You can refine the outcome later

### "I don't know what tasks to create"

**Solutions:**
- Start with research tasks
- Ask: "What's the very first thing I need to do?"
- Create tasks as you think of them
- You can add more tasks later

### "Project seems too big"

**Solutions:**
- Break into phases or sub-projects
- Focus on first phase initially
- Create milestones to track progress
- Start with small, achievable tasks

### "I'm not sure if this should be a project"

**Solutions:**
- Projects have outcomes (something to complete)
- Single actions are tasks, not projects
- Ongoing responsibilities are areas
- If unsure, start as a project and adjust later

---

## Success Criteria

A successful project kickoff means:
- ✓ Project created with clear outcome
- ✓ Initial tasks created (3-5 tasks)
- ✓ Next actions are clear
- ✓ Project documentation in place
- ✓ Kickoff checklist completed (if used)
- ✓ Project linked to Second Brain (if desired)
- ✓ Project ready to start work

---

## Commands Reference

### Project Creation
```bash
# Create project
gtd-project create "Project Name" --outcome "What done looks like"

# Or use MCP tool
create_project(name="Project Name", description="...", repository="...")
```

### Kickoff Checklist
```bash
gtd-project kickoff <project-name>
```

### Task Creation
```bash
# Via MCP tool
create_task(title="...", project="...", priority="...", context="...")
```

### Project Management
```bash
gtd-project view <name>        # View project
gtd-project status <name>       # Check status
gtd-project list                # List all projects
```

### Second Brain Integration
```bash
gtd-brain-sync projects         # Sync all projects
gtd-brain create "<Name>" Projects  # Create Second Brain note
gtd-brain link <path1> <path2>  # Link GTD to Second Brain
```

---

## Workflow Summary

```
Project Kickoff Workflow
│
├─ 1. Define Project Basics
│   ├─ Project name
│   ├─ Outcome definition
│   └─ Optional: goal, repository
│
├─ 2. Create Project Structure
│   └─ create_project() creates directory and README
│
├─ 3. Define Goals and Success Criteria
│   └─ Document in README or kickoff checklist
│
├─ 4. Identify Stakeholders
│   └─ Document who's involved
│
├─ 5. Set Timeline and Milestones
│   └─ Define target date and key milestones
│
├─ 6. Create Initial Tasks
│   └─ create_task() for first 3-5 actions
│
├─ 7. Set Up Project Documentation
│   └─ Enhance README, create notes
│
├─ 8. Run Kickoff Checklist
│   └─ gtd-project kickoff <name>
│
├─ 9. Link to Second Brain (Optional)
│   └─ gtd-brain-sync or manual linking
│
└─ 10. Review and Verify
    ├─ get_project_details()
    ├─ get_project_status()
    └─ list_tasks(project="...")
```

---

Remember: A good project kickoff sets the project up for success. Take time to define the outcome clearly, create actionable initial tasks, and set up good documentation. This investment pays off throughout the project lifecycle.
