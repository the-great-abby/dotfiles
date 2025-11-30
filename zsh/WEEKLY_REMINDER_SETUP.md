# Weekly Review Reminder Setup

This guide explains how to set up automatic weekly reminders for your GTD review process.

## Overview

The weekly reminder system:
- Sends a macOS notification every week at your configured time
- Shows current GTD system stats (inbox, tasks, projects, waiting items)
- Reminds you to run your weekly review
- Only sends if you haven't done a review this week

## Quick Setup

### 1. Install the Launch Agent

```bash
# Copy the plist file to LaunchAgents directory
cp ~/code/dotfiles/zsh/com.abby.gtd.weekly.plist ~/Library/LaunchAgents/

# Load the launch agent
launchctl load ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

### 2. Configure Review Day and Time

Edit your `.gtd_config` file:

```bash
# Weekly review day (0=Sunday, 1=Monday, etc.)
GTD_WEEKLY_REVIEW_DAY="0"  # Sunday

# Weekly review time (24-hour format)
GTD_WEEKLY_REVIEW_TIME="09:00"  # 9:00 AM
```

### 3. Update the Launch Agent (if needed)

If you change the day/time, update the plist file:

```bash
# Edit the plist file
nano ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

Update these values:
- `Weekday`: 0=Sunday, 1=Monday, 2=Tuesday, etc.
- `Hour`: 0-23 (24-hour format)
- `Minute`: 0-59

Then reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

## Manual Testing

Test the reminder manually:

```bash
# Force send a reminder (regardless of day/time)
gtd-weekly-reminder --force
```

## What You'll See

When the reminder triggers, you'll receive:

1. **macOS Notification**:
   - Title: "GTD Weekly Review"
   - Message: "Time for your weekly review"
   - Subtitle: Current stats (inbox, tasks, projects, waiting)
   - Sound: Submarine

2. **Terminal Output** (if terminal is open):
   - Current GTD system stats
   - Reminder to run `gtd-review weekly`
   - List of key areas to review

## Configuration Options

In `.gtd_config`:

```bash
# Weekly review day (0=Sunday, 1=Monday, 2=Tuesday, etc.)
GTD_WEEKLY_REVIEW_DAY="0"

# Weekly review time (24-hour format, HH:MM)
GTD_WEEKLY_REVIEW_TIME="09:00"

# Enable notifications (required for reminders)
GTD_NOTIFICATIONS="true"
```

## Managing the Launch Agent

### Check Status
```bash
launchctl list | grep gtd
```

### Unload (Disable)
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

### Reload (After Changes)
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

### Remove (Uninstall)
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
rm ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

## How It Works

1. **Launch Agent** runs the script at the scheduled time
2. **Script checks**:
   - Is it the review day?
   - Is it around the review time?
   - Has a review been done this week?
3. **If conditions met**: Sends notification with stats
4. **If review already done**: Skips reminder (no spam!)

## Review Detection

The system detects if you've done a weekly review by checking:
- Files in `~/Documents/gtd/weekly-reviews/` directory
- Files created in the last 7 days
- Files matching the current week pattern

## Customization

### Change Notification Sound

Edit `gtd-weekly-reminder` script and change:
```bash
"$notify_cmd" "GTD Weekly Review" "Time for your weekly review" "$stats" "Submarine"
```

To a different sound (see `MAC_NOTIFICATIONS_GUIDE.md` for options).

### Change Reminder Message

Edit the `send_weekly_reminder()` function in `gtd-weekly-reminder` to customize the message.

### Multiple Reminders

To get reminders multiple times per week, create additional plist files with different names and schedules.

## Troubleshooting

### Reminder Not Appearing

1. **Check launch agent is loaded**:
   ```bash
   launchctl list | grep gtd
   ```

2. **Check logs**:
   ```bash
   cat /tmp/gtd-weekly-reminder.log
   cat /tmp/gtd-weekly-reminder.error.log
   ```

3. **Test manually**:
   ```bash
   gtd-weekly-reminder --force
   ```

4. **Check notifications are enabled**:
   ```bash
   grep GTD_NOTIFICATIONS ~/.gtd_config
   ```

5. **Check macOS notification permissions**:
   - System Settings → Notifications & Focus
   - Ensure Terminal has notification permissions

### Reminder Too Frequent

The system automatically skips if you've done a review this week. If you want to disable temporarily:

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.weekly.plist
```

### Wrong Day/Time

Update the plist file and reload (see "Update the Launch Agent" above).

## Integration with Weekly Review

After receiving the reminder, run:

```bash
gtd-review weekly
```

This will:
- Guide you through the weekly review process
- Help you process inbox items
- Review projects and areas
- Check waiting-for items
- Review someday/maybe list

## Best Practices

1. **Set a consistent time** - Sunday morning works well for many people
2. **Do the review when reminded** - Don't let it pile up
3. **Use the stats** - The reminder shows what needs attention
4. **Keep notifications enabled** - So you don't miss reminders

## Example Workflow

```
Sunday 9:00 AM → Notification appears
                → Shows: "Inbox: 5 | Tasks: 12 | Projects: 3 | Waiting: 2"
                → You run: gtd-review weekly
                → Process inbox, review projects, etc.
                → System detects review done, won't remind again this week
```

## Future Enhancements

Planned features:
- Multiple reminder times (e.g., Friday evening + Sunday morning)
- Custom reminder messages
- Integration with calendar
- Review completion tracking
- Stats trends over time

