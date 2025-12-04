# 🔗 Gamification Integration Guide

## Overview

This guide shows how to integrate gamification into your existing GTD commands. The system is designed to be **non-intrusive** - it enhances your workflow without changing how you use GTD.

## 🎯 Integration Points

### 1. Task Completion

When a task is completed, add this to your `gtd-task complete` command:

```bash
# After marking task as complete
gtd-gamify-award task "$priority" "Completed task: $task_name" "task_completion"
```

**XP Values:**
- Low priority task: 10 XP
- Normal task: 25 XP
- High priority/urgent: 50 XP

### 2. Habit Logging

When a habit is logged, add this to your `gtd-habit log` command:

```bash
# After logging habit
gtd-gamify-award "habit_$frequency" "" "Completed habit: $habit_name" "daily_logging"
```

**XP Values:**
- Daily habit: 15 XP
- Weekly habit: 25 XP
- Monthly habit: 50 XP

### 3. Project Completion

When a project is completed, add this to your `gtd-project complete` command:

```bash
# After marking project as complete
gtd-gamify-award "project_$size" "" "Completed project: $project_name"
```

**XP Values:**
- Small project: 100 XP
- Medium project: 250 XP
- Large project: 500 XP

### 4. Daily Logging

When a daily log entry is created, add this:

```bash
# After creating daily log entry
gtd-gamify-award daily_log "" "Daily log entry" "daily_logging"
```

**XP Value:** 5 XP

### 5. Reviews

When a review is completed, add this:

```bash
# After completing review
gtd-gamify-award "review_$type" "" "Completed $type review" "review"
```

**XP Values:**
- Daily review: 50 XP
- Weekly review: 75 XP
- Monthly review: 100 XP

### 6. Exercise/Health

When exercise is logged, add this:

```bash
# After logging exercise
gtd-gamify-award exercise "$intensity" "Exercise: $exercise_type" "exercise"
```

**XP Values:**
- Normal exercise: 20 XP
- Intense exercise: 40 XP

## 📝 Example Integration

Here's how to integrate into an existing command:

### Before (gtd-task complete):

```bash
#!/bin/bash
# ... existing code ...
task_id="$1"
# Mark task as complete
# ... existing completion logic ...
echo "✓ Task completed!"
```

### After (with gamification):

```bash
#!/bin/bash
# ... existing code ...
task_id="$1"
# Mark task as complete
# ... existing completion logic ...
echo "✓ Task completed!"

# Award XP (silent if gamification not set up)
if command -v gtd-gamify-award &>/dev/null; then
  gtd-gamify-award task "" "Completed task: $task_name" "task_completion" 2>/dev/null || true
fi
```

## 🔧 Helper Function

You can also create a helper function in your shell config:

```bash
# Add to ~/.zshrc or ~/.bashrc
award_xp() {
  if command -v gtd-gamify-award &>/dev/null; then
    gtd-gamify-award "$@" 2>/dev/null || true
  fi
}
```

Then use it in your commands:

```bash
award_xp task "" "Completed task" "task_completion"
```

## 🎮 Activity Types

Available activity types for `gtd-gamify-award`:

- `task` - General task completion
- `task_high_priority` - High priority task
- `task_low_priority` - Low priority task
- `habit_daily` - Daily habit
- `habit_weekly` - Weekly habit
- `habit_monthly` - Monthly habit
- `project_small` - Small project
- `project_medium` - Medium project
- `project_large` - Large project
- `daily_log` - Daily log entry
- `review_daily` - Daily review
- `review_weekly` - Weekly review
- `review_monthly` - Monthly review
- `exercise` - Exercise session
- `exercise_intense` - Intense exercise
- `health_log` - Health metric logged

## 🔥 Streak Types

Available streak types:

- `daily_logging` - Daily log entries
- `task_completion` - Task completion
- `review` - Reviews
- `exercise` - Exercise

## ⚠️ Important Notes

1. **Silent Failure**: The `gtd-gamify-award` script fails silently if gamification isn't set up, so it won't break your existing commands.

2. **Optional**: Gamification is completely optional - your GTD system works fine without it.

3. **Performance**: XP awards are fast and don't slow down your commands.

4. **Non-Intrusive**: Gamification doesn't change your workflow - it just adds rewards in the background.

## 🚀 Quick Integration Checklist

- [ ] Add `gtd-gamify-award` call to `gtd-task complete`
- [ ] Add `gtd-gamify-award` call to `gtd-habit log`
- [ ] Add `gtd-gamify-award` call to `gtd-project complete`
- [ ] Add `gtd-gamify-award` call to `gtd-daily-log`
- [ ] Add `gtd-gamify-award` call to `gtd-review`
- [ ] Add `gtd-gamify-award` call to exercise logging commands
- [ ] Test that commands still work if gamification isn't set up

## 📚 See Also

- `GAMIFICATION_QUICK_START.md` - How to use gamification
- `GAMIFICATION_SYSTEM_DESIGN.md` - Full system design
- `gtd-gamify` - Main gamification command
- `gtd-gamify-award` - Helper script for awarding XP

---

**Happy gamifying!** 🎮✨

