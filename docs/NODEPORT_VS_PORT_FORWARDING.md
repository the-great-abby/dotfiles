# NodePort vs Port-Forwarding

## Why NodePort is More Reliable

**NodePort** is a Kubernetes service type that exposes a service on a static port on each node. It's more reliable than port-forwarding because:

1. **Persistent**: NodePort services persist even if kubectl processes die
2. **No Process Dependency**: Doesn't require a running `kubectl port-forward` process
3. **Survives Restarts**: Works across system restarts and kubectl disconnections
4. **Always Available**: Service is always accessible at the NodePort (e.g., 192.168.64.2:30003)

**Port-Forwarding** is less reliable because:

1. **Process-Dependent**: Requires an active `kubectl port-forward` process
2. **Breaks on Disconnect**: If kubectl disconnects, port-forward stops
3. **Manual Setup**: Must be manually restarted after system restarts
4. **Temporary**: Only works while the process is running

## Current Configuration

Your system is configured to use **NodePort** for both services:

- **PostgreSQL**: `192.168.64.2:30003` (NodePort)
- **RabbitMQ**: `192.168.64.2:30672` (NodePort)

## Verifying NodePort Setup

### Quick Check

```bash
make verify-nodeport
```

Or directly:

```bash
./bin/verify-nodeport
```

This will:
- Check if NodePort services exist on ports 30003 and 30672
- Verify service configuration
- Check if pods are running
- Test connectivity

### Manual Verification

```bash
# Check PostgreSQL NodePort
kubectl get svc -A -o wide | grep 30003

# Check RabbitMQ NodePort
kubectl get svc -A -o wide | grep 30672

# Test connectivity
nc -zv 192.168.64.2 30003  # PostgreSQL
nc -zv 192.168.64.2 30672  # RabbitMQ
```

## Troubleshooting NodePort Issues

### Issue: Connection Refused

If you get "Connection refused" when using NodePort:

1. **Verify NodePort exists:**
   ```bash
   kubectl get svc -A -o json | jq -r '.items[] | select(.spec.type=="NodePort") | select(.spec.ports[]?.nodePort==30003)'
   ```

2. **Check if service is running:**
   ```bash
   kubectl get pods -A | grep -i postgres
   kubectl get svc -A | grep -i postgres
   ```

3. **Verify service selector matches pods:**
   ```bash
   # Get service selector
   kubectl get svc <service-name> -n <namespace> -o jsonpath='{.spec.selector}'
   
   # Check if pods match
   kubectl get pods -n <namespace> -l <selector>
   ```

### Setting Up NodePort

If NodePort isn't configured, you can set it up:

```bash
# For PostgreSQL
kubectl patch svc <postgres-service> -n <namespace> -p '{"spec":{"type":"NodePort","ports":[{"port":5432,"nodePort":30003}]}}'

# For RabbitMQ
kubectl patch svc <rabbitmq-service> -n <namespace> -p '{"spec":{"type":"NodePort","ports":[{"port":5672,"nodePort":30672}]}}'
```

Or use the wizard:

```bash
gtd-wizard → Configuration → External Services → Database
```

## Fallback to Port-Forwarding

If NodePort isn't working and you need a temporary solution, you can fall back to port-forwarding:

1. **Change config to use localhost:**
   ```bash
   # Edit .gtd_config_database
   VECTOR_DB_HOST="localhost"
   VECTOR_DB_PORT="13003"
   ```

2. **Set up port-forward:**
   ```bash
   setup-port-forward 13003
   ```

**Note**: Port-forwarding is a temporary workaround. You should fix the NodePort setup for reliability.

## Best Practices

1. **Use NodePort for Production**: More reliable, persistent
2. **Use Port-Forwarding for Development**: Quick setup, but less reliable
3. **Verify Setup**: Run `make verify-nodeport` after deployment
4. **Monitor Services**: Check service status regularly

## Configuration Files

- **Database Config**: `zsh/.gtd_config_database`
  - `VECTOR_DB_HOST`: Should be `192.168.64.2` for NodePort
  - `VECTOR_DB_PORT`: Should be `30003` for NodePort

- **RabbitMQ Config**: `zsh/.gtd_config_database`
  - `RABBITMQ_URL`: Should be `amqp://192.168.64.2:30672` for NodePort
