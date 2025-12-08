# Tool Calling Extension Guide

## Overview

The GTD system now supports extensible tool calling for thinking models. This allows AI models with tool call support (like Qwen thinking models) to:

1. **Access the GTD system** - List tasks, create tasks, read logs, etc.
2. **Perform web searches** - Research topics, verify facts, get current information
3. **Extend capabilities** - Add custom tools for specific workflows

## Architecture

### Tool Registry System

The tool registry (`zsh/functions/gtd_tool_registry.py`) provides a centralized way to:

- **Register tools** - Define tools with descriptions and parameters
- **Execute tools** - Handle tool calls from AI models
- **Organize by category** - Group tools (gtd, web, research, etc.)

### Integration Points

1. **Persona Helper** (`gtd_persona_helper.py`) - Enhanced to support tool calls
2. **MCP Server** (`mcp/gtd_mcp_server.py`) - Provides GTD operations as MCP tools
3. **Tool Registry** - Central registry for all available tools

## Using Tools

### Enabling Tool Calls

When calling a persona with tool support:

```bash
# Enable web search
gtd-advise "Who won the 1967 World Series?" --web-search

# Enable GTD tools
gtd-advise "What tasks do I have?" --enable-gtd-tools

# Enable both
gtd-advise "Research Kubernetes best practices and create a task for it" --web-search --enable-gtd-tools
```

### In Python Code

```python
from zsh.functions.gtd_persona_helper import call_persona, read_config

config = read_config()
advice, exit_code = call_persona(
    config,
    "david",  # persona
    "What tasks do I have in the computer context?",
    context="task_review",
    enable_gtd_tools=True  # Enable GTD tool calls
)
```

## Available Tools

### Web Tools

- **`perform_web_search`** - Search the web for current information
  - Parameters: `query` (string)
  - Use for: Factual questions, research, current events

### GTD Tools

- **`gtd_list_tasks`** - List tasks with filters
  - Parameters: `context`, `energy`, `priority`, `project`, `status`, `limit`
  - Use for: Checking what tasks exist, filtering by context/energy

- **`gtd_create_task`** - Create a new task
  - Parameters: `title`, `project`, `context`, `priority`, `notes`
  - Use for: Creating tasks from suggestions, breaking down projects

- **`gtd_list_projects`** - List all projects
  - Parameters: `status` (active, on-hold, done, all)
  - Use for: Understanding project portfolio

- **`gtd_read_daily_log`** - Read daily log entries
  - Parameters: `date` (YYYY-MM-DD, optional)
  - Use for: Understanding recent activities, analyzing patterns

## Extending the System

### Adding a New Tool

1. **Create a handler function**:

```python
def _my_custom_tool_handler(param1: str, param2: int = 10) -> str:
    """Handler for your custom tool."""
    # Do your work here
    result = f"Processed {param1} with {param2}"
    return json.dumps({"result": result})
```

2. **Register the tool**:

```python
from zsh.functions.gtd_tool_registry import register_tool

register_tool(
    name="my_custom_tool",
    description="Does something useful. Use this when you need to...",
    parameters={
        "type": "object",
        "properties": {
            "param1": {
                "type": "string",
                "description": "First parameter description"
            },
            "param2": {
                "type": "number",
                "description": "Second parameter (default: 10)"
            }
        },
        "required": ["param1"]
    },
    handler=_my_custom_tool_handler,
    category="custom"  # or "gtd", "web", "research", etc.
)
```

3. **Add to tool registry file**:

Edit `zsh/functions/gtd_tool_registry.py` and add your tool registration at the module level (after imports, before the `__all__` export).

### Example: Adding a Calendar Tool

```python
def _gtd_list_calendar_events_handler(date: Optional[str] = None) -> str:
    """Handler for listing calendar events."""
    try:
        from datetime import datetime
        # Your calendar integration code here
        events = get_calendar_events(date)
        return json.dumps({
            "date": date or datetime.now().strftime("%Y-%m-%d"),
            "events": events,
            "count": len(events)
        })
    except Exception as e:
        return f"Error listing calendar events: {str(e)}"

register_tool(
    name="gtd_list_calendar_events",
    description="List calendar events for a specific date or today. Use this to see what's scheduled, check availability, or understand time commitments.",
    parameters={
        "type": "object",
        "properties": {
            "date": {
                "type": "string",
                "description": "Date in YYYY-MM-DD format (default: today)"
            }
        }
    },
    handler=_gtd_list_calendar_events_handler,
    category="gtd"
)
```

### Example: Adding a Research Tool

```python
def _research_topic_handler(topic: str, depth: str = "overview") -> str:
    """Handler for researching a topic."""
    try:
        # Perform multiple searches
        search1 = execute_web_search(f"{topic} overview")
        search2 = execute_web_search(f"{topic} best practices")
        
        # Combine results
        return json.dumps({
            "topic": topic,
            "overview": search1,
            "best_practices": search2,
            "depth": depth
        })
    except Exception as e:
        return f"Error researching topic: {str(e)}"

register_tool(
    name="research_topic",
    description="Research a topic comprehensively by performing multiple web searches. Use this when the user wants to learn about something or needs detailed information.",
    parameters={
        "type": "object",
        "properties": {
            "topic": {
                "type": "string",
                "description": "Topic to research (e.g., 'Kubernetes deployment strategies')"
            },
            "depth": {
                "type": "string",
                "description": "Research depth: 'overview', 'detailed', or 'comprehensive'"
            }
        },
        "required": ["topic"]
    },
    handler=_research_topic_handler,
    category="research"
)
```

## Tool Categories

Organize tools by category for better management:

- **`web`** - Web search and internet tools
- **`gtd`** - GTD system operations (tasks, projects, logs)
- **`research`** - Research and information gathering
- **`integration`** - External system integrations (calendar, email, etc.)
- **`custom`** - Custom tools for specific workflows

## Best Practices

### Tool Descriptions

Write clear, actionable descriptions that help the AI understand when to use the tool:

✅ **Good**: "List tasks from the GTD system with optional filters. Use this to see what tasks are available, check task status, or find tasks by context, energy level, priority, or project."

❌ **Bad**: "Lists tasks."

### Parameter Descriptions

Be specific about what each parameter does:

✅ **Good**:
```python
"context": {
    "type": "string",
    "description": "Filter by context (home, office, computer, phone, errands)"
}
```

❌ **Bad**:
```python
"context": {
    "type": "string"
}
```

### Error Handling

Always handle errors gracefully:

```python
def _my_tool_handler(param: str) -> str:
    try:
        result = do_work(param)
        return json.dumps({"success": True, "result": result})
    except Exception as e:
        return json.dumps({"success": False, "error": str(e)})
```

### Tool Naming

Use descriptive, consistent naming:

- Prefix GTD tools with `gtd_`: `gtd_list_tasks`, `gtd_create_task`
- Use verb_noun pattern: `perform_web_search`, `list_calendar_events`
- Keep names lowercase with underscores

## Testing Tools

### Manual Testing

1. Register your tool in the registry
2. Test the handler directly:

```python
from zsh.functions.gtd_tool_registry import execute_tool

result = execute_tool("my_custom_tool", {"param1": "test", "param2": 5})
print(result)
```

3. Test with a persona:

```bash
gtd-advise "Use my_custom_tool with param1=test" --enable-gtd-tools
```

### Debugging

Check tool call logs:

```bash
tail -f ~/.gtd_logs/tool_calls.log
```

This shows:
- Which tools were called
- What parameters were passed
- Tool execution results
- Any errors

## Integration with Other Systems

### MCP Server Integration

The MCP server (`mcp/gtd_mcp_server.py`) provides many GTD operations. You can:

1. **Call MCP functions directly** in your tool handlers:

```python
from mcp.gtd_mcp_server import list_tasks, create_task, read_project_file
```

2. **Reuse MCP logic** without duplicating code

3. **Extend MCP tools** by wrapping them in tool registry handlers

### Command-Line Integration

Tools can call command-line utilities:

```python
import subprocess

def _gtd_sync_handler() -> str:
    """Sync GTD system with external services."""
    result = subprocess.run(
        ["gtd-sync"],
        capture_output=True,
        text=True
    )
    return json.dumps({
        "success": result.returncode == 0,
        "output": result.stdout,
        "error": result.stderr
    })
```

## Advanced: Tool Chaining

Tools can call other tools:

```python
def _smart_task_creation_handler(title: str, research: bool = False) -> str:
    """Create a task, optionally researching the topic first."""
    if research:
        # Use web search tool
        from zsh.functions.gtd_tool_registry import execute_tool
        research_result = execute_tool(
            "perform_web_search",
            {"query": f"{title} best practices"}
        )
        # Use research in task notes
        notes = f"Research: {research_result}"
    else:
        notes = ""
    
    # Create task with research notes
    return execute_tool(
        "gtd_create_task",
        {"title": title, "notes": notes}
    )
```

## Configuration

### Enabling Tools by Default

To enable GTD tools by default for certain personas, modify `gtd_persona_helper.py`:

```python
# Auto-enable GTD tools for certain personas
if persona_key in ["david", "louiza", "murphy"]:
    enable_gtd_tools = True
```

### Tool Categories

Control which tools are available:

```python
# Only web tools
tools = get_tool_definitions(categories=["web"])

# Only GTD tools
tools = get_tool_definitions(categories=["gtd"])

# Multiple categories
tools = get_tool_definitions(categories=["web", "gtd", "research"])
```

## Examples

### Example 1: Research and Create Task

User: "Research Kubernetes deployment strategies and create a task for it"

The model will:
1. Call `perform_web_search` with query "Kubernetes deployment strategies"
2. Review search results
3. Call `gtd_create_task` with title and notes from research

### Example 2: Task Review

User: "What tasks do I have that require high energy?"

The model will:
1. Call `gtd_list_tasks` with `energy="high"`
2. Format and present the results

### Example 3: Project Planning

User: "List my active projects and suggest next actions"

The model will:
1. Call `gtd_list_projects` with `status="active"`
2. For each project, call `gtd_list_tasks` with `project` filter
3. Analyze and suggest next actions

## Troubleshooting

### Tool Not Being Called

1. Check if model supports tool calls (Qwen, GPT, Claude, etc.)
2. Verify tool is registered: `from gtd_tool_registry import list_all_tools; print(list_all_tools())`
3. Check tool call logs: `~/.gtd_logs/tool_calls.log`
4. Ensure `enable_gtd_tools=True` is passed to `call_persona`

### Tool Execution Errors

1. Check handler function signature matches parameters
2. Verify imports are available
3. Test handler directly (see Testing Tools)
4. Check error messages in tool call logs

### Model Not Using Tools

1. Improve tool descriptions (be more specific about when to use)
2. Add examples in descriptions
3. Use `tool_choice="required"` for critical tools (if API supports)
4. Check if model actually supports tool calling

## Future Enhancements

Potential extensions:

1. **Tool permissions** - Restrict certain tools to certain personas
2. **Tool usage tracking** - Log which tools are used most
3. **Tool composition** - Define workflows as tool sequences
4. **Tool validation** - Validate parameters before execution
5. **Tool caching** - Cache results for expensive operations
6. **Tool rate limiting** - Prevent abuse of external APIs

## Summary

The tool calling system provides:

✅ **Extensibility** - Easy to add new tools  
✅ **Integration** - Works with GTD system and external services  
✅ **Flexibility** - Control which tools are available when  
✅ **Debugging** - Comprehensive logging for troubleshooting  

Start by using existing tools, then extend with your own as needed!
