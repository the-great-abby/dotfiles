# GTD MCP Server - Quick Start

Get up and running with the GTD MCP server in 5 minutes!

## Prerequisites

1. ✅ Python 3.8+ installed
2. ✅ LM Studio running with Gemma 1b model loaded
3. ✅ Your GTD system already set up (tasks, projects, etc.)

## Installation

```bash
cd ~/code/dotfiles/mcp
./setup.sh
```

## Configure Cursor

1. Open Cursor Settings → MCP
2. Add this server configuration (see `CURSOR_MCP_CONFIG.md` for details):

```json
{
  "mcpServers": {
    "gtd-unified-system": {
      "command": "python3",
      "args": ["/Users/abby/code/dotfiles/mcp/gtd_mcp_server.py"]
    }
  }
}
```

3. Restart Cursor

## Test It Works

In Cursor, ask the AI:

```
Suggest tasks from this text: "I need to finish the quarterly report by Friday and schedule a team meeting"
```

The AI should:
1. Analyze the text
2. Generate task suggestions
3. Show you the results

## Quick Examples

### Get Pending Suggestions

```
What pending task suggestions do I have?
```

### Create a Task

```
Create a task called "Review the PR" with high priority
```

### Analyze Log Entry

The auto-suggestion system can analyze your daily logs:

```bash
python3 mcp/gtd_auto_suggest.py entry "Just finished a great workout, feeling energized!"
```

## Optional: Background Analysis

For deeper analysis (weekly reviews, energy patterns), set up the background worker:

```bash
# Option 1: File-based queue (simple)
watch -n 60 'python3 mcp/gtd_deep_analysis_worker.py file'

# Option 2: RabbitMQ (production)
# See README.md for Kubernetes/RabbitMQ setup
```

## Troubleshooting

**MCP server not starting?**
- Check Python: `python3 --version`
- Check dependencies: `pip3 install -r mcp/requirements.txt`
- Check LM Studio is running

**Tools not available?**
- Restart Cursor
- Check MCP status indicator
- Verify config file path is correct

**Need more help?**
- See `README.md` for full documentation
- See `CURSOR_MCP_CONFIG.md` for detailed configuration

## What's Next?

1. ✅ Try suggesting tasks from your notes
2. ✅ Review pending suggestions regularly
3. ✅ Set up auto-suggestions for daily logs (optional)
4. ✅ Configure background worker for deep analysis (optional)

Enjoy your AI-powered GTD system! 🚀

