# tmux Productivity Layout - User Guide

**Layout:** 5 panes for complete GTD workflow monitoring

---

## 📐 Layout Overview

```
┌────────────────────────┬────────────────────────┐
│                        │                        │
│   0: MAIN WORK         │   2: DASHBOARD         │
│   (Your Workspace)     │   (Live Stats)         │
│                        │                        │
│                        │   Updates every 60s    │
├────────────────────────┼────────────────────────┤
│                        │                        │
│   1: GTD WIZARD        │   3: DAILY LOG         │
│   (On-Demand)          │   (Live Feed)          │
│                        │                        │
│   Press Enter→Launch   │   tail -f of today     │
│                        ├────────────────────────┤
│                        │                        │
│                        │   4: ADVICE MONITOR    │
│                        │   (Worker Status)      │
└────────────────────────┴────────────────────────┘
```

---

## 🎯 Pane Guide

### Pane 0: Main Work Area (Top-Left) 🚀

**Purpose:** Your primary workspace

**Use for:**
- Running commands
- Coding/editing
- General terminal work
- Whatever you need!

**Navigation:**
- This is where you'll spend most of your time
- Switch here: `Ctrl+a h` (left) or click

**Pro Tips:**
- Split this pane further if needed: `Ctrl+a |` or `Ctrl+a -`
- Zoom this pane: `Ctrl+a z` (toggles full-screen)

---

### Pane 1: GTD Wizard (Bottom-Left) 🧙

**Purpose:** On-demand access to GTD wizard

**How it works:**
1. Click in this pane (or `Ctrl+a j` to move down)
2. Press **Enter**
3. GTD wizard launches!

**Why it's on-demand:**
- Doesn't use resources until you need it
- You choose when to open it
- Leaves main pane free for work

**When to use:**
- Process inbox
- Review tasks/projects
- Check system status
- Any GTD operations

**To get back to work:**
- Exit wizard (press `0`)
- Switch to pane 0: `Ctrl+a h`

---

### Pane 2: Dashboard (Top-Right) 📊

**Purpose:** Live system status

**Shows:**
- Inbox count (items to process)
- Active tasks
- Active projects
- Areas of responsibility
- **Pending suggestions** 💡
- Logging streak
- Today's entries

**Updates:** Every 60 seconds automatically

**What to look for:**
- 📥 Red inbox count = items need processing!
- 💡 Suggestions = AI has recommendations
- 🔥 Logging streak = keep it going!

**When to check:**
- Glance while working
- Before starting work (morning)
- During breaks
- End of day review

---

### Pane 3: Daily Log (Middle-Right) 📝

**Purpose:** Live feed of your daily log entries

**Shows:**
- Real-time log entries as you add them
- Scrolls automatically (`tail -f`)
- Today's activities/notes

**How to add entries:**
```bash
# From any pane:
addInfoToDailyLog "your note here"
```

**What you'll see:**
- Timestamps
- Your entries
- Incidents
- Notes
- Whatever you log!

**Pro Tips:**
- Scroll back: `Ctrl+a [` then arrow keys (press `q` to exit)
- See full log: `gtd-log` in main pane

---

### Pane 4: Advice Monitor (Bottom-Right) 🤖

**Purpose:** Monitor advice worker status

**Shows:**
- Worker status (running/stopped)
- Worker PID
- Queue status
- Recent activity

**Updates:** Every 60 seconds

**What to look for:**
- ✅ Running = worker healthy
- ❌ Not running = restart with `gtd-advice-worker daemon`
- Queue messages = advice being processed

**When to check:**
- After requesting advice
- If advice seems slow
- Troubleshooting

---

## ⌨️ Navigation Cheat Sheet

### Move Between Panes
```
Ctrl+a h/j/k/l    Vim-style (left/down/up/right)
Ctrl+a arrows     Arrow keys
Click             Mouse (enabled!)
```

### Common Actions
```
Ctrl+a z          Zoom/unzoom current pane (full-screen toggle)
Ctrl+a x          Close current pane
Ctrl+a |          Split current pane vertically
Ctrl+a -          Split current pane horizontally
Ctrl+a ?          Show all keybindings
```

### Session Management
```
Ctrl+a d          Detach (keeps running!)
gtd-tmux attach   Reattach later
Ctrl+a r          Reload config
```

---

## 🎮 Typical Workflows

### Morning Startup
1. **Launch:** `gtd-tmux start productivity`
2. **Check dashboard** (pane 2): See inbox, tasks, etc.
3. **Review log** (pane 3): What happened yesterday?
4. **Work in main pane** (pane 0)
5. **Need wizard?** Switch to pane 1, press Enter

### During Work
1. **Work in pane 0** (main area)
2. **Glance at dashboard** (pane 2) - see status at a glance
3. **Log activities:** `addInfoToDailyLog "what I'm doing"`
4. **Watch entries appear** in pane 3
5. **Use wizard** when needed (pane 1)

### End of Day
1. **Review dashboard** (pane 2): What's left?
2. **Check log** (pane 3): What did I accomplish?
3. **Launch wizard** (pane 1): Do review
4. **Detach:** `Ctrl+a d` (keeps session for tomorrow!)

---

## 🔧 Customization Tips

### Adjust Update Intervals

**Dashboard** (currently 60s):
Edit pane 2 in layout script:
```bash
gtd-dashboard --watch --interval 30  # 30 seconds instead
```

**Advice Monitor** (currently 60s):
Edit pane 4:
```bash
watch --color -n 30 "gtd-advice-monitor"  # 30 seconds
```

### Change Pane Sizes

In the layout script, adjust split percentages:
```bash
tmux split-window -h -p 35  # 35% for right side
tmux split-window -v -p 30  # 30% for bottom
```

### Auto-launch Wizard

If you want wizard to start automatically:
```bash
# In pane 1, change from:
read && gtd-wizard

# To:
gtd-wizard
```

---

## 🐛 Troubleshooting

### "Pane 3 (Daily Log) is empty"
**Fix:** Added entries today?
```bash
addInfoToDailyLog "test entry"
```
Should appear immediately in pane 3!

### "Dashboard not updating"
**Check:** Is watch running?
```bash
ps aux | grep "gtd-dashboard --watch"
```

**Restart:** In pane 2, press `Ctrl+C` then:
```bash
gtd-dashboard --watch --interval 60
```

### "Advice monitor shows 'not running'"
**Fix:** Start the worker:
```bash
gtd-advice-worker daemon
```

### "Wizard pane stuck on 'Press Enter'"
**That's normal!** It's waiting for you. Just press Enter when ready.

---

## 💡 Pro Tips

### 1. **Zoom for Focus**
Working on something complex? Zoom the main pane:
```
Ctrl+a z
```
Press again to unzoom.

### 2. **Split Main Pane**
Need side-by-side terminals in main area?
```
Ctrl+a |    (split vertically)
Ctrl+a -    (split horizontally)
```

### 3. **Detach Often**
Leave work for lunch? Detach, not quit:
```
Ctrl+a d
```
Everything keeps running! Reattach anytime:
```
gtd-tmux attach
```

### 4. **Multiple Sessions**
Run different contexts:
```bash
gtd-tmux start productivity  # Work context
tmux new -s personal         # Personal projects
tmux new -s testing          # Experimental stuff
```

Switch between them:
```bash
gtd-tmux list      # See all sessions
gtd-tmux attach    # Reattach to one
```

### 5. **Use the Dashboard**
Don't open wizard just to check status - just look at pane 2!

### 6. **Log Everything**
Quick logging from main pane:
```bash
alias log="addInfoToDailyLog"
log "Fixed bug in authentication"
```
Watch it appear in pane 3!

---

## 📋 Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║  Productivity Layout Quick Reference                      ║
╠═══════════════════════════════════════════════════════════╣
║  PANES                                                    ║
║    0 (top-left)      Main work area                       ║
║    1 (bottom-left)   GTD wizard (press Enter)             ║
║    2 (top-right)     Dashboard (auto-updates)             ║
║    3 (middle-right)  Daily log (live)                     ║
║    4 (bottom-right)  Advice monitor                       ║
║                                                           ║
║  NAVIGATION                                               ║
║    Ctrl+a h/j/k/l    Move between panes                   ║
║    Ctrl+a z          Zoom/unzoom                          ║
║    Ctrl+a d          Detach session                       ║
║                                                           ║
║  QUICK ACTIONS                                            ║
║    addInfoToDailyLog "note"   Log entry                   ║
║    gtd-capture "task"         Capture task                ║
║    gtd-tmux attach            Reattach session            ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 🚀 Next Steps

1. **Try it:** `gtd-tmux start productivity`
2. **Explore:** Click around, try the panes
3. **Launch wizard:** Click pane 1, press Enter
4. **Work:** Use pane 0 for your actual work
5. **Monitor:** Glance at dashboard (pane 2)
6. **Detach:** `Ctrl+a d` when done

**Remember:** It's YOUR workspace - customize it to fit your workflow!

---

**Created:** December 18, 2025  
**Layout:** Productivity Suite  
**Status:** ✅ Ready to use

