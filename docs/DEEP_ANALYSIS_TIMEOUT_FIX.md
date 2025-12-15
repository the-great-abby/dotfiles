# Deep Analysis Timeout Fix

## Problem

The deep analysis worker was timing out when using thinking models like `qwen/qwen3-4b-thinking-2507`. The error showed:

```
Error calling deep AI: timed out. Model: qwen/qwen3-4b-thinking-2507
```

## Root Cause

Thinking models perform internal reasoning before generating responses, which takes longer than regular models. The default timeout of 120 seconds was insufficient for these models.

## Solution

### 1. Automatic Timeout Adjustment

The deep analysis worker now:
- **Detects thinking models** (models with "thinking" in the name)
- **Doubles the timeout** for thinking models (240s default, vs 120s for regular models)
- **Provides better error messages** with suggestions when timeouts occur

### 2. Configurable Timeout

You can now configure the timeout in your `.gtd_config_ai` file:

```bash
# Deep model timeout (in seconds)
# Thinking models need more time for their reasoning phase
DEEP_MODEL_TIMEOUT="300"  # 5 minutes for thinking models
```

### 3. Recommended Settings

**For Thinking Models** (like qwen3-4b-thinking):
```bash
DEEP_MODEL_TIMEOUT="300"  # 5 minutes
```

**For Regular Models** (7B-13B):
```bash
DEEP_MODEL_TIMEOUT="180"  # 3 minutes
```

**For Smaller Models** (< 7B):
```bash
DEEP_MODEL_TIMEOUT="120"  # 2 minutes (default)
```

## How It Works

1. The worker checks if the model name contains "thinking"
2. If it's a thinking model, it uses `DEEP_MODEL_TIMEOUT * 2` (or 240s default)
3. If it's a regular model, it uses `DEEP_MODEL_TIMEOUT` (or 120s default)
4. The timeout is configurable via `DEEP_MODEL_TIMEOUT` in config

## Testing

After updating the config, restart the deep analysis worker:

```bash
# Stop the worker if running
pkill -f gtd_deep_analysis_worker.py

# Start it again
python3 ~/code/dotfiles/mcp/gtd_deep_analysis_worker.py file
```

Then trigger a new analysis:

```bash
gtd-wizard  # → AI Suggestions → Generate Insights
```

## Troubleshooting

### Still Getting Timeouts?

1. **Check if model is loaded**:
   ```bash
   curl http://localhost:1234/v1/models
   ```

2. **Increase timeout further**:
   ```bash
   # In .gtd_config_ai
   DEEP_MODEL_TIMEOUT="600"  # 10 minutes
   ```

3. **Check model performance**:
   - Thinking models are slower but more thorough
   - Consider using a smaller thinking model if available
   - Or use a regular model for faster results

4. **Monitor the worker**:
   ```bash
   tail -f ~/Documents/gtd/deep_analysis_results/*.json
   ```

### Model Not Responding?

If the model isn't responding at all (not just timing out):

1. **Check LM Studio**:
   - Is the model loaded?
   - Is the server running?
   - Check LM Studio logs

2. **Test with a simple request**:
   ```bash
   curl -X POST http://localhost:1234/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{"model": "qwen/qwen3-4b-thinking-2507", "messages": [{"role": "user", "content": "test"}]}'
   ```

## Changes Made

1. **`mcp/gtd_deep_analysis_worker.py`**:
   - Added thinking model detection
   - Increased timeout for thinking models
   - Better error messages with suggestions
   - Configurable timeout via `DEEP_MODEL_TIMEOUT`

2. **`zsh/.gtd_config_ai`**:
   - Added `DEEP_MODEL_TIMEOUT` configuration option

## Summary

✅ **Fixed**: Timeout increased for thinking models  
✅ **Configurable**: Set `DEEP_MODEL_TIMEOUT` in config  
✅ **Better Errors**: More helpful timeout error messages  
✅ **Automatic**: Detects thinking models and adjusts timeout  

The system should now handle thinking models properly without timing out!
