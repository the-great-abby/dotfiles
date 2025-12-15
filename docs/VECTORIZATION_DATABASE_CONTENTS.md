# Vectorization Database Contents

## What Gets Vectorized

The vectorization database stores semantic embeddings for the following content types:

### Supported Content Types

1. **`daily_log`** - Daily log entries
   - Automatically vectorized when you log entries via wizard
   - Content: Full log entry text

2. **`task`** - Individual tasks
   - Automatically vectorized when tasks are created/updated
   - Content: Task description and notes

3. **`project`** - Project descriptions
   - Automatically vectorized when projects are created/updated
   - Content: Project README and description

4. **`note`** - Notes, MOCs, and Second Brain content
   - **Requires manual scanning or filewatcher**
   - Content: Full note/MOC text
   - Includes: MOCs, zettelkasten notes, Second Brain notes

5. **`file`** - Generic files (from filewatcher)
   - Any `.md`, `.txt`, `.markdown` files in watched directories
   - Content: Full file text

## What Does NOT Get Vectorized Automatically

⚠️ **Important**: Notes and MOCs (including Pathfinder MOC) are **NOT automatically vectorized** unless:

1. **Filewatcher is enabled** and watching the directory where your notes are stored
2. **You manually scan existing files** using `gtd-vector-scan-existing`
3. **You manually vectorize** using `gtd-vectorize-content`

## Why Pathfinder MOC Might Not Be Searchable

If questions about Pathfinder MOC say "no access to information", it likely means:

1. **The MOC file hasn't been vectorized yet**
2. **The filewatcher isn't watching the directory** where your MOC is stored
3. **The filewatcher isn't running**
4. **Existing files haven't been scanned**

## How to Check What's Actually Vectorized

### 1. Check Database Statistics

```bash
gtd-vector-db-status stats
```

This shows:
- Total embeddings count
- Count by content type (daily_log, task, project, note, file)
- Latest/oldest timestamps

### 2. Check if Notes Are Vectorized

```bash
# Count note-type embeddings
gtd-vector-db-status count note

# List note-type embeddings
gtd-vector-db-status list note 20
```

### 3. Search for Pathfinder Content

```bash
cd ~/code/dotfiles
python3 << 'PYEOF'
import sys
sys.path.insert(0, 'zsh/functions')
from gtd_vectorization import search_similar

# Search for Pathfinder content
results = search_similar("Pathfinder", limit=20, threshold=0.5)
print(f"Found {len(results)} Pathfinder-related items:")
for r in results:
    print(f"  {r['content_type']}:{r['content_id']} (similarity: {r['similarity']:.2f})")
    print(f"    Preview: {r['content_text'][:200]}...")
PYEOF
```

## How to Vectorize Your Pathfinder MOC

### Option 1: Scan Existing Files (Recommended)

This will scan all markdown files in your configured directories and queue them for vectorization:

```bash
# Via Makefile
make filewatcher-scan

# Or directly
gtd-vector-scan-existing
```

**What it does:**
- Scans all `.md`, `.txt`, `.markdown` files in watched directories
- Queues them for vectorization (RabbitMQ or file queue)
- Processes notes, MOCs, and other Second Brain content

**After scanning:**
- Make sure the vector worker is running: `make worker-vector-start`
- Wait for processing to complete
- Check status: `gtd-vector-db-status stats`

### Option 2: Manually Vectorize Specific File

If you know the exact path to your Pathfinder MOC:

```bash
# Read the file and vectorize it
gtd-vectorize-content note "pathfinder-moc" "$(cat /path/to/Pathfinder\ MOC.md)"
```

Or use Python directly:

```python
import sys
sys.path.insert(0, '$HOME/code/dotfiles/zsh/functions')
from gtd_vectorization import vectorize_content
from pathlib import Path

# Read your MOC file
moc_path = Path.home() / "Documents" / "obsidian" / "Second Brain" / "Pathfinder MOC.md"
if moc_path.exists():
    content = moc_path.read_text()
    vectorize_content(
        content_type="note",
        content_id="pathfinder-moc",
        content_text=content,
        metadata={"file_path": str(moc_path), "file_name": moc_path.name}
    )
    print("✓ Vectorized Pathfinder MOC")
else:
    print(f"❌ File not found: {moc_path}")
```

### Option 3: Enable Filewatcher

If your notes are in a watched directory, enable the filewatcher to automatically vectorize new/updated files:

```bash
gtd-wizard
→ 27) ⚙️ Configuration & Setup
→ 10) 📁 Setup Vector Filewatcher
→ 4) Start Filewatcher
```

**Configure watched directories:**
- Add your Second Brain/notes directory to `VECTOR_WATCH_DIRS` in `.gtd_config_database`
- Or create symlinks in `~/Documents/gtd/watched/`

## Configuration Check

### 1. Check Vectorization Settings

```bash
grep -E "VECTORIZE|VECTOR_" ~/code/dotfiles/zsh/.gtd_config_database
```

Key settings:
- `GTD_VECTORIZATION_ENABLED="true"` - Must be enabled
- `VECTORIZE_ON_CREATE="true"` - Auto-vectorize new content
- `VECTORIZE_ON_UPDATE="true"` - Auto-vectorize updated content
- `VECTOR_WATCH_DIRS` - Directories to watch for notes

### 2. Check Filewatcher Status

```bash
# Check if filewatcher is running
ps aux | grep gtd_vector_filewatcher

# Check filewatcher config
grep VECTOR_FILEWATCHER ~/code/dotfiles/zsh/.gtd_config_database
```

### 3. Check Worker Status

```bash
# Check if vector worker is running
make worker-vector-status

# Start if not running
make worker-vector-start
```

## Complete Setup Checklist

To ensure Pathfinder MOC (and all notes) are vectorized:

1. ✅ **Enable vectorization:**
   ```bash
   # Check .gtd_config_database
   GTD_VECTORIZATION_ENABLED="true"
   ```

2. ✅ **Configure watched directories:**
   ```bash
   # Add your notes directory
   VECTOR_WATCH_DIRS="/Users/abby/Documents/gtd,/Users/abby/Documents/obsidian/Second Brain"
   ```

3. ✅ **Scan existing files:**
   ```bash
   make filewatcher-scan
   ```

4. ✅ **Start vector worker:**
   ```bash
   make worker-vector-start
   ```

5. ✅ **Verify Pathfinder MOC is vectorized:**
   ```bash
   # Search for it
   python3 << 'PYEOF'
   import sys
   sys.path.insert(0, 'zsh/functions')
   from gtd_vectorization import search_similar
   results = search_similar("Pathfinder", limit=10, threshold=0.5)
   print(f"Found {len(results)} results")
   for r in results:
       print(f"  {r['content_type']}:{r['content_id']}")
   PYEOF
   ```

6. ✅ **Enable filewatcher (optional, for auto-vectorization):**
   ```bash
   gtd-wizard → 27 → 10 → 4
   ```

## Troubleshooting

### "No results found" when searching

1. **Check if content is vectorized:**
   ```bash
   gtd-vector-db-status count note
   ```

2. **If count is 0, scan existing files:**
   ```bash
   make filewatcher-scan
   ```

3. **Check worker is processing:**
   ```bash
   make worker-vector-status
   tail -f ~/Documents/gtd/vector_worker.log
   ```

4. **Check queue:**
   ```bash
   # RabbitMQ
   make rabbitmq-status
   
   # Or file queue
   wc -l ~/Documents/gtd/vectorization_queue.jsonl
   ```

### "Database connection refused"

See `docs/NODEPORT_VS_PORT_FORWARDING.md` for troubleshooting database connectivity.

### "Embedding model not configured"

Check that `LM_STUDIO_EMBEDDING_MODEL` is set in `.gtd_config_ai`:
```bash
grep LM_STUDIO_EMBEDDING_MODEL ~/.gtd_config_ai
```

## Summary

**What's in the database:**
- ✅ Daily logs (auto-vectorized)
- ✅ Tasks (auto-vectorized)
- ✅ Projects (auto-vectorized)
- ⚠️ Notes/MOCs (requires scanning or filewatcher)

**For Pathfinder MOC specifically:**
1. Run `make filewatcher-scan` to scan existing files
2. Ensure vector worker is running: `make worker-vector-start`
3. Verify with: `gtd-vector-db-status count note`
4. Search to confirm: Use the Python search script above

**Going forward:**
- Enable filewatcher to auto-vectorize new/updated notes
- Or manually scan periodically: `make filewatcher-scan`
