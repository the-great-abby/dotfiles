---
name: Habit Check-In
description: Guides daily habit check-in, tracks habit completion, identifies patterns, and links habits to tasks. Maintains consistency and connects habits to the GTD system.
version: 1.0.0
tags:
  - habits
  - daily
  - tracking
  - consistency
  - health
author: GTD System
---

# Habit Check-In Workflow

A comprehensive skill for daily habit tracking, completion logging, pattern identification, and integration with the GTD task system.

## When to Use

Use this skill when you need to:
- **Daily habit check-in**: Track habit completion
- **Review habits**: See which habits need attention
- **Identify patterns**: Understand habit consistency
- **Link to tasks**: Connect habits to actionable tasks
- **Improve consistency**: Get guidance on building habits

## How It Works

This workflow uses habit tracking commands and daily logs to maintain habit consistency and identify patterns.

## Step-by-Step Workflow

### Step 1: List Active Habits

**Purpose:** See all habits that need tracking.

**Actions:**
1. Run `gtd-habit list` to see all active habits
2. Review habit details:
   - Name and description
   - Frequency (daily, weekly, etc.)
   - Current streak
   - Last completion date
   - Area of responsibility
   - Context

**Commands:**
- `gtd-habit list` - List all habits

**What to note:**
- Total number of active habits
- Habits due today
- Habits with long streaks (celebrate!)
- Habits with broken streaks (need attention)

---

### Step 2: Review Habits Due Today

**Purpose:** Identify which habits should be completed today.

**Actions:**
1. From the habit list, identify habits due today:
   - Daily habits (due every day)
   - Weekly habits (due on specific day)
   - Custom frequency habits (due based on schedule)
2. Note which habits are:
   - Already completed today
   - Not yet completed
   - Overdue (missed previous days)

**Commands:**
- `gtd-habit list` - Shows completion status
- `gtd-habit dashboard` - Shows due today (if available)

**Questions to ask:**
- Which habits are due today?
- Which have I already completed?
- Which still need to be done?
- Are any overdue?

---

### Step 3: Log Habit Completions

**Purpose:** Record completed habits.

**Actions:**
1. For each habit completed today:
   ```bash
   gtd-habit log "Habit Name"
   ```
2. This will:
   - Record completion in habit file
   - Update streak counter
   - Log to daily log
   - Update statistics

**Commands:**
- `gtd-habit log "Habit Name"` - Log habit completion

**Best practices:**
- Log immediately after completing
- Be honest about completion
- Don't log if not actually done
- Log even if streak is broken

---

### Step 4: Review Habit Streaks

**Purpose:** Understand habit consistency.

**Actions:**
1. Review streak information for each habit:
   - Current streak length
   - Longest streak
   - Recent completion pattern
2. Identify:
   - Habits with strong streaks (maintain!)
   - Habits with broken streaks (rebuild)
   - Habits that need more attention

**Commands:**
- `gtd-habit list` - Shows streak information
- `gtd-habit dashboard` - Shows streak statistics (if available)

**What to look for:**
- Streaks of 7+ days (good consistency)
- Streaks of 30+ days (excellent!)
- Broken streaks (need attention)
- Patterns (e.g., always miss on weekends)

---

### Step 5: Identify Habit Patterns

**Purpose:** Understand when and why habits succeed or fail.

**Actions:**
1. Review completion patterns:
   - Which days are habits most often completed?
   - Which days are habits most often missed?
   - What contexts work best?
   - What times of day work best?
2. Review daily logs for habit entries:
   - `read_daily_log(date="today")` - Today's habit logs
   - `read_recent_logs(days=7)` - Past week's patterns

**MCP Tools:**
- `read_daily_log(date="today")` - Today's log entries
- `read_recent_logs(days=7)` - Past week's logs

**Patterns to identify:**
- Time of day patterns (morning vs. evening)
- Day of week patterns (weekdays vs. weekends)
- Context patterns (home vs. office)
- Energy level patterns (high vs. low energy)

---

### Step 6: Create Tasks for Missed Habits

**Purpose:** Convert habit intentions into actionable tasks.

**Actions:**
1. For habits not yet completed today:
   - Determine if it's still possible to complete
   - If yes, create a task:
     ```python
     create_task(
         title="Complete [Habit Name]",
         context="<habit context>",
         priority="not_urgent_important",
         notes="Daily habit - maintain streak"
     )
     ```
2. For overdue habits:
   - Create task to get back on track
   - Or accept the broken streak and restart

**MCP Tools:**
- `create_task(title="...", context="...", priority="...", notes="...")` - Create habit task

**When to create tasks:**
- Habit not yet completed and still possible
- Habit overdue and want to restart
- Habit needs setup/preparation

**When not to create tasks:**
- Habit already completed
- Habit not possible today (e.g., gym closed)
- Habit intentionally skipped

---

### Step 7: Review Habit Performance

**Purpose:** Assess overall habit health.

**Actions:**
1. Review habit statistics:
   - Completion rate (last 7 days, last 30 days)
   - Average streak length
   - Total completions
2. Identify:
   - Habits doing well (maintain)
   - Habits struggling (need support)
   - Habits to consider removing
   - New habits to add

**Commands:**
- `gtd-habit dashboard` - Overall statistics (if available)
- `gtd-habit list` - Individual habit stats

**Questions to ask:**
- Which habits are most consistent?
- Which habits are struggling?
- Are there too many habits?
- Should any habits be removed or modified?

---

### Step 8: Plan Habit Improvements

**Purpose:** Make habits more sustainable.

**Actions:**
1. For struggling habits:
   - Reduce frequency (daily → 3x/week)
   - Change time of day
   - Change context
   - Break into smaller steps
   - Add accountability
2. For successful habits:
   - Maintain current approach
   - Consider increasing challenge
   - Share success with others

**Strategies:**
- **Habit stacking**: Link to existing habit
- **Time blocking**: Schedule specific time
- **Context anchoring**: Link to location/context
- **Accountability**: Share with others
- **Start small**: Reduce scope if needed

---

## Detailed Workflow Examples

### Example 1: Daily Morning Habit Check-In

**Scenario:** Morning routine to check and plan habits.

**Steps:**
1. **List habits:**
   ```bash
   gtd-habit list
   ```
   - Found 8 active habits

2. **Review due today:**
   - Morning meditation (daily) - Not yet done
   - Exercise (daily) - Not yet done
   - Read (daily) - Not yet done
   - Weekly review (weekly, Sunday) - Not due today

3. **Create tasks:**
   ```python
   create_task(title="Morning meditation", context="home", priority="not_urgent_important")
   create_task(title="Exercise", context="home", priority="not_urgent_important")
   ```

4. **Plan completion:**
   - Meditation: 7am (morning routine)
   - Exercise: 8am (after meditation)
   - Reading: Evening (low energy time)

### Example 2: Evening Habit Review

**Scenario:** End of day review of habit completion.

**Steps:**
1. **Review today's habits:**
   - Morning meditation - ✅ Completed (logged)
   - Exercise - ✅ Completed (logged)
   - Reading - ❌ Not completed

2. **Log completions:**
   ```bash
   gtd-habit log "Morning meditation"
   gtd-habit log "Exercise"
   ```

3. **Review patterns:**
   - Reading habit missed 3 days this week
   - Pattern: Always miss on busy days
   - Solution: Schedule reading time in calendar

4. **Create improvement task:**
   ```python
   create_task(
       title="Schedule daily reading time",
       priority="not_urgent_important",
       notes="Reading habit struggling - need to time-block"
   )
   ```

### Example 3: Weekly Habit Review

**Scenario:** Weekly review of habit performance.

**Steps:**
1. **Review past week:**
   - `read_recent_logs(days=7)` - Get habit logs
   - Calculate completion rates

2. **Identify patterns:**
   - Meditation: 7/7 days (100%) - Excellent!
   - Exercise: 5/7 days (71%) - Good, but missed weekends
   - Reading: 4/7 days (57%) - Needs improvement

3. **Plan improvements:**
   - Exercise: Add weekend reminder
   - Reading: Time-block 30 min daily
   - Meditation: Maintain current approach

---

## Best Practices

### Habit Logging

**Log immediately:**
- Log right after completing habit
- Don't wait until end of day
- Be honest about completion

**Be consistent:**
- Log every completion
- Don't skip logging
- Maintain accurate records

### Habit Review

**Review regularly:**
- Daily: Quick check-in
- Weekly: Pattern review
- Monthly: Performance assessment

**Be honest:**
- Acknowledge missed habits
- Don't make excuses
- Focus on improvement

### Habit Creation

**Start small:**
- One habit at a time
- Make it easy to complete
- Build consistency first

**Link to existing:**
- Habit stack (after existing habit)
- Time block (specific time)
- Context anchor (specific location)

### Habit Maintenance

**Celebrate streaks:**
- Acknowledge consistency
- Share successes
- Build momentum

**Rebuild after breaks:**
- Don't give up after one miss
- Restart immediately
- Learn from breaks

---

## Integration with Other Skills

This skill works well with:
- **`interactive-morning-review-runbook`**: Include habit check-in in morning routine
- **`evening-checkin`**: Review habit completion in evening
- **`daily-review`**: Include habits in daily review
- **`weekly-review`**: Review habit patterns weekly
- **`energy-audit-planning`**: Match habits to energy levels

---

## Troubleshooting

### "I keep forgetting to log habits"

**Solutions:**
- Add habit logging to morning/evening check-in
- Set reminders
- Log immediately after completing
- Make it part of routine

### "My streaks keep breaking"

**Solutions:**
- Reduce habit difficulty
- Change time or context
- Start with smaller commitment
- Focus on consistency over perfection

### "I have too many habits"

**Solutions:**
- Focus on 3-5 core habits
- Remove or pause less important ones
- Combine related habits
- Build consistency before adding more

### "Habits don't feel meaningful"

**Solutions:**
- Review why you started the habit
- Link to larger goals
- Celebrate small wins
- Adjust if not serving you

---

## Success Criteria

Successful habit check-in:
- ✓ All active habits reviewed
- ✓ Completions logged accurately
- ✓ Patterns identified
- ✓ Tasks created for missed habits
- ✓ Improvements planned
- ✓ Consistency maintained or improved

---

## Commands Reference

### Habit Management
```bash
# List all habits
gtd-habit list

# Log habit completion
gtd-habit log "Habit Name"

# Create new habit
gtd-habit create "Habit Name"

# View habit dashboard
gtd-habit dashboard
```

### Daily Logs
```python
# Read today's log
read_daily_log(date="today")

# Read past week's logs
read_recent_logs(days=7)
```

### Task Creation
```python
# Create task for habit
create_task(
    title="Complete [Habit Name]",
    context="<habit context>",
    priority="not_urgent_important",
    notes="Daily habit"
)
```

---

## Workflow Summary

```
Habit Check-In Workflow
│
├─ 1. List Active Habits
│   └─ gtd-habit list
│
├─ 2. Review Habits Due Today
│   └─ Identify what needs completion
│
├─ 3. Log Habit Completions
│   └─ gtd-habit log "Habit Name"
│
├─ 4. Review Habit Streaks
│   └─ Check consistency patterns
│
├─ 5. Identify Habit Patterns
│   ├─ read_daily_log(date="today")
│   └─ read_recent_logs(days=7)
│
├─ 6. Create Tasks for Missed Habits
│   └─ create_task() for incomplete habits
│
├─ 7. Review Habit Performance
│   └─ Assess overall habit health
│
└─ 8. Plan Habit Improvements
    └─ Make habits more sustainable
```

---

Remember: Habits are about consistency, not perfection. Focus on building sustainable habits that serve your goals. Celebrate streaks, learn from breaks, and continuously improve your habit system.
