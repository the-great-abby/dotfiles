# RabbitMQ Queue Monitoring Guide

## Quick Start

**View queue status:**
```bash
make rabbitmq-status
# or
gtd-rabbitmq-status
```

**Via Wizard:**
```
gtd-wizard → 17) System status → 3) Background Worker Status → 5) View RabbitMQ Queue Status
```

## What You'll See

The status command shows:

### For Each Queue (Deep Analysis & Vectorization):

1. **Messages Waiting**: Number of jobs queued but not yet processed
2. **Active Consumers**: Number of workers currently connected and processing
3. **Status Indicators**:
   - ✅ **Queue empty, worker waiting** - No jobs, worker ready
   - 🔄 **Jobs being processed** - Jobs in queue with workers active
   - ⚠️ **Messages queued but no consumers** - Jobs waiting, but no workers running!
   - ℹ️ **Queue empty, no workers** - No jobs, no workers connected

### File Queue Status (Fallback)

Also shows file queue status for cases where RabbitMQ isn't available.

## Understanding the Output

### Example: Healthy System
```
Deep Analysis Queue:
   Queue: gtd_deep_analysis
   Messages waiting: 0
   Active consumers: 1
   ✅ Queue empty, worker waiting for jobs
```

**Meaning:** Worker is connected and ready, no jobs queued.

### Example: Jobs Being Processed
```
Deep Analysis Queue:
   Queue: gtd_deep_analysis
   Messages waiting: 3
   Active consumers: 1
   🔄 Jobs being processed
```

**Meaning:** Worker is actively processing jobs from the queue.

### Example: Problem Detected
```
Deep Analysis Queue:
   Queue: gtd_deep_analysis
   Messages waiting: 5
   Active consumers: 0
   ⚠️  Warning: Messages queued but no consumers!
      Make sure the worker is running: make worker-deep-status
```

**Meaning:** Jobs are waiting but no worker is processing them. Start the worker!

## Common Scenarios

### Scenario 1: Just Queued a Job

After queuing a job:
```bash
make rabbitmq-status
```

Expected:
- Messages waiting: 1 (or more)
- Active consumers: 1 (if worker is running)
- Status: 🔄 Jobs being processed

### Scenario 2: Checking Worker Health

To verify workers are connected:
```bash
make rabbitmq-status
```

Look for:
- Active consumers > 0 (means workers are connected)
- If 0, check worker status: `make worker-status`

### Scenario 3: Queue Backed Up

If queue has many messages:
```
Messages waiting: 10
Active consumers: 1
```

**Options:**
1. Wait - worker will process them one by one
2. Start additional workers (if needed)
3. Check worker logs for errors: `tail -f /tmp/deep-worker.log`

## Troubleshooting

### No Messages Appearing in RabbitMQ

**Possible causes:**
1. Jobs going to file queue instead
   - Check: `wc -l ~/Documents/gtd/deep_analysis_queue.jsonl`
   - Reason: `RABBITMQ_ENABLED=false` or connection failed

2. RabbitMQ not accessible
   - Check: Is port-forward running?
   - Fix: `kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672`

3. Connection error
   - Check: `make rabbitmq-status` shows connection error
   - Verify: `RABBITMQ_URL` in `.gtd_config_database`

### Messages in Queue But Not Processing

**Symptoms:**
- Messages waiting: > 0
- Active consumers: 0

**Fix:**
1. Start the worker: `make worker-deep-start` or `make worker-vector-start`
2. Check worker logs: `tail -f /tmp/deep-worker.log`
3. Verify RabbitMQ connection in worker logs

### Worker Connected But Not Processing

**Symptoms:**
- Active consumers: 1
- Messages waiting: Not decreasing

**Check:**
1. Worker logs for errors: `tail -f /tmp/deep-worker.log`
2. LM Studio is running (for deep analysis)
3. Vector database is accessible (for vectorization)

## Monitoring During Processing

### Watch Queue in Real-Time

```bash
# Check every 5 seconds
watch -n 5 'gtd-rabbitmq-status'
```

### Watch Worker Logs

```bash
# Deep Analysis Worker
tail -f /tmp/deep-worker.log

# Vectorization Worker
tail -f /tmp/vector-worker.log
```

### Check Results

```bash
# Deep Analysis Results
ls -lt ~/Documents/gtd/deep_analysis_results/ | head -5

# Vectorization (check database)
# Results go directly to PostgreSQL
```

## Integration with Other Tools

### Via Makefile
```bash
make rabbitmq-status
```

### Via Wizard
```
gtd-wizard → 17 → 3 → 5
```

### Direct Command
```bash
gtd-rabbitmq-status
```

### In Scripts
```bash
# Check queue status programmatically
MESSAGES=$(gtd-rabbitmq-status 2>&1 | grep "Messages waiting" | awk '{print $NF}')
if [[ "$MESSAGES" -gt 10 ]]; then
    echo "Queue backed up! Consider scaling workers."
fi
```

## Best Practices

1. **Check before queuing large batches**
   - Ensure workers are running
   - Verify queue isn't already backed up

2. **Monitor during heavy workloads**
   - Use `watch` to monitor queue size
   - Check worker logs for errors

3. **Set up alerts** (optional)
   - Monitor queue size
   - Alert if consumers drop to 0
   - Alert if queue size exceeds threshold

4. **Regular health checks**
   - Run `make rabbitmq-status` periodically
   - Verify workers are connected
   - Check for stuck messages

## Related Commands

```bash
# Worker status
make worker-status

# Start/stop workers
make worker-deep-start
make worker-deep-stop
make worker-vector-start
make worker-vector-stop

# Test RabbitMQ connection
./bin/test_rabbitmq_connection.sh

# View worker logs
tail -f /tmp/deep-worker.log
tail -f /tmp/vector-worker.log
```
