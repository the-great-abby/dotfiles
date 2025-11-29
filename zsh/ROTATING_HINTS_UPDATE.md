# Rotating Hints & Random Personas - Update Summary

## What's New

### 1. Rotating Hints System ✅
Every 5 commands, you now get:
- **A rotating hint** about available GTD commands
- **Daily log reminder** (if log exists or needs to be started)
- **Inbox count reminder** (if you have unprocessed items)

### 2. Random Persona Selection ✅
When you use `addInfoToDailyLog`, it now:
- **Randomly selects** from all 11 available personas
- **Shows which persona** is giving advice
- **Provides variety** in the advice you receive

## Available Hints (Rotating)

The system cycles through these hints every 5 commands:

1. 💭 Log your thoughts: `addInfoToDailyLog "your entry"`
2. 📥 Quick capture: `gtd-capture "your note"`
3. 📥 Capture a task: `gtd-capture --type=task "your task"`
4. 📋 Process your inbox: Check `~/Documents/gtd/0-inbox/`
5. 🤖 Get advice: `python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py hank "your question"`
6. 🎭 Try different personas: george, john, jon, david, cal, james, marie, warren, sheryl, tim
7. 📝 Daily log location: `~/Documents/daily_logs/`
8. 📁 GTD inbox: `~/Documents/gtd/0-inbox/`
9. 💡 Capture ideas: `gtd-capture --type=idea "your idea"`
10. 🔗 Save links: `gtd-capture --type=link "https://..."`
11. 📞 Log calls: `gtd-capture --type=call "call notes"`
12. 📧 Capture email actions: `gtd-capture --type=email "email action"`
13. 🎯 Get GTD advice: `python3 .../gtd_persona_helper.py david "help with organization"`
14. 🧠 Deep work advice: `python3 .../gtd_persona_helper.py cal "help with focus"`
15. 📊 Habit advice: `python3 .../gtd_persona_helper.py james "build a habit"`
16. 😄 Satirical take: `python3 .../gtd_persona_helper.py george "your situation"`
17. 🇬🇧 Witty analysis: `python3 .../gtd_persona_helper.py john "your question"`
18. 🎤 Sharp insights: `python3 .../gtd_persona_helper.py jon "review this"`

## Example Output

Every 5 commands, you'll see something like:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 📥 Quick capture: gtd-capture "your note"
💭 Daily log active - add more: addInfoToDailyLog "your entry"
📥 Inbox has 3 item(s) - process them from: ~/Documents/gtd/0-inbox
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Random Personas

When you run `addInfoToDailyLog "your entry"`, you'll get advice from a randomly selected persona:

**Productivity Experts:**
- Hank Hill (general productivity)
- David Allen (GTD methodology)
- Cal Newport (deep work)
- James Clear (habits)
- Marie Kondo (organization)
- Warren Buffett (strategy)
- Sheryl Sandberg (execution)
- Tim Ferriss (optimization)

**Comedians:**
- George Carlin (satirical critique)
- John Oliver (witty analysis)
- Jon Stewart (satirical insight)

## How It Works

### Hints System
- Uses zsh's `precmd` hook (runs before each prompt)
- Tracks command count with `_daily_log_cmd_count`
- Shows reminder every 5 commands
- Rotates through hints based on command count
- Checks inbox count automatically

### Persona Selection
- Randomly selects from all 11 personas
- Uses `$RANDOM` for selection
- Falls back to old helper if persona helper not found
- Shows persona name in output

## Customization

### Add More Hints
Edit `zshrc_mac_mise` and add to the `_GTD_HINTS` array:

```bash
_GTD_HINTS=(
  "💭 Log your thoughts: addInfoToDailyLog \"your entry\""
  "📥 Quick capture: gtd-capture \"your note\""
  # Add your custom hint here
)
```

### Change Reminder Frequency
Change the `% 5` to a different number:

```bash
if (( _daily_log_cmd_count % 10 == 0 )); then  # Every 10 commands
```

### Disable Hints
Comment out the hook:

```bash
# add-zsh-hook precmd _daily_log_command_counter
```

## Testing

1. **Test hints**: Run 5 commands, you should see a hint
2. **Test persona**: Run `addInfoToDailyLog "test"` multiple times, you should see different personas
3. **Test inbox count**: Create files in `~/Documents/gtd/0-inbox/` and see the count appear

## Notes

- Hints rotate based on command count (not random, but predictable)
- Personas are truly random each time
- Inbox count only shows if GTD directory exists
- All hints are helpful reminders, not intrusive



