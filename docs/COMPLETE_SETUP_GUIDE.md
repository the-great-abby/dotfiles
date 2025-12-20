# Complete Installation & Setup Guide

This guide walks you through the complete setup of the GTD system, including external services (database and RabbitMQ) and AI hosts (LM Studio or Ollama).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Configuration](#initial-configuration)
3. [Download External Service Repositories](#download-external-service-repositories)
4. [Setup PostgreSQL Database](#setup-postgresql-database)
5. [Setup RabbitMQ Message Queue](#setup-rabbitmq-message-queue)
6. [Setup AI Host (LM Studio or Ollama)](#setup-ai-host-lm-studio-or-ollama)
7. [Configure GTD System](#configure-gtd-system)
8. [Wizard-Based Setup Walkthrough](#wizard-based-setup-walkthrough)
9. [Verification & Testing](#verification--testing)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- **Kubernetes cluster** running (minikube, kind, or other)
- **kubectl** configured and connected to your cluster
- **Git** installed
- **Python 3.11+** installed (for MCP server and workers)
- **Make** installed (for running Makefile targets)
- **Access to the internet** (for downloading models)

---

## Initial Configuration

### 1. Clone and Setup Dotfiles

If you haven't already:

```bash
# Clone your dotfiles repository
git clone <your-dotfiles-repo> ~/code/dotfiles
cd ~/code/dotfiles

# Ensure scripts are executable
chmod +x bin/*
chmod +x mcp/setup.sh
```

### 2. Start GTD Wizard

```bash
gtd-wizard
```

The wizard provides an interactive menu for all setup tasks. We'll use it throughout this guide.

---

## Download External Service Repositories

You need two external service repositories for database and RabbitMQ.

### Database Repository

**Repository**: https://github.com/the-great-abby/postgres_databases

```bash
# Create external_services directory
mkdir -p ~/code/external_services
cd ~/code/external_services

# Clone the database repository
git clone https://github.com/the-great-abby/postgres_databases.git database
cd database

# Verify the repository
ls -la
# Should show: Makefile, README.md, and Kubernetes YAML files
```

### RabbitMQ Repository

**Repository**: https://github.com/the-great-abby/message_queue

```bash
# Navigate to external_services (if not already there)
cd ~/code/external_services

# Clone the RabbitMQ repository
git clone https://github.com/the-great-abby/message_queue.git rabbitmq
cd rabbitmq

# Verify the repository
ls -la
# Should show: Makefile, README.md, and Kubernetes YAML files
```

### Verify Setup

```bash
# Check both repositories are in place
ls -la ~/code/external_services/
# Should show:
#   database/
#   rabbitmq/
```

---

## Setup PostgreSQL Database

The database is used for vector storage (pgvector extension) and storing GTD system data.

### Quick Setup (Recommended)

```bash
# Navigate to database directory
cd ~/code/external_services/database

# Deploy PostgreSQL to Kubernetes
make setup

# Wait for database to be ready (usually 30-60 seconds)
kubectl wait --for=condition=ready pod -l app=postgres -n postgres-system --timeout=120s

# Get connection information
make connection-info
```

This will show:
- **NodePort**: Typically `30003` for PostgreSQL
- **Node IP**: Your Kubernetes node IP (e.g., `192.168.64.2`)
- **Connection string**: Use this in your GTD configuration

### Manual Setup (Alternative)

If you prefer manual setup or need custom configuration:

```bash
cd ~/code/external_services/database

# 1. Review configuration files
cat namespace.yaml
cat deployment.yaml
cat services.yaml

# 2. Create namespace
kubectl apply -f namespace.yaml

# 3. Create persistent volume (if using PVC)
kubectl apply -f pvc.yaml  # if exists

# 4. Deploy PostgreSQL
kubectl apply -f deployment.yaml
kubectl apply -f services.yaml

# 5. Wait for pod to be ready
kubectl get pods -n postgres-system -w
# Press Ctrl+C when pod shows "Running"

# 6. Check service
kubectl get svc -n postgres-system

# 7. Get NodePort connection info
kubectl get svc postgres -n postgres-system -o jsonpath='{.spec.ports[?(@.port==5432)].nodePort}'
```

### Verify Database Connection

```bash
# Check pod status
kubectl get pods -n postgres-system

# Check service
kubectl get svc -n postgres-system

# Test connection (if you have psql installed)
# Replace NODE_IP and PORT with values from connection-info
psql -h <NODE_IP> -p <NODE_PORT> -U postgres -d postgres
```

### Database Configuration

The database should be accessible at:
- **Host**: `<NODE_IP>` (e.g., `192.168.64.2`)
- **Port**: `30003` (default NodePort)
- **Database**: `gtd_organization_system` (created during GTD setup)
- **User**: `gtd_organization_system` (created during GTD setup)
- **Password**: `gtd_organization_system` (default, change in production)

---

## Setup RabbitMQ Message Queue

RabbitMQ is used for asynchronous background processing (vectorization, deep analysis, etc.).

### Quick Setup (Recommended)

```bash
# Navigate to RabbitMQ directory
cd ~/code/external_services/rabbitmq

# Deploy RabbitMQ to Kubernetes
make setup

# Wait for RabbitMQ to be ready (usually 30-60 seconds)
kubectl wait --for=condition=ready pod -l app=rabbitmq -n rabbitmq-system --timeout=120s

# Get connection information
make connection-info
```

This will show:
- **AMQP URL**: Typically `amqp://<NODE_IP>:30672`
- **Management UI**: `http://<NODE_IP>:31672`
- **Default credentials**: `guest` / `guest`

### Access Management UI

1. Get connection info: `cd ~/code/external_services/rabbitmq && make connection-info`
2. Open the Management UI URL in your browser (e.g., `http://192.168.64.2:31672`)
3. Login with `guest` / `guest`

### Manual Setup (Alternative)

```bash
cd ~/code/external_services/rabbitmq

# 1. Review configuration files
cat namespace.yaml
cat deployment.yaml
cat services.yaml

# 2. Create namespace
kubectl apply -f namespace.yaml

# 3. Create persistent volume (if using PVC)
kubectl apply -f pvc.yaml  # if exists

# 4. Deploy RabbitMQ
kubectl apply -f deployment.yaml
kubectl apply -f services.yaml

# 5. Wait for pod to be ready
kubectl get pods -n rabbitmq-system -w
# Press Ctrl+C when pod shows "Running"

# 6. Check service
kubectl get svc -n rabbitmq-system

# 7. Get NodePort connection info
kubectl get svc rabbitmq -n rabbitmq-system -o jsonpath='{.spec.ports[?(@.port==5672)].nodePort}'
```

### Verify RabbitMQ Connection

```bash
# Check pod status
kubectl get pods -n rabbitmq-system

# Check service
kubectl get svc -n rabbitmq-system

# Test connection (using rabbitmq-admin or python pika)
python3 -c "import pika; conn = pika.BlockingConnection(pika.ConnectionParameters('<NODE_IP>', 30672)); print('Connected!'); conn.close()"
```

### RabbitMQ Configuration

RabbitMQ should be accessible at:
- **AMQP URL**: `amqp://<NODE_IP>:30672` (default NodePort)
- **Management UI**: `http://<NODE_IP>:31672`
- **User**: `guest`
- **Password**: `guest`

---

## Setup AI Host (LM Studio or Ollama)

You need to choose and setup one AI backend for the GTD system.

### Option 1: LM Studio (Recommended for macOS/Windows)

LM Studio is a desktop application that makes it easy to run local LLMs.

#### Download and Install

1. **Download LM Studio**:
   - Visit: https://lmstudio.ai/
   - Download for your OS (macOS, Windows, or Linux)
   - Install the application

2. **Open LM Studio** and complete initial setup

#### Download Models

1. In LM Studio, go to the **Search** tab
2. Search for and download models:
   - **Fast model** (for quick responses): `qwen/qwen3-1.7b` or `google/gemma-3-1b`
   - **Deep model** (for analysis): `gpt-oss-20b` or similar larger model

3. Models will be downloaded to your local disk

#### Configure and Start Server

1. **Load a model**:
   - Go to **Chat** tab
   - Select a model from the dropdown
   - Click **Load** to load it into memory

2. **Start Local Server**:
   - Go to **Server** tab
   - Click **Start Server**
   - Default port: `1234`
   - Keep the server running

3. **Test the server**:
   ```bash
   curl http://localhost:1234/v1/models
   ```

#### Configure GTD System

Update your GTD configuration:

```bash
# Edit config file
nano ~/code/dotfiles/zsh/.gtd_config
# or
vim ~/code/dotfiles/zsh/.gtd_config
```

Set these values:

```bash
# AI Backend
AI_BACKEND="lmstudio"

# LM Studio Configuration
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_CHAT_MODEL="qwen/qwen3-1.7b"  # Use the exact model name from LM Studio
LM_STUDIO_EMBEDDING_MODEL="text-embedding-nomic-embed-text-v2-moe"
```

**Note**: Use the exact model name that appears in LM Studio's model list.

### Option 2: Ollama (Recommended for Linux)

Ollama is a command-line tool for running local LLMs.

#### Install Ollama

**macOS**:
```bash
brew install ollama
```

**Linux**:
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows**: Download from https://ollama.com/

#### Start Ollama Server

```bash
# Start the server (runs in background)
ollama serve

# Or run as a service (systemd on Linux)
# sudo systemctl enable ollama
# sudo systemctl start ollama
```

#### Download Models

```bash
# Download fast model
ollama pull qwen2.5:1.5b

# Download deep model (optional, for analysis)
ollama pull llama3.1:8b

# List downloaded models
ollama list
```

#### Configure GTD System

Update your GTD configuration:

```bash
# Edit config file
nano ~/code/dotfiles/zsh/.gtd_config
# or
vim ~/code/dotfiles/zsh/.gtd_config
```

Set these values:

```bash
# AI Backend
AI_BACKEND="ollama"

# Ollama Configuration
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
OLLAMA_CHAT_MODEL="qwen2.5:1.5b"  # Use the model name from ollama list
```

#### Test Ollama

```bash
# Test chat completion
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:1.5b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

### Switching Between Backends

You can switch between LM Studio and Ollama at any time:

```bash
gtd-wizard
→ 27) ⚙️ Configuration & Setup
→ 1) Configure AI Backend (LM Studio/Ollama)
```

Or edit the config file directly and change `AI_BACKEND="lmstudio"` to `AI_BACKEND="ollama"` (or vice versa).

---

## Configure GTD System

Now that external services and AI hosts are set up, configure the GTD system to use them.

### Method 1: Interactive Wizard (Recommended)

The easiest way is through the wizard:

```bash
gtd-wizard
```

#### Step-by-Step Wizard Configuration

1. **Configuration & Setup**:
   ```
   → 27) ⚙️ Configuration & Setup
   ```

2. **Configure AI Backend**:
   ```
   → 1) Configure AI Backend (LM Studio/Ollama)
   → Select: LM Studio or Ollama
   → Enter model name (must match exactly)
   → Enter URL (usually default is fine)
   ```

3. **Setup MCP Server & Virtualenv**:
   ```
   → 6) 🔧 Setup MCP Server & Virtualenv
   → 1) Run MCP Server Setup
   → Say "yes" to installing watchdog (needed for filewatcher)
   ```

4. **Setup Database Connection**:
   ```
   → 63) 🗄️ Database Infrastructure Wizard
   → 1) Setup Database Connection
   → Enter host: <NODE_IP> (from database connection-info)
   → Enter port: 30003 (or your NodePort)
   → Enter database name: gtd_organization_system
   → Enter user: gtd_organization_system
   → Enter password: gtd_organization_system
   ```

5. **Setup RabbitMQ Connection**:
   ```
   → 64) 🐰 RabbitMQ Management Wizard
   → 1) Setup RabbitMQ Connection
   → Enter AMQP URL: amqp://<NODE_IP>:30672 (from RabbitMQ connection-info)
   → Enter username: guest
   → Enter password: guest
   → Enable RabbitMQ: Yes
   ```

6. **Verify Configuration**:
   ```
   → 27) ⚙️ Configuration & Setup
   → 4) View Current Configuration
   → Check that all services show as configured
   ```

### Method 2: Manual Configuration

If you prefer manual setup, edit the configuration files directly:

#### Database Configuration

Edit `~/code/dotfiles/zsh/.gtd_config_database`:

```bash
# Vector Database Configuration
VECTOR_DB_HOST="192.168.64.2"  # Your Kubernetes node IP
VECTOR_DB_PORT="30003"         # NodePort from connection-info
VECTOR_DB_NAME="gtd_organization_system"
VECTOR_DB_USER="gtd_organization_system"
VECTOR_DB_PASSWORD="gtd_organization_system"

# Enable vectorization
GTD_VECTORIZATION_ENABLED=true
```

#### RabbitMQ Configuration

Edit `~/code/dotfiles/zsh/.gtd_config_database`:

```bash
# RabbitMQ Configuration
RABBITMQ_ENABLED=true
RABBITMQ_URL="amqp://192.168.64.2:30672"  # Your Kubernetes node IP and NodePort
RABBITMQ_USER="guest"
RABBITMQ_PASS="guest"
RABBITMQ_VECTOR_QUEUE="gtd_vectorization"
```

#### AI Configuration

Edit `~/code/dotfiles/zsh/.gtd_config`:

```bash
# AI Backend
AI_BACKEND="lmstudio"  # or "ollama"

# LM Studio (if using)
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_CHAT_MODEL="qwen/qwen3-1.7b"  # Exact model name
LM_STUDIO_EMBEDDING_MODEL="text-embedding-nomic-embed-text-v2-moe"

# Ollama (if using)
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
OLLAMA_CHAT_MODEL="qwen2.5:1.5b"  # Model name from ollama list
```

---

## Wizard-Based Setup Walkthrough

For first-time setup, follow this complete walkthrough using the wizard:

### Phase 1: Initial Setup

```bash
# 1. Start wizard
gtd-wizard

# 2. Configure basic settings
→ 27) ⚙️ Configuration & Setup
→ Configure user name, directories, etc.
```

### Phase 2: External Services Setup

```bash
# 3. Setup Database
→ 63) 🗄️ Database Infrastructure Wizard
→ 1) Setup Database Connection
→ Enter connection details from: cd ~/code/external_services/database && make connection-info

# 4. Setup RabbitMQ
→ 64) 🐰 RabbitMQ Management Wizard
→ 1) Setup RabbitMQ Connection
→ Enter connection details from: cd ~/code/external_services/rabbitmq && make connection-info
```

### Phase 3: AI Host Setup

```bash
# 5. Configure AI Backend
→ 27) ⚙️ Configuration & Setup
→ 1) Configure AI Backend (LM Studio/Ollama)
→ Follow prompts to configure your chosen backend
```

### Phase 4: MCP Server Setup

```bash
# 6. Setup MCP Server
→ 27) ⚙️ Configuration & Setup
→ 6) 🔧 Setup MCP Server & Virtualenv
→ 1) Run MCP Server Setup
→ Say "yes" to watchdog installation
```

### Phase 5: Start Services

```bash
# 7. Start background workers
→ 17) 📊 System status
→ 3) Background Worker Status
→ 3) Start All Workers
```

---

## Verification & Testing

After setup, verify everything is working:

### 1. Check External Services

```bash
# Database
cd ~/code/external_services/database
make status

# RabbitMQ
cd ~/code/external_services/rabbitmq
make status
```

### 2. Check AI Host

**LM Studio**:
```bash
curl http://localhost:1234/v1/models
```

**Ollama**:
```bash
ollama list
curl http://localhost:11434/v1/models
```

### 3. Test GTD System Configuration

```bash
gtd-wizard
→ 17) 📊 System status
→ View all status indicators
```

All services should show as "configured" or "running".

### 4. Test Vectorization

```bash
# Create a test task
gtd-task add "Test task for vectorization"

# Check RabbitMQ queue (should show a job)
cd ~/code/external_services/rabbitmq
make queue-list

# Check database (vector should be stored)
# This requires database access tools
```

### 5. Test AI Integration

```bash
# Test AI suggestions
gtd-wizard
→ 24) 🤖 AI Suggestions & MCP Tools
→ 1) Get task suggestions
→ Enter some text and see if AI responds
```

---

## Troubleshooting

### Database Connection Issues

**Problem**: Cannot connect to database

**Solutions**:
1. Verify database is running:
   ```bash
   kubectl get pods -n postgres-system
   ```

2. Check NodePort:
   ```bash
   kubectl get svc -n postgres-system
   ```

3. Verify network connectivity:
   ```bash
   # Test connection
   psql -h <NODE_IP> -p 30003 -U postgres
   ```

4. Check firewall rules (if using cloud Kubernetes)

### RabbitMQ Connection Issues

**Problem**: Cannot connect to RabbitMQ

**Solutions**:
1. Verify RabbitMQ is running:
   ```bash
   kubectl get pods -n rabbitmq-system
   ```

2. Check NodePort:
   ```bash
   kubectl get svc -n rabbitmq-system
   ```

3. Test connection:
   ```bash
   python3 -c "import pika; conn = pika.BlockingConnection(pika.ConnectionParameters('<NODE_IP>', 30672)); print('OK'); conn.close()"
   ```

4. Check Management UI:
   ```bash
   cd ~/code/external_services/rabbitmq
   make connection-info
   # Open Management UI in browser
   ```

### AI Host Issues

**LM Studio**:
- **Problem**: Connection refused
  - Solution: Make sure LM Studio server is started (Server tab → Start Server)
  - Check port matches configuration (default 1234)

- **Problem**: Model not found
  - Solution: Verify model name matches exactly what's in LM Studio
  - Load the model in LM Studio before making requests

**Ollama**:
- **Problem**: Connection refused
  - Solution: Start Ollama server: `ollama serve`
  - Check it's running: `ps aux | grep ollama`

- **Problem**: Model not found
  - Solution: Pull the model: `ollama pull <model-name>`
  - Verify: `ollama list`

### Configuration Issues

**Problem**: Settings not taking effect

**Solutions**:
1. Verify config files are being sourced:
   ```bash
   # Check if config is loaded
   grep -r "GTD_BASE_DIR" ~/code/dotfiles/zsh/
   ```

2. Restart terminal or source config:
   ```bash
   source ~/code/dotfiles/zsh/.gtd_config
   ```

3. Check for typos in config values (especially model names)

### Wizard Not Showing Options

**Problem**: Wizard menu items missing

**Solutions**:
1. Update to latest dotfiles:
   ```bash
   cd ~/code/dotfiles
   git pull
   ```

2. Check script permissions:
   ```bash
   chmod +x bin/gtd-wizard*
   ```

3. Verify external service repos are in place:
   ```bash
   ls -la ~/code/external_services/
   ```

---

## Quick Reference

### Repository Locations

- **Dotfiles**: `~/code/dotfiles`
- **Database**: `~/code/external_services/database`
- **RabbitMQ**: `~/code/external_services/rabbitmq`

### Key Commands

```bash
# Database
cd ~/code/external_services/database && make setup
cd ~/code/external_services/database && make connection-info
cd ~/code/external_services/database && make status

# RabbitMQ
cd ~/code/external_services/rabbitmq && make setup
cd ~/code/external_services/rabbitmq && make connection-info
cd ~/code/external_services/rabbitmq && make status

# GTD Wizard
gtd-wizard

# System Status
gtd-wizard → 17) System status
```

### Configuration Files

- **GTD Config**: `~/code/dotfiles/zsh/.gtd_config`
- **Database Config**: `~/code/dotfiles/zsh/.gtd_config_database`
- **Daily Log Config**: `~/code/dotfiles/zsh/.daily_log_config`

---

## Next Steps

After completing setup:

1. **Read the main documentation**: See `README.md` in the dotfiles repo
2. **Explore features**: Use `gtd-wizard` to discover available features
3. **Setup additional features**:
   - Vector filewatcher (optional but recommended)
   - Background workers
   - Calendar integration
   - Health tracking

4. **Review setup checklist**: See `docs/SETUP_CHECKLIST.md` for additional optional features

---

## Additional Resources

- **Database Repository**: https://github.com/the-great-abby/postgres_databases
- **RabbitMQ Repository**: https://github.com/the-great-abby/message_queue
- **LM Studio**: https://lmstudio.ai/
- **Ollama**: https://ollama.com/
- **Setup Checklist**: `docs/SETUP_CHECKLIST.md`
- **MCP Setup**: `mcp/README.md`
- **LM Studio Setup**: `mcp/LM_STUDIO_SETUP.md`

---

**Happy organizing! 🎉**

