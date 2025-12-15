# Background Worker Status Checking

## Overview

The GTD system uses background workers to process deep analysis tasks (weekly reviews, energy analysis, connections, insights) asynchronously. This guide shows you how to check if the worker is running and actively processing jobs.

## Quick Status Check

### Command Line

Run the dedicated status command:

```bash
gtd-worker-status
```

This shows:
- ✅ **Worker Process**: Whether the worker is running, PID, CPU/memory usage
- 📊 **Queue Status**: How many items are waiting to be processed
- 🔄 **Recent Activity**: Latest results and when they were created
- ☸️ **Kubernetes**: Status if deployed to Kubernetes
- 🐰 **RabbitMQ**: Queue status if using RabbitMQ

### Example Output

```
⚙️  Background Worker Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Worker Process:
  ✅ Running (PID: 12345)
    CPU: 2.5% | Memory: 1.2% | Runtime: 02:15:30
    🔄 Actively processing

Queue Status:
  ✅ Queue empty

Recent Activity:
  ✅ Latest result: analysis_2025-01-15_14-30-00.json
    Time: 2025-01-15 14:30:00
    🔄 Active (5m ago)
```

## MCP System Access

Yes! The worker status is accessible through the MCP system. You can ask the AI in Cursor:

### Ask the AI

```
"What's the status of the background worker?"
"Is the background worker processing anything?"
"Check if the background worker is running"
```

The AI will use the `get_worker_status` MCP tool to check:
- Worker process status
- Queue count
- Recent activity
- RabbitMQ status (if configured)

### MCP Tool

The tool is available as: `get_worker_status`

It returns JSON with:
```json
{
  "worker_running": true,
  "worker_pid": 12345,
  "worker_cpu": 2.5,
  "worker_memory": 1.2,
  "queue_count": 0,
  "queue_file": "/Users/abby/Documents/gtd/deep_analysis_queue.jsonl",
  "recent_activity": {
    "latest_result": "analysis_2025-01-15_14-30-00.json",
    "timestamp": "2025-01-15T14:30:00"
  },
  "rabbitmq_available": false
}
```

## Other Status Methods

### 1. Via Wizard

```bash
gtd-wizard
# Choose: Status & Health Checks → Background Worker Status
```

### 2. Comprehensive Status

```bash
cd ~/code/dotfiles/mcp
./gtd_mcp_status.sh
```

This checks everything:
- LM Studio
- MCP Server
- Background Worker
- Queue Status
- Results
- Pending Suggestions

### 3. Quick Checks

**Is worker running?**
```bash
pgrep -f gtd_deep_analysis_worker.py
```

**Queue count:**
```bash
wc -l ~/Documents/gtd/deep_analysis_queue.jsonl
```

**Recent results:**
```bash
ls -lt ~/Documents/gtd/deep_analysis_results/ | head -5
```

## Understanding the Status

### Worker Running + Queue Empty
✅ **Good**: Worker is ready and waiting for new jobs

### Worker Running + Queue Has Items
⚠️ **Processing**: Worker is actively processing or items are queued

### Worker Not Running + Queue Has Items
❌ **Problem**: Worker needs to be started

### Worker Running + No Recent Activity
⏸️ **Idle**: Worker is running but hasn't processed anything recently

## Starting the Worker

### Local Worker

```bash
cd ~/code/dotfiles/mcp
python3 gtd_deep_analysis_worker.py file
```

This starts a local worker that processes jobs from the file queue.

### Kubernetes Worker

If deployed to Kubernetes:
```bash
kubectl get deployment gtd-deep-analysis-worker
kubectl logs -l app=gtd-deep-analysis-worker -f
```

## Queue Types

### File Queue (Default)

Jobs are written to: `~/Documents/gtd/deep_analysis_queue.jsonl`

Each line is a JSON object with the job details.

### RabbitMQ Queue (Optional)

If RabbitMQ is configured, jobs go to the `gtd_deep_analysis` queue.

Check status:
```bash
rabbitmqctl list_queues name messages | grep gtd
```

## What Gets Queued?

These operations queue jobs for background processing:

1. **Weekly Review** (`weekly_review` MCP tool)
2. **Energy Analysis** (`analyze_energy` MCP tool)
3. **Find Connections** (`find_connections` MCP tool)
4. **Generate Insights** (`generate_insights` MCP tool)

All use the deep model (GPT-OSS 20b) for comprehensive analysis.

## Monitoring

### Watch Queue Size

```bash
watch -n 5 'wc -l ~/Documents/gtd/deep_analysis_queue.jsonl'
```

### Watch Worker Process

```bash
watch -n 5 'ps aux | grep gtd_deep_analysis_worker'
```

### Watch Results

```bash
watch -n 10 'ls -lt ~/Documents/gtd/deep_analysis_results/ | head -5'
```

## Troubleshooting

### Worker Not Processing

1. **Check if running:**
   ```bash
   gtd-worker-status
   ```

2. **Check logs:**
   - Local: Check terminal where worker was started
   - Kubernetes: `kubectl logs -l app=gtd-deep-analysis-worker -f`

3. **Check LM Studio:**
   ```bash
   curl http://localhost:1234/v1/models
   ```
   Worker needs LM Studio running with a model loaded.

4. **Restart worker:**
   - Local: Stop and restart
   - Kubernetes: `kubectl rollout restart deployment/gtd-deep-analysis-worker`

### Queue Not Empty

If queue has items but worker isn't processing:

1. Check worker is running: `gtd-worker-status`
2. Check worker logs for errors
3. Verify LM Studio is accessible
4. Check file permissions on queue file

### No Recent Activity

If worker is running but no recent results:

1. Check if there are jobs in the queue
2. Verify LM Studio is responding
3. Check worker logs for errors
4. Ensure results directory is writable

## Integration

The worker status is integrated into:

- ✅ **MCP System**: Ask AI about worker status
- ✅ **gtd-wizard**: Status menu option
- ✅ **gtd-worker-status**: Dedicated command
- ✅ **gtd_mcp_status.sh**: Comprehensive status script

## Summary

**Quick Check:**
```bash
gtd-worker-status
```

**Via AI (Cursor):**
```
"Is the background worker doing anything?"
```

**Comprehensive:**
```bash
cd ~/code/dotfiles/mcp && ./gtd_mcp_status.sh
```

The background worker status is fully accessible through the MCP system, so you can ask the AI in Cursor about it anytime!

