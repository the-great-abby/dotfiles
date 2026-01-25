# Runbooks Guide

## What Are Runbooks?

**Runbooks** are structured, step-by-step procedures that guide the AI system through specific processes. They're similar to Agent Skills but with a focus on:

- ✅ **Structured steps** - Clear, numbered steps that must be followed in order
- ✅ **Validation** - Each step has expected outputs and validation criteria
- ✅ **Error handling** - What to do if a step fails
- ✅ **Completeness** - Ensures all steps are completed
- ✅ **Repeatability** - Same process every time

## Runbooks vs Skills

| Feature | Runbooks | Skills |
|---------|----------|--------|
| **Structure** | Strict step-by-step | Flexible instructions |
| **Validation** | Required at each step | Optional |
| **Error Handling** | Explicit error paths | General guidance |
| **Completeness** | Must complete all steps | Can adapt/abort |
| **Use Case** | Critical processes | General workflows |

**Example:**
- **Runbook**: "Daily Log Review" - Must follow all 7 steps, validate each step
- **Skill**: "Morning Check-In" - Flexible workflow, can adapt based on context

## Creating a Runbook

### 1. Create Runbook Directory

```bash
mkdir -p mcp/skills/your-runbook-name
cd mcp/skills/your-runbook-name
```

### 2. Create SKILL.md with Runbook Structure

```markdown
---
name: Your Runbook Name
description: What this runbook does
version: 1.0.0
type: runbook  # <-- Mark as runbook
tags:
  - runbook
  - your-category
---

# Your Runbook Name

## Purpose

Clear statement of what this runbook accomplishes.

## Prerequisites

- What's needed before starting
- Required tools/data
- Pre-conditions

## Runbook Steps

### Step 1: [Step Name]

**Action:** What tool to call or action to take

**Expected Output:** What you should get back

**Validation:**
- ✅ Success criteria
- ❌ Failure criteria

**Next Step:** What to do next (or "Complete runbook")

---

### Step 2: [Step Name]

[Repeat structure...]

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Step 1 completed
2. ✅ Step 2 completed
...

**Success Criteria:**
- All steps completed
- All validations passed
- User has clear next steps

## Error Handling

**If [condition]:**
- What to do
- How to recover
- When to abort

## Usage

How to invoke this runbook:
- "Use the [name] runbook"
- "Follow the [name] runbook"
- "Run the [name] runbook"
```

## Example Runbooks

### Daily Log Review Runbook

Located at: `mcp/skills/daily-log-review-runbook/SKILL.md`

**Steps:**
1. Load daily log data
2. Analyze log structure
3. Cross-reference with GTD system
4. Identify action items
5. Pattern analysis
6. Generate insights
7. Suggest actions

**Usage:**
```
"Review my daily log using the runbook"
"Follow the daily log review runbook"
```

## Using Runbooks

### In Claude Ask TUI

Ask Claude to use a runbook:

```
"Review my daily log using the runbook"
"Follow the daily log review runbook for today"
"Use the runbook to check my daily log"
```

Claude will:
1. Call `get_agent_skill(skill_name="daily-log-review-runbook")`
2. Read the runbook instructions
3. Follow each step in sequence
4. Validate each step
5. Complete all steps

### In Cursor IDE

Runbooks work the same as skills:

```
"Use the daily log review runbook"
"Follow the runbook to review my log"
```

## Best Practices

### 1. Clear Step Structure

Each step should have:
- **Action** - What to do
- **Expected Output** - What you'll get
- **Validation** - How to verify success
- **Next Step** - What comes next

### 2. Error Handling

Always include:
- What to do if a step fails
- When to continue vs. abort
- How to recover from errors

### 3. Validation

Every step should validate:
- ✅ Data was retrieved correctly
- ✅ Expected format received
- ✅ No errors occurred

### 4. Completeness

Runbooks should:
- Complete all steps (don't skip)
- Provide final summary
- List all actions taken
- Show success/failure status

### 5. Integration

Runbooks can:
- Use Sequential Thinking for complex analysis
- Call other runbooks as sub-processes
- Integrate with GTD tools
- Combine multiple data sources

## Creating Your First Runbook

### Example: Task Review Runbook

```markdown
---
name: Task Review Runbook
type: runbook
tags: [runbook, tasks, review]
---

# Task Review Runbook

## Purpose
Systematically review all active tasks, identify priorities, and suggest actions.

## Runbook Steps

### Step 1: Load Tasks

**Action:** Call `gtd_list_tasks(status='active')`

**Expected Output:** List of active tasks with details

**Validation:**
- ✅ Tasks returned (even if empty list)
- ❌ Error returned

**Next Step:** Proceed to Step 2

---

### Step 2: Analyze Task Status

**Action:** Review each task for:
- Priority level
- Due dates
- Context
- Energy requirements
- Project association

**Output Format:**
```
Task Analysis:
- High Priority: [count]
- Due Soon: [count]
- By Context: [breakdown]
- By Energy: [breakdown]
```

**Next Step:** Proceed to Step 3

---

### Step 3: Identify Actions

**Action:** Suggest specific actions:
- Tasks to prioritize
- Tasks to defer
- Tasks to break down
- Tasks to complete

**Next Step:** Complete runbook

---

## Runbook Completion

**Final Output:**
- ✅ Tasks loaded and analyzed
- ✅ Priorities identified
- ✅ Actions suggested

**Success Criteria:**
- All tasks reviewed
- Clear priorities established
- Actionable recommendations provided
```

## Runbook Categories

You can organize runbooks by category:

- **Review Runbooks**: Daily log review, task review, project review
- **Processing Runbooks**: Inbox processing, task creation, project setup
- **Analysis Runbooks**: Pattern analysis, energy analysis, productivity analysis
- **Planning Runbooks**: Weekly planning, project planning, goal planning

## Integration with Sequential Thinking

Runbooks work great with Sequential Thinking for complex analysis:

```markdown
### Step 5: Complex Analysis

**Action:** Use Sequential Thinking for pattern analysis
1. Call `create_thoughts(thought="Analyzing energy patterns...")`
2. Continue with structured thoughts
3. Call `summarize_thoughts()` for final analysis

**Expected Output:** Structured analysis of patterns

**Validation:**
- ✅ Thoughts created and analyzed
- ✅ Summary generated
```

## Tips for Effective Runbooks

1. **Start Simple** - Begin with basic steps, add complexity later
2. **Test Thoroughly** - Run the runbook yourself to verify it works
3. **Document Assumptions** - Note what data/tools are expected
4. **Handle Edge Cases** - What if data is empty? Missing? Invalid?
5. **Provide Examples** - Show expected inputs/outputs
6. **Make It Repeatable** - Should work the same way every time

## Next Steps

1. ✅ Review the example: `mcp/skills/daily-log-review-runbook/SKILL.md`
2. ✅ Create your own runbook for a process you use often
3. ✅ Test it by asking Claude to use it
4. ✅ Refine based on results

Runbooks make processes consistent, reliable, and easy to follow!
