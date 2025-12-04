# Evening Metrics System - Complete Setup ✅

## 🎉 What's Been Created

You now have a complete evening metrics and summary system! Here's everything that was set up:

### Scripts Created

1. **`bin/gtd-log-mood`** - Log mood and energy
   - Usage: `gtd-log-mood [mood] [energy] [note]`
   - Interactive mode if no args provided
   - Validates input (mood 1-10, energy: high/medium/low)

2. **`bin/gtd-log-weather`** - Log weather conditions
   - Usage: `gtd-log-weather [condition] [temperature] [unit]`
   - Can fetch from Shortcuts or prompt manually

3. **`bin/gtd-log-calendar`** - Log calendar events
   - Usage: `gtd-log-calendar [summary]`
   - Can fetch from Shortcuts or prompt manually

4. **`bin/gtd-evening-summary`** - Comprehensive evening summary
   - Collects all metrics automatically
   - Logs to daily log
   - Sends to Discord (if configured)
   - Options: `--no-discord`, `--force`

5. **`bin/gtd-setup-evening-summary`** - Setup automation
   - Creates launch agent for automatic summaries
   - Runs 5 minutes before evening review

### Integration

- ✅ **Evening routine** (`gtd-evening`) - Automatically creates summary
- ✅ **Evening check-in** (`gtd-checkin evening`) - Health sync already integrated
- ✅ **Discord** - Summaries sent automatically
- ✅ **Daily log** - All metrics logged
- ✅ **AI suggestions** - Metrics trigger AI analysis

## 📋 Next Steps

### 1. Create Shortcuts (Required)

Create these Shortcuts shortcuts (see `EVENING_SUMMARY_SHORTCUTS.md`):

- **"Log Mood"** - Logs mood and energy
- **"Get Weather"** - Gets and logs weather
- **"Get Today's Calendar"** - Gets and logs calendar events

### 2. Test Everything

```bash
# Test mood logging
gtd-log-mood 8 high "Feeling great"

# Test weather logging
gtd-log-weather "Sunny" "72" "F"

# Test calendar logging
gtd-log-calendar "Meeting: Sprint Planning (1.5 hours)"

# Test evening summary (without Discord)
gtd-evening-summary --no-discord

# Check your daily log
cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | tail -20
```

### 3. Install Automation

```bash
gtd-setup-evening-summary
```

This sets up automatic evening summaries that run 5 minutes before your evening review.

### 4. Configure Discord (Optional)

Edit `.gtd_config`:
```bash
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

## 🎯 Daily Workflow

### Morning
- Log weather (via Shortcuts automation or manually)
- Log mood (optional, but helpful)

### Throughout Day
- Log calendar events after meetings
- Log mood changes if significant
- Health data syncs automatically (if set up)

### Evening (Automatic)
1. **5:55 PM** - Evening summary runs automatically
   - Collects all metrics
   - Creates summary
   - Logs to daily log
   - Sends to Discord

2. **6:00 PM** - Evening review reminder
   - Review the summary
   - Do evening check-in
   - Plan tomorrow

### Manual Override
- Run `gtd-evening-summary` anytime
- Run `gtd-evening` to create summary manually

## 📊 What Gets Summarized

The evening summary automatically finds:

- ✅ **Health Data** - Steps, calories, workouts (from health sync)
- ✅ **Weather** - Condition and temperature (if logged)
- ✅ **Calendar** - Meetings and appointments (if logged)
- ✅ **Mood & Energy** - Latest mood check-in (if logged)
- ✅ **Daily Log Stats** - Total entries today
- ✅ **Tasks** - Tasks completed today
- ✅ **Inbox** - Pending items count

## 🔧 Commands Reference

### Logging Commands

```bash
# Mood
gtd-log-mood 8 high "Feeling productive"
gtd-log-mood  # Interactive mode

# Weather
gtd-log-weather "Sunny" "72" "F"
gtd-log-weather  # Interactive mode

# Calendar
gtd-log-calendar "Meeting: Sprint Planning (1.5 hours)"
gtd-log-calendar  # Interactive mode
```

### Summary Commands

```bash
# Create summary
gtd-evening-summary              # With Discord
gtd-evening-summary --no-discord # Without Discord
gtd-evening-summary --force      # Force even if already logged

# Setup automation
gtd-setup-evening-summary
```

## 📚 Documentation

- **Quick Start**: `zsh/EVENING_SUMMARY_QUICK_START.md`
- **Full Setup**: `zsh/EVENING_SUMMARY_SETUP.md`
- **Shortcuts Guide**: `zsh/EVENING_SUMMARY_SHORTCUTS.md`
- **Health Sync**: `zsh/EVENING_HEALTH_SYNC_SETUP.md`

## 🎉 Benefits

Once fully set up:

- ✅ **Automatic Collection** - No manual work needed
- ✅ **Comprehensive View** - See entire day at a glance
- ✅ **Discord Archive** - Summaries saved to Discord
- ✅ **Review Ready** - Perfect for evening review
- ✅ **Pattern Recognition** - AI can analyze patterns
- ✅ **Context Rich** - Weather, mood, calendar all in one place

## 🐛 Troubleshooting

### Summary Not Running
```bash
# Check launch agent
launchctl list | grep evening-summary

# Check logs
tail -f /tmp/gtd-evening-summary.log
tail -f /tmp/gtd-evening-summary.error.log

# Reload
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.evening-summary.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.evening-summary.plist
```

### No Data in Summary
- Make sure metrics were logged today
- Check daily log: `cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md`
- Log metrics manually if needed

### Discord Not Sending
- Check webhook URL: `echo $GTD_DISCORD_WEBHOOK_URL`
- Test manually: `gtd-evening-summary`
- Check error logs

## 💡 Pro Tips

1. **Log Throughout Day** - Don't wait until evening
2. **Use Shortcuts** - Automate as much as possible
3. **Review Summary** - Check it in your daily log
4. **Discord Archive** - Use Discord as backup
5. **Start Simple** - Add more metrics gradually

## 🚀 You're All Set!

Everything is ready to go. Just:
1. Create the Shortcuts shortcuts
2. Test the commands
3. Install automation
4. Enjoy your automated evening summaries!

The system will automatically collect, summarize, and send everything to Discord every evening. Perfect for your evening review! 🌙📊

