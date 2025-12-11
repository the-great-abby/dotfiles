# Deep Analysis Auto-Scheduler

## Overview

The Deep Analysis Auto-Scheduler automatically submits deep analysis jobs (weekly reviews, energy analysis, insights, connections) to the queue based on schedules and event-driven triggers.

This works alongside the vector filewatcher - while the filewatcher automatically queues files for vectorization, the scheduler automatically queues deep analysis jobs.

## How It Works

1. **Scheduled Analysis** - Runs analyses on a schedule (e.g., weekly review every Monday, energy analysis every 3 days)
2. **Event-Driven Triggers** - Automatically triggers analyses when content is created (e.g., energy analysis when a daily log is created)
3. **Daemon Mode** - A background daemon periodically checks if scheduled analyses should run
4. **One-Time Runs** - You can also run the scheduler manually to check for scheduled jobs

## Configuration

All configuration is in `.gtd_config_database`:

### Scheduled Analyses

```bash
# Weekly Review
DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW="true"
DEEP_ANALYSIS_WEEKLY_REVIEW_DAY="monday"  # monday, tuesday, etc.
DEEP_ANALYSIS_WEEKLY_REVIEW_TIME="09:00"  # HH:MM format

# Energy Analysis
DEEP_ANALYSIS_AUTO_ENERGY="true"
DEEP_ANALYSIS_ENERGY_INTERVAL="3"  # Every N days
DEEP_ANALYSIS_ENERGY_DAYS="7"  # Analyze last N days

# Insights
DEEP_ANALYSIS_AUTO_INSIGHTS="true"
DEEP_ANALYSIS_INSIGHTS_INTERVAL="1"  # Every N days

# Connections
DEEP_ANALYSIS_AUTO_CONNECTIONS="true"
DEEP_ANALYSIS_CONNECTIONS_INTERVAL="7"  # Every N days
```

### Event-Driven Triggers

```bash
# Trigger energy analysis when daily log is created
DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG="true"

# Trigger insights when content is created
DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT="true"

# Trigger connections when task is created
DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK="true"
```

## Setup

### Via Wizard (Recommended)

```bash
gtd-wizard → 1) Configuration & Setup → 11) 🧠 Setup Deep Analysis Auto-Scheduler
```

Options:
1. View Current Configuration
2. Configure Scheduled Analyses
3. Configure Event-Driven Triggers
4. Start Scheduler Daemon
5. Stop Scheduler Daemon
6. Check Scheduler Status
7. Run Scheduler Now (one-time check)

### Manual Setup

**1. Configure settings in `.gtd_config_database`:**
```bash
# Edit the config file
vim ~/code/dotfiles/zsh/.gtd_config_database

# Or via wizard
gtd-wizard → 1) Configuration & Setup → 8) Edit Configuration Files
```

**2. Start the scheduler daemon:**
```bash
make scheduler-start

# Or manually
gtd-deep-analysis-scheduler-daemon start
```

**3. Check status:**
```bash
make scheduler-status

# Or manually
gtd-deep-analysis-scheduler-daemon status
```

## Usage

### Running the Scheduler

**Daemon Mode (Recommended):**
```bash
# Start daemon (runs every 15 minutes by default)
make scheduler-start

# Check status
make scheduler-status

# Stop daemon
make scheduler-stop

# Restart
make scheduler-stop && make scheduler-start
```

**One-Time Run:**
```bash
# Check for scheduled jobs and queue them
make scheduler-run

# Or with dry-run to see what would be queued
gtd-deep-analysis-scheduler --dry-run
```

**Change Check Interval:**
```bash
# Set interval in minutes (default: 15)
export DEEP_ANALYSIS_SCHEDULER_INTERVAL=30
make scheduler-start
```

### Event-Driven Triggers

When event-driven triggers are enabled, analyses are automatically queued when:

- **Daily log created** → Energy analysis (if `DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=true`)
- **Task created** → Connections analysis (if `DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=true`)
- **Content created** → Insights (if `DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=true`)

These triggers are integrated into:
- `gtd-wizard-inputs.sh` - Daily log creation
- `bin/gtd-task` - Task creation
- (More triggers can be added as needed)

## How Scheduled Analyses Work

The scheduler tracks when each analysis was last run and only queues new jobs when:
- The schedule interval has passed (e.g., 3 days for energy analysis)
- It hasn't already run today (for weekly reviews)

State is stored in `~/Documents/gtd/.deep_analysis_scheduler_state.json`.

## Examples

### Example 1: Weekly Review Every Monday

```bash
# In .gtd_config_database:
DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW="true"
DEEP_ANALYSIS_WEEKLY_REVIEW_DAY="monday"
DEEP_ANALYSIS_WEEKLY_REVIEW_TIME="09:00"
```

The scheduler will automatically queue a weekly review every Monday at 9 AM.

### Example 2: Energy Analysis Every 3 Days

```bash
# In .gtd_config_database:
DEEP_ANALYSIS_AUTO_ENERGY="true"
DEEP_ANALYSIS_ENERGY_INTERVAL="3"
DEEP_ANALYSIS_ENERGY_DAYS="7"
```

The scheduler will automatically queue energy analysis every 3 days, analyzing the last 7 days.

### Example 3: Energy Analysis on Daily Log Creation

```bash
# In .gtd_config_database:
DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG="true"
DEEP_ANALYSIS_ENERGY_DAYS="7"
```

Every time you create a daily log entry, energy analysis for the last 7 days is automatically queued.

## Integration with Workers

The scheduler submits jobs to the same queue that workers consume:
- **RabbitMQ** (if enabled) - Jobs go to `gtd_deep_analysis` queue
- **File Queue** (fallback) - Jobs go to `~/Documents/gtd/deep_analysis_queue.jsonl`

Make sure your deep analysis worker is running:
```bash
make worker-deep-start
make worker-status
```

## Logs

**Scheduler Daemon Logs:**
```bash
tail -f ~/.gtd-deep-analysis-scheduler.log
```

**Worker Logs (processing the jobs):**
```bash
tail -f /tmp/deep-worker.log
```

## Troubleshooting

### Scheduler Not Running Scheduled Jobs

1. **Check daemon is running:**
   ```bash
   make scheduler-status
   ```

2. **Check configuration:**
   ```bash
   grep DEEP_ANALYSIS ~/code/dotfiles/zsh/.gtd_config_database
   ```

3. **Check logs:**
   ```bash
   tail -20 ~/.gtd-deep-analysis-scheduler.log
   ```

4. **Run manually to test:**
   ```bash
   gtd-deep-analysis-scheduler --dry-run
   ```

### Event-Driven Triggers Not Working

1. **Verify trigger is enabled:**
   ```bash
   grep DEEP_ANALYSIS_TRIGGER ~/code/dotfiles/zsh/.gtd_config_database
   ```

2. **Check if scheduler script is accessible:**
   ```bash
   which gtd-deep-analysis-scheduler
   ```

3. **Test trigger manually:**
   ```bash
   gtd-deep-analysis-scheduler --trigger energy
   ```

### Jobs Queued But Not Processing

1. **Check worker is running:**
   ```bash
   make worker-status
   ```

2. **Check queue status:**
   ```bash
   make rabbitmq-status
   # Or check file queue
   wc -l ~/Documents/gtd/deep_analysis_queue.jsonl
   ```

3. **Check worker logs:**
   ```bash
   tail -f /tmp/deep-worker.log
   ```

## Summary

✅ **Scheduled Analyses** - Automatic weekly reviews, energy analysis, insights, connections  
✅ **Event-Driven Triggers** - Automatic analysis when content is created  
✅ **Daemon Mode** - Background service that checks schedules periodically  
✅ **One-Time Runs** - Manual execution when needed  
✅ **Integrated** - Works with existing RabbitMQ/file queue system  

Perfect for automatically getting deep analysis insights without manual intervention!
