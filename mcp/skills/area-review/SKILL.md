---
name: Area Review
description: Reviews specific areas of responsibility, assesses area health, identifies improvements, and ensures all areas get appropriate attention. Maintains balance across life areas.
version: 1.0.0
tags:
  - areas
  - review
  - balance
  - responsibility
  - maintenance
author: GTD System
---

# Area Review Workflow

A comprehensive skill for reviewing areas of responsibility, assessing their health, identifying improvements, and ensuring all areas get appropriate attention.

## When to Use

Use this skill when you need to:
- **Review specific area**: Deep dive into one area
- **Review all areas**: Comprehensive area audit
- **Monthly area review**: Part of monthly review
- **Area health check**: Assess if area needs attention
- **Balance assessment**: Ensure all areas get attention

## How It Works

This workflow reviews areas systematically, checking relevance, status, related projects/tasks, and identifying improvements.

## Step-by-Step Workflow

### Step 1: List All Areas

**Purpose:** Get overview of all areas.

**Actions:**
1. List all areas:
   ```python
   list_areas()
   ```
2. Review area list:
   - Total number of areas
   - Area names
   - Area status (active/on-hold/archived)

**MCP Tools:**
- `list_areas()` - Get all areas

**What to note:**
- How many areas you have
- Which areas are active
- Which areas might need review

---

### Step 2: Select Area(s) to Review

**Purpose:** Choose which area(s) to focus on.

**Actions:**
1. **Option A: Review all areas**
   - Review each area systematically
   - Best for monthly/quarterly review

2. **Option B: Review specific area**
   - Focus on one area needing attention
   - Best for targeted review

3. **Option C: Review struggling areas**
   - Focus on areas that need improvement
   - Best for problem-solving

**Questions to ask:**
- Which areas haven't been reviewed recently?
- Which areas are struggling?
- Which areas need attention?

---

### Step 3: Review Area Relevance

**Purpose:** Ensure area is still relevant.

**Actions:**
1. For each area, ask:
   - Is this area still relevant to my life?
   - Does it need regular attention?
   - Has my life changed in ways that affect this?
   - Should it be archived or merged?

**Questions to ask:**
- Does this area still matter?
- Is it something I need to maintain?
- Has my life changed?
- Should it be archived?

**Decisions:**
- **Keep active**: Still relevant, needs attention
- **Archive**: No longer relevant
- **Merge**: Overlaps with another area
- **On hold**: Temporarily not active

---

### Step 4: Review Area Status

**Purpose:** Check current area health.

**Actions:**
1. Review area details:
   - Current status (active/on-hold/archived)
   - Last review date
   - Standards defined
   - Goals set
2. Assess:
   - Is status appropriate?
   - When was last review?
   - Are standards clear?

**What to check:**
- Status accuracy
- Review frequency
- Standards clarity
- Goals alignment

---

### Step 5: Review Related Projects

**Purpose:** See what projects support this area.

**Actions:**
1. List projects in this area:
   ```python
   list_projects()  # Filter by area if possible
   ```
2. For each project:
   - Get project status: `get_project_status(project_name)`
   - Check if project supports area
   - Assess project health
   - Identify gaps

**MCP Tools:**
- `list_projects()` - All projects (filter by area)
- `get_project_status(project_name)` - Project details

**Questions to ask:**
- Are there enough projects in this area?
- Are projects making progress?
- Are there gaps that need projects?
- Should any projects be created?

---

### Step 6: Review Related Tasks

**Purpose:** See what tasks support this area.

**Actions:**
1. List tasks in this area:
   ```python
   list_tasks()  # Filter by area if possible
   ```
2. Review tasks:
   - Active tasks
   - Completed tasks
   - Task distribution
   - Task priorities

**MCP Tools:**
- `list_tasks()` - All tasks (filter by area)

**Questions to ask:**
- Are there enough tasks in this area?
- Are tasks aligned with area goals?
- Are priorities appropriate?
- Should any tasks be created?

---

### Step 7: Assess Standards

**Purpose:** Check if area standards are being met.

**Actions:**
1. Review area standards:
   - What are the standards for this area?
   - Are they being met?
   - Do standards need adjustment?
2. Assess:
   - Current performance vs. standards
   - Gaps in meeting standards
   - Standards that need updating

**Questions to ask:**
- What are my standards for this area?
- Am I meeting these standards?
- Are standards too high or too low?
- Should standards be adjusted?

**Standards examples:**
- Health: Exercise 3x/week, sleep 7+ hours
- Finances: Save 20% of income, track expenses
- Relationships: Weekly date night, monthly family time

---

### Step 8: Identify Improvements

**Purpose:** Find ways to improve area.

**Actions:**
1. Identify gaps:
   - What's missing?
   - What needs attention?
   - What's not working?
2. Identify opportunities:
   - What could be better?
   - What should be added?
   - What should be changed?

**Improvement categories:**
- **Projects**: New projects needed
- **Tasks**: Tasks to create
- **Standards**: Standards to adjust
- **Systems**: Systems to improve
- **Resources**: Resources needed

---

### Step 9: Create Action Items

**Purpose:** Turn improvements into actions.

**Actions:**
1. For each improvement:
   - Create project if major
   - Create task if minor
   - Update standards if needed
   - Set goals if appropriate

**MCP Tools:**
- `create_project(name="...", description="...")` - New area project
- `create_task(title="...", project="...", priority="...")` - Area task

**Action item types:**
- **Projects**: Major improvements
- **Tasks**: Quick improvements
- **Standards**: Update standards
- **Goals**: Set area goals

---

### Step 10: Review Area Balance

**Purpose:** Ensure all areas get attention.

**Actions:**
1. Review attention across areas:
   - Which areas get most attention?
   - Which areas are neglected?
   - Is balance appropriate?
2. Adjust if needed:
   - Add projects to neglected areas
   - Create tasks for overlooked areas
   - Rebalance priorities

**Balance questions:**
- Are all areas getting attention?
- Are some areas over-focused?
- Are some areas neglected?
- Is balance appropriate for current life stage?

---

### Step 11: Update Area Status

**Purpose:** Keep area status current.

**Actions:**
1. Update area status if needed:
   - Mark as active if relevant
   - Archive if no longer relevant
   - Put on hold if temporarily inactive
2. Update review date
3. Update standards if changed

**Status options:**
- **Active**: Currently relevant and maintained
- **On Hold**: Temporarily not active
- **Archived**: No longer relevant

---

### Step 12: Document Review

**Purpose:** Record review insights.

**Actions:**
1. Document review findings:
   - Area status
   - Standards assessment
   - Improvements identified
   - Action items created
   - Next review date
2. Log to daily log or create note

**What to document:**
- Review date
- Area status
- Standards met/not met
- Improvements needed
- Action items
- Next review date

---

## Detailed Workflow Examples

### Example 1: Review Single Area

**Scenario:** Review "Health & Wellness" area.

**Steps:**
1. **List areas:**
   ```python
   list_areas()
   ```
   - Found "Health & Wellness" area

2. **Review relevance:**
   - Still relevant? ✅ Yes
   - Needs attention? ✅ Yes
   - Status: Active

3. **Review projects:**
   ```python
   list_projects()  # Filter by area
   ```
   - Found 2 projects: "Fitness Routine", "Nutrition Plan"
   - Both making progress ✅

4. **Review tasks:**
   ```python
   list_tasks()  # Filter by area
   ```
   - Found 5 active tasks
   - All aligned with area goals ✅

5. **Assess standards:**
   - Standard: Exercise 3x/week
   - Current: 2x/week ❌
   - Gap identified

6. **Create action items:**
   ```python
   create_task(
       title="Schedule third weekly workout",
       priority="not_urgent_important",
       notes="Health & Wellness area - meet exercise standard"
   )
   ```

### Example 2: Review All Areas

**Scenario:** Monthly comprehensive area review.

**Steps:**
1. **List all areas:**
   ```python
   list_areas()
   ```
   - Found 8 areas

2. **Review each area systematically:**
   - Health & Wellness: ✅ Good
   - Finances: ⚠️ Needs attention
   - Work & Career: ✅ Good
   - Relationships: ✅ Good
   - Personal Development: ⚠️ Needs attention
   - Home & Living: ✅ Good
   - Hobbies & Interests: ✅ Good
   - Community: ❌ Neglected

3. **Focus on struggling areas:**
   - Finances: Create budget project
   - Personal Development: Add learning tasks
   - Community: Create engagement project

4. **Review balance:**
   - Most attention: Work & Career
   - Least attention: Community
   - Rebalance needed

5. **Create action items:**
   - Projects for neglected areas
   - Tasks for improvements
   - Standards updates

---

## Best Practices

### Review Frequency

**Regular reviews:**
- **Weekly**: Quick check (5-10 min)
- **Monthly**: Comprehensive review (30-45 min)
- **Quarterly**: Major audit (1-2 hours)

**When to review:**
- Part of weekly review
- Part of monthly review
- When area struggles
- When life changes

### Review Depth

**Be thorough:**
- Review all aspects
- Check projects and tasks
- Assess standards
- Identify improvements

**Be honest:**
- Acknowledge gaps
- Don't make excuses
- Focus on improvement
- Set realistic standards

### Area Balance

**Maintain balance:**
- All areas get attention
- No area completely neglected
- Adjust for life stage
- Prioritize appropriately

**Balance questions:**
- Are all areas represented?
- Is balance appropriate?
- Should priorities shift?
- Are some areas over-focused?

### Standards Setting

**Set realistic standards:**
- Not too high (unattainable)
- Not too low (no challenge)
- Specific and measurable
- Aligned with values

**Review standards:**
- Are they being met?
- Do they need adjustment?
- Are they still relevant?
- Should they be updated?

---

## Integration with Other Skills

This skill works well with:
- **`monthly-review`**: Area review is part of monthly review
- **`weekly-review`**: Quick area check in weekly review
- **`project-status-review`**: Review area projects
- **`task-prioritization`**: Prioritize area tasks

---

## Troubleshooting

### "I have too many areas"

**Solutions:**
- Merge overlapping areas
- Archive inactive areas
- Focus on 5-8 core areas
- Review and consolidate

### "Some areas are always neglected"

**Solutions:**
- Schedule dedicated time
- Create projects for neglected areas
- Set minimum standards
- Review balance regularly

### "I don't know what standards to set"

**Solutions:**
- Start with basic standards
- Adjust based on experience
- Look at what works for others
- Focus on what matters to you

### "Areas feel overwhelming"

**Solutions:**
- Reduce number of areas
- Simplify standards
- Focus on essentials
- Review one area at a time

---

## Success Criteria

Successful area review:
- ✓ All areas reviewed
- ✓ Relevance assessed
- ✓ Status updated
- ✓ Projects reviewed
- ✓ Tasks reviewed
- ✓ Standards assessed
- ✓ Improvements identified
- ✓ Action items created
- ✓ Balance checked
- ✓ Review documented

---

## Commands Reference

### Area Management
```python
# List all areas
list_areas()
```

### Project Management
```python
# List projects (filter by area)
list_projects()

# Get project status
get_project_status(project_name)
```

### Task Management
```python
# List tasks (filter by area)
list_tasks()

# Create area task
create_task(title="...", priority="...", notes="Area: ...")
```

### Project Creation
```python
# Create area project
create_project(name="...", description="...")
```

---

## Workflow Summary

```
Area Review Workflow
│
├─ 1. List All Areas
│   └─ list_areas()
│
├─ 2. Select Area(s) to Review
│   └─ All, specific, or struggling areas
│
├─ 3. Review Area Relevance
│   └─ Is it still relevant?
│
├─ 4. Review Area Status
│   └─ Check current status
│
├─ 5. Review Related Projects
│   ├─ list_projects()
│   └─ get_project_status()
│
├─ 6. Review Related Tasks
│   └─ list_tasks()
│
├─ 7. Assess Standards
│   └─ Are standards being met?
│
├─ 8. Identify Improvements
│   └─ What needs attention?
│
├─ 9. Create Action Items
│   ├─ create_project()
│   └─ create_task()
│
├─ 10. Review Area Balance
│   └─ Are all areas getting attention?
│
├─ 11. Update Area Status
│   └─ Keep status current
│
└─ 12. Document Review
    └─ Record insights
```

---

Remember: Areas of responsibility represent the ongoing aspects of your life that need regular attention. Regular review ensures all areas stay relevant, get attention, and maintain appropriate standards. Balance across areas leads to a more fulfilling life.
