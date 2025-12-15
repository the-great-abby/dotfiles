# Bidirectional Obsidian Sync - Implementation Guide

## 🎯 Overview

True bidirectional sync between your GTD system and Obsidian Second Brain. Detects changes made in Obsidian (mobile/other computers), merges conflicts intelligently, and syncs metadata - even when there's no local daily log file!

## ✅ Features Implemented

### 1. **Detect Changes Made in Obsidian**

Automatically detects:
- Daily Notes modified in Obsidian (mobile/other computers)
- Zettelkasten notes with changes
- New notes created in Obsidian
- Files missing local counterparts

**Key Feature**: Works even when there's no local daily log file - it will extract and create one!

### 2. **Merge Strategy for Conflicts**

Intelligent conflict resolution:
- **Daily Logs**: Merges time-stamped entries from both sources
- **Other Files**: Uses newer timestamp by default
- **Manual Review**: Flags conflicts for manual resolution
- **Preserves Data**: Never loses information

### 3. **Sync Metadata (Tags, Links, Status)**

Tracks and syncs:
- Tags (`#tags`)
- Internal links (`[[links]]`)
- Frontmatter metadata (status, created dates, etc.)
- File modification timestamps

### 4. **Timestamp Tracking**

- Tracks modification times for all files
- Identifies source of truth (which version is newer)
- Stores sync metadata in `~/.gtd_brain_sync_metadata.json`
- Remembers last sync time

## 🔧 How It Solves Your Issue

**Problem**: Changes made in Obsidian on mobile don't get pulled to your computer if there's no local daily log file.

**Solution**: The bidirectional sync now:
1. Scans all Daily Notes in Obsidian (regardless of local files)
2. Extracts log content from Daily Notes even if no local log exists
3. Creates local log files automatically
4. Merges intelligently when both exist

## 🚀 Usage

### Via Wizard (Recommended)

```bash
gtd-wizard
# Select: 57) Bidirectional Obsidian Sync
```

**Options:**
- **1) Full bidirectional sync** - Detect and sync all changes
- **2) Sync daily logs only** - Pull daily logs from Obsidian
- **3) Detect changes** - Check what changed (last N days)
- **4) Show sync status** - Current sync state
- **5) Resolve conflicts** - Handle conflicts manually

### Via Command Line

#### Full Sync (Recommended)
```bash
gtd-brain-bidirectional-sync
# or
gtd-brain-bidirectional-sync sync
```

This will:
- Detect all changes in Obsidian
- Pull Daily Notes that don't have local logs
- Merge conflicts intelligently
- Update sync metadata

#### Sync Daily Logs Only
```bash
gtd-brain-bidirectional-sync sync-daily-logs
```

Pulls daily logs from Obsidian Daily Notes, even if no local log exists.

#### Detect Changes
```bash
gtd-brain-bidirectional-sync detect-changes [days]
```

Shows what changed in Obsidian:
```bash
gtd-brain-bidirectional-sync detect-changes 7   # Last 7 days
gtd-brain-bidirectional-sync detect-changes 30  # Last 30 days
```

#### Check Status
```bash
gtd-brain-bidirectional-sync status
```

Shows:
- Last sync time
- Local vs Obsidian file counts
- Pending changes
- Conflicts needing resolution

## 📋 How It Works

### Daily Log Sync Process

1. **Scan Obsidian Daily Notes**
   - Finds all `.md` files in `Second Brain/Daily Notes/`
   - Compares modification times with sync metadata
   - Identifies notes modified in Obsidian

2. **Check for Local Logs**
   - For each Daily Note, checks if local log exists
   - **If no local log exists**: Extracts content from Daily Note and creates local log
   - **If both exist**: Compares timestamps and merges if needed

3. **Extract Log Content**
   - Looks for "### Full Log" section with code block
   - Falls back to extracting time-stamped entries (`HH:MM - ...`)
   - Creates properly formatted daily log file

4. **Merge Conflicts**
   - Combines unique time-stamped entries
   - Obsidian changes take precedence for same time slots
   - Preserves all unique entries from both sources

5. **Update Metadata**
   - Records file timestamps
   - Tracks sync history
   - Stores conflict information

### Example: Pulling from Obsidian (No Local File)

**Scenario**: You edited a Daily Note in Obsidian on mobile, but this computer doesn't have a daily log for that date.

**Before (Old Behavior)**:
- Nothing happens - no local file to compare against
- Changes in Obsidian are invisible to the system

**After (New Behavior)**:
```bash
$ gtd-brain-bidirectional-sync sync-daily-logs

📥 Pulling log from Obsidian (no local file): 2025-01-05
✓ Extracted and pulled log from Obsidian Daily Note
  Created: ~/Documents/daily_logs/2025-01-05.md
```

## 🔄 Workflow Examples

### Example 1: Switching Computers

**On Computer A**:
```bash
gtd-brain-bidirectional-sync sync  # Push changes
```

**Wait for Obsidian to sync** (automatic via iCloud/Dropbox)

**On Computer B**:
```bash
gtd-brain-bidirectional-sync sync  # Pull changes from Obsidian
```

### Example 2: Mobile Workflow

**On Mobile (Obsidian)**:
- Edit Daily Note
- Add entries, tags, links
- Obsidian syncs automatically

**On Computer**:
```bash
gtd-brain-bidirectional-sync sync-daily-logs
```

**Result**: Changes are pulled from Obsidian, even if no local log existed!

### Example 3: Check What Changed

```bash
$ gtd-brain-bidirectional-sync detect-changes 7

📊 Detected 3 change(s) in Obsidian:

⚠️  2 Daily Note(s) in Obsidian without local log files:
   📅 2025-01-05 - Needs to be pulled from Obsidian
   📅 2025-01-06 - Needs to be pulled from Obsidian

📝 Modified Files:
   ✏️  Daily Notes/2025-01-03.md
```

## 📊 Sync Metadata

Metadata is stored in `~/.gtd_brain_sync_metadata.json`:

```json
{
  "created": "2025-01-05T10:00:00",
  "last_sync": "2025-01-05T15:30:00",
  "file_timestamps": {
    "Daily Notes/2025-01-05.md": {
      "mtime": 1736092800,
      "size": 1234,
      "last_synced": "2025-01-05T15:30:00"
    }
  },
  "conflicts": [],
  "metadata_changes": []
}
```

## 🛡️ Conflict Resolution

### Automatic Merging

**Daily Logs**: Merges time-stamped entries
- Unique entries from both sources are combined
- If same time slot exists in both, newer version wins
- All entries are preserved

**Other Files**: Uses newer timestamp
- If Obsidian is newer → updates local
- If local is newer → updates Obsidian
- Flags for review if timestamps are very close

### Manual Resolution

If conflicts are detected:
```bash
gtd-brain-bidirectional-sync resolve
```

Shows all conflicts and lets you choose how to handle them.

## 💡 Key Differences from Old Sync

| Feature | Old (`gtd-daily-log-sync`) | New (`gtd-brain-bidirectional-sync`) |
|---------|---------------------------|-------------------------------------|
| **Detects Obsidian changes** | ❌ Only compares if local file exists | ✅ Scans all Daily Notes |
| **Pulls when no local file** | ❌ Requires local file first | ✅ Extracts from Daily Note |
| **Metadata tracking** | ❌ Only file timestamps | ✅ Full metadata (tags, links, status) |
| **Conflict resolution** | ❌ Simple "newer wins" | ✅ Intelligent merging |
| **Change detection** | ❌ Manual comparison | ✅ Automatic detection |
| **Zettelkasten sync** | ❌ Not supported | ✅ Detects changes |

## 🔍 Troubleshooting

### "No changes detected" but I know I edited in Obsidian

1. Check Obsidian sync completed:
   ```bash
   gtd-brain-bidirectional-sync status
   ```

2. Force re-scan:
   ```bash
   gtd-brain-bidirectional-sync detect-changes 30  # Check last 30 days
   ```

3. Check file permissions:
   ```bash
   ls -la ~/Documents/obsidian/Second\ Brain/Daily\ Notes/
   ```

### "Could not extract log content"

This happens when Daily Note structure doesn't match expected format. The system will:
- Create an empty log file
- Add a comment indicating source
- You can manually add content

To fix:
1. Check Daily Note format in Obsidian
2. Ensure it has "### Full Log" section or time-stamped entries
3. Re-run sync

### Conflicts not resolving

1. View conflicts:
   ```bash
   gtd-brain-bidirectional-sync resolve
   ```

2. Manual merge:
   - Open both files
   - Compare content
   - Merge manually
   - Mark as resolved

## 🎯 Best Practices

1. **Run sync regularly**
   ```bash
   # Add to your daily routine
   gtd-brain-bidirectional-sync sync-daily-logs
   ```

2. **Check status before sync**
   ```bash
   gtd-brain-bidirectional-sync status
   ```

3. **Resolve conflicts promptly**
   - Don't let conflicts accumulate
   - Review and merge regularly

4. **Use wizard for convenience**
   - Option 57 in wizard
   - Interactive conflict resolution

## 📚 Related Commands

- `gtd-daily-log-sync` - Basic daily log sync (one-way focused)
- `gtd-brain-sync` - Link GTD items to Second Brain
- `gtd-brain-sync-daily-logs` - Create Daily Notes from logs (one-way)

## 🔗 Integration

The bidirectional sync integrates with:
- ✅ Daily log system
- ✅ Success metrics tracking
- ✅ Weekly reviews (shows sync status)
- ✅ Wizard system (Option 57)

## 📝 Technical Details

### File Detection
- Scans `Second Brain/Daily Notes/` for `.md` files
- Uses file modification times (mtime)
- Compares with stored sync metadata

### Content Extraction
- Multiple extraction methods (code blocks, time-stamped entries, full note)
- Preserves formatting
- Handles edge cases gracefully

### Conflict Detection
- Compares file modification times
- Checks content hashes for actual changes
- Flags when both files modified within small time window

The system is now truly bidirectional - you can work in Obsidian on mobile and all changes will be pulled back to your computer automatically!
