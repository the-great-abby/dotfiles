# How Agent Skills Work: Understanding the System

## The Concept

Agent Skills are **instructions for AI agents** - not scripts for humans. They tell an AI agent **how to use MCP tools** to accomplish a goal, rather than directly executing code.

## Two Ways Skills Work

### 1. **AI Agent Interprets Instructions** (Original Design)

When an AI agent (like Claude, ChatGPT, etc.) reads a skill:

```
Skill: "Morning Check-In"
Instructions: "Call read_recent_logs(days=3), then call get_inbox_count(), 
              then call suggest_tasks_from_text(...), then call create_task(...)"
```

**What the AI does:**
1. Reads the SKILL.md instructions
2. Understands the workflow steps
3. Calls the appropriate MCP tools in sequence
4. Interprets results and makes decisions
5. Executes the workflow using MCP tools

**Example Flow:**
```
User: "Do my morning check-in"
  ↓
AI: Reads morning-checkin/SKILL.md
  ↓
AI: Understands "Step 1: Call read_recent_logs(days=3)"
  ↓
AI: Calls MCP tool: read_recent_logs(days=3)
  ↓
AI: Gets response: "Recent logs: [entries...]"
  ↓
AI: Continues with Step 2: get_inbox_count()
  ↓
AI: Makes decisions based on results
  ↓
AI: Completes workflow using MCP tools
```

### 2. **Execute Scripts** (Implementation Shortcut)

We created `scripts/execute.sh` files that directly call existing bash commands:

```bash
# scripts/execute.sh
gtd-checkin "morning"  # Directly calls existing bash script
```

This is a **convenience** - it wraps existing workflows. But the **real power** of skills is when an AI agent interprets the instructions and executes them using MCP tools.

## How Skills Are Intended to Work

### Scenario: New Skill Without Existing Implementation

Imagine you create a new skill "Weekly Planning" that doesn't have a bash script:

**SKILL.md:**
```markdown
---
name: Weekly Planning
description: Plan your week using GTD principles
---

# Weekly Planning Workflow

## Step 1: Review Current Tasks
Call `list_tasks(status="active")` to see all active tasks.

## Step 2: Review Projects
Call `list_projects(status="active")` to see all projects.

## Step 3: Generate Priorities
For each project, call `get_project_status(project_name="...")` 
to understand what needs attention.

## Step 4: Create Weekly Plan
Based on the review:
- Use `create_task()` for high-priority items
- Use `update_task()` to adjust priorities
- Use `plan_with_ai()` for complex planning
```

**When an AI agent executes this:**
1. **Reads instructions** - Understands the workflow
2. **Calls MCP tools** - `list_tasks()`, `list_projects()`, `get_project_status()`
3. **Interprets results** - Analyzes the data
4. **Makes decisions** - Determines what needs planning
5. **Executes actions** - Calls `create_task()`, `update_task()`, `plan_with_ai()`
6. **Completes workflow** - Finishes all steps in sequence

**The AI agent is the executor** - it reads instructions and uses tools to accomplish the goal.

## Why This Matters

### Without Skills (Manual)
```
You: I need to plan my week
You: [Manually run commands]
You: gtd-task list
You: gtd-project list
You: [Decide what to do]
You: gtd-task add "Task 1"
You: [Repeat for each task]
```

### With Skills (AI-Powered)
```
You: "Do weekly planning"
AI: [Reads weekly-planning skill]
AI: [Calls list_tasks(), list_projects(), get_project_status()]
AI: [Analyzes results]
AI: [Creates tasks based on analysis]
AI: [Completes workflow automatically]
```

## The Two Approaches We Support

### Approach 1: Execute Scripts (Current Implementation)

**Pros:**
- ✅ Works immediately in wizard
- ✅ Uses existing bash scripts
- ✅ Fast and reliable

**Cons:**
- ❌ Requires script for each skill
- ❌ Not AI-interpretable
- ❌ Can't adapt to context

### Approach 2: AI Interpretation (Agent Skills Standard)

**Pros:**
- ✅ AI reads and executes instructions
- ✅ No script needed - just instructions
- ✅ Can adapt to context
- ✅ Can make intelligent decisions
- ✅ Works with any MCP-enabled agent

**Cons:**
- ❌ Requires MCP-enabled AI agent
- ❌ Slower (AI processing)
- ❌ Depends on AI understanding

## How It Works in Practice

### Example: Morning Check-In Skill

**What the skill says:**
```markdown
1. Call `read_recent_logs(days=3)` to see recent activity
2. Call `get_inbox_count()` to check inbox
3. If inbox > 0, use inbox-processing skill
4. Call `get_context_tasks(context="computer")` to see today's tasks
5. Call `suggest_tasks_from_text()` with log summary
6. Create high-priority tasks using `create_task()`
```

**When AI executes:**
```python
# AI reads skill instructions
skill = get_agent_skill("morning-checkin")
instructions = skill.instructions

# AI understands: "I need to do these steps"

# AI executes Step 1
result1 = execute_agent_skill(
    method="instructions"  # Just gets instructions
)
# OR directly calls MCP tools:
recent_logs = read_recent_logs(days=3)

# AI sees: "I got recent logs. Now Step 2."
inbox_count = get_inbox_count()

# AI sees: "Inbox has 5 items. Step 3 says if > 0, use inbox-processing."
if inbox_count > 0:
    execute_agent_skill("inbox-processing")

# AI continues through all steps...
```

**The AI agent orchestrates the workflow** using MCP tools, following the instructions.

## Current State: Hybrid Approach

We support **both** approaches:

1. **Execute Scripts**: For skills with `scripts/execute.sh`
   - Wizard runs script directly
   - Fast, reliable
   - Works without AI

2. **AI Interpretation**: For skills with only instructions
   - MCP-enabled AI reads instructions
   - AI calls MCP tools to execute workflow
   - Flexible, adaptive

## Using Skills with MCP-Enabled AI

When you use skills with an MCP-enabled AI agent (like in Cursor):

```python
# You ask AI:
"Do my morning check-in"

# AI response:
"I'll help with your morning check-in. Let me use the morning-checkin skill."

# AI executes:
execute_agent_skill(skill_name="morning-checkin", method="instructions")

# AI reads instructions and executes using MCP tools:
read_recent_logs(days=3)  # → Gets logs
get_inbox_count()         # → Gets count  
get_context_tasks(...)    # → Gets tasks
suggest_tasks_from_text(...)  # → Gets suggestions
create_task(...)          # → Creates tasks

# AI reports back:
"I've completed your morning check-in:
- Reviewed 3 days of logs
- Found 2 items in inbox (processed them)
- Identified 5 tasks for today
- Created 3 high-priority tasks
..."
```

## Creating Skills That Work

### For Wizard Use (Execute Script)
```bash
# scripts/execute.sh
# Directly calls existing bash commands
gtd-checkin "morning"
```

### For AI Interpretation (Instructions Only)
```markdown
# SKILL.md
## Step 1: Review Activity
Call `read_recent_logs(days=3)` to see recent activity.

## Step 2: Check Inbox  
Call `get_inbox_count()`. If > 0, process inbox.

## Step 3: Get Suggestions
Call `suggest_tasks_from_text()` with log summary.
```

The AI reads the markdown and executes using MCP tools.

## Best Practice: Include Both

**Ideal skill structure:**
```
skill/
├── SKILL.md           # Instructions for AI agents
└── scripts/
    └── execute.sh     # Script for wizard/humans
```

- **SKILL.md**: AI agents read and interpret
- **execute.sh**: Wizard/humans run directly

Both provide the same workflow, but:
- Scripts are faster and more reliable for known workflows
- Instructions are more flexible and AI-interpretable

## Summary

**Skills provide instructions, not code execution.**

- **With execute scripts**: Direct execution (fast, reliable)
- **With instructions only**: AI interprets and executes using MCP tools (flexible, adaptive)
- **With both**: Works everywhere (best of both worlds)

The **power of skills** is when an AI agent reads instructions and orchestrates MCP tools to accomplish goals, not when they just wrap existing scripts.
