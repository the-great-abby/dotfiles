---
name: Interactive Daily Log Review Runbook
description: Interactive, conversational daily log review that guides you through questions to reflect on your day, identify patterns, and extract actionable insights. Uses GTD command data for grounded analysis.
version: 2.0.0
type: runbook
tags:
  - runbook
  - daily-log
  - review
  - interactive
  - analysis
  - questions
  - reflection
  - patterns
author: GTD System
---

# Interactive Daily Log Review Runbook

An interactive, question-driven daily log review process that guides you through reflecting on your day and extracting actionable insights. This runbook asks questions, waits for your responses, and combines your reflection with actual GTD system data.

**Note:** This is an interactive runbook - the AI will ask you questions one at a time and wait for your responses before proceeding.

## Purpose

This interactive runbook provides a conversational daily review experience:
- Asks you reflective questions about your day
- Analyzes your actual daily log data and system activity
- Identifies gaps between what you did and what you planned
- Extracts actionable insights and patterns
- Creates concrete next steps based on your reflection

## Prerequisites

- 15-20 minutes of reflective time
- Willingness to honestly assess your day
- Daily log entries (even brief ones are helpful)

## Interactive Runbook Steps

### Step 1: Day Reflection Opening

**Question:** "Hi! Ready to reflect on your day? First, let me ask - how are you feeling right now as you look back on today? What's your overall sense of how the day went?"

**Wait for Response**

**Follow-up Questions Based on Response:**
- If positive: "That's wonderful! What made today feel good for you?"
- If neutral/mixed: "What were the highlights and challenges?"  
- If negative: "What made today feel difficult? Let's explore that."

**Actions:**
- Call `gtd_get_datetime()` to confirm today's date
- Call `gtd_read_daily_log(date="today")` to load their actual log data

**What to do with responses:**
- Note their emotional state and overall day assessment
- Compare their feeling with actual log entries (if any)
- Prepare to explore specific areas based on their response

**Next Step:** Wait for their response, then proceed to Step 2.

---

### Step 2: Log Data Analysis & Gap Identification

**Question:** "Let me look at what you actually logged today... [review log content]. I can see [X entries/activities]. Does this capture the full picture of your day, or are there important things that happened that aren't reflected here?"

**Wait for Response**

**Actions During This Step:**
- Call `gtd_log_stats(date="today")` to get quantitative analysis
- Call `gtd_list_tasks(status="completed", date="today")` to see completed tasks
- Call `gtd_get_calendar_overview(date="today")` to see scheduled events

**Follow-up Questions:**
- "What was the most significant thing that happened today?"
- "Looking at your calendar vs. what you logged, did anything unexpected come up?"
- "Are there accomplishments or challenges missing from your log?"

**What to do with responses:**
- Identify gaps between logged activities and actual day
- Note discrepancies between planned and actual activities
- Flag important unlogged events for potential capture

**Next Step:** Wait for their response, then proceed to Step 3.

---

### Step 3: Energy and Focus Pattern Exploration

**Question:** "Tell me about your energy patterns today. When did you feel most focused and productive? When did you feel drained or distracted? How did your energy compare to what you expected?"

**Wait for Response**

**Follow-up Questions:**
- "What activities or situations gave you energy vs. drained it?"
- "Did you notice any patterns with times of day, types of work, or interactions?"
- "How well did you match your energy to the right kinds of tasks?"

**Actions:**
- Call `gtd_log_mood(action="analyze", date="today")` to check mood patterns
- Analyze log entries for energy-related keywords
- Cross-reference with calendar to identify energy impacts

**What to do with responses:**
- Map energy patterns to specific activities and times
- Identify energy drains and energy sources
- Note mismatches between energy levels and task types

**Next Step:** Wait for their response, then proceed to Step 4.

---

### Step 4: Priority Alignment Assessment

**Question:** "Let's talk about priorities. What did you hope to accomplish today, and how did reality match up? Were you able to work on your most important things, or did other stuff take over?"

**Wait for Response**

**Actions:**
- Call `gtd_list_tasks(status="active", priority="high")` to see high-priority tasks
- Compare planned priorities with actual logged activities
- Identify priority tasks that weren't addressed

**Follow-up Questions:**
- "What pulled you away from your priorities (if anything)?"
- "Were there urgent things that came up that weren't on your radar?"
- "Looking back, do you feel good about how you allocated your time and attention?"

**What to do with responses:**
- Identify gaps between intended and actual priorities
- Note patterns of distraction or priority drift
- Flag high-priority items that need attention tomorrow

**Next Step:** Wait for their response, then proceed to Step 5.

---

### Step 5: Learning and Growth Identification

**Question:** "What did you learn today? This could be anything - about yourself, your work, a skill, a relationship, or just life in general. What insights or 'aha moments' did you have?"

**Wait for Response**

**Follow-up Questions:**
- "Were there any mistakes or failures that taught you something valuable?"
- "What would you do differently if you could repeat today?"
- "What patterns are you starting to notice about yourself or your work?"

**Actions:**
- Use Sequential Thinking tools for deeper analysis:
  - Call `create_thoughts(thought="Analyzing daily patterns and learnings from user reflection")`
  - Call `branch_thought(thought_id=X, new_branch="What patterns suggest about future planning")`

**What to do with responses:**
- Capture key learnings and insights
- Identify actionable patterns for future improvement
- Note recurring themes across multiple days

**Next Step:** Wait for their response, then proceed to Step 6.

---

### Step 6: Relationship and Communication Review

**Question:** "How were your interactions with people today? Any meaningful conversations, collaborations, or relationship moments - positive or challenging?"

**Wait for Response**

**Follow-up Questions:**
- "Were there any communication successes or breakdowns?"
- "Did you connect with anyone in a way that felt meaningful?"
- "Are there any follow-ups or relationship maintenance items you need to handle?"

**Actions:**
- Scan log entries for people mentions
- Check calendar for meetings and social events
- Identify relationship-related tasks that might need creation

**What to do with responses:**
- Note relationship patterns and communication insights
- Identify needed follow-ups or relationship maintenance tasks
- Flag social/relationship goals that were advanced or neglected

**Next Step:** Wait for their response, then proceed to Step 7.

---

### Step 7: Task and Project Progress Assessment

**Question:** "Let's get practical - what actual progress did you make on your projects and tasks today? What got moved forward, what got stuck, and what surprised you?"

**Wait for Response**

**Actions:**
- Call `gtd_list_projects(status="active")` to see active projects
- Cross-reference log activities with project progress
- Identify completed work that should be recorded

**Follow-up Questions:**
- "Are there accomplishments you should celebrate or record?"
- "What's blocking progress on important projects?"
- "Are there new tasks or projects that emerged from today's work?"

**What to do with responses:**
- Record completed work that wasn't captured in the system
- Identify and create missing tasks/projects mentioned
- Flag blocked items that need problem-solving

**Next Step:** Wait for their response, then proceed to Step 8.

---

### Step 8: Tomorrow's Intention Setting

**Question:** "Looking ahead to tomorrow, what's your main intention or focus? Given what you learned about yourself today, how do you want to approach tomorrow differently?"

**Wait for Response**

**Actions:**
- Call `gtd_get_calendar_overview(date="tomorrow")` to see tomorrow's context
- Prepare to create tasks based on their intentions
- Use insights from today's patterns to inform planning

**Follow-up Questions:**
- "Based on your energy patterns today, when should you tackle your most important work tomorrow?"
- "Are there any adjustments to your approach or schedule that would help?"
- "What would make tomorrow feel successful for you?"

**What to do with responses:**
- Set intentions for tomorrow based on today's learnings
- Create specific tasks or calendar blocks if requested
- Capture tomorrow's priorities and approach

**Next Step:** Wait for their response, then proceed to Step 9.

---

### Step 9: Action Item Creation

**Question:** "Based on our conversation, I'm seeing several potential action items: [summarize identified actions]. Which of these feel most important to capture or act on? Should I help you create tasks for any of these?"

**Wait for Response**

**Interactive Actions:**
- For each action they confirm:
  - Ask: "Should I create a task for [action]? What would be a good next step?"
  - Call `gtd_create_task()` based on their specifications
  - Ask: "When would be a good time to work on this? What priority feels right?"

**Actions:**
- Call `gtd_add_daily_log_entry()` to add any missing significant events
- Create tasks for follow-ups and action items
- Update system based on identified gaps

**What to do with responses:**
- Create concrete tasks and projects based on discussion
- Capture any unlogged significant events
- Set up follow-through for tomorrow's intentions

**Next Step:** Wait for their confirmation of actions, then proceed to Step 10.

---

### Step 10: Daily Review Summary

**Action:** Provide a personalized summary of the daily review and insights.

**Summary Format:**
```
🌙 Daily Review Summary:

Overall Day Assessment: [their feeling] - [key themes]

Key Insights:
• Energy Pattern: [observation]
• Priority Alignment: [assessment] 
• Main Learning: [key insight]
• Relationship Highlight: [if any]

What Went Well:
• [accomplishment 1]
• [accomplishment 2]

Areas for Tomorrow:
• [intention or improvement]
• [focus area]

Actions Created:
• [task/project created]
• [follow-up item]

Tomorrow's Intention: [their intention]
```

**Final Questions:**
- "Does this summary capture your day and insights well?"
- "Is there anything important we missed or should add?"
- "How did this reflection process feel for you?"

**Next Step:** Complete runbook based on final input.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Personal reflection on day captured
2. ✅ Daily log data analyzed and gaps identified
3. ✅ Energy and focus patterns explored
4. ✅ Priority alignment assessed
5. ✅ Learnings and insights extracted
6. ✅ Relationship interactions reviewed
7. ✅ Task/project progress evaluated
8. ✅ Tomorrow's intentions set
9. ✅ Action items created in GTD system
10. ✅ Personalized summary provided

**Success Criteria:**
- User feels heard and understood in their day assessment
- Real system data combined with personal reflection
- Concrete learnings and insights identified
- Actionable next steps created
- Tomorrow planned with today's insights

## Key Principles for AI Implementation

**CRITICAL: This is an INTERACTIVE runbook**
- **Ask ONE question at a time**
- **Wait for user response before proceeding**
- **Show genuine curiosity about their responses**
- **Adapt questions based on what they share**
- **Combine their reflection with actual system data**

**Conversational Style:**
- Use a warm, reflective tone
- Ask follow-up questions that show you're processing their answers
- Acknowledge challenges without judgment
- Celebrate wins and progress, however small
- Be curious rather than prescriptive

**Data Integration:**
- Always use actual GTD system data to inform questions
- Point out gaps between perception and logged reality (gently)
- Use system data to validate or challenge their assessments
- Create concrete actions based on the combination of reflection + data

**Flexibility:**
- Skip questions if they've already covered the topic
- Spend more time on areas they want to explore
- Allow tangents if they lead to valuable insights
- Adjust depth based on their energy and engagement

## Error Handling

**If daily log is empty:**
- Ask: "I notice your daily log is pretty empty. That's totally fine - can you tell me about your day anyway?"
- Focus more on their verbal reflection
- Suggest: "Based on our conversation, would you like me to add some key events to your log?"

**If user gives minimal responses:**
- Ask more specific questions: "What was the first thing you did after [previous activity]?"
- Offer examples: "For instance, did you feel focused during meetings, or find yourself distracted?"
- Validate brief responses: "Even short days have insights - what felt different about today?"

**If user seems tired or overwhelmed:**
- Offer shortened version: "Would you prefer a quick 5-minute reflection instead?"
- Focus on most important insights
- Emphasize self-compassion: "Some days are just about getting through - that's perfectly valid"

## Usage

**To use this runbook:**
1. Ask: "I'd like to do an interactive daily review"
2. Or: "Can you guide me through reflecting on my day with questions?"
3. Or: "Let's do the daily review runbook with questions"

**Best Times:**
- End of work day (before transitioning to evening)
- Before dinner or evening activities
- When feeling scattered or unclear about the day
- As part of evening routine before bed

## Integration with Other Runbooks

**After Interactive Daily Review:**
- Use evening check-in for wind-down activities
- Reference insights during tomorrow's morning review
- Feed patterns into weekly review discussions

**Before Interactive Daily Review:**
- Consider quick inbox processing if feeling overwhelmed
- Complete any urgent tasks that are mentally distracting
- Find a quiet space for honest reflection

## Advanced Features

**Pattern Recognition (Multi-Day):**
When used regularly, the runbook can identify patterns:
- "I'm noticing you've mentioned energy crashes after lunch three days this week..."
- "Your most productive time seems consistently to be..."
- "You've had relationship insights the past few reviews..."

**Sequential Thinking Integration:**
For complex days or patterns:
- Use `create_thoughts` for deeper analysis of recurring issues
- Use `branch_thought` to explore alternative interpretations of events
- Use `summarize_thoughts` for synthesizing multi-day patterns

**Personalization Learning:**
The runbook adapts over time:
- Remembers which types of questions resonate most
- Identifies your consistent energy patterns and optimal timing
- Learns your communication style and adjusts accordingly

## Tips for Effective Daily Reviews

**For Users:**
- Be honest about struggles as well as wins
- Don't overthink - first reactions are often most insightful  
- Focus on learning rather than judgment
- Remember that "unsuccessful" days often teach the most

**For AI Assistants:**
- Balance data with empathy
- Celebrate small progress and learning
- Help users see patterns they might miss
- Always end with forward momentum, even on difficult days
- Remember that reflection itself is an accomplishment