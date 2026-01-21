# GTD System Dependencies

This document lists all external dependencies required for the GTD organization system.

## External Service Repositories

### 1. PostgreSQL Database with pgvector

**Repository**: `postgres_databases`  
**Location**: `~/code/external_services/database`  
**Purpose**: Vector database for semantic search

**Configuration**:
- Connection settings in `zsh/.gtd_config_database`
- Environment variables: `VECTOR_DB_HOST`, `VECTOR_DB_PORT`, `VECTOR_DB_NAME`, etc.
- Mode-specific settings for work/home computers

**Setup**:
```bash
cd ~/code/external_services
git clone https://github.com/the-great-abby/postgres_databases.git database
cd database
make start  # Deploy to Kubernetes
```

**Dependencies**:
- Kubernetes cluster (Rancher Desktop, minikube, or kind)
- kubectl configured
- PostgreSQL 15+ with pgvector extension

### 2. RabbitMQ Message Queue

**Repository**: `rabbitmq`  
**Location**: `~/code/external_services/rabbitmq`  
**Purpose**: Async message processing

**Configuration**:
- Connection settings in `zsh/.gtd_config_database`
- Environment variables: `RABBITMQ_URL`, `RABBITMQ_USER`, `RABBITMQ_PASS`
- Mode-specific settings for work/home computers

**Setup**:
```bash
cd ~/code/external_services
git clone <rabbitmq-repo> rabbitmq
cd rabbitmq
make setup  # Deploy to Kubernetes
```

**Dependencies**:
- Kubernetes cluster
- kubectl configured

**Queues Used**:
- `gtd_deep_analysis` - Deep analysis tasks
- `gtd_vectorization` - Vectorization tasks
- `gtd_advice` - Advice requests

## System Dependencies

### Python

**Version**: 3.11+  
**Purpose**: MCP server, workers, and Python functions

**Setup**:
```bash
# Using asdf
asdf plugin add python
asdf install python latest
asdf global python latest

# Or using mise
mise plugin add python
mise install python@latest
mise use --global python@latest
```

**Virtual Environment**:
- Location: `mcp/venv/`
- Setup: `cd mcp && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`

**Python Packages** (see `mcp/requirements.txt`):
- pika (RabbitMQ client)
- psycopg2 (PostgreSQL client)
- And others (see requirements.txt)

### Shell Environment

**Bash**: 3.2+ (macOS compatibility requirement)  
**Zsh**: For interactive shell integration

**Note**: All scripts must be bash 3.2 compatible (no bash 4+ features)

### Kubernetes (Optional)

**Purpose**: Deploying external services (PostgreSQL, RabbitMQ)

**Options**:
- Rancher Desktop (recommended for local development)
- minikube
- kind
- Other Kubernetes distributions

**Configuration**:
- NodePort services (ports 30000-32767)
- Stable connections for development

## AI/LLM Backends

### Option 1: LM Studio

**Purpose**: Local LLM inference  
**Configuration**: `zsh/.gtd_config` and `zsh/.gtd_config_ai`

**Settings**:
- `AI_BACKEND="lmstudio"`
- `LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"`
- `LM_STUDIO_CHAT_MODEL="qwen/qwen3-1.7b"`
- `LM_STUDIO_EMBEDDING_MODEL="text-embedding-nomic-embed-text-v2-moe"`

**Setup**:
1. Install LM Studio
2. Download models
3. Start server on port 1234
4. Configure in `.gtd_config_ai`

### Option 2: Ollama

**Purpose**: Local LLM inference  
**Configuration**: `zsh/.gtd_config` and `zsh/.gtd_config_ai`

**Settings**:
- `AI_BACKEND="ollama"`
- `OLLAMA_URL="http://127.0.0.1:31080/v1/chat/completions"`
- Model configuration

**Setup**:
1. Install Ollama
2. Pull models: `ollama pull llama3.2-vision nomic-embed-text`
3. Configure Kubernetes service (if using k8s)
4. Configure in `.gtd_config_ai`

**Kubernetes Integration**:
- Ollama Controller for Kubernetes
- NodePort configuration
- See `docs/OLLAMA_KUBERNETES_SETUP.md`

## Data Directories

### GTD Data Directory

**Location**: `~/Documents/gtd/`  
**Structure**:
```
~/Documents/gtd/
├── 0-inbox/          # Inbox items
├── 1-projects/       # Projects
├── 2-areas/           # Areas of responsibility
├── 3-reference/       # Reference materials
├── 4-someday-maybe/   # Someday/Maybe items
├── 5-waiting-for/     # Waiting for items
├── 6-archive/         # Archived items
├── daily-logs/        # Daily log entries
└── weekly-reviews/    # Weekly review notes
```

**Configuration**: `zsh/.gtd_config` - `GTD_BASE_DIR`

### Daily Logs Directory

**Location**: `~/Documents/daily_logs/`  
**Format**: `YYYY-MM-DD.txt`

**Configuration**: `zsh/.daily_log_config`

### Personalization Data

**Location**: `~/.gtd_personalization.toon`  
**Format**: TOON (or JSON fallback)

**Purpose**: User personalization data for AI interactions

## System Tools

### Required Tools

- **make** - For running Makefile targets
- **git** - Version control
- **kubectl** - Kubernetes management (if using k8s)
- **gcalcli** - Google Calendar CLI (for calendar integration)

### Optional Tools

- **tmux** - Terminal multiplexer (GTD integration available)
- **vim/neovim** - Editor (GTD integration available)

## macOS-Specific

### Launchd

**Purpose**: Scheduled tasks and reminders

**Plists**:
- `com.gtd.auto-suggest.plist` - Auto suggestions
- `com.gtd.checkin-suggestions.plist` - Check-in suggestions
- `com.abby.gtd.*.plist` - Various reminders

**Location**: `launchd/` or `zsh/`

### Notifications

**System**: macOS Notification Center  
**Configuration**: `zsh/.gtd_config_notifications`

## Network Requirements

### Local Services

- LM Studio: `http://localhost:1234`
- Ollama: `http://127.0.0.1:31080` (or configured port)
- PostgreSQL: NodePort (e.g., `localhost:13003`)
- RabbitMQ: NodePort (e.g., `localhost:30672`)

### External Services

- Google Calendar API (for calendar integration)
- Internet access (for web search, model downloads)

## Configuration Files

### Main Configuration

- `zsh/.gtd_config` - Core settings
- `zsh/.gtd_config_database` - Database and RabbitMQ
- `zsh/.gtd_config_ai` - AI/LLM settings
- `zsh/.gtd_config_calendar` - Calendar settings
- `zsh/.gtd_config_capture` - Capture settings
- `zsh/.gtd_config_reviews` - Review settings
- `zsh/.gtd_config_notifications` - Notification settings

### Mode-Specific Configuration

The system supports different configurations for work vs home computers:
- Work mode: `*_WORK` environment variables
- Home mode: `*_HOME` environment variables
- Current mode: Set via `gtd-set-computer` command

## Installation Order

1. **System Dependencies**
   - Python 3.11+
   - Bash 3.2+
   - Zsh
   - make, git, kubectl

2. **External Services** (if using)
   - Kubernetes cluster
   - PostgreSQL database
   - RabbitMQ

3. **AI Backend**
   - LM Studio or Ollama
   - Download models

4. **GTD System**
   - Clone repository
   - Install Python dependencies
   - Configure settings
   - Set up data directories

5. **Integration**
   - Shell integration (zshrc)
   - Launchd plists (macOS)
   - PATH configuration

## Verification

### Check Dependencies

```bash
# Python
python3 --version  # Should be 3.11+

# Shell
bash --version  # Should be 3.2+ (macOS default)

# Kubernetes (if using)
kubectl version --client

# Services
gtd-worker-status  # Check workers
gtd-vector-db-status  # Check database
gtd-rabbitmq-status  # Check RabbitMQ
```

### Test Connections

```bash
# Test database
gtd-vector-db-status init

# Test RabbitMQ
bin/test_rabbitmq_connection.sh

# Test AI backend
gtd-advise --test "Hello"
```

## Troubleshooting

### Database Connection Issues

- Check NodePort configuration
- Verify PostgreSQL is running
- Check credentials in `.gtd_config_database`
- Test connection: `psql -h localhost -p 13003 -U postgres -d vector`

### RabbitMQ Connection Issues

- Check NodePort configuration
- Verify RabbitMQ is running
- Check credentials in `.gtd_config_database`
- Test connection: `bin/test_rabbitmq_connection.sh`

### AI Backend Issues

- Verify LM Studio/Ollama is running
- Check URL configuration
- Test model availability
- Check logs for errors

## Notes

- All external services are optional but recommended for full functionality
- System can run with minimal dependencies (just Python and shell)
- External services can be deployed locally or in cloud
- Configuration supports multiple environments (work/home)
