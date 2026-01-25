---
name: Interactive Morning Review Runbook
description: Interactive morning check-in that guides you through questions step-by-step. Asks questions, waits for responses, and helps you plan your day thoughtfully.
version: 1.0.0
type: runbook
tags:
  - runbook
  - morning
  - interactive
  - checkin
  - daily
  - guided
  - questions
author: GTD System
---

# Interactive Morning Review Runbook

An interactive, question-driven morning review process that guides you through planning your day. This runbook asks questions, waits for your responses, and builds a personalized daily plan.

## Purpose

This runbook provides a conversational morning check-in experience:
- Asks you questions about your current state and priorities
- Waits for your responses before proceeding
- Builds a personalized daily plan based on your inputs
- Helps you reflect on what matters most today

## Prerequisites

- 10-15 minutes of uninterrupted time
- Access to GTD tools for planning actions
- Willingness to engage in self-reflection

## Interactive Runbook Steps

### Step 1: Morning State Check-In

**Question:** "Good morning! How are you feeling right now? What's your energy level like on a scale of 1-10, and how are you mentally/emotionally?"

**Wait for Response**

**Follow-up Questions Based on Response:**
- If energy is low (1-4): "What might help boost your energy today? Are you getting enough sleep/rest?"
- If energy is medium (5-7): "What would help you make the most of your moderate energy today?"
- If energy is high (8-10): "Great! How can we channel this high energy into your most important work?"

**What to do with the response:**
- Note their energy level and emotional state
- Use this to inform task prioritization later
- Suggest energy-appropriate activities

**Next Step:** Wait for their response, then proceed to Step 2.

---

### Step 2: Yesterday's Reflection

**Question:** "Let's briefly reflect on yesterday. What was the most important thing you accomplished? And is there anything from yesterday that's still on your mind or needs follow-up today?"

**Wait for Response**

**Follow-up Questions:**
- "How do you feel about what you got done yesterday?"
- "Is there anything you wish had gone differently?"
- "Are there any loose ends from yesterday that need attention today?"

**What to do with the response:**
- Call `gtd_read_daily_log(date="yesterday")` if they mention specific items
- Note any unfinished items that need to carry forward
- Capture any insights about patterns or improvements

**Next Step:** Wait for their response, then proceed to Step 3.

---

### Step 3: Today's Context and Constraints

**Question:** "What's your day looking like today? Do you have meetings, appointments, or other commitments I should know about? What's your available time and main context (home, office, traveling, etc.)?"

**Wait for Response**

**Actions Based on Response:**
- Call `gtd_get_calendar_overview(date="today")` to supplement their information
- Ask clarifying questions about their availability

**Follow-up Questions:**
- "How much focused work time do you realistically have today?"
- "Are there any potential interruptions or challenges I should factor in?"
- "What context will you be in for most of the day (computer, phone, errands, etc.)?"

**What to do with the response:**
- Note their available time and energy windows
- Identify their primary context for task planning
- Flag any potential scheduling conflicts or constraints

**Next Step:** Wait for their response, then proceed to Step 4.

---

### Step 4: Current Priorities and Concerns

**Question:** "What's been on your mind lately? What feels most important or urgent right now? Are there any specific projects, goals, or areas of your life that need attention today?"

**Wait for Response**

**Follow-up Questions:**
- "If you could only accomplish 1-3 things today, what would they be?"
- "Is there anything causing you stress or concern that we should address?"
- "Are there any opportunities or deadlines coming up that we should prepare for?"

**Actions Based on Response:**
- Call `gtd_list_tasks(status="active")` to see current tasks
- Call `gtd_list_projects(status="active")` to see active projects
- Compare their priorities with system data

**What to do with the response:**
- Identify their top 1-3 priorities for the day
- Note any gaps between what they mentioned and what's in the system
- Flag any missing tasks or projects that should be created

**Next Step:** Wait for their response, then proceed to Step 5.

---

### Step 5: Goal Alignment Check

**Question:** "Taking a step back, how do your priorities today connect to your bigger goals or vision? Is there a particular area of your life (work, health, relationships, personal growth) that deserves extra attention this week?"

**Wait for Response**

**Follow-up Questions:**
- "What would make today feel meaningful and successful for you?"
- "Are there any habits or routines you want to maintain or start today?"
- "Is there something you've been putting off that might be worth tackling?"

**What to do with the response:**
- Connect daily priorities to longer-term goals
- Suggest habit tracking or routine items if relevant
- Call `gtd_get_personalization()` to check for relevant personal goals

**Next Step:** Wait for their response, then proceed to Step 6.

---

### Step 6: Action Planning

**Question:** "Based on our conversation, I'm hearing that your top priorities are [summarize their priorities]. Given your energy level ([their energy]) and available time ([their time constraints]), let's create a realistic plan. Should I help you create tasks for any of these priorities, or update existing ones?"

**Wait for Response**

**Interactive Actions:**
- For each priority they confirm:
  - Ask: "Would you like me to create a task for [priority]? What would be a good next action?"
  - Call `gtd_create_task()` based on their response
  - Ask: "What priority level feels right for this? When would you ideally work on it?"

**Follow-up Questions:**
- "Are there any quick wins (tasks taking <15 minutes) we should include?"
- "Should I block any time in your calendar for focused work?"
- "What's your backup plan if your main priorities get interrupted?"

**What to do with responses:**
- Create tasks based on their specifications
- Set appropriate priorities and contexts
- Suggest time-blocking or scheduling if helpful

**Next Step:** Wait for their responses to each priority, then proceed to Step 7.

---

### Step 7: Daily Intention Setting

**Question:** "Let's wrap up with your intention for today. How do you want to show up today? What mindset, attitude, or approach will serve you best? And is there anything you want to remember throughout the day?"

**Wait for Response**

**Follow-up Questions:**
- "What would help you maintain this intention during busy or stressful moments?"
- "Is there a word, phrase, or reminder that would be helpful?"
- "How will you know at the end of the day if today was successful?"

**Actions:**
- Call `gtd_add_daily_log_entry()` to capture their morning intentions and plan
- Offer to set a reminder for a mid-day or evening check-in

**What to do with the response:**
- Capture their daily intention and mindset
- Create a brief summary of their morning plan
- Suggest any follow-up check-ins or reminders

**Next Step:** Complete the morning review with a summary.

---

### Step 8: Morning Review Summary

**Action:** Provide a personalized summary of the morning review.

**Summary Format:**
```
🌅 Morning Review Summary:
Energy Level: [X/10] - [their description]
Key Priorities Today:
1. [Priority 1] - [status: created task/noted]
2. [Priority 2] - [status: created task/noted]  
3. [Priority 3] - [status: created task/noted]

Daily Intention: [their intention]
Available Time: [their time constraints]
Main Context: [their context]

Next Steps:
- [Any tasks created or actions planned]
- [Any reminders or follow-ups scheduled]

Have a great day! Remember your intention: [their intention]
```

**Questions:**
- "Does this summary capture your morning plan well?"
- "Is there anything else you'd like to add or adjust?"
- "Would you like a reminder about your priorities later today?"

**Next Step:** Complete runbook based on their final input.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Morning state and energy level captured
2. ✅ Yesterday's reflection processed
3. ✅ Today's context and constraints understood
4. ✅ Current priorities identified and planned
5. ✅ Goal alignment checked
6. ✅ Action items created in GTD system
7. ✅ Daily intention set
8. ✅ Summary provided for reference

**Success Criteria:**
- User feels clear about their day ahead
- Top priorities are identified and planned
- Realistic daily plan created
- Energy level and constraints considered
- Intention set for mindful day

## Key Principles for AI Implementation

**CRITICAL: This is an INTERACTIVE runbook**
- **Ask ONE question at a time**
- **Wait for user response before proceeding**
- **Don't rush through all questions at once**
- **Adapt questions based on their responses**
- **Show genuine interest in their answers**

**Conversational Style:**
- Use a warm, supportive tone
- Acknowledge their responses thoughtfully
- Ask follow-up questions that show you're listening
- Avoid sounding robotic or checklist-driven

**Flexibility:**
- Skip questions that don't seem relevant
- Spend more time on areas they seem concerned about
- Adjust the pace based on their engagement
- Allow tangents if they lead to important insights

**Practical Focus:**
- Turn insights into actionable next steps
- Create tasks in their GTD system based on discussion
- Make concrete plans, not just philosophical reflections
- Connect daily actions to bigger picture goals

## Error Handling

**If user seems rushed:**
- Offer a "quick morning check-in" version (Steps 1, 4, 6 only)
- Focus on immediate priorities and actions
- Skip deeper reflection questions

**If user gives minimal responses:**
- Ask more specific, easier-to-answer questions
- Provide examples or multiple choice options
- Focus on practical planning over reflection

**If user seems overwhelmed:**
- Simplify to just 1-2 top priorities
- Focus on what feels manageable today
- Suggest breaking large items into smaller steps
- Offer to schedule follow-up check-ins

## Usage

**To use this runbook:**
1. Ask: "I'd like to do an interactive morning review"
2. Or: "Can you guide me through planning my day with questions?"
3. Or: "Let's do the morning runbook with questions"

**Best Times:**
- Within first hour of waking/starting work day
- Before checking email or diving into tasks
- When you want intentional day planning
- When feeling scattered or unclear about priorities

## Integration with Other Runbooks

**After Interactive Morning Review:**
- Use task-specific runbooks for complex projects
- Reference daily intentions during decision-making
- Use evening review runbook to reflect on the day
- Feed insights into weekly/monthly review runbooks

**Before Interactive Morning Review:**
- Consider inbox processing if overwhelmed with inputs
- Do a quick meditation or mindfulness practice if helpful
- Ensure you have 10-15 uninterrupted minutes

## Tips for Effective Morning Reviews

**For Users:**
- Find a quiet, comfortable space
- Be honest about your energy and constraints
- Don't overthink - first instincts are often right
- Focus on progress, not perfection
- Remember: plans can be adjusted throughout the day

**For AI Assistants:**
- Create psychological safety for honest sharing
- Balance planning with flexibility
- Help users be realistic about their capacity
- Celebrate small wins and progress
- Remember that some days are just about surviving

## Advanced Variations

**Quick Version (5-7 minutes):**
- Steps 1, 4, 6, 8 only
- Focus on energy, priorities, and actions

**Weekly Planning Version:**
- Add questions about week-long goals
- Include project planning elements
- Connect to weekly review insights

**Seasonal/Monthly Adaptation:**
- Include questions about monthly goals
- Ask about seasonal priorities or changes
- Connect to quarterly planning cycles