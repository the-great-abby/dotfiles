# Ollama Controller Integration Guide

This guide explains how to modify the GTD system to use the Ollama Controller instead of connecting directly to Ollama.

## Overview

The Ollama Controller provides:
- **Throttling**: Prevents overwhelming Ollama with too many requests
- **Queuing**: Async request processing with priority queues
- **Monitoring**: Request tracking and status updates
- **Reliability**: Circuit breakers and retry logic

## Key Differences

### Current Setup (Direct Ollama)
- **URL**: `http://localhost:11434/v1/chat/completions` (or via NodePort)
- **Format**: OpenAI-compatible API (`/v1/chat/completions`)
- **Request Format**: OpenAI format with `messages` array

### Ollama Controller Setup
- **URL**: `http://<controller-api>:8080/api/chat` (or via NodePort)
- **Format**: Ollama-native API (`/api/chat` or `/api/generate`)
- **Request Format**: Ollama format (different from OpenAI)

## Required Changes

### 1. Create NodePort Service for Controller API

The Ollama Controller API runs on port 8080. We need to expose it via NodePort:

```yaml
# File: external_services/ollama_controller/kubernetes/ollama-controller-api-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama-controller-api-nodeport
  namespace: ollama-controller
  labels:
    app: ollama-controller-api
    service-type: nodeport
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 31080  # Standard NodePort for Controller API
    protocol: TCP
    name: api
  selector:
    app: ollama-controller-api
```

Deploy it:
```bash
kubectl apply -f external_services/ollama_controller/kubernetes/ollama-controller-api-nodeport.yaml
```

### 2. Update Configuration

**Current Configuration:**
```bash
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
```

**New Configuration (Ollama Controller):**
```bash
OLLAMA_URL="http://<NODE_IP>:31080/api/chat"
# Or for localhost (Docker Desktop):
OLLAMA_URL="http://127.0.0.1:31080/api/chat"
```

### 3. Update Python Functions

The GTD system uses OpenAI-compatible format, but Ollama Controller uses Ollama-native format. We need to update the Python functions to:

#### Option A: Add Adapter Function (Recommended)

Create an adapter that converts OpenAI format to Ollama format:

```python
# In zsh/functions/gtd_persona_helper.py or new adapter module

def convert_openai_to_ollama_format(openai_request):
    """Convert OpenAI-compatible request to Ollama format."""
    ollama_request = {
        "model": openai_request.get("model", "default"),
        "messages": openai_request.get("messages", []),
        "stream": False,  # Controller handles async
        "options": {
            "temperature": openai_request.get("temperature", 0.7),
            "max_tokens": openai_request.get("max_tokens", 2000),
        }
    }
    return ollama_request

def convert_ollama_to_openai_response(ollama_response):
    """Convert Ollama response to OpenAI-compatible format."""
    # Ollama Controller returns Ollama format, need to convert
    if "message" in ollama_response:
        # Ollama format
        return {
            "choices": [{
                "message": {
                    "role": "assistant",
                    "content": ollama_response["message"].get("content", "")
                }
            }]
        }
    elif "response" in ollama_response:
        # Alternative Ollama format
        return {
            "choices": [{
                "message": {
                    "role": "assistant",
                    "content": ollama_response["response"]
                }
            }]
        }
    return ollama_response
```

#### Option B: Update Functions to Use Ollama Format Directly

Modify the functions to use Ollama's native format instead of OpenAI format.

### 4. Files That Need Updates

#### Python Functions:
1. **`zsh/functions/gtd_persona_helper.py`**
   - `call_persona()` function
   - Update request format from OpenAI to Ollama
   - Update response parsing

2. **`zsh/functions/lmstudio_helper.py`**
   - `call_lm_studio()` function
   - Similar updates as above

3. **`zsh/functions/gtd_enhanced_search.py`**
   - `_call_llm()` method in `EnhancedSearchSystem`
   - Update request/response handling

4. **`zsh/functions/gtd_vectorization.py`**
   - Embedding generation (if using Ollama for embeddings)
   - May need different endpoint

#### Configuration Files:
1. **`zsh/.gtd_config_ai`**
   - Update `OLLAMA_URL` to point to controller API

2. **`zsh/.gtd_config`**
   - Update `OLLAMA_URL` if present

3. **`zsh/.daily_log_config`**
   - Update `OLLAMA_URL` if present

#### Scripts:
1. **`bin/configure-ollama-kubernetes`**
   - Update to configure controller API URL instead of direct Ollama
   - Update NodePort to 31080

2. **`bin/verify-nodeport`**
   - Add check for controller API NodePort (31080)

3. **`bin/gtd-wizard-tools.sh`**
   - Update test functions to use controller API
   - Update connection tests

## Request/Response Format Differences

### OpenAI Format (Current)
```json
{
  "model": "gemma2:1b",
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "temperature": 0.7,
  "max_tokens": 2000
}
```

Response:
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you?"
    }
  }]
}
```

### Ollama Format (Controller)
```json
{
  "model": "gemma2:1b",
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "stream": false,
  "options": {
    "temperature": 0.7,
    "num_predict": 2000
  }
}
```

Response:
```json
{
  "model": "gemma2:1b",
  "created_at": "2024-01-01T12:00:00Z",
  "message": {
    "role": "assistant",
    "content": "Hello! How can I help you?"
  },
  "done": true
}
```

## Migration Steps

### Step 1: Deploy Controller API NodePort
```bash
cd ~/code/external_services/ollama_controller/kubernetes
kubectl apply -f ollama-controller-api-nodeport.yaml
```

### Step 2: Verify Controller API is Accessible
```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test controller API
curl http://$NODE_IP:31080/api/v1/health
```

### Step 3: Update Configuration
```bash
# Run configuration script (needs to be updated first)
~/code/dotfiles/bin/configure-ollama-kubernetes
```

Or manually:
```bash
# Edit config file
nano ~/code/dotfiles/zsh/.gtd_config_ai

# Change:
OLLAMA_URL="http://<NODE_IP>:31080/api/chat"
```

### Step 4: Update Python Functions

Add adapter functions or update existing functions to use Ollama format.

### Step 5: Test

```bash
# Test with a simple request
python3 -c "
import urllib.request
import json

url = 'http://<NODE_IP>:31080/api/chat'
data = json.dumps({
    'model': 'gemma2:1b',
    'messages': [{'role': 'user', 'content': 'Hello'}],
    'stream': False
}).encode()

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
response = urllib.request.urlopen(req)
print(response.read().decode())
"
```

## Async Processing

The Ollama Controller supports async processing. When `stream: false`, requests are queued:

```python
# Async request
response = requests.post("http://<NODE_IP>:31080/api/chat", json={
    "model": "gemma2:1b",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": False,
    "priority": 2  # Optional: 1=low, 2=normal, 3=high, 4=urgent
})

# Returns immediately with request_id
request_id = response.json()["request_id"]

# Poll for status
status_response = requests.get(f"http://<NODE_IP>:31080/api/status/{request_id}")
```

For synchronous processing (current GTD behavior), use `stream: true`:
```python
response = requests.post("http://<NODE_IP>:31080/api/chat", json={
    "model": "gemma2:1b",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": True  # Immediate processing
})
```

## Benefits of Using Controller

1. **Throttling**: Prevents overwhelming Ollama
2. **Queuing**: Handles bursts of requests gracefully
3. **Monitoring**: Track request status and metrics
4. **Reliability**: Circuit breakers and retry logic
5. **Priority**: Important requests processed first

## Troubleshooting

### Controller API Not Responding
```bash
# Check service
kubectl get svc -n ollama-controller ollama-controller-api-nodeport

# Check pods
kubectl get pods -n ollama-controller -l app=ollama-controller-api

# Check logs
kubectl logs -n ollama-controller -l app=ollama-controller-api --tail=50
```

### Format Errors
- Ensure requests use Ollama format, not OpenAI format
- Check that response parsing handles Ollama format correctly

### Connection Issues
- Verify NodePort is accessible: `nc -zv <NODE_IP> 31080`
- Check controller API health: `curl http://<NODE_IP>:31080/api/v1/health`

## Next Steps

1. Create the NodePort service YAML
2. Update `configure-ollama-kubernetes` script
3. Create adapter functions for format conversion
4. Update Python functions to use adapter
5. Test end-to-end
6. Update documentation

