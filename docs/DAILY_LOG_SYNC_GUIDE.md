# Daily Log Sync with Second Brain

## ✅ Yes! Daily Logs Now Sync with Second Brain

Your daily logs can now be synced to your Second Brain, creating daily notes that integrate with your knowledge base.

## 🔄 How It Works

### Automatic Sync

When `GTD_SYNC_DAILY_LOGS="true"` in your `.gtd_config`:
- Daily logs are automatically synced when you run `gtd-brain-sync`
- Creates daily notes in `Second Brain/Daily Notes/`
- Extracts key highlights automatically
- Links back to original log files

### Manual Sync

You can also sync manually:

```bash
# Sync today's log
gtd-brain-sync-daily-logs

# Sync specific date
gtd-brain-sync-daily-logs 2025-11-30

# Sync all logs
gtd-brain-sync-daily-logs all
```

## 📊 What Gets Synced

### Daily Note Structure

Each synced daily log creates a note in `Second Brain/Daily Notes/` with:

1. **Summary**
   - Total entry count
   - Link to original log file

2. **Key Highlights** (automatically extracted)
   - **Goals** - Entries mentioning goals
   - **Workouts** - Exercise, kettlebells, walks, runs, weight lifting
   - **Medication** - Pills, medication mentions
   - **Projects** - Project-related entries

3. **Full Log**
   - Complete daily log content
   - Preserved in code block

4. **Notes Section**
   - Space for your reflections
   - Connections to other notes

5. **Tags**
   - `#daily-note`
   - Date tag

## 🔗 Linking Daily Logs to Other Notes

You can link daily logs to projects, areas, or other notes:

```bash
# Link today's log to a project
gtd-brain-sync-daily-logs link 2025-11-30 ~/Documents/obsidian/Second\ Brain/Projects/my-project.md

# This creates bidirectional links:
# - Daily note → Project note
# - Project note → Daily note
```

## 📝 Example Daily Note

After syncing, a daily note looks like:

```markdown
# Daily Note - 2025-11-30

Created: 2025-11-30 17:30
Type: Daily Note
Source: Daily Log

## Daily Log Sync

Synced from daily log: 2025-11-30 17:30

### Summary
- Total entries: 5
- Log file: [[Daily Log: 2025-11-30]] → ~/Documents/daily_logs/2025-11-30.txt

### Key Highlights

#### Goals
  - 05:14 - Goals: Go for a walk, clean bedroom

#### Workouts
  - 10:30 - Did kettlebell workout: swings and Turkish get-ups

#### Medication
  - 08:00 - Took pills

#### Projects
  - 14:00 - Working on website redesign project

### Full Log
```
05:14 - Goals: Go for a walk, clean bedroom
08:00 - Took pills
10:30 - Did kettlebell workout: swings and Turkish get-ups
14:00 - Working on website redesign project
17:00 - Completed task: Review design mockups
```

## Notes

<!-- Add your reflections, insights, and connections here -->

## Tags
#daily-note #2025-11-30
```

## ⚙️ Configuration

### Enable/Disable Sync

In your `.gtd_config`:

```bash
# Sync daily logs to Second Brain (true/false)
GTD_SYNC_DAILY_LOGS="true"  # Set to false to disable
```

### Integration with gtd-brain-sync

When enabled, daily logs are synced as part of the full sync:

```bash
# Full sync (includes daily logs if enabled)
gtd-brain-sync

# Or sync just daily logs
gtd-brain-sync daily-logs
```

## 🎯 Use Cases

### 1. Weekly Review Integration

During weekly review, you can:
- Review daily notes in Second Brain
- See patterns across days
- Connect daily activities to projects
- Track progress over time

### 2. Project Tracking

Link daily logs to projects:
```bash
# Link today's log to active project
gtd-brain-sync-daily-logs link $(date +%Y-%m-%d) ~/Documents/obsidian/Second\ Brain/Projects/current-project.md
```

### 3. Pattern Discovery

Use Second Brain search to find patterns:
- Search for workout entries across all daily notes
- Find when you worked on specific projects
- Track medication compliance
- Discover goal patterns

### 4. Knowledge Building

Daily notes become part of your knowledge base:
- Mark important days as evergreen
- Create MOCs for recurring themes
- Connect daily activities to areas of responsibility
- Build understanding over time

## 🔍 Finding Daily Notes

### In Obsidian

Daily notes are in:
```
Second Brain/Daily Notes/
```

### Via Command

```bash
# List daily notes
ls ~/Documents/obsidian/Second\ Brain/Daily\ Notes/

# Search daily notes
gtd-brain search "workout" Daily\ Notes
```

## 💡 Best Practices

1. **Sync Regularly**
   - Run `gtd-brain-sync-daily-logs all` weekly
   - Or enable auto-sync in `gtd-brain-sync`

2. **Link to Projects**
   - Link daily logs to active projects
   - Track project work over time

3. **Add Reflections**
   - Use the Notes section in daily notes
   - Connect insights to other notes

4. **Create MOCs**
   - Create MOCs for recurring themes
   - Link daily notes to relevant MOCs

5. **Review Patterns**
   - Use weekly review to review daily notes
   - Identify patterns and insights

## 🔄 Workflow Integration

### Daily Workflow

```bash
# 1. Add to daily log
addInfoToDailyLog "Working on project X"

# 2. Sync to Second Brain (optional, can be automatic)
gtd-brain-sync-daily-logs

# 3. Link to project
gtd-brain-sync-daily-logs link $(date +%Y-%m-%d) ~/Documents/obsidian/Second\ Brain/Projects/project-x.md
```

### Weekly Review

```bash
# 1. Sync all daily logs
gtd-brain-sync-daily-logs all

# 2. Review in Second Brain
# Open: ~/Documents/obsidian/Second Brain/Daily Notes/

# 3. Create connections
# Link daily notes to projects, areas, MOCs
```

## 📊 Current Status

**Your daily logs:**
- Location: `~/Documents/daily_logs/`
- Total logs: 3
- Synced: Can sync all with `gtd-brain-sync-daily-logs all`

**Daily notes will be created in:**
- `~/Documents/obsidian/Second Brain/Daily Notes/`

## 🚀 Quick Start

```bash
# Sync all your existing daily logs
gtd-brain-sync-daily-logs all

# View synced notes
ls ~/Documents/obsidian/Second\ Brain/Daily\ Notes/

# Open in Obsidian to see the integration!
```

Your daily logs are now fully integrated with your Second Brain! 🎉

