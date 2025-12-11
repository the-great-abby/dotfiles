# Setup Checklist for New Computer

When transferring your dotfiles to a new computer, follow this checklist:

## Initial Setup

### 1. Basic Configuration
```bash
gtd-wizard
→ 1) Configuration & Setup
→ Follow the prompts to configure:
   - AI backend (LM Studio/Ollama)
   - User name
   - Directory paths
```

### 2. MCP Server & Virtualenv
```bash
gtd-wizard
→ 1) Configuration & Setup
→ 6) 🔧 Setup MCP Server & Virtualenv
```

This installs:
- ✅ Python virtualenv
- ✅ MCP SDK
- ✅ pika (RabbitMQ client)
- ✅ watchdog (optional, for filewatcher)
- ✅ Creates necessary directories

**Tip:** Say "yes" when asked about installing watchdog - it's needed for the filewatcher!

### 3. RabbitMQ Setup (Optional but Recommended)
```bash
gtd-wizard
→ 1) Configuration & Setup
→ 9) 🐰 Setup RabbitMQ Connection
→ 2) 🔌 Start Port-Forward
```

For async processing - makes vectorization much faster.

### 4. Vector Filewatcher Setup (Optional but Recommended)
```bash
gtd-wizard
→ 1) Configuration & Setup
→ 10) 📁 Setup Vector Filewatcher
```

**Quick setup:**
1. Choose `2) Configure Watch Directories` - accepts defaults or custom
2. Choose `3) Setup Symlinks` if you want to monitor external directories
3. Choose `4) Start Filewatcher` to begin monitoring

**With symlinks (for external directories):**
```bash
# Option 3 in filewatcher menu will:
# - Create ~/Documents/gtd/watched directory
# - Help you symlink external directories
# - Configure filewatcher to watch the symlink directory
```

### 5. Start Background Workers
```bash
gtd-wizard
→ 17) System status
→ 3) Background Worker Status
→ 3) Start All Workers
```

Or via Makefile:
```bash
make worker-deep-start
make worker-vector-start
```

### 6. Verify Everything Works

```bash
# Check workers
make worker-status

# Check RabbitMQ (if enabled)
make rabbitmq-status

# Check filewatcher (if enabled)
make filewatcher-status
```

## Quick Setup Command Sequence

For a new computer, run these in order:

```bash
# 1. Basic setup
gtd-wizard → 1) Configuration & Setup → 6) Setup MCP Server & Virtualenv
# (Say yes to watchdog when prompted)

# 2. RabbitMQ (optional)
gtd-wizard → 1) Configuration & Setup → 9) Setup RabbitMQ → 2) Start Port-Forward

# 3. Filewatcher (optional)
gtd-wizard → 1) Configuration & Setup → 10) Setup Vector Filewatcher → 2) Configure → 4) Start

# 4. Start workers
gtd-wizard → 17) System status → 3) Background Worker Status → 3) Start All Workers
```

## What Gets Configured

### Configuration Files Created/Updated:
- `~/.gtd_config` - Core GTD settings
- `~/.gtd_config_database` - Database & RabbitMQ settings
- `~/.daily_log_config` - Daily log settings

### Directories Created:
- `~/Documents/gtd/` - GTD base directory
- `~/Documents/daily_logs/` - Daily logs
- `~/Documents/gtd/watched/` - Symlink directory (if using filewatcher)

### Services Started:
- Background workers (process jobs from queue)
- Vector filewatcher (monitors directories)
- Port-forward (if using RabbitMQ in Kubernetes)

## Testing Your Setup

1. **Test vectorization:**
   ```bash
   gtd-task "Test task"
   # Check: make rabbitmq-status (should show job queued)
   ```

2. **Test filewatcher:**
   ```bash
   # Create a test file
   echo "Test content" > ~/Documents/gtd/test.md
   # Wait 5 seconds, check: make rabbitmq-status
   ```

3. **Test deep analysis:**
   ```bash
   gtd-wizard → 24) AI Suggestions → 7) Trigger weekly review
   # Check: ~/Documents/gtd/deep_analysis_results/
   ```

## Troubleshooting

### Workers Not Starting
- Check Python virtualenv: `ls ~/code/dotfiles/mcp/venv`
- Check dependencies: `~/code/dotfiles/mcp/venv/bin/pip list`

### Filewatcher Not Working
- Check watchdog installed: `~/code/dotfiles/mcp/venv/bin/python3 -c "import watchdog"`
- Check directories exist: `ls -la ~/Documents/gtd/watched`
- Check filewatcher running: `ps aux | grep gtd_vector_filewatcher`

### RabbitMQ Not Connecting
- Check port-forward: `ps aux | grep "kubectl port-forward.*5672"`
- Test connection: `make rabbitmq-status`

## Summary

✅ **Essential:**
1. Basic configuration
2. MCP Server setup

✅ **Recommended:**
3. RabbitMQ setup
4. Vector filewatcher setup
5. Start background workers

Everything is now part of the wizard setup process - just follow the menus!
