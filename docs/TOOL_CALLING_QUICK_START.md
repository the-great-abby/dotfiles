# Tool Calling Quick Start

## What Was Added

A comprehensive tool calling system that allows thinking models (like Qwen thinking models) to:

1. **Access your GTD system** - List tasks, create tasks, read logs, list projects
2. **Perform web searches** - Research topics, verify facts
3. **Extend capabilities** - Easy to add new tools

## Quick Examples

### Research a Topic

```bash
gtd-advise "Research Kubernetes deployment strategies" --web-search
```

The model will use the `perform_web_search` tool to find information.

### Check Your Tasks

```bash
gtd-advise "What tasks do I have that require high energy?" --enable-gtd-tools
```

The model will use `gtd_list_tasks` to check your tasks.

### Research and Create Task

```bash
gtd-advise "Research Kubernetes best practices and create a task for implementing them" --web-search --enable-gtd-tools
```

The model will:
1. Search the web for Kubernetes best practices
2. Create a task with the research findings

## Files Created

1. **`zsh/functions/gtd_tool_registry.py`** - Tool registry system
   - Registers available tools
   - Handles tool execution
   - Easy to extend

2. **`zsh/TOOL_CALLING_EXTENSION_GUIDE.md`** - Complete documentation
   - How to add new tools
   - Best practices
   - Examples

3. **Enhanced `gtd_persona_helper.py`** - Now supports tool calls
   - Automatically detects tool-supporting models
   - Handles tool execution
   - Supports both web search and GTD tools

## Available Tools

### Web Tools
- `perform_web_search` - Search the web

### GTD Tools
- `gtd_list_tasks` - List tasks with filters
- `gtd_create_task` - Create new tasks
- `gtd_list_projects` - List projects
- `gtd_read_daily_log` - Read daily logs

## Adding Your Own Tools

1. Create a handler function in `gtd_tool_registry.py`:

```python
def _my_tool_handler(param: str) -> str:
    # Your code here
    return json.dumps({"result": "success"})
```

2. Register it:

```python
register_tool(
    name="my_tool",
    description="What it does and when to use it",
    parameters={...},
    handler=_my_tool_handler,
    category="custom"
)
```

3. Use it:

```bash
gtd-advise "Use my_tool with param=test" --enable-gtd-tools
```

## Configuration

Tools are automatically available when:
- Model supports tool calling (Qwen, GPT, Claude, etc.)
- `--enable-gtd-tools` flag is used (for GTD tools)
- `--web-search` flag is used (for web search)

## Debugging

Check tool call logs:

```bash
tail -f ~/.gtd_logs/tool_calls.log
```

This shows:
- Which tools were called
- Parameters passed
- Results returned
- Any errors

## Next Steps

1. **Try it out** - Use the examples above
2. **Read the guide** - See `TOOL_CALLING_EXTENSION_GUIDE.md` for details
3. **Extend it** - Add your own tools as needed

## Support

- Full documentation: `TOOL_CALLING_EXTENSION_GUIDE.md`
- Tool registry: `zsh/functions/gtd_tool_registry.py`
- Persona helper: `zsh/functions/gtd_persona_helper.py`
