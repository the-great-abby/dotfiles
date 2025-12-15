# Workflow Improvements: What You're Missing

## 🎯 The Missing Pieces

After analyzing your system, here are the workflow improvements that will make a big difference:

### 1. ⚡ Quick Aliases (Not Set Up)

**Problem**: Your docs suggest aliases like `log`, `idea`, `task`, `c`, `p`, but they're not actually configured.

**Solution**: Add these to your `~/.zshrc`:

```bash
# GTD Quick Aliases - The Most Important Ones
alias log="addInfoToDailyLog"
alias idea="zet"
alias task="gtd-capture"
alias c="gtd-capture"
alias p="gtd-process"
alias t="gtd-task list"
alias w="make gtd-wizard"

# Quick Status & Routines
alias status="make gtd-status"
alias now="gtd-now"  # See below
alias today="gtd-today"  # See below
alias morning="gtd-morning"  # See below
alias evening="gtd-evening"  # See below

# Quick Navigation
alias inbox="cd ~/Documents/gtd/0-inbox"
alias projects="cd ~/Documents/gtd/1-projects"
alias brain="cd ~/Documents/obsidian/Second\ Brain"
```

**Impact**: Saves 5-10 seconds per command, makes capture frictionless.

---

### 2. 🚀 Quick "What Should I Do Now?" Command

**Problem**: No quick way to see what you should focus on right now.

**Solution**: Create `bin/gtd-now`:

```bash
#!/bin/bash
# Quick "What should I do now?" - Shows actionable items at a glance

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 What Should You Do Now?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Inbox count
inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ $inbox_count -gt 0 ]]; then
  echo "📥 Inbox: ${inbox_count} item(s) - Process first!"
  echo ""
fi

# Urgent/Important tasks
echo "🔥 Urgent & Important Tasks:"
gtd-task list --priority=urgent_important 2>/dev/null | head -5 || echo "  (none)"
echo ""

# Tasks due today
echo "📅 Tasks Due Today:"
gtd-task list --due=today 2>/dev/null | head -5 || echo "  (none)"
echo ""

# Next actions (context-based)
echo "💻 Computer Tasks (next 3):"
gtd-task list --context=computer 2>/dev/null | head -3 || echo "  (none)"
echo ""

# Habits due
if [[ -d ~/Documents/gtd/habits ]]; then
  due_habits=$(find ~/Documents/gtd/habits -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ $due_habits -gt 0 ]]; then
    echo "✅ Habits Due: ${due_habits}"
    echo ""
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Quick commands:"
echo "  p          → Process inbox"
echo "  t          → List all tasks"
echo "  w          → Open wizard"
echo ""
```

**Usage**: Just type `now` to see what to focus on.

---

### 3. 🌅 Quick Morning/Evening Routines

**Problem**: Morning and evening routines are mentioned but not implemented as single commands.

**Solution**: Create these scripts:

**`bin/gtd-morning`**:
```bash
#!/bin/bash
# Morning routine - Quick start to your day

echo ""
echo "🌅 Good Morning! Starting your day..."
echo ""

# 1. Check status
make gtd-status

# 2. Process inbox (if items exist)
inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ $inbox_count -gt 0 ]]; then
  echo ""
  read -p "Process inbox now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    gtd-process
  fi
fi

# 3. Show today's focus
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Today's Focus"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gtd-task list --priority=urgent_important 2>/dev/null | head -5
echo ""

# 4. Quick log entry
read -p "Quick morning log entry (or press Enter to skip): " log_entry
if [[ -n "$log_entry" ]]; then
  addInfoToDailyLog "$log_entry"
fi

echo ""
echo "✅ Morning routine complete!"
echo ""
```

**`bin/gtd-evening`**:
```bash
#!/bin/bash
# Evening routine - Wrap up your day

echo ""
echo "🌙 Evening Wrap-Up"
echo ""

# 1. Process inbox
inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ $inbox_count -gt 0 ]]; then
  echo "📥 Inbox: ${inbox_count} item(s)"
  read -p "Process inbox? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    gtd-process
  fi
fi

# 2. Daily log
echo ""
read -p "Evening log entry: " log_entry
if [[ -n "$log_entry" ]]; then
  addInfoToDailyLog "$log_entry"
fi

# 3. Quick review
echo ""
read -p "Quick daily review? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  gtd-review daily
fi

echo ""
echo "✅ Evening routine complete! Rest well."
echo ""
```

**Usage**: 
- `morning` - Start your day
- `evening` - End your day

---

### 4. 🔍 Quick Find & Open Commands

**Problem**: No quick way to find and open items across your system.

**Solution**: Create `bin/gtd-find`:

```bash
#!/bin/bash
# Quick find across GTD system
# Usage: gtd-find <search-term>

if [[ -z "$1" ]]; then
  echo "Usage: gtd-find <search-term>"
  exit 1
fi

SEARCH_TERM="$1"

echo ""
echo "🔍 Searching for: $SEARCH_TERM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Search GTD
echo "📁 GTD System:"
gtd-search "$SEARCH_TERM" 2>/dev/null | head -10
echo ""

# Search Second Brain
if command -v gtd-brain &>/dev/null; then
  echo "🧠 Second Brain:"
  gtd-brain search "$SEARCH_TERM" 2>/dev/null | head -10
  echo ""
fi

# Search daily logs
echo "📝 Daily Logs:"
grep -r "$SEARCH_TERM" ~/Documents/daily_logs/ 2>/dev/null | head -5
echo ""
```

**Usage**: `gtd-find "kubernetes"` - Find anything quickly.

---

### 5. 🔗 Quick Linking Helpers

**Problem**: Linking items between systems requires going through wizards.

**Solution**: Create quick linking shortcuts:

**`bin/gtd-link`**:
```bash
#!/bin/bash
# Quick link helper
# Usage: gtd-link <note> <project|area|resource>

if [[ $# -lt 2 ]]; then
  echo "Usage: gtd-link <note-path> <target>"
  echo ""
  echo "Examples:"
  echo "  gtd-link ~/zettelkasten/note.md my-project"
  echo "  gtd-link idea.md Projects"
  exit 1
fi

NOTE="$1"
TARGET="$2"

# Use zet-link if available
if command -v zet-link &>/dev/null; then
  zet-link link "$NOTE" "$TARGET"
else
  echo "❌ zet-link not found"
  exit 1
fi
```

**Usage**: `gtd-link my-note.md my-project` - Quick linking.

---

### 6. 📊 Enhanced Status Dashboard

**Problem**: Current status is basic. Need a richer overview.

**Solution**: Enhance `bin/gtd-status` or create `bin/gtd-dashboard`:

```bash
#!/bin/bash
# Enhanced system dashboard

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 GTD System Dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Inbox
inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "📥 Inbox: ${inbox_count} item(s)"
if [[ $inbox_count -gt 5 ]]; then
  echo "   ⚠️  Consider processing soon"
fi
echo ""

# Tasks
active_tasks=$(find ~/Documents/gtd/tasks -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
urgent_tasks=$(gtd-task list --priority=urgent_important 2>/dev/null | grep -c "^-" || echo "0")
echo "✅ Tasks: ${active_tasks} active, ${urgent_tasks} urgent"
echo ""

# Projects
projects_count=$(ls -1 ~/Documents/gtd/1-projects/*/README.md 2>/dev/null | wc -l | tr -d ' ')
echo "📁 Projects: ${projects_count} active"
echo ""

# Today's log
today=$(date +"%Y-%m-%d")
log_file="$HOME/Documents/daily_logs/${today}.txt"
if [[ -f "$log_file" ]]; then
  log_count=$(grep -c "^[0-9][0-9]:[0-9][0-9]" "$log_file" 2>/dev/null || echo "0")
  echo "📝 Today's Log: ${log_count} entries"
else
  echo "📝 Today's Log: Not started yet"
fi
echo ""

# Habits
if [[ -d ~/Documents/gtd/habits ]]; then
  due_habits=$(find ~/Documents/gtd/habits -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "✅ Habits: ${due_habits} due"
  echo ""
fi

# Zettelkasten inbox
if [[ -d ~/Documents/obsidian/Second\ Brain/0-inbox ]]; then
  zet_inbox=$(ls -1 ~/Documents/obsidian/Second\ Brain/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "💡 Zettelkasten Inbox: ${zet_inbox} note(s)"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Quick actions:"
echo "  now        → What should I do now?"
echo "  p          → Process inbox"
echo "  t          → List tasks"
echo "  w          → Open wizard"
echo ""
```

**Usage**: `status` or `dashboard` - See everything at a glance.

---

### 7. ⚡ One-Letter Capture Shortcuts

**Problem**: Even `c` for capture could be shorter for common cases.

**Solution**: Add these ultra-short functions to your `.zshrc`:

```bash
# Ultra-quick capture functions
# Usage: c "task" or just: c task
c() {
  if [[ -z "$1" ]]; then
    gtd-capture
  else
    gtd-capture "$*"
  fi
}

# Quick idea capture
i() {
  if [[ -z "$1" ]]; then
    zet
  else
    zet "$*"
  fi
}

# Quick log
l() {
  if [[ -z "$1" ]]; then
    addInfoToDailyLog
  else
    addInfoToDailyLog "$*"
  fi
}
```

**Usage**: 
- `c "my task"` - Capture task
- `i "my idea"` - Capture idea
- `l "my log"` - Log entry

---

### 8. 🎯 Context Switching Helpers

**Problem**: No quick way to switch between different work contexts.

**Solution**: Create context helpers:

```bash
# Quick context switching
alias work="gtd-task list --context=computer --priority=urgent_important"
alias home="gtd-task list --context=home"
alias calls="gtd-task list --context=calls"
alias errands="gtd-task list --context=errands"
```

**Usage**: Type `work` to see computer tasks, `home` for home tasks, etc.

---

## 🚀 Implementation Priority

### Week 1: Quick Wins (5 minutes)
1. ✅ Add quick aliases to `.zshrc`
2. ✅ Create `gtd-now` script
3. ✅ Create `gtd-morning` and `gtd-evening` scripts

### Week 2: Enhanced Experience (15 minutes)
4. ✅ Create `gtd-find` for quick searching
5. ✅ Create `gtd-dashboard` for better status
6. ✅ Add context switching aliases

### Week 3: Advanced (Optional)
7. ✅ Create `gtd-link` helper
8. ✅ Add ultra-short capture functions

---

## 📋 Complete Alias Setup

Add this entire block to your `~/.zshrc`:

```bash
# ============================================
# GTD Quick Aliases & Functions
# ============================================

# Core aliases
alias log="addInfoToDailyLog"
alias idea="zet"
alias task="gtd-capture"
alias c="gtd-capture"
alias p="gtd-process"
alias t="gtd-task list"
alias w="make gtd-wizard"
alias status="make gtd-status"

# Quick routines
alias now="gtd-now"
alias today="gtd-today"
alias morning="gtd-morning"
alias evening="gtd-evening"

# Navigation
alias inbox="cd ~/Documents/gtd/0-inbox"
alias projects="cd ~/Documents/gtd/1-projects"
alias brain="cd ~/Documents/obsidian/Second\ Brain"

# Context switching
alias work="gtd-task list --context=computer --priority=urgent_important"
alias home="gtd-task list --context=home"
alias calls="gtd-task list --context=calls"

# Ultra-quick capture (with arguments)
c() {
  if [[ -z "$1" ]]; then
    gtd-capture
  else
    gtd-capture "$*"
  fi
}

i() {
  if [[ -z "$1" ]]; then
    zet
  else
    zet "$*"
  fi
}

l() {
  if [[ -z "$1" ]]; then
    addInfoToDailyLog
  else
    addInfoToDailyLog "$*"
  fi
}
```

---

## 🎯 The Big Picture

These improvements address the **friction points** in your workflow:

1. **Too many keystrokes** → Aliases solve this
2. **Don't know what to do** → `now` command solves this
3. **Routine is manual** → `morning`/`evening` solve this
4. **Can't find things** → `gtd-find` solves this
5. **Status is basic** → Enhanced dashboard solves this

**The result**: Your system becomes **frictionless** - you can capture, process, and act without thinking about the commands.

---

## ✅ Next Steps

1. **Today**: Add the aliases to your `.zshrc` and reload
2. **This week**: Create the `gtd-now`, `gtd-morning`, and `gtd-evening` scripts
3. **Next week**: Add the enhanced dashboard and find commands

**Start with aliases** - they'll give you immediate improvement with zero effort!





