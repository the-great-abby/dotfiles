# Status Checking Guide

Quick reference for checking the status of your GTD MCP system.

## Quick Status Check

Run the comprehensive status checker:

```bash
cd ~/code/dotfiles/mcp
./gtd_mcp_status.sh
```

This checks:
- ✅ LM Studio (fast model)
- ✅ Deep model
- ✅ MCP server
- ✅ Python dependencies
- ✅ Background worker (local)
- ✅ Background worker (Kubernetes)
- ✅ RabbitMQ
- ✅ Analysis results
- ✅ Pending suggestions

## Individual Checks

### 1. Check MCP Server (in Cursor)

**In Cursor:**
- Look for MCP status indicator in the status bar
- Try asking the AI: "What pending suggestions do I have?"
- Check DevTools: Help → Toggle Developer Tools → Console (look for MCP logs)

**From Command Line:**
```bash
cd ~/code/dotfiles/mcp
./check_mcp_cursor.sh
```

### 2. Check Background Worker

**Kubernetes:**
```bash
kubectl get deployment gtd-deep-analysis-worker
kubectl logs -l app=gtd-deep-analysis-worker --tail=20
```

**Local:**
```bash
ps aux | grep gtd_deep_analysis_worker
```

**Comprehensive Check:**
```bash
cd ~/code/dotfiles/mcp
./check_worker.sh
```

### 3. Check LM Studio

```bash
curl http://localhost:1234/v1/models
```

Or check in LM Studio GUI - it should show which models are loaded.

### 4. Check Queue Status

**File Queue:**
```bash
wc -l ~/Documents/gtd/deep_analysis_queue.jsonl
tail ~/Documents/gtd/deep_analysis_queue.jsonl
```

**RabbitMQ:**
```bash
rabbitmqctl list_queues name messages | grep gtd
```

### 5. Check Results

```bash
ls -lt ~/Documents/gtd/deep_analysis_results/ | head
```

### 6. Check Pending Suggestions

```bash
find ~/Documents/gtd/suggestions -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; | wc -l
```

Or use the wizard:
```bash
gtd-wizard
# Choose: 23 → 2
```

## Common Issues & Solutions

### MCP Server Not Working

1. **Check Cursor configuration:**
   - Settings → MCP → Verify server config
   - Check path to `gtd_mcp_server.py` is correct

2. **Check Python:**
   ```bash
   python3 --version
   python3 -c "import mcp"
   ```

3. **Test server directly:**
   ```bash
   python3 ~/code/dotfiles/mcp/gtd_mcp_server.py
   ```
   (Should start without errors)

### Background Worker Not Processing

1. **Check if running:**
   ```bash
   ./check_worker.sh
   ```

2. **Check logs:**
   - Kubernetes: `kubectl logs -l app=gtd-deep-analysis-worker -f`
   - Local: Check terminal where you started it

3. **Check queue:**
   ```bash
   tail ~/Documents/gtd/deep_analysis_queue.jsonl
   ```

4. **Restart worker:**
   - Kubernetes: `kubectl rollout restart deployment/gtd-deep-analysis-worker`
   - Local: Stop and restart the process

### LM Studio Not Responding

1. **Check if running:**
   ```bash
   curl http://localhost:1234/v1/models
   ```

2. **Check LM Studio:**
   - Open LM Studio
   - Ensure local server is started
   - Ensure a model is loaded

3. **Check port:**
   - Default: 1234
   - Can be changed in LM Studio settings

## Monitoring Scripts

Add to your `.zshrc` for quick access:

```bash
alias gtd-status='cd ~/code/dotfiles/mcp && ./gtd_mcp_status.sh'
alias gtd-worker-check='cd ~/code/dotfiles/mcp && ./check_worker.sh'
alias gtd-mcp-check='cd ~/code/dotfiles/mcp && ./check_mcp_cursor.sh'
```

Then run:
```bash
gtd-status
```

## Continuous Monitoring

### Watch Queue (Local)
```bash
watch -n 5 'wc -l ~/Documents/gtd/deep_analysis_queue.jsonl'
```

### Watch Worker Logs (Kubernetes)
```bash
kubectl logs -l app=gtd-deep-analysis-worker -f
```

### Watch Results
```bash
watch -n 10 'ls -lt ~/Documents/gtd/deep_analysis_results/ | head -5'
```

## Status Dashboard

For a quick visual overview, create a simple dashboard:

```bash
#!/bin/bash
# gtd-dashboard.sh
clear
echo "=== GTD MCP Dashboard ==="
echo ""
./gtd_mcp_status.sh | head -40
echo ""
echo "Press Ctrl+C to exit, or wait 10 seconds for refresh..."
sleep 10
```

Run with: `watch -n 10 ./gtd-dashboard.sh`

