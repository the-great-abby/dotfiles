# 🚀 Quick Start: Long-Term Features

## ⚡ Get Started in 5 Minutes

All long-term features are ready! Here's how to use them:

---

## 1. 🔍 Pattern Recognition

**See your behavior patterns:**
```bash
gtd-pattern-recognition
```

**What it shows:**
- Peak logging hours
- Most active days
- Best contexts for tasks
- Optimal energy levels
- Completion rates

**First run:** Analyzes last 30 days of data

---

## 2. ⚡ Energy-Aware Scheduling

**Get tasks matched to your energy:**
```bash
gtd-energy-schedule suggest
```

**What it does:**
- Matches tasks to your current energy level
- Learns your peak completion times
- Suggests optimal scheduling

**Example:**
```bash
# Get 10 suggestions for high energy
gtd-energy-schedule suggest high 10

# Get scheduling recommendation
gtd-energy-schedule schedule task-123 high
```

---

## 3. 🔔 Predictive Reminders

**Learn when you forget:**
```bash
gtd-predictive-reminders analyze
```

**What it does:**
- Analyzes when you forget to log
- Identifies gap patterns
- Sends reminders at optimal times

**Check if reminder needed:**
```bash
gtd-predictive-reminders check
```

---

## 4. 📅 Calendar Integration

**View both calendars:**
```bash
gtd-calendar view
```

**Check conflicts:**
```bash
gtd-calendar conflicts '2024-12-02 10:00' '2024-12-02 11:00'
```

**Sync task to calendar:**
```bash
gtd-calendar sync task-123 google
```

**Setup Google Calendar:**
1. `brew install gcalcli`
2. `gcalcli login`
3. Done! (uses existing calendar functions)

---

## 🎯 Daily Workflow

### Morning:
```bash
# Get energy-aware tasks
gtd-energy-schedule suggest

# Check calendar
gtd-calendar view
```

### Throughout Day:
- Pattern recognition learns automatically
- Predictive reminders trigger when needed

### Evening:
```bash
# See your patterns
gtd-pattern-recognition insights
```

---

## 📊 What Gets Learned

**Pattern Recognition tracks:**
- When you log (hours, days)
- When you forget (gaps)
- Task completion (contexts, energy, times)
- Productivity metrics

**Data stored in:** `~/.gtd/.patterns/`

---

## 🔧 Quick Setup

### Pattern Recognition
✅ **No setup needed!** Just run it.

### Energy Scheduling
✅ **No setup needed!** Uses existing energy levels.

### Predictive Reminders
✅ **No setup needed!** Learns automatically.

### Calendar Integration
**Google Calendar:**
1. `brew install gcalcli` (if not installed)
2. `gcalcli login`
3. Done!

**Office 365:**
- Requires Microsoft Graph API credentials
- See `LONG_TERM_FEATURES_COMPLETE.md` for details

---

## 💡 Pro Tips

1. **Run pattern recognition weekly** to see trends
2. **Use energy scheduling** to match tasks to your energy
3. **Check calendar conflicts** before scheduling
4. **Let predictive reminders learn** - they get better over time

---

## 📚 Full Documentation

See `LONG_TERM_FEATURES_COMPLETE.md` for complete details.

---

**Everything is ready! Start using the features now!** 🎉





