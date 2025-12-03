# Quick Setup Guide

Get the MCP system up and running quickly!

## 1. Install Dependencies

```bash
cd mcp
./setup.sh
```

This installs:
- `mcp` Python package
- `pika` for RabbitMQ (optional)

## 2. Configure Cursor

Run the setup script:

```bash
cd .cursor
./setup_cursor_mcp.sh
```

This will:
- Detect your OS
- Copy MCP config to Cursor settings
- Update paths automatically
- Verify installation

**Manual setup:**

1. Copy config to Cursor settings:
   ```bash
   # macOS
   mkdir -p ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/
   cp .cursor/mcp_config.json ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
   ```

2. Update paths in the config file

3. Restart Cursor

## 3. Verify Setup

1. Restart Cursor
2. Check MCP status indicator (should show "gtd-unified-system")
3. Ask the AI: "What MCP tools are available?"

## 4. (Optional) Deploy Background Worker

If you want deep analysis capabilities:

```bash
gtd-wizard
# Choose: 23) 🤖 AI Suggestions & MCP Tools
# Choose: 10) 🚀 Deploy Worker to Kubernetes
```

Or use the script directly:

```bash
cd mcp
./deploy.sh build
./deploy.sh deploy
```

## That's It!

You're ready to use the MCP system. Try:

- "Suggest tasks from this text: 'I need to finish the report'"
- "What pending suggestions do I have?"
- "List my tasks for computer context"

## Troubleshooting

### MCP Server Not Connecting

1. Check dependencies: `pip3 list | grep mcp`
2. Test server: `python3 mcp/gtd_mcp_server.py`
3. Check Cursor logs: Help → Toggle Developer Tools → Console

### LM Studio Not Working

1. Start LM Studio
2. Load a model
3. Check URL: `curl http://localhost:1234/v1/models`

See `mcp/README.md` for full documentation.

