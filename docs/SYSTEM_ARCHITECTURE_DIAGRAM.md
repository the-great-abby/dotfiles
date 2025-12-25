# 🏗️ GTD System Architecture - Complete Diagram

**Last Updated:** 2025-12-21  
**System Status:** Production with 8 Background Workers

---

## 🎯 System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GTD UNIFIED SYSTEM ARCHITECTURE                      │
│                    (Zettelkasten + GTD + Second Brain)                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🧠 AI Model Architecture

### Model Tiers & Usage

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AI MODEL TIERS                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  TIER 1: FAST MODELS (Chat/Quick Responses)                        │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │                                                                     │    │
│  │  Work Mode:                                                         │    │
│  │    • Chat: gemma3:4b (Ollama)                                       │    │
│  │    • Instruct: llama3.1:8b-instruct-q6_K (Ollama)                 │    │
│  │    • Embedding: nomic-embed-text (Ollama)                          │    │
│  │                                                                     │    │
│  │  Home Mode:                                                         │    │
│  │    • Chat: gemma3:1b (Ollama)                                       │    │
│  │    • Instruct: svjack/Qwen3-4B-Instruct-2507-heretic (Ollama)     │    │
│  │    • Embedding: nomic-embed-text (Ollama)                          │    │
│  │                                                                     │    │
│  │  Used For:                                                          │    │
│  │    ✓ Dashboard rendering (cache worker)                            │    │
│  │    ✓ Quick task suggestions                                        │    │
│  │    ✓ Task organization (project assignment)                       │    │
│  │    ✓ Knowledge organization (MoC/Area suggestions)                │    │
│  │    ✓ Advice worker (persona responses)                             │    │
│  │    ✓ Badge suggestions                                             │    │
│  │    ✓ Vector embeddings (semantic search)                          │    │
│  │                                                                     │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  TIER 2: DEEP MODELS (Background Analysis)                         │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │                                                                     │    │
│  │  Work Mode:                                                         │    │
│  │    • Deep: gpt-oss:20b (Ollama)                                     │    │
│  │                                                                     │    │
│  │  Home Mode:                                                         │    │
│  │    • Deep: svjack/Qwen3-4B-Instruct-2507-heretic (Ollama)          │    │
│  │                                                                     │    │
│  │  Used For:                                                          │    │
│  │    ✓ Weekly reviews (comprehensive analysis)                       │    │
│  │    ✓ Energy pattern analysis                                       │    │
│  │    ✓ Connection finding                                            │    │
│  │    ✓ Deep insights generation                                      │    │
│  │    ✓ Second brain sync (content analysis)                          │    │
│  │                                                                     │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  TIER 3: THINKING MODELS (Reasoning)                               │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │                                                                     │    │
│  │  Default:                                                           │    │
│  │    • Thinking: qwen/qwen3-4b-thinking-2507                        │    │
│  │                                                                     │    │
│  │  Used For:                                                          │    │
│  │    ✓ Complex reasoning tasks                                       │    │
│  │    ✓ Multi-step problem solving                                    │    │
│  │    ✓ Deep analysis with reasoning chains                           │    │
│  │                                                                     │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Background Workers Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          BACKGROUND WORKERS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  1. DASHBOARD CACHE WORKER                                         │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_dashboard_cache_worker.py                        │    │
│  │  Wrapper: bin/gtd-dashboard-cache-worker                         │    │
│  │  Queue: N/A (runs continuously)                                    │    │
│  │  Model: None (file system operations)                            │    │
│  │  Update Interval: 10 seconds                                       │    │
│  │  Output: ~/Documents/gtd/.dashboard_cache.json                    │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Pre-calculate dashboard statistics                            │    │
│  │    • Cache inbox/task/project counts                               │    │
│  │    • Cache favorited items                                         │    │
│  │    • Cache suggestions counts                                      │    │
│  │    • Prevents dashboard hanging                                   │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  2. DEEP ANALYSIS WORKER                                           │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_deep_analysis_worker.py                          │    │
│  │  Wrapper: bin/gtd-deep-analysis-worker                             │    │
│  │  Queue: gtd_deep_analysis (RabbitMQ) or file queue                 │    │
│  │  Model: Deep Model (gpt-oss:20b / Qwen3-4B-Instruct)              │    │
│  │  Timeout: 600 seconds (10 minutes)                                 │    │
│  │  Output: ~/Documents/gtd/deep_analysis_results/                   │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Weekly reviews (comprehensive analysis)                       │    │
│  │    • Energy pattern analysis                                       │    │
│  │    • Connection finding                                            │    │
│  │    • Deep insights generation                                      │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  3. VECTOR WORKER                                                  │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_vector_worker.py                                  │    │
│  │  Wrapper: bin/gtd-vector-worker                                    │    │
│  │  Queue: gtd_vectorization (RabbitMQ) or file queue                 │    │
│  │  Model: Embedding Model (nomic-embed-text-v2-moe)                 │    │
│  │  Output: PostgreSQL (pgvector)                                     │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Generate embeddings for tasks/projects/notes                  │    │
│  │    • Store in PostgreSQL with pgvector                             │    │
│  │    • Enable semantic search                                        │    │
│  │    • Power vector-based suggestions                                │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  4. ADVICE WORKER                                                  │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_advice_worker.py                                 │    │
│  │  Wrapper: bin/gtd-advice-worker-python                             │    │
│  │  Queue: gtd_advice (RabbitMQ) or file queue                        │    │
│  │  Model: Chat Model (gemma3:1b / gemma3:4b)                        │    │
│  │  Personas: 20+ personas (Hank, David, Cal, James, etc.)           │    │
│  │  Output: ~/Documents/gtd/advice_results/                           │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Process advice requests with persona responses                │    │
│  │    • Use vector search for context                                 │    │
│  │    • Generate personalized advice                                 │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  5. TASK ORGANIZE WORKER                                           │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_task_organize_worker.py                          │    │
│  │  Wrapper: bin/gtd-task-org-worker                                  │    │
│  │  Queue: gtd_task_organization (RabbitMQ) or file queue             │    │
│  │  Model: Instruct Model (llama3.1:8b-instruct / Qwen3-4B-Instruct)  │    │
│  │  Output: Task project assignments                                  │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Suggest projects for tasks                                    │    │
│  │    • Organize tasks into projects                                  │    │
│  │    • Use structured JSON output                                    │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  6. KNOWLEDGE ORGANIZE WORKER                                      │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_knowledge_organize_worker.py                     │    │
│  │  Wrapper: N/A (runs via scheduler)                                 │    │
│  │  Queue: gtd_knowledge_organization (RabbitMQ) or file queue        │    │
│  │  Model: Instruct Model (llama3.1:8b-instruct / Qwen3-4B-Instruct) │    │
│  │  Schedule: 3 AM daily                                              │    │
│  │  Output: ~/Documents/gtd/knowledge_organization_results/          │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Suggest areas of responsibility for projects                  │    │
│  │    • Suggest MoCs (Maps of Content) for notes                      │    │
│  │    • Mine daily logs for themes                                    │    │
│  │    • Suggest new areas based on patterns                           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  7. SECOND BRAIN SYNC WORKER                                       │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_second_brain_sync_worker.py                      │    │
│  │  Wrapper: bin/gtd-second-brain-sync-worker                        │    │
│  │  Queue: gtd_second_brain_sync (RabbitMQ) or file queue            │    │
│  │  Model: Deep Model (for content analysis)                          │    │
│  │  Output: ~/Documents/gtd/second_brain_sync_results/               │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Sync GTD system with Obsidian Second Brain                    │    │
│  │    • Analyze content for connections                               │    │
│  │    • Create bidirectional links                                    │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  8. BADGE SUGGESTION WORKER                                        │    │
│  │  ────────────────────────────────────────────────────────────────  │    │
│  │  Script: mcp/gtd_badge_suggestion_worker.py                        │    │
│  │  Wrapper: bin/gtd-badge-suggestion-worker                         │    │
│  │  Queue: gtd_badge_suggestions (RabbitMQ) or file queue             │    │
│  │  Model: Chat Model (gemma3:1b)                                     │    │
│  │  Output: ~/Documents/gtd/gamification.json                         │    │
│  │                                                                     │    │
│  │  Purpose:                                                          │    │
│  │    • Suggest badges based on activity                              │    │
│  │    • Track achievements                                            │    │
│  │    • Gamification system                                           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔌 System Components & Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SYSTEM COMPONENTS & DATA FLOW                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐       │
│  │   USER       │────────▶│   WIZARD     │────────▶│   MCP SERVER  │       │
│  │  (Terminal)  │         │  (Bash)      │         │   (Python)    │       │
│  └──────────────┘         └──────────────┘         └──────────────┘       │
│         │                         │                         │               │
│         │                         │                         │               │
│         ▼                         ▼                         ▼               │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    QUEUE SYSTEM (RabbitMQ/File)                      │  │
│  │  ────────────────────────────────────────────────────────────────  │  │
│  │                                                                      │  │
│  │  Queues:                                                             │  │
│  │    • gtd_deep_analysis          → Deep Analysis Worker               │  │
│  │    • gtd_vectorization          → Vector Worker                      │  │
│  │    • gtd_advice                 → Advice Worker                       │  │
│  │    • gtd_task_organization      → Task Organize Worker               │  │
│  │    • gtd_knowledge_organization → Knowledge Organize Worker          │  │
│  │    • gtd_second_brain_sync      → Second Brain Sync Worker            │  │
│  │    • gtd_badge_suggestions      → Badge Suggestion Worker            │  │
│  │                                                                      │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│         │                                                                   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    AI BACKENDS (LM Studio / Ollama)                 │  │
│  │  ────────────────────────────────────────────────────────────────  │  │
│  │                                                                      │  │
│  │  Fast Models:                                                        │  │
│  │    • Chat: gemma3:1b, gemma3:4b, qwen/qwen3-1.7b                    │  │
│  │    • Instruct: llama3.1:8b-instruct, Qwen3-4B-Instruct              │  │
│  │    • Embedding: nomic-embed-text-v2-moe                             │  │
│  │                                                                      │  │
│  │  Deep Models:                                                        │  │
│  │    • gpt-oss:20b, svjack/Qwen3-4B-Instruct-2507-heretic             │  │
│  │                                                                      │  │
│  │  Thinking Models:                                                    │  │
│  │    • qwen/qwen3-4b-thinking-2507                                     │  │
│  │                                                                      │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│         │                                                                   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    STORAGE SYSTEMS                                  │  │
│  │  ────────────────────────────────────────────────────────────────  │  │
│  │                                                                      │  │
│  │  File System:                                                        │  │
│  │    • ~/Documents/gtd/ (GTD files)                                   │  │
│  │    • ~/Documents/daily_logs/ (Daily logs)                            │  │
│  │    • ~/Documents/obsidian/Second Brain/ (Second Brain)               │  │
│  │                                                                      │  │
│  │  PostgreSQL (with pgvector):                                        │  │
│  │    • Vector embeddings                                              │  │
│  │    • Semantic search                                                │  │
│  │    • Task/project/note vectors                                      │  │
│  │                                                                      │  │
│  │  RabbitMQ:                                                           │  │
│  │    • Message queues                                                 │  │
│  │    • Job distribution                                               │  │
│  │                                                                      │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Worker Status & Monitoring

### Worker Startup Commands

```bash
# Dashboard Cache Worker (runs continuously)
gtd-dashboard-cache-worker

# Deep Analysis Worker
gtd-deep-analysis-worker

# Vector Worker
gtd-vector-worker

# Advice Worker
gtd-advice-worker-python

# Task Organize Worker
gtd-task-org-worker

# Knowledge Organize Worker (scheduled at 3 AM)
# Runs automatically via launchd

# Second Brain Sync Worker
gtd-second-brain-sync-worker

# Badge Suggestion Worker
gtd-badge-suggestion-worker
```

### Monitoring

```bash
# Check all workers
gtd-wizard → 17) System Status → 3) Background Worker Status

# Check RabbitMQ queues
gtd-rabbitmq-status

# Check individual worker logs
tail -f /tmp/dashboard-cache-worker.log
tail -f /tmp/deep-worker.log
tail -f /tmp/vector-worker.log
tail -f /tmp/advice-worker.log
```

---

## 🎯 Model Usage Matrix

| Component | Model Type | Model Name | Purpose |
|-----------|-----------|------------|---------|
| **Dashboard Cache** | None | N/A | File system operations |
| **Deep Analysis** | Deep | gpt-oss:20b / Qwen3-4B-Instruct | Weekly reviews, insights |
| **Vector Worker** | Embedding | nomic-embed-text-v2-moe | Semantic search |
| **Advice Worker** | Chat | gemma3:1b / gemma3:4b | Persona responses |
| **Task Organize** | Instruct | llama3.1:8b-instruct / Qwen3-4B-Instruct | Project assignment |
| **Knowledge Organize** | Instruct | llama3.1:8b-instruct / Qwen3-4B-Instruct | MoC/Area suggestions |
| **Second Brain Sync** | Deep | gpt-oss:20b / Qwen3-4B-Instruct | Content analysis |
| **Badge Suggestions** | Chat | gemma3:1b | Achievement tracking |
| **MCP Server (Fast)** | Chat | gemma3:1b / gemma3:4b | Quick suggestions |
| **MCP Server (Deep)** | Deep | gpt-oss:20b / Qwen3-4B-Instruct | Background analysis |

---

## 🔄 Complete Data Flow Example

### Example: Creating a Task with AI Suggestions

```
1. User: gtd-wizard → Create task
   │
   ▼
2. Wizard → MCP Server (suggest_tasks_from_text)
   │
   ▼
3. MCP Server → Fast Model (gemma3:1b)
   │
   ▼
4. MCP Server → Queue: gtd_task_organization
   │
   ▼
5. Task Organize Worker → Instruct Model (llama3.1:8b-instruct)
   │
   ▼
6. Task Organize Worker → Suggests project
   │
   ▼
7. Task created with project assignment
   │
   ▼
8. Vector Worker → Queue: gtd_vectorization
   │
   ▼
9. Vector Worker → Embedding Model (nomic-embed-text)
   │
   ▼
10. Vector stored in PostgreSQL (pgvector)
    │
    ▼
11. Dashboard Cache Worker → Updates cache
    │
    ▼
12. Dashboard shows updated task count
```

---

## 🚀 System Capabilities

### Real-Time Operations
- ✅ Dashboard rendering (cached, < 1 second)
- ✅ Task creation
- ✅ Quick AI suggestions
- ✅ Persona advice

### Background Operations
- ✅ Weekly reviews (10+ minutes)
- ✅ Energy analysis
- ✅ Connection finding
- ✅ Deep insights
- ✅ Vector embeddings
- ✅ Knowledge organization
- ✅ Second brain sync

### Scheduled Operations
- ✅ Knowledge organization scan (3 AM daily)
- ✅ Auto-suggest run (3 AM daily, after knowledge scan)
- ✅ Dashboard cache updates (every 10 seconds)

---

## 📈 System Statistics

- **Total Workers:** 8
- **AI Models in Use:** 10+ (across chat, instruct, embedding, deep, thinking)
- **Queues:** 7 (RabbitMQ or file-based)
- **Storage Systems:** 3 (File system, PostgreSQL, RabbitMQ)
- **Personas:** 20+
- **Update Frequency:** Dashboard cache every 10 seconds

---

## 🎨 Visual Summary

```
                    ┌─────────────────┐
                    │   USER INPUT     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  GTD WIZARD     │
                    │  (Bash Shell)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   MCP SERVER    │
                    │   (Python)      │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐        ┌─────▼─────┐       ┌─────▼─────┐
   │  FAST   │        │   QUEUE   │       │   DEEP    │
   │  MODEL  │        │  SYSTEM   │       │   MODEL   │
   │(gemma3) │        │(RabbitMQ) │       │(gpt-oss)  │
   └─────────┘        └─────┬─────┘       └───────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐        ┌─────▼─────┐      ┌─────▼─────┐
   │ WORKERS │        │ POSTGRES  │      │   FILES   │
   │  (8x)   │        │ (pgvector)│      │  (GTD)    │
   └─────────┘        └───────────┘      └───────────┘
```

---

**This system is a complex, multi-layered architecture with 8 background workers, 10+ AI models, and seamless integration between Zettelkasten, GTD, and Second Brain methodologies.**


