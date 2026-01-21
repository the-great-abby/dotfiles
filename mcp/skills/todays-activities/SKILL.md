---
name: Today's Activities
description: Quick overview of today's calendar events, meetings, and scheduled activities. Helps you see what's on your schedule for the day.
version: 1.0.0
tags:
  - calendar
  - daily
  - activities
  - schedule
  - meetings
author: GTD System
---

# Today's Activities Workflow

A focused skill for quickly reviewing your calendar and scheduled activities for today (or any specified date).

## When to Use

Use this skill when you want to:
- **Quick calendar check**: See what's scheduled for today
- **Plan your day**: Understand your time commitments before planning tasks
- **Check specific date**: Review calendar for tomorrow or any date
- **Meeting preparation**: See what meetings are coming up and what preparation might be needed
- **Time blocking**: Identify free time blocks for focused work

## How It Works

This workflow uses the `gtd_get_calendar_overview` tool to fetch and display your calendar information.

## Step-by-Step Workflow

### Step 1: Get Calendar Overview

**Purpose:** Retrieve today's calendar events and activities.

**Actions:**
1. Call `gtd_get_calendar_overview(date="today")` to get today's calendar
   - For a different date, use `date="tomorrow"` or `date="YYYY-MM-DD"` format
   - For a quick summary, use `brief=true`
2. Review the calendar overview returned

**What the overview includes:**
- All events scheduled for the specified date
- Event times and durations
- Event titles and descriptions
- Locations (if available)
- Calendar source (work, personal, etc.)
- Summary statistics (total events, busy time, free time)

---

### Step 2: Analyze Your Schedule

**Purpose:** Understand what your day looks like and identify key information.

**Actions:**
1. Review the events returned:
   - **Meeting times**: When are you busy?
   - **Free blocks**: When do you have time for focused work?
   - **Preparation needed**: Any meetings requiring advance preparation?
   - **Travel time**: Any events that require travel between locations?
   - **Back-to-back meetings**: Any scheduling conflicts or tight transitions?

2. Identify key patterns:
   - Busy periods (multiple meetings)
   - Free periods (good for deep work)
   - Transition times (between meetings)
   - End of day commitments

---

### Step 3: Provide Summary and Insights

**Purpose:** Give the user a clear picture of their day.

**Actions:**
1. Summarize the day's schedule:
   - Total number of events
   - Busy time vs. free time
   - Next upcoming event
   - Key meetings or commitments

2. Provide insights:
   - Best times for focused work (free blocks)
   - Preparation needed for upcoming meetings
   - Any scheduling concerns (back-to-back, conflicts)
   - Recommendations for task planning

---

## Usage Examples

### Quick Check (Brief Mode)

**User:** "What's on my calendar today?"

**Workflow:**
1. Call `gtd_get_calendar_overview(date="today", brief=true)`
2. Provide a concise summary of events

### Detailed Review

**User:** "Show me everything on my calendar for tomorrow"

**Workflow:**
1. Call `gtd_get_calendar_overview(date="tomorrow")`
2. Review all events in detail
3. Provide comprehensive overview with insights

### Planning Integration

**User:** "I need to plan my day - what's on my calendar?"

**Workflow:**
1. Call `gtd_get_calendar_overview(date="today")`
2. Analyze free time blocks
3. Suggest when to schedule different types of tasks
4. Identify preparation time needed for meetings

---

## Best Practices

### When to Use Brief Mode

Use `brief=true` when:
- User just wants a quick check
- You're providing a summary in a larger workflow
- Calendar has many events and you want a condensed view

### When to Use Full Mode

Use full mode (default) when:
- User wants detailed information
- Planning tasks around calendar
- Need to see locations, descriptions, attendees
- Preparing for specific meetings

### Error Handling

If calendar is not authenticated:
- Inform the user that calendar access requires authentication
- Suggest running `gcalcli init` or using `gtd-calendar` menu to authenticate
- Continue gracefully - don't block the workflow

If no events found:
- Confirm the date is correct
- Note that the day appears free
- Suggest this is good for focused work or catching up

---

## Integration with Other Skills

This skill works well with:
- **`morning-checkin`**: Calendar check is already integrated (Step 3)
- **`task-prioritization`**: Use calendar to inform task scheduling
- **`daily-review`**: Review how calendar affected your day
- **`energy-audit-planning`**: Schedule tasks based on energy levels and calendar

---

## Workflow Summary

```
Today's Activities Workflow
│
├─ 1. Get Calendar Overview (gtd_get_calendar_overview)
│   ├─ Specify date (today, tomorrow, or YYYY-MM-DD)
│   └─ Optionally use brief mode for quick summary
│
├─ 2. Analyze Schedule
│   ├─ Review meeting times and durations
│   ├─ Identify free time blocks
│   ├─ Note preparation needs
│   └─ Check for conflicts or tight transitions
│
└─ 3. Provide Summary and Insights
    ├─ Summarize day's schedule
    ├─ Highlight key meetings
    ├─ Suggest best times for focused work
    └─ Provide task planning recommendations
```

---

## Common Variations

### Quick Calendar Check
**Duration:** 30 seconds
1. Call `gtd_get_calendar_overview(date="today", brief=true)`
2. Provide one-sentence summary

### Detailed Day Planning
**Duration:** 2-3 minutes
1. Get full calendar overview
2. Analyze time blocks
3. Provide specific recommendations for task scheduling
4. Identify preparation time needed

### Multi-Day Review
**Duration:** 5 minutes
1. Check today's calendar
2. Check tomorrow's calendar
3. Check next few days
4. Provide overview of upcoming week

---

## Troubleshooting

### "Calendar not authenticated"
- **Solution**: Guide user to authenticate via `gcalcli init` or `gtd-calendar` menu
- **Workaround**: Continue without calendar, note that calendar integration would be helpful

### "No events found"
- **Check**: Verify the date is correct
- **Response**: Confirm day is free, suggest it's good for focused work

### "Calendar fetch failed"
- **Check**: Verify `gtd-calendar-info` script is available
- **Response**: Note calendar is temporarily unavailable, suggest manual check

---

## Success Metrics

A successful today's activities check means:
- ✓ User knows what's scheduled for the day
- ✓ Free time blocks are identified
- ✓ Key meetings are highlighted
- ✓ Preparation needs are noted (if any)
- ✓ User has clear picture of their schedule

Remember: The goal is clarity about your time commitments, not perfection in scheduling.
