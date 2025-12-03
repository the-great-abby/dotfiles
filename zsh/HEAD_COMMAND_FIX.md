# Head Command Fix

## Problem

When adding a daily log entry, the system was failing with:
```
zsh: command not found: head
```

This occurred when trying to read the user's name from the config file.

## Root Cause

The code was using `head -1` to get the first matching line from grep:
```bash
local name_line=$(grep -E "^GTD_USER_NAME=|^NAME=" "$gtd_config_file" 2>/dev/null | head -1)
```

However, `head` wasn't available in the PATH at that moment (possibly due to mise PATH modifications or other PATH issues).

## Solution

Replaced `head -1` with `grep -m 1`, which does the same thing (stops after the first match) but is more portable and doesn't require a separate command:

```bash
local name_line=$(grep -m 1 -E "^GTD_USER_NAME=|^NAME=" "$gtd_config_file" 2>/dev/null)
```

The `-m 1` flag tells grep to stop after the first match, which is exactly what `head -1` was doing.

## Benefits

1. **No PATH dependency**: `grep` is more reliably available than `head`
2. **More efficient**: One command instead of two (no pipe)
3. **More portable**: Works consistently across different systems

## Files Changed

- `zsh/zshrc_mac_mise` (line ~1243)

The fix ensures that user name extraction works reliably without requiring `head` to be in the PATH.

