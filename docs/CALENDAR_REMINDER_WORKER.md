# Calendar Reminder Worker

## Overview

The Calendar Reminder Worker is a background process that automatically:
- Checks for upcoming meeting reminders
- Sends macOS notifications when meetings are approaching
- Updates calendar cache periodically
- Updates dashboard cache with upcoming meeting info

## Features

- **Automatic Reminder Checking**: Checks every 1 minute for upcoming meetings
- **macOS Notifications**: Sends native notifications when reminders are due
- **Calendar Cache Updates**: Refreshes calendar data every 5 minutes
- **Dashboard Integration**: Updates dashboard cache with upcoming meetings
- **Configurable Reminder Times**: Uses `GTD_CALENDAR_REMINDER_TIMES` from config

## Starting the Worker

```bash
# Start the worker
gtd-calendar-reminder-worker

# Check if it's running
pgrep -f gtd_calendar_reminder_worker.py
```

## Configuration

### Reminder Times

Edit `~/.gtd_config_calendar`:

```bash
# Default: 15 minutes before
GTD_CALENDAR_REMINDER_TIMES="15"

# Multiple reminders: 1 hour and 15 minutes before
GTD_CALENDAR_REMINDER_TIMES="60,15"

# Custom: 2 hours, 1 hour, and 15 minutes before
GTD_CALENDAR_REMINDER_TIMES="120,60,15"
```

### Notifications

Notifications are controlled by `GTD_NOTIFICATIONS` in your `.gtd_config`:

```bash
# Enable notifications (default)
GTD_NOTIFICATIONS="true"

# Disable notifications
GTD_NOTIFICATIONS="false"
```

## How It Works

1. **Worker Loop**:
   - Every 1 minute: Checks for upcoming meeting reminders
   - Every 5 minutes: Updates calendar cache from `gcalcli`
   - Continuously: Updates dashboard cache with upcoming meetings

2. **Reminder Detection**:
   - Checks all events in calendar cache
   - Compares event start time with current time
   - If within reminder window (1 minute), sends notification

3. **Notification Tracking**:
   - Tracks sent reminders in `~/.gtd/calendar/reminders_sent.json`
   - Prevents duplicate notifications
   - Remembers which reminder times were sent for each event

4. **Dashboard Integration**:
   - Updates `~/.gtd/.dashboard_cache.json` with:
     - Upcoming meetings (next 5)
     - Next meeting info
     - Last update timestamp

## Notification Format

When a meeting reminder is due, you'll receive a macOS notification:

- **Title**: "🔔 Meeting Reminder: [Event Title]"
- **Message**: "Starts in [X] minutes ([time])"
- **Subtitle**: "[Location] • [Calendar]"
- **Sound**: Glass

## Logs

Worker logs are written to `/tmp/calendar-reminder-worker.log`:

```bash
# View logs
tail -f /tmp/calendar-reminder-worker.log

# Check recent activity
tail -20 /tmp/calendar-reminder-worker.log
```

## Stopping the Worker

```bash
# Find and stop the worker
pkill -f gtd_calendar_reminder_worker.py

# Or use worker status command
gtd-worker-status
# Then stop from the wizard
```

## Integration with Other Systems

### Dashboard Cache Worker

The calendar reminder worker complements the dashboard cache worker:
- **Dashboard Cache Worker**: Updates every 10 seconds with GTD stats
- **Calendar Reminder Worker**: Updates every 1 minute with calendar reminders

Both update the same dashboard cache file, so they work together seamlessly.

### Manual Reminder Checking

You can still check reminders manually:

```bash
# Check reminders on-demand
gtd-calendar-reminders check

# This won't send notifications if already sent by worker
```

## Troubleshooting

### Worker Not Starting

1. **Check Python availability:**
   ```bash
   python3 --version
   ```

2. **Check script permissions:**
   ```bash
   ls -l ~/code/dotfiles/mcp/gtd_calendar_reminder_worker.py
   ```

3. **Check logs:**
   ```bash
   tail -50 /tmp/calendar-reminder-worker.log
   ```

### Notifications Not Appearing

1. **Check notifications enabled:**
   ```bash
   grep GTD_NOTIFICATIONS ~/.gtd_config
   ```

2. **Check macOS notification permissions:**
   - System Preferences → Notifications
   - Ensure Terminal (or your terminal app) has notification permissions

3. **Test notification manually:**
   ```bash
   gtd-notify "Test" "This is a test notification"
   ```

### Reminders Not Triggering

1. **Check calendar cache:**
   ```bash
   ls -lh ~/.gtd/calendar/cache.json
   # Should be recent (within 5 minutes)
   ```

2. **Force calendar cache update:**
   ```bash
   gtd-calendar-fetch --force
   ```

3. **Check reminder times:**
   ```bash
   grep GTD_CALENDAR_REMINDER_TIMES ~/.gtd_config_calendar
   ```

4. **Check sent reminders:**
   ```bash
   cat ~/.gtd/calendar/reminders_sent.json
   ```

## Auto-Start on Login

To start the worker automatically on login, add to your shell profile:

```bash
# In ~/.zshrc or ~/.bash_profile
if ! pgrep -f gtd_calendar_reminder_worker.py >/dev/null; then
    gtd-calendar-reminder-worker >/dev/null 2>&1 &
fi
```

Or use launchd (macOS):

Create `~/Library/LaunchAgents/com.gtd.calendar-reminder-worker.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gtd.calendar-reminder-worker</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/code/dotfiles/bin/gtd-calendar-reminder-worker</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Then load it:

```bash
launchctl load ~/Library/LaunchAgents/com.gtd.calendar-reminder-worker.plist
```

## See Also

- [Calendar Information System Usage](./CALENDAR_INFORMATION_SYSTEM_USAGE.md)
- [Calendar Information System Design](./architecture/calendar_information_system_design.md)
- [Background Worker Status](./BACKGROUND_WORKER_STATUS.md)
