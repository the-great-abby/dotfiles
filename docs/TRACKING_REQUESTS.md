# Tracking Request Processing Status

When you see processing logs like `⏳ Polling for async request 9cfda0e3...`, you can track where the request is in the pipeline using these methods:

## Quick Method: Use gtd-request-status

The `gtd-request-status` tool can search for requests using partial IDs (like `9cfda0e3`):

```bash
# Search by partial Ollama Controller request ID (from logs)
gtd-request-status 9cfda0e3

# Or via wizard
gtd-wizard → 65 → 6 → (enter: 9cfda0e3)
```

The tool will:
1. Search advice result files for matching Ollama Controller request IDs
2. Check Ollama Controller queue status
3. Show where the request currently is

## Finding Full Request IDs

### Option 1: Check Advice Worker Logs

The advice worker logs show both IDs:
- **Advice Request ID**: Format `advice_YYYYMMDD_HHMMSS_PID` (e.g., `advice_20260103_093045_12345`)
- **Ollama Controller Request ID**: Full UUID format (e.g., `9cfda0e3-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

To find the full IDs:
```bash
# View recent logs
tail -f /tmp/advice-worker.log | grep -E "(Processing advice request|Polling for async request)"

# Or search for the partial ID
grep "9cfda0e3" /tmp/advice-worker.log
```

### Option 2: Search Advice Results Directory

If you know the approximate time, search the advice results:
```bash
# List recent result files
ls -lt ~/Documents/gtd/advice_results/*.json | head -10

# Search for Ollama request ID in result files
grep -l "9cfda0e3" ~/Documents/gtd/advice_results/*.json
```

### Option 3: Check RabbitMQ Queue Status

If the request is still queued:
```bash
# Via wizard
gtd-wizard → 17 → 11 (View RabbitMQ Queue Status)
```

## Understanding the Pipeline

The request goes through these stages:

1. **RabbitMQ Queue** (if using RabbitMQ)
   - Status: `gtd_advice` queue
   - Check: `gtd-wizard → 17 → 11`

2. **Advice Worker Processing**
   - Status: Worker picked up the request
   - Check: `grep "Processing advice request" /tmp/advice-worker.log`
   - Shows: Advice Request ID (e.g., `advice_20260103_093045_12345`)

3. **Ollama Controller Queue**
   - Status: Request submitted to Ollama Controller
   - Check: `gtd-request-status <ollama_request_id>`
   - Shows: Queue position, elapsed time, status

4. **Ollama Controller Processing**
   - Status: AI model is processing
   - Check: `gtd-request-status <ollama_request_id>`
   - Shows: Processing status, elapsed time

5. **Advice Worker Polling**
   - Status: Worker waiting for Ollama Controller response
   - Log: `⏳ Polling for async request <partial_id>...`
   - Shows: Partial Ollama Controller request ID

6. **Result Saved**
   - Status: Completed
   - Location: `~/Documents/gtd/advice_results/<advice_request_id>.json`
   - Check: `gtd-request-status <advice_request_id>`

## Example Workflow

1. You see in logs: `⏳ Polling for async request 9cfda0e3...`

2. Search for full ID:
   ```bash
   grep "9cfda0e3" /tmp/advice-worker.log | head -1
   ```

3. Check status:
   ```bash
   gtd-request-status 9cfda0e3
   # or if you found the full ID:
   gtd-request-status 9cfda0e3-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

4. The tool will show:
   - Current location (Ollama Controller queue, processing, or completed)
   - Queue position (if queued)
   - Elapsed time
   - Associated advice request ID (if completed)

## Tips

- **Partial IDs work**: The `gtd-request-status` tool can search using partial IDs
- **Check logs first**: The advice worker logs show both IDs together
- **Use wizard**: `gtd-wizard → 65 → 6` provides an easy interface
- **Monitor in real-time**: Use `tail -f /tmp/advice-worker.log` to watch progress
