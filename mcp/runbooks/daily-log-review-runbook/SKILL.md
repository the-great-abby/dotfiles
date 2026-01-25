---
name: Daily Log Review Runbook
description: Step-by-step runbook for reviewing daily logs. Provides a structured, repeatable process for analyzing daily activity, identifying patterns, and extracting actionable insights.
version: 1.0.0
type: runbook
tags:
  - runbook
  - daily-log
  - review
  - analysis
  - routine
author: GTD System
---

# Daily Log Review Runbook

A structured, step-by-step runbook for reviewing daily logs. This runbook ensures consistent, thorough analysis of daily activity.

## Purpose

This runbook guides the system through a complete daily log review process:
- Reading and understanding daily log entries
- Identifying patterns and themes
- Extracting actionable items
- Providing insights and recommendations

## Prerequisites

- Daily log file exists for the target date
- Access to GTD tools (gtd_read_daily_log, gtd_list_tasks, etc.)

## Runbook Steps

### Step 1: Load Daily Log Data

**Action:** Call `gtd_read_daily_log(date='today')` to get today's log entries.

**Expected Output:** Daily log content with timestamps, entries, and metadata.

**Validation:** 
- ✅ Log file exists and is readable
- ✅ Log contains entries (not empty)
- ❌ If empty or missing, note: "Log is empty or doesn't exist"

**If Daily Log is Missing or Empty:**
- 🎯 **Primary Recommendation:** "Would you like to start with the Interactive Morning Review Runbook? It guides you through questions to establish a daily logging routine."
- 📋 **Alternative Options:**
  - "Use the Daily Log Update runbook to add specific entries for today"
  - "Use the automated Morning Check-In Workflow for a quick system review"
- 💡 **Suggestion:** "The Interactive Morning Review asks thoughtful questions to help you reflect and plan, which naturally builds logging habits"
- 🔄 **Adaptation:** "I can help you review your tasks and projects instead, but daily logs provide richer insights"

**Next Step:** 
- If log has content → Proceed to Step 2
- If log is empty/missing → Offer Interactive Morning Review or daily-log-update runbooks
- User can choose to continue with available data or start logging routine

---

### Step 2: Analyze Log Structure

**Action:** Review the log structure to understand:
- Time blocks and activities
- Energy levels mentioned
- Priorities listed
- Goals mentioned
- Blockers identified
- Gratitude entries

**What to Extract:**
- Activities performed
- Tasks mentioned (but may not be in GTD system)
- Projects referenced
- Patterns (energy, focus areas, recurring themes)

**Output Format:**
```
Log Analysis:
- Activities: [list]
- Tasks mentioned: [list]
- Projects: [list]
- Energy patterns: [observations]
- Themes: [patterns]
```

**Next Step:** Proceed to Step 3.

---

### Step 3: Cross-Reference with GTD System

**Action:** Compare log entries with actual GTD system data.

**Actions:**
1. Call `gtd_list_tasks(status='active')` to see actual tasks
2. Call `gtd_list_projects(status='active')` to see actual projects
3. Compare log mentions with system data

**What to Identify:**
- ✅ Tasks mentioned in log AND in system (tracked)
- ⚠️ Tasks mentioned in log but NOT in system (should be created)
- ✅ Projects mentioned in log AND in system (tracked)
- ⚠️ Projects mentioned in log but NOT in system (should be created)
- ✅ Completed work mentioned in log (should be recorded)

**Output Format:**
```
Cross-Reference Results:
- Tracked items: [items in both log and system]
- Missing items: [items in log but not in system - ACTION NEEDED]
- Completed work: [work done but not recorded - ACTION NEEDED]
```

**Next Step:** Proceed to Step 4.

---

### Step 4: Identify Action Items

**Action:** Extract actionable items from the log.

**What to Look For:**
- Tasks mentioned but not created
- Projects referenced but not tracked
- Follow-up items needed
- Decisions made that need action
- Commitments mentioned

**Action Items Format:**
```
Action Items Found:
1. [Task/Project] - [Reason] - [Priority]
2. [Task/Project] - [Reason] - [Priority]
...
```

**Next Step:** Proceed to Step 5.

---

### Step 5: Pattern Analysis

**Action:** Identify patterns and trends.

**What to Analyze:**
- Energy levels throughout the day
- Focus areas (what got attention)
- Time allocation patterns
- Recurring themes or concerns
- Productivity patterns
- Work-life balance indicators

**Pattern Analysis Format:**
```
Patterns Identified:
- Energy: [observations]
- Focus: [main areas of attention]
- Time: [how time was spent]
- Themes: [recurring topics]
- Balance: [work/life observations]
```

**Next Step:** Proceed to Step 6.

---

### Step 6: Generate Insights

**Action:** Synthesize findings into actionable insights.

**What to Provide:**
- Key accomplishments
- Areas for improvement
- Recommendations
- Questions to consider
- Next steps

**Insights Format:**
```
Insights:
✅ Accomplishments: [what went well]
💡 Opportunities: [areas for improvement]
🎯 Recommendations: [specific suggestions]
❓ Questions: [things to consider]
➡️ Next Steps: [immediate actions]
```

**Next Step:** Proceed to Step 7.

---

### Step 7: Suggest Actions

**Action:** Provide specific, actionable suggestions.

**What to Suggest:**
- Create missing tasks/projects
- Record completed work
- Update priorities
- Schedule follow-ups
- Adjust plans based on patterns

**Suggestion Format:**
```
Suggested Actions:
1. Create task: "[task name]" - [reason]
2. Create project: "[project name]" - [reason]
3. Record completed: "[item]" - [reason]
4. Update priority: "[item]" - [reason]
```

**Next Step:** Complete runbook.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Log data loaded and analyzed
2. ✅ Cross-referenced with GTD system
3. ✅ Action items identified
4. ✅ Patterns analyzed
5. ✅ Insights generated
6. ✅ Actions suggested

**Success Criteria:**
- All steps completed
- Real data used (no hallucination)
- Actionable recommendations provided
- User has clear next steps

## Error Handling

**If log is empty:**
- Acknowledge: "Your daily log is empty for today"
- Suggest: "Consider adding entries to track your day"
- Encourage: "Every entry helps build patterns and insights"

**If tools fail:**
- Report the error clearly
- Continue with available data
- Note what couldn't be checked

**If no patterns found:**
- Acknowledge: "Not enough data yet to identify patterns"
- Suggest: "Continue logging to build up data for analysis"
- Provide general guidance based on available information

## Usage

**To use this runbook:**
1. Ask: "Review my daily log using the runbook"
2. Or: "Follow the daily log review runbook"
3. Or: "Use the runbook to check my daily log"

The system will automatically follow all steps in sequence.

## Integration with Other Runbooks

### Morning Review Integration
If daily logs are missing or sparse, consider establishing a daily logging routine:
- **Interactive Morning Review Runbook**: Guides you through questions to plan your day and establish logging habits
- **Morning Check-In Workflow**: Automated system review for quick daily planning
- **Daily Log Update runbook**: Helps add specific entries throughout the day
- **Weekly/Monthly Reviews**: Build on consistent daily data for deeper insights

### Sequential Thinking Integration
This runbook can be enhanced with Sequential Thinking:
- Use `create_thoughts` for complex pattern analysis
- Use `branch_thought` to explore alternative interpretations
- Use `summarize_thoughts` for final synthesis

Example:
```
Step 5 (Pattern Analysis):
- Call create_thoughts(thought="Let me analyze the energy patterns...")
- Continue with structured thoughts
- Call summarize_thoughts() for final pattern summary
```

### Building a Daily Logging Routine
1. **Start with Interactive Morning Review** - Use Interactive Morning Review Runbook for guided daily planning
2. **Add entries throughout day** - Use Daily Log Update runbook as needed  
3. **Review daily** - Use this Daily Log Review runbook each evening
4. **Weekly synthesis** - Use Weekly Review runbook to identify patterns
5. **Monthly strategic planning** - Use Monthly Review runbook for bigger picture
