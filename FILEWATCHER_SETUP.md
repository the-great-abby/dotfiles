# Vector Filewatcher Setup

## Overview

The filewatcher automatically monitors directories (including symlinks) and queues files for vectorization when they're created or modified.

## How It Works

1. **Monitors directories** - Watches for file changes in configured directories
2. **Follows symlinks** - Automatically includes symlinked directories
3. **Debounces changes** - Waits 2 seconds after file changes to avoid duplicate processing
4. **Queues automatically** - Queues files for vectorization via RabbitMQ or file queue

## Setup

### 1. Install watchdog library

```bash
# In virtualenv (recommended)
$HOME/code/dotfiles/mcp/venv/bin/pip install watchdog

# Or system-wide
pip3 install watchdog
```

### 2. Configure directories to watch

Edit `~/.gtd_config_database` or `zsh/.gtd_config_database`:

```bash
# Directories to watch (comma-separated)
# Defaults to GTD_BASE_DIR and DAILY_LOG_DIR if not set
VECTOR_WATCH_DIRS="${VECTOR_WATCH_DIRS:-$HOME/Documents/gtd,$HOME/Documents/daily_logs}"

# Enable filewatcher
VECTOR_FILEWATCHER_ENABLED="${VECTOR_FILEWATCHER_ENABLED:-true}"
```

### 3. Using symlinks (as you mentioned)

If you want to scan external directories via symlinks:

**Via Wizard (recommended):**
```bash
gtd-wizard → 1) Configuration & Setup → 10) Setup Vector Filewatcher → 3) Setup Symlinks
```

**Manually:**
```bash
# Create a watched directory structure (or use your custom location)
# Default: ~/Documents/gtd/watched
# Or configure via VECTOR_WATCH_DIR in .gtd_config_database
mkdir -p ~/Documents/gtd/watched

# Create symlinks to external directories
ln -s ~/Documents/gtd ~/Documents/gtd/watched/gtd
ln -s ~/Documents/daily_logs ~/Documents/gtd/watched/daily_logs

# Configure filewatcher to watch the symlink directory
VECTOR_WATCH_DIRS="$HOME/Documents/gtd/watched"
```

The filewatcher will automatically follow symlinks and include those directories.

**Note:** You can customize the watched directory location using option 4 in the filewatcher wizard menu.

### 4. Start the filewatcher

```bash
# Start in foreground (see logs)
gtd-vector-filewatcher

# Or start in background
nohup gtd-vector-filewatcher > /tmp/vector-filewatcher.log 2>&1 &
```

## What Gets Watched

### File Types
- `.md` (Markdown)
- `.txt` (Text files)
- `.markdown` (Markdown)

### Ignored Patterns
- Queue files (`.jsonl`)
- Log files (`.log`)
- Temporary files (`*.tmp`, `*~`)
- Hidden files (`.` prefix)

### Content Type Detection

The filewatcher automatically detects content type from path:
- `daily_logs/` → `daily_log`
- `tasks/` → `task`
- `projects/` → `project`
- `notes/` or `zettel/` → `note`
- Default → `document`

## Configuration Options

### In `.gtd_config_database`:

```bash
# Directories to watch (comma-separated, can include symlinks)
VECTOR_WATCH_DIRS="$HOME/Documents/gtd,$HOME/Documents/daily_logs"

# Watched directory location (for symlinks to external directories)
# Default: $HOME/Documents/gtd/watched
# You can change this to any location you prefer
VECTOR_WATCH_DIR="$HOME/Documents/gtd/watched"

# Enable/disable filewatcher
VECTOR_FILEWATCHER_ENABLED="true"
```

### Customizing the Watched Directory Location

You can change where the watched directory (where symlinks are stored) is located:

**Via Wizard:**
```bash
gtd-wizard → 1) Configuration & Setup → 10) Setup Vector Filewatcher → 4) Configure Watched Directory Location
```

**Manually:**
Edit `~/.gtd_config_database` or `~/code/dotfiles/zsh/.gtd_config_database`:
```bash
VECTOR_WATCH_DIR="/path/to/your/watched/directory"
```

The filewatcher will automatically use this location when setting up symlinks.

### Environment Variables:

```bash
export VECTOR_WATCH_DIRS="$HOME/Documents/gtd,$HOME/Documents/daily_logs"
export VECTOR_FILEWATCHER_ENABLED="true"
```

## Integration with Existing System

### Works with existing queue system:
- ✅ Uses same `queue_vectorization()` function
- ✅ Respects `RABBITMQ_ENABLED` setting
- ✅ Falls back to file queue if RabbitMQ unavailable
- ✅ Respects `GTD_VECTORIZATION_ENABLED` setting

### Does NOT conflict with:
- ✅ Manual vectorization (via `gtd-vectorize-content`)
- ✅ Event-driven vectorization (when creating tasks/projects)
- ✅ Existing workers

## Managing the Filewatcher

### Start filewatcher:
```bash
gtd-vector-filewatcher
```

### Check if running:
```bash
ps aux | grep gtd_vector_filewatcher
```

### Stop filewatcher:
```bash
pkill -f gtd_vector_filewatcher
```

### View logs:
```bash
tail -f /tmp/vector-filewatcher.log  # if started with nohup
```

## Example: Using Symlinks

To scan external directories via symlinks:

**Easy way (via wizard):**
```bash
gtd-wizard → 1) Configuration & Setup → 10) Setup Vector Filewatcher → 3) Setup Symlinks
```

**Manual way:**
```bash
# 1. Configure watched directory location (optional - defaults to ~/Documents/gtd/watched)
# Edit .gtd_config_database:
VECTOR_WATCH_DIR="/custom/path/to/watched"  # or leave default

# 2. Create the watched directory (or use wizard option 3)
mkdir -p "$(grep VECTOR_WATCH_DIR ~/.gtd_config_database | cut -d'"' -f2)"  # or just mkdir -p ~/Documents/gtd/watched

# 3. Create symlinks to external directories
WATCHED_DIR="${VECTOR_WATCH_DIR:-$HOME/Documents/gtd/watched}"
ln -s ~/Documents/gtd "$WATCHED_DIR/gtd"
ln -s ~/Documents/daily_logs "$WATCHED_DIR/daily_logs"
ln -s ~/Documents/obsidian/Second\ Brain "$WATCHED_DIR/second_brain"

# 4. Configure filewatcher to watch the symlink directory
# In .gtd_config_database:
VECTOR_WATCH_DIRS="$WATCHED_DIR"

# 5. Start filewatcher
gtd-vector-filewatcher
```

The filewatcher will automatically:
- Follow the symlinks
- Watch all linked directories
- Queue files for vectorization as they're created/modified

## Troubleshooting

### Filewatcher not processing files

1. **Check if running:**
   ```bash
   ps aux | grep gtd_vector_filewatcher
   ```

2. **Check logs:**
   ```bash
   tail -f /tmp/vector-filewatcher.log
   ```

3. **Check vectorization enabled:**
   ```bash
   grep GTD_VECTORIZATION_ENABLED ~/code/dotfiles/zsh/.gtd_config_database
   ```

4. **Check directories exist:**
   ```bash
   # Check if directories are being watched
   ls -la ~/Documents/gtd/watched  # if using symlinks
   ```

### Files not being queued

1. **Check file extension** - Must be `.md`, `.txt`, or `.markdown`
2. **Check if ignored** - Not in ignored patterns list
3. **Check queue status:**
   ```bash
   make rabbitmq-status
   ```

### Symlinks not being followed

- The filewatcher automatically follows symlinks within watched directories
- Make sure symlinks are valid: `ls -la ~/Documents/gtd/watched`
- Check if target directories exist

## Integration with Wizard

Add to wizard menu for easy management (future enhancement):

```bash
gtd-wizard
→ 17) System status
→ 4) Vector Filewatcher Status
```

## Summary

- ✅ **Filewatcher monitors directories** automatically
- ✅ **Follows symlinks** to include external directories
- ✅ **Queues files** for vectorization automatically
- ✅ **Works with existing queue system** (RabbitMQ or file queue)
- ✅ **Debounces changes** to avoid duplicate processing

Perfect for automatically vectorizing files created outside of GTD scripts!
