---
name: Weekly Review Runbook
description: Interactive weekly review that guides you through questions to reflect on the past week and plan the upcoming week. Uses GTD methodology with conversational approach.
version: 2.0.0
type: runbook
tags:
  - runbook
  - weekly-review
  - gtd
  - planning
  - review
  - routine
  - interactive
  - questions
author: GTD System
---

# Interactive Weekly Review Runbook

An interactive, question-driven weekly review process that guides you through reflecting on the past week and planning the upcoming week using GTD methodology.

**Note:** This is an interactive runbook - the AI will ask you questions one at a time and wait for your responses before proceeding.

## Purpose

This interactive runbook guides you through a conversational weekly review:
- Reflecting on the previous week through questions and discussion
- Identifying patterns, wins, and areas for improvement
- Organizing your GTD system based on insights
- Planning the upcoming week with intention and clarity

## Prerequisites

- 60-90 minutes of uninterrupted time for reflection
- Willingness to engage in honest self-reflection  
- Access to your calendar, tasks, and logs for reference

## Interactive Runbook Steps

### Step 1: Weekly Review Opening - Get Centered

**Question:** "Hi! Ready for your weekly review? First, let's get centered. How are you feeling right now as we start this review? Are there any pressing thoughts or concerns on your mind that we should capture before we dive in?"

**Wait for Response**

**Follow-up Questions:**
- "Is there anything you've been meaning to capture or deal with that's been floating around in your head?"
- "How has your energy been this week overall?"
- "Are you in a good headspace to do some reflection, or do we need to address anything first?"

**Actions Based on Response:**
- Help them capture any loose items or open loops
- Note their current state and energy for context
- Call `gtd_get_datetime()` to establish the review timeframe

**What to do with the response:**
- Acknowledge their current state
- Capture any immediate items they want to note
- Set the tone for honest, productive reflection

**Next Step:** Wait for their response, then proceed to Step 2.

---

### Step 2: Previous Week Reflection

**Question:** "Let's start by looking back at this past week. What would you say were your biggest wins or accomplishments this week? What are you most proud of?"

**Wait for Response**

**Follow-up Questions:**
- "What didn't go as planned this week? What got left undone or didn't work out the way you hoped?"
- "Were there any patterns you noticed - times when you felt most/least productive, energized, or focused?"
- "What was the most challenging part of your week?"
- "Did anything surprise you about how the week unfolded?"

**Actions Based on Response:**
- Call `gtd_read_daily_log()` for recent days to supplement their memory if helpful
- Call `gtd_list_tasks(status='completed')` to see completed tasks they might have forgotten
- Note patterns and themes they mention

**Important Note:** If they mention sparse daily logs:
- "It sounds like you don't have much logged for this week. Would you be interested in the Interactive Morning Review Runbook to help build that habit? For now, let's work with your memory and what you do remember."

**What to do with the response:**
- Acknowledge their accomplishments enthusiastically
- Help them see patterns they might miss
- Note any incomplete items that need attention
- Capture insights about what works/doesn't work for them

**Next Step:** Wait for their response, then proceed to Step 3.

---

### Step 3: System and Commitment Review

**Question:** "Now let's look at your current commitments and projects. When you think about all the things you're supposed to be working on, what feels most important or urgent right now? What projects or areas are demanding your attention?"

**Wait for Response**

**Follow-up Questions:**
- "Are there any projects that feel stalled or stuck? What's blocking them?"
- "Looking at your task list, are there things that no longer feel relevant or important?"
- "What commitments are you carrying that might need to be renegotiated or released?"
- "Are there any areas where you feel overcommitted or spread too thin?"

**Actions Based on Response:**
- Call `gtd_list_projects(status='active')` to show current projects
- Call `gtd_list_tasks(status='active')` to review current tasks
- Help them identify what needs updating, completing, or releasing

**Interactive Review Process:**
For items they mention as problematic:
- "Would you like to update/remove [specific item]?"
- "What would need to happen to move [stalled project] forward?"
- "Should we archive [irrelevant task] or put it in someday/maybe?"

**What to do with the response:**
- Help them identify what's working vs. what's not
- Offer to update their GTD system based on their insights
- Note patterns of overcommitment or unclear priorities
- Create action items for system maintenance

**Next Step:** Wait for their response, then proceed to Step 4.

---

### Step 4: System Organization and Updates

**Question:** "Based on our conversation so far, it sounds like there are some updates needed to your system. What new tasks, projects, or commitments have come up that we should capture? And what items need to be updated, archived, or removed?"

**Wait for Response**

**Follow-up Questions:**
- "Are there any new projects or initiatives that should be added to your system?"
- "What tasks or reminders do you need to create based on this week's insights?"
- "Should we clean up any outdated or irrelevant items from your lists?"
- "Are there any priorities that need to be adjusted based on what you've learned this week?"

**Interactive Processing:**
For each item they mention:
- "Would you like me to create a task for [item]? What would be the next action?"
- "Should [old project] be archived or moved to someday/maybe?"
- "What priority level feels right for [new commitment]?"
- "When would you ideally work on [task]?"

**Actions Based on Response:**
- Create new tasks/projects based on their specifications
- Update existing items that need clarification
- Archive or remove irrelevant commitments
- Adjust priorities based on current insights

**What to do with the response:**
- Turn their insights into actionable system updates
- Help them feel organized and current
- Ensure nothing important is falling through the cracks
- Create a sense of control and clarity

**Next Step:** Wait for their response, then proceed to Step 5.

---

### Step 5: Looking Ahead - Upcoming Week Planning

**Question:** "Now let's look ahead to next week. What do you know is coming up? Any important meetings, deadlines, events, or commitments that are already on your calendar?"

**Wait for Response**

**Follow-up Questions:**
- "What preparation do you need to do for any of these upcoming events?"
- "Are there any potential conflicts or scheduling challenges you can see?"
- "Based on what you know about next week, what's your realistic capacity? Will it be a busy week or more open?"
- "Are there any important but non-urgent things you'd like to make progress on next week?"

**Actions Based on Response:**
- Call `gtd_get_calendar_overview()` to supplement their memory
- Help identify preparation tasks needed
- Note capacity constraints and energy considerations

**Planning Questions:**
- "What would make next week feel successful and productive?"
- "If you could only focus on 2-3 main things next week, what would they be?"
- "Are there any blocks of focused time you should protect for important work?"
- "What might derail your plans, and how can you prepare for that?"

**What to do with the response:**
- Help them set realistic expectations for the week
- Identify key priorities and focus areas
- Create preparation tasks for upcoming events
- Note potential challenges and mitigation strategies

**Next Step:** Wait for their response, then proceed to Step 6.

---

### Step 6: Weekly Intentions and Focus Setting

**Question:** "Based on everything we've discussed - your reflections on this past week and what's coming up next week - what do you want to focus on? If next week could only be about 2-3 main things, what would you want them to be?"

**Wait for Response**

**Follow-up Questions:**
- "How do these priorities connect to your bigger goals or vision?"
- "What would make next week feel meaningful and successful for you personally?"
- "Is there anything related to your health, relationships, or personal growth that deserves attention next week?"
- "What's one new thing you'd like to learn or improve on?"
- "How do you want to show up next week? What mindset or approach would serve you best?"

**Intention Setting Questions:**
- "What would you regret not making progress on next week?"
- "Is there someone you want to connect with or support?"
- "What habit or routine would you like to maintain or start?"
- "How can you make next week align with what matters most to you?"

**Actions Based on Response:**
- Help them articulate clear, specific weekly intentions
- Connect daily actions to bigger picture goals
- Ensure balance between work, personal, and growth priorities
- Create accountability for their commitments

**What to do with the response:**
- Summarize their key intentions and priorities
- Help them see how weekly goals connect to larger vision
- Create specific, actionable commitments
- Set up systems for tracking progress

**Next Step:** Wait for their response, then proceed to Step 7.

---

### Step 7: Insights and System Updates

**Question:** "As we wrap up, what insights or patterns are you noticing from our conversation? What's working well for you, and what might need to change or improve?"

**Wait for Response**

**Follow-up Questions:**
- "Are there any habits, routines, or systems that are serving you well that you want to continue?"
- "What's not working as well as you'd like? What feels like it needs adjustment?"
- "Based on this review, are there any changes you want to make to how you plan your weeks or manage your commitments?"
- "What would help you have better weeks going forward?"

**System Update Questions:**
- "Should we create any new tasks or projects based on what you've shared?"
- "Are there any priorities or contexts that need updating in your system?"
- "Would you like to set up any reminders or recurring check-ins based on these insights?"
- "How do you want to remember or track the intentions you've set for next week?"

**Actions Based on Response:**
- Create tasks/projects based on their commitments and insights
- Update system priorities and organization
- Set up tracking or reminder systems as requested
- Capture key insights for future reference

**What to do with the response:**
- Ensure their GTD system reflects current reality and priorities
- Help them implement improvements they've identified
- Create accountability mechanisms for their commitments
- Document insights for future weekly reviews

**Next Step:** Wait for their response, then proceed to Step 8.

---

### Step 8: Weekly Review Summary and Commitment

**Action:** Provide a personalized summary and final commitment check.

**Summary Format:**
```
🗓️ Weekly Review Summary:

Past Week Reflection:
✅ Key Accomplishments: [their main wins]
🔍 Patterns Noticed: [themes and insights]
💡 Lessons Learned: [what they discovered]

Upcoming Week Focus:
🎯 Top Priorities:
1. [Priority 1]
2. [Priority 2] 
3. [Priority 3]

📋 Key Commitments: [important meetings/deadlines/events]
💪 Personal Intentions: [health/relationships/growth goals]
🔧 System Improvements: [changes they want to make]

Next Steps:
- [Specific tasks/projects created]
- [System updates made]
- [Follow-up actions planned]
```

**Final Questions:**
- "Does this summary capture your week well?"
- "How are you feeling about the week ahead now?"
- "Is there anything else you want to add or adjust?"
- "What will help you remember and stay committed to these intentions?"

**Completion Criteria:**
- ✅ Previous week thoroughly reflected upon
- ✅ Current system reviewed and updated  
- ✅ Upcoming week planned with clear priorities
- ✅ Weekly intentions set with personal meaning
- ✅ Insights captured for continuous improvement
- ✅ Feeling of clarity and control established

**Success Indicators:**
- User feels clear and confident about the week ahead
- System is current and organized
- Realistic priorities set based on actual capacity
- Balance between work, personal, and growth priorities
- Actionable next steps created

## Key Principles for AI Implementation

**CRITICAL: This is an INTERACTIVE runbook**
- **Ask ONE question at a time**
- **Wait for user response before proceeding**  
- **Don't rush through all questions at once**
- **Adapt questions based on their responses**
- **Show genuine curiosity and interest**

**Conversational Style:**
- Use a warm, reflective tone
- Acknowledge their insights and celebrate their wins
- Ask follow-up questions that show you're listening
- Help them connect dots and see patterns
- Balance challenge with support

**Flexibility:**
- Spend more time on areas they seem concerned about
- Skip questions that don't resonate or seem irrelevant  
- Allow tangents if they lead to important insights
- Adjust pace based on their engagement level
- Focus on their priorities, not checklist completion

**Practical Focus:**
- Turn reflections into actionable next steps
- Create tasks and commitments in their GTD system
- Make concrete plans based on their insights  
- Help them see progress and growth

## Time Guidelines

**Interactive Session Time:**
- **Step 1:** 5-10 minutes (centering and setup)
- **Step 2:** 15-20 minutes (past week reflection)
- **Step 3:** 15-20 minutes (system and commitment review)
- **Step 4:** 10-15 minutes (organization and updates)
- **Step 5:** 10-15 minutes (upcoming week planning)
- **Step 6:** 10-15 minutes (intention setting)
- **Step 7:** 10-15 minutes (insights and system updates)
- **Step 8:** 5-10 minutes (summary and commitment)

**Total Time:** 80-120 minutes (plan for 90 minutes)

## Error Handling

**If overwhelmed by the review:**
- Break it into smaller sessions
- Focus on the most critical steps (2, 3, 4)
- Use timers to stay focused
- Remember: done is better than perfect

**If system has too many items:**
- Prioritize ruthlessly
- Move non-critical items to someday/maybe
- Consider if you're over-committed
- Focus on outcomes, not just activities

**If tools fail:**
- Continue with available information
- Make notes of what couldn't be checked
- Manually review what you can remember
- Update systems when tools are working

## Usage

**To use this runbook:**
1. Ask: "Guide me through a weekly review using the runbook"
2. Or: "Let's do my weekly review following the runbook"
3. Or: "Start the weekly review runbook process"

**Best Times for Weekly Reviews:**
- Friday afternoon (prepare for next week)
- Sunday evening (transition into new week)
- Consistent day/time each week

## Integration with Other Runbooks

**Before Weekly Review:**
- Consider doing daily log reviews for the past week
- Ensure daily logs are up to date

**After Weekly Review:**
- Use daily runbooks throughout the week
- Update daily logs with weekly insights
- Plan daily priorities based on weekly intentions

## Benefits of Regular Weekly Reviews

- **Stress Reduction:** Nothing falls through cracks
- **Clarity:** Clear priorities and commitments  
- **Control:** Proactive vs reactive management
- **Alignment:** Actions match intentions and goals
- **Growth:** Continuous learning and improvement
- **Trust:** Confidence in your system and decisions

## Tips for Effective Weekly Reviews

1. **Consistency:** Same day/time each week
2. **Environment:** Quiet, distraction-free space
3. **Tools:** Have all systems accessible
4. **Honesty:** Be realistic about capacity and commitments
5. **Focus:** Complete the review, resist task-switching
6. **Flexibility:** Adapt the process to your needs
7. **Action:** Don't just review - update and commit

## Troubleshooting Common Issues

**"I don't have time for weekly reviews"**
- Start with 30-minute version (steps 2, 3, 4 only)
- Block time like any important meeting
- Remember: reviews save more time than they cost

**"My system is too complex"**
- Simplify during the review process
- Focus on actionable items only
- Consider if complexity serves you

**"I keep forgetting to do reviews"**
- Set recurring calendar reminder
- Link to existing weekly routine
- Start small and build the habit

**"Reviews feel overwhelming"**
- Break into shorter sessions
- Focus on one step at a time
- Use timers to maintain momentum

## Monthly Integration

This weekly review prepares for and complements monthly reviews:
- Weekly insights inform monthly planning
- Monthly goals guide weekly priorities
- Quarterly goals influence monthly themes
- Annual vision shapes quarterly objectives