# Cursor MCP Configuration

This directory contains configuration files for Cursor's Model Context Protocol (MCP) integration.

## Quick Setup

### macOS

1. Copy the MCP config to Cursor's settings:

```bash
# Create directory if it doesn't exist
mkdir -p ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/

# Copy the config (update paths in the JSON first!)
cp mcp_config.json ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

2. Update paths in the config file to match your system:

```bash
# Replace /Users/abby/code/dotfiles with your actual path
sed -i '' "s|/Users/abby/code/dotfiles|$(cd ~/code/dotfiles && pwd)|g" ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

3. Restart Cursor

### Linux

```bash
mkdir -p ~/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/
cp mcp_config.json ~/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

### Windows

```powershell
mkdir -p "$env:APPDATA\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\"
copy mcp_config.json "$env:APPDATA\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json"
```

## Using the Setup Script

Run the setup script to automatically configure Cursor:

```bash
./.cursor/setup_cursor_mcp.sh
```

This will:
1. Detect your OS
2. Update paths in the config
3. Copy config to Cursor settings directory
4. Verify installation

## Manual Configuration

See `../mcp/CURSOR_MCP_CONFIG.md` for detailed manual setup instructions.

## Verification

After setup, restart Cursor and verify:

1. Check Cursor's MCP status indicator (should show "gtd-unified-system")
2. Ask the AI: "What MCP tools are available?"
3. Try: "What pending task suggestions do I have?"

## Troubleshooting

If the MCP server isn't connecting:

1. Check Python dependencies: `pip3 list | grep mcp`
2. Test the server directly: `python3 mcp/gtd_mcp_server.py`
3. Check Cursor logs: Help → Toggle Developer Tools → Console
4. Verify paths in the config match your system

