# macOS Notifications Guide for GTD System

Your GTD system now includes full macOS notification support using AppleScript (`osascript`). This guide explains how it works and how to configure it.

## How It Works

The notification system uses macOS's built-in notification center via AppleScript. When GTD events occur (task completion, inbox processing, etc.), you'll receive native macOS notifications.

## Configuration

In your `.gtd_config` file:

```bash
# Enable/disable notifications
GTD_NOTIFICATIONS="true"  # Set to "false" to disable

# Notification method
GTD_NOTIFICATION_METHOD="osascript"  # For macOS notifications
# Alternative: "terminal" for terminal output only
```

## Notification Types

### 1. Task Completion
When you complete a task:
```bash
gtd-task complete <task-id>
```

You'll receive a notification:
- **Title**: "Task Complete"
- **Message**: Task name
- **Subtitle**: "Great job!"
- **Sound**: Ping

### 2. Inbox Processing
When your inbox is empty after processing:
```bash
gtd-process --all
```

You'll receive a notification:
- **Title**: "GTD Inbox"
- **Message**: "Inbox is empty"
- **Subtitle**: "All items processed"
- **Sound**: Ping

### 3. Inbox Reminders
You can manually check inbox count:
```bash
gtd-notify inbox 5
```

This sends a notification if you have items waiting.

### 4. Review Reminders
For scheduled reviews:
```bash
gtd-notify review weekly
```

### 5. Deadline Warnings
For approaching deadlines:
```bash
gtd-notify deadline "Submit report" "2 hours"
```

## Manual Notifications

You can send custom notifications using the `gtd-notify` command:

```bash
# Basic notification
gtd-notify "Title" "Message" "Subtitle" "Sound"

# Examples
gtd-notify "GTD" "Inbox processing complete" "All items processed"
gtd-notify "Reminder" "Don't forget your weekly review" "" "Glass"
```

## Sound Options

Available macOS notification sounds:
- `default` - Default system sound
- `Glass` - Glass sound
- `Ping` - Ping sound
- `Submarine` - Submarine sound
- `Basso` - Basso sound
- `Blow` - Blow sound
- `Bottle` - Bottle sound
- `Frog` - Frog sound
- `Funk` - Funk sound
- `Hero` - Hero sound
- `Morse` - Morse sound
- `Pop` - Pop sound
- `Purr` - Purr sound
- `Sosumi` - Sosumi sound
- `Tink` - Tink sound
- `none` - No sound

## Convenience Functions

The `gtd-notify` command includes convenience functions:

```bash
# Inbox count notification
gtd-notify inbox 5

# Task completion notification
gtd-notify complete "Finish project proposal"

# Review reminder
gtd-notify review weekly

# Deadline warning
gtd-notify deadline "Submit report" "2 hours"
```

## Integration Points

Notifications are automatically sent from:

1. **`gtd-task complete`** - When tasks are completed
2. **`gtd-process`** - When inbox is empty after processing
3. **Future integrations** - More commands will add notifications

## macOS Notification Settings

To control how notifications appear:

1. Open **System Settings** (or System Preferences on older macOS)
2. Go to **Notifications & Focus**
3. Find **Terminal** (or the app running the script)
4. Configure:
   - **Allow Notifications**: Enable
   - **Alert Style**: Choose Banner, Alert, or None
   - **Show in Notification Center**: Enable
   - **Sound**: Enable/disable

## Troubleshooting

### Notifications Not Appearing

1. **Check if notifications are enabled**:
   ```bash
   grep GTD_NOTIFICATIONS ~/.gtd_config
   # Should show: GTD_NOTIFICATIONS="true"
   ```

2. **Check macOS notification permissions**:
   - System Settings → Notifications & Focus
   - Ensure Terminal has notification permissions

3. **Test manually**:
   ```bash
   gtd-notify "Test" "This is a test"
   ```

4. **Check if osascript works**:
   ```bash
   osascript -e 'display notification "Test" with title "GTD"'
   ```

### Notifications Too Frequent

Disable specific notifications by modifying the commands, or set:
```bash
GTD_NOTIFICATIONS="false"
```

### Change Notification Method

If you prefer terminal output instead:
```bash
GTD_NOTIFICATION_METHOD="terminal"
```

This will show notifications in the terminal instead of macOS notification center.

## Customization

### Custom Notification Sounds

Edit the notification calls in the GTD commands to use different sounds:

```bash
# In gtd-task or other commands, change:
"$NOTIFY_CMD" complete "$task_name"
# To:
"$NOTIFY_CMD" "Task Complete" "$task_name" "Great job!" "Glass"
```

### Disable Specific Notifications

To disable task completion notifications but keep others, edit `gtd-task` and comment out the notification line.

## Best Practices

1. **Keep notifications enabled** for important events (task completion, empty inbox)
2. **Use appropriate sounds** - Ping for completions, Basso for warnings
3. **Don't over-notify** - Only notify for meaningful events
4. **Review notification settings** periodically to ensure they're not too intrusive

## Future Enhancements

Planned notification features:
- Scheduled review reminders
- Deadline warnings (X hours before due)
- Inbox count reminders (if inbox has items for >24 hours)
- Project milestone notifications
- Weekly review reminders

## Example Workflow

```bash
# 1. Process inbox (notification when empty)
gtd-process --all

# 2. Complete a task (notification on completion)
gtd-task complete 20240101120000-task

# 3. Check inbox count
gtd-notify inbox 3

# 4. Manual reminder
gtd-notify "GTD Review" "Time for weekly review" "Stay organized"
```

## Technical Details

The notification system uses:
- **AppleScript** (`osascript`) for macOS notifications
- **Fallback to terminal** if osascript fails or on non-macOS systems
- **Configurable** via `.gtd_config`
- **Non-blocking** - notifications don't interrupt command execution

The `gtd-notify` command is a standalone utility that can be called from any GTD command or used manually.

