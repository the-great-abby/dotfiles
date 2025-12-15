# Wizard Process Reminders Enhancement

## Overview

Enhanced the GTD Wizard to show process reminders and frequency recommendations at the top of the main menu. This helps you understand the GTD rhythm and remember how often to visit each section of your system.

## What Was Added

### Process Reminders at Top of Main Menu

When you start the wizard, you now see **process reminders** automatically displayed showing:

- **Daily activities** (multiple times, 1-2 times, as needed)
- **Weekly activities** (once per week)
- **Monthly activities** (once per month)
- **Quarterly/Yearly activities** (strategic planning)
- **As needed/ongoing** activities

Each section shows:
- The menu number
- What it's for
- How often to do it
- Time estimates where applicable

### Example Display

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Quick Reference: How Often to Visit Each Section
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Daily (Multiple times):
  1) Capture to inbox - As needed (whenever something comes to mind)
  15) Log to daily log - Multiple times throughout the day

📅 Daily (1-2 times):
  2) Process inbox - Morning & evening (keep it empty!)
  19) Morning/Evening Check-In - Start & end of day (5-10 min)
  6) Daily review - Morning or evening (5-10 min)

⚡ Daily (As needed):
  3) Manage tasks - When selecting what to work on
  4) Manage projects - When working on active projects
  ...

📆 Weekly (Once):
  6) Weekly review - Sunday morning or Friday afternoon (1-2 hours) ⚠️  CRITICAL
  7) Sync with Second Brain - After weekly review
  25) Goal Tracking & Progress - Weekly goal check-in

[And more...]
```

## Frequency Guide

### Daily - Multiple Times
- **Capture** (1): As needed, whenever something comes to mind
- **Daily Log** (15): Multiple times throughout the day

### Daily - 1-2 Times
- **Process Inbox** (2): Morning & evening (keep it empty!)
- **Morning/Evening Check-In** (19): Start & end of day
- **Daily Review** (6): Morning or evening

### Daily - As Needed
- **Manage Tasks** (3): When selecting what to work on
- **Manage Projects** (4): When working on active projects
- **Search** (16): When looking for something
- **Get Advice** (11): When stuck or need perspective

### Weekly - Once
- **Weekly Review** (6): Sunday morning or Friday afternoon (1-2 hours) ⚠️ CRITICAL
- **Sync Second Brain** (7): After weekly review
- **Goal Tracking** (25): Weekly goal check-in

### Monthly - Once
- **Monthly Review** (6): Last/first weekend (2-3 hours)
- **Review Areas** (5): Monthly area review

### Quarterly/Yearly
- **Quarterly Review** (6): Every 3 months (3-4 hours)
- **Yearly Review** (6): Once per year (4-6 hours)

### As Needed / Ongoing
- **System Status** (17): Check health periodically
- **Manage Habits** (18): Track daily/weekly habits
- **Manage MOCs** (8): When organizing knowledge
- **Express Phase** (9): When creating from notes

## Benefits

1. **Always Know the Rhythm**: See at a glance how often to visit each section
2. **Build Better Habits**: Understand which activities should be daily vs weekly
3. **Don't Forget Critical Items**: Weekly review is marked as CRITICAL
4. **Better Planning**: Know time commitments (5-10 min vs 1-2 hours)
5. **GTD Rhythm**: Understand the natural flow of the GTD system

## Key Reminders

### ⚠️ Most Critical
- **Weekly Review**: Every week, no exceptions (1-2 hours)
- **Process Inbox**: Daily, morning & evening
- **Daily Log**: Multiple times throughout the day

### Important Habits
- **Capture**: As soon as something comes to mind
- **Process**: Don't let inbox pile up
- **Review**: Weekly review is non-negotiable

## Integration with Review Wizard

The review wizard also has its own guide showing:
- Review types available
- Time commitments
- What each review involves

Together, these reminders help you:
1. Understand the GTD rhythm
2. Know what to do when
3. Build consistent habits
4. Never forget critical reviews

## Tips

1. **Read the Reminders**: They're there to help - take a moment to read them
2. **Focus on Critical Items**: Weekly review is marked as CRITICAL for a reason
3. **Build Daily Habits**: Capture and process should become automatic
4. **Plan Reviews**: Block time for weekly/monthly reviews in your calendar
5. **Use as Reference**: The reminders help you understand the system flow

## Technical Details

### Function Added

- `show_process_reminders()`: Displays frequency guide at top of main menu

### Display Logic

- Organized by frequency (daily, weekly, monthly, quarterly/yearly, as needed)
- Color-coded for easy scanning
- Includes menu numbers for quick navigation
- Shows time estimates where helpful

### Always Visible

- Reminders show automatically when you start the wizard
- No need to remember frequencies
- Helps build the GTD rhythm naturally

