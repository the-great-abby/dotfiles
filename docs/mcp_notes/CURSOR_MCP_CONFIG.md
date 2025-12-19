# Cursor MCP Configuration Guide

This guide shows you how to configure the GTD MCP server in Cursor.

## Quick Setup

### 1. Add MCP Server to Cursor

Open Cursor Settings → Features → Model Context Protocol (MCP)

Or directly edit your Cursor config file:
- **macOS**: `~/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- **Linux**: `~/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- **Windows**: `%APPDATA%\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`

Add this configuration:

```json
{
  "mcpServers": {
    "gtd-unified-system": {
      "command": "python3",
      "args": [
        "/Users/abby/code/dotfiles/mcp/gtd_mcp_server.py"
      ],
      "env": {
        "GTD_USER_NAME": "Abby",
        "GTD_DEEP_MODEL_URL": "http://gpt-oss-20b:8080/v1/chat/completions",
        "GTD_DEEP_MODEL_NAME": "gpt-oss-20b",
        "GTD_RABBITMQ_URL": "amqp://localhost:5672",
        "GTD_RABBITMQ_QUEUE": "gtd_deep_analysis"
      }
    }
  }
}
```

### 2. Update Paths

Replace `/Users/abby/code/dotfiles/mcp/gtd_mcp_server.py` with your actual path:

```bash
# Find your path
echo "$(cd ~/code/dotfiles && pwd)/mcp/gtd_mcp_server.py"
```

### 3. Verify Setup

1. Restart Cursor
2. Check that MCP server is connected (should see in status)
3. Try asking: "What pending task suggestions do I have?"
4. The AI should be able to use the MCP tools

## Environment Variables

### Required

- `GTD_USER_NAME`: Your name (used in prompts)

### Optional (for deep analysis)

- `GTD_DEEP_MODEL_URL`: URL for GPT-OSS 20b model
- `GTD_DEEP_MODEL_NAME`: Model name for deep analysis
- `GTD_RABBITMQ_URL`: RabbitMQ connection (if using background queue)
- `GTD_RABBITMQ_QUEUE`: Queue name (default: "gtd_deep_analysis")

### Automatic (from config files)

The MCP server automatically reads:
- `~/.gtd_config` or `zsh/.gtd_config` for:
  - `GTD_BASE_DIR`: Base directory for GTD files
  - `LM_STUDIO_URL`: Fast model URL (Gemma 1b)
  - `LM_STUDIO_CHAT_MODEL`: Fast model name
  - `GTD_USER_NAME`: Your name

## Testing

### Test MCP Server Directly

```bash
python3 /Users/abby/code/dotfiles/mcp/gtd_mcp_server.py
```

If it starts without errors, it's working!

### Test in Cursor

Ask the AI:

1. "Suggest tasks from this text: 'I need to finish the report and schedule a meeting'"
2. "What pending suggestions do I have?"
3. "Create a task: Review the PR"

## Troubleshooting

### Server Not Starting

1. Check Python path: `which python3`
2. Check dependencies: `pip3 list | grep mcp`
3. Check script is executable: `ls -l mcp/gtd_mcp_server.py`

### Tools Not Available

1. Restart Cursor completely
2. Check MCP server is running (status indicator)
3. Check logs in Cursor DevTools (Help → Toggle Developer Tools)

### Model Connection Issues

1. Ensure LM Studio is running
2. Check model is loaded in LM Studio
3. Verify URL in config: `LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"`

## Advanced Configuration

### Local Development

If developing locally, you might want to use a different config:

```json
{
  "mcpServers": {
    "gtd-unified-system": {
      "command": "python3",
      "args": [
        "/Users/abby/code/dotfiles/mcp/gtd_mcp_server.py"
      ],
      "env": {
        "GTD_USER_NAME": "Abby",
        "PYTHONPATH": "/Users/abby/code/dotfiles"
      }
    }
  }
}
```

### Production Setup

For production with Kubernetes/RabbitMQ:

```json
{
  "mcpServers": {
    "gtd-unified-system": {
      "command": "python3",
      "args": [
        "/app/mcp/gtd_mcp_server.py"
      ],
      "env": {
        "GTD_USER_NAME": "Abby",
        "GTD_DEEP_MODEL_URL": "http://gpt-oss-20b-service:8080/v1/chat/completions",
        "GTD_RABBITMQ_URL": "amqp://rabbitmq-service:5672"
      }
    }
  }
}
```

## Next Steps

1. ✅ Configure MCP server in Cursor
2. ✅ Test with simple commands
3. ✅ Set up auto-suggestions (optional)
4. ✅ Configure background worker (optional)

See `README.md` for full documentation.

