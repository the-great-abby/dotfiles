# Metric Collection Optimizations - Quick Start

## ✅ What's Been Added

Easy optimizations to help gather metrics with minimal effort:

1. **Morning Context Collection** (`gtd-morning-context`) - Auto-collects weather, calendar, prompts for mood
2. **Batch Collection** (`gtd-collect-all`) - One command to collect everything
3. **Setup Scripts** - Automate morning collection

## 🚀 Quick Setup (5 Minutes)

### 1. Test Morning Context

```bash
# Test manually
gtd-morning-context

# This will:
# - Fetch weather automatically
# - Get today's calendar
# - Prompt for mood
```

### 2. Install Automatic Morning Collection

```bash
gtd-setup-morning-context
```

This will:
- Run daily at your morning reminder time (default: 8:00 AM)
- Automatically collect weather and calendar
- Prompt for mood via notification

### 3. Test Batch Collection

```bash
# Collect everything at once
gtd-collect-all

# Or skip certain metrics
gtd-collect-all --skip-health
gtd-collect-all --skip-calendar
```

## 📊 What Gets Collected

### Morning Context (Automatic)
- ✅ Weather (automatic fetch)
- ✅ Today's calendar events (automatic fetch)
- ✅ Mood (prompted)

### Batch Collection (Manual)
- ✅ Weather
- ✅ Calendar events
- ✅ Health data
- ✅ Mood & energy

## 🎯 Daily Workflow

### Morning (Automatic)
- **8:00 AM** - Morning context collected automatically
- Weather and calendar logged
- Mood prompt sent

### Anytime (Manual)
- **`gtd-collect-all`** - Collect everything at once
- Great for catch-up or end-of-day

### Evening (Automatic)
- **5:55 PM** - Evening summary runs
- Collects all logged metrics
- Creates comprehensive summary

## 💡 Quick Wins

### 1. Morning Automation
```bash
gtd-setup-morning-context
```
Now weather and calendar are logged automatically every morning!

### 2. Quick Catch-Up
```bash
gtd-collect-all
```
One command collects everything if you missed logging during the day.

### 3. Quick Mood (Create Shortcut)
Create a Shortcuts shortcut "Quick Mood" that just asks for mood number, assumes medium energy.

## 📚 Full Documentation

- **Optimizations Guide**: `zsh/METRIC_COLLECTION_OPTIMIZATIONS.md` - All 15 optimizations
- **Evening Summary**: `zsh/EVENING_SUMMARY_SETUP.md` - Evening collection
- **Health Sync**: `zsh/EVENING_HEALTH_SYNC_SETUP.md` - Health data

## 🎉 Benefits

- ✅ **Less Effort** - More automation = less manual work
- ✅ **More Data** - Easier collection = more metrics
- ✅ **Better Patterns** - More data = better insights
- ✅ **Consistent** - Automation = consistent logging

Enjoy your optimized metric collection! 📊🚀

