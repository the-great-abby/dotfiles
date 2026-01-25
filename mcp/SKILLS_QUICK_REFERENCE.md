# Agent Skills Quick Reference

## What Are Skills?

**Agent Skills** are reusable workflows that guide AI agents (like Claude) on how to use GTD tools to accomplish goals. They're file-based (just folders with `SKILL.md`), making them easy to create, share, and version.

## How Skills Work with Claude

### Architecture
```
Claude API Call
    ↓
Tool Registry (gtd_tool_registry.py)
    ├─ GTD Tools (gtd_*)
    └─ Skill Tools (list/get/execute_agent_skill)
        ↓
Skills Registry (gtd_skills.py)
    ↓
Skills Directory (mcp/skills/)
    └─ SKILL.md files
```

### Claude's Workflow

1. **Discover**: `list_agent_skills(query="morning")`
2. **Read**: `get_agent_skill(skill_name="interactive-morning-review-runbook")`
3. **Follow**: Claude reads instructions and executes using GTD tools

## Available Skills

- **interactive-morning-review-runbook**: Complete morning routine workflow
- **inbox-processing**: Process inbox items using GTD methodology
- **daily-review**: Evening reflection and review workflow
- **task-summary**: Generate task summaries

## Using Skills

### From Claude (via claude-ask)

```bash
# Claude will discover and use skills automatically
claude-ask "Help me do my morning check-in"
```

### From MCP Server

```python
# List skills
list_agent_skills(query="morning")

# Get skill details
get_agent_skill(skill_name="interactive-morning-review-runbook")

# Execute skill
execute_agent_skill(skill_name="interactive-morning-review-runbook", method="instructions")
```

## Creating New Skills

1. Create folder: `mcp/skills/your-skill/`
2. Add `SKILL.md` with YAML frontmatter + instructions
3. Skills auto-discover on next MCP server start

See `mcp/AGENT_SKILLS.md` for full guide.

## Key Concepts

### Skills vs MCP Tools

- **MCP Tools**: Primitives (create_task, read_daily_log, etc.)
- **Skills**: Compositions (workflows that use MCP tools)

### Skills vs Scripts

- **Scripts**: Direct execution (`scripts/execute.sh`)
- **Skills**: Instructions for AI to follow (uses MCP tools)

## Integration Status

✅ **Implemented:**
- Skill tools registered in `gtd_tool_registry.py`
- Claude bridge includes skills category
- System message explains skills to Claude

✅ **Working:**
- Claude can discover skills
- Claude can read skill instructions
- Claude can follow skill workflows

## Example: Morning Check-In

**User:** "Help me do my morning check-in"

**Claude's Process:**
1. Calls `list_agent_skills(query="morning")`
2. Gets `interactive-morning-review-runbook` skill
3. Calls `get_agent_skill("interactive-morning-review-runbook")`
4. Reads instructions:
   - Step 1: `gtd_read_daily_log(date="today")`
   - Step 2: `gtd_get_inbox_count()`
   - Step 3: If inbox > 0, use `inbox-processing` skill
   - etc.
5. Follows instructions step-by-step

## Best Practices

1. **Discover first**: Always use `list_agent_skills` before assuming a skill exists
2. **Read instructions**: Use `get_agent_skill` to understand workflows
3. **Follow step-by-step**: Skills provide clear instructions - follow them
4. **Compose skills**: Skills can reference other skills

## Documentation

- `mcp/CLAUDE_SKILLS_INTEGRATION.md` - Full integration guide
- `mcp/AGENT_SKILLS.md` - How to create skills
- `mcp/MCP_VS_SKILLS.md` - When to use skills vs tools
- `mcp/skills/HOW_SKILLS_WORK.md` - Conceptual overview
