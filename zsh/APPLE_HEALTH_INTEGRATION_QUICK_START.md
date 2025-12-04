# Apple Health Integration - Quick Start

## ✅ What's Been Set Up

You now have Apple Health/Apple Watch integration via Shortcuts! Here's what was created:

1. **Helper Script**: `bin/gtd-healthkit-log` - Receives health data from Shortcuts and logs it
2. **Setup Guide**: `zsh/APPLE_HEALTH_SHORTCUTS_SETUP.md` - Complete setup instructions
3. **Examples**: `zsh/APPLE_HEALTH_SHORTCUTS_EXAMPLES.md` - Ready-to-use shortcut templates

## 🚀 Next Steps (5 Minutes)

### 1. Test the Helper Script

```bash
# Test that the script works
gtd-healthkit-log "Test: Apple Watch workout - 30 minutes, 300 calories" "14:30"

# Check your daily log
cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | tail -3
```

### 2. Create Your First Shortcut

1. Open **Shortcuts** app on your iPhone/iPad/Mac
2. Tap **+** to create new shortcut
3. Name it: **"Log Workout"**
4. Add these actions:
   - **Get Health Samples** → Type: Workouts, Date: Today, Limit: 1
   - **Get Details** → Get: Workout Type, Duration, Total Energy Burned
   - **Text** → Format: `Apple Watch Workout: [Workout Type] - [Duration] minutes, [Total Energy Burned] calories`
   - **Get Current Date** → Format: HH:mm
   - **Run Shell Script** → Script: `"$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"`
     - Pass: Text as $1, Formatted Date as $2

### 3. Test It

- Run the shortcut manually
- Check your daily log to see the entry

### 4. Automate It (Optional)

- Go to **Automation** tab in Shortcuts
- Create automation: **When Workout Ends**
- Action: **Run Shortcut** → Select "Log Workout"
- Turn off "Ask Before Running"

## 📚 Full Documentation

For complete setup instructions and more examples, see:
- **Setup Guide**: `zsh/APPLE_HEALTH_SHORTCUTS_SETUP.md`
- **Examples**: `zsh/APPLE_HEALTH_SHORTCUTS_EXAMPLES.md`

## 🎯 What You Can Log

- ✅ Workouts (type, duration, calories, distance)
- ✅ Steps (daily count)
- ✅ Heart Rate (current, resting, workout average)
- ✅ Active Energy (calories burned)
- ✅ Exercise Minutes (Apple Watch rings)
- ✅ Stand Hours
- ✅ Sleep (duration, quality)

## 💡 Pro Tip

Start with one shortcut (workouts are easiest), test it, then add more. You can create shortcuts for:
- Individual metrics (steps, heart rate)
- Daily summaries (all metrics at once)
- Specific triggers (after workout, end of day, etc.)

## 🔗 Integration Benefits

Once set up, your Apple Health data will:
- ✅ Automatically appear in your daily log
- ✅ Trigger your health reminder system (Mistress Louiza)
- ✅ Generate AI suggestions/banter
- ✅ Sync to your Second Brain
- ✅ Be searchable in your GTD system

Enjoy your automated health logging! 🏃‍♀️💪

