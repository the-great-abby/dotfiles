# MCP Tools vs Agent Skills: When to Use Which

## Key Differences

### MCP Tools (Model Context Protocol)
**What they are:** Programmatic tools defined in code (Python functions) that provide direct capabilities to AI agents.

**Characteristics:**
- ✅ **Defined in code**: Written as Python functions with `@server.call_tool()` decorators
- ✅ **Powerful & flexible**: Can access databases, APIs, file systems, complex logic
- ✅ **Type-safe**: JSON schemas define inputs/outputs precisely
- ✅ **Real-time**: Direct function execution with immediate results
- ✅ **Integrated**: Directly part of the MCP server codebase
- ❌ **Requires code changes**: Adding new tools requires modifying Python code
- ❌ **Not portable**: Tied to this specific MCP server implementation
- ❌ **Developer-only**: Requires programming knowledge to create

**Examples from your system:**
- `suggest_tasks_from_text`: Calls AI models, processes responses, saves to disk
- `create_task`: Interacts with GTD file system, validates inputs
- `search_vector_database`: Queries vector DB, processes embeddings
- `perform_web_search`: Makes HTTP requests, processes results

### Agent Skills
**What they are:** File-based packages (folders with `SKILL.md`) that provide procedural knowledge and instructions to agents.

**Characteristics:**
- ✅ **File-based**: Just folders with markdown files (no code changes needed)
- ✅ **Portable**: Can be shared across different agent systems
- ✅ **Easy to create**: Non-developers can write skills
- ✅ **Version-controlled**: Easy to track changes, share, collaborate
- ✅ **Declarative**: Instructions tell agents HOW to do something
- ✅ **Composable**: Skills can use MCP tools to accomplish goals
- ❌ **Limited execution**: Scripts are simpler than full Python functions
- ❌ **Instructional**: Primarily guides agents on what to do with existing tools
- ❌ **Less powerful**: Can't directly access complex system internals

**Examples:**
- Skill: "How to conduct a weekly review using GTD tools"
- Skill: "Template for creating project documentation"
- Skill: "Workflow for processing email into tasks"

## When to Use MCP Tools

Use **MCP Tools** when you need:

1. **System Integration**
   - Accessing databases, APIs, or external services
   - Direct file system operations with validation
   - Complex data processing or transformation

2. **Real-time Operations**
   - Immediate results without human interpretation
   - Transactional operations (create, update, delete)
   - Operations requiring type safety and validation

3. **Core Capabilities**
   - Fundamental system features that are always available
   - Operations that other tools/skills depend on
   - Low-level primitives for the system

**Your current MCP tools are appropriate examples:**
- ✅ `suggest_tasks_from_text` - Core AI functionality
- ✅ `create_task` - Direct system operation
- ✅ `search_vector_database` - Database access
- ✅ `perform_web_search` - External API integration

## When to Use Agent Skills

Use **Agent Skills** when you need:

1. **Procedural Knowledge**
   - Step-by-step workflows ("How to do X")
   - Best practices and methodologies
   - Context-specific guidance

2. **Templates & Patterns**
   - Reusable document templates
   - Standard workflows that can vary
   - Common patterns for tasks

3. **User-Contributed Content**
   - Domain-specific expertise
   - Team-specific processes
   - Customizable workflows

4. **Composition of Existing Tools**
   - Using multiple MCP tools in a specific sequence
   - Workflows that combine several capabilities
   - Higher-level processes built on primitives

**Good skill examples for your system:**
- ✅ Skill: "Weekly Review Process" - Uses `weekly_review`, `get_pending_suggestions`, etc.
- ✅ Skill: "Project Kickoff Template" - Provides template for new projects
- ✅ Skill: "Daily Standup Preparation" - Workflow using various MCP tools
- ✅ Skill: "GTD Processing Workflow" - Steps for processing inbox items

## How They Work Together

**Skills USE MCP Tools** - This is the key relationship:

```
Agent Skill (SKILL.md)
  ↓ instructions
AI Agent
  ↓ calls
MCP Tools (Python functions)
  ↓ execute
System Operations
```

**Example:**

```markdown
# SKILL.md: Weekly Review Skill
---
name: Weekly Review Workflow
---

## When to Use
Use this skill at the end of each week to review progress.

## How It Works
1. Call `weekly_review()` to queue deep analysis
2. Call `get_pending_suggestions()` to review pending items
3. Use `create_task_from_suggestion()` to act on items
4. Use `search_vector_database()` to find related notes
```

The skill provides instructions, but the actual work is done by MCP tools.

## Should You Convert MCP Tools to Skills?

### ❌ **DON'T Convert** These MCP Tools to Skills:
- `suggest_tasks_from_text` - Core AI capability
- `create_task` - Direct system operation
- `search_vector_database` - Database access
- `perform_web_search` - External API
- Any tool that requires complex logic or system integration

**Why?** These are **primitives** - they're the building blocks that skills use.

### ✅ **DO Create Skills** For:
- "How to conduct a weekly review" (uses `weekly_review`, `get_pending_suggestions`, etc.)
- "Template for project planning" (provides structure, uses `create_task`)
- "Workflow for processing daily log" (combines `suggest_tasks_from_text` + `create_task`)
- "Best practices for task prioritization" (guidance using existing tools)

**Why?** These are **compositions** - they combine primitives into workflows.

## Recommended Architecture

```
┌─────────────────────────────────────┐
│         MCP Server Core             │
│  (Python code - gtd_mcp_server.py) │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   MCP Tools (Primitives)    │   │
│  │  - suggest_tasks_from_text  │   │
│  │  - create_task              │   │
│  │  - search_vector_database   │   │
│  │  - perform_web_search       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Skills Management Tools    │   │
│  │  - list_agent_skills        │   │
│  │  - execute_agent_skill      │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│      Agent Skills (File-based)      │
│      (mcp/skills/*/SKILL.md)        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Skill: Weekly Review       │   │
│  │  (Uses MCP tools above)     │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │  Skill: Project Template    │   │
│  │  (Provides templates)       │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Decision Tree

```
Need a new capability?
│
├─ Does it require:
│  ├─ Database/API access? → MCP Tool
│  ├─ Complex logic/validation? → MCP Tool
│  ├─ Direct system operations? → MCP Tool
│  │
│  └─ Or is it:
│     ├─ A workflow/process? → Skill
│     ├─ Instructions/guidance? → Skill
│     ├─ A template/pattern? → Skill
│     └─ Composition of existing tools? → Skill
```

## Summary

- **MCP Tools** = **Building blocks** (what the system CAN do)
- **Agent Skills** = **Instructions & workflows** (HOW to use the building blocks)

**Keep your MCP tools as tools. Create skills that use those tools to provide higher-level capabilities.**

Your current architecture is correct - you have MCP tools for core operations, and now you have skills for procedural knowledge that can use those tools.
