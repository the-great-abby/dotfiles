# How to Redeploy Ollama Controller with OpenAI-Compatible Endpoints

The Ollama Controller has been updated to support `/v1/chat/completions`, but the running deployment doesn't have it yet. Here's how to redeploy:

## Quick Redeploy

### Option 1: Full Redeploy (Recommended)

```bash
cd ~/code/external_services/ollama_controller
make k8s-deploy
```

This will:
1. Build new Docker images with the updated code
2. Deploy to Kubernetes
3. Wait for pods to be ready

### Option 2: Just Restart API (If Code is Already Built)

If the images are already built with the new code:

```bash
cd ~/code/external_services/ollama_controller
make force-restart-api
```

Or manually:
```bash
kubectl rollout restart deployment ollama-controller-api -n ollama-controller
kubectl rollout status deployment ollama-controller-api -n ollama-controller
```

### Option 3: Development Deploy (Faster, 1 Replica)

```bash
cd ~/code/external_services/ollama_controller
make k8s-deploy-dev
```

## Verify the Redeploy

After redeploying, test the endpoint:

```bash
# Test OpenAI-compatible endpoint
curl http://127.0.0.1:31080/v1/models

# Should return models list (not "Not Found")
```

## Current Status

**What's Working:**
- ✅ Controller API is running
- ✅ Ollama is connected (health check shows healthy)
- ✅ Models are available (via `/api/tags`)
- ✅ NodePort service is configured

**What's Missing:**
- ❌ `/v1/chat/completions` endpoint (returns "Not Found")
- ❌ `/v1/models` endpoint (returns "Not Found")

**After Redeploy:**
- ✅ `/v1/chat/completions` will work
- ✅ `/v1/models` will work
- ✅ GTD system will be able to use controller

## Troubleshooting

### If Redeploy Fails

1. **Check if images build:**
   ```bash
   cd ~/code/external_services/ollama_controller
   make k8s-build
   ```

2. **Check deployment status:**
   ```bash
   kubectl get pods -n ollama-controller
   kubectl logs -n ollama-controller -l app=ollama-controller-api --tail=50
   ```

3. **Check if code has the endpoint:**
   ```bash
   # Check if the API file has /v1/chat/completions route
   grep -r "/v1/chat/completions" ~/code/external_services/ollama_controller/api/
   ```

### If Endpoint Still Not Available

The code might not have the endpoint yet. Check:
```bash
# Look for OpenAI-compatible routes
grep -r "v1/chat\|v1/models\|openai\|chat/completions" ~/code/external_services/ollama_controller/api/
```

If it's not there, the code update might not be complete yet.

## Quick Test After Redeploy

```bash
# Test the endpoint
curl -X POST http://127.0.0.1:31080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma2:1b",
    "messages": [{"role": "user", "content": "Hello"}]
  }'

# If it works, you'll get a response
# If it doesn't, you'll get "Not Found" or an error
```

## Summary

**To use the Ollama Controller:**
1. ✅ NodePort is configured (done)
2. ✅ Config is updated (done)
3. ⏳ **Redeploy controller API** (needed)
4. ✅ Test and use (after redeploy)

Once redeployed, the GTD system will automatically use the controller!

