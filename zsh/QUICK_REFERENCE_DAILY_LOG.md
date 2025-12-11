# Quick Reference: From addInfoToDailyLog to Unified System

## 🎯 Keep What Works, Add What's Missing

### Your Current Command (Keep Using It!)

```bash
addInfoToDailyLog "your log entry"
```

**Use this for:**
- ✅ General thoughts and reflections
- ✅ Daily summaries
- ✅ Journal entries
- ✅ Emotional state
- ✅ General activity logging

## 🚀 Add These Commands (Just 2 More!)

### 1. Capture Ideas

```bash
zet "your atomic idea"
```

**Use this for:**
- 💡 Specific concepts or insights
- 💡 Things you want to remember
- 💡 Ideas you might link together

### 2. Capture Tasks

```bash
gtd-capture "your task"
```

**Use this for:**
- 📋 Actionable items
- 📋 Things you need to do
- 📋 Follow-ups

## 📅 Daily Workflow (Add 30 Seconds)

### Morning (Unchanged)

```bash
addInfoToDailyLog "Starting my day"
```

### During Day (Add Capture)

```bash
addInfoToDailyLog "Working on project"        # Your usual log

zet "Key insight discovered"                  # NEW: Atomic idea
gtd-capture "Action item"                     # NEW: Task
```

### Evening (Add Processing)

```bash
addInfoToDailyLog "Ending my day"             # Your usual log

make gtd-wizard → 2                            # NEW: Process (30 seconds)
```

## 🎯 Through the Wizard (Easier!)

### Daily Log

```bash
make gtd-wizard → 15 (Log to daily log)
```

### Capture Ideas

```bash
make gtd-wizard → 1 → 8 (Zettelkasten note)
```

### Capture Tasks

```bash
make gtd-wizard → 1 → 1 (Task)
```

### Process

```bash
make gtd-wizard → 2 (Process inbox)
```

## 💡 Decision: What to Use When?

```
General thought/reflection?
└─→ addInfoToDailyLog "..."

Specific idea/concept?
└─→ zet "..."

Actionable task?
└─→ gtd-capture "..."
```

## ⚡ Quick Aliases (Optional)

Add to your `.zshrc`:

```bash
alias log="addInfoToDailyLog"
alias idea="zet"
alias task="gtd-capture"
```

Now use:

```bash
log "Starting day"       # Your usual
idea "my idea"           # Capture idea
task "my task"           # Capture task
```

## ✅ That's It!

**Keep:** `addInfoToDailyLog` for general logging
**Add:** `zet` for ideas, `gtd-capture` for tasks
**Process:** End of day (30 seconds)

You're using the unified system! 🎉





