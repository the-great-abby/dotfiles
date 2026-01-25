---
name: Meeting Follow-up Tasks
description: Automatically create tasks from meeting notes, decisions, and action items. Proactively converts meeting outcomes into GTD tasks without asking permission.
version: 1.0.0
type: runbook
tags:
  - runbook
  - meetings
  - task-creation
  - automatic
  - follow-up
  - gtd
author: GTD System
---

# Meeting Follow-up Tasks Runbook

A proactive runbook that automatically processes meeting notes, extracts action items, decisions, and follow-ups, then creates appropriate GTD tasks immediately. **No permission asking - just creates the necessary tasks.**

## Purpose

This runbook transforms meeting notes into actionable task management:
- Automatically extracts action items, decisions, and commitments from meeting content
- Creates tasks with appropriate owners, contexts, and due dates
- Sets up waiting-for tasks when action depends on others
- Creates follow-up reminders and review tasks
- **Immediately converts meeting outcomes into GTD system**

## Prerequisites

- Meeting notes, agenda, or description provided
- Access to GTD task creation tools
- Understanding of meeting participants and their roles

## Runbook Steps

### Step 1: Parse Meeting Content for Actionables

**Action:** Analyze meeting content and automatically identify actionable items.

**Meeting Content Analysis Patterns:**

**Action Item Indicators:**
- "Action:", "AI:", "TODO:", "[ ]", "- [ ]"
- "[Name] will", "[Name] to", "[Name] agreed to"
- "Follow up", "Send", "Call", "Email", "Review"
- "By [date]", "Due [date]", "Before [date]"

**Decision Indicators:**
- "Decided", "Agreed", "Concluded", "Resolved"
- "Decision:", "We will", "The team will"
- "Going with", "Chosen", "Selected"

**Waiting Indicators:**
- "Waiting for", "[Name] will get back", "Pending"
- "Need from [Name]", "[Name] to provide"
- "Blocked by", "Depends on [Name]"

**Follow-up Indicators:**
- "Next meeting", "Check in", "Review in", "Revisit"
- "Status update", "Progress report", "Follow up meeting"

**Next Step:** Extract and categorize all identified items.

---

### Step 2: Categorize and Extract Action Items

**Action:** Automatically sort identified items into categories and extract details.

**Extraction Logic:**
```python
def extract_meeting_items(meeting_content):
    action_items = []
    decisions = []
    waiting_items = []
    follow_ups = []
    
    # Parse for action patterns
    action_patterns = [
        r'(?i)(.*?)(will|to|agreed to) (.*?)(?=\.|$|\n)',
        r'(?i)action:?\s*(.*?)(?=\.|$|\n)',
        r'(?i)todo:?\s*(.*?)(?=\.|$|\n)',
        r'(?i)- \[ \]\s*(.*?)(?=\.|$|\n)'
    ]
    
    # Parse for deadlines
    deadline_patterns = [
        r'(?i)by (monday|tuesday|wednesday|thursday|friday|saturday|sunday|\d{1,2}[\/\-]\d{1,2})',
        r'(?i)due (.*?)(?=\.|$|\n)',
        r'(?i)before (.*?)(?=\.|$|\n)'
    ]
    
    # Parse for people assignments
    person_patterns = [
        r'@(\w+)',
        r'([A-Z][a-z]+) (will|to)',
        r'([A-Z][a-z]+) agreed'
    ]
    
    return extracted_items
```

**Auto-Categorization:**
- **My Actions** → Create tasks assigned to me
- **Others' Actions** → Create waiting-for tasks  
- **Team Actions** → Create collaborative tasks
- **Decisions** → Create reference/note tasks
- **Follow-ups** → Create scheduled review tasks

**Next Step:** Create tasks for each category automatically.

---

### Step 3: Create Action Item Tasks Automatically

**Action:** Use `gtd_create_task()` for each identified action item.

**My Action Items:**
```python
for action in my_actions:
    gtd_create_task(
        title=action['description'],
        context=determine_context(action['description']),
        priority=determine_priority(action),
        due_date=action.get('deadline'),
        notes=f"From meeting: {meeting_title} on {meeting_date}\nOriginal note: {action['original_text']}",
        project=action.get('project_id')
    )
```

**Context Determination Logic:**
```python
def determine_context(description):
    if any(word in description.lower() for word in ['call', 'phone', 'ring']):
        return '@calls'
    elif any(word in description.lower() for word in ['email', 'send', 'write']):
        return '@email'  
    elif any(word in description.lower() for word in ['meeting', 'discuss', 'talk']):
        return '@agenda'
    elif any(word in description.lower() for word in ['research', 'look up', 'find']):
        return '@research'
    elif any(word in description.lower() for word in ['buy', 'get', 'pick up']):
        return '@errands'
    else:
        return '@action'
```

**Priority Determination:**
```python
def determine_priority(action):
    urgency_words = ['urgent', 'asap', 'critical', 'important', 'deadline']
    if any(word in action['description'].lower() for word in urgency_words):
        return 'high'
    elif action.get('deadline'):
        return 'high'
    else:
        return 'medium'
```

**Next Step:** Create waiting-for tasks for others' actions.

---

### Step 4: Create Waiting-For Tasks Automatically

**Action:** Create waiting-for tasks for actions assigned to others.

**Waiting-For Task Creation:**
```python
for waiting_item in others_actions:
    gtd_create_task(
        title=f"Waiting for: {waiting_item['person']} to {waiting_item['action']}",
        context='@waiting',
        priority='medium',
        due_date=waiting_item.get('deadline'),
        notes=f"Waiting for {waiting_item['person']} since {meeting_date}\nFrom meeting: {meeting_title}\nOriginal commitment: {waiting_item['original_text']}",
        project=waiting_item.get('project_id')
    )
```

**Follow-up Reminders:**
```python
# Create follow-up reminder task for 1 week if no deadline specified
if not waiting_item.get('deadline'):
    follow_up_date = meeting_date + timedelta(days=7)
    gtd_create_task(
        title=f"Follow up with {waiting_item['person']} on {waiting_item['action']}",
        context='@calls',
        priority='low', 
        due_date=follow_up_date,
        notes=f"Follow-up reminder for waiting item from {meeting_title}"
    )
```

**Next Step:** Create decision reference tasks.

---

### Step 5: Create Decision Reference Tasks

**Action:** Create tasks to document and communicate important decisions.

**Decision Documentation:**
```python
for decision in decisions_made:
    gtd_create_task(
        title=f"Document decision: {decision['topic']}",
        context='@write',
        priority='medium',
        notes=f"Decision from meeting: {meeting_title} on {meeting_date}\nDecision: {decision['description']}\nRationale: {decision.get('rationale', 'Not specified')}\nImpact: {decision.get('impact', 'To be determined')}",
        project=decision.get('project_id')
    )
    
    # Create communication task if decision affects others
    if decision.get('affects_team'):
        gtd_create_task(
            title=f"Communicate decision on {decision['topic']} to team",
            context='@email',
            priority='high',
            notes=f"Share decision made in {meeting_title} meeting\nDecision: {decision['description']}"
        )
```

**Next Step:** Set up follow-up meeting tasks.

---

### Step 6: Create Follow-up and Review Tasks

**Action:** Automatically create tasks for meeting follow-ups and progress reviews.

**Next Meeting Preparation:**
```python
if next_meeting_mentioned:
    gtd_create_task(
        title=f"Prepare for {meeting_series} follow-up meeting",
        context='@agenda',
        priority='medium',
        due_date=next_meeting_date - timedelta(days=1),
        notes=f"Review progress on action items from {meeting_title}\nCheck status of waiting items\nPrepare agenda for next meeting"
    )
```

**Progress Check Tasks:**
```python
# Create mid-point check if action items have long deadlines
long_deadline_items = [item for item in all_items if item.get('deadline') and 
                      (item['deadline'] - meeting_date).days > 7]

if long_deadline_items:
    check_date = meeting_date + timedelta(days=3)
    gtd_create_task(
        title=f"Check progress on {meeting_title} action items",
        context='@review',
        priority='low',
        due_date=check_date,
        notes=f"Mid-week check on action items from {meeting_title}\nItems to check: {[item['description'] for item in long_deadline_items]}"
    )
```

**Next Step:** Generate comprehensive meeting summary.

---

### Step 7: Generate Meeting Follow-up Summary

**Action:** Provide complete summary of all created tasks and next steps.

**Summary Format:**
```
📋 **Meeting Follow-up Complete: [MEETING_TITLE]**

🎯 **My Action Items Created:** {my_task_count}
- [task 1] ({context}, due: {date})
- [task 2] ({context}, due: {date})

⏳ **Waiting For Created:** {waiting_task_count}  
- Waiting for [Person]: [action] (follow-up: {date})
- Waiting for [Person]: [action] (due: {date})

📝 **Decisions to Document:** {decision_count}
- Document decision: [topic]
- Communicate decision: [topic] to team

📅 **Follow-up Tasks:** {followup_count}
- Prepare for next meeting (due: {date})
- Check progress on action items (due: {date})

🔗 **Project Connections:**
- {project_count} tasks linked to existing projects
- {new_project_count} new project areas identified

💡 **Next Steps:**
✅ All action items are now in your GTD system
✅ Next actions are ready to work on
✅ Waiting items will be tracked automatically  
✅ Follow-ups scheduled for appropriate dates

**Total Tasks Created:** {total_count}
**Immediate Next Actions:** {next_action_count}
```

**Next Step:** Complete runbook.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ All meeting action items converted to GTD tasks
2. ✅ Waiting-for items tracked with follow-up reminders
3. ✅ Decisions documented and communication planned
4. ✅ Follow-up meetings and reviews scheduled
5. ✅ Appropriate contexts, priorities, and deadlines assigned
6. ✅ Complete audit trail from meeting to tasks

**Success Criteria:**
- No meeting outcomes lost or forgotten
- All commitments properly tracked
- Appropriate follow-up systems in place
- Clear next actions available immediately

## Meeting Type Templates

### **Team Meeting Template:**
- Focus on collaborative actions and team decisions
- Create more @agenda and @email tasks
- Set up team communication tasks
- Schedule progress check meetings

### **Client Meeting Template:**
- Create client-specific waiting tasks
- Set up proposal/follow-up tasks
- Track client commitments carefully
- Create relationship management tasks

### **Project Meeting Template:**
- Link all tasks to specific project
- Create milestone review tasks
- Set up project communication tasks  
- Track project-specific decisions

### **One-on-One Template:**
- Create personal development tasks
- Set up feedback implementation tasks
- Schedule regular check-in tasks
- Track career/growth commitments

## Usage

**To use this runbook:**
1. "Process meeting notes from [meeting name]"
2. "Create tasks from today's team meeting"
3. "Convert [meeting] outcomes to GTD tasks"

**Input Formats Supported:**
- Formal meeting minutes
- Bullet-point notes
- Email meeting summaries
- Voice-to-text meeting transcripts
- Agenda with handwritten notes

## Error Handling

**If unclear action items:**
- Create task with "Clarify: [unclear item]" @agenda
- Schedule follow-up to get clarity

**If no clear owner:**
- Create task to determine ownership
- Default to creating waiting task for meeting organizer

**If conflicting information:**
- Create multiple tasks to resolve conflicts
- Schedule clarification meeting

## Integration

**Works with:**
- Daily/weekly review runbooks
- Project management runbooks  
- Team communication workflows
- Calendar and scheduling systems

**Triggers:**
- Can be automatically triggered by meeting end (calendar integration)
- Manual trigger after meeting
- Batch processing of multiple meetings

This runbook ensures that meetings actually result in action rather than just discussion, converting every meeting into productive task management without the usual delay and uncertainty.