# Learning System Preferences - Implementation Guide

## 🎯 Overview

The Learning System Preferences feature makes your GTD system adapt to **you** instead of you adapting to it. It tracks your behavior, learns your preferences, and uses that knowledge to improve suggestions and reduce unwanted AI recommendations.

## ✅ Features Implemented

### 1. **Track and Learn Preferred GTD Contexts**

**What it tracks:**
- Which contexts you actually use (computer, home, office, phone, etc.)
- Frequency of context usage
- Context preference scores (derived from usage)

**How it learns:**
- Automatically tracks context every time you create a task
- Tracks context when processing inbox items
- Learns from existing tasks (via `gtd-preferences-learn learn`)

**How it uses this:**
- AI suggestions will prefer contexts you actually use
- Context suggestions adapt to your usage patterns

### 2. **Task Priority Calibration**

**What it tracks:**
- How often you use each priority level
- Examples of tasks you mark as each priority
- Your personal definition of "urgent" and "important"

**How it learns:**
- Tracks priority every time you create a task
- Stores example tasks for each priority level
- Learns your priority scale from actual usage

**How it uses this:**
- AI suggestions will match your priority calibration
- If you rarely use "urgent_important", AI won't suggest it often
- Priority suggestions align with your actual behavior

### 3. **Writing Style Preferences**

**What it tracks:**
- Examples of your task titles
- Note writing styles (from Zettelkasten notes)
- Preferred formats (concise vs. detailed)

**How it learns:**
- Extracts task titles from existing tasks
- Analyzes note content for style patterns
- Learns from what you actually write

**How it uses this:**
- AI suggestions match your writing style
- Task titles suggested in your preferred format
- Consistent tone and style across suggestions

### 4. **Review Timing Optimization**

**What it tracks:**
- Actual times you perform daily reviews
- Actual days/times for weekly reviews
- Frequency and patterns of monthly reviews

**How it learns:**
- Automatically tracks when you run `gtd-review daily`
- Tracks when you run `gtd-review weekly`
- Calculates average review times from your behavior

**How it uses this:**
- Suggests review times based on when you actually review
- Reminders align with your natural review patterns
- Optimized scheduling based on your behavior

### 5. **Feature Usage Patterns**

**What it tracks:**
- Commands you use (and how often)
- Wizard options you select
- Suggestion acceptance/dismissal rates
- Which suggestion types you accept vs. dismiss

**How it learns:**
- Tracks every command you run
- Monitors wizard option selections
- Tracks suggestion acceptance/dismissal

**How it uses this:**
- Stops suggesting features you never use
- Prioritizes suggestions for features you actually use
- Improves suggestion relevance based on acceptance rates

### 6. **Config File for Manual Preference Overrides**

**Location:** `~/.gtd_preferences_config`

Allows you to manually override learned preferences:
- Force context preferences
- Adjust priority calibration
- Disable suggestions for unused features
- Set preferred review times
- Customize writing style preferences

## 🚀 Usage

### Initialize Preferences System

```bash
gtd-preferences-learn init
```

This creates `~/.gtd_preferences.json` to start tracking.

### Learn from Existing Tasks

```bash
gtd-preferences-learn learn
```

Scans all your existing tasks and learns:
- Context preferences
- Priority patterns
- Writing styles

### View Learned Preferences

```bash
gtd-preferences-learn show
```

Shows a summary of:
- Preferred contexts (with usage percentages)
- Priority usage patterns
- Review timing averages
- Feature usage stats
- Suggestion acceptance rates

### Via Wizard

```bash
gtd-wizard
# Select: 58) Learning System Preferences
```

**Options:**
1. **View learned preferences** - See what the system has learned
2. **Learn from existing tasks** - One-time learning scan
3. **Set manual preference overrides** - Edit config file
4. **Reset preferences** - Start fresh
5. **View preferences config file** - See manual overrides

## 📊 Automatic Tracking

The system automatically tracks:

### Task Creation
- Context used
- Priority assigned
- Task title (for style learning)
- Command used (`gtd-task`)

### Review Timing
- When you run `gtd-review daily`
- When you run `gtd-review weekly`
- When you run `gtd-review monthly`

### Suggestion Interactions
- When you accept a suggestion
- When you dismiss a suggestion
- Suggestion type (task, project, zettel, MOC)

### Feature Usage
- Wizard option selections
- Commands executed
- Feature interactions

## 🔧 Manual Overrides

Edit `~/.gtd_preferences_config` to override learned preferences:

```bash
# Preferred contexts
computer=0.8
home=0.6

# Priority calibration
priority_urgent_important=0.1
priority_not_urgent_important=0.7

# Disable suggestions for unused features
disable_suggestions_for=habits
disable_suggestions_for=zettelkasten

# Review timing preferences
preferred_daily_review_time=18:00
preferred_weekly_review_day=Sunday
```

## 🎯 Impact

### Before (Without Learning)
- AI suggests contexts you never use
- Priority suggestions don't match your scale
- Suggestions for features you never use
- Review reminders at times you never review
- Writing style doesn't match yours

### After (With Learning)
- ✅ Context suggestions match your actual usage
- ✅ Priority calibration learns your personal scale
- ✅ Suggestions stop for unused features
- ✅ Review timing optimizes to when you actually review
- ✅ Writing style matches your preferences
- ✅ System adapts to **you**, not vice versa

## 📈 Example Output

```bash
$ gtd-preferences-learn show

📚 Learned Preferences
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Preferred Contexts:
   computer            ████████████████ (80%)
   home                ████████ (40%)
   phone               ██ (10%)

⚡ Priority Usage:
   not_urgent_important    145 tasks
   urgent_important         12 tasks
   urgent_not_important      8 tasks

📅 Review Timing:
   Daily reviews: Average time 18:30
   Weekly reviews: 24 recorded

🔧 Feature Usage:
   Top commands:
      gtd-task                   245 uses
      gtd-capture                189 uses
      gtd-review                  42 uses

   Suggestion acceptance rate: 67/145 (46.2%)

Last updated: 2025-01-05T14:23:15
```

## 🔄 Integration Points

### Already Integrated
- ✅ Task creation (`gtd-task`)
- ✅ Review timing (`gtd-review`)
- ✅ Context selection (`gtd-process`)
- ✅ Suggestion acceptance/dismissal (`gtd-checkin`)
- ✅ Wizard usage (`gtd-wizard`)

### Future Integration
- AI suggestion generation (use preferences in prompts)
- Context suggestions (prefer learned contexts)
- Priority suggestions (match user's calibration)
- Review reminders (use learned times)

## 🛡️ Privacy

All preferences are stored locally:
- `~/.gtd_preferences.json` - Learned preferences
- `~/.gtd_preferences_config` - Manual overrides

No data is sent anywhere. Everything stays on your machine.

## 💡 Best Practices

1. **Initialize early** - Run `init` when setting up
2. **Learn from existing data** - Run `learn` to bootstrap
3. **Review periodically** - Check `show` to see what's learned
4. **Use manual overrides** - Fine-tune with config file
5. **Let it learn** - The more you use the system, the better it gets

The system continuously learns and adapts. The longer you use it, the more it understands your preferences!
