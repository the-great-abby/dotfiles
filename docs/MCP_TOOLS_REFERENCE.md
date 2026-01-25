# MCP Tools Reference

Complete list of all available MCP tools in the GTD system.

## Overview

Your system has **two types of MCP tools**:

1. **GTD Tool Registry Tools** (17 tools) - Used by Claude API calls via `claude-ask` and the TUI
2. **MCP Server Tools** (40+ tools) - Available in Cursor IDE via the MCP server
3. **Sequential Thinking Tools** (4 tools) - Available if Sequential Thinking MCP is configured

---

## GTD Tool Registry Tools (17 tools)

These tools are available when using Claude via `claude-ask`, `claude-gtd`, or the Claude Ask TUI.

### GTD Tools (12 tools)

| Tool Name | Description |
|-----------|-------------|
| `gtd_list_tasks` | List tasks with filters (context, energy, priority, project, status) |
| `gtd_create_task` | Create a new task with title, project, context, priority, notes |
| `gtd_list_projects` | List all projects (active, completed, all) |
| `gtd_read_daily_log` | Read daily log entries (supports 'today', 'yesterday', '3 days ago', YYYY-MM-DD) |
| `gtd_add_daily_log_entry` | Add an entry to the daily log (auto-timestamped) |
| `gtd_get_datetime` | Get current date/time or calculate relative dates |
| `gtd_get_inbox_count` | Get count of unprocessed inbox items |
| `gtd_suggest_tasks_from_text` | Analyze text and suggest actionable tasks |
| `gtd_search_second_brain` | Search personal knowledge base (notes, Pathfinder campaign, etc.) |
| `gtd_get_personalization` | Get user personalization data (relationships, goals, energy patterns, etc.) |
| `gtd_update_personalization` | Update personalization data (learn user preferences) |
| `gtd_get_calendar_overview` | Get today's calendar overview (events, meetings) |

### Skill Tools (3 tools)

| Tool Name | Description |
|-----------|-------------|
| `list_agent_skills` | List all available Agent Skills (workflows) |
| `get_agent_skill` | Get detailed instructions for a specific skill |
| `execute_agent_skill` | Execute a skill (instructions, scripts, or templates) |

### System Tools (1 tool)

| Tool Name | Description |
|-----------|-------------|
| `list_available_tools` | List all available tools (can filter by category) |

### Web Tools (1 tool)

| Tool Name | Description |
|-----------|-------------|
| `perform_web_search` | Perform web search for current, accurate information |

---

## MCP Server Tools (40+ tools)

These tools are available in **Cursor IDE** when the MCP server is connected. They provide more detailed functionality than the tool registry tools.

### Task Management (10 tools)

| Tool Name | Description |
|-----------|-------------|
| `list_tasks` | List tasks with filters (structured data) |
| `get_task_details` | Get detailed information about a specific task |
| `create_task` | Create a new task directly |
| `update_task` | Update task properties (title, context, energy, priority, status) |
| `complete_task` | Mark a task as complete |
| `defer_task` | Defer a task until a specific date/time |
| `get_context_tasks` | Get tasks available in a specific context and energy level |
| `suggest_tasks_from_text` | Analyze text and suggest tasks (fast AI) |
| `suggest_task` | Suggest a task (adds to pending suggestions) |
| `create_task_from_suggestion_quick` | Create task from suggestion with one keystroke |

### Task Suggestions (7 tools)

| Tool Name | Description |
|-----------|-------------|
| `get_pending_suggestions` | Get all pending task suggestions |
| `get_immediate_suggestions` | Get high-confidence suggestions (auto-creation) |
| `get_review_mode_suggestions` | Get medium-confidence suggestions (review mode) |
| `create_tasks_from_suggestion` | Create task from a pending suggestion |
| `dismiss_suggestion` | Dismiss a suggestion (tracks for learning) |
| `get_suggestion_statistics` | Get acceptance statistics and confidence thresholds |

### Project Management (4 tools)

| Tool Name | Description |
|-----------|-------------|
| `list_projects` | List all projects with details and status |
| `create_project` | Create a new project (with optional repository link) |
| `get_project_details` | Get detailed information about a project |
| `get_project_status` | Get project status (tasks, progress, next actions) |

### Goals & Areas (4 tools)

| Tool Name | Description |
|-----------|-------------|
| `list_goals` | List all goals with details and status |
| `create_goal` | Create a new goal (with deadline, area, description) |
| `get_goal_details` | Get detailed information about a goal |
| `update_goal` | Update goal properties (progress, status, deadline) |
| `list_areas` | List all areas of responsibility |

### Daily Logs (2 tools)

| Tool Name | Description |
|-----------|-------------|
| `read_daily_log` | Read daily log entries for a specific date or today |
| `read_recent_logs` | Read daily log entries from the past N days |

### Personalization (2 tools)

| Tool Name | Description |
|-----------|-------------|
| `get_personalization` | Get user personalization data (relationships, goals, patterns) |
| `update_personalization` | Update personalization data (learn user preferences) |

### Deep Analysis (4 tools)

| Tool Name | Description |
|-----------|-------------|
| `weekly_review` | Trigger deep weekly review analysis (background, 20b model) |
| `analyze_energy` | Analyze energy patterns from daily logs (background) |
| `find_connections` | Find connections between tasks, projects, zettels (background) |
| `generate_insights` | Generate insights from recent activity (background) |

### System & Planning (3 tools)

| Tool Name | Description |
|-----------|-------------|
| `get_inbox_count` | Get count of unprocessed inbox items |
| `get_worker_status` | Check background worker status (queue, activity) |
| `restructure_with_natural_language` | Restructure items based on natural language commands |
| `plan_with_ai` | Interactive AI planning assistant (break down goals/projects/tasks) |

### Vector Database (if configured)

| Tool Name | Description |
|-----------|-------------|
| `search_vector_database` | Semantic search across vectorized content |
| `get_vector_database_stats` | Get database statistics |
| `get_file_vector_info` | Check if a file is vectorized |

---

## Sequential Thinking Tools (4 tools)

These tools are available if Sequential Thinking MCP is configured in Cursor.

| Tool Name | Description |
|-----------|-------------|
| `create_thoughts` | Start a structured thinking process with initial thoughts |
| `revise_thought` | Revise a previous thought and update subsequent thoughts |
| `branch_thought` | Create alternative reasoning paths |
| `summarize_thoughts` | Get a summary of the thinking process |

**Note**: Sequential Thinking tools are only available in Cursor IDE, not in the Claude Ask TUI.

---

## How to Check Available Tools

### In Claude Ask TUI

1. Press `Ctrl+T` to see tool status
2. Shows: Total tools, GTD tools, Skill tools, Sequential Thinking (if available)

### In Cursor IDE

1. Ask: "What MCP tools are available?"
2. Or check MCP status indicator in Cursor's status bar
3. Or use: `list_available_tools` tool

### Via Command Line

```bash
# Check tool registry
python3 -c "
from zsh.functions.gtd_tool_registry import get_tool_definitions
tools = get_tool_definitions()
print(f'Total: {len(tools)} tools')
for t in tools:
    print(f'  - {t[\"function\"][\"name\"]}')
"
```

---

## Tool Categories

### By Category

- **GTD**: Task, project, goal, and daily log management
- **Skills**: Agent Skills (reusable workflows)
- **Web**: Web search capabilities
- **System**: System utilities and tool discovery
- **Deep Analysis**: Background analysis (queued for 20b model)
- **Personalization**: User context and preferences
- **Sequential Thinking**: Structured problem-solving (if configured)

### By Access Method

- **Claude API/TUI**: GTD Tool Registry tools (17 tools)
- **Cursor MCP**: MCP Server tools (40+ tools) + Sequential Thinking (4 tools)
- **Both**: Some tools are available in both (like `gtd_list_tasks` and `list_tasks`)

---

## Usage Examples

### List Tasks
```python
# Via Claude API/TUI
gtd_list_tasks(status="active", limit=10)

# Via MCP Server (Cursor)
list_tasks(status="active", limit=10)
```

### Read Daily Log
```python
# Via Claude API/TUI
gtd_read_daily_log(date="today")

# Via MCP Server (Cursor)
read_daily_log(date="today")
```

### Search Second Brain
```python
# Via Claude API/TUI
gtd_search_second_brain(topic="Pathfinder campaign", max_results=5)
```

### Use Sequential Thinking
```python
# Via Cursor MCP only
create_thoughts(thought="How should I organize my tasks?", nextThoughtNeeded=True)
```

---

## Troubleshooting

### Tools Not Showing Up

1. **In Claude Ask TUI**: Press `Ctrl+T` to verify tools are loaded
2. **In Cursor**: Check MCP status indicator, restart Cursor if needed
3. **Sequential Thinking**: Verify it's configured in Cursor MCP settings

### Tool Execution Errors

- Check tool parameters match the schema
- Verify required parameters are provided
- Check tool handler is available (for tool registry tools)

### MCP Server Not Connected

- Restart Cursor completely
- Check Cursor DevTools for MCP connection errors
- Verify MCP server configuration file location

---

## Quick Reference

**Most Used Tools:**
- `gtd_list_tasks` / `list_tasks` - See what tasks you have
- `gtd_read_daily_log` / `read_daily_log` - Review daily logs
- `gtd_create_task` / `create_task` - Create new tasks
- `gtd_get_personalization` / `get_personalization` - Get user context
- `list_agent_skills` - Discover available workflows
- `gtd_search_second_brain` - Search your notes

**For Complex Problems:**
- `plan_with_ai` - Interactive planning assistant
- `create_thoughts` (Sequential Thinking) - Structured problem-solving
- `weekly_review` - Deep analysis

**For Learning:**
- `gtd_update_personalization` - Remember user preferences
- `get_suggestion_statistics` - Learn from task suggestions
