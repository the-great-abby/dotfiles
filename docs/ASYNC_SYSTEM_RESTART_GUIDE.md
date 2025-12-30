# Async System Restart Guide

## Issue: Timeout After Implementing Async

After implementing the async system, you may still see timeouts if the Python modules haven't been reloaded.

## What Needs to Be Restarted

### ✅ Background Workers (Already Restarted)
- `gtd_deep_analysis_worker.py` - ✅ Restarted
- Other background workers - ✅ Restarted

### ❌ Python Modules (Need Reload)
The persona helper and other Python modules are **cached** when imported. Changes won't take effect until:

1. **Restart the calling process** (if it's a long-running process)
2. **Reload Python modules** (if using interactive Python)
3. **Restart your shell/terminal** (if calling from command line)

## How to Fix

### Option 1: Restart Your Shell/Terminal
```bash
# Exit and restart your terminal
# This will reload all Python modules
```

### Option 2: Clear Python Cache
```bash
# Find and remove Python cache files
find ~/code/dotfiles -name "*.pyc" -delete
find ~/code/dotfiles -name "__pycache__" -type d -exec rm -r {} +
```

### Option 3: Force Module Reload (Python)
If you're in a Python session:
```python
import importlib
import sys
# Remove from cache
if 'gtd_persona_helper' in sys.modules:
    del sys.modules['gtd_persona_helper']
if 'gtd_ai_helpers' in sys.modules:
    del sys.modules['gtd_ai_helpers']
if 'gtd_ai_async' in sys.modules:
    del sys.modules['gtd_ai_async']
# Re-import
from zsh.functions import gtd_persona_helper
```

## What Changed

### Persona Helper (`gtd_persona_helper.py`)
- **Before**: 60-second polling timeout
- **After**: 1800-second (30-minute) polling timeout
- Uses async system's polling with longer timeout

### Deep Analysis Worker (`gtd_deep_analysis_worker.py`)
- **Before**: Blocking for up to 30 minutes
- **After**: Non-blocking async submission
- Returns immediately, background worker handles polling

## Verification

After restarting, test with:
```bash
# Test persona helper (should now wait up to 30 minutes)
python3 ~/code/dotfiles/zsh/functions/gtd_persona_helper.py random "Test message"

# Check if async system is working
python3 -c "
import sys
sys.path.insert(0, '~/code/dotfiles/zsh/functions')
from gtd_ai_async import get_pending_requests
pending = get_pending_requests()
print(f'Pending requests: {len(pending)}')
"
```

## Configuration

The timeout is now controlled by:
- **Polling timeout**: 1800 seconds (30 minutes) - hardcoded in persona helper
- **Async system timeout**: 1800 seconds (30 minutes) - default in `gtd_ai_async.py`

You can adjust these if needed, but 30 minutes should handle most long-running requests.

## Troubleshooting

### Still Seeing 600-Second Timeout?

1. **Check config file**: `~/.gtd_config_ai` or `~/.gtd_config`
   - Look for `TIMEOUT="600"` or `LM_STUDIO_TIMEOUT="600"`
   - This affects the initial HTTP request timeout, not polling

2. **Check environment variables**:
   ```bash
   echo $TIMEOUT
   echo $LM_STUDIO_TIMEOUT
   ```

3. **Verify code changes**:
   ```bash
   grep -n "max_poll_time" ~/code/dotfiles/zsh/functions/gtd_persona_helper.py
   # Should show: max_poll_time = 1800.0
   ```

### Still Timing Out After 30 Minutes?

- The request might actually be taking longer than 30 minutes
- Check the Ollama Controller queue status
- Consider increasing the timeout further if needed




