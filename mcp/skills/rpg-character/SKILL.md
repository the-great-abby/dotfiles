---
name: RPG Character System
description: Transform your GTD productivity into an RPG adventure! View your character stats, level, XP, quests, achievements, and progress in a fun, game-like interface.
version: 1.0.0
tags:
  - gamification
  - rpg
  - fun
  - motivation
  - character
  - stats
  - quests
author: GTD System
tool:
  type: object
  properties:
    action:
      type: string
      enum: [stats, quests, levelup, achievements, character, full]
      description: What to display - stats (character stats), quests (active quests), levelup (level up guide), achievements (unlocked achievements), character (full character sheet), or full (everything)
  required: []
---

# RPG Character System

Transform your GTD productivity journey into an epic RPG adventure! This skill provides a fun, immersive way to view your progress, level, XP, quests, and achievements.

## When to Use

Use this skill when you want to:
- **Check your character stats** - See your level, XP, HP (energy), and attributes
- **View active quests** - See what daily/weekly/monthly quests are available
- **Track achievements** - Review unlocked badges and achievements
- **Get motivation** - See your progress in a fun, game-like format
- **Plan leveling** - Understand how to gain XP and level up
- **Celebrate progress** - View your character's growth over time

## How It Works

This skill integrates with the existing gamification system (`gtd-gamify`) to present your productivity data in an RPG format. It uses MCP tools to gather data and presents it as a character sheet.

### Character Stats Overview

Your character has these core attributes:

- **Level**: Your overall progress level (based on total XP)
- **XP (Experience Points)**: Earned from completing tasks, habits, projects, reviews
- **HP (Health Points)**: Represents your energy/stamina (based on streaks and consistency)
- **MP (Mana Points)**: Represents your focus/mental energy (based on review completion)
- **Strength**: Task completion power (based on tasks completed)
- **Wisdom**: Review and reflection power (based on reviews completed)
- **Dexterity**: Habit consistency (based on habit streaks)
- **Constitution**: Overall system health (based on daily logging consistency)

### Quest System

Quests are challenges that give bonus XP when completed:

**Daily Quests:**
- Complete 3 tasks → +30 XP
- Complete all daily habits → +25 XP
- Log to daily log → +5 XP
- Exercise for 30+ minutes → +40 XP

**Weekly Quests:**
- Complete weekly review → +50 XP
- Complete 20 tasks → +100 XP
- Maintain 7-day habit streak → +75 XP

**Monthly Quests:**
- Complete monthly review → +100 XP
- Complete 100 tasks → +500 XP
- Complete a major project → +300 XP

### Achievement System (Badges)

Achievements are permanent unlocks that show your mastery:

- **Task Achievements**: Complete 10/50/100/500/1000 tasks
- **Habit Achievements**: 7/30/100/365 day streaks
- **Project Achievements**: Complete 5/10/25/50 projects
- **Review Achievements**: 7/30/100 consecutive reviews
- **Health Achievements**: Exercise streaks, health logging streaks
- **Special Achievements**: Unlockable through unique combinations

## Usage

### View Full Character Sheet

**Action:** `action="full"` or `action="character"`

**What it shows:**
- Character stats (Level, XP, HP, MP, Attributes)
- Active quests (Daily/Weekly/Monthly)
- Recent achievements unlocked
- Progress bars for next level
- Streak information
- Badge status

**MCP Tools to use:**
1. Call `read_daily_log(date="today")` to get today's activity
2. Use gamification system to get stats (via `gtd-gamify` or direct file access)
3. Call `list_tasks(status="active")` to see current quest opportunities
4. Call `get_pending_suggestions()` to see if there are quest-related suggestions

**Display format:**
```
╔════════════════════════════════════════════════╗
║         🎮 YOUR RPG CHARACTER SHEET 🎮        ║
╠════════════════════════════════════════════════╣
║ Level: 12  |  XP: 2,450 / 2,880 (Next Level)  ║
║ HP: ████████░░ 80%  |  MP: ██████░░░░ 60%     ║
╠════════════════════════════════════════════════╣
║ ATTRIBUTES:                                    ║
║   💪 Strength: 15 (Tasks completed)            ║
║   🧠 Wisdom: 12 (Reviews completed)            ║
║   ⚡ Dexterity: 18 (Habit streaks)             ║
║   ❤️  Constitution: 20 (Daily logging)          ║
╠════════════════════════════════════════════════╣
║ ACTIVE QUESTS:                                 ║
║   📋 Daily: Complete 3 tasks (1/3)              ║
║   📋 Daily: Log to daily log (✓)               ║
║   📅 Weekly: Complete 20 tasks (12/20)         ║
╠════════════════════════════════════════════════╣
║ RECENT ACHIEVEMENTS:                           ║
║   🎖️ Task Warrior (7-day task streak)          ║
║   🎖️ Daily Logger (7-day logging streak)      ║
╚════════════════════════════════════════════════╝
```

### View Stats Only

**Action:** `action="stats"`

**What it shows:**
- Current level and XP
- Progress to next level
- Core stats (HP, MP, Attributes)
- Streak information

### View Active Quests

**Action:** `action="quests"`

**What it shows:**
- All available daily quests with progress
- Weekly quests with progress
- Monthly quests with progress
- XP rewards for each quest
- Completion status

**How to determine quest progress:**
1. Call `list_tasks(status="completed", days=1)` for daily task quest
2. Call `read_daily_log(date="today")` for daily log quest
3. Call `list_tasks(status="completed", days=7)` for weekly task quest
4. Check habit completion via habit system
5. Check review completion via review system

### View Achievements

**Action:** `action="achievements"`

**What it shows:**
- All unlocked badges/achievements
- Progress toward next achievements
- Lost badges (if any) and how to recover them
- Achievement categories (Tasks, Habits, Projects, Reviews, Health, Special)

### Level Up Guide

**Action:** `action="levelup"`

**What it shows:**
- Current XP and level
- XP needed for next level
- Ways to earn XP (with amounts)
- Recommended activities to level up
- Progress tracking

**XP Sources:**
- Complete task: 10-50 XP (based on priority/complexity)
- Complete habit: 15 XP (daily), 25 XP (weekly), 50 XP (monthly)
- Complete project: 100-500 XP (based on size)
- Daily log entry: 5 XP
- Weekly review: 50 XP
- Monthly review: 100 XP
- Exercise/workout: 20-40 XP
- Health metric logged: 5 XP
- Badge earned: 50-500 XP (varies by badge)

## Step-by-Step Workflow

### To Display Full Character Sheet

1. **Gather Character Data**
   - Read gamification data file (or call `gtd-gamify` to get stats)
   - Extract: level, total_xp, current_xp, stats, streaks, badges

2. **Calculate Attributes**
   - **Strength**: Based on `stats.tasks_completed` (scale: 1 task = 0.1 strength)
   - **Wisdom**: Based on `stats.reviews_completed` (scale: 1 review = 0.5 wisdom)
   - **Dexterity**: Based on `streaks.task_completion` and `streaks.habits` (scale: 1 day streak = 0.2 dexterity)
   - **Constitution**: Based on `streaks.daily_logging` (scale: 1 day streak = 0.1 constitution)

3. **Calculate HP and MP**
   - **HP**: Based on consistency (streaks) - `(daily_logging_streak + task_streak) / 2 * 10` (max 100)
   - **MP**: Based on review completion - `(reviews_completed / total_possible_reviews) * 100` (max 100)

4. **Determine Active Quests**
   - Check today's task completion: `list_tasks(status="completed", days=1)`
   - Check today's log entry: `read_daily_log(date="today")`
   - Check habit completion: Query habit system
   - Check weekly/monthly progress: Aggregate from stats

5. **Get Recent Achievements**
   - Read `badges` from gamification data
   - Filter for recently earned (within last 7 days)
   - Show badge name, description, XP bonus

6. **Format and Display**
   - Create character sheet with all information
   - Use visual elements (progress bars, emojis, borders)
   - Make it engaging and fun!

### To Show Quest Progress

1. **Get Quest Definitions**
   - Daily quests: Task completion, log entry, habits, exercise
   - Weekly quests: Review completion, task count, streak maintenance
   - Monthly quests: Review completion, task count, project completion

2. **Check Progress for Each Quest**
   - Query relevant MCP tools to get current counts
   - Compare against quest requirements
   - Calculate completion percentage

3. **Display Quest List**
   - Show quest name and description
   - Show progress (e.g., "3/5 tasks completed")
   - Show XP reward
   - Show completion status (✓ or progress bar)

## Integration with MCP Tools

This skill uses these MCP tools:

- `read_daily_log(date="today")` - Check daily log quest completion
- `list_tasks(status="completed", days=N)` - Check task quest progress
- `list_tasks(status="active")` - See available tasks for quests
- `get_inbox_count()` - Context for daily activity
- `read_recent_logs(days=7)` - Context for weekly progress
- Gamification system (`gtd-gamify`) - Get all stats, XP, level, badges

## Best Practices

### When to Check Your Character

- **Daily**: Check stats in the morning to see quests for the day
- **After completing tasks**: See XP gains and level progress
- **Weekly**: Review full character sheet to see overall progress
- **After reviews**: Check for achievement unlocks

### Using Quests for Motivation

- Focus on daily quests for immediate motivation
- Use weekly quests for medium-term goals
- Use monthly quests for long-term planning
- Celebrate quest completion with XP gains!

### Leveling Up Strategy

- **Quick XP**: Daily log entries (5 XP each, easy!)
- **Medium XP**: Complete tasks (10-50 XP each)
- **High XP**: Complete projects (100-500 XP)
- **Bonus XP**: Complete reviews (50-100 XP)
- **Mega XP**: Unlock achievements (50-500 XP)

### Maintaining Your Character

- **Keep HP high**: Maintain daily logging and task streaks
- **Keep MP high**: Complete regular reviews
- **Build attributes**: Consistent activity across all areas
- **Recover lost badges**: Build streaks to regain achievements

## Example Interactions

### "Show me my character stats"
→ Displays: Level, XP, HP, MP, Attributes, Streaks

### "What quests do I have?"
→ Displays: All active quests with progress and XP rewards

### "How do I level up?"
→ Displays: Current level, XP needed, ways to earn XP, recommendations

### "Show me my achievements"
→ Displays: All unlocked badges, progress toward next achievements

### "Show me my full character sheet"
→ Displays: Complete RPG character sheet with all information

## Fun Features

### Character Classes (Future Enhancement)

Based on your activity patterns, you could be:
- **Warrior**: High task completion, strong in execution
- **Mage**: High review completion, strong in reflection
- **Rogue**: High habit consistency, strong in routines
- **Paladin**: Balanced across all areas, well-rounded

### Prestige System

At high levels (25+), you can "prestige" - reset your level but gain permanent bonuses and special titles.

### Equipment System (Future Enhancement)

Complete quests to unlock "equipment" that provides bonuses:
- **Productivity Sword**: +10% XP from tasks
- **Wisdom Robe**: +10% XP from reviews
- **Stamina Boots**: +5 HP per day
- **Focus Ring**: +5 MP per day

## Troubleshooting

### "My stats aren't updating"
- Make sure you're completing tasks and logging activities
- Check that `gtd-gamify` is tracking your activity
- Verify gamification data file is being updated

### "I'm not leveling up"
- Check your XP sources (tasks, habits, reviews)
- Complete more activities to earn XP
- Focus on quests for bonus XP

### "My HP/MP is low"
- HP: Build streaks (daily logging, task completion)
- MP: Complete more reviews (daily, weekly, monthly)
- Consistency is key!

## Success Metrics

A successful RPG character session means:
- ✓ You can see your current level and progress
- ✓ You understand how to earn XP and level up
- ✓ You know what quests are available
- ✓ You're motivated to complete activities
- ✓ You can track your achievements and badges

Remember: The goal is to make productivity fun and engaging while maintaining the serious benefits of the GTD system!
