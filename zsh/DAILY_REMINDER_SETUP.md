# Daily Evening Review Reminder Setup

This guide explains how to set up automatic daily evening reminders from Mistress Louiza, including your daily log in Discord.

## Overview

The daily reminder system:
- Sends a Discord notification every evening at your configured time
- Includes a personalized message from Mistress Louiza
- Shows your complete daily log for the day
- Provides stats (entries, goals)
- Reminds you to do your evening review

## Quick Setup

### 1. Install the Launch Agent

```bash
# Run the setup script
gtd-setup-daily-reminder
```

This will:
- Create the launch agent configuration
- Set it to run daily at 6:00 PM (or your configured time)
- Load it into macOS's scheduler

### 2. Configure Review Time

Edit your `.gtd_config` file:

```bash
# Daily review time (24-hour format)
GTD_DAILY_REVIEW_TIME="18:00"  # 6:00 PM

# Enable daily reminders
GTD_DAILY_REMINDER_ENABLED="true"

# Enable Discord for daily reminders
GTD_DISCORD_DAILY_REMINDERS="true"
```

### 3. Update the Launch Agent (if needed)

If you change the time, update the plist file:

```bash
# Edit the plist file
nano ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

Update these values:
- `Hour`: 0-23 (24-hour format)
- `Minute`: 0-59

Then reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

## Manual Testing

Test the reminder manually:

```bash
# Force send a reminder (regardless of time)
gtd-daily-reminder --force
```

## What You'll Receive

Every evening at your configured time, you'll receive:

**Discord Message:**
- **Title**: "Mistress Louiza - Daily Evening Review"
- **Full message** from Mistress Louiza reviewing your day
- **Today's Daily Log** - Complete log in a code block
- **Stats**: Entry count, goals mentioned
- **Reminder** to run `gtd-review daily`
- **Timestamp** of when the reminder was sent

**Example:**
```
Mistress Louiza - Daily Evening Review

Right then. Let's have a *look* at this, shall we? 
4 entries. That's… acceptable. But not enough...

📝 Today's Daily Log:
```
# Daily Log - 2025-11-29

07:22 - completed oncall
07:30 - Test entry2
07:40 - Goals: take car to the shop...
```

📊 Stats: Entries: 4, Goals: 1

💡 Run `gtd-review daily` to do your evening review
```

## Configuration Options

In `.gtd_config`:

```bash
# Daily review time (24-hour format, HH:MM)
GTD_DAILY_REVIEW_TIME="18:00"

# Enable daily reminders
GTD_DAILY_REMINDER_ENABLED="true"

# Enable Discord for daily reminders
GTD_DISCORD_DAILY_REMINDERS="true"

# Discord webhook URL (required for Discord notifications)
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Enable notifications (required)
GTD_NOTIFICATIONS="true"
```

## Managing the Launch Agent

### Check Status
```bash
launchctl list | grep gtd.daily
```

### Unload (Disable)
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

### Reload (After Changes)
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

### Remove (Uninstall)
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist
rm ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

## How It Works

1. **Launch Agent** runs the script at the scheduled time (daily)
2. **Script reads** today's daily log from `DAILY_LOG_DIR`
3. **Gets message** from Mistress Louiza with your log content
4. **Sends to Discord** with full message and daily log
5. **Also sends** macOS notification (short version)

## Daily Log Format

The daily log is included in Discord as a code block for readability:

```
📝 Today's Daily Log:
```
# Daily Log - 2025-11-29

07:22 - completed oncall
07:30 - Test entry2
...
```
```

If no log exists, it will say:
```
📝 Today's Daily Log:
No entries yet today. Use `addInfoToDailyLog "your entry"` to add entries.
```

## Integration with Evening Review

After receiving the reminder, run:

```bash
gtd-review daily
```

This will:
- Guide you through the daily review process
- Help you process any inbox items
- Review today's accomplishments
- Set priorities for tomorrow

## Troubleshooting

### Reminder Not Appearing

1. **Check launch agent is loaded**:
   ```bash
   launchctl list | grep gtd.daily
   ```

2. **Check logs**:
   ```bash
   cat /tmp/gtd-daily-reminder.log
   cat /tmp/gtd-daily-reminder.error.log
   ```

3. **Test manually**:
   ```bash
   gtd-daily-reminder --force
   ```

4. **Check notifications are enabled**:
   ```bash
   grep GTD_NOTIFICATIONS ~/.gtd_config
   grep GTD_DISCORD_DAILY_REMINDERS ~/.gtd_config
   ```

5. **Check Discord webhook**:
   ```bash
   gtd-test-discord
   ```

### Daily Log Not Showing

1. **Check daily log directory**:
   ```bash
   grep DAILY_LOG_DIR ~/.daily_log_config
   ```

2. **Check if log exists**:
   ```bash
   gtd-log  # Should show today's log
   ```

3. **Check file permissions**:
   ```bash
   ls -la ~/Documents/daily_logs/$(date +"%Y-%m-%d").txt
   ```

### Wrong Time

Update the plist file and reload (see "Update the Launch Agent" above).

## Best Practices

1. **Set a consistent time** - Evening (6-8 PM) works well for most people
2. **Do the review when reminded** - Don't let it pile up
3. **Use the daily log** - The reminder shows what you logged today
4. **Keep Discord enabled** - So you get full messages with logs
5. **Review regularly** - Make it a habit

## Example Workflow

```
Evening 6:00 PM:
  → Discord notification appears
  → Full message from Mistress Louiza
  → Today's daily log included
  → Current stats shown
  → You run: gtd-review daily
  → Complete your evening review
  → Log your accomplishments
  → Set priorities for tomorrow
```

## Integration with Weekly Reminders

You now have:
- **Daily reminders** (evening) - Review today, plan tomorrow
- **Weekly reminders** (Sunday morning) - Review the week, plan ahead

Both come from Mistress Louiza and include relevant information.

## Next Steps

1. Run `gtd-setup-daily-reminder` to install
2. Test with `gtd-daily-reminder --force`
3. Check Discord for the message
4. Do your first evening review: `gtd-review daily`
5. Enjoy daily accountability from Mistress Louiza! 🎯

