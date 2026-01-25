---
name: Interactive Context Review
description: Comprehensive context-based task review and batch processing session. Optimizes productivity by systematically working through tasks grouped by context (@calls, @email, @errands, etc.) with energy and time matching.
version: 1.0.0
type: runbook
tags:
  - runbook
  - interactive
  - context-review
  - gtd
  - productivity
  - batch-processing
  - focus
author: GTD System
---

# Interactive Context Review Runbook

A systematic, interactive session for reviewing and processing tasks by context. Maximizes productivity through intelligent batch processing, energy matching, and focused work sessions.

## Purpose

This runbook optimizes your task execution by:
- **Grouping tasks by context** (@calls, @email, @errands, etc.)
- **Batch processing** similar activities for efficiency
- **Matching tasks to energy levels** and available time
- **Eliminating context switching** overhead
- **Creating focused work sessions** with clear outcomes
- **Optimizing your environment** for maximum productivity
- **Tracking completion satisfaction** and momentum

## Prerequisites

1. **GTD system** with tasks organized by contexts
2. **Current task list** with active next actions  
3. **Time block available** for focused context work (30-120 minutes)
4. **Access to relevant tools** (phone, computer, transportation for errands)

## Instructions for AI Agent

This is a highly interactive runbook. Ask **ONE question at a time**, adapt to user responses, and use real GTD system data. Focus on creating productive, satisfying work sessions.

### Phase 1: Context Review Setup

**Step 1: Current State Assessment**

```
🎯 **Welcome to Interactive Context Review!**

Let's start by understanding your current situation and goals.

**Question 1:** What's driving this context review session today?

A) 🔥 **Focused Work Session** - I have dedicated time to knock out tasks
B) ⚡ **Quick Context Clear** - I want to batch similar tasks efficiently  
C) 🧠 **Energy Optimization** - I want to match tasks to my current energy
D) 📅 **Time-Specific** - I have a specific time window to use productively
E) 🎯 **Context Overload** - One of my contexts has too many tasks

[Adapt session based on motivation]
```

**Step 2: Available Resources Assessment**

Use `gtd_list_tasks(status="active")` to get current task list, then:

```
**Question 2:** What resources do you have available right now?

📱 **Communication:** Phone access for calls/texts?
💻 **Computer:** Full computer setup with internet?
🚗 **Transportation:** Can you travel for errands?
🏢 **Location:** Where are you? (home, office, mobile)
⏰ **Time:** How much time do you have available?
⚡ **Energy:** How's your energy level? (high, medium, low)

[Use responses to filter appropriate contexts and tasks]
```

### Phase 2: Context Analysis & Selection

**Step 3: Context Overview**

Analyze user's current tasks by context:

```
**Question 3:** Looking at your current tasks, here's your context breakdown:

📞 **@calls**: [X] tasks - [brief summary]
✉️ **@email**: [X] tasks - [brief summary] 
🏃 **@errands**: [X] tasks - [brief summary]
💻 **@computer**: [X] tasks - [brief summary]
👥 **@agenda-[people]**: [X] tasks - [brief summary]
🧠 **@think**: [X] tasks - [brief summary]
📚 **@read**: [X] tasks - [brief summary]
[Other contexts]: [X] tasks each

Which context feels most important or appealing to tackle right now?

[Wait for selection, then dive deeper into that context]
```

**Step 4: Context Deep Dive**

For selected context, show specific tasks:

```
**Question 4:** Let's dive into your **[SELECTED CONTEXT]** tasks:

[List specific tasks in selected context with details]

Looking at these tasks:
• Which ones feel most important or urgent?
• Are there any you could do quickly (< 5 minutes)?
• Any that require specific timing or preparation?
• Any you're avoiding or feel resistant to?

What patterns do you notice?

[Understand task relationships and user feelings]
```

### Phase 3: Energy & Time Optimization

**Step 5: Energy-Task Matching**

```
**Question 5:** Let's match these tasks to your current energy and mental state.

For your current energy level, how do these tasks feel?

[For each task in selected context, ask:]

**Task:** [Task description]
A) 🚀 **High Energy Match** - I'm excited to tackle this  
B) ⚡ **Good Energy Match** - I can handle this well
C) 🔋 **Medium Energy** - Doable but not ideal
D) 😴 **Low Energy Needed** - This feels heavy right now
E) ⏰ **Time/Setup Issue** - Need different timing or preparation

[Rank tasks by energy match for optimal sequencing]
```

**Step 6: Batch Processing Opportunities**

```
**Question 6:** I notice some tasks that could be batched together efficiently:

[Identify similar tasks that can be grouped]

**Proposed Batches:**
• **Quick Wins** (< 5 min each): [List quick tasks]
• **Deep Work** (> 30 min each): [List complex tasks]
• **Similar Tools/Setup**: [List tasks needing same resources]
• **Same Location/Person**: [List related tasks]

Does this grouping make sense? Any adjustments?

[Refine batching based on user input]
```

### Phase 4: Session Planning

**Step 7: Session Design**

```
**Question 7:** Let's design your optimal work session.

Based on your time ([X] minutes) and energy, I suggest:

**Option A - Power Sprint:**
• 25 min focused work + 5 min break (Pomodoro style)
• Focus on [2-3 highest energy match tasks]

**Option B - Batch Processing:**  
• Group similar tasks together
• Start with quick wins, build momentum
• [X] minute session with natural breaks

**Option C - Mixed Session:**
• Start with 1 quick win for momentum
• Tackle 1 major task
• End with easier tasks

Which approach feels best for you today?

[Customize session based on preference]
```

**Step 8: Environment Optimization**

```
**Question 8:** Let's optimize your environment for maximum focus.

For your [CONTEXT] work session:

**Physical Setup:**
• Do you have everything you need? ([context-specific tools])
• Any distractions to eliminate? (notifications, clutter, etc.)
• Optimal lighting, temperature, seating?

**Mental Preparation:**  
• Any quick mental clearing needed?
• Background music or silence?
• Water, snacks, bathroom break first?

**Focus Ritual:**
• How do you like to start focused work sessions?

What setup would help you succeed?

[Help optimize work environment]
```

### Phase 5: Task Execution Guidance

**Step 9: Session Launch**

```
**🚀 Ready to launch your [CONTEXT] session!**

**Your Session Plan:**
• **Duration:** [X] minutes
• **Context:** [Selected context]
• **Task Order:** [Optimized sequence]
• **Environment:** [Optimizations noted]

**Question 9:** Before we start, how would you like me to support you during the session?

A) 🎯 **Task-by-Task Guidance** - Check in after each task
B) ⏰ **Time Check-ins** - Remind you of time every [X] minutes  
C) 🧘 **Mindful Transitions** - Help with breaks and transitions
D) 📊 **Progress Tracking** - Update on accomplishments
E) 🔇 **Silent Focus** - Just track progress, check in at end

[Provide requested support level]
```

**Step 10: Task-by-Task Processing**

For each task in the session:

```
**Current Task:** [Task description]
**Estimated Time:** [X] minutes
**Context:** [Context]

**Before you start:**
• Is everything set up for this task?
• Any questions or clarity needed?
• Ready to begin?

**[WORK TIME]**

**After completion:**
• How did that go? (1-5 satisfaction scale)
• Any follow-up actions needed?
• Ready for the next task?

[Continue through planned tasks]
```

### Phase 6: Session Monitoring & Adaptation

**Step 11: Energy Check-ins**

During longer sessions:

```
**Energy Check-in** (every 25-30 minutes):

**Question 11:** How are you feeling right now?

🚀 **High Energy** - Ready to tackle challenging tasks
⚡ **Good Energy** - Maintaining good focus  
🔋 **Medium Energy** - Could use easier tasks
😴 **Lower Energy** - Maybe time for a break or different approach
🛑 **Need Break** - Definite break time

Based on your energy, should we:
• Continue as planned?
• Switch to easier tasks?
• Take a break?
• Adjust the session?

[Adapt session based on real-time energy]
```

**Step 12: Progress Momentum**

```
**🎉 Progress Check!**

**Completed So Far:**
✅ [List completed tasks]

**Question 12:** How does this progress feel?

A) 🔥 **Momentum Building** - Feeling great, want to keep going
B) ✅ **Steady Progress** - Good consistent work
C) 😐 **Slog Mode** - Getting things done but not exciting
D) 😓 **Struggling** - Tasks feel harder than expected
E) 🎯 **Ready to Switch** - Want to change context or approach

**Remaining Tasks:**
• [List remaining planned tasks]

Should we continue as planned or make adjustments?

[Adapt based on momentum and satisfaction]
```

### Phase 7: Context Completion & Review

**Step 13: Session Completion**

```
**🏁 Session Complete!**

**Your Accomplishments:**
✅ [List all completed tasks]
📊 **Completion Rate:** [X]% of planned tasks
⏰ **Time Used:** [X] of [Y] minutes available
⚡ **Energy Level:** [Current vs starting energy]

**Question 13:** Looking at what you accomplished, how do you feel?

Rate your satisfaction: 1-10
• What worked really well in this session?
• What was challenging or inefficient?
• Any insights about your [context] work style?

[Capture feedback and insights]
```

**Step 14: Remaining Task Planning**

```
**Question 14:** You have [X] tasks remaining in this context:

[List uncompleted tasks]

For these remaining tasks:
A) 📅 **Schedule Next Session** - Plan another [context] batch session
B) 🔄 **Reschedule Tasks** - Move to different contexts or times
C) 📝 **Modify Tasks** - Break down or redefine challenging tasks
D) ⚡ **Quick Second Round** - Tackle a few more right now
E) ✅ **Context Complete** - These can wait for natural opportunities

What feels right for the remaining tasks?

[Handle remaining tasks appropriately]
```

### Phase 8: Context Optimization Learning

**Step 15: Pattern Recognition**

```
**Question 15:** Let's capture insights to optimize future [context] sessions:

**Task Timing:**
• Which tasks took longer/shorter than expected?
• What was your optimal task sequence?
• Best time of day for this context?

**Energy Patterns:**
• Which tasks energized vs drained you?
• How did your energy change throughout the session?

**Environment/Setup:**
• What environmental factors helped or hindered?
• Any tools or resources you needed but didn't have?

**Batch Processing:**
• Did grouping similar tasks help efficiency?
• Any better ways to batch these activities?

[Capture optimization insights]
```

**Step 16: Context Review Scheduling**

```
**Question 16:** Based on today's session, how would you like to handle [context] tasks going forward?

**Frequency Options:**
• **Daily Mini-Sessions** (15-20 min daily [context] time)
• **Weekly Batch Sessions** (60-90 min weekly [context] blocks)  
• **Opportunistic Processing** (tackle when convenient)
• **Energy-Based** (only when energy matches context needs)

**Optimization Ideas:**
• Set up dedicated [context] workspace/tools
• Block calendar time for [context] batches
• Create [context] task templates or checklists
• Identify optimal [context] timing

What approach would work best for your lifestyle?

[Plan ongoing context optimization]
```

### Phase 9: GTD System Updates

**Step 17: Task Status Updates**

```
I'm updating your GTD system with today's progress:

✅ **Completed Tasks:** [X] tasks marked complete
🔄 **Modified Tasks:** [Tasks that were changed/refined]
📅 **Rescheduled Tasks:** [Tasks moved to different contexts/times]
📝 **New Tasks:** [Any new tasks identified during session]

**Context Health Update:**
• **[Context]**: [X] remaining tasks, next session recommended [timing]
• **Overall**: [Assessment of user's context balance]

[Update all tasks and provide system health overview]
```

### Phase 10: Momentum Planning

**Step 18: Cross-Context Planning**

```
**Question 17:** After this great [context] session, what context would you like to tackle next?

**Current Context Status:**
📞 **@calls**: [X] tasks - [energy level needed]
✉️ **@email**: [X] tasks - [energy level needed]
🏃 **@errands**: [X] tasks - [energy level needed]  
💻 **@computer**: [X] tasks - [energy level needed]
[Other contexts with task counts]

**Suggestions based on current energy/momentum:**
• [Context recommendation based on energy and momentum]

Should we plan your next context session?

[Help plan optimal context sequence]
```

**Step 19: Success Celebration**

```
**🎉 Congratulations on a productive [context] session!**

**Today's Win:**
✅ **Tasks Completed:** [X] 
⏰ **Focused Time:** [X] minutes of productive work
🎯 **Context Efficiency:** Batch-processed [context] tasks effectively
⚡ **Energy Management:** [Observation about energy usage]
📈 **System Health:** [Context] context is now more manageable

**Question 18:** How would you like to celebrate this productivity win?

A) 🎯 **Keep Rolling** - Ride this momentum to another context
B) ☕ **Reward Break** - Take a well-earned break  
C) 📝 **Reflection Time** - Journal about insights and progress
D) 📞 **Share Success** - Tell someone about your accomplishment
E) 🎮 **Fun Activity** - Do something enjoyable to celebrate

You've earned whatever feels right! 🚀

[Support chosen celebration/transition]
```

## Advanced Features

### Smart Context Switching
- **Energy-based recommendations** for optimal context sequences
- **Time-block integration** with calendar availability
- **Interruption handling** when urgent tasks arise mid-session

### Context Analytics
- **Completion rate tracking** by context over time
- **Energy pattern recognition** for each context type
- **Optimal timing identification** for different contexts
- **Batch size optimization** based on historical performance

### Environmental Intelligence
- **Location-based context filtering** (only show @errands when out)
- **Tool availability checking** (only suggest @calls when phone available)
- **Calendar integration** for context-appropriate time blocks

## Context-Specific Optimizations

### 📞 @calls Context
- **Call script preparation** and talking points
- **Batch calling efficiency** (similar calls together)
- **Follow-up task creation** from call outcomes

### ✉️ @email Context  
- **Email batch processing** with templates
- **Response prioritization** and quick wins identification
- **Inbox zero progression** tracking

### 🏃 @errands Context
- **Route optimization** for efficient travel
- **Store hours checking** and availability confirmation
- **Grouping by location** and timing

### 💻 @computer Context
- **Deep work vs. quick tasks** energy matching
- **Tool setup optimization** and distraction elimination
- **Multitasking prevention** and focus maintenance

## Benefits

✅ **Elimination of Context Switching** - Batch similar tasks for efficiency  
✅ **Energy Optimization** - Match tasks to current energy levels  
✅ **Focused Work Sessions** - Create distraction-free productivity blocks  
✅ **Momentum Building** - Quick wins fuel continued progress  
✅ **System Health** - Keep contexts manageable and current  
✅ **Satisfaction Tracking** - Maintain motivation through visible progress  

This runbook transforms scattered task execution into systematic, satisfying productivity sessions that respect your energy and maximize your focus!