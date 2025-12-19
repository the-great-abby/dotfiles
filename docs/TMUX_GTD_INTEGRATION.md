# tmux + GTD Integration Guide

**Created:** December 18, 2025  
**Purpose:** Integrate your GTD system with tmux for ultimate productivity

---

## 🎯 Why tmux + GTD?

**tmux** (terminal multiplexer) lets you:
- Split your terminal into multiple panes
- Keep processes running when you disconnect
- Save and restore workspace layouts
- Monitor multiple things at once

**Perfect for GTD because:**
- 👁️ Keep GTD dashboard visible while you work
- 🔄 Monitor background workers (advice, vectorization)
- 📊 See your status at a glance
- 🎯 Maintain focus with dedicated spaces

---

## 🚀 Quick Start (5 Minutes)

### 1. Install tmux (if not already installed)

```bash
# macOS
brew install tmux

# Verify installation
tmux -V
```

### 2. Create Basic tmux Config

```bash
# Create config file
touch ~/.tmux.conf

# Add basic settings
cat >> ~/.tmux.conf << 'EOF'
# Make tmux colors work properly
set -g default-terminal "screen-256color"

# Enable mouse support (click to switch panes, resize, etc)
set -g mouse on

# Start window numbering at 1 (easier to reach)
set -g base-index 1

# Use vim keybindings
setw -g mode-keys vi

# Make Escape key work faster in vim
set -sg escape-time 0

# Increase scrollback buffer
set -g history-limit 10000
EOF
```

### 3. Start Your First Session

```bash
# Start tmux with a session name
tmux new -s gtd

# Inside tmux:
# - Split horizontally: Ctrl+b then "
# - Split vertically: Ctrl+b then %
# - Switch panes: Ctrl+b then arrow keys
# - Detach: Ctrl+b then d
# - Reattach: tmux attach -t gtd
```

---

## 📐 GTD Layout Examples

### Layout 1: "The Command Center"

**Perfect for:** Overview mode, daily reviews, quick checks

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              Main Work Area                         │
│         (your editor, commands, etc)                │
│                                                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│         📊 gtd-dashboard --watch                    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Setup:**
```bash
# Start session
tmux new -s gtd-center

# Split horizontally (Ctrl+b then ")
# Then in bottom pane:
gtd-dashboard --watch --interval 30

# Switch back to top pane (Ctrl+b then up arrow)
# Work normally
```

**tmux Script:** `~/gtd-center-layout.sh`
```bash
#!/bin/bash
tmux new-session -d -s gtd-center
tmux split-window -v -p 30
tmux send-keys -t 1 'gtd-dashboard --watch --interval 30' C-m
tmux select-pane -t 0
tmux attach -t gtd-center
```

---

### Layout 2: "The Monitor"

**Perfect for:** Watching background workers, debugging

```
┌──────────────────────┬──────────────────────────────┐
│                      │                              │
│                      │   📊 gtd-dashboard           │
│   Main Work Area     │                              │
│                      ├──────────────────────────────┤
│                      │                              │
│                      │   🐰 Advice Worker Log       │
│                      │   tail -f advice-worker.log  │
│                      │                              │
└──────────────────────┴──────────────────────────────┘
```

**Setup Script:** `~/gtd-monitor-layout.sh`
```bash
#!/bin/bash
SESSION="gtd-monitor"

tmux new-session -d -s $SESSION

# Main window
tmux rename-window -t $SESSION:0 'work'

# Split vertically (right side for monitoring)
tmux split-window -h -p 35

# Split right pane horizontally
tmux select-pane -t 1
tmux split-window -v

# Top right: dashboard (watch mode)
tmux select-pane -t 1
tmux send-keys 'gtd-dashboard --watch' C-m

# Bottom right: advice worker log
tmux select-pane -t 2
tmux send-keys 'tail -f /private/tmp/advice-worker.log' C-m

# Focus on main work pane
tmux select-pane -t 0

# Attach to session
tmux attach -t $SESSION
```

---

### Layout 3: "The Productivity Suite"

**Perfect for:** Deep work sessions, GTD processing

```
┌──────────────────────┬──────────────────────────────┐
│                      │                              │
│                      │   📊 Dashboard               │
│   Main Work          │                              │
│   (editor/coding)    ├──────────────────────────────┤
│                      │                              │
│                      │   📝 Daily Log               │
├──────────────────────┤   (auto-updating)            │
│                      │                              │
│   🎯 GTD Wizard      ├──────────────────────────────┤
│   (quick access)     │                              │
│                      │   🧠 Advice Queue Monitor    │
└──────────────────────┴──────────────────────────────┘
```

**Setup Script:** `~/gtd-productivity-layout.sh`
```bash
#!/bin/bash
SESSION="gtd-suite"

tmux new-session -d -s $SESSION

# Create layout
tmux split-window -h -p 35      # Split right 35%
tmux select-pane -t 1
tmux split-window -v            # Split right pane in half
tmux split-window -v            # Split bottom-right in half
tmux select-pane -t 0
tmux split-window -v -p 30      # Split left pane, bottom 30%

# Now we have 5 panes:
# Pane 0: Top-left (main work)
# Pane 1: Bottom-left (gtd-wizard)
# Pane 2: Top-right (dashboard)
# Pane 3: Middle-right (daily log)
# Pane 4: Bottom-right (advice monitor)

# Set up each pane
tmux select-pane -t 0
tmux send-keys 'cd ~/Documents/gtd && clear' C-m

tmux select-pane -t 1
tmux send-keys 'gtd-wizard' C-m

tmux select-pane -t 2
tmux send-keys 'gtd-dashboard --watch --interval 60' C-m

tmux select-pane -t 3
tmux send-keys 'tail -f ~/Documents/gtd/$(date +%Y-%m-%d).md' C-m

tmux select-pane -t 4
tmux send-keys 'gtd-advice-monitor' C-m
tmux send-keys 'watch -n 60 gtd-advice-monitor' C-m

# Focus on main work pane
tmux select-pane -t 0

tmux attach -t $SESSION
```

---

### Layout 4: "The Minimal"

**Perfect for:** Focused work with just a glance

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                                                     │
│              Main Work Area                         │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│─────────────────────────────────────────────────────│
│ 🎯 GTD 2025-12-18 | 📥 0 | ✅ 83 | 📁 7 | 🎯 9     │
└─────────────────────────────────────────────────────┘
```

**Setup Script:** `~/gtd-minimal-layout.sh`
```bash
#!/bin/bash
SESSION="gtd-minimal"

tmux new-session -d -s $SESSION
tmux split-window -v -p 5  # Just 5% for status
tmux send-keys -t 1 'watch -n 60 "gtd-dashboard --compact"' C-m
tmux select-pane -t 0
tmux attach -t $SESSION
```

---

## 🎨 Enhanced tmux Configuration for GTD

Add this to your `~/.tmux.conf`:

```bash
# ============================================================================
# GTD-Optimized tmux Configuration
# ============================================================================

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

# True color support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Enable mouse (click, scroll, resize)
set -g mouse on

# Start window/pane numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback
set -g history-limit 50000

# Faster escape (better for vim)
set -sg escape-time 0

# Enable focus events for vim
set -g focus-events on

# -----------------------------------------------------------------------------
# Key Bindings
# -----------------------------------------------------------------------------

# Remap prefix to Ctrl+a (easier to reach than Ctrl+b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Split panes with | and - (more intuitive)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes with Vim keys
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Quick pane cycling
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# -----------------------------------------------------------------------------
# GTD-Specific Key Bindings
# -----------------------------------------------------------------------------

# Ctrl+a, g - Quick GTD dashboard
bind g split-window -v -p 30 'gtd-dashboard --watch'

# Ctrl+a, G - GTD wizard
bind G split-window -h 'gtd-wizard'

# Ctrl+a, w - Show advice worker monitor
bind w split-window -v 'gtd-advice-monitor'

# Ctrl+a, d - Show daily log
bind D split-window -h "tail -f ~/Documents/gtd/$(date +%Y-%m-%d).md"

# Ctrl+a, c - Quick capture
bind C command-prompt -p "Quick capture:" "split-window -v 'gtd-capture \"%1\"'"

# -----------------------------------------------------------------------------
# Status Bar (with GTD info)
# -----------------------------------------------------------------------------

# Update status bar frequently
set -g status-interval 60

# Status bar colors
set -g status-style bg=colour235,fg=colour255

# Left side: session name
set -g status-left-length 40
set -g status-left "#[fg=green,bold]#S #[fg=yellow]| "

# Right side: GTD compact status + time
set -g status-right-length 100
set -g status-right "#(gtd-dashboard --compact 2>/dev/null || echo '🎯 GTD') | %H:%M %d-%b"

# Window status
set -g window-status-format " #I:#W "
set -g window-status-current-format " #[fg=black,bg=green,bold]#I:#W "

# Pane border colors
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=green

# Message colors
set -g message-style bg=colour235,fg=colour255,bold

# -----------------------------------------------------------------------------
# GTD Layouts (Saved Sessions)
# -----------------------------------------------------------------------------

# Create GTD workspace layout on startup (optional)
# Uncomment to auto-create GTD session:
# new-session -s gtd -n work
# split-window -h -p 30
# send-keys -t 1 'gtd-dashboard --watch' C-m
# select-pane -t 0

# -----------------------------------------------------------------------------
# Copy Mode (Vim-like)
# -----------------------------------------------------------------------------

setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# macOS clipboard integration
if-shell "uname | grep -q Darwin" \
  'bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"'

# -----------------------------------------------------------------------------
# Visual Improvements
# -----------------------------------------------------------------------------

# Show pane numbers longer
set -g display-panes-time 2000

# Show messages longer
set -g display-time 4000

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off

# -----------------------------------------------------------------------------
# Plugins (optional - install TPM first)
# -----------------------------------------------------------------------------

# To use plugins, install TPM:
# git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Then add these lines and press Ctrl+a, I to install:
# set -g @plugin 'tmux-plugins/tpm'
# set -g @plugin 'tmux-plugins/tmux-sensible'
# set -g @plugin 'tmux-plugins/tmux-resurrect'  # Save/restore sessions
# set -g @plugin 'tmux-plugins/tmux-continuum'  # Auto-save sessions

# Initialize plugin manager (keep at bottom)
# run '~/.tmux/plugins/tpm/tpm'
```

---

## 🎮 Quick tmux Cheat Sheet

### Basic Commands

```bash
# Session management
tmux new -s gtd              # Create new session named "gtd"
tmux attach -t gtd           # Attach to session "gtd"
tmux ls                      # List sessions
tmux kill-session -t gtd     # Kill session "gtd"

# Inside tmux (Ctrl+a = prefix)
Ctrl+a d        # Detach from session
Ctrl+a c        # Create new window
Ctrl+a n/p      # Next/previous window
Ctrl+a 0-9      # Switch to window by number
Ctrl+a ,        # Rename current window
```

### Pane Management (with our config)

```bash
Ctrl+a |        # Split vertically
Ctrl+a -        # Split horizontally
Ctrl+a h/j/k/l  # Navigate panes (vim-style)
Ctrl+a H/J/K/L  # Resize panes
Ctrl+a x        # Close current pane
Ctrl+a z        # Zoom/unzoom pane (full screen toggle)
```

### GTD-Specific (custom bindings)

```bash
Ctrl+a g        # Show GTD dashboard in bottom pane
Ctrl+a G        # Open GTD wizard in right pane
Ctrl+a w        # Show advice worker monitor
Ctrl+a D        # Show daily log
Ctrl+a C        # Quick capture (prompts for input)
```

---

## 🚀 Getting Started: Your First GTD Session

### Step 1: Install and configure

```bash
# Install tmux
brew install tmux

# Create starter config
curl -o ~/.tmux.conf https://raw.githubusercontent.com/YOUR_REPO/dotfiles/main/tmux/tmux.conf
# Or use the config above
```

### Step 2: Create your layout scripts

```bash
# Make scripts directory
mkdir -p ~/bin/tmux-layouts

# Save one of the layout scripts above
# I recommend starting with "The Monitor"
vim ~/bin/tmux-layouts/gtd-monitor.sh
chmod +x ~/bin/tmux-layouts/gtd-monitor.sh
```

### Step 3: Launch!

```bash
# Start your GTD session
~/bin/tmux-layouts/gtd-monitor.sh

# Or for minimal:
tmux new -s gtd
gtd-dashboard
```

### Step 4: Daily workflow

```bash
# Morning
~/bin/tmux-layouts/gtd-monitor.sh
# Do your work, check dashboard occasionally

# Detach (keeps running)
Ctrl+a d

# Later: reattach
tmux attach -t gtd-monitor

# Evening: close
Ctrl+a d
tmux kill-session -t gtd-monitor
```

---

## 💡 Pro Tips

### 1. **Name Your Sessions by Context**

```bash
tmux new -s gtd-work      # Work context
tmux new -s gtd-personal  # Personal context
tmux new -s gtd-review    # Review mode
```

### 2. **Use Pane Titles**

```bash
# In any pane, set a title
printf '\033]2;%s\033\\' 'Dashboard'
```

### 3. **Auto-start with your Shell**

Add to `~/.zshrc`:

```bash
# Auto-attach or create GTD session
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    # Check if already in tmux
    if [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]]; then
        # Attach to existing session or create new
        tmux attach -t gtd 2>/dev/null || ~/bin/tmux-layouts/gtd-monitor.sh
    fi
fi
```

### 4. **Script Common Workflows**

```bash
# ~/bin/gtd-morning
#!/bin/bash
tmux new -s morning -d
tmux send-keys 'gtd-dashboard' C-m
tmux split-window -h
tmux send-keys 'gtd-review daily' C-m
tmux attach
```

### 5. **Use Status Bar for Motivation**

Add to `~/.tmux.conf`:

```bash
set -g status-right "🎯 $(gtd-dashboard --compact | grep -o '✅ [0-9]*') tasks | %H:%M"
```

---

## 🎨 Color Schemes

### Catppuccin (Modern & Calm)

```bash
# Add to ~/.tmux.conf
set -g status-style bg='#1e1e2e',fg='#cdd6f4'
set -g pane-border-style fg='#45475a'
set -g pane-active-border-style fg='#89b4fa'
```

### Gruvbox (Warm & Retro)

```bash
set -g status-style bg='#282828',fg='#ebdbb2'
set -g pane-border-style fg='#504945'
set -g pane-active-border-style fg='#b8bb26'
```

### Nord (Cool & Professional)

```bash
set -g status-style bg='#2e3440',fg='#d8dee9'
set -g pane-border-style fg='#4c566a'
set -g pane-active-border-style fg='#88c0d0'
```

---

## 🔧 Troubleshooting

### Colors look wrong

```bash
# In ~/.tmux.conf
set -g default-terminal "screen-256color"

# In ~/.zshrc or ~/.bashrc
export TERM=xterm-256color
```

### Mouse doesn't work

```bash
# Add to ~/.tmux.conf
set -g mouse on
```

### Dashboard not updating

```bash
# Increase update interval
set -g status-interval 60

# Or in the watch command
gtd-dashboard --watch --interval 30
```

### Panes too small

```bash
# Resize with prefix + H/J/K/L
# Or adjust percentage in layout script
tmux split-window -v -p 40  # 40% height
```

---

## 📚 Further Learning

### Official Resources
- [tmux GitHub](https://github.com/tmux/tmux)
- [tmux man page](https://man.openbsd.org/tmux.1)
- [Awesome tmux](https://github.com/rothgar/awesome-tmux)

### Recommended Plugins
- **TPM** - Plugin manager
- **tmux-resurrect** - Save/restore sessions
- **tmux-continuum** - Auto-save sessions
- **tmux-yank** - Better copy/paste

### GTD-Specific Scripts

All layout scripts mentioned here can be created in:
`~/bin/tmux-layouts/`

Make them executable:
```bash
chmod +x ~/bin/tmux-layouts/*.sh
```

---

## 🎯 Summary

**Start Simple:**
1. Install tmux
2. Use basic config
3. Try "The Monitor" layout
4. Get comfortable with pane navigation

**Level Up:**
1. Add custom key bindings
2. Create your own layouts
3. Integrate with your workflow
4. Automate session creation

**Pro Level:**
1. Session management scripts
2. Context-based layouts
3. Automatic reconnection
4. Integration with other tools

---

**Your GTD system + tmux = Productivity Superpower! 🚀**

Ready to start? Try:
```bash
# Install
brew install tmux

# Quick test
tmux new -s test
gtd-dashboard --watch
# Ctrl+a d to detach
# tmux attach -t test to reattach
```

Questions? Check `gtd-help` or the tmux manual!

