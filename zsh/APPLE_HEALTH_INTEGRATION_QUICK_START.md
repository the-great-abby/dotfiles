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

> **⚠️ Reality Check:** Health actions often **don't appear in Shortcuts search**. They're hard to find and may not work on all devices. We recommend starting with **Manual Logging** (see below) - it's simpler and more reliable!

#### Option A: Manual Logging (Recommended - Works Everywhere)

**Simplest approach that works on all devices:**

1. Open **Shortcuts** app on your iPhone/iPad/Mac
2. Tap **+** to create new shortcut
3. Name it: **"Log Health Data"**
4. Add these actions:
   - **Ask for Input** → Type: Text → Prompt: "Enter health data (e.g., '12,345 steps' or '30 min workout, 300 calories'):"
   - **Get Current Date** → Format: Custom → Format String: **HH:mm**
   - **Run Shell Script** → 
     - Shell: **/bin/zsh**
     - Input: **as arguments**
     - Script: `"$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"`
     - Pass inputs: Ask for Input as $1, Formatted Date as $2

**To use:**
- Run the shortcut
- When prompted, enter your health data
- Examples:
  - "12,345 steps"
  - "30 min kettlebell workout, 300 calories"
  - "Heart rate: 72 bpm"
  - "8 hours sleep"

#### Option B: Automated Health Actions (Advanced - May Not Work)

**Only try this if you can find Health actions:**

1. Open **Shortcuts** app
2. Browse action categories (don't search - browse manually)
3. Look for **"Health"** category
4. If found, use:
   - **Find Health Samples** (or "Get Health Samples") → Type: Workouts
   - **Get Details** → Extract workout info
   - Format as text
   - Run Shell Script (same as above)

**If you can't find Health category:** Use Option A (Manual Logging) instead!

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

You can log any health data manually, or automatically if Health actions are available:

- ✅ Workouts (type, duration, calories, distance)
- ✅ Steps (daily count)
- ✅ Heart Rate (current, resting, workout average)
- ✅ Active Energy (calories burned)
- ✅ Exercise Minutes (Apple Watch rings)
- ✅ Stand Hours
- ✅ Sleep (duration, quality)

**Note:** With manual logging, you simply type in the data. For example:
- "12,345 steps"
- "30 min workout, 300 calories"
- "Heart rate: 72 bpm"

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

