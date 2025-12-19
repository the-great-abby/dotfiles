# tmux + GTD Quick Start Guide

**Get productive with tmux in 5 minutes!** 🚀

---

## ⚡ Super Quick Start (Copy-Paste)

```bash
# 1. Copy the GTD tmux config
cp ~/code/dotfiles/tmux/tmux.conf.gtd ~/.tmux.conf

# 2. Start a GTD session
gtd-tmux start monitor

# Done! You're in tmux with GTD dashboard monitoring.
```

**Inside tmux:**
- Switch panes: `Ctrl+a` then arrow keys
- Detach: `Ctrl+a d`
- Help: `Ctrl+a ?`

**To return:** `gtd-tmux attach`

---

## 🎯 4 Ready-to-Use Layouts

### 1. **Monitor** (Recommended) 
```bash
gtd-tmux start monitor
```
- 65% work area | 35% monitoring
- Dashboard (top right) + Advice worker log (bottom right)
- **Best for:** Daily work

### 2. **Minimal**
```bash
gtd-tmux start minimal
```
- 95% work area | 5% status bar
- Compact dashboard updates every 60s
- **Best for:** Focused deep work

### 3. **Command Center**
```bash
gtd-tmux start center
```
- 70% work area | 30% full dashboard
- Live dashboard updates every 30s
- **Best for:** Reviews and planning

### 4. **Productivity Suite**
```bash
gtd-tmux start productivity
```
- 5 panes: Work + Wizard + Dashboard + Log + Monitor
- Complete system visibility
- **Best for:** Power users

---

## 🎮 Essential Commands

### Session Management
```bash
gtd-tmux start [layout]    # Start session
gtd-tmux list              # List sessions
gtd-tmux attach [name]     # Attach to session
gtd-tmux kill [name]       # Kill session
gtd-tmux status            # Check setup
gtd-tmux layouts           # Show layouts
```

### Inside tmux (Ctrl+a is prefix)
```bash
# Navigation
Ctrl+a h/j/k/l     # Move between panes (vim-style)
Ctrl+a arrow keys  # Move between panes (arrows)

# Splitting
Ctrl+a |           # Split vertically
Ctrl+a -           # Split horizontally

# GTD Shortcuts
Ctrl+a g           # Open dashboard (bottom pane)
Ctrl+a G           # Open wizard (right pane)
Ctrl+a t           # Show tasks
Ctrl+a D           # Show daily log
Ctrl+a w           # Advice worker monitor

# Quick Layouts
Ctrl+a M           # Monitor layout
Ctrl+a C           # Command Center layout
Ctrl+a P           # Productivity Suite

# Other
Ctrl+a d           # Detach (session keeps running!)
Ctrl+a x           # Close current pane
Ctrl+a z           # Zoom/unzoom pane
Ctrl+a ?           # Show all keybindings
```

---

## 📅 Typical Workflow

### Morning
```bash
# Start your GTD session
gtd-tmux start monitor

# Check dashboard, process inbox, review tasks
# Work in main pane, monitor in right panes

# Take a break - detach (session keeps running)
Ctrl+a d
```

### Afternoon
```bash
# Resume where you left off
gtd-tmux attach

# Continue working
# Dashboard shows updated stats

# End of day - detach again
Ctrl+a d
```

### Evening
```bash
# Final check
gtd-tmux attach

# Review day, close out
# When done, kill session
Ctrl+a d
gtd-tmux kill gtd-monitor
```

---

## 💡 Pro Tips

### Tip 1: Keep Sessions Running
```bash
# Detach (Ctrl+a d) instead of closing
# Session keeps running in background
# Attach anytime: gtd-tmux attach
```

### Tip 2: Multiple Sessions
```bash
# Create context-specific sessions
gtd-tmux start monitor      # Session: gtd-monitor
tmux new -s work            # Session: work
tmux new -s personal        # Session: personal

# Switch between them
gtd-tmux list
gtd-tmux attach work
```

### Tip 3: Customize Layouts
```bash
# Edit layout scripts in:
~/bin/tmux-layouts/

# Adjust pane sizes, commands, etc.
```

### Tip 4: Status Bar Shows GTD
The tmux status bar at bottom shows:
- Session name (left)
- Compact GTD dashboard (right)
- Current time

Updates every 60 seconds!

### Tip 5: Mouse Support
Our config enables mouse:
- Click to switch panes
- Drag borders to resize
- Scroll with wheel

---

## 🆘 Troubleshooting

### "gtd-tmux: command not found"
```bash
# Make sure it's executable
chmod +x ~/bin/gtd-tmux

# Check if ~/bin is in PATH
echo $PATH | grep "$HOME/bin"
```

### "Layout not found"
```bash
# Check layout scripts exist
ls ~/bin/tmux-layouts/

# Make them executable
chmod +x ~/bin/tmux-layouts/*.sh
```

### "Config not working"
```bash
# Copy GTD config
cp ~/code/dotfiles/tmux/tmux.conf.gtd ~/.tmux.conf

# Reload in tmux
Ctrl+a r
```

### "Colors look weird"
```bash
# Check TERM
echo $TERM

# Should be xterm-256color or similar
# Add to ~/.zshrc if needed:
export TERM=xterm-256color
```

### "Can't see my session"
```bash
# List all sessions
tmux ls

# Attach to specific session
tmux attach -t SESSION_NAME
```

---

## 🎨 Next Steps

Once comfortable:

1. **Read full guide:** `docs/TMUX_GTD_INTEGRATION.md`
2. **Customize config:** Edit `~/.tmux.conf`
3. **Create custom layouts:** Add to `~/bin/tmux-layouts/`
4. **Try plugins:** Install TPM for more features
5. **Share your setup:** Show your team!

---

## 📚 Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║  tmux + GTD Quick Reference                               ║
╠═══════════════════════════════════════════════════════════╣
║  START SESSION                                            ║
║    gtd-tmux start monitor                                 ║
║                                                           ║
║  NAVIGATION (Ctrl+a then...)                              ║
║    h/j/k/l      Move panes (vim)                          ║
║    arrow keys   Move panes                                ║
║    n/p          Next/prev window                          ║
║                                                           ║
║  SPLITTING (Ctrl+a then...)                               ║
║    |            Split vertically                          ║
║    -            Split horizontally                        ║
║                                                           ║
║  GTD (Ctrl+a then...)                                     ║
║    g            Dashboard (bottom)                        ║
║    G            Wizard (right)                            ║
║    t            Tasks                                     ║
║    D            Daily log                                 ║
║                                                           ║
║  SESSION                                                  ║
║    Ctrl+a d     Detach (keeps running)                    ║
║    gtd-tmux attach   Reattach                             ║
║                                                           ║
║  HELP                                                     ║
║    Ctrl+a ?     Show all keybindings                      ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 🎯 One-Line Start

```bash
cp ~/code/dotfiles/tmux/tmux.conf.gtd ~/.tmux.conf && gtd-tmux start monitor
```

**That's it! You're ready to be productive with tmux + GTD!** 🚀

For more details, see: `docs/TMUX_GTD_INTEGRATION.md`

