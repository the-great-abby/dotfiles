# How to Use the Ollama Controller

Your Ollama Controller is already configured! Here's how to use it.

## Current Status

✅ **Controller API**: Configured at `http://127.0.0.1:31080/v1/chat/completions`  
✅ **NodePort Service**: Running on port 31080  
✅ **Configuration**: Updated in `.gtd_config_ai`

## Quick Start

### Step 1: Switch AI Backend to Ollama

The controller is configured, but you need to set your AI backend to use Ollama:

```bash
# Edit your config file
nano ~/code/dotfiles/zsh/.gtd_config_ai

# Set AI_BACKEND to "ollama"
AI_BACKEND="ollama"
```

Or use the wizard:
```bash
gtd-wizard
# Choose: 27) ⚙️  Configuration & Setup
# Then: 1) 🤖 Switch AI Backend (LM Studio ↔ Ollama)
# Select: Ollama
```

### Step 2: Verify It's Working

Test the controller:

```bash
# Test controller API directly
curl http://127.0.0.1:31080/v1/models

# Test from GTD system
python3 ~/code/dotfiles/zsh/functions/gtd_persona_helper.py hank "Hello, test message"
```

## Using the Controller

### Normal Usage

Once `AI_BACKEND="ollama"` is set, **everything works automatically**:

1. **Persona Helper** (advice):
   ```bash
   python3 ~/code/dotfiles/zsh/functions/gtd_persona_helper.py hank "your question"
   ```

2. **Daily Log Reviews**:
   ```bash
   reviewDailyLog  # Uses Ollama via controller
   ```

3. **Enhanced Search**:
   - Uses Ollama for query enhancement automatically

4. **Wizard Functions**:
   - All AI features in the wizard use the controller

### No Code Changes Needed!

Since the controller supports OpenAI-compatible endpoints:
- ✅ All existing functions work as-is
- ✅ Same request/response format
- ✅ Just change the URL (already done!)

## What the Controller Provides

### Benefits

1. **Throttling**: Prevents overwhelming Ollama with too many requests
2. **Queuing**: Handles bursts of requests gracefully
3. **Monitoring**: Track request status and metrics
4. **Reliability**: Circuit breakers and retry logic
5. **Priority**: Important requests processed first

### How It Works

```
Your GTD System
    ↓
Ollama Controller API (port 31080)
    ↓ (throttles, queues, monitors)
Ollama Service (port 11434)
    ↓
LLM Models
```

## Configuration

### Current Setup

**Controller API URL:**
```bash
OLLAMA_URL="http://127.0.0.1:31080/v1/chat/completions"
```

**To Use It:**
```bash
AI_BACKEND="ollama"
```

### Mode-Specific Configuration

You can set different backends for work vs home:

```bash
# Work mode
WORK_AI_BACKEND="ollama"
WORK_OLLAMA_CHAT_MODEL="gemma3:4b"

# Home mode  
HOME_AI_BACKEND="ollama"
HOME_OLLAMA_CHAT_MODEL="gemma3:1b"
```

## Testing

### Test Controller API

```bash
# List available models
curl http://127.0.0.1:31080/v1/models

# Test chat completion
curl -X POST http://127.0.0.1:31080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma2:1b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Test from GTD System

```bash
# Test persona helper
python3 ~/code/dotfiles/zsh/functions/gtd_persona_helper.py hank "Test message"

# Check if using controller
grep OLLAMA_URL ~/code/dotfiles/zsh/.gtd_config_ai
# Should show: http://127.0.0.1:31080/v1/chat/completions
```

## Troubleshooting

### Controller Not Responding

```bash
# Check service
kubectl get svc -n ollama-controller ollama-controller-api-nodeport

# Check pods
kubectl get pods -n ollama-controller -l app=ollama-controller-api

# Check logs
kubectl logs -n ollama-controller -l app=ollama-controller-api --tail=50
```

### Still Using LM Studio

If requests are still going to LM Studio:

1. **Check AI_BACKEND:**
   ```bash
   grep AI_BACKEND ~/code/dotfiles/zsh/.gtd_config_ai
   ```

2. **Set to Ollama:**
   ```bash
   # Edit config
   nano ~/code/dotfiles/zsh/.gtd_config_ai
   # Change: AI_BACKEND="ollama"
   ```

3. **Reload config:**
   ```bash
   source ~/code/dotfiles/zsh/.gtd_config_ai
   ```

### No Models Available

If you see "0 models found":

1. **Check if Ollama has models:**
   ```bash
   # From inside a pod or if Ollama is accessible
   curl http://localhost:11434/api/tags
   ```

2. **Controller may need to connect to Ollama:**
   - Check controller logs for connection issues
   - Verify Ollama service is running in Kubernetes

## Advanced Features

### Async Processing (Future)

The controller supports async processing with callbacks:

```python
# Queue a request (returns immediately)
response = requests.post("http://127.0.0.1:31080/v1/chat/completions", json={
    "model": "gemma2:1b",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": False,  # Async mode
    "priority": 2,     # Optional priority
    "callback_url": "https://your-app.com/webhook"  # Optional callback
})

# Get request_id and poll for status
request_id = response.json()["request_id"]
status = requests.get(f"http://127.0.0.1:31080/api/status/{request_id}")
```

Currently, the GTD system uses synchronous mode (`stream: true`), which works immediately.

## Summary

**To use the Ollama Controller:**

1. ✅ **Already configured** - URL is set in config
2. ⚙️ **Set AI_BACKEND to "ollama"** - Switch from LM Studio
3. 🚀 **Use normally** - Everything works automatically!

**That's it!** The controller is a drop-in replacement - no code changes needed.

