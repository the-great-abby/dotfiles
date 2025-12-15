# How to Verify Vectorized Content

## Quick Commands

### 1. Check Database Statistics

```bash
gtd-vector-db-status stats
```

Shows:
- Total number of embeddings
- Count by content type (daily_log, task, project, note, etc.)
- Latest/oldest created/updated timestamps

### 2. Count Embeddings

```bash
# Count all embeddings
gtd-vector-db-status count

# Count by content type
gtd-vector-db-status count daily_log
gtd-vector-db-status count task
gtd-vector-db-status count project
gtd-vector-db-status count note
```

### 3. List Embeddings

```bash
# List all embeddings (default: 100)
gtd-vector-db-status list

# List with custom limit
gtd-vector-db-status list "" 50

# List by content type
gtd-vector-db-status list daily_log
gtd-vector-db-status list task 20
gtd-vector-db-status list project
```

### 4. Test Database Connection

```bash
gtd-vector-db-status test
```

## Via Wizard Menu

```bash
gtd-wizard
→ 24) 🤖 AI Suggestions & MCP Tools
→ 8) 🔍 Vector Database Status & Inspection
```

Options:
1. View Statistics
2. List All Entries
3. List by Content Type
4. Count Entries

## Search for Specific Content

### Test Vector Search

You can test if content is searchable using Python:

```python
import sys
sys.path.insert(0, '$HOME/code/dotfiles/zsh/functions')
from gtd_vectorization import search_similar

# Search for content
results = search_similar(
    query_text="Pathfinder session 12",
    content_type=None,  # Search all types
    limit=10,
    threshold=0.6
)

print(f"Found {len(results)} results:")
for result in results:
    print(f"  - {result['content_type']}:{result['content_id']} (similarity: {result['similarity']:.2f})")
    print(f"    Preview: {result['content_text'][:200]}...")
```

### Via Command Line

```bash
cd ~/code/dotfiles
python3 << 'PYEOF'
import sys
sys.path.insert(0, 'zsh/functions')
from gtd_vectorization import search_similar

results = search_similar("Pathfinder session 12", limit=5, threshold=0.6)
print(f"Found {len(results)} results:")
for r in results:
    print(f"  {r['content_type']}:{r['content_id']} ({r['similarity']:.2f})")
PYEOF
```

## Check What's Been Vectorized

### 1. Check Statistics

```bash
gtd-vector-db-status stats
```

Example output:
```
📊 Vector Database Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total embeddings: 134

By content type:
  • daily_log: 45
  • task: 32
  • project: 12
  • note: 28
  • file: 17

Latest created: 2025-12-13 15:30:00
Latest updated: 2025-12-13 15:30:00
Oldest created: 2025-12-01 08:00:00
```

### 2. List Recent Entries

```bash
gtd-vector-db-status list "" 20
```

Shows the 20 most recent vectorized items with previews.

### 3. Check Specific Content Type

```bash
# Check if daily logs are vectorized
gtd-vector-db-status count daily_log
gtd-vector-db-status list daily_log 10

# Check if tasks are vectorized
gtd-vector-db-status count task
gtd-vector-db-status list task 10
```

## Verify a Specific File/Item

### Check if a Specific Item Exists

```python
import sys
sys.path.insert(0, '$HOME/code/dotfiles/zsh/functions')
from gtd_vector_db import VectorDatabase, read_database_config

db = VectorDatabase(read_database_config())
if db.connect():
    # List all embeddings and search for your item
    embeddings = db.list_embeddings(limit=1000)
    for emb in embeddings:
        if "session 12" in emb['content_id'].lower() or "session 12" in emb['content_preview'].lower():
            print(f"Found: {emb['content_type']}:{emb['content_id']}")
            print(f"Preview: {emb['content_preview'][:200]}")
    db.disconnect()
```

## Check Queue Status

### See What's Waiting to be Vectorized

```bash
# Check RabbitMQ queue
make rabbitmq-status

# Or check file queue
wc -l ~/Documents/gtd/vectorization_queue.jsonl
cat ~/Documents/gtd/vectorization_queue.jsonl | head -5
```

## Common Verification Scenarios

### Scenario 1: "Did my Pathfinder session notes get vectorized?"

```bash
# Search for Pathfinder content
python3 << 'PYEOF'
import sys
sys.path.insert(0, 'zsh/functions')
from gtd_vectorization import search_similar

results = search_similar("Pathfinder", limit=20, threshold=0.5)
print(f"Found {len(results)} Pathfinder-related items:")
for r in results:
    print(f"  {r['content_type']}:{r['content_id']} (similarity: {r['similarity']:.2f})")
PYEOF
```

### Scenario 2: "Are my daily logs being vectorized?"

```bash
# Count daily logs
gtd-vector-db-status count daily_log

# List recent daily logs
gtd-vector-db-status list daily_log 10
```

### Scenario 3: "Is a specific file vectorized?"

```bash
# List all and grep for your file
gtd-vector-db-status list "" 1000 | grep "your-file-name"
```

## Troubleshooting

### No Results Found

1. **Check if vectorization is enabled:**
   ```bash
   grep GTD_VECTORIZATION_ENABLED ~/code/dotfiles/zsh/.gtd_config_database
   ```

2. **Check if worker is running:**
   ```bash
   make worker-vector-status
   ```

3. **Check queue:**
   ```bash
   make rabbitmq-status
   ```

4. **Re-scan existing files:**
   ```bash
   make filewatcher-scan
   ```

### Database Connection Issues

```bash
# Test connection
gtd-vector-db-status test

# Check database config
cat ~/code/dotfiles/zsh/.gtd_config_database | grep -E "DB_|POSTGRES"
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `gtd-vector-db-status stats` | Show overall statistics |
| `gtd-vector-db-status count` | Count all embeddings |
| `gtd-vector-db-status count daily_log` | Count by type |
| `gtd-vector-db-status list` | List all (100 default) |
| `gtd-vector-db-status list task 20` | List 20 tasks |
| `gtd-vector-db-status test` | Test connection |
