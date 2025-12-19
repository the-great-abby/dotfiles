# Task Completion Review System

Automatically finds tasks mentioned as completed in your daily logs and lets you review them before closing.

## Overview

This system:
1. ✅ Analyzes your recent daily logs for completed work
2. ✅ Matches completed items to existing active tasks
3. ✅ Shows you a review interface with confidence scores
4. ✅ Lets you approve/reject each match before closing tasks
5. ✅ **Automatically notifies you when completions need review!**

### 🔔 Smart Notifications

**The system automatically checks and notifies you!**

- **Automatic**: When `gtd-auto-suggest` runs (nightly at 3 AM), it checks for completions
- **Manual**: Run `gtd-auto-suggest check-completions` anytime
- **Notifications**: Discord + macOS notifications when completions are found
- **No action needed**: Just review when notified!

See the [Smart Notifications](#smart-notifications) section below for details.

## Quick Start

### Basic Usage

```bash
# Review completions from last 7 days (interactive)
gtd-review-task-completions

# Review last 14 days
gtd-review-task-completions --days 14

# Dry run (see what would be closed without actually closing)
gtd-review-task-completions --dry-run

# Auto-approve high-confidence matches (≥85%)
gtd-review-task-completions --auto

# Get JSON output (for automation)
gtd-review-task-completions --json
```

## How It Works

### 1. Analysis Phase

The system:
- Reads your recent daily logs (default: 7 days)
- Uses AI to identify completed work mentioned in logs
- Looks for phrases like:
  - "finished", "completed", "done"
  - "deployed", "shipped", "launched"
  - "fixed", "resolved", "solved"
  - Past tense accomplishments

### 2. Matching Phase

For each completion found:
- Searches all active tasks
- Calculates similarity scores
- Shows matches with confidence levels
- Combines completion confidence with match similarity

### 3. Review Phase

You'll see:
- **Completion description** from your log
- **Matched tasks** with similarity scores
- **Combined confidence** (completion confidence × similarity)
- Options to approve, reject, or select specific matches

### 4. Completion Phase

After review:
- Selected tasks are closed using `gtd-task complete`
- Results are shown in a summary
- Failed completions are reported

## Example Session

```
📋 TASK COMPLETION REVIEW
================================================================================

Analyzed 7 days of logs
Found 3 potential task completions

[1] COMPLETION FOUND IN LOG (2025-01-15)
--------------------------------------------------------------------------------
Description: Fixed the login bug
Confidence: 85%
Context: Working on authentication system

Matched Tasks:
  1. Fix login bug
     ID: 20250110120000-fix-login-bug
     Similarity: 95% | Combined Confidence: 81%

Options:
  [y] Yes, close the best match (first task)
  [n] No, skip this
  [s] Skip all remaining

Your choice: y
✓ Marked for completion

[2] COMPLETION FOUND IN LOG (2025-01-14)
--------------------------------------------------------------------------------
Description: Deployed new feature
Confidence: 90%

Matched Tasks:
  1. Deploy new feature to production
     ID: 20250108100000-deploy-feature
     Similarity: 88% | Combined Confidence: 79%
  2. Test new feature deployment
     ID: 20250108110000-test-deployment
     Similarity: 65% | Combined Confidence: 59%

Options:
  [y] Yes, close the best match (first task)
  [n] No, skip this
  [1-2] Close a specific match
  [s] Skip all remaining

Your choice: 1
✓ Marked for completion

✅ COMPLETING TASKS
================================================================================
✓ Completed: Fix login bug
✓ Completed: Deploy new feature to production

📊 SUMMARY
================================================================================
Completed: 2
Failed: 0
```

## Options

### `--days N`
Analyze the last N days of logs (default: 7)

```bash
gtd-review-task-completions --days 14
```

### `--dry-run`
Preview what would be closed without actually closing tasks

```bash
gtd-review-task-completions --dry-run
```

### `--auto`
Automatically approve matches with ≥85% confidence (no interactive review)

```bash
gtd-review-task-completions --auto
```

**Use with caution!** Always test with `--dry-run` first.

### `--json`
Output results as JSON (useful for automation/integration)

```bash
gtd-review-task-completions --json > completions.json
```

## Confidence Scores

The system uses two confidence metrics:

1. **Completion Confidence** (0-100%)
   - How confident the AI is that something was actually completed
   - Based on language patterns in your log

2. **Match Similarity** (0-100%)
   - How well the completion description matches the task title
   - Uses fuzzy string matching

3. **Combined Confidence** = Completion Confidence × Match Similarity
   - Used to rank matches
   - Higher = more likely to be correct

## Best Practices

### 1. Start with Dry Run
```bash
gtd-review-task-completions --dry-run
```

### 2. Review Regularly
Run weekly to catch completed tasks:
```bash
# Add to your weekly review routine
gtd-review-task-completions --days 7
```

### 3. Use Auto Mode Carefully
Only use `--auto` after you've verified the system works well for you:
```bash
# First, test with dry-run
gtd-review-task-completions --auto --dry-run

# Then enable for real
gtd-review-task-completions --auto
```

### 4. Adjust Days as Needed
- **Daily**: `--days 1` (quick check)
- **Weekly**: `--days 7` (default)
- **Monthly**: `--days 30` (catch up)

## Integration with Auto-Suggest

This complements your existing auto-suggest system:

- **Auto-Suggest**: Creates tasks from logs
- **Task Completion Review**: Closes tasks mentioned as completed in logs

Together, they keep your task list synchronized with your actual work!

## Troubleshooting

### "No completed work found"
- Check that your daily logs contain completion language
- Try increasing `--days` to look further back
- Make sure logs are in the expected location (`~/Documents/daily_logs`)

### "No tasks matched"
- The completion might not match any active task titles
- Check that tasks are actually active (not already completed)
- The description might be too different from task titles

### "Task completion failed"
- Verify the task ID is correct
- Check that `gtd-task complete` command works
- Ensure you have write permissions to task files

## Advanced Usage

### Automation Example

Create a weekly cron job or launchd task:

```bash
#!/bin/bash
# Weekly task completion review
gtd-review-task-completions --auto --days 7
```

### JSON Processing

For custom automation:

```bash
# Get completions as JSON
gtd-review-task-completions --json > completions.json

# Process with jq
cat completions.json | jq '.potential_completions[] | .completion.description'
```

## Smart Notifications

The system automatically checks for pending task completions and notifies you!

### Automatic Notifications

When you run `gtd-auto-suggest run`, it automatically:
1. Checks for task completions in recent logs
2. Sends a notification if any are found
3. Includes Discord notification (if configured) and macOS notification

### Manual Check

Check for completions anytime:

```bash
# Check last 7 days (default)
gtd-auto-suggest check-completions

# Check last 14 days
gtd-auto-suggest check-completions --value 14
```

This will:
- Show how many completions need review
- Display top matches
- Send a notification if any are found

### Notification Types

**Discord Notification:**
```
📋 Task Completions Need Review

3 task completions found in recent logs

📋 Review: Run `gtd-review-task-completions`
🔍 Dry Run: `gtd-review-task-completions --dry-run`
```

**macOS Notification:**
- Title: "📋 Task Completions Need Review"
- Message: "3 task completions found in recent logs"
- Subtitle: "Run 'gtd-review-task-completions' to review"
- Sound: Glass

### Scheduled Checks

The auto-suggest system runs nightly at 3 AM and will automatically check for completions. You'll get notified if any are found!

## Related Commands

- `gtd-task complete <id>` - Manually complete a task
- `gtd-auto-suggest` - Auto-create tasks from logs
- `gtd-auto-suggest check-completions` - Check for pending completions
- `gtd-progress-analyzer` - Analyze progress without closing tasks

## Files

- **Script**: `mcp/gtd_task_completion_review.py`
- **CLI**: `bin/gtd-review-task-completions`
- **Dependencies**: 
  - Reuses `gtd_progress_analyzer.py` for all log analysis and task matching
  - Extends existing `analyze_completions_for_tasks()` function
  - No code duplication - leverages existing scanners!

---

**Note**: This system is designed to help you, not replace your judgment. Always review matches before closing tasks, especially when confidence is low.

