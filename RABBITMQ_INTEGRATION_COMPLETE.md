# RabbitMQ Integration Complete ✅

## What's Been Integrated

### 1. ✅ Deep Analysis Queue (Already Working)
- **Status**: Fully integrated
- **Queue**: `gtd_deep_analysis`
- **Worker**: `mcp/gtd_deep_analysis_worker.py`
- **Usage**: Automatically used when queuing deep analysis tasks

### 2. ✅ Vectorization Queue (Newly Integrated)
- **Status**: Integrated and ready to use
- **Queue**: `gtd_vectorization`
- **Worker**: `mcp/gtd_vector_worker.py`
- **Queue Function**: `queue_vectorization()` in `gtd_vectorization.py`
- **Script**: Updated `bin/gtd-vectorize-content` to check `RABBITMQ_ENABLED`

## How It Works

### Vectorization Flow

1. **Content Created** → Scripts call `gtd-vectorize-content`
2. **Check Config** → If `RABBITMQ_ENABLED=true`, queue to RabbitMQ
3. **Queue Message** → Published to `gtd_vectorization` queue
4. **Worker Consumes** → `gtd_vector_worker.py` processes messages
5. **Vectorize** → Generates embeddings and stores in PostgreSQL

### Fallback Behavior

- If RabbitMQ unavailable → Falls back to file queue
- If `RABBITMQ_ENABLED=false` → Processes synchronously (original behavior)
- Always works, just uses different mechanisms

## Files Created/Modified

### New Files
- `mcp/gtd_vector_worker.py` - Vectorization worker
- `bin/gtd-vector-worker` - Worker startup script
- `bin/test_rabbitmq_connection.sh` - Connection testing
- `bin/setup_rabbitmq_local.sh` - Port-forward helper

### Modified Files
- `zsh/functions/gtd_vectorization.py` - Added `queue_vectorization()` function
- `bin/gtd-vectorize-content` - Added RabbitMQ check and async queuing
- `zsh/.gtd_config_database` - Added RabbitMQ credentials config
- `mcp/gtd_mcp_server.py` - Added credential support
- `mcp/gtd_deep_analysis_worker.py` - Added credential support
- `zsh/functions/gtd_vector_db.py` - Added credential support
- `bin/gtd-wizard-tools.sh` - Added RabbitMQ setup menu (option 9)

## Configuration

### Enable RabbitMQ for Vectorization

Edit `zsh/.gtd_config_database`:

```bash
# Enable RabbitMQ for async vectorization
RABBITMQ_ENABLED="true"  # Set to "true" to enable
RABBITMQ_URL="amqp://localhost:5672"
RABBITMQ_USER="guest"
RABBITMQ_PASS="guest"
RABBITMQ_VECTOR_QUEUE="gtd_vectorization"
```

### Port-Forward (for Kubernetes RabbitMQ)

```bash
# Start port-forward in separate terminal
./bin/setup_rabbitmq_local.sh

# Or manually:
kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672
```

## Usage

### Start Vectorization Worker

```bash
# Start worker (will use RabbitMQ if available, file queue otherwise)
gtd-vector-worker

# Process file queue only
gtd-vector-worker file
```

### Test Connection

```bash
# Test RabbitMQ connection and queue setup
./bin/test_rabbitmq_connection.sh
```

### Check Status (via Wizard)

```bash
gtd-wizard
# Go to: Configuration & Setup → 9) Setup RabbitMQ Connection
```

## Integration Points

### Already Integrated

The following scripts automatically call `gtd-vectorize-content`, which now respects `RABBITMQ_ENABLED`:

- ✅ `bin/gtd-task` - Queues tasks for vectorization
- ✅ `bin/gtd-wizard-org.sh` - Queues projects for vectorization
- ⚠️ `bin/gtd-daily-log` - May need to be checked/updated

### To Queue Content Programmatically

```python
from zsh.functions.gtd_vectorization import queue_vectorization

# Queue for async processing
status = queue_vectorization(
    content_type="task",
    content_id="task-123",
    content_text="Task description...",
    metadata={"tags": ["work"]}
)

# Status will be: "queued_to_rabbitmq", "queued_to_file", or "queue_failed"
```

## Worker Management

### Start Worker (Foreground)

```bash
gtd-vector-worker
```

### Start Worker (Background)

```bash
# Using nohup
nohup gtd-vector-worker > /tmp/vector-worker.log 2>&1 &

# Or using tmux/screen
tmux new -s vector-worker
gtd-vector-worker
# Detach with Ctrl+B then D
```

### Stop Worker

```bash
# Find process
ps aux | grep gtd_vector_worker

# Kill process
kill <PID>
```

### Check Worker Status

```bash
# Check if worker is running
ps aux | grep gtd_vector_worker

# Check queue messages (requires port-forward)
kubectl exec -n rabbitmq-system <rabbitmq-pod> -- rabbitmqctl list_queues name messages
```

## Testing

### Test End-to-End

1. **Enable RabbitMQ**:
   ```bash
   # Edit zsh/.gtd_config_database
   RABBITMQ_ENABLED="true"
   ```

2. **Start Port-Forward**:
   ```bash
   ./bin/setup_rabbitmq_local.sh
   ```

3. **Start Worker**:
   ```bash
   gtd-vector-worker
   ```

4. **Create Content**:
   ```bash
   # This will queue for vectorization
   gtd-task "Test task for vectorization"
   ```

5. **Verify**:
   - Check worker output for processing messages
   - Check database for new vectors
   - Check queue status

## Next Steps

### Optional Enhancements

1. **Worker Monitoring**:
   - Add worker status endpoint
   - Create management dashboard
   - Add health checks

2. **Daily Log Integration**:
   - Verify `gtd-daily-log` calls vectorization
   - Add if missing

3. **Queue Management**:
   - Add retry logic with exponential backoff
   - Add dead letter queue for failed messages
   - Add queue monitoring/metrics

4. **Performance**:
   - Batch processing for multiple items
   - Parallel workers for scaling
   - Connection pooling

## Troubleshooting

### Worker Not Processing

1. Check RabbitMQ connection:
   ```bash
   ./bin/test_rabbitmq_connection.sh
   ```

2. Check worker is running:
   ```bash
   ps aux | grep gtd_vector_worker
   ```

3. Check queue has messages:
   - RabbitMQ: Check via kubectl/management UI
   - File queue: Check `~/Documents/gtd/vectorization_queue.jsonl`

### Queue Messages Not Processing

1. Check worker logs for errors
2. Verify database connection
3. Verify embedding model is accessible
4. Check file permissions

### Fallback to File Queue

This is expected if:
- RabbitMQ is not running
- `RABBITMQ_ENABLED=false`
- Connection fails

The system will automatically fall back to file queue, which works but processes synchronously when the worker runs.
