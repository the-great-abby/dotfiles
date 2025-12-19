# gtd-dashboard - Command Center Quick Reference

**Created:** December 18, 2025  
**Purpose:** Standalone command to view GTD Command Center status

---

## 🎯 Quick Start

```bash
# Show full dashboard
gtd-dashboard

# Compact one-liner (great for status bars!)
gtd-dashboard --compact

# Watch mode - auto-refresh every 5 seconds
gtd-dashboard --watch

# Custom refresh interval
gtd-dashboard --watch --interval 10
```

---

## 📊 What It Shows

### Full Mode (`gtd-dashboard`)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 GTD Command Center
   Thursday, 2025-12-18 13:00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 System Status

  ✓ Inbox: Empty
  ✅ Active Tasks: 83
  📁 Active Projects: 7
  🎯 Areas: 9

📈 Quick Stats

  🔥 Logging Streak: 16 day(s)
  📝 Today's Entries: 7
```

### Compact Mode (`gtd-dashboard --compact`)

```
🎯 GTD 2025-12-18 13:01 | 📥 0 | ✅ 83 | 📁 7 | 🎯 9
```

**Format:** `Date Time | Inbox | Tasks | Projects | Areas`

---

## 💡 Use Cases

### 1. Quick Status Check

```bash
# Just want to see status without opening wizard
gtd-dashboard
```

### 2. Terminal Multiplexer Panel (tmux/screen)

```bash
# In a dedicated pane
gtd-dashboard --watch

# Or with custom interval
gtd-dashboard --watch --interval 30
```

### 3. Shell Prompt Integration

Add to your `.zshrc` or `.bashrc`:

```bash
# Function to show compact GTD status
gtd_prompt() {
  gtd-dashboard --compact 2>/dev/null || echo "🎯 GTD"
}

# Add to your PS1/PROMPT
# Example for zsh:
PROMPT='$(gtd_prompt) %~ %# '
```

### 4. Status Bar (Polybar/i3status/etc)

```bash
# In your status bar config
[module/gtd]
exec = gtd-dashboard --compact
interval = 60
```

### 5. Alfred/Spotlight Workflow

```bash
# Quick lookup via launcher
gtd-dashboard | pbcopy  # Copy to clipboard
```

### 6. Monitoring Dashboard

```bash
# Terminal 1: Your work
# Terminal 2: Live GTD status
gtd-dashboard --watch --interval 30
```

---

## 🎨 Options

| Option | Short | Description |
|--------|-------|-------------|
| `--watch` | `-w` | Continuous refresh mode |
| `--interval SEC` | `-i` | Set refresh interval (seconds) |
| `--compact` | `-c` | One-line compact display |
| `--help` | `-h` | Show help message |

---

## 📋 Comparison with Other Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `gtd-wizard` | Full interactive wizard | When you want to DO something |
| `gtd-dashboard` | Quick status view | When you want to CHECK something |
| `gtd-review` | Detailed review process | Weekly/daily reviews |
| `gtd-task list` | View just tasks | Focus on tasks only |

---

## 🔧 Integration Examples

### tmux Configuration

```bash
# .tmux.conf
# Bottom-right pane showing GTD status
bind-key G split-window -h -p 30 'gtd-dashboard --watch'
```

### Zsh/Bash Aliases

```bash
# Quick aliases
alias gtds='gtd-dashboard'
alias gtdw='gtd-dashboard --watch'
alias gtdc='gtd-dashboard --compact'
```

### Keyboard Shortcut (macOS)

```bash
# Create Quick Action in Automator:
# Run Shell Script → gtd-dashboard
# Assign keyboard shortcut in System Preferences
```

---

## 🎯 Pro Tips

### 1. **Check Before Starting Work**
```bash
gtd-dashboard
# See if inbox needs processing before diving in
```

### 2. **Quick Glance While Working**
```bash
gtd-dashboard --compact
# Fast one-liner when you need a quick check
```

### 3. **Monitor During Deep Work**
```bash
gtd-dashboard --watch --interval 300
# Check every 5 minutes in a side window
```

### 4. **Script Integration**
```bash
# Check inbox count in scripts
inbox_count=$(gtd-dashboard --compact | grep -oP '📥 \K\d+')
if [ "$inbox_count" -gt 5 ]; then
    notify-send "GTD" "Inbox has $inbox_count items!"
fi
```

### 5. **Morning Routine**
```bash
# Add to your morning script
echo "Good morning! Here's your GTD status:"
gtd-dashboard
```

---

## 🆚 vs Full Wizard

### Use `gtd-wizard` when you want to:
- ✅ Process inbox
- ✅ Add/complete tasks
- ✅ Manage projects
- ✅ Review system
- ✅ Configure settings

### Use `gtd-dashboard` when you want to:
- 👁️ Just see status
- 👁️ Quick glance at numbers
- 👁️ Monitor in background
- 👁️ Check without interruption

---

## 🐛 Troubleshooting

### Dashboard doesn't show

```bash
# Check if GTD system is set up
ls ~/Documents/gtd/

# Check if required files exist
ls ~/code/dotfiles/bin/gtd-common.sh
ls ~/code/dotfiles/bin/gtd-wizard-core.sh
```

### Colors not showing

```bash
# Your terminal might not support colors
# Try with basic output
gtd-dashboard --compact
```

### Watch mode not updating

```bash
# Check terminal size
# Watch mode requires clearing screen
# Use standard mode in small terminals
gtd-dashboard
```

---

## 📊 Output Format Details

### System Status Indicators

| Icon | Meaning | Color |
|------|---------|-------|
| 📥 | Inbox items | Red if > 0, Green if empty |
| ✅ | Active tasks | Cyan |
| 📁 | Active projects | Cyan |
| 🎯 | Areas of responsibility | Cyan |

### Quick Stats

| Icon | Meaning |
|------|---------|
| 🔥 | Logging streak (days) |
| 📝 | Today's log entries |

---

## 🚀 Future Enhancements (Ideas)

- [ ] `--json` output for scripting
- [ ] `--color/--no-color` flag
- [ ] `--quiet` mode (numbers only)
- [ ] Notification thresholds
- [ ] Historical trends
- [ ] Integration with gtd-notify
- [ ] Desktop widget support

---

## 📝 Related Commands

- `gtd-wizard` - Full interactive wizard
- `gtd-task list` - List tasks
- `gtd-project list` - List projects
- `gtd-review` - Review system
- `gtd-advice-monitor` - Monitor advice worker
- `gtd-help` - GTD help system

---

## 🎓 Best Practices

1. **Morning Check** - Run `gtd-dashboard` first thing
2. **Regular Glances** - Check compactly throughout day
3. **Watch Mode** - Use in dedicated window during work blocks
4. **Integration** - Add to your shell prompt or status bar
5. **Quick Reference** - Keep it easily accessible

---

## 📚 More Info

- Full wizard documentation: `docs/GTD_QUICK_REFERENCE.md`
- Command reference: `gtd-help`
- Quick start: `gtd-wizard` and follow prompts

---

**Command:** `gtd-dashboard`  
**Location:** `bin/gtd-dashboard`  
**Created:** December 18, 2025  
**Status:** ✅ Production Ready

