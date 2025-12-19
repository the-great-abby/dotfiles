# Auto-Suggest Phase 3 - Intelligence & Notifications

**Status:** ✅ Complete  
**Release Date:** December 17, 2025

## Overview

Phase 3 adds intelligence and visibility to the Auto-Suggest system through Discord notifications and automatic threshold adjustment based on your acceptance patterns.

## What's New in Phase 3

### 1. 🔔 Discord Notifications ✅

Get real-time updates on auto-suggest activity directly in Discord.

#### Notification Types

**1. Action Notifications** (Real-time)
```
🤖 Auto-Suggest Action
✅ Create task: 'Review Q4 financials'

Type: task_suggestion
Confidence: 92%
```

**2. Daily Summary** (End of day or after scheduled run)
```
📊 Auto-Suggest Daily Summary
Summary for 2025-12-17

✅ Successful: 12
❌ Failed: 1
⏭️ Skipped: 8
📊 Success Rate: 92%

By Type:
  • task_suggestion: 8
  • project_suggestion: 3
  • area_assignment: 1
```

**3. Error Alerts** (When failures occur)
```
🤖 Auto-Suggest Action
❌ Failed to create MoC: 'Deep Learning'

Type: moc_suggestion
Confidence: 88%
Error: Directory permission denied
```

**4. Threshold Adjustments** (Weekly, when thresholds change)
```
⚙️ Auto-Suggest Threshold Adjusted
Type: task_suggestion
Old Threshold: 85%
New Threshold: 82%
Change: ↓ Decreased by 3%

Reason: High acceptance rate (94%) allows lowering threshold
```

#### Configuration

Discord notifications use your existing webhook configuration:

```bash
# Check if webhook is configured
echo $GTD_DISCORD_WEBHOOK_URL

# If not set, add to your .zshrc or .gtd_config:
export GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

#### Notification Settings

Configure in `~/Documents/gtd/.auto_suggest_config.json`:

```json
{
  "notifications": {
    "discord_enabled": true,
    "notify_on_action": true,
    "notify_daily_summary": true,
    "notify_on_error": true,
    "notify_threshold_adjustment": true
  }
}
```

**Control what you receive:**
- `notify_on_action`: Get notified for every action (can be noisy if many actions)
- `notify_daily_summary`: Once-daily summary (recommended)
- `notify_on_error`: Only failures (quiet but keeps you informed)
- `notify_threshold_adjustment`: Know when system adjusts itself

**Recommended Settings:**

For active monitoring:
```json
{
  "notify_on_action": false,
  "notify_daily_summary": true,
  "notify_on_error": true,
  "notify_threshold_adjustment": true
}
```

For debugging:
```json
{
  "notify_on_action": true,
  "notify_daily_summary": false,
  "notify_on_error": true,
  "notify_threshold_adjustment": true
}
```

For minimal notifications:
```json
{
  "notify_on_action": false,
  "notify_daily_summary": true,
  "notify_on_error": false,
  "notify_threshold_adjustment": false
}
```

### 2. 🤖 Smart Threshold Adjustment ✅

Automatically tunes confidence thresholds based on your acceptance patterns.

#### How It Works

The system analyzes your decision history:
- **High acceptance rate** (>95%) → Lower threshold (show more suggestions)
- **Low acceptance rate** (<75%) → Raise threshold (be more selective)
- **Target rate** (85%) → Maintains optimal balance

#### Example Scenario

**Initial State:**
- Task suggestions: 85% threshold
- Your acceptance rate: 94% (you accept almost everything)

**After Analysis:**
- System lowers threshold to 82%
- Now you see slightly more suggestions
- Still maintains high quality (your acceptance pattern indicates you can handle it)

**Another Scenario:**
- MoC suggestions: 95% threshold
- Your acceptance rate: 68% (you reject many)

**After Analysis:**
- System raises threshold to 97%
- Now you see fewer, higher-confidence suggestions
- Reduces noise and improves your experience

#### Configuration

Enable in `~/Documents/gtd/.auto_suggest_config.json`:

```json
{
  "smart_thresholds": {
    "enabled": false,
    "min_threshold": 0.70,
    "max_threshold": 0.98,
    "adjustment_interval_days": 7,
    "min_samples": 20,
    "target_acceptance_rate": 0.85
  }
}
```

**Settings explained:**
- `enabled`: Turn smart adjustment on/off
- `min_threshold`: Never go below 70% (safety minimum)
- `max_threshold`: Never go above 98% (leave some automation)
- `adjustment_interval_days`: Review every 7 days
- `min_samples`: Need 20+ decisions before adjusting (ensures statistical validity)
- `target_acceptance_rate`: Aim for 85% acceptance (balance of precision/recall)

#### Running Threshold Adjustment

**Manual run:**
```bash
gtd-auto-suggest adjust-thresholds
```

**Automatic (scheduled):**
When you use the scheduler (`gtd-auto-suggest-schedule install`), threshold adjustment runs automatically once per week.

**Output example:**
```
Analyzing acceptance rates and adjusting thresholds...

✓ Threshold Adjustments Made:
============================================================

task_suggestion:
  Old threshold: 85%
  New threshold: 82%
  Acceptance rate: 94%
  Reason: High acceptance rate (94%) allows lowering threshold

project_suggestion:
  Old threshold: 90%
  New threshold: 93%
  Acceptance rate: 73%
  Reason: Low acceptance rate (73%) requires raising threshold

Skipped Types:
============================================================
  moc_suggestion: Not enough samples (12 < 20)
  area_assignment: Acceptance rate (86%) is within target range

Current configuration:
  task_suggestion: 82%
  project_suggestion: 93%
  area_assignment: 90%
  moc_suggestion: 95%
  area_suggestion: 95%
```

## Complete Feature Set

### Phase 1 & 2 Features
- ✅ Autonomous suggestion implementation
- ✅ Suggestion source integration
- ✅ Safety controls
- ✅ Undo functionality
- ✅ Scheduling
- ✅ Statistics

### Phase 3 Additions
- ✅ **Discord notifications** - Real-time updates and summaries
- ✅ **Smart threshold adjustment** - Self-tuning based on your patterns
- ✅ **Scheduled threshold reviews** - Automatic weekly optimization
- ✅ **Multiple notification types** - Actions, summaries, errors, adjustments

## CLI Reference

### New Commands (Phase 3)

```bash
# Manually run threshold adjustment
gtd-auto-suggest adjust-thresholds

# Status shows notification and smart threshold config
gtd-auto-suggest status
```

### Configuration Commands

```bash
# Enable smart thresholds
# Edit config file:
vim ~/Documents/gtd/.auto_suggest_config.json
# Set "smart_thresholds": { "enabled": true }

# Disable action notifications (keep summaries)
# Edit config file:
vim ~/Documents/gtd/.auto_suggest_config.json
# Set "notify_on_action": false

# View current config
gtd-auto-suggest config
```

## Usage Patterns

### Pattern 1: Fully Automated Intelligence

```bash
# One-time setup
gtd-auto-suggest enable --live
gtd-auto-suggest-schedule install

# Enable smart thresholds
vim ~/Documents/gtd/.auto_suggest_config.json
# Set "smart_thresholds": { "enabled": true }

# Configure Discord (if not already)
export GTD_DISCORD_WEBHOOK_URL="your-webhook-url"

# System now:
# - Runs daily at 9 AM
# - Implements suggestions
# - Sends Discord summary
# - Adjusts thresholds weekly
# - Notifies you of changes
```

### Pattern 2: Monitored Automation

```bash
# Run manually with notifications
gtd-auto-suggest run --live

# Check Discord for:
# - What was implemented
# - Success/failure status
# - Daily summary

# Review and adjust weekly
gtd-auto-suggest adjust-thresholds
```

### Pattern 3: Conservative Self-Tuning

```bash
# Enable only daily summaries (not per-action)
vim ~/Documents/gtd/.auto_suggest_config.json
# "notify_on_action": false
# "notify_daily_summary": true

# Enable smart thresholds
# "smart_thresholds": { "enabled": true }

# Let it run for 2-4 weeks
# System will optimize itself
# You get daily Discord summaries
# Thresholds adjust automatically
```

## Integration with Learning System

Smart threshold adjustment integrates deeply with the unified learning system:

**Data Flow:**
```
User Decisions → Unified Learning → Acceptance Rates
                                          ↓
                                    Smart Thresholds
                                          ↓
                                   Adjusted Thresholds
                                          ↓
                              Auto-Suggest (uses new thresholds)
                                          ↓
                                    More User Decisions
                                    (feedback loop)
```

**Benefits:**
1. System learns from all your decisions (manual + auto)
2. Improves over time automatically
3. Adapts to changing preferences
4. Per-type optimization (each suggestion type tunes independently)

## Safety Features

### Smart Threshold Safety
- **Minimum threshold**: Won't go below 70% (configurable)
- **Maximum threshold**: Won't go above 98% (configurable)
- **Sample requirement**: Needs 20+ decisions before adjusting
- **Gradual changes**: Only adjusts by 5% at a time
- **Weekly cadence**: Not too frequent, allows pattern stabilization
- **Manual override**: You can always adjust manually

### Notification Safety
- **Non-blocking**: Notification failures don't break auto-suggest
- **Timeout**: 5-second timeout on Discord webhooks
- **Silent failures**: Logs errors but continues operation
- **Configurable**: Turn off notifications you don't want

## Best Practices

### For Notifications

**1. Start with summaries only**
```json
{
  "notify_on_action": false,
  "notify_daily_summary": true
}
```
Less noisy, still informed.

**2. Enable action notifications during testing**
```json
{
  "notify_on_action": true,
  "notify_daily_summary": false
}
```
See what's happening in real-time.

**3. Always keep error notifications**
```json
{
  "notify_on_error": true
}
```
Important for catching issues.

### For Smart Thresholds

**1. Let it gather data first**
- Run for 2-3 weeks before enabling
- Need 20+ decisions per type
- More data = better adjustments

**2. Start conservative**
```json
{
  "target_acceptance_rate": 0.90
}
```
Higher target = more selective suggestions.

**3. Monitor adjustments**
- Check Discord when thresholds change
- Review if adjustments make sense
- Disable if system adjusts incorrectly

**4. Manual intervention when needed**
```bash
# If system adjusted wrong, fix it:
gtd-auto-suggest config --type task_suggestion --value 0.85

# Then re-enable smart thresholds after a week
```

## Troubleshooting

### "Smart thresholds not adjusting"

**Check:**
```bash
# 1. Is it enabled?
cat ~/Documents/gtd/.auto_suggest_config.json | grep -A5 smart_thresholds

# 2. Enough decisions?
gtd-auto-suggest stats
# Look for decision counts per type

# 3. When was last adjustment?
cat ~/Documents/gtd/.last_threshold_adjustment
# Should update weekly
```

### "Not receiving Discord notifications"

**Check:**
```bash
# 1. Webhook configured?
echo $GTD_DISCORD_WEBHOOK_URL

# 2. Notifications enabled in config?
cat ~/Documents/gtd/.auto_suggest_config.json | grep -A5 notifications

# 3. Test manually:
gtd-auto-suggest run --live
# Watch Discord channel
```

### "Too many Discord notifications"

**Solution:**
```bash
# Disable per-action notifications
vim ~/Documents/gtd/.auto_suggest_config.json
# Set "notify_on_action": false

# Keep daily summary only
# Set "notify_daily_summary": true
```

### "Thresholds adjusted too aggressively"

**Solution:**
```bash
# Tighten the target range
vim ~/Documents/gtd/.auto_suggest_config.json
# Adjust: "target_acceptance_rate": 0.88 (closer to 85% means less adjustment)

# Or increase min_samples requirement
# "min_samples": 30 (need more data before adjusting)

# Or disable temporarily
# "enabled": false
```

## Performance Impact

**Discord Notifications:**
- Adds <100ms per notification
- Non-blocking (doesn't slow down auto-suggest)
- Timeout after 5 seconds
- Zero impact if webhook not configured

**Smart Threshold Adjustment:**
- Runs once per week
- Takes 1-5 seconds depending on history size
- Only when `adjust-thresholds` called
- No impact on regular auto-suggest runs

## Future Enhancements (Phase 4+)

Potential additions:

- **Multi-channel notifications**: Different channels for different types
- **Notification templates**: Customizable Discord embed formats
- **Slack integration**: Alternative to Discord
- **Email digests**: Weekly email summaries
- **Threshold prediction**: ML model to predict optimal thresholds
- **A/B testing**: Test different thresholds automatically
- **User profiles**: Different settings for work vs personal time

## Summary

Phase 3 makes auto-suggest **intelligent and visible**:

1. **✅ Real-time visibility** - Know what's happening via Discord
2. **✅ Self-optimizing** - Thresholds adjust based on your patterns
3. **✅ Fully automated** - Weekly reviews happen automatically
4. **✅ Configurable** - Control notification frequency and adjustment behavior
5. **✅ Safe** - Multiple safeguards against over-adjustment

The system now learns and adapts to your preferences automatically while keeping you informed!

---

**Documentation:**
- [Main Documentation](AUTO_SUGGEST_SYSTEM.md)
- [Quick Start](AUTO_SUGGEST_QUICKSTART.md)
- [Phase 2 Features](AUTO_SUGGEST_PHASE2.md)
- [Phase 3 Features](AUTO_SUGGEST_PHASE3.md) (this document)

