# Habits & Recurring Tasks Guide

## 🎯 Overview

Your GTD system now includes a comprehensive habit tracker and recurring task system. This helps you track often-repeated tasks and build consistent habits.

## 🔁 What Are Habits vs. Recurring Tasks?

### Habits
- **Tracked over time** - Streaks, completions, statistics
- **Focus on consistency** - Building routines
- **Long-term tracking** - See progress over weeks/months
- **Examples**: Morning workout, daily meditation, taking pills

### Recurring Tasks
- **One-time tasks that repeat** - Same task, different instances
- **Focus on completion** - Get it done each time
- **Examples**: Weekly review, monthly report, quarterly planning

**Recommendation**: Use habits for things you want to track long-term (workouts, pills, routines). Use recurring tasks for one-time tasks that happen regularly (reviews, reports).

## 📋 Habit Tracker Features

### 1. **Create Habits**
```bash
gtd-habit create "Morning workout"
gtd-habit create "Take pills"
gtd-habit create "Daily meditation"
```

**What you'll set:**
- Habit name and description
- Frequency (daily, weekly, monthly, custom)
- Area of responsibility (optional)
- Context (optional)
- Time of day (optional)

### 2. **Log Completions**
```bash
gtd-habit log "Morning workout"
# or
gtd-habit complete "Morning workout"
```

**What happens:**
- Tracks completion date
- Updates streak (consecutive days)
- Updates longest streak
- Increments total completions
- Logs to daily log automatically
- Celebrates milestones (7, 30, 100 days)

### 3. **View Dashboard**
```bash
gtd-habit dashboard
```

**Shows:**
- Overall stats (total habits, active, due today)
- Habits due today
- Top streaks
- Total completions

### 4. **List All Habits**
```bash
gtd-habit list
```

**Shows:**
- All habits with status
- Current streaks
- Last completed date
- Which ones are due today

## 🔄 Recurring Tasks

### Create Recurring Task
```bash
gtd-task add "Weekly review"
# When asked "Is this a recurring task/habit? (y/n):" answer "y"
# Then choose frequency
```

**Or create as habit:**
```bash
gtd-habit create "Weekly review"
```

**Recommendation**: Use `gtd-habit` for things you want to track over time. Use `gtd-task` with recurring flag for one-time tasks.

## 📊 What Gets Tracked

### For Each Habit:
- **Streak** - Consecutive days completed
- **Longest Streak** - Best streak ever
- **Total Completions** - All-time count
- **Last Completed** - Most recent date
- **Frequency** - How often it should be done
- **Status** - Active/archived

### Automatic Integration:
- **Daily Logs** - Completions logged automatically
- **Areas** - Linked to areas of responsibility
- **Context** - Can have context (home, computer, etc.)

## 🎯 Common Habits to Track

### Health & Wellness
```bash
gtd-habit create "Morning workout" --frequency=daily --area="health-wellness"
gtd-habit create "Take morning pills" --frequency=daily --area="health-wellness"
gtd-habit create "Take evening pills" --frequency=daily --area="health-wellness"
gtd-habit create "Face routine" --frequency=daily --area="health-wellness"
```

### Personal Development
```bash
gtd-habit create "Study Kubernetes" --frequency=daily --area="personal-development"
gtd-habit create "Read" --frequency=daily --area="personal-development"
gtd-habit create "Practice skills" --frequency=daily --area="personal-development"
```

### Home & Living
```bash
gtd-habit create "Clean bedroom" --frequency=weekly --area="home-living-space"
gtd-habit create "Do laundry" --frequency=weekly --area="home-living-space"
```

### Work & Career
```bash
gtd-habit create "Update LinkedIn" --frequency=monthly --area="work-career"
gtd-habit create "Review industry news" --frequency=daily --area="work-career"
```

## 💡 How Habits Work

### Daily Habits
- Should be completed every day
- Streak resets if you miss a day
- Best for routines and daily practices

### Weekly Habits
- Should be completed once per week
- Streak continues if completed within the week
- Best for weekly maintenance tasks

### Monthly Habits
- Should be completed once per month
- Streak continues if completed within the month
- Best for monthly reviews and maintenance

### Custom Frequencies
- "Every 3 days"
- "Weekdays only"
- "First Monday of month"
- Custom patterns

## 🔄 Workflow: Using Habits

### Morning Routine
```bash
# Log morning habits
gtd-habit log "Take morning pills"
gtd-habit log "Morning workout"
```

### Evening Routine
```bash
# Log evening habits
gtd-habit log "Take evening pills"
gtd-habit log "Face routine"
```

### Weekly Review
```bash
# Check habit dashboard
gtd-habit dashboard

# Review which habits need attention
gtd-habit list
```

## 📊 Habit Dashboard

The dashboard shows:

### Overall Stats
- Total habits
- Active habits
- Due today
- Total streak days
- Total completions

### Habits Due Today
- Lists all daily habits not yet completed
- Quick commands to log them

### Top Streaks
- Shows your longest current streaks
- Motivation to keep going!

## 🎯 Integration with Daily Logs

Habits automatically log to your daily log:

```bash
gtd-habit log "Morning workout"
# Automatically adds to daily log:
# "Completed habit: Morning workout (Health & Wellness area)"
```

This means:
- Habits appear in your daily log
- Personas can see your habit progress
- Mistress Louiza can track your consistency
- Easy to review habit patterns

## 🔄 Recurring Tasks vs. Habits

### When to Use Habits:
- Things you want to track long-term
- Building consistency (workouts, pills, routines)
- Want to see streaks and statistics
- Daily/weekly routines

### When to Use Recurring Tasks:
- One-time tasks that repeat
- Don't need long-term tracking
- Just need to remember to do them
- Examples: Weekly review, monthly report

### Recommendation:
- **Use habits** for personal routines (workouts, pills, meditation)
- **Use recurring tasks** for work tasks (reports, reviews)

## 🚀 Quick Start

### 1. Create Your First Habit
```bash
gtd-habit create "Take pills"
```

### 2. Log Completion
```bash
gtd-habit log "Take pills"
```

### 3. Check Dashboard
```bash
gtd-habit dashboard
```

### 4. Review Regularly
```bash
# During weekly review
gtd-habit dashboard
```

## 📋 Common Habits Based on Your System

Based on what you already track:

### Health & Wellness
```bash
gtd-habit create "Take pills" --frequency=daily
gtd-habit create "Workout" --frequency=daily  # kettlebells, walks, runs
gtd-habit create "Face routine" --frequency=daily
```

### Home & Living
```bash
gtd-habit create "Clean bedroom" --frequency=weekly
gtd-habit create "Do laundry" --frequency=weekly
```

### Personal Development
```bash
gtd-habit create "Study Kubernetes" --frequency=daily
gtd-habit create "GTD review" --frequency=weekly
```

## 💡 Pro Tips

### 1. **Start Small**
- Create 3-5 habits first
- Focus on most important ones
- Add more gradually

### 2. **Log Immediately**
- Log habits right after completing them
- Don't wait until end of day
- Build the logging habit!

### 3. **Use Dashboard**
- Check dashboard daily
- See what's due
- Celebrate streaks

### 4. **Link to Areas**
- Assign habits to areas
- Track by life area
- Review during area review

### 5. **Review Regularly**
- Check habits during weekly review
- Archive habits you no longer do
- Adjust frequencies as needed

## 🎯 Integration with Mistress Louiza

Mistress Louiza can see your habit progress in daily logs:
- She'll notice if you're consistent
- She'll scold if you miss habits
- She'll celebrate streaks
- She'll remind you about due habits

## 📊 Example Habit Setup

```bash
# Create health habits
gtd-habit create "Take morning pills"
# Frequency: daily
# Area: Health & Wellness
# Time: morning

gtd-habit create "Workout"
# Frequency: daily
# Area: Health & Wellness
# Time: flexible

# Create home habits
gtd-habit create "Clean bedroom"
# Frequency: weekly
# Area: Home & Living Space

# Create learning habits
gtd-habit create "Study Kubernetes"
# Frequency: daily
# Area: Personal Development
```

## 🔄 Access from Wizard

```bash
make gtd-wizard
# Choose: 17) 🔁 Manage habits & recurring tasks
```

## 📚 Commands Reference

```bash
# Create habit
gtd-habit create "Habit Name"

# Log completion
gtd-habit log "Habit Name"
gtd-habit complete "Habit Name"  # Same as log

# View dashboard
gtd-habit dashboard

# List habits
gtd-habit list

# View details
gtd-habit view "Habit Name"

# Archive habit
gtd-habit archive "Habit Name"
```

## 🎯 Next Steps

1. **Create your first habit:**
   ```bash
   gtd-habit create "Take pills"
   ```

2. **Start logging:**
   ```bash
   gtd-habit log "Take pills"
   ```

3. **Check dashboard:**
   ```bash
   gtd-habit dashboard
   ```

4. **Add more habits gradually!**

Your habits are now tracked and integrated with your GTD system! 🔁✨

