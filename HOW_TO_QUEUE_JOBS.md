# How to Submit Jobs to RabbitMQ Queues

## Overview

There are two types of workers:
1. **Deep Analysis Worker** - Processes weekly reviews, energy analysis, insights, connections
2. **Vectorization Worker** - Processes content vectorization (tasks, projects, daily logs)

## 🧠 Deep Analysis Jobs

### Method 1: Automatic Scheduler (Recommended for Regular Analysis)

**The scheduler automatically submits deep analysis jobs based on schedules and triggers:**

```bash
# Setup via wizard
gtd-wizard → 1) Configuration & Setup → 11) 🧠 Setup Deep Analysis Auto-Scheduler

# Start the scheduler daemon
make scheduler-start
```

**Configure automatic schedules:**
- Weekly reviews every Monday
- Energy analysis every 3 days
- Insights every day
- Connections every week

**Event-driven triggers:**
- Energy analysis when daily log is created
- Connections when task is created
- Insights when content is created

See `DEEP_ANALYSIS_AUTO_SCHEDULER.md` for full documentation.

### Method 2: Via Wizard Menu (Manual Trigger)

```bash
gtd-wizard
→ 24) 🤖 AI Suggestions & MCP Tools
→ Choose from:
   - 7) Trigger weekly review (background)
   - 8) Analyze energy patterns (background)
   - 9) Find connections (background)
   - 10) Generate insights (background)
```

### Method 3: Via MCP Tools in Cursor

Ask the AI in Cursor:
- "Run a weekly review"
- "Analyze my energy patterns"
- "Find connections in my work"
- "Generate insights from my recent activity"

The AI will use the MCP tools which automatically queue the jobs.

### Method 4: Direct Python Call

```python
# In Python or via command line
python3 -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_mcp_server import queue_deep_analysis

# Queue a weekly review
status = queue_deep_analysis('weekly_review', {'week_start': '2025-01-15'})
print(status)  # Will show: queued_to_rabbitmq or queued_to_file

# Queue energy analysis
status = queue_deep_analysis('analyze_energy', {'days': 7})
print(status)

# Queue connection finding
status = queue_deep_analysis('find_connections', {'scope': 'all'})
print(status)

# Queue insights generation
status = queue_deep_analysis('generate_insights', {'focus': 'general'})
print(status)
"
```

### Method 5: Directly to File Queue (for testing)

You can manually add jobs to the file queue:

```bash
# Add a weekly review job
cat >> ~/Documents/gtd/deep_analysis_queue.jsonl << 'EOF'
{"type": "weekly_review", "context": {"week_start": "2025-01-15"}, "timestamp": "2025-01-15T10:00:00", "model": "qwen/qwen3-4b-thinking-2507", "model_url": "http://localhost:1234/v1/chat/completions"}
EOF
```

## 📝 Vectorization Jobs

### Method 1: Automatic via Filewatcher (Recommended for External Files)

**Filewatcher automatically monitors directories and queues files as they're created/modified:**

```bash
# Start filewatcher
make filewatcher-start

# Or manually
gtd-vector-filewatcher
```

The filewatcher:
- ✅ Monitors `~/Documents/gtd` and `~/Documents/daily_logs` by default
- ✅ Follows symlinks automatically (perfect for external directories)
- ✅ Watches for new/modified `.md`, `.txt`, `.markdown` files
- ✅ Automatically queues them for vectorization
- ✅ Works with RabbitMQ or file queue

**Setup with symlinks (as you mentioned):**
```bash
# Create a watched directory
mkdir -p ~/Documents/gtd/watched

# Symlink external directories
ln -s ~/Documents/gtd ~/Documents/gtd/watched/gtd
ln -s ~/Documents/daily_logs ~/Documents/gtd/watched/daily_logs

# Configure to watch the symlink directory
# In .gtd_config_database:
VECTOR_WATCH_DIRS="$HOME/Documents/gtd/watched"
```

See `FILEWATCHER_SETUP.md` for full details.

### Method 2: Event-Driven (When Creating Content via Scripts)

Vectorization is automatically queued when you create/update content via GTD scripts:

```bash
# Creating a task automatically queues vectorization
gtd-task "Review the quarterly budget"

# Creating a project automatically queues vectorization
gtd-wizard → 4) Manage projects → Create new project
```

**This only works if:**
- `GTD_VECTORIZATION_ENABLED=true` in `.gtd_config_database`
- `RABBITMQ_ENABLED=true` (for async) or `false` (for sync)

### Method 2: Direct Command

```bash
# Manually queue content for vectorization
gtd-vectorize-content "task" "task-123" "Task description text here"

# Or with metadata
gtd-vectorize-content "daily_log" "2025-01-15" "Today I worked on..." 
```

### Method 3: Direct Python Call

```python
# In Python
from zsh.functions.gtd_vectorization import queue_vectorization

status = queue_vectorization(
    content_type="task",
    content_id="task-123",
    content_text="Complete the quarterly report",
    metadata={"tags": ["work", "urgent"]}
)

print(status)  # queued_to_rabbitmq or queued_to_file
```

### Method 4: Directly to File Queue

```bash
# Add vectorization job manually
cat >> ~/Documents/gtd/vectorization_queue.jsonl << 'EOF'
{"content_type": "task", "content_id": "test-123", "content_text": "Test task for vectorization", "metadata": {}, "timestamp": "2025-01-15T10:00:00"}
EOF
```

## 📊 Checking Queue Status

### Quick Check (Recommended)

**View RabbitMQ Queue Status:**
```bash
# Method 1: Direct command
gtd-rabbitmq-status

# Method 2: Via Makefile
make rabbitmq-status

# Method 3: Via Wizard
gtd-wizard
→ 17) System status
→ 3) Background Worker Status
→ 5) View RabbitMQ Queue Status
```

This shows:
- ✅ Messages waiting in each queue
- ✅ Active consumers (workers) connected
- ✅ Processing status
- ✅ File queue fallback status

### Deep Analysis Queue (Manual Check)

```bash
# Check file queue
wc -l ~/Documents/gtd/deep_analysis_queue.jsonl
cat ~/Documents/gtd/deep_analysis_queue.jsonl

# Check RabbitMQ via Python (if port-forward is running)
# The gtd-rabbitmq-status script handles this automatically
```

### Vectorization Queue (Manual Check)

```bash
# Check file queue
wc -l ~/Documents/gtd/vectorization_queue.jsonl
cat ~/Documents/gtd/vectorization_queue.jsonl
```

### Via Worker Status Command

```bash
make worker-status
# Or
gtd-worker-status
```

## 📁 Where Results Are Saved

### Deep Analysis Results

All results are saved to:
```
~/Documents/gtd/deep_analysis_results/
```

Files are named:
- `weekly_review_20250115_143000.json`
- `analyze_energy_20250115_143000.json`
- `find_connections_20250115_143000.json`
- `generate_insights_20250115_143000.json`

### Vectorization Results

Vectorization stores embeddings directly in PostgreSQL (vector database). No separate result files.

View vectors via:
```python
from zsh.functions.gtd_vector_db import VectorDatabase
db = VectorDatabase()
db.connect()
results = db.search_similar(query_embedding, limit=10)
```

## 🔄 Queue Behavior

### If RabbitMQ is Available

1. Jobs go to RabbitMQ queue
2. Worker consumes from RabbitMQ
3. Fast, async processing

### If RabbitMQ is Not Available

1. Jobs go to file queue (JSONL format)
2. Worker polls file queue every 5 seconds
3. Still works, just processes from files

### Automatic Fallback

Both systems automatically fall back to file queue if:
- RabbitMQ is not running
- `RABBITMQ_ENABLED=false`
- Connection fails
- `pika` library not installed

## 🎯 Quick Reference

### Queue Deep Analysis Jobs

| Job Type | Wizard Path | MCP Tool | Python Function |
|----------|-------------|----------|-----------------|
| Weekly Review | 24 → 7 | `weekly_review` | `queue_deep_analysis('weekly_review', {...})` |
| Energy Analysis | 24 → 8 | `analyze_energy` | `queue_deep_analysis('analyze_energy', {'days': 7})` |
| Find Connections | 24 → 9 | `find_connections` | `queue_deep_analysis('find_connections', {'scope': 'all'})` |
| Generate Insights | 24 → 10 | `generate_insights` | `queue_deep_analysis('generate_insights', {'focus': 'general'})` |

### Queue Vectorization Jobs

| Method | Command | When to Use |
|--------|---------|-------------|
| Automatic | Content creation scripts | Default - happens automatically |
| Direct | `gtd-vectorize-content type id text` | Manual vectorization |
| Python | `queue_vectorization(...)` | Programmatic access |

## ✅ Verification

After queuing a job, verify it was queued:

```bash
# Deep Analysis - check file queue
tail -1 ~/Documents/gtd/deep_analysis_queue.jsonl | jq .

# Deep Analysis - check if worker is processing
tail -f /tmp/deep-worker.log

# Vectorization - check file queue  
tail -1 ~/Documents/gtd/vectorization_queue.jsonl | jq .

# Vectorization - check if worker is processing
tail -f /tmp/vector-worker.log
```

## 🚨 Troubleshooting

### Jobs Not Processing

1. **Check workers are running:**
   ```bash
   make worker-status
   ```

2. **Check worker logs:**
   ```bash
   tail -f /tmp/deep-worker.log
   tail -f /tmp/vector-worker.log
   ```

3. **Check queue has messages:**
   ```bash
   wc -l ~/Documents/gtd/*queue.jsonl
   ```

4. **Restart workers if needed:**
   ```bash
   make worker-deep-restart
   make worker-vector-restart
   ```

### Jobs Queued But Not Processing

- Worker may have crashed - check logs
- Queue file may have invalid JSON - check syntax
- Database/embedding model may not be accessible
