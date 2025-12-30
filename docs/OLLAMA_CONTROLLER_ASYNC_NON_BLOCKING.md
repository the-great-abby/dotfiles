# Ollama Controller Non-Blocking Async Requests

## Overview

Instead of blocking for up to 30 minutes waiting for AI requests to complete, the new async system allows you to:

1. **Submit requests** and return immediately
2. **Background worker** polls all pending requests in a loop
3. **Multiple requests** can run in parallel without blocking
4. **Callbacks** notify when requests complete

## Benefits

- ✅ **Non-blocking**: Submit and continue working
- ✅ **Parallel processing**: Multiple requests can be in-flight
- ✅ **Background polling**: Single worker checks all requests
- ✅ **No 30-minute wait**: Returns immediately with request_id

## Usage

### Basic Example

```python
from gtd_ai_async import submit_ai_request_async

# Submit request - returns immediately
url = "http://127.0.0.1:31080/v1/chat/completions"
payload = {
    "model": "qwen3:4b",
    "messages": [{"role": "user", "content": "Hello"}],
    "priority": 20
}

request_id, error = submit_ai_request_async(
    url=url,
    payload=payload,
    max_poll_time=1800.0,  # 30 minutes
    poll_interval=2.0  # Check every 2 seconds
)

if error:
    print(f"Error: {error}")
elif request_id:
    print(f"Request submitted: {request_id}")
    # Request is now being polled in background
    # Continue with other work...
else:
    # Immediate response (rare for queued requests)
    result = json.loads(request_id)
    print(result['choices'][0]['message']['content'])
```

### With Callback

```python
def on_complete(result: str, error: Optional[str]):
    if error:
        print(f"Request failed: {error}")
    else:
        data = json.loads(result)
        content = data['choices'][0]['message']['content']
        print(f"Response: {content}")

request_id, error = submit_ai_request_async(
    url=url,
    payload=payload,
    callback=on_complete  # Called when request completes
)

# Request submitted, callback will be called when done
# Continue with other work...
```

### With Result File

```python
request_id, error = submit_ai_request_async(
    url=url,
    payload=payload,
    result_file="deep_analysis_2024-01-15.json"  # Saved when complete
)

# Result will be saved to ~/.gtd/ai_results/deep_analysis_2024-01-15.json
```

### Check Status Manually

```python
from gtd_ai_async import check_request_status

result, error, is_complete = check_request_status(request_id)

if is_complete:
    if error:
        print(f"Error: {error}")
    else:
        print(f"Result: {result}")
else:
    print("Still processing...")
```

## How It Works

### 1. Request Submission

```
Your Code
  ↓
submit_ai_request_async()
  ↓
Makes HTTP request
  ↓
If queued → Store request_id → Return immediately ✅
If immediate → Return result ✅
```

### 2. Background Polling

```
Background Thread (runs continuously)
  ↓
Every 0.5 seconds:
  - Check all pending requests
  - Poll status endpoint for each
  - If complete → Call callback, save result
  - If timeout → Remove, call callback with error
  - If still pending → Continue polling
```

### 3. Multiple Requests

```
Request 1 (submitted) → Background worker polls it
Request 2 (submitted) → Background worker polls it
Request 3 (submitted) → Background worker polls it
...
All requests polled in parallel, no blocking!
```

## Integration with Existing Code

### Option 1: Use Async for Long-Running Requests

```python
from gtd_ai_async import submit_ai_request_async

# For background tasks (deep analysis, etc.)
def call_deep_ai_async(prompt: str, system_prompt: str = None):
    url = DEEP_MODEL_URL
    payload = {
        "model": actual_model_name,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "priority": 20
    }
    
    def on_complete(result, error):
        if error:
            # Handle error (log, notify, etc.)
            pass
        else:
            # Process result (save, notify, etc.)
            data = json.loads(result)
            content = data['choices'][0]['message']['content']
            # Do something with content...
    
    request_id, error = submit_ai_request_async(
        url=url,
        payload=payload,
        callback=on_complete,
        max_poll_time=1800.0  # 30 minutes
    )
    
    return request_id  # Return immediately
```

### Option 2: Hybrid Approach

For interactive requests, use blocking (fast response needed).
For background tasks, use async (can wait, don't block).

```python
from gtd_ai_helpers import handle_ai_response

# Interactive request - use blocking
if is_interactive:
    result, error = handle_ai_response(result, base_url, max_poll_time=60.0)
else:
    # Background task - use async
    from gtd_ai_async import submit_ai_request_async
    request_id, error = submit_ai_request_async(url, payload)
```

## Configuration

### Polling Interval

Default: 2 seconds between checks
- Lower = more responsive, more API calls
- Higher = less API calls, slower detection

### Max Poll Time

Default: 1800 seconds (30 minutes)
- How long to keep polling before giving up
- Should match expected processing time

### Result Storage

Results are stored in: `~/.gtd/ai_results/`
Pending requests: `~/.gtd/pending_ai_requests.json`

## Monitoring

### Check Pending Requests

```python
from gtd_ai_async import get_pending_requests

pending = get_pending_requests()
for request_id, info in pending.items():
    elapsed = time.time() - info['submitted_at']
    print(f"{request_id}: {elapsed:.1f}s elapsed")
```

### Stop Polling

```python
from gtd_ai_async import stop_polling

stop_polling()  # Stops background thread
```

## Migration Guide

### Before (Blocking)

```python
# Blocks for up to 30 minutes
result, error = handle_ai_response(result, base_url, max_poll_time=1800.0)
if error:
    return f"Error: {error}"
content = result['choices'][0]['message']['content']
```

### After (Non-Blocking)

```python
# Returns immediately
request_id, error = submit_ai_request_async(url, payload, callback=on_complete)
if error:
    return f"Error: {error}"
# Continue with other work, callback handles result
```

## Best Practices

1. **Use async for background tasks** (deep analysis, batch processing)
2. **Use blocking for interactive** (user queries, real-time responses)
3. **Set appropriate timeouts** based on expected processing time
4. **Use callbacks** to handle results asynchronously
5. **Save results to files** for long-running tasks
6. **Monitor pending requests** to track progress

## Example: Deep Analysis Worker

```python
def process_analysis_job(job_data):
    prompt = job_data['prompt']
    
    def on_complete(result, error):
        if error:
            save_error(job_data['job_id'], error)
        else:
            data = json.loads(result)
            content = data['choices'][0]['message']['content']
            save_result(job_data['job_id'], content)
    
    request_id, error = submit_ai_request_async(
        url=DEEP_MODEL_URL,
        payload={
            "model": "qwen3:4b",
            "messages": [{"role": "user", "content": prompt}],
            "priority": 20
        },
        callback=on_complete,
        result_file=f"analysis_{job_data['job_id']}.json"
    )
    
    # Job submitted, continue processing other jobs
    # Result will be saved when complete
```




