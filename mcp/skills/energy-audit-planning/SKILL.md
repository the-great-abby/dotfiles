---
name: Energy Audit & Planning
description: Analyze energy patterns, identify drains and boosts, and plan your schedule to match tasks to energy levels. Optimizes productivity by working with your natural energy rhythms.
version: 1.0.0
tags:
  - energy
  - productivity
  - planning
  - optimization
  - health
author: GTD System
---

# Energy Audit & Planning Workflow

A comprehensive skill for understanding your energy patterns, identifying what drains vs. energizes you, and planning your schedule to optimize productivity by matching tasks to energy levels.

## When to Use

Use this skill when you need to:
- **Understand energy patterns**: Learn when you have high/low energy
- **Identify energy drains**: Find what depletes your energy
- **Identify energy boosts**: Find what energizes you
- **Optimize schedule**: Match tasks to energy levels
- **Plan your day**: Schedule work based on energy
- **Improve productivity**: Work with your natural rhythms

## How It Works

This workflow uses energy tracking, analysis, and planning to help you work with your natural energy patterns rather than against them.

## Step-by-Step Workflow

### Step 1: Log Energy Impacts

**Purpose:** Track what affects your energy throughout the day.

**Actions:**
1. **Log energy drains:**
   ```bash
   gtd-energy-audit log "Activity" drain -3 "Note"
   ```
   - Activities that deplete energy
   - Impact: -5 (severe) to -1 (mild)

2. **Log energy boosts:**
   ```bash
   gtd-energy-audit log "Activity" boost +3 "Note"
   ```
   - Activities that increase energy
   - Impact: +1 (mild) to +5 (major)

3. **Log consistently:**
   - After significant activities
   - When you notice energy changes
   - At end of day (review)

**Commands:**
- `gtd-energy-audit log "Activity" drain -3 "Note"`
- `gtd-energy-audit log "Activity" boost +3 "Note"`

**What to log:**
- **Drains:** Meetings, difficult conversations, tedious tasks, interruptions
- **Boosts:** Exercise, creative work, social time, accomplishments, breaks

**Impact scale:**
- **-5 to -3**: Major drain (exhausting)
- **-2 to -1**: Mild drain (tiring)
- **+1 to +2**: Mild boost (refreshing)
- **+3 to +5**: Major boost (energizing)

---

### Step 2: Analyze Energy Patterns

**Purpose:** Understand your energy patterns over time.

**Actions:**
1. **Analyze energy data:**
   ```bash
   gtd-energy-audit analyze
   ```
2. **Review patterns:**
   - What activities drain you most?
   - What activities boost you most?
   - When do you have high/low energy?
   - What patterns do you notice?

3. **Request deep analysis:**
   - Use `analyze_energy(days=7)` for weekly patterns
   - Use `analyze_energy(days=30)` for monthly patterns

**Commands:**
- `gtd-energy-audit analyze` - Analyze energy patterns
- `analyze_energy(days=7)` - Deep analysis (MCP tool)

**MCP Tools:**
- `analyze_energy(days=7)` - Comprehensive energy analysis (deep analysis)

**What to look for:**
- Time of day patterns (morning person vs. evening person)
- Activity patterns (what consistently drains/boosts)
- Day of week patterns (Mondays vs. Fridays)
- Recovery patterns (how long to recover from drains)

---

### Step 3: Identify Energy Drains

**Purpose:** Find what consistently depletes your energy.

**Actions:**
1. Review analysis results for top drains
2. For each major drain:
   - Can it be eliminated?
   - Can it be reduced?
   - Can it be scheduled differently?
   - Can it be delegated?
3. Create plan to minimize drains

**Questions to ask:**
- What activities drain me most?
- Can I eliminate or reduce these?
- When do these happen? (Can I schedule differently?)
- How can I recover from drains?

**Strategies:**
- **Eliminate:** Remove unnecessary drains
- **Reduce:** Minimize frequency or duration
- **Schedule:** Put drains in low-energy times
- **Recover:** Plan recovery activities after drains

---

### Step 4: Identify Energy Boosts

**Purpose:** Find what consistently energizes you.

**Actions:**
1. Review analysis results for top boosts
2. For each major boost:
   - Can I do more of this?
   - Can I schedule this strategically?
   - Can I use this to recover from drains?
3. Create plan to maximize boosts

**Questions to ask:**
- What activities boost me most?
- How can I do more of these?
- When should I schedule these?
- How can I use boosts strategically?

**Strategies:**
- **Increase:** Do more boosting activities
- **Schedule:** Put boosts in low-energy times
- **Recovery:** Use boosts to recover from drains
- **Prevention:** Use boosts to prevent energy drops

---

### Step 5: Understand Energy Patterns by Time

**Purpose:** Learn when you have high/low energy.

**Actions:**
1. Review energy patterns by time of day
2. Identify:
   - Peak energy times (high energy)
   - Low energy times
   - Energy transitions
3. Note patterns:
   - Morning person vs. evening person
   - Post-lunch dip
   - Evening energy levels

**MCP Tools:**
- `analyze_energy(days=7)` - Shows time-based patterns
- `gtd-energy-schedule` - Uses learned patterns

**Common patterns:**
- **Morning peak:** High energy 6am-10am
- **Midday dip:** Lower energy 2pm-4pm
- **Evening:** Varies by person
- **Night:** Typically low energy

---

### Step 6: Match Tasks to Energy Levels

**Purpose:** Schedule tasks when you have matching energy.

**Actions:**
1. **Get tasks by energy requirement:**
   - `list_tasks(energy="high")` - High-energy tasks
   - `list_tasks(energy="medium")` - Medium-energy tasks
   - `list_tasks(energy="low")` - Low-energy tasks

2. **Match to energy patterns:**
   - High-energy tasks → Peak energy times
   - Medium-energy tasks → Medium energy times
   - Low-energy tasks → Low energy times

3. **Use energy-aware scheduling:**
   ```bash
   gtd-energy-schedule
   ```

**MCP Tools:**
- `list_tasks(energy="high")` - High-energy tasks
- `get_context_tasks(context="...", energy="...")` - Filter by context and energy
- `gtd-energy-schedule` - Energy-aware scheduling tool

**Best practices:**
- **Peak energy:** Deep work, creative tasks, important decisions
- **Medium energy:** Regular work, meetings, planning
- **Low energy:** Administrative tasks, email, routine work

---

### Step 7: Plan Day Based on Energy

**Purpose:** Create energy-optimized daily schedule.

**Actions:**
1. **Identify your energy pattern for today:**
   - Review typical pattern for this time/day
   - Adjust based on sleep, health, etc.
   - Note current energy level

2. **Schedule tasks by energy:**
   - Morning (if high energy): Important, high-energy tasks
   - Midday (if medium energy): Regular work, meetings
   - Afternoon (if low energy): Low-energy tasks, admin
   - Evening (varies): Match to your pattern

3. **Plan energy management:**
   - Schedule boosts after drains
   - Plan recovery time
   - Batch similar energy-level tasks

**MCP Tools:**
- `gtd-energy-schedule` - Creates energy-optimized schedule
- `get_context_tasks(context="...", energy="...")` - Get tasks for time/energy

**Schedule template:**
```
Morning (High Energy):
- [High-energy important task]
- [Creative work]
- [Deep thinking]

Midday (Medium Energy):
- [Regular work]
- [Meetings]
- [Planning]

Afternoon (Low Energy):
- [Admin tasks]
- [Email]
- [Routine work]

Evening (Varies):
- [Match to your pattern]
```

---

### Step 8: Track and Refine

**Purpose:** Continuously improve energy management.

**Actions:**
1. **Log energy impacts regularly:**
   - After significant activities
   - When you notice changes
   - End of day review

2. **Review patterns weekly:**
   - `gtd-energy-audit analyze` - Weekly review
   - `analyze_energy(days=7)` - Deep analysis

3. **Adjust schedule based on learnings:**
   - Move tasks to better times
   - Eliminate or reduce drains
   - Increase boosts
   - Refine energy matching

**Commands:**
- `gtd-energy-audit analyze` - Review patterns
- `gtd-energy-audit report 30` - Monthly report
- `analyze_energy(days=30)` - Monthly deep analysis

---

## Detailed Workflow Examples

### Example 1: Daily Energy Planning

**Scenario:** Planning your day with energy awareness.

**Steps:**
1. **Check current energy:** Note how you feel
2. **Review typical pattern:** Morning person, peak 8-11am
3. **Get tasks:**
   - `list_tasks(energy="high")` → 5 high-energy tasks
   - `list_tasks(energy="low")` → 8 low-energy tasks
4. **Schedule:**
   - 8-11am: High-energy important task
   - 11am-1pm: Medium-energy work
   - 2-4pm: Low-energy admin (post-lunch dip)
   - 4-6pm: Medium-energy tasks
5. **Plan boosts:** Exercise at 12pm, break at 3pm

### Example 2: Weekly Energy Audit

**Scenario:** Understanding your energy patterns.

**Steps:**
1. **Log impacts throughout week:**
   - `gtd-energy-audit log "Long meeting" drain -3`
   - `gtd-energy-audit log "Workout" boost +4`
2. **Analyze at end of week:**
   - `gtd-energy-audit analyze`
   - `analyze_energy(days=7)`
3. **Review patterns:**
   - Top drains: Meetings (-3.2 avg), Email (-2.1 avg)
   - Top boosts: Exercise (+4.1 avg), Creative work (+3.5 avg)
   - Peak energy: 8-11am weekdays
4. **Adjust schedule:**
   - Schedule important work 8-11am
   - Batch meetings in afternoon
   - Add exercise breaks

### Example 3: Energy Recovery Planning

**Scenario:** Recovering from energy drains.

**Steps:**
1. **Identify drain:** Long meeting drained energy (-4)
2. **Plan recovery:**
   - Schedule boost activity next
   - Use `gtd-energy-audit log "Walk" boost +2`
   - Take break before next task
3. **Match next task to energy:**
   - Current energy: Low (after drain)
   - Next task: Low-energy admin work
   - Schedule high-energy task later

---

## Best Practices

### Energy Logging

**Log consistently:**
- After significant activities
- When you notice energy changes
- End of day (quick review)
- Don't over-log (focus on significant impacts)

**Be honest:**
- Log actual impacts, not what you think they should be
- Note context (time, day, circumstances)
- Include notes for context

### Energy Analysis

**Review regularly:**
- Weekly: Quick review of patterns
- Monthly: Deep analysis of trends
- Quarterly: Major pattern review

**Look for patterns:**
- Time of day patterns
- Day of week patterns
- Activity patterns
- Recovery patterns

### Energy Planning

**Match tasks to energy:**
- High energy → High-energy tasks
- Low energy → Low-energy tasks
- Don't fight your energy
- Work with your patterns

**Schedule strategically:**
- Important work in peak times
- Drains in low-energy times (if possible)
- Boosts after drains
- Recovery time between drains

### Energy Management

**Minimize drains:**
- Eliminate unnecessary drains
- Reduce frequency or duration
- Schedule differently
- Delegate when possible

**Maximize boosts:**
- Do more boosting activities
- Schedule strategically
- Use for recovery
- Build into routine

---

## Integration with Other Skills

This skill works well with:
- **`task-prioritization`**: Match priorities to energy
- **`interactive-morning-review-runbook`**: Plan day based on energy
- **`evening-checkin`**: Review energy patterns
- **`weekly-review`**: Analyze energy patterns
- **`context-task-selection`**: Match tasks to energy and context

---

## Troubleshooting

### "I don't have energy patterns"

**Solutions:**
- Start logging consistently
- Patterns emerge over time (2-4 weeks)
- Use default patterns (morning peak, afternoon dip)
- Adjust as you learn

### "Everything drains my energy"

**Solutions:**
- Look for boosts you're missing
- Check sleep, health, stress
- May need recovery period
- Consider if burnout is an issue

### "I can't match tasks to energy"

**Solutions:**
- Start with obvious matches
- Adjust as you learn
- Some tasks can't be moved (meetings)
- Focus on what you can control

### "Energy patterns keep changing"

**Solutions:**
- This is normal (varies by day)
- Look for general patterns, not exact times
- Account for variables (sleep, stress, health)
- Use patterns as guide, not rule

---

## Success Criteria

Successful energy management:
- ✓ Energy impacts logged consistently
- ✓ Patterns identified (time, activities)
- ✓ Drains minimized
- ✓ Boosts maximized
- ✓ Tasks matched to energy levels
- ✓ Schedule optimized for energy
- ✓ Productivity improved

---

## Commands Reference

### Energy Logging
```bash
# Log energy drain
gtd-energy-audit log "Activity" drain -3 "Note"

# Log energy boost
gtd-energy-audit log "Activity" boost +3 "Note"
```

### Energy Analysis
```bash
# Analyze patterns
gtd-energy-audit analyze

# Generate report
gtd-energy-audit report 30

# Deep analysis (MCP tool)
analyze_energy(days=7)
```

### Energy-Aware Scheduling
```bash
# Get energy-optimized schedule
gtd-energy-schedule

# Get tasks by energy
list_tasks(energy="high")
get_context_tasks(context="computer", energy="high")
```

---

## Workflow Summary

```
Energy Audit & Planning Workflow
│
├─ 1. Log Energy Impacts
│   ├─ gtd-energy-audit log "Activity" drain -3
│   └─ gtd-energy-audit log "Activity" boost +3
│
├─ 2. Analyze Energy Patterns
│   ├─ gtd-energy-audit analyze
│   └─ analyze_energy(days=7)
│
├─ 3. Identify Energy Drains
│   └─ Find and minimize drains
│
├─ 4. Identify Energy Boosts
│   └─ Find and maximize boosts
│
├─ 5. Understand Energy Patterns by Time
│   └─ Learn peak/low energy times
│
├─ 6. Match Tasks to Energy Levels
│   ├─ list_tasks(energy="high")
│   └─ Schedule high-energy tasks in peak times
│
├─ 7. Plan Day Based on Energy
│   ├─ gtd-energy-schedule
│   └─ Match tasks to energy pattern
│
└─ 8. Track and Refine
    ├─ Log consistently
    ├─ Review weekly
    └─ Adjust schedule
```

---

Remember: Energy management is about working with your natural rhythms, not against them. Track what affects your energy, identify patterns, and schedule work to match your energy. This optimization can significantly improve productivity and well-being.
