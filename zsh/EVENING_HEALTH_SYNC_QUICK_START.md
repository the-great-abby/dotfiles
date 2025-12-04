# Evening Health Sync - Quick Start

## ✅ What's Been Set Up

You now have automatic evening health sync! Here's what was created:

1. **Sync Script**: `bin/gtd-sync-health` - Syncs Apple Health data to daily log
2. **Setup Script**: `bin/gtd-setup-health-sync` - Installs automatic evening sync
3. **Integration**: Health sync added to `gtd-evening` and `gtd-checkin evening`

## 🚀 Next Steps (3 Minutes)

### 1. Create Your Health Summary Shortcut

1. Open **Shortcuts** app
2. Create shortcut named: **"Log Daily Health Summary"**
3. Set it up to log daily health summary (see `APPLE_HEALTH_SHORTCUTS_EXAMPLES.md`)

### 2. Test Manual Sync

```bash
# Test that sync works
gtd-sync-health

# Check your daily log
cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | tail -3
```

### 3. Install Automatic Evening Sync

```bash
gtd-setup-health-sync
```

This will:
- Run 10 minutes before your evening review (default: 5:50 PM if review is 6:00 PM)
- Automatically sync health data every evening
- Prevent duplicates (won't sync if already logged)

## 📅 How It Works

### Automatic Sync
- **Runs daily** at 5:50 PM (10 min before 6:00 PM review)
- **Uses your Shortcuts shortcut** to log health data
- **Prevents duplicates** - won't sync if already logged today

### Manual Sync
- **`gtd-evening`** - Automatically syncs health data
- **`gtd-checkin evening`** - Automatically syncs health data
- **`gtd-sync-health`** - Manual sync anytime

## ⚙️ Configuration

### Change Sync Time

Edit `.gtd_config`:
```bash
GTD_DAILY_REVIEW_TIME="18:00"  # Health sync runs 10 min before this
```

Then reload:
```bash
gtd-setup-health-sync  # Re-runs setup with new time
```

### Custom Shortcut Name

If your shortcut has a different name:
```bash
GTD_HEALTH_SYNC_SHORTCUT="My Custom Shortcut Name"
```

## 🎯 What Gets Logged

Your shortcut should log entries like:
```
18:00 - Apple Watch Daily Summary: 12,345 steps, 650 calories, 60 exercise minutes
```

## 📚 Full Documentation

- **Setup Guide**: `zsh/EVENING_HEALTH_SYNC_SETUP.md` - Complete instructions
- **Shortcuts Setup**: `zsh/APPLE_HEALTH_SHORTCUTS_SETUP.md` - How to create shortcuts
- **Examples**: `zsh/APPLE_HEALTH_SHORTCUTS_EXAMPLES.md` - Ready-to-use templates

## 🐛 Troubleshooting

### Sync Not Working?

1. **Test manually:**
   ```bash
   gtd-sync-health --force
   ```

2. **Check logs:**
   ```bash
   tail -f /tmp/gtd-health-sync.log
   ```

3. **Verify shortcut exists** in Shortcuts app

4. **Reload launch agent:**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
   launchctl load ~/Library/LaunchAgents/com.abby.gtd.health-sync.plist
   ```

## 🎉 Benefits

Once set up:
- ✅ Health data automatically logged every evening
- ✅ Ready for evening review/check-in
- ✅ Triggers health reminder system
- ✅ Generates AI suggestions
- ✅ Syncs to Second Brain

Enjoy your automated evening health sync! 🏃‍♀️💪

