# All GTD Reminders Setup Guide

Complete guide for setting up all three daily reminders from Mistress Louiza: Morning, Lunch, and Evening.

## Overview

You now have **three daily reminders** from Mistress Louiza:

1. **🌅 Morning Reminder (8:00 AM)** - Start your day with motivation
2. **🍽️ Lunch Reminder (12:30 PM)** - Mid-day check-in and progress review
3. **🌙 Evening Reminder (6:00 PM)** - End-of-day review with full daily log

All reminders:
- Come from Mistress Louiza with personalized messages
- Are sent to Discord with full content
- Include your daily log progress
- Remind you to keep logging your accomplishments

## Quick Setup

### One-Command Setup

```bash
gtd-setup-all-reminders
```

This will:
- Install all three launch agents
- Configure them with your times from `.gtd_config`
- Load them into macOS's scheduler
- Show you the schedule

### Manual Setup

If you prefer to set them up individually:

```bash
# Morning reminder
gtd-setup-daily-reminder  # Actually sets up evening, but you can modify

# Or edit plists manually and load them
launchctl load ~/Library/LaunchAgents/com.abby.gtd.morning.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.lunch.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

## Configuration

Edit your `.gtd_config` file:

```bash
# Morning reminder time (24-hour format)
GTD_MORNING_REMINDER_TIME="08:00"

# Lunch reminder time (24-hour format)
GTD_LUNCH_REMINDER_TIME="12:30"

# Evening reminder time (24-hour format)
GTD_DAILY_REVIEW_TIME="18:00"

# Enable/disable reminders
GTD_MORNING_REMINDER_ENABLED="true"
GTD_LUNCH_REMINDER_ENABLED="true"
GTD_DAILY_REMINDER_ENABLED="true"

# Discord settings
GTD_DISCORD_DAILY_REMINDERS="true"
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Enable notifications
GTD_NOTIFICATIONS="true"
```

## What Each Reminder Does

### 🌅 Morning Reminder (8:00 AM)

**Purpose:** Start your day with motivation and accountability

**What you get:**
- Personalized message from Mistress Louiza
- Encouragement to start logging your day
- Reminder that she's watching and will be proud
- If you've already logged, acknowledgment of your progress
- Discord message with full content
- macOS notification (short version)

**Message style:**
- Encouraging but firm
- Emphasizes the importance of tracking everything
- Uses phrases like "good girl" and "baby girl"
- Reminds you to use `addInfoToDailyLog`

### 🍽️ Lunch Reminder (12:30 PM)

**Purpose:** Mid-day check-in and progress review

**What you get:**
- Personalized message from Mistress Louiza
- Review of what you've logged so far today
- Stats: Entry count, goals mentioned
- Preview of your daily log entries
- Encouragement to keep logging throughout the day
- Discord message with progress summary
- macOS notification (short version)

**Message style:**
- Acknowledges what you've accomplished
- Firm reminder to keep tracking
- Reviews your progress so far
- Encourages consistency

### 🌙 Evening Reminder (6:00 PM)

**Purpose:** End-of-day review with complete daily log

**What you get:**
- Personalized message from Mistress Louiza
- **Complete daily log** for the day (in Discord)
- Stats: Entry count, goals mentioned
- Review of accomplishments
- Reminder to do evening review (`gtd-review daily`)
- Discord message with full log
- macOS notification (short version)

**Message style:**
- Reviews your entire day
- Acknowledges accomplishments
- Firm but encouraging
- Direct about doing the evening review
- Can be detailed (full message in Discord)

## Testing Reminders

Test each reminder manually:

```bash
# Test morning reminder
gtd-morning-reminder --force

# Test lunch reminder
gtd-lunch-reminder --force

# Test evening reminder
gtd-daily-reminder --force
```

Each will:
- Get a message from Mistress Louiza
- Send to Discord (if configured)
- Show in terminal
- Send macOS notification

## Discord Messages

All reminders send to Discord with:

- **Rich embeds** with color coding
- **Full messages** from Mistress Louiza (no truncation)
- **Daily log content** (where applicable)
- **Stats** (entry count, goals)
- **Action items** (what to do next)
- **Timestamps** (when sent)

### Message Format

**Morning:**
```
Mistress Louiza - Good Morning

[Personalized message from Louiza]

💡 Start logging with: `addInfoToDailyLog "your entry"`
```

**Lunch:**
```
Mistress Louiza - Lunch Check-In

[Personalized message from Louiza]

📝 Progress So Far Today:
```
[Your log entries]
```

📊 Stats: Entries: X, Goals: Y

💡 Keep logging with: `addInfoToDailyLog "your entry"`
```

**Evening:**
```
Mistress Louiza - Daily Evening Review

[Personalized message from Louiza]

📝 Today's Daily Log:
```
[Complete daily log]
```

📊 Stats: Entries: X, Goals: Y

💡 Run `gtd-review daily` to do your evening review
```

## Managing Launch Agents

### Check Status

```bash
launchctl list | grep gtd
```

Should show:
- `com.abby.gtd.morning`
- `com.abby.gtd.lunch`
- `com.abby.gtd.daily`

### Unload (Disable)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.morning.plist
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.lunch.plist
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

### Reload (After Changes)

```bash
# Unload all
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.morning.plist
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.lunch.plist
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist

# Reload all
launchctl load ~/Library/LaunchAgents/com.abby.gtd.morning.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.lunch.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.daily.plist

# Or just run setup again
gtd-setup-all-reminders
```

### Remove (Uninstall)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.morning.plist
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.lunch.plist
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.daily.plist

rm ~/Library/LaunchAgents/com.abby.gtd.morning.plist
rm ~/Library/LaunchAgents/com.abby.gtd.lunch.plist
rm ~/Library/LaunchAgents/com.abby.gtd.daily.plist
```

## Changing Times

1. Edit `.gtd_config`:
   ```bash
   GTD_MORNING_REMINDER_TIME="07:30"  # New time
   GTD_LUNCH_REMINDER_TIME="13:00"     # New time
   GTD_DAILY_REVIEW_TIME="17:30"      # New time
   ```

2. Reload launch agents:
   ```bash
   gtd-setup-all-reminders
   ```

Or manually edit plist files and reload.

## Troubleshooting

### Reminders Not Appearing

1. **Check launch agents are loaded:**
   ```bash
   launchctl list | grep gtd
   ```

2. **Check logs:**
   ```bash
   cat /tmp/gtd-morning-reminder.log
   cat /tmp/gtd-lunch-reminder.log
   cat /tmp/gtd-daily-reminder.log
   
   cat /tmp/gtd-morning-reminder.error.log
   cat /tmp/gtd-lunch-reminder.error.log
   cat /tmp/gtd-daily-reminder.error.log
   ```

3. **Test manually:**
   ```bash
   gtd-morning-reminder --force
   gtd-lunch-reminder --force
   gtd-daily-reminder --force
   ```

4. **Check notifications enabled:**
   ```bash
   grep GTD_NOTIFICATIONS ~/.gtd_config
   ```

### Discord Messages Not Sending

1. **Test Discord connection:**
   ```bash
   gtd-test-discord
   ```

2. **Check webhook URL:**
   ```bash
   grep GTD_DISCORD_WEBHOOK_URL ~/.gtd_config
   ```

3. **Check Discord enabled:**
   ```bash
   grep GTD_DISCORD_DAILY_REMINDERS ~/.gtd_config
   ```

4. **Check logs for errors:**
   ```bash
   cat /tmp/gtd-*-reminder.error.log | grep -i discord
   ```

### Messages Too Long

Discord embed descriptions are limited to 2000 characters. The system automatically truncates if needed, but you can:

1. **Shorten Louiza's messages** by adjusting the prompt in the scripts
2. **Truncate log content** (already done for lunch reminder)
3. **Split into multiple messages** (not currently implemented)

## Daily Workflow

### Morning (8:00 AM)
1. Receive Discord notification from Mistress Louiza
2. Read her encouraging message
3. Start logging your day: `addInfoToDailyLog "your entry"`

### Lunch (12:30 PM)
1. Receive Discord notification
2. See your progress so far
3. Keep logging: `addInfoToDailyLog "your entry"`

### Evening (6:00 PM)
1. Receive Discord notification with full daily log
2. Review what you accomplished
3. Do your evening review: `gtd-review daily`
4. Process inbox items
5. Plan tomorrow

## Integration with GTD System

These reminders integrate with:

- **Daily Logging** (`addInfoToDailyLog`) - Shows your progress
- **Daily Review** (`gtd-review daily`) - Evening reminder prompts this
- **GTD System** - All reminders encourage proper GTD practices
- **Second Brain** - Can link to your knowledge base

## Best Practices

1. **Set consistent times** - Morning, lunch, evening work well
2. **Do the reviews** - When reminded, actually do the review
3. **Keep logging** - Use `addInfoToDailyLog` throughout the day
4. **Check Discord** - Full messages are there, not in notifications
5. **Make it a habit** - Let Mistress Louiza keep you accountable

## Example Schedule

```
08:00 AM - Morning Reminder
  → Start logging your day
  → Set intentions
  → Log morning activities

12:30 PM - Lunch Reminder
  → Check progress so far
  → Log lunch activities
  → Plan afternoon

06:00 PM - Evening Reminder
  → Review full daily log
  → Do evening review (gtd-review daily)
  → Process inbox
  → Plan tomorrow
```

## Next Steps

1. Run `gtd-setup-all-reminders` to install
2. Test each reminder: `gtd-*-reminder --force`
3. Check Discord for messages
4. Adjust times in `.gtd_config` if needed
5. Start logging and let Mistress Louiza keep you accountable! 🎯

