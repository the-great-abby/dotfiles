# Quick Status Commands

## One Command to Check Everything

```bash
cd ~/code/dotfiles/mcp && ./gtd_mcp_status.sh
```

## Quick Checks

### Is LM Studio Running?
```bash
curl http://localhost:1234/v1/models
```

### Is MCP Server Working?
In Cursor, ask: "What pending suggestions do I have?"

### Is Background Worker Running?
```bash
cd ~/code/dotfiles/mcp && ./check_worker.sh
```

### How Many Suggestions Pending?
```bash
find ~/Documents/gtd/suggestions -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; | wc -l
```

### How Many Items in Queue?
```bash
wc -l ~/Documents/gtd/deep_analysis_queue.jsonl 2>/dev/null || echo "0"
```

### Latest Analysis Results?
```bash
ls -lt ~/Documents/gtd/deep_analysis_results/*.json 2>/dev/null | head -3
```

## Add to Your Shell

Add to `~/.zshrc`:

```bash
# GTD MCP Status Aliases
alias gtd-status='cd ~/code/dotfiles/mcp && ./gtd_mcp_status.sh'
alias gtd-worker='cd ~/code/dotfiles/mcp && ./check_worker.sh'
alias gtd-mcp='cd ~/code/dotfiles/mcp && ./check_mcp_cursor.sh'
```

Then just run:
```bash
gtd-status
```

