---
name: Inbox Processing
description: Systematic GTD inbox processing workflow using the 2-minute rule and decision framework. Processes inbox items into tasks, projects, reference, or trash.
version: 1.0.0
tags:
  - inbox
  - processing
  - gtd
  - workflow
  - productivity
author: GTD System
---

# Inbox Processing Workflow

A systematic approach to processing inbox items following GTD methodology. Empty your inbox by making clear decisions on each item and moving it to the appropriate place in your system.

## When to Use

Use this skill whenever you have items in your inbox:
- **Regularly:** As part of daily review or check-in
- **When inbox fills:** Process before it becomes overwhelming
- **Transition times:** Between activities, end of day
- **Dedicated time:** Schedule 15-30 minute inbox processing sessions

**GTD Principle:** Inbox is a collection point, not a storage place. Process it regularly to maintain system clarity.

---

## How It Works

This workflow processes each inbox item using GTD's decision tree, applying the 2-minute rule, and using MCP tools to create tasks, projects, or file items appropriately.

### Step 1: Assess Inbox Status

**Purpose:** Understand what needs processing.

**Actions:**
1. Call `get_inbox_count()` to see how many items are in the inbox
2. If count = 0: ✓ Inbox is clear, you're done!
3. If count > 0: Continue to processing steps

**Inbox size guidelines:**
- **0-5 items:** Quick processing (< 5 minutes)
- **6-20 items:** Standard processing (10-20 minutes)
- **21+ items:** Schedule dedicated time (30+ minutes) or process in batches

---

### Step 2: Process Each Item (One at a Time)

**Purpose:** Make a clear decision on each inbox item.

**For each inbox item, follow this decision tree:**

#### Decision 1: Is It Actionable?

**Question:** Does this require any action from me?

**If NO (Not Actionable):**
- **Trash:** Delete it if it's not useful
- **Reference:** File it if it's information you might need later
  - Use reference filing system
  - No action needed, just organized storage
- **Someday/Maybe:** Interesting but not now
  - Add to someday/maybe list
  - Review during weekly review

**If YES (Actionable):**
- Continue to Decision 2

---

#### Decision 2: What's the Next Action?

**Question:** What's the very next physical action required?

**If multiple steps needed:**
- It's a **Project** → Go to Project Processing
- Projects are outcomes that require multiple actions
- Example: "Plan vacation" = project (need to research, book, pack, etc.)

**If single action:**
- It's a **Task** → Go to Task Processing
- Next action is clear and single
- Example: "Email John about meeting" = task (action: send email)

---

#### Decision 3: Can It Be Done in 2 Minutes?

**Question:** Will completing this action take less than 2 minutes?

**If YES (2-Minute Rule):**
- **Do it now!** Don't create a task, just complete it
- Clear it from inbox
- Mark as done or delete
- GTD principle: If it takes less time to do than to track, do it now

**If NO (Takes > 2 minutes):**
- Continue to Decision 4

---

#### Decision 4: Should I Delegate It?

**Question:** Is this something someone else should or could do?

**If YES (Delegate):**
- Delegate to appropriate person
- Create a waiting-for item (track that you're waiting for response)
- Set follow-up date if needed
- Move original to waiting-for or reference

**If NO (I should do it):**
- Continue to Task or Project creation

---

### Step 3: Create Task (If Single Action)

**Purpose:** Convert actionable items into trackable tasks.

**When to create task:**
- Single, clear next action
- Takes > 2 minutes
- You're the one to do it (not delegating)

**Actions:**
1. Extract clear action from inbox item
   - Start with verb: "Email...", "Call...", "Research...", "Write..."
   - Be specific: "Email John about project timeline" not "John"
2. Determine context (where can you do this?):
   - `computer` - Requires computer/internet
   - `phone` - Phone call
   - `home` - At home
   - `office` - At office/work
   - `errands` - While out
3. Determine priority:
   - `urgent_important` - Do today
   - `not_urgent_important` - Important but not urgent
   - `urgent_not_important` - Urgent but less important
   - `not_urgent_not_important` - Low priority
4. Determine project (if applicable):
   - If task relates to a project, associate it
5. Use MCP tool to create task:
   ```
   create_task(
       title="<clear action>",
       context="<context>",
       priority="<priority>",
       project="<project_name>"  # optional
   )
   ```
6. Or use AI suggestions if item is ambiguous:
   ```
   suggest_tasks_from_text(
       text="<inbox item content>",
       context="inbox",
       mode="review"
   )
   ```
   Then create from suggestions if appropriate

**Task creation best practices:**
- Clear action verbs (avoid "think about", "consider")
- Specific enough to know what to do
- Include context and priority
- Link to project if applicable

---

### Step 4: Create Project (If Multiple Actions)

**Purpose:** Convert multi-step items into projects with next actions.

**When to create project:**
- Outcome requires multiple steps
- Not clear single next action
- Will take time to complete

**Actions:**
1. Identify the outcome/result (project goal):
   - What does "done" look like?
   - Example: "Plan vacation" → outcome: booked trip with itinerary
2. Use MCP tool to create project:
   ```
   create_project(
       name="<project_name>",
       description="<desired outcome>",
       area="<area>"  # optional
   )
   ```
3. Identify the next action (first step):
   - What's the very first thing to do?
   - Example: "Research vacation destinations"
4. Create task for next action:
   ```
   create_task(
       title="<next action>",
       project="<project_name>",
       context="<context>",
       priority="<priority>"
   )
   ```
5. Optional: Use AI for project planning:
   ```
   plan_with_ai(
       plan_type="project",
       item_name="<project_name>",
       item_context="<description>"
   )
   ```

**Project creation best practices:**
- Name reflects outcome, not activity
- Define what "done" looks like
- Always have a next action task
- Associate with area if applicable

---

### Step 5: Process Reference Items

**Purpose:** File information for future use.

**When to file as reference:**
- Not actionable
- Might be useful later
- Information to keep organized

**Actions:**
1. Determine appropriate reference category/location
2. File in reference system (outside GTD system typically)
3. If it's project-related reference, add to project folder
4. Remove from inbox (it's processed)

**Note:** Reference items don't go in your task system - they're just filed information.

---

### Step 6: Handle Someday/Maybe Items

**Purpose:** Capture ideas for later consideration.

**When to add to someday/maybe:**
- Interesting but not actionable now
- Not a current priority
- Want to remember but not commit to now

**Actions:**
1. Add to someday/maybe list or file
2. Review during weekly review
3. Can activate later if it becomes relevant
4. Remove from inbox (it's processed)

**GTD Principle:** Someday/Maybe keeps your system clean while preserving ideas.

---

### Step 7: Confirm Inbox is Empty

**Purpose:** Verify all items have been processed.

**Actions:**
1. Call `get_inbox_count()` again
2. If count = 0: ✓ Success! Inbox is processed
3. If count > 0: Review remaining items
   - Sometimes items need more time to process
   - That's okay - process what you can, schedule more time if needed

---

## Decision Tree Summary

```
Is it actionable?
│
├─ NO → Is it useful?
│   ├─ Yes → File as Reference
│   └─ No → Trash
│
└─ YES → What's the next action?
    │
    ├─ Multiple steps? → Create Project + Next Action Task
    │
    └─ Single action? → Can it be done in 2 minutes?
        │
        ├─ YES → Do it now!
        │
        └─ NO → Should I delegate?
            │
            ├─ YES → Delegate + Create Waiting-For
            │
            └─ NO → Create Task
```

---

## Best Practices

### Processing Discipline
- **One item at a time:** Don't skip around
- **Make decisions:** Don't leave items "for later"
- **Be ruthless:** If you won't do it, delete it
- **Stay focused:** Process entire inbox in one session when possible

### 2-Minute Rule
- **Real 2 minutes:** Don't underestimate time
- **Do it now:** If < 2 minutes, don't track it
- **Stick to it:** Prevents procrastination on small items
- **Exceptions:** Only skip if truly inappropriate time/place

### Task Clarity
- **Action verbs:** Start with "Email", "Call", "Research"
- **Be specific:** "Email John about project timeline" not "John"
- **Clear context:** Where can you actually do this?
- **Right priority:** Don't over-prioritize

### Project Definition
- **Outcome-focused:** What does "done" look like?
- **Always have next action:** Every project needs a next task
- **Name clearly:** Project name should indicate desired result

### Batch Processing
- **Process regularly:** Daily is ideal
- **Dedicated time:** Schedule 15-30 minutes if needed
- **Don't rush:** Better to take time than make poor decisions
- **Empty inbox:** Goal is zero items

---

## Common Patterns

### Email Inbox Items
- Email about meeting → Task: "RSVP to meeting invite"
- Email with information → Reference (file or delete)
- Email with request → Task or Project (depending on complexity)

### Meeting Notes
- Action item for me → Task
- Action item for others → Waiting-for
- Information → Reference
- Idea for later → Someday/Maybe

### Random Thoughts
- "I should..." → Task or Someday/Maybe
- Reminder → Task with defer date
- Idea → Someday/Maybe or Project if actionable

### Physical Items
- Mail to handle → Task
- Receipts → Reference (file)
- Things to read → Task: "Read [item]" or Someday/Maybe

---

## Integration with Other Skills

This skill is used by:
- **`morning-checkin`**: Processes inbox as part of morning routine
- **`daily-review`**: Processes inbox as first step of review
- **`evening-checkin`**: Processes inbox before wrapping up day

This skill uses:
- **`suggest_tasks_from_text`**: For unclear items that need AI help
- **`create_task`**: To create tasks from items
- **`create_project`**: To create projects from items
- **`plan_with_ai`**: For complex items that need planning help

---

## Troubleshooting

### "I have too many items to process"
- Process in batches (do 10, take break)
- Schedule dedicated processing time
- Set goal: reduce by X items per session
- Process more frequently to prevent buildup

### "I don't know what to do with an item"
- If unsure, use `suggest_tasks_from_text()` for AI help
- If still unclear, move to someday/maybe
- Better to defer decision than make bad one
- Review in weekly review for clarity

### "Items keep coming back"
- Ensure you're making clear decisions
- If recurring, create a task to handle it permanently
- If reference, file it properly
- If someday/maybe, review weekly to decide

### "2-minute rule is taking too long"
- Be honest about timing
- If > 2 minutes, create a task
- Group small tasks for dedicated time
- Use rule as guide, not absolute

### "I'm creating too many tasks"
- Use 2-minute rule more consistently
- Be selective about what you commit to
- Use someday/maybe for less urgent items
- Defer tasks appropriately

---

## Success Criteria

Inbox processing is successful when:
- ✓ Inbox count is 0 (or very low, < 3 items)
- ✓ All items have clear decisions made
- ✓ Tasks are created with clear actions
- ✓ Projects have next actions defined
- ✓ System feels organized and trusted
- ✓ Nothing important was missed

**Remember:** Empty inbox = clear mind. The goal is to trust your system completely, knowing nothing important is forgotten and everything has a place.
