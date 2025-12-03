# Kubernetes Deployment for GTD Deep Analysis Worker

This directory contains Kubernetes manifests for deploying the GTD Deep Analysis Worker.

## Prerequisites

- Kubernetes cluster with access to:
  - RabbitMQ service (or update `rabbitmq-url` in secrets)
  - Persistent storage for GTD data
  - LM Studio accessible (either via service or ingress)

## Quick Deploy

### 1. Update Configuration

Edit `deployment.yaml`:
- Update image registry: `your-registry/gtd-worker:latest`
- Update LM Studio URL if different: `GTD_DEEP_MODEL_URL`
- Update model name if different: `GTD_DEEP_MODEL_NAME`
- Update RabbitMQ service name in `service.yaml` secret

### 2. Create Secrets

```bash
kubectl create secret generic gtd-secrets \
  --from-literal=rabbitmq-url='amqp://rabbitmq:5672'
```

### 3. Deploy

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 4. Check Status

```bash
kubectl get pods -l app=gtd-deep-analysis-worker
kubectl logs -l app=gtd-deep-analysis-worker -f
```

## Building the Docker Image

Create a `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY mcp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY mcp/ /app/
COPY zsh/ /app/zsh/

# Set working directory
WORKDIR /app

CMD ["python3", "gtd_deep_analysis_worker.py"]
```

Build and push:

```bash
docker build -t your-registry/gtd-worker:latest .
docker push your-registry/gtd-worker:latest
```

## Configuration Options

### Environment Variables

- `GTD_DEEP_MODEL_URL`: LM Studio endpoint (default: `http://localhost:1234/v1/chat/completions`)
- `GTD_DEEP_MODEL_NAME`: Model name in LM Studio (default: `gpt-oss-20b`)
- `GTD_RABBITMQ_URL`: RabbitMQ connection string
- `GTD_RABBITMQ_QUEUE`: Queue name (default: `gtd_deep_analysis`)
- `GTD_USER_NAME`: User name for analysis
- `GTD_BASE_DIR`: Base GTD directory (default: `/data/gtd`)
- `DAILY_LOG_DIR`: Daily logs directory (default: `/data/daily_logs`)
- `SECOND_BRAIN`: Second Brain directory (default: `/data/second_brain`)

### Persistent Storage

The deployment uses a PersistentVolumeClaim to store:
- GTD data files
- Daily logs
- Analysis results
- Queue files (if using file-based queue)

### Connecting to LM Studio

If LM Studio is running locally or on a different service:

1. **Local LM Studio**: Use port-forward or NodePort service
2. **LM Studio Service**: Create a service and update URL
3. **External LM Studio**: Use full URL with ingress

Example port-forward for local:

```bash
kubectl port-forward service/lm-studio 1234:1234
```

## Troubleshooting

### Worker Not Processing Messages

1. Check RabbitMQ connection:
   ```bash
   kubectl logs -l app=gtd-deep-analysis-worker | grep -i rabbitmq
   ```

2. Verify queue exists:
   ```bash
   kubectl exec -it <rabbitmq-pod> -- rabbitmqctl list_queues
   ```

### LM Studio Connection Issues

1. Check network connectivity:
   ```bash
   kubectl exec -it <worker-pod> -- curl -v <lm-studio-url>
   ```

2. Verify model is loaded in LM Studio

### Storage Issues

1. Check PVC status:
   ```bash
   kubectl get pvc gtd-data-pvc
   ```

2. Verify mount:
   ```bash
   kubectl exec -it <worker-pod> -- ls -la /data
   ```

## Scaling

To run multiple workers:

```bash
kubectl scale deployment gtd-deep-analysis-worker --replicas=3
```

Note: Each worker will process messages independently. RabbitMQ handles distribution.

## Monitoring

Add monitoring:

```yaml
# Add to deployment.yaml
livenessProbe:
  exec:
    command:
    - python3
    - -c
    - "import os; exit(0 if os.path.exists('/data/gtd') else 1)"
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command:
    - python3
    - -c
    - "import pika; pika.BlockingConnection(pika.URLParameters('${GTD_RABBITMQ_URL}'))"
  initialDelaySeconds: 10
  periodSeconds: 5
```

