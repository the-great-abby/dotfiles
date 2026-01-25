---
name: Interactive Project Planning
description: Comprehensive, step-by-step project planning session using GTD's Natural Planning Model. Transforms big projects into clear, actionable task lists with proper organization and next actions.
version: 1.0.0
type: runbook
tags:
  - runbook
  - interactive
  - project-planning
  - gtd
  - natural-planning-model
  - next-actions
author: GTD System
---

# Interactive Project Planning Runbook

A comprehensive, conversational project planning session that uses David Allen's Natural Planning Model to transform overwhelming projects into organized, actionable task lists.

## Purpose

This runbook guides you through the complete project planning process:
- **Clarify project purpose** and success criteria
- **Apply Natural Planning Model** systematically
- **Break down complex projects** into manageable tasks
- **Identify clear next actions** and organize by context
- **Set up project tracking** and milestone monitoring
- **Create realistic timelines** and resource allocation
- **Integrate seamlessly** with your GTD system

## Prerequisites

1. **GTD system** properly configured
2. **Project concept or need** identified
3. **Time for planning session** (20-60 minutes depending on complexity)
4. **Access to GTD tools** for task and project creation

## Instructions for AI Agent

This is a highly interactive runbook. Ask **ONE question at a time** and adapt subsequent questions based on user responses. Use actual GTD system data to provide context and suggestions.

### Phase 1: Project Initialization

**Step 1: Project Discovery**
Start by understanding the project scope:

```
🎯 **Welcome to Interactive Project Planning!**

Let's start with the basics about your project.

**Question 1:** What is the project or outcome you want to plan? 
(Describe it in a few sentences - don't worry about being perfect, we'll refine this together)

[Wait for response, then continue to Step 2]
```

**Step 2: Project Classification**
Determine project type and complexity:

```
**Question 2:** Looking at what you described, which best describes this project?

A) 📋 **Simple Multi-Step Project** (3-10 clear steps, straightforward)
B) 🏗️ **Complex Project** (Multiple phases, dependencies, resources needed)  
C) 🌟 **Ongoing Area of Focus** (Continuous improvement, no clear end)
D) 🚀 **Creative/Exploratory Project** (Research, learning, uncertain outcomes)
E) 🎯 **Goal Achievement Project** (Specific measurable outcome)

[Adapt planning approach based on selection]
```

### Phase 2: Natural Planning Model - Purpose & Principles

**Step 3: Purpose Clarification**

```
**Question 3:** Let's get crystal clear on WHY this project matters.

Complete this sentence: "The purpose of this project is to..."

Think about:
• What problem does this solve?
• What opportunity does this create?  
• Why is this important to you/your organization?
• What happens if this project succeeds? If it fails?

[Wait for purpose statement, acknowledge and refine if needed]
```

**Step 4: Guiding Principles**

```
**Question 4:** What principles or constraints should guide this project?

Consider:
• Quality standards (what does "good enough" look like?)
• Timeline constraints (any hard deadlines?)
• Budget or resource limits?
• People or stakeholders to consider?
• Values that must be honored?

For example: "We must deliver by Q2, involve the whole team, and maintain our quality standards"

[Capture principles and constraints]
```

### Phase 3: Natural Planning Model - Vision & Brainstorming

**Step 5: Vision Creation**

```
**Question 5:** Let's paint a picture of SUCCESS. 

Imagine it's [time frame] and this project is completely successful. Describe what you see:

• What exists that didn't exist before?
• How do people feel?
• What has changed?
• What are people saying about the outcome?
• How do YOU feel about what you've accomplished?

Be as specific and vivid as possible - this vision will guide all our planning.

[Wait for vision, help refine and make it compelling]
```

**Step 6: Creative Brainstorming**

```
**Question 6:** Now let's brainstorm everything that might be involved in making this vision real.

Don't organize or judge yet - just capture ideas:

• What major steps or phases come to mind?
• What resources might you need?
• Who might need to be involved?
• What could go wrong (and how to prevent it)?
• What research or learning is needed?
• What tools, systems, or processes are required?

Share whatever comes to mind - we'll organize it all next!

[Capture all ideas without judgment, encourage creative thinking]
```

### Phase 4: Natural Planning Model - Organizing

**Step 7: Component Organization**

Based on brainstorming, organize into major components:

```
**Question 7:** Looking at all the ideas we captured, I see several themes emerging.

Let me organize these into major project components:

[AI organizes brainstormed items into logical groups]

Does this organization make sense? Are there:
• Any missing major components?
• Components that should be combined?
• Things in the wrong category?
• Different way to structure this?

[Refine organization based on feedback]
```

**Step 8: Sequencing and Dependencies**

```
**Question 8:** Now let's think about ORDER and DEPENDENCIES.

For each major component:
1. What must happen BEFORE this component can start?
2. What can happen IN PARALLEL with other work?
3. What DEPENDS ON this component being completed?

Let's go through them one by one:
[Component 1]: What needs to happen before you can start this?

[Continue for each component, building dependency map]
```

### Phase 5: Next Actions Identification

**Step 9: Next Actions Discovery**

```
**Question 9:** For each component, let's identify the very NEXT physical action required.

[Component 1]: What is the very next physical action you need to take to move this forward?

Remember, a good next action:
✅ Starts with a verb
✅ Is specific enough that you could do it right now
✅ Has a clear outcome
✅ Doesn't require further planning

For example: "Call John to discuss requirements" not "Figure out requirements"

[Continue for each component]
```

**Step 10: Context Assignment**

```
**Question 10:** Let's assign contexts to make these actions easier to execute.

For each next action, which context fits best?

🖥️ @computer - Requires computer/internet
📞 @calls - Phone calls to make
✉️ @email - Email communications  
🏃 @errands - Things to do when out
👥 @agenda-[person] - Items to discuss with specific people
🧠 @think - Planning, thinking, reflecting
📚 @read - Reading or research
🏠 @home - Actions requiring being at home
🏢 @office - Actions requiring being at office

[Assign contexts to each next action]
```

### Phase 6: Project Setup & Integration

**Step 11: Project Creation**

```
Let me create this project in your GTD system with all the information we've gathered.

**Creating Project:**
- Title: [Refined project title]
- Purpose: [Purpose statement]
- Vision: [Success vision]  
- Status: Active
- Components: [Major components identified]
```

Use `gtd_create_project()` with the gathered information.

**Step 12: Task Creation**

```
**Question 11:** Now I'll create all the next actions we identified. 

Should I:
A) Create ALL next actions now (full project task list)
B) Create only the IMMEDIATE next actions (next 1-2 weeks)
C) Create next actions by COMPONENT (you choose which components to activate)

What's your preference for managing this project?

[Create appropriate tasks based on preference]
```

Use `gtd_create_task()` for each identified next action with proper contexts.

### Phase 7: Milestone & Timeline Planning

**Step 13: Milestone Identification**

```
**Question 12:** Let's identify key milestones - the major checkpoints that show progress.

Looking at your project components, what are the major milestones?

For example:
• "Requirements finalized" (end of research phase)
• "Prototype completed" (end of development phase)  
• "Team trained" (end of rollout phase)

These should be clear outcomes you can celebrate achieving!

[Identify and capture milestones]
```

**Step 14: Timeline Estimation**

```
**Question 13:** Let's create a realistic timeline.

For each major component, what's your best estimate:

[Component 1]: How long do you think this will take?
• Optimistic estimate (everything goes perfectly)
• Realistic estimate (normal challenges)  
• Pessimistic estimate (significant obstacles)

We'll use these to build a project timeline with buffers.

[Continue for all components, build overall timeline]
```

### Phase 8: Risk Assessment & Contingency

**Step 15: Risk Identification**

```
**Question 14:** Let's identify potential risks and how to handle them.

What could potentially derail or delay this project?

For each risk you identify:
• How likely is it? (High/Medium/Low)
• How much impact? (High/Medium/Low)  
• What could you do to PREVENT it?
• What would you do IF it happens?

[Identify and plan for major risks]
```

### Phase 9: Resource Planning

**Step 16: Resource Assessment**

```
**Question 15:** What resources do you need to make this project successful?

Consider:
👥 **People:** Who needs to be involved? Skills needed?
💰 **Budget:** Any costs for tools, services, materials?  
⏰ **Time:** How much time per week can you dedicate?
🛠️ **Tools:** Software, equipment, or systems needed?
📚 **Knowledge:** What do you need to learn or research?
🏢 **Space:** Physical or digital workspace requirements?

[Assess and plan for resource needs]
```

### Phase 10: Review & Launch Planning

**Step 17: Project Review Setup**

```
**Question 16:** How do you want to track progress and stay on top of this project?

Options:
A) 📅 **Weekly Project Review** - Dedicated weekly check-in
B) 🎯 **Milestone Reviews** - Review at each major milestone  
C) 📊 **Monthly Project Dashboard** - Monthly progress assessment
D) 🔄 **Daily Standup Style** - Brief daily project check-ins
E) 📝 **Custom Schedule** - You tell me what works

What feels sustainable and motivating for you?

[Set up appropriate project review cadence]
```

**Step 18: Launch Planning**

```
**Question 17:** When and how do you want to launch this project?

Consider:
• When will you start the first next action?
• Do you need to block time on your calendar?
• Are there any preparations needed before you begin?
• Should we schedule your first project review?
• Any announcements or communications needed?

Let's plan your project launch!

[Plan project initiation]
```

### Phase 11: Final Integration & Summary

**Step 19: GTD System Integration**

```
I'm now integrating everything into your GTD system:

✅ **Project Created:** [Project name] with full details
✅ **Tasks Created:** [X] next actions with proper contexts  
✅ **Milestones Set:** [X] key checkpoints identified
✅ **Review Schedule:** [Frequency] project reviews planned
✅ **Resources Noted:** Requirements documented in project notes

**Your Next Actions:**
[List immediate next actions with contexts]

**Upcoming Milestones:**
[List next 2-3 milestones with target dates]
```

**Step 20: Success Celebration & Commitment**

```
**🎉 Congratulations! You've completed comprehensive project planning!**

**Final Question:** On a scale of 1-10, how clear and confident do you feel about this project now?

If less than 8, what would make you feel more confident?

**Your Project at a Glance:**
• **Purpose:** [Purpose statement]
• **Vision:** [Success vision]  
• **Next Action:** [First next action]
• **Timeline:** [Overall timeline]
• **First Milestone:** [First milestone and date]

**Project Review scheduled for:** [Date and time]

You're ready to make this vision a reality! 🚀
```

## Advanced Features

### Dynamic Questioning

Adapt questions based on project type:
- **Creative projects:** More emphasis on exploration and iteration
- **Technical projects:** More focus on dependencies and resources  
- **Team projects:** More stakeholder and communication planning
- **Personal projects:** More motivation and habit integration

### GTD Integration Points

- **Seamless task creation** with proper contexts and projects
- **Calendar integration** for milestone dates and reviews
- **Reference material** capture and organization  
- **Waiting-for** tracking for dependencies on others
- **Someday/maybe** parking for future project ideas

### Progress Tracking

- **Milestone celebrations** when achieved
- **Regular project health checks** during reviews
- **Adjustment guidance** when plans change
- **Completion ceremonies** when projects finish

## Benefits

✅ **Comprehensive Planning:** Nothing gets missed with systematic approach  
✅ **Clear Next Actions:** Always know what to do next  
✅ **Realistic Timelines:** Proper estimation with risk buffers  
✅ **GTD Integration:** Seamlessly fits existing workflow  
✅ **Engaging Process:** Interactive format keeps you motivated  
✅ **Flexible Adaptation:** Works for any project type or size  

This runbook transforms overwhelming projects into clear, manageable action plans that integrate perfectly with your GTD system!