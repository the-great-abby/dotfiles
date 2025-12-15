# GTD Advisor Progress Tracking Enhancements

## Overview

Enhanced the GTD advisor system to encourage recording more projects and tasks, and provide progress updates based on daily logs that help identify completed work not recorded in the system.

## What Was Added

### 1. Progress Analyzer (`mcp/gtd_progress_analyzer.py`)

A new Python script that analyzes daily logs to identify completed work that hasn't been recorded in the GTD task/project system.

**Features:**
- Analyzes recent daily logs (default: last 7 days)
- Uses AI to identify completed work from log entries
- Compares against existing tasks and projects
- Generates suggestions for recording unrecorded completions
- Provides human-readable progress summaries

**Usage:**
```bash
# Analyze and return JSON
python3 mcp/gtd_progress_analyzer.py analyze [days]

# Generate human-readable summary
python3 mcp/gtd_progress_analyzer.py summary [days]
```

**Example Output:**
```
Progress Update - Last 7 Days:

Found 15 completed items in your logs.
5 of them are not recorded in your task/project system.

Unrecorded Completions:
  • Fixed login bug (2025-01-15)
  • Deployed new feature (2025-01-14)
  • Completed code review (2025-01-13)
  ... and 2 more

Consider recording these in your GTD system to maintain accurate progress tracking!
```

### 2. Enhanced `gtd-advise` Command

Added progress analysis integration to the advisor system.

**New Function:**
- `get_progress_analysis()` - Retrieves and displays progress analysis when advisors are called

**Integration Points:**
- Progress analysis is automatically included when reviewing daily logs
- Progress analysis is included in general advisor context (even when not reviewing logs)
- Works with both single persona and "all personas" modes

**How It Works:**
- When you call `gtd-advise`, the system automatically:
  1. Analyzes your recent daily logs (last 7 days)
  2. Identifies completed work not in your GTD system
  3. Includes this information in the context sent to advisors
  4. Advisors can then encourage you to record these items

### 3. Enhanced Advisor Personas

Updated all advisor personas to:
- Encourage recording completed work
- Provide progress updates based on daily log analysis
- Suggest recording tasks and projects when mentioned
- Help identify work that should be tracked

**New Instructions in System Prompts:**
- Advisors now know to look for Progress Analysis data
- They encourage recording completed work with helpful suggestions
- They explain the value of tracking (progress visibility, pattern recognition)
- They provide specific actionable suggestions

**Example Advisor Response:**
> "I see you completed fixing the login bug yesterday - great work! I noticed it's not recorded in your GTD system yet. Consider adding it as a completed task so you can track your progress. You've completed 5 items this week that aren't tracked - recording them would give you a clearer picture of your accomplishments!"

### 4. Enhanced Auto-Suggestion System

Updated the auto-suggestion banter to encourage recording.

**Changes:**
- Banter now includes gentle reminders to record completed work
- Suggests recording when completion is mentioned in log entries
- Encourages good GTD practices like tracking projects

**Example Banter:**
> "Great job completing the deployment! Consider recording it in your GTD system so you can track your progress and see patterns in your work."

## How to Use

### Get Progress Updates with Advisors

```bash
# Get advice with progress analysis included automatically
gtd-advise hank "What should I focus on?"

# Review daily log with progress analysis
gtd-advise --all "Review my daily log"

# Progress analysis is included in all advisor calls
gtd-advise david "Help me organize my tasks"
```

### Direct Progress Analysis

```bash
# Get progress summary
python3 ~/code/dotfiles/mcp/gtd_progress_analyzer.py summary 7

# Get detailed JSON analysis
python3 ~/code/dotfiles/mcp/gtd_progress_analyzer.py analyze 7
```

## Technical Details

### Progress Analyzer Algorithm

1. **Read Daily Logs**: Scans recent daily log files (`.md` or `.txt` format)
2. **AI Analysis**: Uses AI to identify completed work from log entries by looking for:
   - Completion indicators: "finished", "completed", "done", "deployed", etc.
   - Past tense accomplishments: "I built", "I created", "I fixed"
   - Context clues from log entries
3. **Compare with System**: Checks existing tasks and projects to see if items are already recorded
4. **Generate Suggestions**: Creates actionable suggestions for recording unrecorded work

### Integration Points

- **`gtd-advise`**: Progress analysis is automatically included in advisor context
- **`gtd_persona_helper.py`**: System prompts include instructions for handling progress data
- **`gtd_auto_suggest.py`**: Banter encourages recording in real-time

## Benefits

1. **Better Tracking**: Identifies completed work that would otherwise go untracked
2. **Progress Visibility**: Helps you see patterns and accomplishments
3. **Habit Building**: Advisors gently encourage recording, building the habit over time
4. **Complete Picture**: Gives advisors context about your actual progress vs. what's recorded
5. **Actionable Suggestions**: Provides specific items to record, not just general advice

## Future Enhancements

Potential future improvements:
- Automatic task/project creation from identified completions
- Weekly progress reports
- Pattern recognition across completed work
- Integration with gamification system for recording completions

## Notes

- Progress analysis runs automatically but won't slow down advisor responses (runs in background when possible)
- The analyzer uses AI, so it may occasionally miss items or suggest items that are already recorded (system learns and improves)
- All suggestions are gentle and encouraging - the goal is to help build the habit, not create pressure

