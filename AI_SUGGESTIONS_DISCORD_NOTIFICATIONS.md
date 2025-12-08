# AI Suggestions Discord Notifications

## Overview

AI background jobs that generate suggestions now automatically send Discord notifications when new suggestions are created. This allows you to review suggestions without being restricted by Discord's text limits, as the notification includes direct file access information.

## How It Works

When an AI suggestion is created (via `gtd_auto_suggest.py` or the MCP server), the system:

1. **Saves the suggestion** to `${GTD_BASE_DIR}/suggestions/{suggestion_id}.json`
2. **Sends a Discord notification** (if webhook is configured) with:
   - Suggestion title
   - Reason for the suggestion
   - Confidence score
   - **File path** for direct access
   - **Commands** to review the suggestion

## Discord Message Format

Each notification includes:

```
💡 New AI Suggestion

**{Title}**

**Reason:** {Why this suggestion matters}
**Confidence:** {Percentage}

📁 **File:** `{full_path_to_json_file}`
💡 **Review:** Run `gtd-checkin` and select 'Review pending suggestions'
🔗 **Direct access:** `open {file_path}` or `cat {file_path}`
```

## Setup

### 1. Configure Discord Webhook

Add your Discord webhook URL to `.gtd_config`:

```bash
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
```

**To get a webhook URL:**
1. Open Discord → Server Settings → Integrations → Webhooks
2. Click "New Webhook"
3. Choose a channel for notifications
4. Copy the webhook URL

### 2. Test the Setup

Test that notifications work:

```bash
# Test Discord connection
gtd-test-discord

# Create a test log entry (this will trigger AI suggestions)
addInfoToDailyLog "Test entry that might generate a suggestion"
```

## Features

### ✅ Automatic Notifications
- All new AI suggestions trigger Discord notifications
- No manual action required
- Works for all suggestion sources (daily logs, background analysis, etc.)

### ✅ Full File Access
- Direct file path included in notification
- Commands to open/view the file
- No text truncation - full suggestion available in JSON file

### ✅ Non-Blocking
- Discord notifications are sent asynchronously
- If Discord fails, suggestion saving still succeeds
- Silent failure - won't break your workflow

### ✅ Rich Information
- Suggestion title and reason
- Confidence score
- Multiple ways to access the file

## Accessing Suggestions

When you receive a Discord notification, you can:

1. **Review via gtd-checkin:**
   ```bash
   gtd-checkin
   # Select option 4: "Review pending suggestions"
   ```

2. **Open the file directly:**
   ```bash
   open ~/Documents/gtd/suggestions/{suggestion_id}.json
   # or
   cat ~/Documents/gtd/suggestions/{suggestion_id}.json
   ```

3. **View in your editor:**
   ```bash
   code ~/Documents/gtd/suggestions/{suggestion_id}.json
   # or
   vim ~/Documents/gtd/suggestions/{suggestion_id}.json
   ```

## Technical Details

### Implementation

- **Location:** `mcp/gtd_mcp_server.py`
- **Function:** `save_suggestion()` now calls `send_discord_notification()`
- **Notification Function:** `send_discord_notification()` uses Discord webhook API

### Configuration Loading

The Discord webhook URL is loaded from:
1. Environment variable: `GTD_DISCORD_WEBHOOK_URL`
2. Config file: `.gtd_config` (takes precedence)

### Error Handling

- If Discord webhook is not configured: notifications are silently skipped
- If Discord request fails: suggestion is still saved successfully
- Timeout: 5 seconds (prevents hanging)

## Example Notification

When you log an entry like:

```bash
addInfoToDailyLog "I should review my project priorities this week"
```

You might receive a Discord notification:

```
💡 New AI Suggestion

**Review project priorities**

**Reason:** You mentioned reviewing priorities, this is a good time to ensure alignment with goals
**Confidence:** 85%

📁 **File:** `/Users/abby/Documents/gtd/suggestions/abc-123-def-456.json`
💡 **Review:** Run `gtd-checkin` and select 'Review pending suggestions'
🔗 **Direct access:** `open /Users/abby/Documents/gtd/suggestions/abc-123-def-456.json` or `cat /Users/abby/Documents/gtd/suggestions/abc-123-def-456.json`
```

## Troubleshooting

### Notifications Not Appearing

1. **Check webhook URL:**
   ```bash
   echo $GTD_DISCORD_WEBHOOK_URL
   # or check .gtd_config
   grep GTD_DISCORD_WEBHOOK_URL ~/.gtd_config
   ```

2. **Test Discord connection:**
   ```bash
   gtd-test-discord
   ```

3. **Verify suggestions are being created:**
   ```bash
   ls -la ~/Documents/gtd/suggestions/*.json
   ```

4. **Check suggestion status:**
   ```bash
   # Only pending suggestions trigger notifications
   grep -l '"status":\s*"pending"' ~/Documents/gtd/suggestions/*.json
   ```

### Webhook URL Not Loading

- Make sure it's in `.gtd_config` (not just environment variable)
- Check for quotes: `GTD_DISCORD_WEBHOOK_URL="https://..."`
- Restart your terminal/shell after adding to config

## Benefits

1. **No Text Limits:** Full suggestion details in JSON file, not truncated in Discord
2. **Persistent:** Discord messages stay for reference
3. **Accessible:** View from any device with Discord
4. **Actionable:** Direct file paths and commands included
5. **Non-Intrusive:** Only notifies for new pending suggestions

## Related Features

- **Review Suggestions:** `gtd-checkin` → "Review pending suggestions"
- **AI Suggestions:** Generated from daily logs via `gtd_auto_suggest.py`
- **Background Jobs:** Suggestions created during logging and analysis

