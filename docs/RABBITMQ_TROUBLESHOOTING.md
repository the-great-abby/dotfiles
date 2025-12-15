# RabbitMQ Connection Troubleshooting

## Connection Reset Issues

If you're seeing "Connection reset by peer" errors in port-forward:

### Normal Behavior

**Connection resets are normal** when:
- Connections are opened and closed quickly (normal AMQP behavior)
- Clients disconnect after completing their work
- RabbitMQ cleans up idle connections

These reset messages in port-forward logs are **not errors** - they're informational.

### Actual Problems

**Connection resets indicate a real issue when:**
- Port-forward fails completely and stops
- RabbitMQ pod is restarting frequently
- You can't connect at all

## Diagnosing Issues

### Check RabbitMQ Pod Status

```bash
# Check if pod is running and healthy
kubectl get pods -n rabbitmq-system

# Check restart count (should be low/stable)
kubectl get pods -n rabbitmq-system -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}'

# Check pod events
kubectl describe pod -n rabbitmq-system <pod-name>
```

### Check RabbitMQ Health

```bash
# Check RabbitMQ status inside the pod
kubectl exec -n rabbitmq-system <pod-name> -- rabbitmqctl status

# Check queue status
kubectl exec -n rabbitmq-system <pod-name> -- rabbitmqctl list_queues
```

### Monitor Port-Forward

```bash
# Watch port-forward logs for patterns
kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672 15672:15672 15692:15692

# If you see frequent resets, check RabbitMQ pod status in another terminal
kubectl get pods -n rabbitmq-system -w
```

## Common Issues

### Issue 1: Pod Restarting

**Symptoms:**
- High restart count
- Port-forward fails repeatedly
- Connection drops frequently

**Fix:**
```bash
# Check pod logs
kubectl logs -n rabbitmq-system <pod-name> --tail=50

# Check pod events for errors
kubectl describe pod -n rabbitmq-system <pod-name>

# Common causes:
# - Memory limits too low (check with: kubectl top pod -n rabbitmq-system <pod-name>)
# - Liveness probe failing
# - Storage issues (check PVC status)
```

### Issue 2: Storage Issues

**Symptoms:**
- PVC in Pending state
- Pod can't start or keeps restarting
- "storageclass not found" errors

**Check:**
```bash
# Check PVC status
kubectl get pvc -n rabbitmq-system

# Check storage class
kubectl get storageclass

# If PVC is pending, you may need to:
# 1. Create the storage class
# 2. Update the PVC to use an existing storage class
# 3. Use ephemeral storage (not recommended for production)
```

### Issue 3: Port-Forward Instability

**Symptoms:**
- Port-forward disconnects frequently
- "lost connection to pod" errors
- Need to restart port-forward often

**Solutions:**

1. **Use the enhanced setup script** (includes auto-retry):
   ```bash
   ./bin/setup_rabbitmq_local.sh
   ```

2. **Run port-forward in tmux/screen** for stability:
   ```bash
   tmux new -s rabbitmq-pf
   kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672 15672:15672 15692:15692
   # Detach with Ctrl+B then D
   ```

3. **Check network stability**:
   ```bash
   # Test connectivity to pod
   kubectl exec -n rabbitmq-system <pod-name> -- rabbitmqctl ping
   ```

### Issue 4: Connection Timeouts

**Symptoms:**
- Clients can't connect
- Connection timeout errors
- "Connection refused" errors

**Fix:**
```bash
# Verify port-forward is running
ps aux | grep "kubectl port-forward.*5672"

# Verify port is accessible locally
nc -zv localhost 5672

# Restart port-forward if needed
./bin/setup_rabbitmq_local.sh
```

## Best Practices

### 1. Keep Port-Forward Running

Use a dedicated terminal or tmux session:
```bash
# Start tmux session
tmux new -s rabbitmq

# Run port-forward
kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672 15672:15672 15692:15692

# Detach: Ctrl+B then D
# Reattach: tmux attach -t rabbitmq
```

### 2. Monitor RabbitMQ Health

Set up regular checks:
```bash
# Quick health check script
#!/bin/bash
echo "Checking RabbitMQ health..."
kubectl get pods -n rabbitmq-system
kubectl exec -n rabbitmq-system $(kubectl get pod -n rabbitmq-system -l app.kubernetes.io/name=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl status | head -10
```

### 3. Check Queue Status Regularly

```bash
# Use the status script
make rabbitmq-status

# Or check directly
kubectl exec -n rabbitmq-system <pod-name> -- rabbitmqctl list_queues name messages consumers
```

## When Connection Resets Are Normal

**These reset messages are OK:**
```
Handling connection for 5672
E1210 10:24:28.919047 portforward.go:406] error forwarding port 5672 to pod: exit status 1
E1210 10:24:28.919217 portforward.go:234] lost connection to pod
```

**Why?** 
- Clients connect, do work, disconnect
- Port-forward sees the connection close
- This is normal AMQP connection lifecycle
- Port-forward continues working

**Only worry if:**
- Port-forward exits completely
- You can't reconnect
- RabbitMQ pod is restarting

## Getting Help

If issues persist:

1. **Collect diagnostic info:**
   ```bash
   kubectl get pods -n rabbitmq-system -o wide
   kubectl describe pod -n rabbitmq-system <pod-name>
   kubectl logs -n rabbitmq-system <pod-name> --tail=100
   kubectl get events -n rabbitmq-system --sort-by='.lastTimestamp' | tail -20
   ```

2. **Check resource usage:**
   ```bash
   kubectl top pod -n rabbitmq-system
   kubectl top node
   ```

3. **Verify service and endpoints:**
   ```bash
   kubectl get svc -n rabbitmq-system rabbitmq
   kubectl get endpoints -n rabbitmq-system rabbitmq
   ```
