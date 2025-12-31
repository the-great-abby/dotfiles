# Calendar Information System - Usage Guide

## 🎯 Overview

The Calendar Information System helps you plan your day by integrating your Google Calendar (and Outlook) with your GTD system. It provides:

- **Daily calendar overview** in morning check-ins
- **Proactive meeting reminders** (15 minutes before, configurable)
- **Time blocking suggestions** with specific task recommendations
- **Conflict detection** when scheduling tasks
- **Background notifications** via dashboard cache

## 🚀 Quick Start

### 1. Initial Setup

The system uses your existing calendar configuration from `~/.gtd_config_calendar`. Make sure you have:

- `gcalcli` installed and authenticated (`gcalcli init`)
- Calendars configured in `GTD_CALENDARS` array

### 2. First Use

```bash
# Fetch calendar data (creates cache)
gtd-calendar-fetch

# View today's calendar
gtd-calendar-info overview today

# Check for meeting reminders
gtd-calendar-reminders check
```

## 📅 Daily Workflow

### Morning Check-In

When you run `gtd-checkin morning`, you'll automatically see:

```
📅 Today's Calendar

Morning (9:00 AM - 12:00 PM):
  9:00 AM - 10:00 AM  [Work] Team Standup
                      Location: Zoom: https://zoom.us/j/123
                      Duration: 1 hour

📊 Summary:
  • Total events: 3
  • Busy time: 3 hours
  • Free time: 5 hours
  • Next meeting: Team Standup at 9:00 AM (in 30 minutes)
```

### Get Time Blocking Suggestions

```bash
# Get suggestions for today
gtd-calendar-info suggest-blocks today

# Output:
💡 Time Blocking Suggestions

Available blocks:
  • 12:00 PM - 2:00 PM (2 hours)
  • 3:00 PM - 5:00 PM (2 hours)

Recommended tasks:
  • [HIGH] Review quarterly report
    → Schedule: 12:00 PM - 1:00 PM (60 min)
    → Context: work
  
  • [MEDIUM] Write blog post
    → Schedule: 3:00 PM - 5:00 PM (120 min)
```

### Check for Conflicts

Before scheduling a task, check for conflicts:

```bash
gtd-calendar-info conflicts "Review report" "2024-12-02 10:00" 60

# Output:
⚠️  Conflict detected:
   Task: Review report
   Proposed time: 10:00 AM - 11:00 AM
   
   Conflicts with:
   • Team Standup (9:00 AM - 10:00 AM) - Overlaps by 0 minutes
```

## 🔔 Meeting Reminders

### Automatic Reminders

Reminders are checked automatically when you:
- Run `gtd-calendar-reminders check`
- Start a morning check-in
- The system runs in the background (via dashboard cache)

### Reminder Display

When a meeting is approaching, you'll see:

```
🔔 Meeting Reminder
   Team Standup
   Starts in: 15 minutes
   Time: 9:00 AM
   Location: Zoom: https://zoom.us/j/123
   Calendar: Work
   
   Notes:
   Daily standup meeting
   
   Agenda:
   - Updates
   - Blockers
```

### Configure Reminder Times

Edit `~/.gtd_config_calendar`:

```bash
# Default: 15 minutes before
GTD_CALENDAR_REMINDER_TIMES="15"

# Multiple reminders: 1 hour and 15 minutes before
GTD_CALENDAR_REMINDER_TIMES="60,15"

# Custom: 2 hours, 1 hour, and 15 minutes before
GTD_CALENDAR_REMINDER_TIMES="120,60,15"
```

## 📊 Commands Reference

### Calendar Fetcher

```bash
# Fetch and cache calendar data
gtd-calendar-fetch

# Force refresh (ignore cache)
gtd-calendar-fetch --force

# Fetch specific date range
gtd-calendar-fetch --start "2024-12-02" --end "2024-12-09"
```

### Calendar Info

```bash
# Daily overview (today)
gtd-calendar-info overview today

# Daily overview (brief mode)
gtd-calendar-info overview today brief

# Specific date
gtd-calendar-info overview "2024-12-05"

# Time blocking suggestions
gtd-calendar-info suggest-blocks today

# Check for conflicts
gtd-calendar-info conflicts "Task title" "2024-12-02 10:00" 60
```

### Reminders

```bash
# Check for upcoming reminders
gtd-calendar-reminders check

# Update dashboard cache with reminder info
gtd-calendar-reminders update-dashboard
```

## ⚙️ Configuration

### Cache Settings

```bash
# Cache TTL (default: 15 minutes)
GTD_CALENDAR_CACHE_TTL_MINUTES=15
```

### Reminder Settings

```bash
# Reminder times (comma-separated minutes)
GTD_CALENDAR_REMINDER_TIMES="15"        # Default: 15 minutes
GTD_CALENDAR_REMINDER_TIMES="60,15"     # 1 hour and 15 minutes
GTD_CALENDAR_REMINDER_TIMES="120,60,15" # 2 hours, 1 hour, 15 minutes
```

## 🔄 Integration Points

### Morning Check-In

Calendar overview is automatically shown in `gtd-checkin morning`:

```bash
gtd-checkin morning
# Shows calendar overview automatically
```

### Daily Review

Calendar context is shown in `gtd-review daily`:

```bash
gtd-review daily morning   # Shows today's calendar
gtd-review daily evening   # Shows tomorrow's calendar
```

### Dashboard Cache

Reminder information is stored in the dashboard cache (`~/.gtd/.dashboard_cache.json`):

```json
{
  "calendar_reminders": {
    "upcoming": [
      {
        "title": "Team Standup",
        "start": "2024-12-02T09:00:00",
        "time_until_minutes": 15,
        "location": "Zoom",
        "calendar": "Work"
      }
    ],
    "next_meeting": {
      "title": "Team Standup",
      "time_until_minutes": 15
    }
  }
}
```

## 🛠️ Troubleshooting

### Calendar Not Showing

1. **Check gcalcli authentication:**
   ```bash
   gcalcli list
   ```

2. **Re-authenticate if needed:**
   ```bash
   gcalcli init
   ```

3. **Force refresh cache:**
   ```bash
   gtd-calendar-fetch --force
   ```

### Reminders Not Working

1. **Check reminder configuration:**
   ```bash
   grep GTD_CALENDAR_REMINDER_TIMES ~/.gtd_config_calendar
   ```

2. **Manually check reminders:**
   ```bash
   gtd-calendar-reminders check
   ```

3. **Clear reminder tracking:**
   ```bash
   rm ~/.gtd/calendar/reminders_sent.json
   ```

### Cache Issues

1. **Clear cache:**
   ```bash
   rm ~/.gtd/calendar/cache.json
   gtd-calendar-fetch
   ```

2. **Check cache age:**
   ```bash
   ls -lh ~/.gtd/calendar/cache.json
   ```

## 📝 Examples

### Example 1: Morning Planning

```bash
# 1. Morning check-in (shows calendar automatically)
gtd-checkin morning

# 2. Get time blocking suggestions
gtd-calendar-info suggest-blocks today

# 3. Schedule a task (check for conflicts first)
gtd-calendar-info conflicts "Review report" "2024-12-02 14:00" 60
```

### Example 2: Proactive Reminders

```bash
# Check for reminders (can be run periodically)
gtd-calendar-reminders check

# Or set up a cron job:
# */5 * * * * gtd-calendar-reminders check >/dev/null 2>&1
```

### Example 3: Custom Reminder Times

```bash
# Edit config
vim ~/.gtd_config_calendar

# Set multiple reminder times
GTD_CALENDAR_REMINDER_TIMES="120,60,15"

# Reload and test
source ~/.gtd_config_calendar
gtd-calendar-reminders check
```

## 🎯 Best Practices

1. **Run calendar fetch daily** - Set up a cron job or run manually each morning
2. **Use brief mode** - For quick overviews, use `brief` mode
3. **Check conflicts** - Always check for conflicts before scheduling important tasks
4. **Customize reminders** - Adjust reminder times based on your needs
5. **Review suggestions** - Use time blocking suggestions to plan your day

## 🔗 Related Commands

- `gtd-calendar` - Main calendar integration (add events, view calendar)
- `gtd-checkin` - Morning/evening check-ins (includes calendar overview)
- `gtd-review` - Daily reviews (includes calendar context)
- `gcalcli` - Google Calendar CLI (underlying tool)

## 📚 See Also

- [Calendar Information System Design](../architecture/calendar_information_system_design.md)
- [GTD Calendar Integration](../GAMIFICATION_CALENDAR_INTEGRATION.md)
- [Daily Review Timing Guide](../DAILY_REVIEW_TIMING_GUIDE.md)
