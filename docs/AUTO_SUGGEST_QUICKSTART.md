# Auto-Suggest Quick Start Guide

**Get started with autonomous AI suggestion implementation in 5 minutes**

## What is Auto-Suggest?

Auto-Suggest automatically implements high-confidence AI suggestions, saving you time reviewing and applying obvious recommendations. Think "autopilot mode" for your GTD system.

**✨ Phase 2 & 3 are now available!** 
- **Phase 2**: Suggestion source integration, automated undo, scheduling, and enhanced statistics
- **Phase 3**: Discord notifications and smart threshold adjustment (self-tuning system!)

## 🚀 Quick Start (5 Steps)

### 1. Check Status

```bash
gtd-auto-suggest status
```

### 2. Test with Dry-Run (Safe)

```bash
gtd-auto-suggest run --dry-run
```

This shows what *would* happen without making changes.

### 3. Enable Dry-Run Mode

```bash
gtd-auto-suggest enable
```

Now it's enabled but still won't make actual changes.

### 4. Configure (Optional)

```bash
# Set confidence threshold for task suggestions
gtd-auto-suggest config --type task_suggestion --value 0.90

# Disable MoC suggestions (more conservative)
gtd-auto-suggest config --type moc_suggestion --value false
```

### 5. Go Live (When Ready)

```bash
gtd-auto-suggest enable --live
```

⚠️ **Warning**: This enables autonomous implementation! Only do this after testing in dry-run mode.

## 📊 Common Commands

```bash
# View current status
gtd-auto-suggest status

# Run in dry-run mode (safe preview)
gtd-auto-suggest run --dry-run

# Run in live mode (actually implement)
gtd-auto-suggest run --live

# View history of actions
gtd-auto-suggest history

# Disable auto-suggest
gtd-auto-suggest disable

# **Phase 2 Commands**

# List recent actions that can be undone
gtd-auto-suggest list-undo

# Undo most recent action
gtd-auto-suggest undo

# View statistics
gtd-auto-suggest stats

# Setup daily auto-run at 9 AM
gtd-auto-suggest-schedule install

# **Phase 3 Commands**

# Manually adjust thresholds based on acceptance patterns
gtd-auto-suggest adjust-thresholds

# Discord notifications happen automatically when enabled
# Configure in ~/Documents/gtd/.auto_suggest_config.json
```

## ⚙️ Recommended Settings

### Conservative (Recommended for New Users)

```bash
# Only enable task suggestions
gtd-auto-suggest config --type task_suggestion --value true
gtd-auto-suggest config --type project_suggestion --value false
gtd-auto-suggest config --type moc_suggestion --value false
gtd-auto-suggest config --type area_suggestion --value false

# High confidence threshold
gtd-auto-suggest config --type task_suggestion --value 0.92

# Enable in dry-run mode first
gtd-auto-suggest enable
```

### Balanced (For Regular Users)

```bash
# Enable task and project suggestions
gtd-auto-suggest config --type task_suggestion --value true
gtd-auto-suggest config --type project_suggestion --value true
gtd-auto-suggest config --type moc_suggestion --value false
gtd-auto-suggest config --type area_suggestion --value false

# Moderate thresholds
gtd-auto-suggest config --type task_suggestion --value 0.85
gtd-auto-suggest config --type project_suggestion --value 0.90

# Enable live mode
gtd-auto-suggest enable --live
```

### Aggressive (For Advanced Users)

```bash
# Enable all suggestion types
gtd-auto-suggest config --type task_suggestion --value true
gtd-auto-suggest config --type project_suggestion --value true
gtd-auto-suggest config --type moc_suggestion --value true
gtd-auto-suggest config --type area_suggestion --value true

# Lower thresholds (more suggestions implemented)
gtd-auto-suggest config --type task_suggestion --value 0.80
gtd-auto-suggest config --type project_suggestion --value 0.85
gtd-auto-suggest config --type moc_suggestion --value 0.90
gtd-auto-suggest config --type area_suggestion --value 0.90

# Enable live mode
gtd-auto-suggest enable --live
```

## 🛡️ Safety Features

Auto-suggest has multiple safety layers:

1. **Dry-Run Default**: Always starts in dry-run mode
2. **Confidence Thresholds**: Only implements high-confidence suggestions
3. **Rate Limits**: Max 5 actions per run, 20 per day (default)
4. **Automatic Backups**: Creates backups before file modifications
5. **Audit Trail**: Complete log of all actions
6. **Whitelist/Blacklist**: Pattern-based filtering

## 📈 Typical Workflow

```bash
# Week 1: Test in dry-run
gtd-auto-suggest enable
gtd-auto-suggest run --dry-run  # Run daily
gtd-auto-suggest history         # Review at end of week

# Week 2: Enable live for one type
gtd-auto-suggest config --type task_suggestion --value true
gtd-auto-suggest enable --live
gtd-auto-suggest run             # Run daily
gtd-auto-suggest history         # Review at end of week

# Week 3+: Enable more types as confident
gtd-auto-suggest config --type project_suggestion --value true
# Continue monitoring
```

## 🔧 Configuration Files

### Config Location
`~/Documents/gtd/.auto_suggest_config.json`

### Action Log
`~/Documents/gtd/auto_suggest_actions.jsonl`

### Backups
`~/Documents/gtd/.auto_suggest_undo/`

## 🎯 Use Cases

### 1. Daily Task Organization
Let auto-suggest handle routine task organization (moving tasks to projects, assigning areas).

**Setup:**
```bash
gtd-auto-suggest config --type task_suggestion --value true
gtd-auto-suggest config --type task_suggestion --value 0.88
gtd-auto-suggest enable --live
```

### 2. Project Management
Auto-create suggested projects from related tasks.

**Setup:**
```bash
gtd-auto-suggest config --type project_suggestion --value true
gtd-auto-suggest config --type project_suggestion --value 0.90
gtd-auto-suggest enable --live
```

### 3. Knowledge Organization
Automatically implement suggested MoCs and Areas (more conservative).

**Setup:**
```bash
gtd-auto-suggest config --type moc_suggestion --value true
gtd-auto-suggest config --type area_suggestion --value true
gtd-auto-suggest config --type moc_suggestion --value 0.95
gtd-auto-suggest config --type area_suggestion --value 0.95
gtd-auto-suggest enable --live
```

## ⚡ From the Wizard

Access auto-suggest from the GTD Wizard:

```
Main Menu
  → 9) AI Suggestions & MCP Tools
    → 19) 🤖 Auto-Suggest Controls
```

From there you can:
- View status
- Run in dry-run or live mode
- Configure settings
- View history

## 🚨 Troubleshooting

### "Daily action limit reached"
```bash
# Check usage
gtd-auto-suggest status

# Increase limit if needed (edit config)
vim ~/Documents/gtd/.auto_suggest_config.json
# Change "max_actions_per_day": 30
```

### "No pending suggestions found"
Make sure suggestion sources are generating suggestions first:
- Run task suggestions: Option 1 in AI Suggestions menu
- Run knowledge org scan: Option 16 in AI Suggestions menu

### "Auto-suggest is disabled"
```bash
gtd-auto-suggest enable
```

### View detailed error logs
```bash
cat ~/Documents/gtd/auto_suggest_actions.jsonl | jq 'select(.success == false)'
```

## 📚 Learn More

- [Complete Documentation](AUTO_SUGGEST_SYSTEM.md)
- [Unified Learning System](UNIFIED_LEARNING_SYSTEM.md)
- [Enhanced Learning Features](ENHANCED_LEARNING_FEATURES.md)

## 💡 Pro Tips

1. **Start Small**: Enable one type at a time
2. **Monitor Daily**: Check history for first 2 weeks
3. **Use Learning**: Let the system learn your preferences for 2+ weeks
4. **Adjust Thresholds**: Fine-tune based on observed accuracy
5. **Keep Backups**: Don't disable `require_backup` setting
6. **Review Logs**: Periodically check action log for patterns

## 🎓 Next Steps

After getting comfortable with auto-suggest:

1. **Schedule Automatic Runs** (see full docs)
2. **Integrate with Learning System** (already built-in)
3. **Create Custom Filters** (whitelist/blacklist patterns)
4. **Set Up Notifications** (planned feature)
5. **Tune Confidence Thresholds** based on learning stats

---

**Remember**: Auto-suggest is designed to handle the *obvious* suggestions automatically, letting you focus on the interesting/complex decisions. Start conservative and gradually increase automation as you gain confidence in the system.

