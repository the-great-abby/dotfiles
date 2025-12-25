# Ollama Controller Priority System

## Overview

The Ollama Controller uses a priority-based queuing system where **higher numbers = higher priority** (more important).

## Priority Levels

### Foreground Tasks (30+)
**Use for:** User-initiated, interactive requests that need immediate processing

- **30 = HIGH** - Important interactive requests
  - Persona helper queries (`gtd_persona_helper.py`)
  - Wizard AI features
  - Interactive AI suggestions
  - Real-time user requests

- **40 = URGENT** - Critical interactive requests
  - Emergency queries
  - Time-sensitive user requests

### Background Tasks (20 or lower)
**Use for:** Scheduled tasks, batch processing, async jobs

- **20 = NORMAL** - Standard background tasks (default)
  - Deep analysis worker (`gtd_deep_analysis_worker.py`)
  - Scheduled reviews
  - Batch processing
  - Auto-suggestions

- **10 = LOW** - Background tasks that can wait
  - Non-urgent batch jobs
  - Maintenance tasks
  - Low-priority analysis

## How It Works

### Worker Behavior

The controller worker processes requests based on priority:

1. **High Priority First** (≥30): Processed immediately, even during active periods
2. **Normal/Low Priority** (<30): Processed only when:
   - No high priority requests are queued
   - No recent activity (no requests completed in last 5 minutes)

This throttling prevents background tasks from overwhelming the system during active use.

### Request Flow

```
User Request (Priority 30)
  ↓
Controller API
  ↓
Queue (sorted by priority)
  ↓
Worker picks highest priority
  ↓
Processes immediately ✅

Background Task (Priority 20)
  ↓
Controller API
  ↓
Queue (sorted by priority)
  ↓
Worker checks for high priority first
  ↓
If no recent activity → Process ✅
If recent activity → Wait (throttled) ⏳
```

## Setting Priority in Code

### Foreground Requests (Interactive)

```python
# In gtd_persona_helper.py
payload = {
    "model": model_name,
    "messages": [...],
    "priority": 30,  # HIGH for interactive requests
    ...
}
```

Or use the `is_background` parameter:

```python
call_persona(config, persona_key, content, is_background=False)  # Uses priority 30
```

### Background Requests

```python
# In gtd_deep_analysis_worker.py
payload = {
    "model": model_name,
    "messages": [...],
    "priority": 20,  # NORMAL for background tasks
    ...
}
```

Or use the `is_background` parameter:

```python
call_persona(config, persona_key, content, is_background=True)  # Uses priority 20
```

## Current Implementation

### ✅ Updated Files

1. **`zsh/functions/gtd_persona_helper.py`**
   - Default priority: **30** (HIGH) for foreground requests
   - Supports `is_background` parameter for background tasks
   - Followup requests use same priority as original

2. **`mcp/gtd_deep_analysis_worker.py`**
   - Uses priority **20** (NORMAL) for all background analysis tasks

### 📝 Priority Mapping

| Task Type | Priority | Code Location |
|-----------|----------|---------------|
| Persona helper (interactive) | 30 | `gtd_persona_helper.py` |
| Wizard AI features | 30 | `gtd_persona_helper.py` |
| Deep analysis worker | 20 | `gtd_deep_analysis_worker.py` |
| Scheduled reviews | 20 | Background workers |
| Batch processing | 20 | Background workers |

## Testing

Test priority settings:

```bash
# Test foreground request (priority 30)
python3 zsh/functions/gtd_persona_helper.py skippy "test"

# Test with explicit background flag
python3 -c "
from zsh.functions.gtd_persona_helper import call_persona, read_config
config = read_config()
result = call_persona(config, 'skippy', 'test', is_background=True)
print(result)
"
```

## Benefits

1. **Responsive UI**: Interactive requests (30+) process immediately
2. **System Protection**: Background tasks (20) are throttled during active use
3. **Resource Management**: Prevents overwhelming Ollama with batch jobs
4. **Fair Queuing**: Higher priority requests always processed first

## Notes

- Priority is **not** like Unix niceness (lower = better)
- Higher numbers = higher priority (more important)
- Default for interactive requests: **30** (HIGH)
- Default for background tasks: **20** (NORMAL)
- Throttling window: 5 minutes (no low priority if recent activity)

