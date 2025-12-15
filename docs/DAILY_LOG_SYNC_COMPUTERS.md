# Daily Log Sync Between Computers

## ✅ Yes! Daily Logs Can Now Sync Between Computers

Your daily logs can now sync between computers using your Second Brain (Obsidian) sync.

## 🔄 How It Works

### Automatic Sync via Obsidian

Daily logs are synced to:
```
~/Documents/obsidian/Second Brain/Daily Logs/
```

Since this is in your Obsidian vault, it syncs automatically via Obsidian sync (iCloud, Dropbox, etc.).

### The Sync Process

1. **On your current computer** (before switching):
   ```bash
   gtd-daily-log-sync push
   # or
   gtd-daily-log-sync sync
   ```
   This copies your daily logs to the Second Brain directory.

2. **Wait for Obsidian to sync** (automatic via iCloud/Dropbox/etc.)

3. **On your new computer** (after switching):
   ```bash
   gtd-daily-log-sync pull
   # or
   gtd-daily-log-sync sync
   ```
   This pulls the synced daily logs to your local directory.

## 📱 Commands

### Push (Before Switching Computers)

```bash
gtd-daily-log-sync push
```

Copies all local daily logs to Second Brain directory.
- Use this before switching computers
- Ensures your logs are in the cloud

### Pull (After Switching Computers)

```bash
gtd-daily-log-sync pull
```

Pulls daily logs from Second Brain directory to local.
- Use this after switching computers
- Gets the latest logs from the cloud

### Sync (Two-Way, Recommended)

```bash
gtd-daily-log-sync sync
# or just
gtd-daily-log-sync
```

Two-way sync that merges both directions:
- Local → Second Brain (if local is newer)
- Second Brain → Local (if cloud is newer)
- Handles conflicts intelligently

### Status

```bash
gtd-daily-log-sync status
```

Shows:
- Local daily log count
- Synced daily log count
- Sync directory location

## 🎯 Workflow: Switching Computers

### Step-by-Step

1. **On old computer:**
   ```bash
   gtd-daily-log-sync push
   ```
   Wait a moment for Obsidian to sync.

2. **Verify sync:**
   ```bash
   gtd-daily-log-sync status
   ```
   Check that logs are synced.

3. **On new computer:**
   ```bash
   gtd-daily-log-sync pull
   ```
   Your daily logs are now up to date!

### Quick Sync (Recommended)

Just use two-way sync on both computers:

```bash
# On old computer
gtd-daily-log-sync sync

# On new computer (after Obsidian syncs)
gtd-daily-log-sync sync
```

This automatically handles both directions.

## 📊 What Gets Synced

- All `.txt` files from `~/Documents/daily_logs/`
- Preserves file modification times
- Handles conflicts (newer file wins)
- Creates missing directories automatically

## 🔍 Access from Wizard

You can also sync from the wizard:

```bash
make gtd-wizard
# Choose: 13) 🧠 Learn Second Brain (where to start)
# Then: 9) 📱 Sync daily logs (for switching computers)
```

## ⚙️ Configuration

In your `.daily_log_config`:

```bash
# Sync method (default: second-brain)
DAILY_LOG_SYNC_METHOD="second-brain"
```

The sync directory is automatically:
```
~/Documents/obsidian/Second Brain/Daily Logs/
```

## 💡 Tips

### Regular Sync

Sync regularly, not just when switching computers:

```bash
# Add to your daily routine
gtd-daily-log-sync sync
```

### Check Status

Before switching computers, check status:

```bash
gtd-daily-log-sync status
```

### Automatic Sync

Since daily logs are in your Obsidian vault, they sync automatically when Obsidian syncs. You just need to:

1. Push before switching (or use sync)
2. Pull after switching (or use sync)

## 🚨 Troubleshooting

### "Sync directory not found"

Run `gtd-daily-log-sync push` first to create it.

### "Daily log directory not found"

Check your `.daily_log_config`:
```bash
DAILY_LOG_DIR="$HOME/Documents/daily_logs"
```

### Logs not syncing

1. Check Obsidian sync is working
2. Verify Second Brain directory exists
3. Run `gtd-daily-log-sync status` to check

### Conflicts

The sync command handles conflicts by:
- If local is newer → update cloud
- If cloud is newer → update local
- If same → skip

## 📝 Example Session

```bash
# On MacBook (old computer)
$ gtd-daily-log-sync status
📁 Local daily logs: 5 log(s)
☁️  Synced daily logs: 3 log(s)

$ gtd-daily-log-sync sync
✓ Synced: 2025-11-30.txt → Second Brain
✓ Synced: 2025-11-29.txt → Second Brain
✓ Updated: 2025-11-28.txt → Second Brain

# Wait for Obsidian to sync...

# On iMac (new computer)
$ gtd-daily-log-sync status
📁 Local daily logs: 3 log(s)
☁️  Synced daily logs: 5 log(s)

$ gtd-daily-log-sync sync
✓ Pulled: 2025-11-30.txt ← Second Brain
✓ Pulled: 2025-11-29.txt ← Second Brain
✓ Updated: 2025-11-28.txt ← Second Brain

# Now both computers are in sync!
```

## 🎉 Benefits

1. **Automatic** - Uses existing Obsidian sync
2. **Simple** - Just push/pull commands
3. **Safe** - Handles conflicts intelligently
4. **Fast** - Only syncs what's needed
5. **Integrated** - Works with your Second Brain

Your daily logs are now always in sync! 📱✨

