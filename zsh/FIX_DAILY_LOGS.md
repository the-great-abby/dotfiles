# Fix: Daily Logs Not Showing in Obsidian

## 🔍 The Problem

You see files in "Daily Logs" folder, but they might not show up well in Obsidian because:
- They're `.txt` files (raw text)
- They're in the wrong format for Obsidian

## ✅ The Solution

Convert your daily logs to formatted Daily Notes that Obsidian can display properly:

```bash
# Sync today's log to create a Daily Note
gtd-brain-sync-daily-logs

# Sync all your daily logs
gtd-brain-sync-daily-logs all
```

## 🎯 Quick Fix (Right Now)

```bash
# Convert all your existing logs to Daily Notes
gtd-brain-sync-daily-logs all
```

This will:
- ✅ Create formatted `.md` files in `Daily Notes/` folder
- ✅ Extract key highlights (goals, workouts, medication, projects)
- ✅ Add proper structure and tags
- ✅ Make them viewable in Obsidian

## 📁 Understanding the Folders

### "Daily Logs" Folder
- Contains raw `.txt` files
- Used for syncing between computers
- Not formatted for Obsidian viewing

### "Daily Notes" Folder  
- Contains formatted `.md` files
- Properly structured for Obsidian
- Shows up beautifully with summaries and highlights

## 🔄 The Two Commands

1. **`gtd-daily-log-sync`** → Syncs `.txt` files to "Daily Logs" (for backup)
2. **`gtd-brain-sync-daily-logs`** → Creates formatted `.md` files in "Daily Notes" (for viewing)

You need **both**, but for viewing in Obsidian, you need the Daily Notes!

## 💡 After Running the Sync

1. **Check Daily Notes folder:**
   ```bash
   ls ~/Documents/obsidian/Second\ Brain/Daily\ Notes/
   ```

2. **Refresh Obsidian:**
   - Close and reopen Obsidian, or
   - Click refresh in the file explorer

3. **You should now see:**
   - Formatted daily notes with summaries
   - Key highlights extracted
   - Full log content
   - Tags and links

## 🚀 Add to Your Workflow

Add this to your evening routine:

```bash
# Your usual logging
addInfoToDailyLog "Ending my day"

# NEW: Create Daily Note from today's log
gtd-brain-sync-daily-logs
```

Now your Daily Notes will always be up to date in Obsidian! 🎉



