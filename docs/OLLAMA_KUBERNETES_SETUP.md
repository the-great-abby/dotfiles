# Ollama Controller Kubernetes Integration

This document describes how to set up and use the Ollama Controller service via Kubernetes NodePort, similar to how PostgreSQL and RabbitMQ are configured.

## Overview

The Ollama Controller is now integrated with the GTD system to use Kubernetes NodePort for reliable, persistent connections. This follows the same pattern as PostgreSQL (port 30003) and RabbitMQ (port 30672).

## Quick Setup

### 1. Create NodePort Service

The NodePort service configuration is available at:
```
~/code/external_services/ollama_controller/kubernetes/ollama-nodeport-service.yaml
```

To deploy it:

```bash
cd ~/code/external_services/ollama_controller/kubernetes
kubectl apply -f ollama-nodeport-service.yaml
```

Or patch the existing service:

```bash
kubectl patch svc ollama-service -n ollama-controller \
  -p '{"spec":{"type":"NodePort","ports":[{"port":11434,"targetPort":11434,"nodePort":31134}]}}'
```

### 2. Configure GTD System

Use the automated configuration script:

```bash
~/code/dotfiles/bin/configure-ollama-kubernetes
```

This script will:
- Detect your Kubernetes node IP
- Check if NodePort service exists
- Test connectivity
- Update your GTD configuration files (`.gtd_config_ai` and `.gtd_config`)

### 3. Verify Setup

```bash
# Verify NodePort services (includes Ollama)
make verify-nodeport

# Or directly
~/code/dotfiles/bin/verify-nodeport
```

## Configuration

### NodePort Details

- **Port**: 31134 (standard NodePort for Ollama)
- **Service**: `ollama-service` in namespace `ollama-controller`
- **URL Format**: `http://<NODE_IP>:31134/v1/chat/completions`

### Node IP Detection

The system automatically detects the correct node IP:
- **Minikube**: Uses `minikube ip`
- **Docker Desktop / Rancher Desktop**: Uses `127.0.0.1` or detected node IP
- **Other Kubernetes**: Uses detected InternalIP

### Configuration Files

The Ollama URL is configured in:
- `~/.gtd_config_ai` (primary location)
- `~/.gtd_config` (fallback)

Example configuration:
```bash
OLLAMA_URL="http://192.168.64.2:31134/v1/chat/completions"
```

Or for Docker Desktop:
```bash
OLLAMA_URL="http://127.0.0.1:31134/v1/chat/completions"
```

## Using the Wizard

The GTD Wizard now includes an Ollama Controller configuration option:

1. Open GTD Wizard: `gtd-wizard`
2. Navigate to: **65) 🤖 Ollama Controller Configuration**
3. Choose from:
   - **1) Configure Ollama Kubernetes Connection** - Automated setup
   - **2) Show Connection Information** - Display current config
   - **3) Verify NodePort Service** - Check service status
   - **4) Test Ollama Connection** - Test API connectivity

## Connection Information

To view connection information:

```bash
cd ~/code/external_services/ollama_controller
make connection-info
```

This will show:
- Kubernetes service URL (for pods)
- NodePort URL (for host access)
- API endpoint URL

## Troubleshooting

### NodePort Not Accessible

1. **Check if service exists:**
   ```bash
   kubectl get svc -n ollama-controller | grep NodePort
   ```

2. **Verify NodePort port:**
   ```bash
   kubectl get svc ollama-service -n ollama-controller -o jsonpath='{.spec.ports[?(@.nodePort==31134)].nodePort}'
   ```

3. **Check pod status:**
   ```bash
   kubectl get pods -n ollama-controller
   ```

### Connection Refused

1. **Test NodePort connectivity:**
   ```bash
   nc -zv <NODE_IP> 31134
   ```

2. **Test API endpoint:**
   ```bash
   curl http://<NODE_IP>:31134/v1/models
   ```

3. **Check service selector:**
   ```bash
   kubectl get svc ollama-service -n ollama-controller -o jsonpath='{.spec.selector}'
   kubectl get pods -n ollama-controller -l <selector>
   ```

### Configuration Not Updating

1. **Check current configuration:**
   ```bash
   grep OLLAMA_URL ~/code/dotfiles/zsh/.gtd_config_ai
   ```

2. **Manually update if needed:**
   ```bash
   # Edit the config file
   nano ~/code/dotfiles/zsh/.gtd_config_ai
   # Set: OLLAMA_URL="http://<NODE_IP>:31134/v1/chat/completions"
   ```

3. **Reload configuration:**
   ```bash
   source ~/code/dotfiles/zsh/.gtd_config_ai
   ```

## Integration with External Services

The Ollama Controller is now integrated alongside other external services:

- **PostgreSQL**: Port 30003 (NodePort)
- **RabbitMQ**: Port 30672 (NodePort)
- **Ollama**: Port 31134 (NodePort)

All services use the same NodePort pattern for consistency and reliability.

## Benefits of NodePort

1. **Persistent**: Service persists even if kubectl processes die
2. **No Process Dependency**: Doesn't require running `kubectl port-forward`
3. **Survives Restarts**: Works across system restarts
4. **Always Available**: Service accessible at static IP:port
5. **Reliable**: More reliable than port-forwarding

## Related Documentation

- [NodePort vs Port-Forwarding](./NODEPORT_VS_PORT_FORWARDING.md)
- [Complete Setup Guide](./COMPLETE_SETUP_GUIDE.md)
- [Architecture Decisions](./architecture_decisions.md)

## Scripts and Tools

- `bin/configure-ollama-kubernetes` - Automated configuration script
- `bin/verify-nodeport` - Verify all NodePort services (includes Ollama)
- `external_services/ollama_controller/kubernetes/ollama-nodeport-service.yaml` - Service definition
- `external_services/ollama_controller/Makefile` - Updated with connection-info target

