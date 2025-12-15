# 📅 Gamification & Calendar Integration

## 🎮 How Calendar Activities Award XP

The gamification system now integrates with your calendar (gcalcli) to reward you for calendar-related activities!

## 🎯 XP Awards for Calendar Activities

### 1. Logging Calendar Events
**Command:** `gtd-log-calendar` or `gtd-log-calendar "Meeting: Sprint Planning"`

**XP Award:** 5 XP (health_log activity type)

**When:** Every time you log a calendar event to your daily log

**Example:**
```bash
gtd-log-calendar "Meeting: Team Standup (30 min)"
# ✓ Added: 10:00 - Calendar: Meeting: Team Standup (30 min)
# +5 XP (Logged calendar event)
```

### 2. Syncing Tasks to Calendar
**Command:** `gtd-calendar sync <task-id> google`

**XP Award:** 25 XP (task activity type)

**When:** When you sync a GTD task to your Google Calendar

**Example:**
```bash
gtd-calendar sync task-123 google
# ✓ Added to Google Calendar: Review quarterly report
# +25 XP (Synced task to calendar: Review quarterly report)
```

### 3. Adding Calendar Events Directly
**Command:** `gtd-calendar google add "Meeting" "2024-12-02 10:00" 60`

**XP Award:** 25 XP (task activity type)

**When:** When you add an event directly to Google Calendar via gcalcli

**Example:**
```bash
gtd-calendar google add "Client Meeting" "2024-12-02 14:00" 60
# +25 XP (Added calendar event: Client Meeting)
```

## 📊 Integration Points

### Automatic Integration
- **`gtd-log-calendar`**: Automatically awards XP when logging calendar events
- **`gtd-calendar sync`**: Automatically awards XP when syncing tasks to calendar
- **`gtd-calendar google add`**: Automatically awards XP when adding events

### Silent Operation
- Gamification hooks fail silently if gamification isn't set up
- Your calendar commands work normally even without gamification
- No performance impact - XP awards are fast and non-blocking

## 🎯 Calendar-Related Achievements

While there aren't calendar-specific achievements yet, calendar activities contribute to:
- **Daily Logging Streak**: Logging calendar events maintains your daily logging streak
- **Task Completion**: Syncing tasks to calendar is tracked as task activity
- **Health Logging**: Calendar events are logged as health/logging activities

## 💡 Tips for Maximum XP

1. **Log Your Calendar Events**: Use `gtd-log-calendar` to log meetings and events
2. **Sync Tasks to Calendar**: When you schedule a task, sync it to calendar for bonus XP
3. **Plan Ahead**: Adding events to calendar helps with planning and earns XP
4. **Daily Logging**: Calendar events logged to daily log contribute to your logging streak

## 🔄 Workflow Example

```bash
# Morning: Check calendar
gtd-calendar view 7

# Log today's meetings
gtd-log-calendar "Standup: 9:00 AM (15 min)"
# +5 XP

# Sync an important task to calendar
gtd-calendar sync task-456 google
# +25 XP

# Add a new meeting
gtd-calendar google add "1-on-1 with Manager" "2024-12-02 15:00" 30
# +25 XP
```

## 📚 Related Commands

- **`gtd-calendar view`**: View calendar (no XP, but helps with planning)
- **`gtd-calendar conflicts`**: Check for scheduling conflicts
- **`gtd-log-calendar`**: Log calendar events to daily log (+5 XP)
- **`gtd-calendar sync`**: Sync tasks to calendar (+25 XP)
- **`gtd-calendar google add`**: Add events to Google Calendar (+25 XP)

## 🎮 Gamification Dashboard

Check your calendar-related XP in the gamification dashboard:

```bash
gtd-gamify dashboard
```

Calendar activities will show up in:
- **Statistics**: Health logs (from calendar event logging)
- **Task Statistics**: Tasks synced to calendar
- **Daily Logs**: Calendar events logged

---

**Happy scheduling and earning XP!** 📅🎮

