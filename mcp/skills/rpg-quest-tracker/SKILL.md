---
name: RPG Quest Tracker
description: Track your daily, weekly, and monthly quests with real-time progress! See exactly what you need to do to complete quests and earn bonus XP. Get quest recommendations based on your current activity.
version: 1.0.0
tags:
  - gamification
  - rpg
  - quests
  - tracking
  - progress
  - daily
  - weekly
  - monthly
author: GTD System
tool:
  type: object
  properties:
    action:
      type: string
      enum: [view, daily, weekly, monthly, progress, recommendations, full]
      description: Action to perform - view (all quests), daily (daily quests only), weekly (weekly quests only), monthly (monthly quests only), progress (detailed progress), recommendations (quest suggestions), full (complete quest dashboard)
    quest_id:
      type: string
      description: Specific quest ID to view details for (optional)
  required: []
---

# RPG Quest Tracker

Track your productivity quests with real-time progress! See exactly what you need to do to complete daily, weekly, and monthly quests, earn bonus XP, and get personalized quest recommendations.

## When to Use

Use this skill when you want to:
- **Check quest progress** - See how close you are to completing quests
- **Get quest recommendations** - Find out which quests you can complete today
- **Track daily quests** - See what you need to do today
- **Plan weekly quests** - See what to focus on this week
- **Review monthly goals** - Check progress on monthly quests
- **Earn bonus XP** - Complete quests for extra rewards

## How It Works

Quests are challenges that give bonus XP when completed. The quest tracker:
- **Monitors progress** in real-time using MCP tools
- **Shows completion status** with progress bars
- **Recommends quests** based on your current activity
- **Tracks quest history** for analytics
- **Celebrates completion** when you finish quests

### Quest Types

#### Daily Quests
Reset every day at midnight. Quick wins for daily motivation.

**Available Daily Quests:**
- **Complete 3 Tasks** → +30 XP
- **Complete All Daily Habits** → +25 XP
- **Log to Daily Log** → +5 XP
- **Exercise for 30+ Minutes** → +40 XP
- **Process Inbox** → +15 XP (if inbox had items)
- **Complete High-Priority Task** → +20 XP

#### Weekly Quests
Reset every Monday. Medium-term goals for the week.

**Available Weekly Quests:**
- **Complete Weekly Review** → +50 XP
- **Complete 20 Tasks** → +100 XP
- **Maintain 7-Day Habit Streak** → +75 XP
- **Complete 1 Project** → +150 XP
- **Log Daily Log 7 Days** → +50 XP
- **Complete 5 High-Priority Tasks** → +80 XP

#### Monthly Quests
Reset on the 1st of each month. Long-term goals for the month.

**Available Monthly Quests:**
- **Complete Monthly Review** → +100 XP
- **Complete 100 Tasks** → +500 XP
- **Complete a Major Project** → +300 XP
- **Maintain 30-Day Habit Streak** → +200 XP
- **Complete 10 Projects** → +400 XP
- **Log Daily Log 30 Days** → +250 XP

### Quest Rarity

Quests have different rarities affecting rewards:
- **Common** (Gray): Standard quests, normal rewards
- **Uncommon** (Green): Slightly harder, +25% rewards
- **Rare** (Blue): Challenging, +50% rewards
- **Epic** (Purple): Very challenging, +100% rewards
- **Legendary** (Gold): Extremely challenging, +200% rewards

## Usage

### View All Quests

**Action:** `action="view"` or `action="full"`

**What it shows:**
- All active quests (daily, weekly, monthly)
- Progress bars for each quest
- Completion status (✓ or progress)
- XP rewards
- Time remaining

**MCP Tools to use:**
1. `list_tasks(status="completed", days=1)` - Daily task quest progress
2. `read_daily_log(date="today")` - Daily log quest progress
3. `list_tasks(status="completed", days=7)` - Weekly task quest progress
4. Habit system queries - Habit quest progress
5. Review system queries - Review quest progress

**Display format:**
```
╔════════════════════════════════════════════════════════════╗
║              📋 QUEST TRACKER 📋                          ║
╠════════════════════════════════════════════════════════════╣
║ DAILY QUESTS (Resets in 14h 23m)                          ║
╠════════════════════════════════════════════════════════════╣
║ ✅ Complete 3 Tasks                    [████████░░] 2/3  ║
║    +30 XP | Complete 1 more task!                        ║
║                                                           ║
║ ✅ Log to Daily Log                     [██████████] ✓   ║
║    +5 XP | Completed!                                     ║
║                                                           ║
║ ⏳ Complete All Daily Habits            [█████░░░░░] 3/5  ║
║    +25 XP | 2 habits remaining                           ║
╠════════════════════════════════════════════════════════════╣
║ WEEKLY QUESTS (Resets in 3d 14h)                         ║
╠════════════════════════════════════════════════════════════╣
║ ⏳ Complete 20 Tasks                   [████████░░] 12/20 ║
║    +100 XP | 8 tasks remaining                            ║
║                                                           ║
║ ⏳ Complete Weekly Review                [░░░░░░░░░░] 0/1  ║
║    +50 XP | Not started                                   ║
╠════════════════════════════════════════════════════════════╣
║ MONTHLY QUESTS (Resets in 12d)                            ║
╠════════════════════════════════════════════════════════════╣
║ ⏳ Complete 100 Tasks                  [████░░░░░░] 45/100 ║
║    +500 XP | 55 tasks remaining                           ║
╚════════════════════════════════════════════════════════════╝
```

### View Daily Quests Only

**Action:** `action="daily"`

**What it shows:**
- Only daily quests
- Detailed progress for each
- Recommendations for completion
- Time until reset

### View Weekly Quests Only

**Action:** `action="weekly"`

**What it shows:**
- Only weekly quests
- Progress for the week
- Days remaining
- Weekly recommendations

### View Monthly Quests Only

**Action:** `action="monthly"`

**What it shows:**
- Only monthly quests
- Progress for the month
- Days remaining
- Monthly recommendations

### Get Quest Recommendations

**Action:** `action="recommendations"`

**What it shows:**
- Quests you're closest to completing
- Quests you can complete today
- Quests that match your current activity
- Priority order (easiest to hardest)

**Logic:**
1. Calculate completion percentage for each quest
2. Filter quests that are >50% complete
3. Filter quests that can be completed today
4. Sort by completion percentage (highest first)
5. Show top 5-10 recommendations

### View Detailed Quest Progress

**Action:** `action="progress"` with `quest_id="<id>"`

**What it shows:**
- Detailed breakdown of quest requirements
- Current progress vs. required
- What you need to do to complete
- Estimated time to complete
- Related quests

## Step-by-Step Workflow

### To Track Quest Progress

1. **Load Quest Definitions**
   - Define all available quests with requirements
   - Store quest metadata (name, description, XP reward, requirements)

2. **Query Current Activity**
   - **Daily tasks**: `list_tasks(status="completed", days=1)`
   - **Daily log**: `read_daily_log(date="today")`
   - **Habits**: Query habit system for today's completions
   - **Weekly tasks**: `list_tasks(status="completed", days=7)`
   - **Reviews**: Query review system for completion status
   - **Projects**: Query project system for completions

3. **Calculate Progress**
   - Compare current activity against quest requirements
   - Calculate completion percentage
   - Determine completion status (not started, in progress, complete)

4. **Display Quests**
   - Group by type (daily, weekly, monthly)
   - Show progress bars
   - Show completion status
   - Show XP rewards
   - Show time until reset

### To Get Recommendations

1. **Calculate Completion Percentages**
   - For each quest, calculate: `(current / required) * 100`

2. **Filter Quests**
   - Quests >50% complete (close to completion)
   - Quests that can be completed today (based on requirements)
   - Active quests only (not expired)

3. **Sort and Rank**
   - Sort by completion percentage (highest first)
   - Prioritize daily quests (time-sensitive)
   - Consider quest difficulty

4. **Display Recommendations**
   - Show top 5-10 quests
   - Explain why each is recommended
   - Show what you need to do to complete

## Quest Definitions

### Daily Quest Definitions

```python
DAILY_QUESTS = [
    {
        "id": "daily_3_tasks",
        "name": "Complete 3 Tasks",
        "description": "Complete 3 tasks today",
        "type": "daily",
        "rarity": "common",
        "xp_reward": 30,
        "requirements": {
            "tasks_completed_today": 3
        }
    },
    {
        "id": "daily_log_entry",
        "name": "Log to Daily Log",
        "description": "Make at least one daily log entry",
        "type": "daily",
        "rarity": "common",
        "xp_reward": 5,
        "requirements": {
            "daily_log_entries_today": 1
        }
    },
    {
        "id": "daily_all_habits",
        "name": "Complete All Daily Habits",
        "description": "Complete all your daily habits",
        "type": "daily",
        "rarity": "uncommon",
        "xp_reward": 25,
        "requirements": {
            "daily_habits_completed": "all"
        }
    },
    {
        "id": "daily_exercise",
        "name": "Exercise for 30+ Minutes",
        "description": "Exercise for at least 30 minutes",
        "type": "daily",
        "rarity": "uncommon",
        "xp_reward": 40,
        "requirements": {
            "exercise_minutes_today": 30
        }
    }
]
```

### Weekly Quest Definitions

```python
WEEKLY_QUESTS = [
    {
        "id": "weekly_review",
        "name": "Complete Weekly Review",
        "description": "Complete your weekly review",
        "type": "weekly",
        "rarity": "rare",
        "xp_reward": 50,
        "requirements": {
            "weekly_review_completed": True
        }
    },
    {
        "id": "weekly_20_tasks",
        "name": "Complete 20 Tasks",
        "description": "Complete 20 tasks this week",
        "type": "weekly",
        "rarity": "uncommon",
        "xp_reward": 100,
        "requirements": {
            "tasks_completed_this_week": 20
        }
    },
    {
        "id": "weekly_habit_streak",
        "name": "Maintain 7-Day Habit Streak",
        "description": "Maintain a 7-day habit streak",
        "type": "weekly",
        "rarity": "rare",
        "xp_reward": 75,
        "requirements": {
            "habit_streak": 7
        }
    }
]
```

### Monthly Quest Definitions

```python
MONTHLY_QUESTS = [
    {
        "id": "monthly_review",
        "name": "Complete Monthly Review",
        "description": "Complete your monthly review",
        "type": "monthly",
        "rarity": "epic",
        "xp_reward": 100,
        "requirements": {
            "monthly_review_completed": True
        }
    },
    {
        "id": "monthly_100_tasks",
        "name": "Complete 100 Tasks",
        "description": "Complete 100 tasks this month",
        "type": "monthly",
        "rarity": "rare",
        "xp_reward": 500,
        "requirements": {
            "tasks_completed_this_month": 100
        }
    },
    {
        "id": "monthly_major_project",
        "name": "Complete a Major Project",
        "description": "Complete a major project this month",
        "type": "monthly",
        "rarity": "epic",
        "xp_reward": 300,
        "requirements": {
            "major_project_completed_this_month": True
        }
    }
]
```

## Integration with MCP Tools

This skill uses these MCP tools:

- `list_tasks(status="completed", days=N)` - Get completed tasks for time period
- `read_daily_log(date="today")` - Check daily log entries
- `get_inbox_count()` - Check inbox processing quest
- Habit system - Query habit completions
- Review system - Query review completion status
- Project system - Query project completions
- Exercise/health system - Query exercise data

## Best Practices

### Daily Quest Strategy

- **Focus on easy wins**: Complete daily log quest first (+5 XP, quick!)
- **Build momentum**: Complete 3 tasks quest early in the day
- **Maintain consistency**: Complete all daily habits for bonus XP
- **Check progress**: Review quest status in morning and evening

### Weekly Quest Strategy

- **Plan ahead**: Check weekly quests on Monday
- **Track progress**: Monitor throughout the week
- **Prioritize**: Focus on high-XP quests (weekly review, 20 tasks)
- **Don't forget**: Weekly review quest is critical!

### Monthly Quest Strategy

- **Set monthly goals**: Review monthly quests on 1st of month
- **Track consistently**: Check progress weekly
- **Adjust if needed**: Some quests may need adjustment
- **Celebrate completion**: Monthly quests give big XP!

## Example Interactions

### "Show me my quests"
→ Displays: All active quests with progress

### "What quests can I complete today?"
→ Displays: Recommendations for today's completable quests

### "Show me daily quests"
→ Displays: Only daily quests with progress

### "How close am I to completing the weekly review quest?"
→ Displays: Detailed progress for weekly review quest

### "What's my quest progress?"
→ Displays: Complete quest dashboard with all quests

## Future Enhancements

### Quest Chains
- Complete one quest to unlock the next
- Story-based quest chains
- Themed quest chains (e.g., "Productivity Master" chain)

### Special Event Quests
- Holiday quests
- Milestone quests (level up, achievement unlock)
- Limited-time quests

### Quest Sharing
- Share quest progress (optional)
- Quest leaderboards (optional)
- Quest challenges with others

### Quest Analytics
- Quest completion rate
- Average time to complete
- Most/least completed quests
- Quest difficulty analysis

## Troubleshooting

### "Quest progress not updating"
- Verify MCP tools are working correctly
- Check that activities are being tracked
- Ensure quest definitions match activity types

### "Quest shows as incomplete when it should be complete"
- Check quest requirements match actual activity
- Verify time period (daily = today, weekly = this week, etc.)
- Check for timezone issues

### "Can't see quest recommendations"
- Ensure you have some activity tracked
- Check that quest definitions are loaded
- Verify gamification data is available

## Success Metrics

A successful quest tracking session means:
- ✓ You can see all active quests with accurate progress
- ✓ You understand what you need to do to complete quests
- ✓ You get useful recommendations for today
- ✓ Quest progress updates in real-time
- ✓ You're motivated to complete quests for bonus XP

Remember: Quests are meant to guide and motivate, not stress you out. Complete what you can, and celebrate your progress! 🎮✨
