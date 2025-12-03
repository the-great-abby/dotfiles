# Kubernetes Deployment Guide

Complete guide for deploying the GTD Deep Analysis Worker to Kubernetes.

## Quick Start

Use the deployment wizard in `gtd-wizard`:

```bash
gtd-wizard
# Choose: 23) 🤖 AI Suggestions & MCP Tools
# Choose: 10) 🚀 Deploy Worker to Kubernetes
```

Or use the deployment script directly:

```bash
cd mcp
./deploy.sh build      # Build Docker image
./deploy.sh deploy     # Deploy to Kubernetes
./deploy.sh status     # Check status
./deploy.sh logs       # View logs
```

## Prerequisites

1. **Kubernetes Cluster**: Accessible via `kubectl`
2. **Docker/Podman**: For building images
3. **RabbitMQ**: Running in Kubernetes or accessible
4. **LM Studio**: Accessible from Kubernetes (via service or ingress)

## Step-by-Step Deployment

### 1. Build Docker Image

```bash
./deploy.sh build
```

This will:
- Build the Docker image using `Dockerfile`
- Tag with your registry (if provided)
- Optionally push to registry

**Manual build:**

```bash
docker build -f Dockerfile -t gtd-worker:latest ..
docker tag gtd-worker:latest your-registry/gtd-worker:latest
docker push your-registry/gtd-worker:latest
```

### 2. Configure Kubernetes

Update `kubernetes/deployment.yaml`:

- **Image name**: Replace `your-registry/gtd-worker:latest` with your image
- **LM Studio URL**: Update `GTD_DEEP_MODEL_URL` if different
- **Model name**: Update `GTD_DEEP_MODEL_NAME` if different
- **RabbitMQ URL**: Will be set via secrets

### 3. Create Secrets

```bash
kubectl create secret generic gtd-secrets \
  --from-literal=rabbitmq-url='amqp://rabbitmq:5672'
```

Or update the secret in `deployment.yaml` and apply:

```bash
kubectl apply -f kubernetes/deployment.yaml
```

### 4. Deploy

```bash
./deploy.sh deploy
```

This will:
- Create/update secrets
- Apply deployment and service manifests
- Wait for pods to be ready

**Manual deploy:**

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl wait --for=condition=ready pod -l app=gtd-deep-analysis-worker --timeout=120s
```

## Configuration

### Environment Variables

The deployment uses these environment variables:

- `GTD_DEEP_MODEL_URL`: LM Studio endpoint (default: `http://localhost:1234/v1/chat/completions`)
- `GTD_DEEP_MODEL_NAME`: Model name (default: `gpt-oss-20b`)
- `GTD_RABBITMQ_URL`: RabbitMQ connection (from secret)
- `GTD_RABBITMQ_QUEUE`: Queue name (default: `gtd_deep_analysis`)
- `GTD_USER_NAME`: User name for analysis
- `GTD_BASE_DIR`: Base GTD directory (default: `/data/gtd`)
- `DAILY_LOG_DIR`: Daily logs directory (default: `/data/daily_logs`)
- `SECOND_BRAIN`: Second Brain directory (default: `/data/second_brain`)

### Persistent Storage

The deployment creates a PersistentVolumeClaim for:
- GTD data files
- Daily logs
- Analysis results
- Queue files (if using file-based queue)

### Connecting to LM Studio

**Option 1: Port Forward**

If LM Studio runs locally:

```bash
kubectl port-forward service/lm-studio 1234:1234
```

Then update worker to use: `http://host.docker.internal:1234/v1/chat/completions`

**Option 2: Kubernetes Service**

Create a service for LM Studio:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: lm-studio
spec:
  selector:
    app: lm-studio
  ports:
  - port: 1234
    targetPort: 1234
```

Update worker env: `GTD_DEEP_MODEL_URL=http://lm-studio:1234/v1/chat/completions`

**Option 3: External URL**

If LM Studio is accessible externally:

```yaml
env:
- name: GTD_DEEP_MODEL_URL
  value: "http://lm-studio.example.com:1234/v1/chat/completions"
```

## Monitoring & Management

### Check Status

```bash
./deploy.sh status
```

Or manually:

```bash
kubectl get deployment gtd-deep-analysis-worker
kubectl get pods -l app=gtd-deep-analysis-worker
kubectl describe pod -l app=gtd-deep-analysis-worker
```

### View Logs

```bash
./deploy.sh logs
```

Or manually:

```bash
kubectl logs -l app=gtd-deep-analysis-worker -f
kubectl logs -l app=gtd-deep-analysis-worker --tail=100
```

### Update Deployment

```bash
./deploy.sh update
```

This rebuilds the image and redeploys. Or manually:

```bash
./deploy.sh build
kubectl rollout restart deployment/gtd-deep-analysis-worker
```

### Scale Workers

```bash
kubectl scale deployment gtd-deep-analysis-worker --replicas=3
```

Each worker processes messages independently. RabbitMQ handles distribution.

### Remove Deployment

```bash
./deploy.sh undeploy
```

Or manually:

```bash
kubectl delete -f kubernetes/deployment.yaml
kubectl delete -f kubernetes/service.yaml
```

## Troubleshooting

### Worker Not Starting

1. Check pod status:
   ```bash
   kubectl get pods -l app=gtd-deep-analysis-worker
   kubectl describe pod <pod-name>
   ```

2. Check logs:
   ```bash
   kubectl logs <pod-name>
   ```

3. Check image pull:
   ```bash
   kubectl describe pod <pod-name> | grep -i image
   ```

### RabbitMQ Connection Issues

1. Check RabbitMQ is accessible:
   ```bash
   kubectl exec -it <worker-pod> -- curl -v <rabbitmq-url>
   ```

2. Verify secrets:
   ```bash
   kubectl get secret gtd-secrets -o yaml
   ```

3. Test connection:
   ```bash
   kubectl exec -it <worker-pod> -- python3 -c "import pika; pika.BlockingConnection(pika.URLParameters('amqp://...'))"
   ```

### LM Studio Connection Issues

1. Check network connectivity:
   ```bash
   kubectl exec -it <worker-pod> -- curl -v <lm-studio-url>
   ```

2. Verify model is loaded in LM Studio

3. Check DNS resolution:
   ```bash
   kubectl exec -it <worker-pod> -- nslookup <lm-studio-host>
   ```

### Storage Issues

1. Check PVC status:
   ```bash
   kubectl get pvc gtd-data-pvc
   kubectl describe pvc gtd-data-pvc
   ```

2. Verify mount:
   ```bash
   kubectl exec -it <worker-pod> -- ls -la /data
   ```

3. Check storage class:
   ```bash
   kubectl get storageclass
   ```

### Performance Issues

1. Check resource usage:
   ```bash
   kubectl top pod -l app=gtd-deep-analysis-worker
   ```

2. Adjust resources in `deployment.yaml`:
   ```yaml
   resources:
     requests:
       memory: "1Gi"
       cpu: "500m"
     limits:
       memory: "4Gi"
       cpu: "2000m"
   ```

## Advanced Configuration

### Health Checks

Add to `deployment.yaml`:

```yaml
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

### Resource Limits

Adjust based on your needs:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### Node Selection

Deploy to specific nodes:

```yaml
nodeSelector:
  workload-type: ai
tolerations:
- key: "ai-workload"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

## Integration with gtd-wizard

The deployment is integrated into `gtd-wizard`:

1. Open wizard: `gtd-wizard`
2. Navigate: `23) 🤖 AI Suggestions & MCP Tools`
3. Choose: `10) 🚀 Deploy Worker to Kubernetes`

Or check status:

1. Open wizard: `gtd-wizard`
2. Navigate: `17) 📊 System status`
3. Choose: `5) 🚀 Kubernetes Deployment Status`

## See Also

- `kubernetes/README.md` - Kubernetes-specific documentation
- `README.md` - Main MCP documentation
- `CURSOR_MCP_CONFIG.md` - Cursor configuration

