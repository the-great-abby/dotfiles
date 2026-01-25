# Runbook Session Persistence

**Description**: Comprehensive system for saving, resuming, and managing interrupted interactive runbook sessions.

**Type**: System Integration

**Complexity**: Advanced

**Use Cases**: 
- Resume interrupted email backlog processing
- Continue multi-step project planning across sessions  
- Track progress in long-running reviews
- Preserve user inputs and context across sessions

---

## Overview

The Session Persistence System allows you to:

1. **Save Progress Automatically** - Sessions save state after each step
2. **Resume From Any Point** - Pick up exactly where you left off
3. **Track Multiple Sessions** - Manage several concurrent runbooks
4. **Preserve User Context** - All inputs and persona settings saved
5. **Session Management** - List, complete, abandon, and clean up sessions

## Core Components

### 1. Session Management (`runbook_sessions.py`)
- **Session Creation**: Start new persistent sessions
- **Progress Tracking**: Save step completion and user inputs
- **State Persistence**: Comprehensive session state management
- **Resume Logic**: Load exact continuation point

### 2. Resume Tool (`gtd-runbook-resume`)
- **List Sessions**: See all resumable sessions
- **Session Details**: View progress and completion status
- **Resume Execution**: Continue interrupted runbooks
- **Session Cleanup**: Manage old and completed sessions

## Usage Workflow

### Starting a New Session

When you start an interactive runbook, create a session:

```bash
# Method 1: Start with session creation
gtd-runbook-resume create --runbook "interactive-email-backlog-processor" --persona "quartermaster"

# Method 2: Let the runbook create the session automatically
gtd-runbook interactive-email-backlog-processor
# (Session created automatically, ID shown)
```

### During Runbook Execution

**Automatic Saving**: Progress is saved automatically after each step:
- Current step number and name
- User inputs and choices  
- Step-specific data and context
- Timestamp and progress percentage

**Manual Saving**: You can also save notes:
```bash
# Add notes to current session
python3 mcp/skills/session-persistence/scripts/runbook_sessions.py note <session_id> "Taking a break for lunch"
```

### Resuming Interrupted Sessions

```bash
# List all resumable sessions
gtd-runbook-resume list

# Get detailed session information
gtd-runbook-resume info abc123ef

# Resume a specific session
gtd-runbook-resume resume abc123ef
```

### Session Management

```bash
# Complete a finished session
gtd-runbook-resume complete abc123ef

# Abandon a session you won't continue
gtd-runbook-resume abandon abc123ef

# Clean up old sessions (30+ days)
gtd-runbook-resume cleanup --days 30
```

## Session Data Structure

Each session stores:

```json
{
  "session_id": "abc123ef",
  "runbook_name": "interactive-email-backlog-processor",
  "persona": "quartermaster",
  "created_at": "2024-01-20T10:30:00",
  "last_active": "2024-01-20T11:45:00", 
  "current_step": 3,
  "status": "active",
  "completed_steps": [0, 1, 2],
  "user_inputs": {
    "1": {"email_count": "1847", "time_available": "2 hours"},
    "2": {"quick_delete_count": "423"}
  },
  "step_data": {
    "1": {"assessment_complete": true},
    "2": {"emails_processed": 423, "time_spent": "25 minutes"}  
  },
  "step_history": [
    {
      "step_num": 1,
      "step_name": "Email Assessment",
      "timestamp": "2024-01-20T10:35:00",
      "inputs": {"email_count": "1847"}
    }
  ],
  "session_notes": [
    {
      "timestamp": "2024-01-20T11:00:00",
      "note": "Taking 15 minute break"
    }
  ],
  "resume_point": "Systematic Processing Phase"
}
```

## Integration with Existing Runbooks

### Email Backlog Processor Example

Your existing email runbook can be enhanced with session persistence:

```markdown
## Step 1: Email Assessment

**Quartermaster**: "Let's assess your email situation, sailor!"

1. How many emails in your inbox? 
2. How much time do you have available?

<!-- Session automatically saves these inputs -->

---

## Step 2: Quick Victories

**Based on your assessment from Step 1:**
- Target: Delete/archive 20% quickly
- Time allocation: 15-20 minutes

<!-- Progress tracked automatically -->

---

## Resume Logic

If interrupted and resumed:
- Skip completed steps (1 if finished)  
- Show previous inputs from Step 1
- Continue from current step with context
```

### Integration Code

Add to your runbook scripts:

```python
from skills.session_persistence.scripts.runbook_sessions import save_progress

# At each step
save_progress(session_id, step_num=1, step_name="Email Assessment", 
              inputs={"email_count": email_count, "time_available": time_available})

# When resuming
resume_info = get_resume_info(session_id)
if resume_info:
    # Skip to current step
    current_step = resume_info['current_step']
    previous_inputs = resume_info['user_inputs']
    # Continue from resume point
```

## Benefits

### For You
- **Never Lose Progress**: Interrupted sessions can always be resumed
- **Context Preservation**: All your inputs and choices saved
- **Multiple Sessions**: Work on several runbooks simultaneously  
- **Progress Tracking**: See completion percentages and time invested

### For Long Runbooks
- **Email Backlog Processing**: Resume multi-hour email cleanup sessions
- **Annual Reviews**: Continue comprehensive life/work reviews across days
- **Project Planning**: Persist complex planning sessions with all details
- **Habit Optimization**: Track progress through multi-week optimization processes

## Advanced Features

### Session Analytics
- Track time spent per step
- Identify commonly abandoned steps
- Measure completion rates by runbook type
- Progress visualization

### Cross-Session Learning
- Common input patterns
- Optimal session lengths
- Best resume points
- Success predictors

### Integration Points
- **Boss Battle System**: Resume epic task battles
- **Achievement System**: Track session completion achievements  
- **Persona System**: Maintain persona consistency across sessions
- **Seasonal Themes**: Apply consistent themes to resumed sessions

## Storage Location

Sessions stored in: `~/Documents/gtd/.sessions/`
- `abc123ef.json` - Individual session files
- `active_sessions.json` - Index of active sessions
- Automatic cleanup of old sessions (configurable)

## Error Recovery

### Session Corruption
- Automatic backup after each save
- Recovery from last known good state
- Manual session reconstruction tools

### Missing Sessions  
- Session recreation from partial data
- Import/export capabilities
- Manual session bootstrapping

## Future Enhancements

1. **Visual Progress Tracking** - Web-based session dashboard
2. **Collaboration Support** - Share sessions with accountability partners
3. **Automated Scheduling** - Smart resume reminders
4. **Integration APIs** - Connect with external productivity tools
5. **Mobile Access** - View/manage sessions from mobile devices

---

## Quick Start

1. **Enable Session Persistence**: Already included in your runbook system
2. **Start a Session**: Use `gtd-runbook-resume create` or let runbooks auto-create
3. **Work on Runbook**: Progress saves automatically
4. **Get Interrupted**: No problem - session is preserved
5. **Resume Later**: Use `gtd-runbook-resume resume <session_id>`

**Your 67 interactive runbooks now have full session persistence!** 🎯✨