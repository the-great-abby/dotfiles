# Quick Reference: Submitting Jobs to Queues

## ✅ Kubernetes Worker Removed
The Kubernetes worker deployment has been removed. All jobs are processed by **local workers** that are already running.

## 🎯 How Jobs Work

**Flow:**
```
Your Code → Queues Job → RabbitMQ/File Queue → Local Worker Consumes → Processes
```

**Key Points:**
- ✅ You **submit jobs directly** (via wizard, MCP, or code)
- ✅ Jobs go to **RabbitMQ** (if enabled) or **file queue** (fallback)
- ✅ **Local workers** automatically consume and process jobs
- ❌ You don't need to submit through workers - they just consume

## 🚀 Quick Ways to Submit Jobs

### 1. Deep Analysis Jobs (Wizard - Easiest)
```bash
gtd-wizard
→ 24) 🤖 AI Suggestions & MCP Tools
→ 7) Trigger weekly review (background)
→ 8) Analyze energy patterns (background)
→ 9) Find connections (background)
→ 10) Generate insights (background)
```

### 2. Deep Analysis Jobs (MCP Tools in Cursor)
Just ask the AI:
- "Run a weekly review"
- "Analyze my energy patterns"
- "Find connections in my work"

### 3. Vectorization Jobs (Automatic)
Happens automatically when you:
- Create tasks: `gtd-task "Review budget"`
- Create projects: via wizard
- Create daily logs: via wizard

### 4. Direct Python Call
```python
# Deep Analysis
python3 -c "
import sys; sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_mcp_server import queue_deep_analysis
queue_deep_analysis('weekly_review', {'week_start': '2025-01-15'})
"

# Vectorization
python3 -c "
from zsh.functions.gtd_vectorization import queue_vectorization
queue_vectorization('task', 'task-123', 'Task description text')
"
```

## ✅ Verify Jobs Are Processing

1. **Check workers are running:**
   ```bash
   gtd-wizard → 17) System status → 3) Background Worker Status
   ```

2. **Check worker logs:**
   ```bash
   tail -f /tmp/deep-worker.log
   tail -f /tmp/vector-worker.log
   ```

3. **Check queue files:**
   ```bash
   # Deep analysis queue
   tail -1 ~/Documents/gtd/deep_analysis_queue.jsonl
   
   # Vectorization queue
   tail -1 ~/Documents/gtd/vectorization_queue.jsonl
   ```

## 🔍 Where Results Go

**Deep Analysis Results:**
- `~/Documents/gtd/deep_analysis_results/`
- Files like: `weekly_review_20250115_143000.json`

**Vectorization Results:**
- Stored in PostgreSQL vector database
- Accessible via `gtd_vector_db.py` functions

## 📝 Summary

- ✅ Jobs submitted via wizard/MCP/code → automatically queued
- ✅ Local workers running → automatically process jobs
- ✅ No Kubernetes needed → everything works locally
- ✅ RabbitMQ optional → falls back to file queue if unavailable
