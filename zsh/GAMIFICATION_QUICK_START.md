# 🎮 Gamification Quick Start Guide

## 🚀 Getting Started

Your GTD system now has comprehensive gamification! Here's how to use it:

### 1. Via the Wizard (Easiest!)

```bash
gtd-wizard
# Then choose option 28: 🎮 Gamification & Habitica
```

The wizard provides an interactive menu for:
- Viewing your gamification dashboard
- Checking achievements
- Viewing streaks and statistics
- Awarding XP manually
- Setting up Habitica integration

### 2. Direct Commands

```bash
gtd-gamify dashboard
```

This shows:
- Your current level and XP
- All your streaks (logging, tasks, reviews, exercise)
- Statistics (tasks completed, habits, projects, etc.)
- Achievements unlocked

### 2. How XP Works

XP is automatically awarded when you:
- ✅ Complete a task → 10-50 XP (based on priority/complexity)
- ✅ Complete a habit → 15-50 XP (based on frequency)
- ✅ Complete a project → 100-500 XP (based on size)
- ✅ Log daily entry → 5 XP
- ✅ Complete review → 50-100 XP
- ✅ Exercise/workout → 20-40 XP

### 3. Leveling Up

- **Levels 1-10**: 100 XP per level (Level 2 = 100 XP, Level 3 = 200 XP, etc.)
- **Level 10+**: Exponential scaling (Level 10 = 1000 XP, Level 11 = 1200 XP, etc.)
- **Level Up**: Automatic celebration when you level up!

### 4. Streaks

Track streaks for:
- **Daily Logging**: Consecutive days with log entries
- **Task Completion**: Consecutive days with at least 1 task completed
- **Reviews**: Consecutive days with reviews completed
- **Exercise**: Consecutive days with exercise logged

Streaks are automatically updated when you complete activities!

### 5. Achievements

Achievements unlock automatically when you reach milestones:
- **Task Achievements**: First task, 10 tasks, 50 tasks, 100 tasks, 500 tasks, 1000 tasks
- **Habit Achievements**: First habit, 100 habits, 500 habits
- **Project Achievements**: First project, 5 projects, 10 projects, 25 projects
- **Review Achievements**: First review, 7 reviews, 30 reviews
- **Streak Achievements**: 3-day, 7-day, 30-day, 100-day, 365-day streaks
- **Level Achievements**: Level 5, 10, 25, 50
- **Exercise Achievements**: First exercise, 10 exercises, 50 exercises

### 6. Integration with Existing Commands

Gamification is **automatic**! Just use your existing GTD commands:
- `gtd-task complete` → Awards XP automatically
- `gtd-habit log` → Awards XP and updates streak automatically
- `gtd-project complete` → Awards XP automatically
- `gtd-daily-log` → Awards XP and updates streak automatically
- `gtd-review` → Awards XP and updates streak automatically

## 🎯 Habitica Integration (Optional)

### Setup Habitica

1. **Create Habitica Account**: Sign up at https://habitica.com
2. **Get API Credentials**:
   - Go to Settings → API
   - Copy your User ID and API Token
3. **Configure Integration**:
   ```bash
   gtd-habitica setup
   ```
4. **Sync**:
   ```bash
   gtd-habitica sync        # GTD → Habitica
   gtd-habitica sync-back   # Habitica → GTD
   gtd-habitica status      # Check status
   ```

### What Syncs

- **GTD Tasks** → Habitica To-Dos
- **GTD Habits** → Habitica Habits/Dailies
- **GTD Projects** → Habitica Challenges or grouped To-Dos

## 💡 Tips for Maximum Engagement

1. **Check Dashboard Daily**: See your progress and stay motivated
2. **Maintain Streaks**: Even small actions keep streaks alive
3. **Complete Quests**: Daily/weekly quests give bonus XP
4. **Unlock Achievements**: Work toward milestone achievements
5. **Level Up**: Each level feels like progress!

## 🎉 Example Session

### Via Wizard:
```bash
$ gtd-wizard
# Choose option 28: 🎮 Gamification & Habitica
# Then choose option 1: 📊 View Gamification Dashboard
```

### Direct Command:
```bash
# Check your stats
$ gtd-gamify dashboard

🎮 GTD GAMIFICATION DASHBOARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Level & Progress
   Level 3 | Total XP: 250
   Progress to Level 4: 50/100 (50%)
   XP needed for next level: 50

🔥 Streaks
   Daily Logging: 5 days (Longest: 5)
   Task Completion: 3 days (Longest: 3)
   Reviews: 2 days (Longest: 2)
   Exercise: 1 days (Longest: 1)

📈 Statistics
   Tasks Completed: 12
   Habits Completed: 8
   Projects Completed: 1
   Reviews Completed: 2
   Daily Logs: 5
   Exercise Sessions: 1

🏆 Achievements
   Unlocked: 3/30

# Complete a task
$ gtd-task complete task-123
✓ Task completed!
+25 XP (Completed task)

# Complete a habit
$ gtd-habit log "Morning workout"
✓ Habit logged!
+15 XP (Completed habit: Morning workout)
🔥 Streak: 2 days

# Check achievements
$ gtd-gamify achievements

🏆 ACHIEVEMENT UNLOCKED: Getting Started
   Completed 10 tasks
   +25 XP bonus!
```

## 🔧 Manual Commands

### Via Wizard:
```bash
gtd-wizard
# Option 28 → Option 5: Award XP Manually
# Option 28 → Option 2: Check Achievements
```

### Direct Commands:
```bash
# Award XP manually
gtd-gamify award 50 "Special activity" "exercise"

# Update streak manually
gtd-gamify streak daily_logging

# Check achievements
gtd-gamify achievements
```

## 📚 More Information

- **Full Design**: `zsh/GAMIFICATION_SYSTEM_DESIGN.md`
- **CKA Gamification**: `zsh/CKA_GAMIFICATION_GUIDE.md` (for study-specific gamification)

---

**Start gamifying your productivity today!** 🎮✨

