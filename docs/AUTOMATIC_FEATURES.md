# What Happens Automatically in Your GTD System

## ✅ Automatic Features (Currently Active)

### 1. Daily Log Reminders (Every 5 Commands)
**Location**: `zshrc_mac_mise` lines 80-104

**What happens**:
- After every 5 commands you run in your terminal, you get a friendly reminder
- If you have a daily log file: "💭 Friendly reminder: Don't forget to log your thoughts..."
- If you don't have one: "📝 Hey there! Remember to start your daily log..."

**How it works**:
- Uses zsh's `precmd` hook (runs before each prompt)
- Tracks command count with `_daily_log_cmd_count`
- Shows reminder when count is divisible by 5

**Example**:
```bash
$ ls
$ cd ~
$ pwd
$ echo "test"
$ git status
# After 5th command, you'll see:
💭 Friendly reminder: Don't forget to log your thoughts with: addInfoToDailyLog "your entry"
```

### 2. Automatic Advice When Logging
**Location**: `zshrc_mac_mise` lines 265-369

**What happens**:
When you run `addInfoToDailyLog "your entry"`:
1. ✅ Automatically creates log directory if it doesn't exist
2. ✅ Automatically creates daily log file if it doesn't exist
3. ✅ Automatically appends your entry with timestamp
4. ✅ Automatically calls LM Studio for advice (if helper script found)
5. ✅ Automatically uses default persona (Hank) from `lmstudio_helper.py`

**What you need to do manually**:
- Load a model in LM Studio (see `LM_STUDIO_SETUP.md`)
- Make sure LM Studio server is running

## ❌ What Does NOT Happen Automatically

### Things You Need to Do Manually:

1. **Download Models in LM Studio**
   - Open LM Studio → Search tab → Download model
   - See `LM_STUDIO_SETUP.md` for detailed instructions

2. **Load Models**
   - After downloading, go to Chat tab → Click model → Click "Load"
   - Model must be loaded before advice will work

3. **Start LM Studio Server**
   - Go to Server tab → Make sure it's running
   - Default port is 1234 (matches your config)

4. **Process Inbox Items**
   - `gtd-capture` puts items in inbox
   - You need to manually process them (future: `gtd-process` command)

5. **Weekly Reviews**
   - Not automated yet (future feature)

## 🔄 Future Automatic Features (Not Yet Implemented)

These are planned but not yet built:

1. **Auto-categorization** - AI suggests category/project/area when capturing
2. **Auto-tagging** - Based on keywords in capture
3. **Scheduled reviews** - Automatic daily/weekly review reminders
4. **Context suggestions** - AI suggests best task based on time/energy
5. **Dependency detection** - Auto-detect blocked tasks
6. **Calendar sync** - Auto-sync tasks with calendar

## 📝 Current Workflow

### What's Automatic:
```
You run command → Counter increments → Every 5 commands → Reminder shows
```

```
You run addInfoToDailyLog → Entry saved → LM Studio called → Advice shown
```

### What's Manual:
```
You think of something → Run gtd-capture → Item in inbox → You process it
```

```
You want advice → Run persona helper → Get advice
```

## 🎯 Quick Reference

| Feature | Automatic? | Location |
|---------|-----------|----------|
| Daily log reminders | ✅ Yes (every 5 commands) | `zshrc_mac_mise:80-104` |
| Advice when logging | ✅ Yes (if LM Studio ready) | `zshrc_mac_mise:265-369` |
| Model downloading | ❌ No (manual in LM Studio) | LM Studio app |
| Model loading | ❌ No (manual in LM Studio) | LM Studio app |
| Inbox processing | ❌ No (future: `gtd-process`) | Not yet built |
| Weekly reviews | ❌ No (future feature) | Not yet built |

## 💡 Tips

1. **The reminder is helpful** - It keeps daily logging top of mind
2. **Advice is automatic** - Once LM Studio is set up, advice happens automatically
3. **You control when to capture** - `gtd-capture` is manual (by design)
4. **Processing is manual** - GTD methodology requires you to make decisions

## 🐛 Troubleshooting

### Reminder not showing?
- Check that `zshrc_mac_mise` is being sourced
- Check that `add-zsh-hook precmd` is working
- Restart your terminal

### Advice not working?
- Check LM Studio is running
- Check model is loaded
- Check server is running
- See `LM_STUDIO_SETUP.md` for details



