# Evening Summary Setup Guide

## 🎯 What This Does

The evening summary automatically:
- ✅ Collects all daily metrics (health, weather, calendar, mood)
- ✅ Creates a comprehensive summary
- ✅ Logs to your daily log
- ✅ Sends to Discord (if configured)
- ✅ Runs automatically before your evening review

## 🚀 Quick Setup

### Step 1: Create Shortcuts (5 minutes)

Create these Shortcuts shortcuts (see `EVENING_SUMMARY_SHORTCUTS.md` for details):
1. **"Log Mood"** - Logs mood and energy
2. **"Get Weather"** - Gets and logs weather
3. **"Get Today's Calendar"** - Gets and logs calendar events
4. **"Log Daily Health Summary"** - Already have this from health sync!

### Step 2: Install Automatic Summary

```bash
gtd-setup-evening-summary
```

This will:
- Create a launch agent that runs 5 minutes before your evening review
- Default: 5:55 PM if review is at 6:00 PM
- Automatically collect and summarize all metrics

### Step 3: Configure Discord (Optional)

Edit your `.gtd_config`:
```bash
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
GTD_DISCORD_EVENING_SUMMARY="true"
```

## 📊 What Gets Summarized

The evening summary automatically finds and includes:

1. **💪 Health Data**
   - Steps, calories, exercise minutes
   - Workouts completed
   - From Apple Health sync

2. **🌤️ Weather**
   - Condition and temperature
   - From weather logging

3. **📅 Calendar Events**
   - Meetings and appointments
   - From calendar logging

4. **😊 Mood & Energy**
   - Latest mood check-in
   - Energy level
   - From mood logging

5. **📝 Daily Log Stats**
   - Total entries today
   - Activity summary

6. **✅ Tasks**
   - Tasks completed today

7. **📥 Inbox Status**
   - Pending items count

## 🕐 When It Runs

### Automatic (via Launch Agent)
- **Time**: 5 minutes before your evening review
- **Default**: 5:55 PM (if review is 6:00 PM)
- **Frequency**: Daily

### Manual
- **`gtd-evening`** - Automatically creates summary
- **`gtd-evening-summary`** - Run anytime

## 📱 Manual Logging

You can also log metrics manually throughout the day:

### Log Mood
```bash
gtd-log-mood 8 high "Feeling great after workout"
# Or interactive:
gtd-log-mood
```

### Log Weather
```bash
gtd-log-weather "Sunny" "72" "F"
# Or interactive:
gtd-log-weather
```

### Log Calendar Event
```bash
gtd-log-calendar "Meeting: Sprint Planning (1.5 hours)"
# Or interactive:
gtd-log-calendar
```

## 🔧 Configuration

### Change Summary Time

Edit `.gtd_config`:
```bash
GTD_DAILY_REVIEW_TIME="18:00"  # Summary runs 5 min before this
```

Then reload:
```bash
gtd-setup-evening-summary  # Re-runs setup
```

### Disable Discord

```bash
gtd-evening-summary --no-discord
```

Or set in config:
```bash
GTD_DISCORD_EVENING_SUMMARY="false"
```

### Disable Automatic Summary

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.evening-summary.plist
```

## 📋 Example Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌙 Evening Summary - 2025-01-15 17:55
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💪 **Health:** Apple Watch Daily Summary: 12,345 steps, 650 calories burned, 60 exercise minutes
🌤️  **Weather:** Sunny, 72°F
📅 **Calendar:** 3 event(s) today
   • Meeting: Sprint Planning (1.5 hours)
   • Appointment: Doctor (30 minutes)
   • Call: Team Standup (30 minutes)
😊 **Mood & Energy:** Mood: 8/10, Energy: high - Feeling productive
📝 **Daily Log:** 12 entries today
✅ **Tasks:** 5 completed today
📥 **Inbox:** Empty ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🐛 Troubleshooting

### Summary Not Running

1. **Check launch agent:**
   ```bash
   launchctl list | grep evening-summary
   ```

2. **Check logs:**
   ```bash
   tail -f /tmp/gtd-evening-summary.log
   tail -f /tmp/gtd-evening-summary.error.log
   ```

3. **Reload launch agent:**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.abby.gtd.evening-summary.plist
   launchctl load ~/Library/LaunchAgents/com.abby.gtd.evening-summary.plist
   ```

### No Data in Summary

The summary only includes data that was logged today. Make sure:
- Health sync ran (or was logged manually)
- Weather was logged (via shortcut or manually)
- Calendar events were logged
- Mood was logged

### Discord Not Sending

1. **Check webhook URL:**
   ```bash
   echo $GTD_DISCORD_WEBHOOK_URL
   ```

2. **Test manually:**
   ```bash
   gtd-evening-summary  # Should send to Discord
   ```

3. **Check Discord logs** in the error log file

## 💡 Tips

1. **Log Throughout Day**: Log mood, weather, and calendar events as they happen
2. **Evening Summary Finds Everything**: You don't need to log everything at once
3. **Manual Override**: Always run `gtd-evening-summary` manually if needed
4. **Review Summary**: Check the summary in your daily log after it runs
5. **Discord Archive**: Summary in Discord serves as a backup/archive

## 🎉 Benefits

Once set up:
- ✅ **Automatic Collection** - No manual work needed
- ✅ **Comprehensive View** - See your entire day at a glance
- ✅ **Discord Archive** - Summary saved to Discord
- ✅ **Review Ready** - Summary ready for evening review
- ✅ **Pattern Recognition** - AI can analyze patterns over time

Enjoy your automated evening summaries! 🌙📊

