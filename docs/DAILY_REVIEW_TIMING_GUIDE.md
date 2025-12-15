# Daily Review & Check-In Timing Guide

## 🎯 Overview

You have **two different processes** for daily reflection and planning:

1. **Daily Review** (`gtd-review daily`) - Currently mixed-purpose, needs clarification
2. **Check-Ins** (`gtd-checkin`) - Separate morning and evening processes

## 📅 Recommended Daily Flow

### 🌅 **MORNING** (When you start your day)

**Use: `gtd-checkin morning`**

**Purpose:** Set intentions and plan your day

**What it does:**
- Sets top 3 priorities for TODAY
- Plans your day
- Checks system status (inbox, tasks)
- Completes morning habits
- Sets intentions

**Questions:**
1. How am I feeling? (energy, mood, readiness)
2. Top 3 priorities for today
3. Today's goals
4. Potential blockers
5. Gratitude

**Time:** 5-10 minutes

---

### 🌙 **EVENING** (End of day, around 6 PM or before bed)

**Use: `gtd-checkin evening`** + **`gtd-review daily`** (if you want a quick review)

**Purpose:** Reflect on the day and prepare for tomorrow

**Evening Check-In (`gtd-checkin evening`):**
- Reflects on accomplishments
- Reviews what went well
- Identifies what could improve
- Completes evening habits
- Plans tomorrow preview

**Evening Review (`gtd-review daily`):**
- Quick system check (inbox count, active tasks)
- Sets priorities for TOMORROW (not today!)
- Reviews what you accomplished TODAY (not yesterday)
- Notes blockers

**Questions:**
1. What did I accomplish today?
2. What went well?
3. What could improve?
4. Did I complete priorities?
5. Gratitude
6. What did I learn?
7. Areas attention
8. Tomorrow preview

**Time:** 5-10 minutes

---

## ✅ Fixed!

Your `gtd-review daily` now **automatically detects** morning vs evening and asks appropriate questions!

**Morning questions:**
- What are my top 3 priorities today?
- What did I accomplish yesterday?
- What's blocking me?
- What needs my attention?

**Evening questions:**
- What did I accomplish today?
- What went well today?
- What's blocking me?
- What are my top 3 priorities for tomorrow?
- What needs my attention?

---

## ✅ How It Works Now

### Auto-Detection (Default)

```bash
gtd-review daily
```

Automatically detects time of day:
- Before 12 PM (noon) → Morning review
- After 12 PM (noon) → Evening review

### Manual Selection

**Morning Review:**
```bash
gtd-review daily morning
```

Questions:
- What are my top 3 priorities today?
- What did I accomplish yesterday?
- What's blocking me?
- What needs my attention?

**Evening Review:**
```bash
gtd-review daily evening
```

Questions:
- What did I accomplish today?
- What went well today?
- What's blocking me?
- What are my top 3 priorities for tomorrow?
- What needs my attention?

---

### Option 2: Use Check-Ins Instead (Simpler!)

**Just use the existing check-ins:**

**Morning:**
```bash
gtd-checkin morning
# or just
gtd-checkin  # Auto-detects time
```

**Evening:**
```bash
gtd-checkin evening
```

This gives you:
- ✅ Clear separation of morning vs evening
- ✅ Better questions for each time
- ✅ Habit tracking built-in
- ✅ Already integrated with daily logs

---

## 🎯 Recommended Daily Routine

### Morning Routine (8:00 AM)
```bash
1. gtd-checkin morning          # Set priorities, plan day
2. Process inbox if needed      # gtd-process
3. Start logging                # addInfoToDailyLog "Starting work..."
```

### Evening Routine (6:00 PM)
```bash
1. gtd-checkin evening          # Reflect on day
2. gtd-review daily             # Quick system check (optional)
3. Process inbox                # Clear it for tomorrow
4. Plan tomorrow                # Set intentions
5. Log final entry              # addInfoToDailyLog "Ending work..."
```

---

## 📝 What Gets Saved Where

### Morning Check-In
- Saved to: Daily log
- Shows: Intentions, priorities, goals
- Personas see: Your daily plan

### Evening Check-In
- Saved to: Daily log
- Shows: Accomplishments, reflections, learnings
- Personas see: Your daily progress

### Daily Review
- Saved to: `~/Documents/gtd/weekly-reviews/daily-YYYY-MM-DD.md`
- Shows: Priorities, accomplishments, blockers
- Purpose: Quick system snapshot

---

## 🔄 Integration

All of these integrate with:
- **Daily Logs** - Everything saves to your daily log
- **Mistress Louiza** - She sees your check-ins and reviews
- **Habit System** - Check-ins include habit tracking
- **GTD System** - Reviews check inbox and tasks

---

## 💡 Pro Tips

1. **Start with Check-Ins** - They're more comprehensive and user-friendly
2. **Make it routine** - Same time every day
3. **Keep it brief** - 5-10 minutes max
4. **Be honest** - Reflection only works if you're real
5. **Use quick actions** - Process inbox from check-in menus

---

## 🚀 Quick Start

**Today's Morning:**
```bash
gtd-checkin morning
```

**Today's Evening:**
```bash
gtd-checkin evening
```

**Optional Evening Review:**
```bash
gtd-review daily
```

---

## 📚 Related Commands

```bash
# Check-ins (recommended)
gtd-checkin morning
gtd-checkin evening
gtd-checkin              # Auto-detects time

# Daily review (system-focused)
gtd-review daily

# From wizard
make gtd-wizard
# Choose: 18) 🌅 Morning/Evening Check-In
# Choose: 6) Review → 1) Daily review
```

---

## 🎯 Summary

**Morning = Planning & Intentions**
- Use: `gtd-checkin morning`
- Focus: What will I do today?
- Questions: Priorities, goals, blockers

**Evening = Reflection & Preparation**
- Use: `gtd-checkin evening` OR `gtd-review daily evening`
- Focus: What did I do? What's tomorrow?
- Questions: Accomplishments, learnings, tomorrow's plan

**Daily Review = Time-Aware System Check**
- Use: `gtd-review daily` (auto-detects) OR `gtd-review daily morning/evening`
- Focus: System status + appropriate questions for time of day
- Morning: Priorities for today, yesterday's accomplishments
- Evening: Today's accomplishments, priorities for tomorrow

