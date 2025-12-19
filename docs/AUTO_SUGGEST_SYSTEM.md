# GTD Auto-Suggest System

**Autonomous AI Suggestion Implementation with Safety Controls**

## Overview

The Auto-Suggest System enables autonomous implementation of high-confidence AI suggestions, reducing manual review overhead while maintaining safety and control. Think of it as "autopilot mode" for your GTD system.

### Key Features

- 🤖 **Autonomous Implementation**: Automatically implements high-confidence suggestions
- 🛡️ **Safety Controls**: Multiple layers of protection (dry-run, thresholds, limits)
- 📊 **Confidence-Based**: Uses learned thresholds from the unified learning system
- 🔍 **Audit Trail**: Complete logging of all actions taken
- ↩️ **Undo Support**: Backup and restore functionality
- ⚙️ **Highly Configurable**: Per-type settings, whitelist/blacklist, rate limits

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Auto-Suggest System                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────┐    ┌─────────────┐   ┌──────────────┐ │
│  │  Pending   │ -> │  Filter by  │ ->│  Implement   │ │
│  │ Suggestions│    │ Confidence  │   │ Suggestions  │ │
│  └────────────┘    └─────────────┘   └──────────────┘ │
│         │                  │                  │         │
│         v                  v                  v         │
│  ┌────────────┐    ┌─────────────┐   ┌──────────────┐ │
│  │  Learning  │    │   Safety    │   │   Action     │ │
│  │   System   │    │   Checks    │   │   Logging    │ │
│  └────────────┘    └─────────────┘   └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Integration Points

1. **Unified Learning System**: Pulls confidence thresholds and records decisions
2. **Suggestion Sources**: Task suggestions, project suggestions, knowledge organization
3. **GTD Tools**: Uses `gtd-task-organize`, `gtd-project`, `gtd-moc`, `gtd-area`
4. **Action Log**: JSONL format audit trail for all actions

## Quick Start

### 1. Check Status

```bash
gtd-auto-suggest status
```

Shows:
- Global enable/disable state
- Dry-run vs live mode
- Action limits (per run, per day)
- Today's usage
- Type-specific configurations

### 2. Test with Dry-Run

**Always start with dry-run mode** to preview what would happen:

```bash
gtd-auto-suggest run --dry-run
```

This will:
- Show which suggestions would be implemented
- Display confidence levels
- Preview actions
- **NOT actually make any changes**

### 3. Enable (Dry-Run Mode)

Once comfortable, enable auto-suggest in dry-run mode:

```bash
gtd-auto-suggest enable
```

This allows scheduled runs but still won't make actual changes.

### 4. Enable Live Mode (⚠️ Use with Caution)

Only after thoroughly testing:

```bash
gtd-auto-suggest enable --live
```

This enables **autonomous implementation** of suggestions. Actions will be taken automatically based on confidence thresholds.

## Configuration

### Configuration File

Location: `~/Documents/gtd/.auto_suggest_config.json`

### Default Configuration

```json
{
  "enabled": false,
  "dry_run": true,
  "max_actions_per_run": 5,
  "max_actions_per_day": 20,
  "min_confidence_override": null,
  "type_configs": {
    "task_suggestion": {
      "enabled": true,
      "min_confidence": 0.85
    },
    "project_suggestion": {
      "enabled": true,
      "min_confidence": 0.90
    },
    "moc_suggestion": {
      "enabled": false,
      "min_confidence": 0.95
    },
    "area_suggestion": {
      "enabled": false,
      "min_confidence": 0.95
    }
  },
  "whitelist_patterns": [],
  "blacklist_patterns": [],
  "safety": {
    "require_backup": true,
    "max_file_size_kb": 500,
    "preserve_history": 30
  }
}
```

### Configuration via CLI

#### Enable/Disable a Type

```bash
# Disable MoC suggestions
gtd-auto-suggest config --type moc_suggestion --value false

# Enable task suggestions
gtd-auto-suggest config --type task_suggestion --value true
```

#### Adjust Confidence Thresholds

```bash
# Require 95% confidence for task suggestions
gtd-auto-suggest config --type task_suggestion --value 0.95

# Lower threshold to 80% for project suggestions
gtd-auto-suggest config --type project_suggestion --value 0.80
```

#### Edit Configuration Directly

```bash
# View current config
gtd-auto-suggest config

# Edit manually
vim ~/Documents/gtd/.auto_suggest_config.json
```

## Safety Features

### 1. Dry-Run Mode (Default)

System always starts in dry-run mode. Must explicitly enable live mode.

### 2. Confidence Thresholds

- **Type-specific minimums**: Each suggestion type has its own threshold
- **Learning integration**: Thresholds can be learned from user behavior
- **Conservative defaults**: Knowledge org suggestions require ≥95% confidence

### 3. Rate Limiting

- **Per-run limit**: Default 5 actions per run (prevent runaway execution)
- **Daily limit**: Default 20 actions per day (prevent excessive automation)
- Limits prevent system from making too many changes at once

### 4. Whitelist/Blacklist

```bash
# Add patterns to config
vim ~/Documents/gtd/.auto_suggest_config.json

# Example whitelist (only these patterns allowed)
"whitelist_patterns": ["*work*", "*project-x*"]

# Example blacklist (never auto-implement these)
"blacklist_patterns": ["*personal*", "*archive*"]
```

### 5. File Size Limits

Files larger than 500KB are not auto-edited by default (prevents unintended changes to large files).

### 6. Automatic Backups

Before implementing any suggestion that modifies a file:
- Creates timestamped backup in `~/Documents/gtd/.auto_suggest_undo/`
- Backups preserved for 30 days
- Enables manual rollback if needed

### 7. Complete Audit Trail

All actions logged to `~/Documents/gtd/auto_suggest_actions.jsonl`:

```json
{
  "suggestion_id": "task_001",
  "type": "task_suggestion",
  "description": "Move task to project X",
  "confidence": 0.92,
  "timestamp": "2025-12-17T10:30:45",
  "dry_run": false,
  "success": true,
  "backup_path": "/path/to/backup.md"
}
```

## Typical Workflows

### Workflow 1: Conservative Testing

1. Enable dry-run mode: `gtd-auto-suggest enable`
2. Run daily and review logs: `gtd-auto-suggest run --dry-run`
3. After 1-2 weeks, review results: `gtd-auto-suggest history`
4. Adjust thresholds if needed
5. Enable live mode for specific types only

### Workflow 2: Gradual Rollout

1. Start with task suggestions only (lowest risk):
   ```bash
   gtd-auto-suggest config --type task_suggestion --value true
   gtd-auto-suggest config --type project_suggestion --value false
   gtd-auto-suggest config --type moc_suggestion --value false
   gtd-auto-suggest config --type area_suggestion --value false
   ```

2. Enable live mode: `gtd-auto-suggest enable --live`

3. Monitor for 1 week: `gtd-auto-suggest history`

4. Gradually enable other types

### Workflow 3: Full Automation

For advanced users with high trust in the system:

1. Enable all types with high confidence thresholds
2. Set per-day limit to comfortable level (e.g., 10-15)
3. Enable live mode
4. Schedule daily runs (see Scheduling section)
5. Review weekly via history command

## CLI Reference

### Commands

| Command | Description |
|---------|-------------|
| `run` | Execute auto-suggest (respects config) |
| `status` | Show current configuration and usage |
| `enable` | Enable auto-suggest (optionally with `--live`) |
| `disable` | Disable auto-suggest |
| `config` | View or update configuration |
| `history` | Show action history |
| `help` | Show help message |

### Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Force dry-run mode (preview only) |
| `--live` | Force live mode (actually implement) |
| `--type TYPE` | Specify suggestion type for config |
| `--value VALUE` | Set configuration value |
| `--force` | Skip confirmations |

### Examples

```bash
# Show status
gtd-auto-suggest status

# Run in dry-run mode
gtd-auto-suggest run --dry-run

# Enable with live mode
gtd-auto-suggest enable --live

# Disable completely
gtd-auto-suggest disable

# Configure task suggestion threshold
gtd-auto-suggest config --type task_suggestion --value 0.90

# View action history
gtd-auto-suggest history

# Force run in live mode (override config)
gtd-auto-suggest run --live
```

## Wizard Integration

The auto-suggest system is integrated into the GTD Wizard:

```
Main Menu → AI Suggestions & MCP Tools → Option 19
```

From the wizard, you can:
- View current status
- Run in dry-run or live mode
- Enable/disable
- Configure thresholds
- View action history

## Scheduling (Future)

To run auto-suggest automatically (e.g., daily):

### Using Launchd (macOS)

```xml
<!-- ~/Library/LaunchAgents/com.gtd.auto-suggest.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gtd.auto-suggest</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/yourusername/code/dotfiles/bin/gtd-auto-suggest</string>
        <string>run</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/gtd-auto-suggest.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/gtd-auto-suggest.err</string>
</dict>
</plist>
```

Load with: `launchctl load ~/Library/LaunchAgents/com.gtd.auto-suggest.plist`

### Using Cron

```bash
# Run daily at 9 AM
0 9 * * * /Users/yourusername/code/dotfiles/bin/gtd-auto-suggest run >> /tmp/gtd-auto-suggest.log 2>&1
```

## Monitoring & Troubleshooting

### Check Today's Usage

```bash
gtd-auto-suggest status | grep "Today's usage"
```

### View Recent Actions

```bash
gtd-auto-suggest history
```

### Check Action Log

```bash
# View all actions
cat ~/Documents/gtd/auto_suggest_actions.jsonl

# View only successful actions
cat ~/Documents/gtd/auto_suggest_actions.jsonl | jq 'select(.success == true)'

# View only failures
cat ~/Documents/gtd/auto_suggest_actions.jsonl | jq 'select(.success == false)'

# Count actions by type
cat ~/Documents/gtd/auto_suggest_actions.jsonl | jq -r '.type' | sort | uniq -c
```

### Verify Backups

```bash
ls -lh ~/Documents/gtd/.auto_suggest_undo/
```

### Debug Mode

To see detailed Python output:

```bash
python3 ~/code/dotfiles/mcp/gtd_auto_suggest.py run --dry-run
```

## Integration with Learning System

The auto-suggest system is tightly integrated with the unified learning system:

1. **Pulls Thresholds**: Reads learned confidence thresholds per suggestion type
2. **Records Decisions**: All auto-implemented suggestions are recorded as "accept" decisions
3. **Continuous Learning**: Thresholds adjust over time based on all decisions (manual + auto)
4. **Explainability**: Can view why suggestions were auto-implemented via learning stats

Example workflow:
```bash
# Check learned thresholds
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats

# Run auto-suggest (uses learned thresholds)
gtd-auto-suggest run

# Review learning insights after auto-implementation
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py insights
```

## Best Practices

### 🚦 Start Conservative

1. ✅ Begin with dry-run mode
2. ✅ Enable only one suggestion type initially
3. ✅ Use high confidence thresholds (≥90%)
4. ✅ Set low per-day limits (5-10)
5. ✅ Review logs daily for first week

### 📊 Monitor Regularly

- Check `gtd-auto-suggest history` weekly
- Review learning stats: `python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats`
- Audit action log for unexpected behavior
- Verify backups are being created

### ⚙️ Tune Gradually

- Adjust thresholds based on observed accuracy
- Increase limits slowly as confidence grows
- Enable additional types one at a time
- Use whitelist/blacklist for edge cases

### 🛡️ Maintain Safety

- Keep `require_backup` enabled
- Don't set `max_actions_per_day` too high
- Review blacklist patterns regularly
- Test configuration changes in dry-run first

### 📈 Leverage Learning

- Let the system run for 2+ weeks to gather data
- Use learned thresholds instead of overrides
- Review cross-domain insights regularly
- Provide explicit feedback when system makes mistakes

## Limitations & Caveats

### Current Limitations

1. **Suggestion Source Integration**: Currently requires manual integration with suggestion sources (to be implemented)
2. **Undo Functionality**: Backups are created but automated undo not yet implemented
3. **Complex Suggestions**: Only supports suggestions with clear, deterministic actions
4. **No Preview UI**: No graphical preview of pending actions (CLI only)

### What Auto-Suggest Does NOT Do

- ❌ Make subjective decisions (e.g., writing content)
- ❌ Delete data without backup
- ❌ Override user-specified decisions
- ❌ Bypass safety checks
- ❌ Implement suggestions below confidence threshold
- ❌ Exceed configured rate limits

## Roadmap

### Phase 1 (Current)
- ✅ Core auto-suggest framework
- ✅ Safety controls (dry-run, thresholds, limits)
- ✅ Learning system integration
- ✅ CLI interface
- ✅ Wizard integration

### Phase 2 (Planned)
- [ ] Complete suggestion source integration
- [ ] Automated undo functionality
- [ ] Scheduling setup script
- [ ] Enhanced logging and analytics
- [ ] Notification system for actions taken

### Phase 3 (Future)
- [ ] Machine learning for confidence adjustment
- [ ] Pattern detection for suggestion types
- [ ] Visual dashboard for monitoring
- [ ] Mobile notifications
- [ ] A/B testing framework

## FAQ

**Q: Is it safe to enable live mode?**

A: Yes, with proper configuration. Start with high confidence thresholds (≥90%), enable only one type initially, and set conservative rate limits. The system creates backups before any file modifications.

**Q: What happens if something goes wrong?**

A: All actions are logged, and backups are created before file modifications. You can review the action log to see exactly what happened and restore from backups if needed.

**Q: How does auto-suggest decide which suggestions to implement?**

A: It filters suggestions based on:
1. Global enable/disable state
2. Type-specific enable/disable state
3. Confidence threshold (learned or configured)
4. Whitelist/blacklist patterns
5. Daily/per-run action limits

**Q: Can I rollback an auto-implemented suggestion?**

A: Manual rollback is currently supported by restoring from the backup files in `~/Documents/gtd/.auto_suggest_undo/`. Automated undo is planned for a future release.

**Q: How do I know what was auto-implemented?**

A: Check the action log:
```bash
gtd-auto-suggest history
# or
cat ~/Documents/gtd/auto_suggest_actions.jsonl | jq
```

**Q: Will auto-suggest interfere with my manual workflow?**

A: No. Auto-suggest only processes pending suggestions and records its decisions in the learning system. Your manual workflow continues normally.

**Q: Can I use auto-suggest for only specific types of suggestions?**

A: Yes! You can enable/disable each suggestion type independently:
```bash
gtd-auto-suggest config --type task_suggestion --value true
gtd-auto-suggest config --type moc_suggestion --value false
```

## Support

For issues or questions:
1. Check the action log: `gtd-auto-suggest history`
2. Review configuration: `gtd-auto-suggest status`
3. Test in dry-run mode: `gtd-auto-suggest run --dry-run`
4. Check learning stats: `python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats`

## See Also

- [Unified Learning System](UNIFIED_LEARNING_SYSTEM.md)
- [Enhanced Learning Features](ENHANCED_LEARNING_FEATURES.md)
- [Knowledge Organization System](KNOWLEDGE_ORGANIZATION_SYSTEM.md)
- [GTD Wizard Documentation](../README.md)

