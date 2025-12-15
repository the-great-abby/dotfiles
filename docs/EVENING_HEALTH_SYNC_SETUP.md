# Evening Health Sync Setup

Automatically sync your Apple Health data to your daily log in the evening, before your evening review/check-in.

## 🎯 What This Does

- **Automatically syncs** Apple Health data (steps, workouts, calories, etc.) to your daily log
- **Runs 10 minutes before** your evening review time (default: 5:50 PM if review is 6:00 PM)
- **Integrated** into your evening routine (`gtd-evening` and `gtd-checkin evening`)
- **Prevents duplicates** - won't sync if already logged today (unless forced)

## 🚀 Quick Setup

### Step 1: Create Your Health Sync Shortcut

First, make sure you have a Shortcuts shortcut that logs health data:

1. Open **Shortcuts** app
2. Create a shortcut named: **"Log Daily Health Summary"**
3. Set it up to log your daily health summary (see `APPLE_HEALTH_SHORTCUTS_SETUP.md`)

Or use a custom name and set it in `.gtd_config`:
```bash
GTD_HEALTH_SYNC_SHORTCUT="Your Custom Shortcut Name"
```

### Step 2: Install Automatic Evening Sync

```bash
gtd-setup-health-sync
```

This will:
- Create a launch agent that runs 10 minutes before your evening review
- Use your `GTD_DAILY_REVIEW_TIME` from `.gtd_config` (default: 6:00 PM)
- So if review is at 6:00 PM, sync runs at 5:50 PM

### Step 3: Verify It Works

Test manually:
```bash
gtd-sync-health
```

Check your daily log:
```bash
cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | tail -5
```

## 📅 How It Works

### Automatic Sync (via Launch Agent)

The launch agent runs daily at a set time (10 minutes before your evening review):

```
Evening Review Time: 6:00 PM
Health Sync Time:    5:50 PM
```

### Manual Sync (via Evening Routines)

Health sync is also integrated into:
- **`gtd-evening`** - Automatically syncs health data
- **`gtd-checkin evening`** - Automatically syncs health data before check-in

### Smart Duplicate Prevention

The sync script checks if health data was already logged today. If it finds an entry like:
- "Apple Watch Daily Summary"
- "Apple Watch: [X] steps, [Y] calories"

It won't sync again (unless you use `--force`).

## ⚙️ Configuration

### Change Sync Time

Edit your `.gtd_config`:
```bash
# Evening review time (health sync runs 10 min before this)
GTD_DAILY_REVIEW_TIME="18:00"  # 6:00 PM
```

Then reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
```

Or just run setup again:
```bash
gtd-setup-health-sync
```

### Custom Shortcut Name

If your Shortcuts shortcut has a different name:
```bash
GTD_HEALTH_SYNC_SHORTCUT="My Health Summary Shortcut"
```

### Disable Automatic Sync

```bash
GTD_HEALTH_SYNC_ENABLED="false"
```

Then unload the launch agent:
```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
```

## 🔧 Manual Commands

### Sync Health Data Now
```bash
gtd-sync-health
```

### Force Sync (even if already logged)
```bash
gtd-sync-health --force
```

### Check Sync Status
```bash
# Check if launch agent is loaded
launchctl list | grep health-sync

# Check logs
tail -f /tmp/gtd-health-sync.log
tail -f /tmp/gtd-health-sync.error.log
```

## 📊 What Gets Logged

Your Shortcuts shortcut should log entries like:

```
18:00 - Apple Watch Daily Summary: 12,345 steps, 650 calories burned, 60 exercise minutes, 12 stand hours
```

Or individual metrics:
```
18:00 - Apple Watch: 12,345 steps today
18:00 - Apple Watch Workout: Running - 45 minutes, 450 calories
```

## 🎯 Integration with Evening Routine

### Option 1: Automatic (Recommended)

The launch agent syncs automatically 10 minutes before your evening review. You don't need to do anything!

### Option 2: Manual via Evening Routines

When you run:
- `gtd-evening` - Health sync runs automatically
- `gtd-checkin evening` - Health sync runs automatically

### Option 3: Shortcuts Automation

You can also create a Shortcuts automation:
1. **Automation**: Time of Day (5:50 PM daily)
2. **Action**: Run Shortcut → "Log Daily Health Summary"

This gives you redundancy - if the launch agent fails, Shortcuts will still run.

## 🐛 Troubleshooting

### Sync Not Running

1. **Check launch agent status:**
   ```bash
   launchctl list | grep health-sync
   ```

2. **Check logs:**
   ```bash
   cat /tmp/gtd-health-sync.log
   cat /tmp/gtd-health-sync.error.log
   ```

3. **Reload launch agent:**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
   launchctl load ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
   ```

### Shortcut Not Found

Make sure:
1. Your Shortcuts shortcut exists and is named correctly
2. The shortcut name matches `GTD_HEALTH_SYNC_SHORTCUT` in `.gtd_config`
3. The shortcut can run via Shortcuts CLI (macOS 12+)

### Health Data Not Appearing

1. **Test the shortcut manually** in Shortcuts app
2. **Test the sync script:**
   ```bash
   gtd-sync-health --force
   ```
3. **Check your daily log:**
   ```bash
   cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md
   ```

## 💡 Pro Tips

1. **Test First**: Always test `gtd-sync-health` manually before relying on automation
2. **Check Logs**: If sync isn't working, check the error logs
3. **Redundancy**: Use both launch agent AND Shortcuts automation for reliability
4. **Custom Time**: Adjust the sync time by changing `GTD_DAILY_REVIEW_TIME`
5. **Force Sync**: Use `--force` if you want to log health data multiple times per day

## 🎉 Benefits

Once set up, your Apple Health data will:
- ✅ Automatically appear in your daily log every evening
- ✅ Be ready for your evening review/check-in
- ✅ Trigger your health reminder system
- ✅ Generate AI suggestions/banter
- ✅ Sync to your Second Brain
- ✅ Be searchable in your GTD system

Enjoy your automated evening health sync! 🏃‍♀️💪

