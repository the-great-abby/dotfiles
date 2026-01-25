# Sequential Thinking MCP Setup Guide

## Overview

Sequential Thinking MCP is a separate MCP server that provides structured problem-solving tools. It needs to be configured in Cursor's actual MCP settings, not just in the workspace config.

## Important: Where Cursor Stores MCP Settings

The `.cursor/mcp_config.json` file in your workspace is **NOT** the active Cursor MCP settings file. Cursor uses a different location:

- **macOS**: `~/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- **Linux**: `~/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- **Windows**: `%APPDATA%\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`

## Setup Steps

### 1. Find Your Cursor MCP Settings File

```bash
# macOS
open ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/

# Or check if it exists
ls -la ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

### 2. Add Sequential Thinking MCP

Edit the `cline_mcp_settings.json` file and add:

```json
{
  "mcpServers": {
    "gtd-unified-system": {
      "command": "python3",
      "args": [
        "/Users/abby/code/dotfiles/mcp/gtd_mcp_server.py"
      ],
      "env": {
        "GTD_USER_NAME": "${env:USER}",
        "GTD_DEEP_MODEL_URL": "http://127.0.0.1:31080/v1/chat/completions",
        "GTD_DEEP_MODEL_NAME": "gpt-oss-20b",
        "GTD_RABBITMQ_URL": "amqp://192.168.64.2:30672",
        "GTD_RABBITMQ_QUEUE": "gtd_deep_analysis",
        "PYTHONPATH": "${workspaceFolder}"
      }
    },
    "sequentialthinking": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "mcp/sequentialthinking"
      ]
    }
  }
}
```

### 3. Verify Docker Image Exists

```bash
docker images | grep sequentialthinking
# Should show: mcp/sequentialthinking:latest
```

### 4. Test Docker Image

```bash
docker run --rm -i mcp/sequentialthinking --help
# Should show: "Sequential Thinking MCP Server running on stdio"
```

### 5. Restart Cursor

**Important**: After updating MCP settings, you must:
1. Quit Cursor completely (Cmd+Q on macOS)
2. Reopen Cursor
3. Wait for MCP servers to connect (check status indicator)

### 6. Verify Tools Are Available

#### In Cursor Chat:
Ask: "What MCP tools are available?" or "List all available tools"

You should see Sequential Thinking tools:
- `create_thoughts` - Start a thinking process
- `revise_thought` - Revise a previous thought
- `branch_thought` - Create alternative reasoning paths
- `summarize_thoughts` - Get a summary

#### In Claude Ask TUI:
Press `Ctrl+T` to see tool status. Note: Sequential Thinking tools won't appear in the GTD tool registry check because they come from a separate MCP server. They're only available when Cursor is connected to that server.

## Troubleshooting

### Tools Not Showing Up

1. **Check Cursor MCP Status**:
   - Look for MCP status indicator in Cursor's status bar
   - Should show both "gtd-unified-system" and "sequentialthinking" as connected

2. **Check Cursor DevTools**:
   - Help → Toggle Developer Tools → Console
   - Look for MCP connection errors

3. **Verify Docker Image**:
   ```bash
   docker images mcp/sequentialthinking
   ```

4. **Test Docker Command**:
   ```bash
   docker run --rm -i mcp/sequentialthinking
   # Should start the MCP server (will wait for stdio input)
   ```

5. **Check Cursor Logs**:
   - Help → Toggle Developer Tools → Console
   - Filter for "MCP" or "sequentialthinking"
   - Look for connection errors

### Docker Issues

If Docker command fails:
- Make sure Docker is running: `docker ps`
- Verify image exists: `docker images | grep sequential`
- Try pulling the image: `docker pull mcp/sequentialthinking`

### Alternative: Use NPX Instead of Docker

If Docker doesn't work, you can use npx:

```json
"sequentialthinking": {
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-sequential-thinking"
  ]
}
```

## How Sequential Thinking Tools Work

Sequential Thinking MCP provides tools for structured reasoning:

1. **create_thoughts**: Start a new thinking process with initial thoughts
2. **revise_thought**: Modify a previous thought and update subsequent thoughts
3. **branch_thought**: Create alternative reasoning paths
4. **summarize_thoughts**: Get a summary of the thinking process

These tools help Claude break down complex problems into manageable steps, which can reduce hallucination and improve accuracy.

## Integration with GTD System

Sequential Thinking tools work alongside GTD tools:
- Use Sequential Thinking for complex problem analysis
- Use GTD tools for task/project management
- Combine both for structured problem-solving and task creation

Example workflow:
1. Use `create_thoughts` to analyze a complex problem
2. Use `gtd_list_tasks` to see existing tasks
3. Use `gtd_create_task` to create tasks based on the analysis
