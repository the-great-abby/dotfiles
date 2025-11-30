# Morning & Evening Check-In Process

## 🎯 Overview

The check-in process helps you start and end each day intentionally, with structured reflection, planning, and habit tracking.

## 🌅 Morning Check-In

### What It Does

The morning check-in helps you:
- Set intentions for the day
- Identify top priorities
- Check system status (inbox, tasks, projects)
- Review and complete morning habits
- Plan your day

### Morning Questions

1. **How am I feeling?** - Energy, mood, readiness
2. **Top 3 priorities** - What matters most today?
3. **Today's goals** - What do I need to accomplish?
4. **Potential blockers** - What might get in the way?
5. **Gratitude** - What am I grateful for?

### Morning Habits

- Automatically shows morning habits
- Prompts to complete them
- Logs completions automatically

### Quick Actions

After check-in, you can:
- Process inbox
- View today's tasks
- View habit dashboard
- Continue with your day

## 🌙 Evening Check-In

### What It Does

The evening check-in helps you:
- Reflect on the day
- Review accomplishments
- Identify what went well
- Plan for tomorrow
- Complete evening habits
- Review areas of responsibility

### Evening Questions

1. **What did I accomplish?** - Review the day
2. **What went well?** - Celebrate wins
3. **What could improve?** - Learn from challenges
4. **Did I complete priorities?** - Check progress
5. **Gratitude** - What am I grateful for?
6. **What did I learn?** - Capture insights
7. **Areas attention** - Which areas got attention?
8. **Tomorrow preview** - What's important tomorrow?

### Evening Habits

- Automatically shows evening habits
- Prompts to complete them
- Logs completions automatically

### Quick Actions

After check-in, you can:
- Review today's log
- View habit dashboard
- Plan tomorrow
- Continue

## 🚀 How to Use

### Morning Check-In
```bash
gtd-checkin morning
# or
gtd-checkin  # Auto-detects time of day
```

### Evening Check-In
```bash
gtd-checkin evening
```

### From Wizard
```bash
make gtd-wizard
# Choose: 18) 🌅 Morning/Evening Check-In
```

## 📝 What Gets Saved

All check-ins are automatically saved to your daily log:

### Morning Check-In Saves:
- How you're feeling
- Top 3 priorities
- Today's goals
- Potential blockers
- Gratitude
- Morning habit completions

### Evening Check-In Saves:
- Accomplishments
- What went well
- What could improve
- Priorities completed
- Gratitude
- What you learned
- Areas attention
- Tomorrow preview
- Evening habit completions

## 🔄 Integration with Your System

### Daily Logs
- All check-ins saved to daily log
- Personas can see your reflections
- Mistress Louiza tracks your progress

### Habits
- Automatically shows due habits
- Prompts to complete them
- Logs completions

### Areas
- Evening check-in asks about areas
- Links to area review

### Tasks & Projects
- Morning shows system status
- Quick actions to process/view

## 💡 Pro Tips

### 1. **Make It a Routine**
- Do morning check-in when you start your day
- Do evening check-in before bed
- Set reminders if needed

### 2. **Be Honest**
- Reflect honestly on feelings
- Acknowledge what went well
- Learn from challenges

### 3. **Keep It Brief**
- 5-10 minutes for each check-in
- Don't overthink answers
- Focus on what matters

### 4. **Use Quick Actions**
- Process inbox in morning
- Review log in evening
- Plan tomorrow at night

### 5. **Review Regularly**
- Look back at check-ins weekly
- See patterns in your reflections
- Adjust priorities based on patterns

## 🎯 Example Morning Check-In

```bash
$ gtd-checkin morning

🌅 Morning Check-In - 2025-11-30 (Sunday)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Quick Status
  📥 Inbox: 3 item(s)
  ✅ Active tasks: 5
  📁 Active projects: 2

🔁 Habits Due Today:
  • Take pills
  • Morning workout

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💭 Morning Reflection

1. How am I feeling this morning? (energy, mood, readiness)
   Feeling good, ready to tackle the day, medium energy

2. What are my top 3 priorities for today?
   Priority 1: Process inbox
   Priority 2: Study Kubernetes
   Priority 3: Clean bedroom

3. What do I need to accomplish today?
   Process inbox, study for 2 hours, clean bedroom, take pills

4. What might get in my way today? (blockers, distractions)
   Need to stay focused, avoid distractions

5. What am I grateful for today?
   Good health, supportive partner, learning opportunities

🔁 Morning Habits
  Complete 'Take pills'? (y/n): y
  ✓ Logged: Take pills
  Streak: 5 day(s)

  Complete 'Morning workout'? (y/n): y
  ✓ Logged: Morning workout
  Streak: 3 day(s)

✓ Morning check-in saved to daily log

Quick actions:
  1) Process inbox (3 items)
  2) View today's tasks
  3) View habit dashboard
  4) Continue
Choose (1-4): 1
[Processes inbox...]

Have a productive day! 🌅
```

## 🎯 Example Evening Check-In

```bash
$ gtd-checkin evening

🌙 Evening Check-In - 2025-11-30 (Sunday)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💭 Evening Reflection

1. What did I accomplish today?
   Processed inbox, studied Kubernetes for 2 hours, cleaned bedroom

2. What went well today?
   Stayed focused, completed all priorities, felt productive

3. What could have gone better?
   Could have started earlier, got distracted a bit

4. Did I complete my top priorities?
   Yes, all three priorities completed!

5. What am I grateful for today?
   Productive day, good progress on learning, clean space

6. What did I learn today?
   New Kubernetes concepts, better understanding of pods

🔁 Evening Habits
  Complete 'Take evening pills'? (y/n): y
  ✓ Logged: Take evening pills
  Streak: 5 day(s)

🎯 Areas Check
Which areas got attention today?
   Health & Wellness (workout, pills), Personal Development (Kubernetes study), Home & Living Space (cleaned bedroom)

📅 Tomorrow Preview
What's important for tomorrow?
   Continue Kubernetes study, weekly review, plan next week

✓ Evening check-in saved to daily log

Quick actions:
  1) Review today's log
  2) View habit dashboard
  3) Plan tomorrow
  4) Continue
Choose (1-4): 2
[Shows habit dashboard...]

Rest well! 🌙
```

## 🔄 Setting Up Reminders

### Morning Reminder
You can set up a reminder (if not already set):
```bash
# Check if morning reminder exists
gtd-setup-morning-reminder
```

### Evening Reminder
You can set up a reminder:
```bash
# Create evening check-in reminder
# (Can be added to existing daily reminder system)
```

## 📊 Benefits

### Morning Check-In:
- ✅ Start day with intention
- ✅ Set clear priorities
- ✅ Check system status
- ✅ Complete morning habits
- ✅ Plan your day

### Evening Check-In:
- ✅ Reflect on the day
- ✅ Celebrate wins
- ✅ Learn from challenges
- ✅ Complete evening habits
- ✅ Plan tomorrow
- ✅ Review areas

## 🎯 Integration with Mistress Louiza

Mistress Louiza can see your check-ins in daily logs:
- She'll notice if you're consistent
- She'll celebrate your reflections
- She'll remind you if you miss check-ins
- She'll track your progress

## 🚀 Quick Start

### 1. Try Morning Check-In
```bash
gtd-checkin morning
```

### 2. Try Evening Check-In
```bash
gtd-checkin evening
```

### 3. Make It a Habit
- Add to your routine
- Set reminders
- Review regularly

## 📚 Commands Reference

```bash
# Morning check-in
gtd-checkin morning
gtd-checkin  # Auto-detects (morning if before noon)

# Evening check-in
gtd-checkin evening

# From wizard
make gtd-wizard → 18) 🌅 Morning/Evening Check-In
```

## 🎯 Next Steps

1. **Try it today:**
   ```bash
   gtd-checkin morning
   ```

2. **Set up routine:**
   - Morning: When you start your day
   - Evening: Before bed

3. **Review regularly:**
   - Look back at check-ins
   - See patterns
   - Adjust as needed

Your check-in process is ready! 🌅🌙✨

