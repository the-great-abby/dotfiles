# HealthKit Wizard Integration Guide

## ✅ Integration Complete!

The HealthKit integration is now fully available in the GTD Wizard, providing an interactive interface to view, analyze, and manage your health data from Apple Health.

## 🎯 Accessing HealthKit in the Wizard

### From Main Menu

When you run `gtd-wizard` or `make gtd-wizard`, you'll now see:

```
🔍 ANALYSIS - Insights & Tracking:
  ...
  30) 💪 HealthKit & Health Data
```

Select option **30** to access the HealthKit wizard.

## 🔧 HealthKit Wizard Features

The HealthKit wizard (option 30) provides 8 main options:

### 1. 📊 View Today's Health Summary
- Shows today's health metrics at a glance
- Displays steps, calories, exercise minutes, stand hours, heart rate
- Lists recent workouts
- Shows all health entries from today's daily log

**Use when:** You want a quick overview of today's activity

### 2. 📅 View Health Data for Specific Date
- View health data for any past date
- Enter date in YYYY-MM-DD format
- Shows all health entries from that day

**Use when:** You want to review a specific day's health data

### 3. 📈 View Health Trends (Date Range)
- See health data across multiple days
- Default: Last 7 days
- Shows step counts and health activity summaries
- Useful for spotting patterns and trends

**Use when:** You want to see how your health activity changes over time

### 4. 🔄 Sync Health Data from Apple Health
- Manually trigger health data sync
- Runs your configured Shortcuts shortcut
- Logs health data to your daily log
- Awards XP for syncing (gamification)

**Use when:** You want to manually sync health data (e.g., after a workout)

### 5. 💡 Health Insights & Interpretation
- Provides personalized health insights
- Checks exercise status
- Checks medication compliance
- Provides tips and encouragement
- Interprets step counts and exercise minutes

**Use when:** You want to understand your health status and get motivation

### 6. 📋 View Recent Health Entries
- Shows health entries from the last N days (default: 7)
- Lists all health-related log entries
- Useful for quick review

**Use when:** You want to see recent health logging activity

### 7. 🔍 Search Health Data
- Search across all daily logs for health-related terms
- Examples: "workout", "steps", "calories", "heart rate"
- Shows dates and matching entries

**Use when:** You want to find specific health events or metrics

### 8. 📖 HealthKit Setup Guide
- Quick reference for HealthKit setup
- Links to detailed documentation
- Setup instructions

**Use when:** You need help setting up HealthKit integration

## 📊 What Health Data is Displayed

The wizard reads health data from your daily logs, which are populated by:

1. **Apple Health Shortcuts** - Automatic or manual sync
2. **Manual logging** - Using `gtd-daily-log` or `addInfoToDailyLog`
3. **Automatic evening sync** - If configured (see `EVENING_HEALTH_SYNC_SETUP.md`)

### Supported Metrics

- **Steps** - Daily step count
- **Calories** - Active energy/calories burned
- **Exercise Minutes** - Apple Watch exercise ring
- **Stand Hours** - Stand goal hours (out of 12)
- **Heart Rate** - Current or average heart rate
- **Workouts** - Exercise sessions with type, duration, calories
- **Sleep** - Sleep duration and quality
- **Medication** - Pill/medication logging

## 🚀 Quick Start

### 1. Set Up HealthKit Integration (If Not Done)

```bash
# See setup guide
cat zsh/APPLE_HEALTH_INTEGRATION_QUICK_START.md

# Or view in wizard
gtd-wizard
# Then select: 30 (HealthKit) → 8 (Setup Guide)
```

### 2. Sync Health Data

```bash
# Manual sync
gtd-sync-health

# Or via wizard
gtd-wizard
# Then select: 30 (HealthKit) → 4 (Sync Health Data)
```

### 3. View Your Health Data

```bash
gtd-wizard
# Then select: 30 (HealthKit) → 1 (Today's Summary)
```

## 💡 Tips for Best Results

### 1. Regular Syncing
- Sync health data daily (automatic evening sync recommended)
- Or sync manually after workouts using the wizard

### 2. Consistent Logging
- Let Apple Health track automatically
- Use Shortcuts for automatic logging
- Log workouts and activities consistently

### 3. Review Regularly
- Use "Today's Summary" for daily check-ins
- Use "Health Trends" weekly to see patterns
- Use "Health Insights" for motivation and feedback

### 4. Search When Needed
- Use search to find specific workouts or events
- Search for patterns (e.g., "kettlebell", "running")

## 🔗 Integration with Other Systems

### Daily Logs
- All health data appears in your daily logs
- Format: `HH:MM - Apple Watch: [metric]`
- Example: `18:00 - Apple Watch Daily Summary: 12,345 steps, 650 calories`

### Health Reminders
- Health data triggers health reminders (Mistress Louiza)
- Checks for workouts, medication, junk food
- Sends reminders and encouragement via Discord

### Gamification
- Exercise logs award XP automatically
- Health sync awards XP
- Track progress in habit tracker

### Second Brain
- Daily logs sync to Second Brain
- Health data appears in daily notes
- Searchable in your knowledge base

## 📚 Related Documentation

- **Setup:** `zsh/APPLE_HEALTH_INTEGRATION_QUICK_START.md`
- **Shortcuts Setup:** `zsh/APPLE_HEALTH_SHORTCUTS_SETUP.md`
- **Shortcuts Examples:** `zsh/APPLE_HEALTH_SHORTCUTS_EXAMPLES.md`
- **Evening Sync:** `zsh/EVENING_HEALTH_SYNC_SETUP.md`
- **Health Reminders:** `zsh/HEALTH_REMINDER_SETUP.md`

## 🎯 Common Workflows

### Morning Routine
1. Open wizard: `gtd-wizard`
2. Check today's health: Option 30 → 1
3. Get insights: Option 30 → 5
4. Plan your day based on health status

### After Workout
1. Sync health data: Option 30 → 4
2. View summary: Option 30 → 1
3. See insights: Option 30 → 5

### Weekly Review
1. View trends: Option 30 → 3 (last 7 days)
2. Search for patterns: Option 30 → 7 (search "workout")
3. Review insights: Option 30 → 5

## 🐛 Troubleshooting

### No Health Data Showing

1. **Check if data is logged:**
   ```bash
   cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | grep -i "Apple Watch\|Health"
   ```

2. **Sync health data:**
   ```bash
   gtd-sync-health
   ```

3. **Check Shortcuts setup:**
   - Verify Shortcuts shortcut exists
   - Test shortcut manually
   - See Setup Guide (option 8 in wizard)

### Data Not Parsing Correctly

- Health data must be in daily logs
- Format should include keywords like "steps", "calories", "workout"
- Check daily log format matches expected patterns

### Sync Not Working

- Check Shortcuts shortcut name matches config
- Test shortcut manually in Shortcuts app
- Verify `gtd-sync-health` command works
- Check error logs if using automatic sync

## 🎉 Benefits

Once integrated, you can:

- ✅ View health data in one place
- ✅ Track trends and patterns
- ✅ Get personalized health insights
- ✅ Integrate health with GTD system
- ✅ Connect health to goals and habits
- ✅ Search health history easily
- ✅ Review health as part of daily routine

Enjoy your integrated health tracking! 💪🏃‍♀️

