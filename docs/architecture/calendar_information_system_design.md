# Calendar Information System Design

## 🎯 Overview

A calendar information system that helps plan your day and provides proactive meeting reminders, integrated with the GTD system.

## 📋 Requirements

1. **Data Source**: Google Calendar via `gcalcli`
2. **Multiple Calendars**: Support Google (home) and Outlook (work)
3. **Daily Overview/Review**: Morning review showing today's schedule
4. **Proactive Suggestions**: Planning assistance throughout the day
5. **Meeting Reminders**: Multiple reminders (e.g., 1 hour, 15 minutes before)
6. **Integration**: Works with GTD check-ins and reviews
7. **Data Format**: JSON or structured text
8. **Caching**: On-demand queries with periodic updates

## 🏗️ Architecture

### Data Flow

```
gcalcli → Calendar Fetcher → JSON Cache → Calendar Service → GTD Integration
                                                      ↓
                                            Reminder System
```

### Components

1. **Calendar Fetcher** (`gtd-calendar-fetch`)
   - Uses `gcalcli` to fetch events from all configured calendars
   - Converts to structured JSON format
   - Handles errors and authentication

2. **Calendar Cache** (`~/.gtd/calendar/cache.json`)
   - Stores fetched calendar events
   - Includes metadata (last fetch time, calendar sources)
   - TTL-based refresh (default: 15 minutes)

3. **Calendar Service** (`gtd-calendar-info`)
   - Main interface for calendar information
   - Provides daily overview, upcoming events, reminders
   - Integrates with GTD system

4. **Reminder System** (`gtd-calendar-reminders`)
   - Background process or on-demand checks
   - Multiple reminder times (configurable)
   - Displays meeting details (time, location, notes, agenda)

5. **GTD Integration**
   - Morning check-in shows calendar overview
   - Daily review includes calendar context
   - Proactive suggestions based on calendar gaps

## 📊 Data Format

### JSON Structure

```json
{
  "metadata": {
    "last_fetch": "2024-12-02T10:30:00Z",
    "fetch_duration_ms": 1234,
    "calendars_fetched": ["GTD", "Work"],
    "cache_ttl_minutes": 15
  },
  "events": [
    {
      "id": "event_123",
      "title": "Team Standup",
      "start": "2024-12-02T10:00:00-08:00",
      "end": "2024-12-02T10:30:00-08:00",
      "calendar": "Work",
      "calendar_display": "Work Calendar",
      "location": "Zoom: https://zoom.us/j/123",
      "description": "Daily standup meeting\n\nAgenda:\n- Updates\n- Blockers",
      "attendees": ["alice@example.com", "bob@example.com"],
      "is_all_day": false,
      "reminders_sent": []
    }
  ]
}
```

### Structured Text Format (Alternative)

```
=== Calendar Cache ===
Last Fetch: 2024-12-02 10:30:00
Calendars: GTD, Work

--- Event: Team Standup ---
Time: 2024-12-02 10:00 - 10:30
Calendar: Work
Location: Zoom: https://zoom.us/j/123
Description:
  Daily standup meeting
  
  Agenda:
  - Updates
  - Blockers
Attendees: alice@example.com, bob@example.com
```

## 🔄 Caching Strategy

### Cache Location
- `~/.gtd/calendar/cache.json` (or `$GTD_BASE_DIR/calendar/cache.json`)

### Cache TTL
- Default: 15 minutes
- Configurable via `GTD_CALENDAR_CACHE_TTL_MINUTES`
- Force refresh: `gtd-calendar-fetch --force`

### Cache Invalidation
- Time-based: Check if cache is older than TTL
- Event-based: Force refresh before important operations
- Manual: `gtd-calendar-fetch --force`

### Cache Update Process
1. Check cache age
2. If expired or forced, fetch from `gcalcli`
3. Parse and convert to JSON
4. Save to cache file
5. Return cached data

## 📅 Daily Overview

### Morning Review Integration

**Command**: `gtd-calendar-info overview --date today`

**Output Format**:
```
📅 Today's Calendar - Monday, December 2, 2024

Morning (9:00 AM - 12:00 PM):
  9:00 AM - 10:00 AM  [Work] Team Standup
                      Location: Zoom: https://zoom.us/j/123
                      Duration: 1 hour

  11:00 AM - 12:00 PM [GTD]  Deep Work Block
                      No location
                      Duration: 1 hour

Afternoon (12:00 PM - 5:00 PM):
  2:00 PM - 3:00 PM   [Work] Client Meeting
                      Location: Conference Room A
                      Notes: Prepare quarterly report
                      Duration: 1 hour

Evening (5:00 PM - 9:00 PM):
  No events scheduled

📊 Summary:
  • Total events: 3
  • Busy time: 3 hours
  • Free time: 5 hours
  • Next meeting: Team Standup at 9:00 AM (in 30 minutes)
```

### Integration Points

1. **Morning Check-In** (`gtd-checkin morning`)
   - Automatically shows calendar overview
   - Helps set priorities based on calendar commitments

2. **Daily Review** (`gtd-review daily morning`)
   - Includes calendar context
   - Shows conflicts with planned tasks

3. **Standalone Command**
   - `gtd-calendar-info overview` - Quick calendar view
   - `gtd-calendar-info today` - Today's events only

## 🔔 Meeting Reminders

### Reminder Times

**Default**: 1 hour, 15 minutes before meeting
**Configurable**: `GTD_CALENDAR_REMINDER_TIMES="60,15"` (minutes)

### Reminder Format

```
🔔 Meeting Reminder: Team Standup
   Starts in: 15 minutes (9:00 AM)
   Location: Zoom: https://zoom.us/j/123
   Calendar: Work
   
   Notes:
   Daily standup meeting
   
   Agenda:
   - Updates
   - Blockers
   
   Attendees: alice@example.com, bob@example.com
```

### Reminder Delivery

1. **On-Demand Check** (`gtd-calendar-reminders check`)
   - Check for upcoming meetings
   - Show reminders that haven't been sent yet
   - Mark reminders as sent

2. **Background Process** (Future)
   - Periodic checks (every 5 minutes)
   - Desktop notifications
   - Terminal notifications

3. **Integration Points**
   - Before running any GTD command
   - During morning check-in
   - Manual check: `gtd-calendar-reminders`

### Reminder Tracking

Store sent reminders in cache:
```json
{
  "reminders_sent": [
    {
      "event_id": "event_123",
      "reminder_time_minutes": 60,
      "sent_at": "2024-12-02T08:00:00Z"
    }
  ]
}
```

## 🎯 Proactive Suggestions

### Time Blocking Suggestions

**Command**: `gtd-calendar-info suggest-blocks --date today`

**Output**:
```
💡 Time Blocking Suggestions for Today

Available blocks:
  • 12:00 PM - 2:00 PM (2 hours) - Good for deep work
  • 3:00 PM - 5:00 PM (2 hours) - Good for focused tasks
  
Recommended tasks:
  • Review quarterly report (needs 1 hour, fits in 12:00-2:00 PM)
  • Write blog post (needs 2 hours, fits in 3:00-5:00 PM)
```

### Conflict Detection

**Command**: `gtd-calendar-info conflicts --task "Review report" --time "2024-12-02 10:00" --duration 60`

**Output**:
```
⚠️  Conflict detected:
   Task: Review report
   Proposed time: 10:00 AM - 11:00 AM
   
   Conflicts with:
   • Team Standup (9:00 AM - 10:00 AM) - Overlaps by 0 minutes
   
   Suggested alternatives:
   • 12:00 PM - 1:00 PM (2 hours after meeting)
   • 3:00 PM - 4:00 PM (3 hours after meeting)
```

## 🔌 GTD Integration

### Morning Check-In Enhancement

Add calendar overview to `gtd-checkin morning`:

```bash
# In gtd-checkin morning
echo ""
echo "📅 Today's Calendar:"
gtd-calendar-info overview --date today --brief
echo ""
```

### Daily Review Enhancement

Add calendar context to `gtd-review daily`:

```bash
# In gtd-review daily morning
echo ""
echo "📅 Calendar Context:"
gtd-calendar-info today --summary
echo ""
```

### Task Scheduling Integration

When scheduling tasks, check calendar:

```bash
# In task scheduling
gtd-calendar-info conflicts --task "$task_title" --time "$proposed_time" --duration "$duration"
```

## 📁 File Structure

```
~/.gtd/calendar/
├── cache.json              # Cached calendar events
├── reminders_sent.json     # Tracking of sent reminders
└── config.json             # Calendar-specific config (optional)

bin/
├── gtd-calendar-fetch       # Fetch events from gcalcli
├── gtd-calendar-info        # Main calendar information interface
└── gtd-calendar-reminders   # Reminder checking and display
```

## ⚙️ Configuration

### Environment Variables

```bash
# Cache settings
GTD_CALENDAR_CACHE_TTL_MINUTES=15

# Reminder settings
GTD_CALENDAR_REMINDER_TIMES="60,15"  # 1 hour and 15 minutes before

# Display settings
GTD_CALENDAR_SHOW_LOCATION=true
GTD_CALENDAR_SHOW_ATTENDEES=true
GTD_CALENDAR_SHOW_DESCRIPTION=true
```

### Calendar Config

Uses existing `~/.gtd_config_calendar`:
- `GTD_CALENDARS` array for multiple calendars
- Calendar names and display names
- Read-write permissions

## 🚀 Implementation Plan

1. **Phase 1: Data Fetching & Caching**
   - Create `gtd-calendar-fetch` script
   - Implement JSON cache with TTL
   - Parse `gcalcli` output

2. **Phase 2: Information Display**
   - Create `gtd-calendar-info` script
   - Implement daily overview
   - Format events nicely

3. **Phase 3: Reminders**
   - Create `gtd-calendar-reminders` script
   - Implement reminder checking
   - Track sent reminders

4. **Phase 4: GTD Integration**
   - Integrate with morning check-in
   - Integrate with daily review
   - Add proactive suggestions

5. **Phase 5: Advanced Features**
   - Time blocking suggestions
   - Conflict detection
   - Background reminder process

## 🔍 Example Usage

```bash
# Fetch and cache calendar data
gtd-calendar-fetch

# View today's calendar overview
gtd-calendar-info overview --date today

# Check for upcoming meeting reminders
gtd-calendar-reminders check

# Get time blocking suggestions
gtd-calendar-info suggest-blocks --date today

# Check for conflicts when scheduling a task
gtd-calendar-info conflicts --task "Review report" --time "2024-12-02 10:00" --duration 60
```

## 📝 Notes

- All scripts must be bash 3.2 compatible (macOS default)
- Use existing `gtd-common.sh` helpers
- Follow existing GTD script patterns
- Integrate with existing calendar config system
- Support multiple calendars (Google + Outlook)
- Handle authentication errors gracefully
