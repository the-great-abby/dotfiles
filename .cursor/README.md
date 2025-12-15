# Cursor MCP Configuration

This directory contains configuration files for Cursor's Model Context Protocol (MCP) integration.

## Quick Setup ✨

**No setup required!** Cursor automatically reads MCP configuration from `.cursor/mcp.json` in your workspace.

### How It Works

1. **Create mcp.json** (one-time, if needed):
   ```bash
   cd .cursor
   # If mcp.json doesn't exist, create it from mcp_config.json
   if [[ ! -f mcp.json ]]; then
     cp mcp_config.json mcp.json
   fi
   ```
   
   Or run the setup script which will do this automatically:
   ```bash
   ./.cursor/setup_cursor_mcp.sh
   ```

2. **Open this workspace in Cursor** - Cursor automatically detects `.cursor/mcp.json`

3. **Restart Cursor** (if it was already open when you first added the config)

4. **Verify it's working** - Check the MCP status indicator or ask: "What MCP tools are available?"

That's it! The configuration uses workspace-relative paths (`${workspaceFolder}`) so it works for anyone who clones this repository.

## Configuration File

The MCP configuration is in `.cursor/mcp_config.json` (rename to `mcp.json` for Cursor to auto-detect it) and includes:
- **Workspace-relative paths**: Uses `${workspaceFolder}` so it works everywhere
- **Environment variables**: Uses `${env:USER}` for your username  
- **All MCP tools**: Including the new vector database query tools (`search_vector_database`, `get_vector_database_stats`, `get_file_vector_info`)

## Alternative: Global Configuration

If you prefer to use global Cursor settings instead of workspace settings:

```bash
./.cursor/setup_cursor_mcp.sh
```

This will copy the config to Cursor's global settings directory and convert paths to absolute paths.

See `../mcp/CURSOR_MCP_CONFIG.md` for detailed manual setup instructions.

## Verification

After setup, restart Cursor and verify:

1. Check Cursor's MCP status indicator (should show "gtd-unified-system")
2. Ask the AI: "What MCP tools are available?"
3. Try: "What pending task suggestions do I have?"
4. Try vector database queries: "Search for information about Pathfinder MOC"

## Troubleshooting

If the MCP server isn't connecting:

1. Check Python dependencies: `pip3 list | grep mcp`
2. Test the server directly: `python3 mcp/gtd_mcp_server.py`
3. Check Cursor logs: Help → Toggle Developer Tools → Console
4. Verify the config file is named `mcp.json` (not `mcp_config.json`)
5. Make sure you're opening the workspace (not just a folder) in Cursor

## Available MCP Tools

The MCP server provides many tools including:

### Task Management
- `suggest_tasks_from_text` - Analyze text and suggest tasks
- `create_task` - Create a new task
- `list_tasks` - List tasks with filters
- `get_task_details` - Get task information

### Vector Database (NEW!)
- `search_vector_database` - Semantic search across all vectorized content
- `get_vector_database_stats` - Get database statistics
- `get_file_vector_info` - Check if a file is vectorized

### Projects & Goals
- `list_projects` - List all projects
- `create_project` - Create a new project
- `list_goals` - List goals
- `create_goal` - Create a new goal

### Analysis
- `weekly_review` - Trigger deep weekly review
- `analyze_energy` - Analyze energy patterns
- `find_connections` - Find connections between items

And many more! Ask the AI: "What MCP tools are available?" to see the full list.
