# GTD Unified System - MCP Server

Model Context Protocol (MCP) server for the GTD Unified System, providing AI-powered task suggestions, deep analysis, and intelligent automation.

## Architecture

### Two-Tier AI System

1. **Fast Layer (Gemma 1b)**: Quick, templated prompts for:
   - Task suggestions from text
   - Immediate responses
   - Auto-suggestions with banter
   - Fast task creation

2. **Deep Layer (GPT-OSS 20b)**: Background analysis for:
   - Weekly reviews
   - Energy pattern analysis
   - Connection finding
   - Deep insights

### Components

- **`gtd_mcp_server.py`**: Main MCP server with all tools
- **`gtd_auto_suggest.py`**: Intelligent auto-suggestion system with banter
- **`gtd_deep_analysis_worker.py`**: Background worker for deep analysis
- **Configuration**: Uses existing `.gtd_config` file

## Setup

### 1. Install Dependencies

```bash
pip install mcp pika  # pika is optional (for RabbitMQ)
```

### 2. Configure MCP Server in Cursor

Add to your Cursor MCP settings:

```json
{
  "mcpServers": {
    "gtd-unified-system": {
      "command": "python3",
      "args": [
        "/Users/abby/code/dotfiles/mcp/gtd_mcp_server.py"
      ],
      "env": {
        "GTD_USER_NAME": "Abby",
        "GTD_DEEP_MODEL_URL": "http://gpt-oss-20b:8080/v1/chat/completions",
        "GTD_RABBITMQ_URL": "amqp://localhost:5672"
      }
    }
  }
}
```

### 3. Configure Deep Analysis Worker

#### Option A: Kubernetes/RabbitMQ (Production)

```yaml
# Deployment for Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gtd-deep-analysis-worker
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: worker
        image: your-registry/gtd-worker:latest
        command: ["python3", "/app/gtd_deep_analysis_worker.py"]
        env:
        - name: GTD_DEEP_MODEL_URL
          value: "http://gpt-oss-20b:8080/v1/chat/completions"
        - name: GTD_RABBITMQ_URL
          value: "amqp://rabbitmq:5672"
```

#### Option B: Local File Queue (Development)

The system will automatically fall back to a file-based queue if RabbitMQ isn't available.

Start the worker manually:
```bash
python3 mcp/gtd_deep_analysis_worker.py file
```

Or run continuously:
```bash
watch -n 60 'python3 mcp/gtd_deep_analysis_worker.py file'
```

## Usage

### Fast Commands (Gemma 1b)

#### Suggest Tasks from Text

```python
# Via MCP
suggest_tasks_from_text(
    text="I need to finish the quarterly report by Friday and also schedule a team meeting",
    context="daily_log"
)
```

#### Create Tasks

```python
# Create from suggestion
create_tasks_from_suggestion(suggestion_id="abc-123")

# Create directly
create_task(
    title="Finish quarterly report",
    project="q4-planning",
    context="computer",
    priority="urgent_important"
)
```

#### Get Pending Suggestions

```python
get_pending_suggestions()
```

#### Complete/Defer Tasks

```python
complete_task(task_id="20250101120000-task")
defer_task(task_id="20250101120000-task", until="2025-01-15")
```

### Deep Analysis Commands (GPT-OSS 20b, Background)

These queue work for background processing:

```python
# Weekly review
weekly_review(week_start="2025-01-06")

# Analyze energy patterns
analyze_energy(days=7)

# Find connections
find_connections(scope="all")

# Generate insights
generate_insights(focus="productivity")
```

Results are saved to: `~/Documents/gtd/deep_analysis_results/`

### Auto-Suggestions with Banter

The auto-suggestion system analyzes daily log entries and provides contextual banter:

```bash
# Analyze recent logs and generate suggestions
python3 mcp/gtd_auto_suggest.py analyze 1

# Process a single log entry
python3 mcp/gtd_auto_suggest.py entry "Just finished a great workout, feeling energized!"

# Generate banter only
python3 mcp/gtd_auto_suggest.py banter "Struggling with this bug all day"
```

#### Integration with Daily Logging

Add to your daily log workflow to auto-suggest tasks:

```bash
# After logging, analyze and suggest
addInfoToDailyLog "your log entry"
python3 mcp/gtd_auto_suggest.py entry "$(tail -1 ~/Documents/daily_logs/$(date +%Y-%m-%d).txt | sed 's/^[0-9:]* - //')"
```

## Configuration

### Environment Variables

- `GTD_USER_NAME`: Your name (default: "Abby")
- `GTD_DEEP_MODEL_URL`: URL for GPT-OSS 20b (default: `http://gpt-oss-20b:8080/v1/chat/completions`)
- `GTD_DEEP_MODEL_NAME`: Model name (default: "gpt-oss-20b")
- `GTD_RABBITMQ_URL`: RabbitMQ connection string (default: `amqp://localhost:5672`)
- `GTD_RABBITMQ_QUEUE`: Queue name (default: "gtd_deep_analysis")

### Config File

Uses existing `~/.gtd_config` or `zsh/.gtd_config` for:
- GTD directory structure
- LM Studio URL (for fast model)
- Model names
- User settings

## Example Workflow

1. **Morning**: Log your day, get auto-suggestions with banter
   ```bash
   addInfoToDailyLog "Starting work on the new feature"
   python3 mcp/gtd_auto_suggest.py analyze 1
   ```

2. **During Day**: Use MCP tools via Cursor AI
   - AI suggests tasks from your notes
   - You approve and create tasks
   - System provides contextual banter

3. **Evening**: Review pending suggestions
   ```python
   get_pending_suggestions()  # See what AI suggested
   ```

4. **Weekly**: Deep analysis runs in background
   ```python
   weekly_review()  # Queues for 20b model
   # Results appear in ~/Documents/gtd/deep_analysis_results/
   ```

## Directory Structure

```
~/Documents/gtd/
├── suggestions/              # Pending task suggestions
│   └── {uuid}.json
├── deep_analysis_results/    # Results from deep analysis
│   └── weekly_review_20250106_120000.json
└── deep_analysis_queue.jsonl # File-based queue (fallback)
```

## Troubleshooting

### MCP Server Not Starting

- Check Python path: `which python3`
- Verify dependencies: `pip list | grep mcp`
- Check config file exists: `ls ~/.gtd_config`

### Deep Analysis Not Processing

- Check worker is running: `ps aux | grep gtd_deep_analysis_worker`
- Check queue file: `tail ~/Documents/gtd/deep_analysis_queue.jsonl`
- Check RabbitMQ connection (if using): `rabbitmqctl list_queues`

### Suggestions Not Generating

- Check LM Studio is running and model is loaded
- Verify model URL in config
- Check logs: `python3 mcp/gtd_auto_suggest.py entry "test"`

## Development

### Testing MCP Server

```bash
# Start server manually (for testing)
python3 mcp/gtd_mcp_server.py
```

### Testing Auto-Suggestions

```bash
# Test with sample entry
python3 mcp/gtd_auto_suggest.py entry "Need to review the PR and deploy the update"
```

### Testing Deep Analysis

```bash
# Test worker with file queue
python3 mcp/gtd_deep_analysis_worker.py file
```

## Future Enhancements

- [ ] Webhook integration for real-time suggestions
- [ ] Slack/Discord bot for suggestions
- [ ] Mobile app integration
- [ ] Advanced pattern recognition
- [ ] Predictive task scheduling
- [ ] Integration with calendar events

