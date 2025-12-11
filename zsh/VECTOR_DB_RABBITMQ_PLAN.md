# Vector Database & RabbitMQ Integration Plan

## Overview

This document outlines the architecture for integrating PostgreSQL vector database and RabbitMQ for asynchronous vectorization processing in the GTD system.

## Current Status

✅ **Completed:**
- PostgreSQL vector database configuration (`.gtd_config_database`)
- Database connection helper (`gtd_vector_db.py`)
- Vectorization module (`gtd_vectorization.py`)
- Schema initialization script (`gtd-init-vector-db`)

⏳ **Planned:**
- RabbitMQ integration for async processing
- Background worker for vectorization
- Queue management and retry logic

## Architecture

### Components

```
┌─────────────────┐
│  GTD Scripts    │
│  (daily logs,   │
│   tasks, etc.)  │
└────────┬────────┘
         │
         │ (1) Content created/updated
         ▼
┌─────────────────┐
│ Vectorization   │
│   Service       │
└────────┬────────┘
         │
         ├─► (2a) Direct mode: Process immediately
         │
         └─► (2b) Async mode: Queue via RabbitMQ
                    │
                    ▼
            ┌───────────────┐
            │   RabbitMQ    │
            │   Queue       │
            └───────┬───────┘
                    │
                    │ (3) Worker consumes
                    ▼
            ┌───────────────┐
            │  Background   │
            │   Worker      │
            └───────┬───────┘
                    │
                    │ (4) Generate embeddings
                    ▼
            ┌───────────────┐
            │  Embedding    │
            │    API        │
            │ (LM Studio)   │
            └───────┬───────┘
                    │
                    │ (5) Store vectors
                    ▼
            ┌───────────────┐
            │  PostgreSQL   │
            │  + pgvector   │
            └───────────────┘
```

### Data Flow

1. **Content Creation/Update**
   - GTD scripts create or update content (daily logs, tasks, projects)
   - If `VECTORIZE_ON_CREATE` or `VECTORIZE_ON_UPDATE` is enabled:
     - Direct mode: Process immediately (synchronous)
     - Async mode: Queue message to RabbitMQ

2. **Queue Processing**
   - Messages contain: `content_type`, `content_id`, `content_text`, `metadata`
   - RabbitMQ handles message persistence and delivery
   - Supports retry logic for failed processing

3. **Background Worker**
   - Consumes messages from queue
   - Generates embeddings using LM Studio/Ollama
   - Stores embeddings in PostgreSQL
   - Handles errors and retries

4. **Vector Search**
   - Search queries generate embeddings
   - PostgreSQL performs similarity search
   - Results returned to user

## Configuration

### Database Configuration (`.gtd_config_database`)

```bash
# PostgreSQL settings
VECTOR_DB_HOST="localhost"
VECTOR_DB_PORT="13003"
VECTOR_DB_NAME="vector"
VECTOR_DB_USER="postgres"
VECTOR_DB_PASSWORD="your_password"

# Vectorization settings
GTD_VECTORIZATION_ENABLED="true"
VECTORIZE_ON_CREATE="true"
VECTORIZE_ON_UPDATE="true"

# RabbitMQ settings (when ready)
RABBITMQ_ENABLED="false"  # Set to true when RabbitMQ is set up
RABBITMQ_URL="amqp://localhost:5672"
RABBITMQ_VECTOR_QUEUE="gtd_vectorization"
```

## RabbitMQ Integration Plan

### Phase 1: Queue Infrastructure

**Files to create:**
- `zsh/functions/gtd_rabbitmq.py` - RabbitMQ connection and queue management
- `bin/gtd-vector-worker` - Background worker script
- `mcp/gtd_vector_worker.py` - Python worker implementation

**Features:**
- Connection management with retry logic
- Queue declaration and binding
- Message publishing
- Message consumption with acknowledgment
- Error handling and dead letter queue

### Phase 2: Worker Implementation

**Worker responsibilities:**
1. Connect to RabbitMQ
2. Consume messages from `gtd_vectorization` queue
3. For each message:
   - Extract content information
   - Generate embedding using `gtd_vectorization.generate_embedding()`
   - Store in database using `gtd_vector_db.VectorDatabase`
   - Acknowledge message on success
   - Requeue on failure (with retry limit)

**Error handling:**
- Failed embeddings → Retry up to 3 times
- Database errors → Log and move to dead letter queue
- Network errors → Retry with exponential backoff

### Phase 3: Integration Points

**Update existing scripts to use vectorization:**

1. **Daily Log Script** (`gtd-daily-log`)
   - After saving log, queue for vectorization
   - Or process immediately if `RABBITMQ_ENABLED=false`

2. **Task Management** (`gtd-wizard`, `gtd_mcp_server.py`)
   - When tasks are created/updated, queue for vectorization

3. **Project Management**
   - When projects are created/updated, queue for vectorization

### Phase 4: Monitoring & Management

**Tools to create:**
- `bin/gtd-vector-status` - Check queue status
- `bin/gtd-vector-purge` - Clear failed messages
- `bin/gtd-vector-retry` - Retry failed messages

## Message Format

```json
{
  "content_type": "daily_log",
  "content_id": "2024-01-15",
  "content_text": "Today I worked on...",
  "metadata": {
    "date": "2024-01-15",
    "user": "Abby",
    "tags": ["work", "coding"]
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "retry_count": 0
}
```

## Implementation Steps

### Step 1: Set Up RabbitMQ

```bash
# Install RabbitMQ (macOS)
brew install rabbitmq

# Start RabbitMQ
brew services start rabbitmq

# Or use Docker
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

### Step 2: Create RabbitMQ Helper Module

Create `zsh/functions/gtd_rabbitmq.py` with:
- Connection management
- Queue operations
- Message publishing
- Message consumption helpers

### Step 3: Create Background Worker

Create `mcp/gtd_vector_worker.py`:
- Worker class that consumes from queue
- Integrates with `gtd_vectorization.py`
- Handles errors and retries

### Step 4: Update Vectorization Module

Modify `gtd_vectorization.py`:
- Add `vectorize_async()` function that queues messages
- Add `vectorize_sync()` function for immediate processing
- Choose mode based on `RABBITMQ_ENABLED` config

### Step 5: Integration

Update GTD scripts to call vectorization:
- `gtd-daily-log` - After log creation
- `gtd-wizard` - After task/project creation
- `gtd_mcp_server.py` - After task creation via MCP

## Testing Plan

1. **Unit Tests**
   - Test database connection and schema
   - Test embedding generation
   - Test vector storage and retrieval
   - Test similarity search

2. **Integration Tests**
   - Test end-to-end vectorization flow
   - Test RabbitMQ queue operations
   - Test worker processing
   - Test error handling and retries

3. **Performance Tests**
   - Batch vectorization performance
   - Search query performance
   - Queue throughput

## Dependencies

### Python Packages

```bash
pip install psycopg2-binary  # PostgreSQL driver
# pgvector extension installed in PostgreSQL

# For RabbitMQ (when ready)
pip install pika  # RabbitMQ client
```

### PostgreSQL Extensions

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

## Next Steps

1. ✅ **Database Setup** - Complete
2. ✅ **Vectorization Module** - Complete
3. ⏳ **RabbitMQ Setup** - Pending user setup
4. ⏳ **Worker Implementation** - Ready to implement when RabbitMQ is ready
5. ⏳ **Integration** - Ready to integrate when worker is ready

## Questions for User

1. **RabbitMQ Setup**: When would you like to set up RabbitMQ? We can proceed with direct (synchronous) vectorization for now.

2. **Content Types**: Which content types should be vectorized?
   - Daily logs ✓
   - Tasks ✓
   - Projects ✓
   - Notes?
   - Suggestions?

3. **Batch Processing**: Should we process existing content in batches, or only new content?

4. **Search Integration**: Where should vector search be integrated?
   - GTD wizard?
   - MCP server?
   - Standalone search command?

## Usage Examples

### Direct Vectorization (Current)

```python
from zsh.functions.gtd_vectorization import vectorize_content

# Vectorize a daily log
vectorize_content(
    content_type="daily_log",
    content_id="2024-01-15",
    content_text="Today I worked on the vector database...",
    metadata={"date": "2024-01-15"}
)
```

### Async Vectorization (Future)

```python
from zsh.functions.gtd_vectorization import vectorize_async

# Queue for async processing
vectorize_async(
    content_type="daily_log",
    content_id="2024-01-15",
    content_text="Today I worked on the vector database...",
    metadata={"date": "2024-01-15"}
)
```

### Search

```python
from zsh.functions.gtd_vectorization import search_similar

# Search for similar content
results = search_similar(
    query_text="working on database setup",
    content_type="daily_log",
    limit=5
)
```

