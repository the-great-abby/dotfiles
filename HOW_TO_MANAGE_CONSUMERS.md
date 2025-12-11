# How to Manage RabbitMQ Consumers (Workers)

## Understanding Consumers

**Consumers** are workers that connect to RabbitMQ and process messages from queues. If you see "Messages waiting: 4" but "Active consumers: 0", it means:
- Jobs are queued in RabbitMQ ✅
- But no workers are connected to process them ❌

## Why Workers Don't Connect

Common reasons:
1. **Worker started before RabbitMQ was available** - Falls back to file queue
2. **Port-forward not running** - Worker can't reach RabbitMQ
3. **Worker crashed** - Needs to be restarted
4. **Connection failed** - Worker silently fell back to file queue

## How to Connect Workers to RabbitMQ

### Method 1: Restart Workers (Easiest)

**Via Wizard:**
```
gtd-wizard
→ 17) System status
→ 3) Background Worker Status
→ 6) Restart All Workers (Reconnect to RabbitMQ)
```

**Via Command:**
```bash
# Stop workers
make worker-deep-stop
make worker-vector-stop

# Wait a moment
sleep 2

# Start workers (they'll connect to RabbitMQ if available)
make worker-deep-start
make worker-vector-start
```

**Via Helper Script:**
```bash
./bin/manage-rabbitmq-consumers
```

### Method 2: Check Current Status

**Check if workers are running:**
```bash
make worker-status
```

**Check RabbitMQ consumer status:**
```bash
make rabbitmq-status
```

Look for:
- ✅ **Active consumers: 1** - Worker is connected!
- ❌ **Active consumers: 0** - Worker not connected, needs restart

## Verification Steps

### Step 1: Ensure Port-Forward is Running

```bash
# Check if port-forward is active
nc -zv localhost 5672

# Or check process
ps aux | grep "kubectl port-forward.*5672"
```

If not running:
```bash
# Start port-forward
kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672 15672:15672 15692:15692

# Or use the wizard
gtd-wizard → 1) Configuration & Setup → 9) Setup RabbitMQ Connection → 2) Start Port-Forward
```

### Step 2: Ensure RabbitMQ is Enabled

Check config:
```bash
grep RABBITMQ_ENABLED ~/code/dotfiles/zsh/.gtd_config_database
```

Should show: `RABBITMQ_ENABLED="true"`

### Step 3: Restart Workers

```bash
# Stop existing workers
make worker-deep-stop
make worker-vector-stop

# Start them again (they'll connect to RabbitMQ)
make worker-deep-start
make worker-vector-start
```

### Step 4: Verify Connection

Wait 5-10 seconds, then check:
```bash
make rabbitmq-status
```

You should see:
```
Deep Analysis Queue:
   Messages waiting: X
   Active consumers: 1    ← This should be 1!
   🔄 Jobs being processed
```

## Troubleshooting

### Workers Won't Connect

**Check worker logs:**
```bash
tail -f /tmp/deep-worker.log
tail -f /tmp/vector-worker.log
```

Look for:
- `Waiting for messages on gtd_deep_analysis` - Connected to RabbitMQ ✅
- `Falling back to file queue...` - Not connected, using file queue ❌
- `Connection refused` - Port-forward not running ❌

**Common fixes:**

1. **Port-forward not running:**
   ```bash
   ./bin/setup_rabbitmq_local.sh
   ```

2. **Wrong RabbitMQ URL:**
   ```bash
   # Check config
   cat ~/code/dotfiles/zsh/.gtd_config_database | grep RABBITMQ
   
   # Should be: RABBITMQ_URL="amqp://localhost:5672"
   ```

3. **Worker using file queue:**
   - Restart the worker after RabbitMQ is available
   - Workers try RabbitMQ first, then fall back to file queue if it fails

### Messages Not Processing

**If messages are queued but not processing:**

1. **Check consumers:**
   ```bash
   make rabbitmq-status
   ```

2. **If consumers = 0:**
   - Restart workers (see Method 1 above)

3. **If consumers = 1 but messages not decreasing:**
   - Check worker logs for errors: `tail -f /tmp/deep-worker.log`
   - Verify LM Studio is running (for deep analysis)
   - Check if jobs are failing

## Quick Reference

### Check Status
```bash
make rabbitmq-status      # Queue and consumer status
make worker-status        # Worker process status
```

### Restart Workers
```bash
make worker-deep-stop     # Stop deep analysis worker
make worker-deep-start    # Start (connects to RabbitMQ)

make worker-vector-stop   # Stop vectorization worker
make worker-vector-start  # Start (connects to RabbitMQ)
```

### View Logs
```bash
tail -f /tmp/deep-worker.log      # Deep analysis worker
tail -f /tmp/vector-worker.log    # Vectorization worker
```

### Via Wizard
```
gtd-wizard
→ 17) System status
→ 3) Background Worker Status
→ 6) Restart All Workers (Reconnect to RabbitMQ)
```

## Best Practices

1. **Always check port-forward first** - Workers can't connect without it
2. **Restart workers after enabling RabbitMQ** - Existing workers won't reconnect automatically
3. **Monitor consumer count** - Should be 1+ when workers are active
4. **Check logs if stuck** - Logs show connection status and errors

## Summary

**To connect workers to RabbitMQ:**
1. ✅ Ensure port-forward is running
2. ✅ Ensure `RABBITMQ_ENABLED="true"`
3. ✅ Restart workers: `make worker-deep-stop && make worker-deep-start`
4. ✅ Verify: `make rabbitmq-status` should show "Active consumers: 1"
