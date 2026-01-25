---
name: Interactive Priority Matrix
description: Interactive task prioritization using the Eisenhower Matrix (Urgent/Important) with guided decision-making, context optimization, and GTD integration for maximum productivity and focus.
version: 1.0.0
type: runbook
tags:
  - runbook
  - interactive
  - priority-matrix
  - eisenhower-matrix
  - gtd
  - productivity
  - decision-making
author: GTD System
---

# Interactive Priority Matrix Runbook

A comprehensive, guided prioritization session using the Eisenhower Matrix to classify tasks by urgency and importance, optimize your focus, and create clear action plans for maximum productivity.

## Purpose

This runbook helps you:
- **Classify all tasks** using the Eisenhower Matrix (Urgent/Important)
- **Identify priority patterns** and decision-making insights
- **Optimize time allocation** based on matrix quadrants
- **Create action plans** for each priority category
- **Reduce reactive work** by planning proactive approaches
- **Align daily actions** with long-term importance
- **Build priority decision-making skills** for ongoing use

## Prerequisites

1. **GTD system** with current task list
2. **Dedicated focus time** (30-45 minutes)
3. **Current task load** that needs prioritization
4. **Calendar access** for time blocking and scheduling

## Instructions for AI Agent

This is an analytical and decision-making focused runbook. Ask **ONE question at a time**, help users think through priority criteria, and provide clear frameworks for difficult decisions. Use real task data from their GTD system.

### Phase 1: Priority Framework Setup

**Step 1: Prioritization Context**

```
🎯 **Welcome to Your Interactive Priority Matrix Session!**

Let's transform your task overwhelm into clear, prioritized action plans.

**Question 1:** What's driving your need for prioritization today?

A) 😰 **Overwhelmed** - Too many tasks, not sure where to focus
B) ⏰ **Time Crunch** - Limited time, need to choose what matters most
C) 🎯 **Clarity Seeking** - Want to ensure I'm working on the right things
D) 📊 **System Optimization** - Regular review to maintain good priorities
E) 🔥 **Crisis Mode** - Urgent issues requiring immediate priority decisions
F) 📈 **Growth Focus** - Want to spend more time on important, non-urgent work

Understanding your context helps us tailor the prioritization approach.

[Adapt matrix approach based on driving need]
```

**Step 2: Current Task Assessment**

Use `gtd_list_tasks(status="active")` to get current task list:

```
**Question 2:** Let's assess your current task load and scope.

**Your Current Active Tasks:** [X] total tasks
📋 **Task Overview:**
[Display categorized list of current tasks]

**Quick Assessment:**
• **Volume:** How does this number of tasks feel? (overwhelming, manageable, light)
• **Variety:** What types of work do you see? (deep work, admin, communication, etc.)
• **Time Sensitivity:** Any immediate deadlines or time constraints?
• **Energy Mix:** Tasks requiring high focus vs. low energy work?

**Prioritization Scope:**
Should we prioritize:
A) 📋 **All Active Tasks** - Complete task prioritization
B) 🎯 **Today's Focus** - Just tasks for today/this week
C) 📊 **Specific Category** - Tasks from particular context or project
D) 🔥 **Problem Areas** - Tasks you're struggling to prioritize

[Define scope based on needs and capacity]
```

### Phase 2: Eisenhower Matrix Education & Setup

**Step 3: Matrix Framework Introduction**

```
**Question 3:** How familiar are you with the Eisenhower Matrix?

Let me explain the framework we'll use:

**📊 The Four Quadrants:**

**🔴 Quadrant 1 - DO (Urgent & Important)**
• Crises, emergencies, pressing deadlines  
• Can't be avoided, must be handled immediately
• Goal: Minimize these through better planning

**🟢 Quadrant 2 - SCHEDULE (Important, Not Urgent)**  
• Long-term goals, planning, prevention, development
• Most valuable work, but easy to postpone
• Goal: Maximize time here for best results

**🟡 Quadrant 3 - DELEGATE (Urgent, Not Important)**
• Interruptions, some emails, some meetings
• Feels urgent but doesn't advance your goals
• Goal: Delegate, automate, or minimize

**⚫ Quadrant 4 - ELIMINATE (Not Urgent, Not Important)**
• Busy work, time wasters, excessive social media
• Neither urgent nor important to your goals
• Goal: Eliminate or drastically reduce

Ready to classify your tasks using this framework?

[Ensure understanding before proceeding]
```

**Step 4: Criteria Definition**

```
**Question 4:** Let's define what "urgent" and "important" mean for your specific situation.

**URGENT Criteria (Time Pressure):**
What makes something urgent for you?
• Hard deadlines (when?)
• Other people waiting (who?)
• Consequences of delay (what happens?)
• External time pressure (meetings, events)

**IMPORTANT Criteria (Value & Impact):**
What makes something important for you?
• Advances major goals or projects
• Aligns with core values and priorities  
• Has significant positive impact if done well
• Contributes to long-term success
• Only you can do it (unique skills/authority)

**Your Personal Context:**
• What are your top 3 current priorities/goals?
• What would "success" look like this week/month?
• What work creates the most value in your role?
• What tasks, if ignored, cause the biggest problems?

These criteria will guide our task classification.

[Establish personalized urgency and importance criteria]
```

### Phase 3: Task Classification Process

**Step 5: Task-by-Task Classification**

```
**Question 5:** Let's classify each of your tasks. I'll present them one by one.

**Task 1:** [First task from their list]
**Project:** [Associated project if any]
**Context:** [Current context]

**Classification Questions:**
🕐 **Urgency Assessment:**
• Is there a specific deadline? (When?)
• Are other people waiting for this?
• What happens if this waits another week?
• Is this creating time pressure or stress?

⭐ **Importance Assessment:**  
• Does this advance your major goals?
• What's the positive impact if done well?
• What's the negative impact if ignored?
• Could someone else do this instead?

**Your Assessment:** Urgent? (Yes/No) Important? (Yes/No)

Based on your answers:
🔴 **DO** (Urgent & Important) - Handle immediately
🟢 **SCHEDULE** (Important, Not Urgent) - Plan dedicated time
🟡 **DELEGATE** (Urgent, Not Important) - Find alternatives
⚫ **ELIMINATE** (Neither) - Question necessity

[Continue through all tasks systematically]
```

**Step 6: Matrix Population Review**

```
**Question 6:** Let's review your classified tasks and see the patterns.

**📊 Your Priority Matrix:**

**🔴 DO (Urgent & Important):** [X] tasks
[List Quadrant 1 tasks]

**🟢 SCHEDULE (Important, Not Urgent):** [X] tasks
[List Quadrant 2 tasks]

**🟡 DELEGATE (Urgent, Not Important):** [X] tasks
[List Quadrant 3 tasks]

**⚫ ELIMINATE (Neither Urgent nor Important):** [X] tasks  
[List Quadrant 4 tasks]

**Pattern Analysis:**
• Which quadrant has the most tasks?
• Any surprises in the classification?
• Tasks you found difficult to classify?
• Patterns in what ends up where?

**Initial Reactions:**
Does this distribution feel accurate and helpful?
Any tasks you want to reconsider or reclassify?

[Review and refine classifications]
```

### Phase 4: Quadrant-Specific Action Planning

**Step 7: Quadrant 1 - Crisis Management**

```
**Question 7:** Let's create an action plan for your DO (Urgent & Important) tasks.

**🔴 Your DO Tasks:** [List Quadrant 1 tasks]

**Immediate Action Planning:**
For each urgent & important task:

**[Task 1]:** 
• **Deadline:** When must this be completed?
• **Time Required:** How long will this take?
• **Dependencies:** What do you need to complete this?
• **Scheduling:** When will you do this? (specific time block)

**Crisis Prevention:**
Looking at these urgent tasks:
• Which ones could have been prevented with earlier action?
• What warning signs did you miss?
• How can you avoid similar crises in the future?

**Capacity Check:**
Given your DO tasks and their deadlines:
• Is your schedule realistic?
• What might need to be rescheduled or delegated?
• Any conflicts or resource constraints?

[Plan immediate action and future prevention]
```

**Step 8: Quadrant 2 - Strategic Planning**

```
**Question 8:** Now let's plan your SCHEDULE (Important, Not Urgent) tasks - the most valuable quadrant!

**🟢 Your SCHEDULE Tasks:** [List Quadrant 2 tasks]

**Strategic Planning:**
These tasks create the most value but are easiest to postpone.

**For Each Important Task:**
**[Task 1]:**
• **Value Impact:** What's the benefit of completing this well?
• **Time Investment:** How much focused time does this need?
• **Optimal Timing:** When are you most effective for this type of work?
• **Preparation:** Any research or setup required first?

**Time Protection Strategy:**
• **Calendar Blocking:** Should we schedule specific time blocks for these?
• **Energy Matching:** Which tasks need your peak energy times?
• **Environment:** Any special setup needed for focused work?
• **Defense:** How will you protect this time from urgent interruptions?

**Quadrant 2 Goal:**  
What percentage of your time would you ideally spend on important, non-urgent work?
Current estimate vs. goal?

[Plan strategic time allocation and protection]
```

**Step 9: Quadrant 3 - Delegation Strategy**

```
**Question 9:** Let's address your DELEGATE (Urgent, Not Important) tasks.

**🟡 Your DELEGATE Tasks:** [List Quadrant 3 tasks]

**Delegation Analysis:**
For each task that feels urgent but isn't truly important:

**[Task 1]:**
• **Urgency Source:** Why does this feel urgent? (External pressure, habit, etc.)
• **Importance Gap:** Why isn't this important to your goals?
• **Alternatives:** Who else could handle this?
• **Elimination:** Could this be skipped entirely?

**Delegation Options:**
👥 **People Delegation:** Who on your team or in your network could handle this?
🤖 **System Delegation:** Can this be automated or systematized?
📅 **Time Delegation:** Can this be batched or scheduled differently?
🚫 **Boundary Delegation:** Can you say no or set better boundaries?

**Decision Framework:**
For future urgent-but-unimportant tasks:
• Standard responses to common requests?
• Criteria for when you'll take these on vs. delegate?
• Systems to catch these earlier?

[Develop delegation and boundary strategies]
```

**Step 10: Quadrant 4 - Elimination Planning**

```
**Question 10:** Let's be honest about your ELIMINATE (Neither Urgent nor Important) tasks.

**⚫ Your ELIMINATE Tasks:** [List Quadrant 4 tasks]

**Elimination Assessment:**
For each low-value task:

**[Task 1]:**
• **Origin:** How did this get on your task list?
• **Habit:** Do you do this out of habit rather than necessity?
• **Value Question:** What would happen if you never did this again?
• **Time Sink:** How much time does this typically consume?

**Elimination Strategies:**
🗑️ **Delete:** Simply remove from your task list
🔄 **Minimize:** Reduce frequency or time spent
📱 **Automate:** Use tools to handle automatically
👥 **Delegate:** Give to someone who finds value in it
⏰ **Time-Box:** Limit to specific, small time allocation

**Hidden Time Wasters:**
Are there other activities not on your task list that belong in Quadrant 4?
• Excessive email checking?
• Social media browsing?
• Perfectionism on low-value work?
• Meetings that could be emails?

[Plan systematic elimination of low-value activities]
```

### Phase 5: Time Allocation & Scheduling

**Step 11: Ideal Time Distribution**

```
**Question 11:** Let's design your ideal time allocation across the four quadrants.

**Current Distribution Estimate:**
Looking at your tasks and typical week, estimate current time:
🔴 **Quadrant 1 (DO):** [X]% of time
🟢 **Quadrant 2 (SCHEDULE):** [X]% of time  
🟡 **Quadrant 3 (DELEGATE):** [X]% of time
⚫ **Quadrant 4 (ELIMINATE):** [X]% of time

**Ideal Distribution Goal:**
What would you like these percentages to be?
🔴 **Quadrant 1:** [target]% - (crisis management)
🟢 **Quadrant 2:** [target]% - (strategic work) 
🟡 **Quadrant 3:** [target]% - (delegatable urgent work)
⚫ **Quadrant 4:** [target]% - (elimination target)

**Expert Recommendation:**
• Quadrant 1: 20-25% (some crises are inevitable)
• Quadrant 2: 65-70% (maximum value creation)  
• Quadrant 3: 5-10% (minimize through delegation)
• Quadrant 4: 0-5% (near elimination)

How do your goals compare to these benchmarks?

[Set realistic time allocation targets]
```

**Step 12: Weekly Schedule Integration**

```
**Question 12:** Let's integrate your prioritized tasks into your actual schedule.

**Calendar Integration Strategy:**

**🔴 DO Tasks - Immediate Scheduling:**
[For each Quadrant 1 task]
**[Task]:** When will you complete this? (specific day/time)

**🟢 SCHEDULE Tasks - Time Blocking:**
**Peak Energy Blocks:** When are you most focused? (morning, afternoon, etc.)
**Deep Work Sessions:** How long can you focus without interruption?
**Frequency:** Daily Quadrant 2 time? Weekly blocks? Both?

**Suggested Schedule:**
• **Daily:** [X] minutes of important work (when?)
• **Weekly:** [X] hour focused block for strategic projects
• **Monthly:** [X] hour planning/review session

**Protection Strategies:**
• **Meeting Boundaries:** When do you NOT take meetings?
• **Communication Windows:** Designated email/message times?
• **Interruption Protocol:** How do you handle urgent but unimportant requests?

Should I help you block time on your calendar for priority work?

[Create specific scheduling plan]
```

### Phase 6: Decision-Making Systems

**Step 13: Priority Decision Framework**

```
**Question 13:** Let's create a decision-making system for future priority decisions.

**Quick Priority Assessment Tool:**
When new tasks or requests arise, ask:

**⏰ Urgency Test:**
• Is there a real deadline? (vs. artificial urgency)
• What are the actual consequences of delay?
• Is someone else creating false urgency?

**⭐ Importance Test:**
• Does this advance my major goals?
• What's the opportunity cost of saying yes?
• Am I the right person for this?
• What happens if I don't do this at all?

**Default Responses by Quadrant:**
🔴 **Urgent & Important:** "I'll handle this immediately"
🟢 **Important, Not Urgent:** "Let me schedule time for this properly"  
🟡 **Urgent, Not Important:** "Who else could handle this?"
⚫ **Neither:** "I'm going to pass on this"

**Boundary Scripts:**
What language helps you maintain priorities?
• For delegation requests?
• For non-urgent "urgent" requests?
• For low-value activities?

[Create personal decision-making framework]
```

### Phase 7: Implementation & System Updates

**Step 14: GTD System Updates**

```
I'm now updating your GTD system based on your priority classifications:

**Task Priority Updates:**
🔴 **DO Tasks:** [X] tasks marked as urgent/important
🟢 **SCHEDULE Tasks:** [X] tasks scheduled for focused time blocks
🟡 **DELEGATE Tasks:** [X] tasks marked for delegation/boundaries
⚫ **ELIMINATE Tasks:** [X] tasks removed or minimized

**Context Refinements:**
Based on priority analysis:
• Any contexts that need adjustment?
• New contexts needed (e.g., @delegate, @eliminate)?
• Priority flags or tags to add?

**Project Priority Updates:**
Do any projects need priority level adjustments based on this analysis?

**Question 14:** How should we integrate these priority insights into your ongoing GTD system?

A) 📋 **Priority Tags** - Add urgent/important tags to tasks
B) 🎯 **Context Refinement** - Adjust contexts to reflect priorities
C) 📅 **Calendar Integration** - Schedule priority work directly  
D) 🔄 **Review Integration** - Add priority check to weekly reviews
E) 📊 **Dashboard View** - Create priority-based task views

[Update GTD system based on priority insights]
```

### Phase 8: Monitoring & Adjustment

**Step 15: Priority Tracking System**

```
**Question 15:** Let's set up a system to monitor and maintain good priorities.

**Regular Priority Review:**
📅 **Daily:** Quick priority check during morning planning?
📊 **Weekly:** Full priority review during GTD weekly review?
🔄 **Monthly:** Priority pattern analysis and goal alignment?

**Priority Metrics to Track:**
⏱️ **Time Distribution:** Actual time spent in each quadrant
🎯 **Goal Progress:** How well priorities advance your major goals
😌 **Stress Levels:** Correlation between Quadrant 1 overload and stress
✅ **Completion Satisfaction:** Which priorities feel most rewarding

**Warning Signs to Monitor:**
🚨 **Quadrant 1 Overload:** Too much crisis management
😴 **Quadrant 2 Neglect:** Important work consistently postponed
🌊 **Quadrant 3 Creep:** Urgency addiction and boundary erosion
⏰ **Quadrant 4 Drain:** Time wasters sneaking back in

**Course Correction Triggers:**
What signs would indicate you need another priority matrix session?
• Feeling overwhelmed despite having systems?
• Major goal or life changes?
• Consistent time in wrong quadrants?

[Establish priority monitoring and adjustment system]
```

### Phase 9: Skills Development & Mastery

**Step 16: Priority Skills Assessment**

```
**Question 16:** Let's assess your priority-related skills and identify areas for development.

**Self-Assessment (1-10 scale):**

🎯 **Priority Identification:** How well do you distinguish urgent vs. important?
⏰ **Time Estimation:** How accurately do you estimate task duration?
🚫 **Boundary Setting:** How effectively do you say no to low-priority requests?
📅 **Planning:** How well do you protect time for important work?
🔄 **Flexibility:** How well do you adapt when priorities shift?
👥 **Delegation:** How comfortable are you delegating or asking for help?

**Skill Development Priorities:**
Based on your self-assessment and today's matrix work:
• Which skills would have the biggest impact if improved?
• Any patterns in your priority challenges?
• Skills that would prevent Quadrant 1 crises?

**Development Resources:**
What would help you improve priority management skills?
• Books, courses, or training?
• Practice opportunities or challenges?
• Accountability partner or coaching?
• Tools or systems upgrades?

[Identify priority skill development opportunities]
```

### Phase 10: Integration & Commitment

**Step 17: Priority System Integration**

```
**🎊 Congratulations on completing your Priority Matrix Session!**

**Your Priority System Results:**
📊 **Tasks Classified:** [X] total tasks organized by urgency/importance
⏰ **Time Allocated:** Clear plan for focus on high-value work
🎯 **Decisions Made:** [X] eliminations, [X] delegations, [X] scheduled priorities
📅 **Calendar Integrated:** Protected time blocks for important work
🛠️ **System Updated:** GTD system refined with priority insights

**Your Priority Distribution:**
🔴 **DO (Urgent & Important):** [X] tasks - [X]% target time
🟢 **SCHEDULE (Important, Not Urgent):** [X] tasks - [X]% target time
🟡 **DELEGATE (Urgent, Not Important):** [X] tasks - [X]% target time
⚫ **ELIMINATE (Neither):** [X] tasks minimized or removed

**Key Insights:**
• What was your biggest priority realization today?
• Which quadrant needs the most attention going forward?
• What will you do differently in your daily planning?

**Question 17:** How confident do you feel about your priority system now?

Rate 1-10:
• **Clarity:** Understanding of what's truly important vs. urgent
• **System:** Having tools and processes to maintain good priorities  
• **Skills:** Ability to make good priority decisions ongoing
• **Boundaries:** Confidence in saying no to low-priority requests

Any areas that need additional support or development?

[Assess confidence and identify remaining needs]
```

**Step 18: Implementation Commitment**

```
**Question 18:** Let's commit to implementing your priority system.

**This Week's Priority Commitments:**
🎯 **Quadrant 2 Focus:** What important work will you protect time for?
📅 **Schedule Defense:** How will you maintain your priority time blocks?
🚫 **Boundary Practice:** What will you say no to or delegate?
🔍 **Daily Check:** How will you maintain priority awareness?

**30-Day Priority Challenge:**
Would you like to commit to tracking your time distribution across quadrants for 30 days?
• Daily 2-minute priority reflection?
• Weekly quadrant time estimation?
• Monthly priority pattern review?

**Support Systems:**
• **Accountability:** Who can support your priority commitments?
• **Reminders:** What reminders would help maintain focus?
• **Reviews:** When is your next full priority matrix review?

**Success Metrics:**
How will you know your priority system is working?
• More time in Quadrant 2 (important, not urgent)?
• Less stress from crisis management?
• Better progress on major goals?
• Greater satisfaction with daily work?

Ready to make your priorities your reality? 🚀

[Secure implementation commitment and support]
```

## Advanced Features

### Dynamic Priority Assessment
- **Context-Based Priorities** - Different priority criteria for work vs. personal
- **Energy-Priority Matching** - Aligning high-importance tasks with peak energy
- **Seasonal Priority Shifts** - Adapting priorities to life phases and cycles

### Collaborative Priority Management
- **Team Priority Alignment** - Ensuring individual priorities support team goals
- **Delegation Optimization** - Smart matching of delegated tasks to team capabilities
- **Priority Communication** - Clear priority explanations for stakeholders

### Priority Analytics
- **Time Tracking Integration** - Measuring actual vs. intended time allocation
- **Priority Pattern Analysis** - Understanding personal priority tendencies
- **Goal Achievement Correlation** - Linking priority choices to goal progress

## Quadrant-Specific Strategies

### 🔴 **Quadrant 1 (DO) - Crisis Management**
- **Prevention Planning** - Systems to catch issues before they become urgent
- **Crisis Response Templates** - Standardized approaches for common emergencies
- **Stress Management** - Techniques for handling high-pressure situations

### 🟢 **Quadrant 2 (SCHEDULE) - Strategic Work**
- **Deep Work Protocols** - Optimal conditions for focused, important work
- **Long-term Planning** - Systems for keeping important work visible and planned
- **Skill Development** - Investing in capabilities that prevent future crises

### 🟡 **Quadrant 3 (DELEGATE) - Boundary Management**
- **Delegation Templates** - Standard processes for common delegation needs
- **Boundary Scripts** - Prepared responses for common low-importance requests
- **Authority Management** - Clear guidelines on when to take on others' urgent work

### ⚫ **Quadrant 4 (ELIMINATE) - Time Protection**
- **Elimination Audit** - Regular review of time-wasting activities
- **Habit Interruption** - Breaking patterns of low-value work
- **Value Focus** - Maintaining clear connection to high-value activities

## Benefits

✅ **Clear Focus** - Eliminate confusion about what to work on when  
✅ **Stress Reduction** - Less crisis management through better planning  
✅ **Goal Progress** - More time on important work that advances objectives  
✅ **Boundary Skills** - Better ability to say no to low-value requests  
✅ **Time Optimization** - Strategic allocation of time and energy resources  
✅ **Decision Framework** - Consistent criteria for evaluating new requests  
✅ **Long-term Thinking** - Balance between urgent demands and important goals  

This runbook transforms priority confusion into clear, systematic decision-making that aligns daily actions with long-term success!