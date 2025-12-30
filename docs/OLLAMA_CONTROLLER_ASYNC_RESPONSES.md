# Ollama Controller Async Response Handling

## Overview

The Ollama Controller supports **async request processing**. When a request is queued (instead of processed immediately), the controller returns a response with `status: "queued"` and a `request_id`. The client must then poll a status endpoint to get the final result.

## Pattern: Always Handle Async Responses

**CRITICAL**: All code that makes requests to Ollama Controller (port 31080) **MUST** handle async responses.

### Why This Matters

- **Ollama Controller queues requests** when the system is busy or throttling
- **Direct responses** are returned when the system can process immediately
- **Code that doesn't handle async** will see "No response from AI" errors

## Implementation

### Use the Shared Helper

**Location**: `zsh/functions/gtd_ai_helpers.py`

**Function**: `handle_ai_response(result, base_url, max_poll_time=60.0, poll_interval=0.5)`

```python
from gtd_ai_helpers import handle_ai_response

# After making the initial request
result = json.loads(response.read().decode('utf-8'))

# Handle async responses automatically
base_url = url.rsplit('/v1', 1)[0]
polled_result, poll_error = handle_ai_response(result, base_url, max_poll_time=timeout)

if poll_error:
    return f"Error: {poll_error}"

if polled_result:
    result = polled_result

# Now use result['choices'] as normal
```

### Example: Before (Incorrect)

```python
# ❌ BAD - Doesn't handle async
with urllib.request.urlopen(req, timeout=timeout) as response:
    result = json.loads(response.read().decode('utf-8'))
    if 'choices' in result:
        return result['choices'][0]['message']['content']
    return "No response from AI"  # ← This happens when queued!
```

### Example: After (Correct)

```python
# ✅ GOOD - Handles async
from gtd_ai_helpers import handle_ai_response

with urllib.request.urlopen(req, timeout=timeout) as response:
    result = json.loads(response.read().decode('utf-8'))
    
    # Handle async responses
    base_url = url.rsplit('/v1', 1)[0]
    polled_result, poll_error = handle_ai_response(result, base_url, max_poll_time=timeout)
    
    if poll_error:
        return f"Error: {poll_error}"
    
    if polled_result:
        result = polled_result
    
    if 'choices' in result:
        return result['choices'][0]['message']['content']
    return "No response from AI"
```

## Functions That Must Handle Async

All of these functions have been updated to use the shared helper:

1. ✅ `call_deep_ai()` - `mcp/gtd_deep_analysis_worker.py`
2. ✅ `call_fast_ai()` - `mcp/gtd_mcp_server.py`
3. ✅ `call_persona()` - `zsh/functions/gtd_persona_helper.py`
4. ✅ `_call_llm()` - `zsh/functions/gtd_enhanced_search.py`
5. ✅ `call_lm_studio()` - `zsh/functions/lmstudio_helper.py`

## How Async Responses Work

### 1. Initial Request

```json
POST /v1/chat/completions
{
  "model": "qwen3:4b",
  "messages": [{"role": "user", "content": "Hello"}]
}
```

### 2. Queued Response

```json
{
  "status": "queued",
  "request_id": "abc123-def456-ghi789"
}
```

### 3. Poll Status Endpoint

```json
GET /v1/chat/completions/{request_id}
```

### 4. Completed Response

```json
{
  "choices": [{
    "message": {
      "content": "Hello! How can I help you?"
    }
  }]
}
```

## Testing

To test async handling:

1. **Make a request** to Ollama Controller
2. **Check the response** - if `status: "queued"`, it's working
3. **Wait for completion** - the helper polls automatically
4. **Verify result** - should have `choices` array

## Error Handling

The helper handles:
- ✅ **HTTP 400** - Request not completed yet (continue polling)
- ✅ **HTTP 404** - Request not found yet (continue polling)
- ✅ **Connection errors** - Continue polling
- ✅ **Timeouts** - Return error after max_poll_time
- ✅ **Failed requests** - Return error immediately

## Configuration

- **max_poll_time**: Maximum time to poll (default: 60 seconds)
- **poll_interval**: Time between polls (default: 0.5 seconds)
- **timeout**: Timeout for each status check (default: 5 seconds)

## DRY Principle

**All async handling is centralized** in `gtd_ai_helpers.py`:

- ✅ Single source of truth for polling logic
- ✅ Consistent error handling across all functions
- ✅ Easy to update if Ollama Controller API changes
- ✅ Fallback handling if helpers not available

## When Adding New AI Functions

**Always**:

1. Import `handle_ai_response` from `gtd_ai_helpers`
2. Check for async responses after initial request
3. Poll if needed using the helper
4. Use the polled result

**Never**:

- ❌ Assume responses are always immediate
- ❌ Skip async handling "because it's fast"
- ❌ Duplicate polling logic
- ❌ Return "No response" without checking for queued status

## Related Documentation

- `docs/OLLAMA_CONTROLLER_INTEGRATION.md` - General integration guide
- `docs/HOW_TO_USE_OLLAMA_CONTROLLER.md` - Usage guide
- `zsh/functions/gtd_ai_helpers.py` - Implementation


