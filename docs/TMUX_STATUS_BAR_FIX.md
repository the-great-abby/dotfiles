# tmux Status Bar Fix - Quick Reference

## The Issue

The tmux status bar shows ANSI escape codes instead of clean text:
```
gtd-suite │ [0m 0 | [0;36m✅[0m 83 | [0;36m📁[0m 7 | ...
```

## The Solution

Your `~/.tmux.conf` has been updated to use `--plain` mode, but your current session needs to reload it.

## ⚡ Quick Fix (2 seconds)

**Inside your tmux session, press:**
```
Ctrl+a r
```

You should see: `✅ Config reloaded!`

The status bar will immediately update to show clean text:
```
gtd-suite │ 🎯 GTD 2025-12-18 14:50 | 📥 0 | ✅ 83 | 📁 7 | 🎯 9 | 💡 0 │ 14:50 18-Dec
```

## Alternative: Restart Session

If reload doesn't work:
```bash
# Exit tmux (or press Ctrl+a d to detach)
# Then kill and restart:
tmux kill-session -t gtd-suite
gtd-tmux start productivity
```

## How to Verify It's Fixed

Look at the bottom status bar:
- ❌ **Bad:** Shows `[0m`, `[0;36m`, etc.
- ✅ **Good:** Shows clean emojis and numbers

## Why This Happened

1. You started tmux session with old config
2. We updated `~/.tmux.conf` while session was running  
3. tmux doesn't auto-reload configs
4. Need manual reload: `Ctrl+a r`

## Remember

After updating `~/.tmux.conf`:
- **Existing sessions:** Press `Ctrl+a r` to reload
- **New sessions:** Will automatically use new config

