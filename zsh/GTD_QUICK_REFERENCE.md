# GTD Quick Reference Card

## 🚀 Daily Commands

```bash
# Morning
gtd-log                    # View today's log
gtd-process               # Process inbox
gtd-review daily          # Daily review
gtd-task list             # See tasks

# Capture
gtd-capture "..."         # Quick capture
addInfoToDailyLog "..."   # Log entry + advice

# Work
gtd-task list --context=computer
gtd-task complete <id>    # Complete task

# Evening
addInfoToDailyLog "..."   # End of day log
gtd-process               # Clear inbox
```

## 📅 Weekly Commands

```bash
gtd-review weekly         # Weekly review
gtd-brain-sync            # Sync with Second Brain
gtd-advise --all          # Get advice from all personas
```

## 🎯 Most Used Commands

| Command | What It Does |
|---------|-------------|
| `gtd-capture "..."` | Capture anything to inbox |
| `gtd-process` | Process inbox items |
| `gtd-task list` | List all tasks |
| `gtd-task complete <id>` | Complete a task |
| `addInfoToDailyLog "..."` | Log entry + get advice |
| `gtd-review weekly` | Weekly review |
| `gtd-advise <persona> "..."` | Get advice |

## 🧠 Second Brain

```bash
gtd-brain create "Title" Projects
gtd-brain link <gtd-item> <brain-note>
gtd-brain search "query"
gtd-brain-discover connections <note>
gtd-brain-sync
```

## 💬 Get Advice

```bash
gtd-advise david    # GTD methodology
gtd-advise cal      # Deep work
gtd-advise james    # Habits
gtd-advise warren   # Strategy
gtd-advise louiza   # Accountability
gtd-advise fred     # Self-care
gtd-advise bob      # Creativity
```

## 📋 Task Filters

```bash
gtd-task list --context=home
gtd-task list --energy=low
gtd-task list --priority=urgent_important
gtd-task list --project=myproject
```

## 🔔 Notifications

```bash
gtd-notify "Title" "Message"
gtd-notify inbox 5
gtd-notify complete "Task"
```

## 🎯 The GTD Flow

```
Capture → Process → Organize → Review
   ↓         ↓          ↓         ↓
gtd-capture gtd-process auto    gtd-review
```

## ⚡ Quick Aliases (Add to .zshrc)

```bash
alias c="gtd-capture"
alias tasks="gtd-task list"
alias gtd-daily="gtd-review daily"
alias gtd-weekly="gtd-review weekly"
alias gtd-morning="gtd-log && gtd-process && gtd-review daily"
```

## 📊 Check Status

```bash
gtd-process              # Shows inbox count
gtd-task list            # Shows active tasks
gtd-project list         # Shows projects
gtd-brain-discover stats # Second Brain stats
```

## 🆘 When Stuck

```bash
gtd-advise david "Help me get organized"
gtd-review weekly        # Start fresh
gtd-process --all        # Clear inbox
```

## 🎓 Remember

1. **Capture everything** - `gtd-capture`
2. **Process daily** - `gtd-process`
3. **Review weekly** - `gtd-review weekly`
4. **Get advice** - `gtd-advise <persona>`
5. **Log daily** - `addInfoToDailyLog`

---

**Full guide:** See `HOW_TO_USE_GTD_EFFECTIVELY.md`

