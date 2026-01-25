# Claude + Agent Skills Integration Guide

## Current State

### How Skills Work Now

**Agent Skills** are file-based packages (folders with `SKILL.md`) that provide procedural knowledge and instructions to AI agents. They're designed to tell agents **how to use MCP tools** to accomplish goals.

**Current Architecture:**
```
┌─────────────────────────────────────┐
│         MCP Server                  │
│  (gtd_mcp_server.py)                │
│                                     │
│  ✅ Skills Tools Available:        │
│     - list_agent_skills            │
│     - get_agent_skill               │
│     - execute_agent_skill          │
│     - reload_agent_skills          │
└─────────────────────────────────────┘
           │
           │ (via MCP protocol)
           │
           ▼
┌─────────────────────────────────────┐
│    Cursor IDE / MCP Clients         │
│    (Can use skills via MCP)          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    Claude Direct API Calls           │
│    (claude_ollama_bridge.py)         │
│                                     │
│  ❌ Skills Tools NOT Available      │
│     (Only gtd_tool_registry tools)  │
└─────────────────────────────────────┘
```

### The Gap

When you call Claude directly via `claude-ask` or `claude-gtd`, the system:
1. ✅ Loads GTD tools from `gtd_tool_registry.py` (tasks, projects, logs, etc.)
2. ❌ **Does NOT load skill tools** (`list_agent_skills`, `execute_agent_skill`, etc.)

This means Claude can use GTD primitives but can't discover or execute skills.

## Solution: Register Skill Tools

To make skills available to Claude, we need to register them in `gtd_tool_registry.py`. This allows Claude to:
- Discover available skills
- Read skill instructions
- Execute skills (which then use MCP tools)

## Implementation

### Step 1: Register Skill Tools in Tool Registry

Add skill tool handlers to `zsh/functions/gtd_tool_registry.py`:

```python
# Add at the end of gtd_tool_registry.py

def _list_agent_skills_handler(query: Optional[str] = None, tags: Optional[List[str]] = None) -> str:
    """Handler for listing agent skills."""
    try:
        from pathlib import Path
        import sys
        
        # Import skills registry
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_skills.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_skills.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_skills", mcp_path)
            skills_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(skills_module)
            
            registry = skills_module.get_registry()
            
            if query or tags:
                skills = registry.search_skills(query=query, tags=tags)
            else:
                skills = registry.list_skills()
            
            return json.dumps({
                "skills": skills,
                "count": len(skills)
            }, default=str)
        else:
            return json.dumps({
                "error": "Skills module not found",
                "skills": [],
                "count": 0
            })
    except Exception as e:
        return json.dumps({
            "error": f"Error listing skills: {str(e)}",
            "skills": [],
            "count": 0
        })


def _get_agent_skill_handler(skill_name: str) -> str:
    """Handler for getting a specific skill."""
    try:
        from pathlib import Path
        import sys
        
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_skills.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_skills.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_skills", mcp_path)
            skills_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(skills_module)
            
            registry = skills_module.get_registry()
            skill = registry.get_skill(skill_name)
            
            if skill:
                return json.dumps({
                    "skill": skill.to_dict(),
                    "instructions": skill.instructions,
                    "metadata": skill.metadata
                }, default=str)
            else:
                return json.dumps({
                    "error": f"Skill not found: {skill_name}",
                    "available_skills": [s["id"] for s in registry.list_skills()]
                })
        else:
            return json.dumps({
                "error": "Skills module not found"
            })
    except Exception as e:
        return json.dumps({
            "error": f"Error getting skill: {str(e)}"
        })


def _execute_agent_skill_handler(
    skill_name: str,
    method: str = "instructions",
    args: Optional[Dict[str, Any]] = None
) -> str:
    """Handler for executing an agent skill."""
    try:
        from pathlib import Path
        import sys
        
        mcp_path = Path(__file__).parent.parent.parent / "mcp" / "gtd_skills.py"
        if not mcp_path.exists():
            mcp_path = Path.home() / "code" / "dotfiles" / "mcp" / "gtd_skills.py"
        
        if mcp_path.exists():
            import importlib.util
            spec = importlib.util.spec_from_file_location("gtd_skills", mcp_path)
            skills_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(skills_module)
            
            registry = skills_module.get_registry()
            success, output, metadata = registry.execute_skill(
                skill_name=skill_name,
                method=method,
                args=args or {}
            )
            
            return json.dumps({
                "success": success,
                "output": output,
                "metadata": metadata
            }, default=str)
        else:
            return json.dumps({
                "error": "Skills module not found",
                "success": False
            })
    except Exception as e:
        return json.dumps({
            "error": f"Error executing skill: {str(e)}",
            "success": False
        })


# Register skill tools
register_tool(
    name="list_agent_skills",
    description="List all available Agent Skills. Skills are reusable workflows that guide how to use GTD tools to accomplish goals. Use this to discover what skills are available, then use get_agent_skill to read their instructions.",
    parameters={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Optional search query to filter skills by name or description"
            },
            "tags": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Optional list of tags to filter skills (e.g., ['morning', 'routine'])"
            }
        }
    },
    handler=_list_agent_skills_handler,
    category="skills"
)

register_tool(
    name="get_agent_skill",
    description="Get detailed information about a specific Agent Skill including its full instructions. Skills provide step-by-step workflows for using GTD tools. Use this to understand how to accomplish a goal using available tools.",
    parameters={
        "type": "object",
        "properties": {
            "skill_name": {
                "type": "string",
                "description": "Name of the skill to retrieve (e.g., 'interactive-morning-review-runbook', 'inbox-processing')"
            }
        },
        "required": ["skill_name"]
    },
    handler=_get_agent_skill_handler,
    category="skills"
)

register_tool(
    name="execute_agent_skill",
    description="Execute an Agent Skill. Skills can return instructions (for AI to follow), execute scripts, or render templates. Most commonly, use method='instructions' to get the skill's workflow steps, then follow those steps using GTD tools.",
    parameters={
        "type": "object",
        "properties": {
            "skill_name": {
                "type": "string",
                "description": "Name of the skill to execute"
            },
            "method": {
                "type": "string",
                "description": "Execution method: 'instructions' (returns skill instructions for AI to follow), 'script:<script_name>' (executes a script), or 'template:<template_name>' (renders a template). Default: 'instructions'",
                "default": "instructions"
            },
            "args": {
                "type": "object",
                "description": "Optional arguments to pass to the skill (for scripts or templates)"
            }
        },
        "required": ["skill_name"]
    },
    handler=_execute_agent_skill_handler,
    category="skills"
)
```

### Step 2: Update Claude Bridge to Include Skills

Modify `mcp/claude_ollama_bridge.py` to include skills tools:

```python
# In _call_claude method, around line 413:

from gtd_tool_registry import get_tool_definitions
gtd_tools = get_tool_definitions(categories=["gtd", "skills"])  # Add "skills" category
```

### Step 3: Update System Message

Enhance the system message to mention skills:

```python
# Around line 430 in claude_ollama_bridge.py:

if tools:
    system_message += "\n\nYou have access to GTD tools to interact with the user's productivity system. Use these tools when you need to access tasks, projects, daily logs, or other GTD data."
    
    # Check if skills tools are available
    skill_tools = [t for t in tools if t.get("name", "").startswith(("list_agent_skills", "get_agent_skill", "execute_agent_skill"))]
    if skill_tools:
        system_message += "\n\nYou also have access to Agent Skills - reusable workflows that guide how to accomplish goals using GTD tools. Use list_agent_skills to discover available skills, then get_agent_skill to read their instructions. Skills provide step-by-step guidance on using tools effectively."
```

## How Claude Will Use Skills

### Example Flow

**User:** "Help me do my morning check-in"

**Claude's Process:**
1. **Discover skills**: Calls `list_agent_skills(query="morning")`
   - Returns: `[{"id": "interactive-morning-review-runbook", "name": "Morning Check-In", ...}]`

2. **Get skill details**: Calls `get_agent_skill(skill_name="interactive-morning-review-runbook")`
   - Returns: Full instructions from `SKILL.md`

3. **Follow instructions**: Reads the skill's step-by-step workflow:
   - Step 1: Call `gtd_read_daily_log(date="today")`
   - Step 2: Call `gtd_get_inbox_count()`
   - Step 3: If inbox > 0, use `inbox-processing` skill
   - Step 4: Call `gtd_get_context_tasks(context="computer")`
   - etc.

4. **Execute workflow**: Claude follows the instructions, calling GTD tools in sequence

### Benefits

✅ **Claude can discover skills** - No need to hardcode skill names  
✅ **Claude can read instructions** - Understands workflows without code changes  
✅ **Claude can execute workflows** - Follows skill instructions using available tools  
✅ **Skills remain portable** - Still file-based, easy to share and version  
✅ **Composable** - Skills can reference other skills (e.g., interactive-morning-review-runbook → inbox-processing)

## Best Practices

### 1. Skill Design for Claude

When writing skills that Claude will use:

**✅ DO:**
- Write clear, step-by-step instructions
- Reference specific tool names (e.g., `gtd_read_daily_log`)
- Include decision points (e.g., "If inbox > 0, then...")
- Provide context on when to use the skill
- Include examples

**❌ DON'T:**
- Assume Claude knows internal implementation details
- Use vague instructions like "process the inbox"
- Skip error handling guidance

### 2. Skill Discovery

Claude should discover skills dynamically:

```python
# Good: Discover skills first
list_agent_skills(query="review")

# Then get details
get_agent_skill(skill_name="daily-review")

# Then follow instructions
# (Claude reads instructions and executes using tools)
```

### 3. Skill Composition

Skills can reference other skills:

```markdown
# interactive-morning-review-runbook/SKILL.md

## Step 2: Process Inbox
If inbox count > 0:
- Use the `inbox-processing` skill to process all items
- Call: get_agent_skill(skill_name="inbox-processing")
- Follow its instructions
```

### 4. Error Handling

Skills should guide Claude on error handling:

```markdown
## Error Handling
If `gtd_read_daily_log` returns an error:
- Check if the log directory exists
- If not, create it using appropriate tools
- Retry the operation
```

## Current Skills

Your system has these skills available:

- **interactive-morning-review-runbook**: Complete morning routine workflow
- **inbox-processing**: Process inbox items using GTD methodology
- **daily-review**: Evening reflection and review workflow
- **task-summary**: Generate task summaries

## Testing

After implementing:

1. **Test skill discovery:**
   ```bash
   claude-ask "What skills are available for morning routines?"
   ```

2. **Test skill execution:**
   ```bash
   claude-ask "Help me do my morning check-in"
   ```

3. **Verify Claude follows instructions:**
   - Claude should call `list_agent_skills`
   - Then `get_agent_skill("interactive-morning-review-runbook")`
   - Then follow the instructions step-by-step

## Architecture Summary

```
┌─────────────────────────────────────┐
│    Claude API Call                  │
│    (claude_ollama_bridge.py)         │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│    Tool Registry                    │
│    (gtd_tool_registry.py)           │
│                                     │
│  ✅ GTD Tools (gtd_*)              │
│  ✅ Skill Tools (list/get/execute) │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│    Skills Registry                  │
│    (gtd_skills.py)                  │
│                                     │
│  ✅ Loads SKILL.md files           │
│  ✅ Provides skill metadata         │
│  ✅ Executes skills                │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│    Skills Directory                 │
│    (mcp/skills/)                    │
│                                     │
│  ✅ interactive-morning-review-runbook/SKILL.md       │
│  ✅ inbox-processing/SKILL.md      │
│  ✅ daily-review/SKILL.md          │
└─────────────────────────────────────┘
```

## Next Steps

1. ✅ Register skill tools in `gtd_tool_registry.py`
2. ✅ Update `claude_ollama_bridge.py` to include skills category
3. ✅ Test skill discovery and execution
4. ✅ Create more skills as needed
5. ✅ Document skill creation process

## Related Documentation

- `mcp/AGENT_SKILLS.md` - How to create skills
- `mcp/MCP_VS_SKILLS.md` - When to use skills vs MCP tools
- `mcp/skills/HOW_SKILLS_WORK.md` - How skills work conceptually
- `mcp/skills/SKILL_SUGGESTIONS.md` - Ideas for new skills
