# Ollama Controller Integration - Simplified Guide

Since the Ollama Controller now supports OpenAI-compatible endpoints (`/v1/chat/completions`), integration is much simpler - **no code changes needed!**

## What Changed

The Ollama Controller API has been updated to support:
- ✅ `/v1/chat/completions` - OpenAI-compatible chat endpoint
- ✅ `/v1/models` - OpenAI-compatible models endpoint
- ✅ Same request/response format as direct Ollama

This means **no Python code changes are required** - the GTD system can use the controller as a drop-in replacement!

## Quick Setup

### 1. Deploy Controller API NodePort

```bash
cd ~/code/external_services/ollama_controller/kubernetes
kubectl apply -f ollama-controller-api-nodeport.yaml
```

This creates a NodePort service on port **31080** that exposes the Controller API.

### 2. Configure GTD System

Run the automated configuration script:

```bash
~/code/dotfiles/bin/configure-ollama-kubernetes
```

This will:
- Detect your Kubernetes node IP
- Check if Controller API NodePort exists
- Test connectivity
- Update your config files to use: `http://<NODE_IP>:31080/v1/chat/completions`

### 3. Verify Setup

```bash
# Check all NodePort services
make verify-nodeport

# Or test directly
curl http://<NODE_IP>:31080/v1/models
```

## Configuration

### URL Format

**Before (Direct Ollama):**
```bash
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
# Or via NodePort:
OLLAMA_URL="http://192.168.64.2:31134/v1/chat/completions"
```

**After (Ollama Controller):**
```bash
OLLAMA_URL="http://192.168.64.2:31080/v1/chat/completions"
```

**That's it!** The endpoint path (`/v1/chat/completions`) stays the same.

### Configuration Files

The URL is updated in:
- `~/.gtd_config_ai` (primary)
- `~/.gtd_config` (if present)
- `~/.daily_log_config` (if present)

## Benefits

Using the Controller provides:
1. **Throttling** - Prevents overwhelming Ollama
2. **Queuing** - Handles request bursts gracefully
3. **Monitoring** - Track request status and metrics
4. **Reliability** - Circuit breakers and retry logic
5. **Priority** - Important requests processed first

## No Code Changes Needed!

Since the Controller supports OpenAI-compatible endpoints:
- ✅ All existing Python functions work as-is
- ✅ No format conversion needed
- ✅ No adapter modules required
- ✅ Same request/response format

The GTD system will automatically use the controller when `OLLAMA_URL` points to it.

## Testing

### Test Controller API

```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test models endpoint
curl http://$NODE_IP:31080/v1/models

# Test chat endpoint
curl -X POST http://$NODE_IP:31080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma2:1b",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Test from GTD System

```bash
# Test persona helper (uses OLLAMA_URL from config)
python3 -c "
from zsh.functions.gtd_persona_helper import read_config, call_persona
config = read_config()
result, code = call_persona(config, 'hank', 'Hello, how are you?')
print(result)
"
```

## Troubleshooting

### Controller API Not Responding

1. **Check service:**
   ```bash
   kubectl get svc -n ollama-controller ollama-controller-api-nodeport
   ```

2. **Check pods:**
   ```bash
   kubectl get pods -n ollama-controller -l app=ollama-controller-api
   ```

3. **Check logs:**
   ```bash
   kubectl logs -n ollama-controller -l app=ollama-controller-api --tail=50
   ```

### Connection Refused

1. **Verify NodePort:**
   ```bash
   kubectl get svc -n ollama-controller ollama-controller-api-nodeport -o jsonpath='{.spec.ports[0].nodePort}'
   # Should return: 31080
   ```

2. **Test connectivity:**
   ```bash
   nc -zv <NODE_IP> 31080
   ```

3. **Check if controller needs redeployment:**
   ```bash
   # If controller was just updated, may need to redeploy
   cd ~/code/external_services/ollama_controller
   make k8s-deploy  # Or follow your deployment process
   ```

### Endpoint Not Found (404)

If you get 404 errors, the controller may not have the `/v1/chat/completions` endpoint yet. Check:

1. **Controller version** - Ensure it supports OpenAI-compatible endpoints
2. **Controller logs** - Check for endpoint registration
3. **API documentation** - Verify available endpoints

## Migration Path

### Option 1: Direct Switch (Recommended)

1. Deploy Controller API NodePort
2. Run `configure-ollama-kubernetes`
3. Done! System now uses controller

### Option 2: Gradual Migration

1. Keep direct Ollama as fallback
2. Test controller with specific requests
3. Switch when confident

The system supports both - just change the URL!

## Next Steps

1. ✅ Deploy Controller API NodePort
2. ✅ Run configuration script
3. ✅ Test connectivity
4. ✅ Verify GTD system works
5. ✅ Monitor controller metrics

## Summary

**Before:** Direct Ollama connection, no throttling/queuing
**After:** Controller API connection, same endpoints, same format, with throttling/queuing

**Code Changes Required:** None! 🎉

Just update the URL and you're done.

