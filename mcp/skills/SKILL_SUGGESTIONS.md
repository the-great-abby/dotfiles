# Agent Skills Suggestions for GTD System

Based on analysis of your existing workflows, here are Agent Skills that could replace or enhance current bash scripts. These skills use MCP tools to provide higher-level capabilities.

## How to Use This Guide

**When creating a new skill**, reference this guide to:

1. **Find inspiration**: Browse the suggested skills below to see what workflows could benefit from being skills
2. **Understand patterns**: See how existing workflows are structured and what MCP tools they use
3. **Follow best practices**: Learn from the examples of how skills should be designed
4. **Check implementation status**: See which skills are already implemented (✅) and which are still suggestions

**To create a skill:**
- Run `mcp/create-skill.sh` (or use the wizard's skill management menu)
- The creation helper will offer to show this guide before you start
- Use the suggestions below as templates for your skill's structure and workflow

**Each suggestion includes:**
- **What it replaces/enhances**: The existing workflow or capability
- **What it does**: The functionality and MCP tools used
- **Why it's better as a skill**: Benefits of the skill approach

## High-Priority Skills (Replace Existing Workflows)

### 1. Morning Review Runbook
**Replaces:** `gtd-morning`, `gtd-generate-checkin-suggestions` (morning)

**Runbook Name:** `interactive-morning-review-runbook` ✅ (Already implemented)

**What it does:**
- Guides through morning routine using MCP tools
- Uses `read_daily_log` to review recent entries
- Uses `suggest_tasks_from_text` to generate task suggestions
- Uses `get_context_tasks` to show today's focus
- Uses `create_task` to create prioritized tasks

**Why it's better as a skill:**
- Composable - can be customized per user
- Uses MCP tools instead of direct file access
- Instructions can be updated without code changes
- Can include AI guidance on best practices

---

### 2. Evening Check-In Workflow  
**Replaces:** `gtd-evening`

**Skill Name:** `evening-checkin`

**What it does:**
- Guides through evening wrap-up using MCP tools
- Uses `read_daily_log` to review today's entries
- Uses `list_tasks` to see what was accomplished
- Uses `complete_task` for task completion
- Suggests tomorrow's priorities using `suggest_tasks_from_text`

**Why it's better as a skill:**
- Provides reflection guidance
- Combines multiple MCP tools in a workflow
- Customizable for different evening routines

---

### 3. Daily Review Process
**Replaces:** `gtd-review daily`

**Skill Name:** `daily-review`

**What it does:**
- Guides through GTD daily review questions
- Uses `get_inbox_count` to check inbox status
- Uses `list_tasks` to review active tasks
- Uses `get_pending_suggestions` to review AI suggestions
- Uses `create_task` or `dismiss_suggestion` to act on items
- Uses `read_recent_logs` for context

**Why it's better as a skill:**
- Structured review process with guidance
- Uses MCP tools consistently
- Can be personalized per user

---

### 4. Weekly Review Process
**Replaces:** `gtd-review weekly`

**Skill Name:** `weekly-review`

**What it does:**
- Comprehensive weekly review workflow
- Uses `weekly_review` MCP tool for deep analysis
- Uses `list_projects` to review all projects
- Uses `get_project_status` for project details
- Uses `find_connections` to discover relationships
- Uses `generate_insights` for AI analysis
- Uses `list_areas` for area review

**Why it's better as a skill:**
- Provides structured questions and guidance
- Orchestrates multiple MCP tools
- Can include templates for review notes

---

### 5. Inbox Processing Workflow
**Replaces:** `gtd-process`

**Skill Name:** `inbox-processing`

**What it does:**
- Guides through GTD inbox processing (2-minute rule)
- Uses `get_inbox_count` to check inbox
- Uses `suggest_tasks_from_text` to analyze items
- Uses `create_task`, `create_project`, or `dismiss_suggestion` based on decisions
- Provides GTD methodology guidance

**Why it's better as a skill:**
- Instructional - teaches GTD methodology
- Uses MCP tools instead of direct file manipulation
- Can include templates for common patterns

---

### 6. Project Kickoff Template
**Replaces:** Custom project setup scripts

**Skill Name:** `project-kickoff`

**What it does:**
- Provides project initialization workflow
- Uses `create_project` MCP tool
- Uses `plan_with_ai` for project planning
- Uses `create_task` to set initial tasks
- Provides templates for project structure

**Why it's better as a skill:**
- Reusable templates
- Standardizes project creation
- Guides users through best practices

---

### 7. Task Processing from Daily Log
**Replaces:** Parts of `gtd-generate-checkin-suggestions`

**Skill Name:** `log-to-tasks`

**What it does:**
- Analyzes daily log entries for task opportunities
- Uses `read_recent_logs` to get log context
- Uses `suggest_tasks_from_text` with log entries
- Uses `create_task` to create actionable items
- Provides guidance on when to create tasks

**Why it's better as a skill:**
- Focused on single workflow
- Uses MCP tools properly
- Can be invoked from various contexts

---

## Medium-Priority Skills (Enhance Existing Workflows)

### 8. Context-Based Task Selection
**Enhances:** Task browsing workflows

**Skill Name:** `context-task-selection`

**What it does:**
- Helps select tasks based on current context
- Uses `get_context_tasks` to filter tasks
- Uses `list_tasks` with context filters
- Provides guidance on context switching

---

### 9. Project Status Review
**Enhances:** Project review workflows

**Skill Name:** `project-status-review`

**What it does:**
- Reviews project progress
- Uses `list_projects` to get all projects
- Uses `get_project_status` for details
- Uses `get_project_details` for deep dive
- Provides status templates

---

### 10. Habit Check-In Workflow
**Enhances:** Habit tracking

**Skill Name:** `habit-checkin`

**What it does:**
- Guides through daily habit check-in
- Uses habit-related MCP tools (if available)
- Provides habit tracking guidance
- Can integrate with task system

---

### 11. Deep Analysis Request
**Enhances:** Analysis workflows

**Skill Name:** `request-deep-analysis`

**What it does:**
- Guides on when to request deep analysis
- Uses `weekly_review`, `analyze_energy`, `find_connections`
- Explains when each analysis type is useful
- Provides templates for analysis requests

---

### 12. Task Prioritization Guidance
**New capability**

**Skill Name:** `task-prioritization`

**What it does:**
- Provides guidance on task prioritization
- Uses `list_tasks` to see all tasks
- Uses `get_context_tasks` for context-based filtering
- Provides GTD priority framework guidance

---

## Implementation Priority

### Phase 1: Core Workflows (Week 1)
1. ✅ `interactive-morning-review-runbook` - Interactive morning review (already implemented)
2. ✅ `evening-checkin` - Replace evening routine  
3. ✅ `daily-review` - Replace daily review script

### Phase 2: Processing Workflows (Week 2)
4. ✅ `inbox-processing` - Replace inbox processing
5. ✅ `log-to-tasks` - Replace checkin suggestion generation
6. ✅ `weekly-review` - Enhance weekly review

### Phase 3: Enhancement Skills (Week 3)
7. ✅ `project-kickoff` - Standardize project creation
8. ✅ `context-task-selection` - Improve task browsing
9. ✅ `task-prioritization` - Add prioritization guidance

---

## How Skills Would Work

### Example: Morning Check-In Skill

Instead of running `gtd-morning` which does:
1. Check status
2. Process inbox
3. Show tasks
4. Log entry

The skill would provide instructions like:

```markdown
# Morning Check-In Workflow

## Step 1: Review Recent Activity
Use `read_recent_logs(days=3)` to see what's been happening.

## Step 2: Check Inbox
Use `get_inbox_count()` to see if there are items to process.
If > 0, use `inbox-processing` skill to process.

## Step 3: Review Today's Focus
Use `get_context_tasks(context="computer")` to see tasks for your current context.

## Step 4: Generate Suggestions
Use `suggest_tasks_from_text(text="<yesterday's log summary>")` to get AI suggestions.

## Step 5: Create Priority Tasks
Use `create_task()` for high-priority items from suggestions.
```

The AI agent executing the skill would call these MCP tools in sequence, guided by the skill instructions.

---

## Benefits of Converting to Skills

1. **No Code Changes**: Update workflows by editing SKILL.md files
2. **Composable**: Combine skills in different ways
3. **Shareable**: Share workflows with others
4. **Version Controlled**: Track changes via git
5. **Instructional**: Skills teach best practices
6. **AI-Friendly**: Agents can understand and execute workflows
7. **Testable**: Can test workflows without modifying code

---

## Migration Strategy

### Option A: Gradual Migration
- Keep existing scripts
- Create skills that use MCP tools
- Gradually migrate users to skills
- Eventually deprecate scripts

### Option B: Wrapper Approach
- Create skills that call existing scripts via `execute_agent_skill(method="script:...")`
- Transition scripts to use MCP tools internally
- Eventually scripts become thin wrappers around skills

### Option C: Hybrid
- Keep high-frequency scripts (for speed)
- Convert complex workflows to skills (for flexibility)
- Scripts can call skills, skills use MCP tools

---

## Next Steps

Would you like me to:
1. **Create specific skill implementations** for any of these?
2. **Show example SKILL.md files** for the top priorities?
3. **Create a migration plan** for specific workflows?

Let me know which skills you'd like implemented first!
