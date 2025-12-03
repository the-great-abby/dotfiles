# LM Studio Configuration Guide

Since both models (Gemma 1b and GPT-OSS 20b) run via LM Studio locally, here's how to configure them.

## Model Setup in LM Studio

### Option 1: Same URL, Different Model Names

LM Studio can serve multiple models, but you need to specify which model when making requests.

1. **Load Gemma 1b** in LM Studio for fast responses
2. **Load GPT-OSS 20b** in LM Studio for deep analysis
3. Both use the same endpoint: `http://localhost:1234/v1/chat/completions`
4. Specify model name in the request

**Configuration:**
```bash
# In .gtd_config
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_CHAT_MODEL="google/gemma-3-1b"  # Fast model

# For deep model (env var or config)
GTD_DEEP_MODEL_URL="http://localhost:1234/v1/chat/completions"
GTD_DEEP_MODEL_NAME="gpt-oss-20b"  # Deep model
```

### Option 2: Different Ports (If Running Multiple Instances)

If you want to run both models simultaneously:

1. **Start LM Studio** on port 1234 with Gemma 1b
2. **Start another LM Studio instance** on port 1235 with GPT-OSS 20b

**Configuration:**
```bash
# Fast model
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_CHAT_MODEL="google/gemma-3-1b"

# Deep model
GTD_DEEP_MODEL_URL="http://localhost:1235/v1/chat/completions"
GTD_DEEP_MODEL_NAME="gpt-oss-20b"
```

## Testing Configuration

### Test Fast Model (Gemma 1b)

```bash
curl -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-3-1b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

### Test Deep Model (GPT-OSS 20b)

```bash
curl -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss-20b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

## Model Name Resolution

LM Studio uses the model name from your model files. Check what names LM Studio recognizes:

1. Open LM Studio
2. Go to **Settings** → **Local Server**
3. Check the model name it reports

Common formats:
- `google/gemma-3-1b`
- `gemma-3-1b`
- `gpt-oss-20b`
- `gpt-oss-20b-instruct`

**Important:** The model name in your config must match exactly what LM Studio expects.

## Updating Configuration

### For Local Development

Edit `~/.gtd_config` or `zsh/.gtd_config`:

```bash
# Fast model (Gemma 1b)
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_CHAT_MODEL="google/gemma-3-1b"

# Deep model (GPT-OSS 20b) - can be same URL
GTD_DEEP_MODEL_URL="http://localhost:1234/v1/chat/completions"
GTD_DEEP_MODEL_NAME="gpt-oss-20b"
```

Or set environment variables:

```bash
export GTD_DEEP_MODEL_URL="http://localhost:1234/v1/chat/completions"
export GTD_DEEP_MODEL_NAME="gpt-oss-20b"
```

### For Kubernetes Deployment

Update `kubernetes/deployment.yaml`:

```yaml
env:
- name: GTD_DEEP_MODEL_URL
  value: "http://lm-studio-service:1234/v1/chat/completions"  # Service name
- name: GTD_DEEP_MODEL_NAME
  value: "gpt-oss-20b"
```

Or if accessing local LM Studio from pod:

```yaml
env:
- name: GTD_DEEP_MODEL_URL
  value: "http://host.docker.internal:1234/v1/chat/completions"
```

## Troubleshooting

### "Model not found" Error

1. **Check model is loaded** in LM Studio
2. **Verify model name** matches exactly
3. **Try listing models**:
   ```bash
   curl http://localhost:1234/v1/models
   ```

### Connection Refused

1. **Check LM Studio is running**
2. **Verify server is started** (Settings → Local Server → Start)
3. **Check port** matches configuration
4. **Test connection**: `curl http://localhost:1234/v1/models`

### Timeout Issues

1. **Increase timeout** in config:
   ```bash
   LM_STUDIO_TIMEOUT="120"  # 2 minutes for deep model
   ```
2. **Check model is loaded** (unloaded models are slow)
3. **Monitor LM Studio** logs for errors

### Multiple Model Instances

If you want both models available simultaneously:

1. **Option A**: Use model switching (load one, then the other as needed)
2. **Option B**: Run two LM Studio instances on different ports
3. **Option C**: Use a model router/proxy (advanced)

## Recommended Setup

For best performance:

1. **Keep Gemma 1b loaded** for fast responses
2. **Load GPT-OSS 20b** when needed for deep analysis
3. **Use same URL** with different model names
4. **Monitor resource usage** (20b model uses more RAM)

## Quick Test Script

Create `test_models.sh`:

```bash
#!/bin/bash

echo "Testing fast model (Gemma 1b)..."
curl -s -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-3-1b",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 20
  }' | jq -r '.choices[0].message.content'

echo ""
echo "Testing deep model (GPT-OSS 20b)..."
curl -s -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss-20b",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 20
  }' | jq -r '.choices[0].message.content'
```

Run: `chmod +x test_models.sh && ./test_models.sh`

