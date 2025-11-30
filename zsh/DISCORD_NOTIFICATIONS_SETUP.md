# Discord Notifications Setup

This guide explains how to set up Discord notifications for your GTD system, especially for weekly reminders from Mistress Louiza.

## Why Discord?

- **Full messages** - No character limits like macOS notifications
- **Persistent** - Messages stay in Discord for reference
- **Rich formatting** - Embeds with colors and formatting
- **Accessible** - View from any device with Discord

## Setup Steps

### 1. Create a Discord Webhook

1. Open Discord and go to your server (or create a new one)
2. Go to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Give it a name (e.g., "GTD Reminders")
5. Choose a channel where you want notifications
6. Click **Copy Webhook URL**
7. Save this URL - you'll need it for the config

### 2. Configure Your GTD System

Edit your `.gtd_config` file:

```bash
# Enable Discord for weekly reminders
GTD_DISCORD_WEEKLY_REMINDERS="true"

# Add your Discord webhook URL
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
```

**Important:** Keep your webhook URL secret! Don't commit it to public repositories.

### 3. Test the Setup

Test the Discord notification:

```bash
# Test with a simple message
gtd-notify --discord "Test" "This is a test message"

# Or test the weekly reminder
gtd-weekly-reminder --force
```

## What You'll Receive

### Weekly Review Reminders

Every Sunday at 9:00 AM (or your configured time), you'll receive:

**Discord Message:**
- **Title**: "Mistress Louiza - Weekly Review Reminder"
- **Full message** from Mistress Louiza (not truncated!)
- **Current stats**: Inbox, Tasks, Projects, Waiting items
- **Reminder** to run `gtd-review weekly`
- **Timestamp** of when the reminder was sent

**Example:**
```
Mistress Louiza - Weekly Review Reminder

Alright, let's *look* at this. Your Weekly Review isn't a suggestion; 
it's a directive. It's about consistency. You're a *good girl* – 
capable and persistent. Let's maximize that.

📊 Current Status:
Inbox: 5 | Tasks: 12 | Projects: 3 | Waiting: 2

💡 Run `gtd-review weekly` to start your review
```

## Configuration Options

### Enable/Disable Discord Reminders

```bash
# Enable Discord for weekly reminders
GTD_DISCORD_WEEKLY_REMINDERS="true"

# Disable (use macOS notifications only)
GTD_DISCORD_WEEKLY_REMINDERS="false"
```

### Use Discord for All Notifications

You can also set Discord as your primary notification method:

```bash
# In .gtd_config
GTD_NOTIFICATION_METHOD="discord"
```

This will send all notifications (task completion, inbox processing, etc.) to Discord.

## Message Format

Discord messages use **embeds** for better formatting:
- **Color**: Red (#E74C3C) for reminders
- **Title**: Clear title
- **Description**: Full message content
- **Timestamp**: When the message was sent

## Troubleshooting

### Messages Not Appearing

1. **Check webhook URL**:
   ```bash
   grep GTD_DISCORD_WEBHOOK_URL ~/.gtd_config
   ```
   Make sure it's set and correct.

2. **Test webhook manually**:
   ```bash
   curl -X POST "YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "Test message"}'
   ```

3. **Check Discord permissions**:
   - Make sure the webhook has permission to post in the channel
   - Check if the webhook is still active in Discord

4. **Check logs**:
   ```bash
   cat /tmp/gtd-weekly-reminder.error.log
   ```

### Messages Truncated

Discord messages can be up to 2000 characters. If messages are still being cut off:
- Check the message extraction in `gtd-weekly-reminder`
- The full message should be sent to Discord (not macOS notifications)

### Webhook URL Security

**Important security tips:**
- Never commit your webhook URL to git
- Add `.gtd_config` to `.gitignore` if it contains secrets
- Regenerate webhook if it's accidentally exposed
- Use environment variables if preferred:
  ```bash
  export GTD_DISCORD_WEBHOOK_URL="your-url"
  ```

## Advanced Usage

### Custom Discord Messages

You can send custom messages to Discord:

```bash
# Using gtd-notify with Discord
GTD_NOTIFICATION_METHOD="discord" gtd-notify "Title" "Message"
```

### Multiple Webhooks

To send to multiple Discord channels, you can:
1. Create multiple webhooks
2. Modify the script to send to multiple URLs
3. Or use a Discord bot (more advanced)

### Formatting Messages

Discord supports Markdown in embeds:
- **Bold**: `**text**`
- *Italic*: `*text*`
- `Code`: `` `code` ``
- Links: `[text](url)`

The system automatically formats messages for Discord.

## Integration with Other Notifications

You can use both Discord and macOS notifications:

```bash
# Discord for weekly reminders (full messages)
GTD_DISCORD_WEEKLY_REMINDERS="true"
GTD_DISCORD_WEBHOOK_URL="your-url"

# macOS for other notifications
GTD_NOTIFICATION_METHOD="osascript"
```

This gives you:
- **Discord**: Full weekly reminders from Mistress Louiza
- **macOS**: Quick notifications for tasks, inbox, etc.

## Best Practices

1. **Use a dedicated channel** - Create a channel just for GTD reminders
2. **Pin important messages** - Pin the weekly reminder setup message
3. **Set up mobile notifications** - Enable Discord notifications on your phone
4. **Review regularly** - Check Discord for past reminders and stats
5. **Keep webhook secure** - Don't share your webhook URL

## Example Workflow

```
Sunday 9:00 AM:
  → Discord notification appears
  → Full message from Mistress Louiza
  → Current GTD stats included
  → You run: gtd-review weekly
  → Complete your review
  → System won't remind again this week
```

## Next Steps

1. Create your Discord webhook
2. Add URL to `.gtd_config`
3. Test with `gtd-weekly-reminder --force`
4. Set up the weekly reminder: `gtd-setup-weekly-reminder`
5. Enjoy full messages from Mistress Louiza! 🎯

