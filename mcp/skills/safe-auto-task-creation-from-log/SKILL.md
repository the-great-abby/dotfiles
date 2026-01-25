---
name: Safe Auto Task Creation from Log
description: Automatically extract actionable items from daily log entries and create GTD tasks with built-in duplicate prevention. Enhanced version that prevents conflicts between TUI and background workers.
version: 2.0.0
type: runbook
tags:
  - runbook
  - task-creation
  - daily-log
  - automatic
  - proactive
  - gtd
  - coordination
  - safe
author: GTD System
---

# Safe Auto Task Creation from Log Runbook

An enhanced, conflict-safe version of the auto task creation runbook that prevents duplicate operations between the interactive TUI and background workers.

## Purpose

This runbook transforms daily log analysis from passive review to active task creation while preventing conflicts:
- Automatically extracts commitments, follow-ups, and next actions from log entries
- Creates tasks immediately with **duplicate prevention**
- **Prevents conflicts** between TUI and background worker processing
- Sets appropriate priorities, contexts, and due dates
- Updates the daily log with created task references
- **Coordinates with other system processes** to avoid double-processing

## Key Enhancements over Basic Version

### 🛡️ **Conflict Prevention:**
- **Content fingerprinting** - Detects if log content was already processed
- **Operation locking** - Prevents simultaneous processing of same log
- **Duplicate task detection** - Avoids creating nearly identical tasks
- **Source tracking** - Records who created what and when

### 🔄 **Coordination Features:**
- **Lock acquisition** for exclusive log processing
- **Processing history** to prevent re-processing same content
- **Graceful handling** when another process is already working
- **Automatic cleanup** of stale locks and tracking files

## Prerequisites

1. **GTD system** properly configured with task creation capabilities
2. **Daily log** entries available for processing
3. **Enhanced GTD tools** loaded for coordination
4. **Coordination system** initialized

## Instructions for AI Agent

### Step 1: Initialize Coordination System

```python
# Load enhanced tools with coordination
from enhanced_gtd_tools import EnhancedGTDTools

# Initialize with source identifier
tools = EnhancedGTDTools(source="background_worker")  # or "tui", "advice", etc.
```

### Step 2: Get Daily Log Content

Use `gtd_read_daily_log()` to get today's log content:

```python
# Get today's daily log
log_result = gtd_read_daily_log(date="today")
log_content = log_result["content"] 
date = log_result["date"]
```

### Step 3: Safe Processing with Coordination

Use the enhanced processing method that includes all safety checks:

```python
# Process with built-in duplicate prevention
result = tools.process_daily_log_safe(log_content, date)

if result["status"] == "already_processed":
    print(f"✅ Log already processed: {result['message']}")
    return
elif result["status"] == "lock_timeout":
    print(f"⏰ Another process is working on this log: {result['message']}")
    return
elif result["status"] == "completed":
    print(f"🎯 Successfully processed log: {result['tasks_created']} tasks created")
```

## Pattern Recognition for Task Extraction

### High-Priority Action Patterns:
- **"Need to [action]"** → Extract as task with appropriate context
- **"Must [action] by [date]"** → Extract with due date and high priority
- **"Follow up on [topic]"** → Create follow-up task
- **"Call/Email [person] about [topic]"** → Communication task with @calls/@email context
- **"Research [topic]"** → Research task with @research context
- **"Buy/Purchase [item]"** → Errands task with @errands context

### Context Assignment Logic:
- **Communication words** (call, phone, email, message) → @calls or @email
- **Research words** (research, google, look up, find out) → @research  
- **Purchase words** (buy, purchase, shopping) → @errands
- **Default** → @computer

### Priority Assignment:
- **Urgent words** (urgent, asap, immediately, critical) → urgent_important
- **Important words** (important, must, need to) → not_urgent_important
- **Default** → not_urgent_not_important

## Example Processing Flow

```
Input Log: "Today I need to call John about the project meeting. 
           Also should research React hooks for the new feature.
           Must email Sarah the report by Friday."

Processing Results:
✅ Task 1: "Call John about the project meeting" [@calls, not_urgent_important]
✅ Task 2: "Research React hooks for the new feature" [@research, not_urgent_not_important] 
✅ Task 3: "Email Sarah the report by Friday" [@email, not_urgent_important, due: Friday]

Coordination:
🔒 Acquired lock: log_processing on 2025-01-24
📝 Marked log content as processed to prevent duplicates
🔓 Released lock: log_processing on 2025-01-24
```

## Safety Mechanisms

### 1. **Duplicate Content Prevention**
- Creates SHA256 fingerprint of log content
- Checks if identical content was processed in last hour
- Skips processing if already done

### 2. **Operation Locking**  
- Acquires exclusive lock on date-specific log processing
- Prevents multiple agents from processing same log simultaneously
- 30-second timeout with graceful handling

### 3. **Task Deduplication**
- Checks for existing similar tasks before creation
- Uses title + project + context signature matching
- Prevents creation of nearly identical tasks

### 4. **Process Coordination**
- Tracks processing source (TUI, worker, etc.)
- Maintains processing history for troubleshooting  
- Automatic cleanup of stale locks (60+ minutes old)

## Error Handling

The system gracefully handles various conflict scenarios:

### Already Processed:
```
⏭️  Skipping duplicate processing: auto_task_creation
Status: already_processed
Message: Daily log for 2025-01-24 already processed for task creation
```

### Lock Timeout:
```
⏰ Timeout acquiring lock: log_processing on 2025-01-24  
Status: lock_timeout
Message: Another process is already processing daily log for 2025-01-24
```

### Duplicate Tasks:
```
🛑 Similar task already exists: Call John about project
Status: duplicate_detected  
Message: Similar task already exists: Call John about project
```

## Integration with Background Workers

This safe version works perfectly with background workers:

```bash
# Background worker can safely process logs
gtd-advise questmaster 'Execute safe-auto-task-creation-from-log skill'

# Even if user runs it simultaneously in TUI, no conflicts occur
# One will process, the other will detect and skip gracefully
```

## Verification and Monitoring

After processing, verify results:

```python
# Check what was created
task_result = gtd_list_tasks(status="active", limit=10)
print(f"Recent tasks: {task_result}")

# Check coordination logs
print(f"Processing result: {result}")
print(f"Tasks created: {result['tasks_created']}")
print(f"Coordination status: {result['status']}")
```

## Cleanup and Maintenance

The system automatically:
- **Cleans up stale locks** (older than 60 minutes)
- **Rotates processing history** to prevent disk buildup  
- **Removes old fingerprints** after reasonable time
- **Handles crashed processes** gracefully

## Benefits

### ✅ **Zero Conflicts:**
- No duplicate tasks from simultaneous processing
- No race conditions between TUI and workers
- Safe parallel operation of multiple agents

### ✅ **Intelligent Processing:**
- Remembers what was already processed
- Skips unnecessary work efficiently
- Provides clear status feedback

### ✅ **Reliable Operation:**
- Handles system crashes and restarts
- Automatic recovery from stale states
- Comprehensive error handling

### ✅ **Performance:**
- Fast duplicate detection (< 100ms)
- Efficient locking with timeouts
- Minimal overhead for coordination

This enhanced runbook ensures your GTD system can run background automation while still allowing interactive use without any conflicts or duplicate work!