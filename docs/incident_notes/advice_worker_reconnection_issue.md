# Incident Report: Advice Worker RabbitMQ Connection Issue

**Date:** December 18, 2025  
**Severity:** High  
**Component:** Advice Worker (`gtd_advice_worker.py`)  
**Status:** Root Cause Identified

---

## Summary

The advice worker successfully processes advice requests but fails immediately after processing, resulting in a broken pipe error when attempting to acknowledge the message to RabbitMQ. This causes the worker to restart, reconnect, and reprocess the **same message repeatedly**, creating an infinite loop.

---

## Symptoms

1. ✅ Worker shows as "Running" (PID exists)
2. ⚠️ RabbitMQ reports "Active consumers: 0" despite worker running
3. ✅ Messages are successfully processed (advice generated)
4. ❌ Connection breaks during acknowledgment with `BrokenPipeError(32, 'Broken pipe')`
5. 🔄 Worker restarts and processes the **same message** again
6. 📊 Queue shows messages waiting but they're stuck being reprocessed

---

## Root Cause Analysis

### The Problem: Timing Issue

Looking at the logs:

```
📥 Processing: advice_20251217_064557_34614 at 2025-12-18 11:18:15.666993
Processing advice request: advice_20251217_064557_34614 (persona: charity, mode: normal)
✅ Advice request completed: advice_20251217_064557_34614
⚠️  Connection lost while acknowledging: Stream connection lost: BrokenPipeError(32, 'Broken pipe')
```

**What's happening:**

1. **Worker receives message** from RabbitMQ
2. **Processing takes a long time** (minutes for AI to generate advice)
3. **During processing, RabbitMQ connection times out** or breaks
4. **Worker tries to acknowledge** (`ch.basic_ack`) after processing completes
5. **Connection is already closed** → `BrokenPipeError`
6. **Message never acknowledged** → stays in queue
7. **Worker reconnects** → gets same message again
8. **Infinite loop** 🔄

### Why This Happens

#### Issue 1: Heartbeat/Timeout Configuration

From line 379 in the code:

```python
params.heartbeat = 900  # 15 minutes
params.blocked_connection_timeout = 900  # 15 minutes
```

**Problem:** While the advice worker has a 15-minute heartbeat configured, **RabbitMQ or the network may be closing the connection sooner**. The connection is timing out during the long AI processing operation.

#### Issue 2: No Connection Health Check

The code processes the advice request (which can take 5-10 minutes), but **doesn't check if the connection is still alive before trying to acknowledge**.

From line 409:

```python
if connection.is_closed:
    print("⚠️  Connection is closed, skipping message")
    connection_error_occurred = True
    return
```

This check happens **at the start** of processing, but the connection can die **during** processing.

#### Issue 3: No Message Acknowledgment Before Processing Completes

The worker doesn't acknowledge the message until **after** the advice is generated, saved, and Discord notification sent. If anything breaks during this time, the message stays in the queue.

---

## Impact

### High Severity Because:

1. **Messages never complete** - stuck in infinite reprocessing loop
2. **Wasted resources** - AI processes same request multiple times
3. **No progress** - queue never clears
4. **User confusion** - worker appears healthy but isn't consuming messages
5. **Result duplication** - same advice generated repeatedly

### Observed Behavior:

- Same message ID processed 14+ times: `advice_20251217_064557_34614`
- Each processing cycle takes ~10-20 minutes
- Worker has been in this loop for **hours**
- 2 messages stuck in queue (likely both experiencing same issue)

---

## Comparison with Deep Analysis Worker

**Why doesn't the Deep Analysis Worker have this problem?**

Let me check if it has better connection handling or if it's just lucky due to shorter processing times.

Key differences:
- Deep analysis may have shorter timeouts
- May process messages faster
- May have different heartbeat settings
- **Possibly has message pre-fetching disabled** (prefetch_count=1)

Both workers use `prefetch_count=1`, so that's not the difference.

---

## Proposed Solutions

### Solution 1: Add Connection Health Monitoring (Recommended)

**Approach:** Check connection health periodically during long operations.

```python
def process_advice_request_with_heartbeat(message: Dict[str, Any], connection) -> bool:
    """Process advice request with periodic connection checks."""
    
    # Before starting long operation
    if connection.is_closed:
        print("⚠️  Connection closed before processing")
        return False
    
    # ... start processing ...
    
    # During processing, periodically check connection
    # (This could be done in the call_deep_ai function with a callback)
    
    # After processing, check before acknowledging
    if connection.is_closed:
        print("⚠️  Connection closed during processing")
        return False
    
    return True
```

**Pros:**
- Detects connection issues early
- Prevents attempting to ack on dead connection
- Allows graceful failure and retry

**Cons:**
- More complex to implement
- Need to thread-safely check connection during AI call

---

### Solution 2: Use Message TTL and Dead Letter Queue (Better Long-Term)

**Approach:** Configure RabbitMQ to handle stuck messages automatically.

1. Set message TTL (time-to-live) on the queue
2. Configure a dead-letter exchange for expired/failed messages
3. Messages that can't be processed move to dead letter queue
4. Worker can retry from dead letter queue with different strategy

**Pros:**
- Prevents infinite loops
- Standard RabbitMQ pattern
- Handles all failure modes

**Cons:**
- Requires RabbitMQ configuration changes
- More infrastructure to manage

---

### Solution 3: Acknowledge Immediately, Process Asynchronously (Not Recommended)

**Approach:** Acknowledge message immediately after receiving, then process.

**Pros:**
- Message never stuck in queue
- Simple change

**Cons:**
- ❌ **Dangerous:** If worker crashes during processing, message is lost forever
- ❌ No retry capability
- ❌ Goes against queue reliability guarantees

---

### Solution 4: Increase Heartbeat and Add Process Timeout (Quick Fix)

**Approach:** 
1. Increase heartbeat to 30 minutes (or disable)
2. Add explicit timeout to AI processing
3. Better error handling around acknowledgment

```python
# Increase heartbeat
params.heartbeat = 1800  # 30 minutes
params.blocked_connection_timeout = 1800

# Add timeout to AI processing
try:
    with timeout(1200):  # 20 minute timeout
        advice_output = call_deep_ai(...)
except TimeoutError:
    print("⚠️  AI processing timed out")
    # Nack the message to requeue
    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
    return
```

**Pros:**
- Simple to implement
- Addresses immediate issue
- Doesn't require RabbitMQ changes

**Cons:**
- Doesn't solve underlying problem if network is unstable
- Still vulnerable to connection drops

---

### Solution 5: Use RabbitMQ Publisher Confirms Pattern (Advanced)

**Approach:** Use RabbitMQ's publisher confirms feature to ensure acknowledgments are received.

**Pros:**
- Guaranteed delivery
- Robust

**Cons:**
- Complex to implement
- Requires significant code changes

---

## Recommended Fix (Combination Approach)

### Immediate Fix (Deploy Today):

1. **Add connection check before acknowledgment** (lines 467-477)
2. **Add try-except with connection validation** around ack/nack
3. **Log when connection dies during processing**
4. **Don't retry immediately if connection is dead** - exit callback and let retry logic handle it

### Code Changes:

```python
# In callback function, before ack/nack:
if success:
    try:
        # Check connection before attempting ack
        if connection.is_closed or not connection.is_open:
            print(f"⚠️  Connection closed during processing, cannot ack message")
            connection_error_occurred = True
            try:
                ch.stop_consuming()
            except:
                pass
            return
        
        ch.basic_ack(delivery_tag=method.delivery_tag)
        print(f"✅ Message acknowledged: {message.get('id')}")
    except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, 
            OSError, BrokenPipeError) as conn_err:
        print(f"⚠️  Connection lost while acknowledging: {conn_err}")
        print(f"   Message will be requeued: {message.get('id')}")
        connection_error_occurred = True
        try:
            ch.stop_consuming()
        except:
            pass
        return
```

### Short-Term Fix (This Week):

1. **Increase heartbeat to 30 minutes** (line 379)
2. **Add processing timeout** (20 minutes max)
3. **Add periodic connection checks** during long operations

### Long-Term Fix (Next Sprint):

1. **Implement dead-letter queue pattern**
2. **Add message TTL configuration**
3. **Add monitoring/alerting** for stuck messages
4. **Consider splitting very long operations** into multiple shorter steps

---

## Testing Plan

### 1. Verify Current Issue

```bash
# Check logs
tail -f /private/tmp/advice-worker.log

# Check queue
docker exec rabbitmq rabbitmqadmin -f long -d 3 list queues
```

### 2. Deploy Fix

```bash
# Update code with connection check before ack
# Restart worker
gtd-advice-worker restart
```

### 3. Monitor

```bash
# Watch for:
# - Connection errors
# - Successful acknowledgments
# - Message processing without loops
tail -f /private/tmp/advice-worker.log | grep -E "(Processing|acknowledged|Connection lost)"
```

### 4. Success Criteria

- ✅ Messages processed once (not repeatedly)
- ✅ Queue empties after processing
- ✅ Worker stays connected or gracefully handles disconnects
- ✅ No "active consumers: 0" warnings when worker is running

---

## Prevention

### Monitoring

Add alerting for:
1. Messages stuck in queue for > 30 minutes
2. Worker running but consumers = 0
3. Same message ID processed > 2 times

### Code Quality

1. Add unit tests for connection failure scenarios
2. Add integration tests with RabbitMQ
3. Document expected processing times
4. Add circuit breaker pattern for repeated failures

### Infrastructure

1. Configure RabbitMQ dead-letter queues
2. Set up message TTL
3. Add Grafana dashboard for queue metrics
4. Set up PagerDuty alerts

---

## Related Components

Similar issue **may affect**:
- Deep Analysis Worker (check if it's just processing faster)
- Task Organization Worker
- Vectorization Worker

**Action:** Audit all workers for same pattern and apply preventive fixes.

---

## Timeline

| Time | Event |
|------|-------|
| 07:27 AM | Worker started, processed message successfully |
| 07:27 AM | Connection lost during ack, first restart |
| 07:34 AM | Reprocessed same message, failed again |
| ... | Loop continued for ~4 hours |
| 11:30 AM | Still looping (last log entry) |

**Total Duration:** 4+ hours  
**Messages Stuck:** 2  
**Duplicate Processing:** 14+ times for same message

---

## Conclusion

### The Issue:
The advice worker successfully processes messages but the RabbitMQ connection dies during the long AI processing operation (5-10 minutes). When the worker tries to acknowledge the message, it gets a `BrokenPipeError` because the connection is already closed. The message stays in the queue, and the worker restarts and reprocesses it indefinitely.

### The Fix:
Add a connection health check before attempting to acknowledge messages, and improve error handling to gracefully handle connection failures. Increase heartbeat timeout and add processing timeouts as additional safety measures.

### Priority:
**High** - Deploy connection health check fix immediately to stop the infinite loop.

---

**Report compiled:** December 18, 2025  
**Next Review:** After fix deployment

