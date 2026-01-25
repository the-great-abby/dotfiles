---
name: Daily Log Update Runbook
description: Step-by-step runbook for updating daily logs. Provides a structured, repeatable process for capturing activities, thoughts, accomplishments, and reflections in the daily log.
version: 1.0.0
type: runbook
tags:
  - runbook
  - daily-log
  - update
  - capture
  - logging
  - routine
author: GTD System
---

# Daily Log Update Runbook

A structured, step-by-step runbook for updating daily logs. This runbook ensures consistent, thorough capture of daily activities, thoughts, and reflections.

## Purpose

This runbook guides the system through a complete daily log update process:
- Understanding what information to capture
- Structuring log entries appropriately
- Adding entries with proper formatting
- Ensuring completeness and consistency

## Prerequisites

- Access to GTD tools (gtd_add_daily_log_entry, gtd_get_datetime, etc.)
- User wants to add information to their daily log

## Runbook Steps

### Step 1: Understand What to Capture

**Action:** Determine what information the user wants to log.

**What to Capture:**
- Activities performed
- Thoughts and reflections
- Accomplishments and wins
- Challenges or blockers
- Energy levels
- Mood or emotional state
- Meetings or conversations
- Decisions made
- Ideas or insights
- Gratitude entries
- Goals or priorities mentioned

**Questions to Ask (if needed):**
- What did you do?
- What did you accomplish?
- What are you thinking about?
- How are you feeling?
- What happened today?
- What should be remembered?

**Next Step:** Proceed to Step 2.

---

### Step 2: Get Current Date and Time Context

**Action:** Call `gtd_get_datetime()` to get the current date and time context.

**Expected Output:** Current date in YYYY-MM-DD format and current time.

**Validation:**
- ✅ Date and time retrieved successfully
- ✅ Date format is correct (YYYY-MM-DD)

**Why This Matters:**
- Ensures entries are added to the correct date
- Helps with timestamp accuracy
- Supports adding entries to past/future dates if needed

**Next Step:** Proceed to Step 3.

---

### Step 3: Structure the Entry

**Action:** Format the entry appropriately based on content type.

**Entry Types and Formats:**

1. **Activity Entry:**
   ```
   "Worked on [project/task] - [details]"
   ```

2. **Accomplishment Entry:**
   ```
   "Completed [task/project] - [impact/result]"
   ```

3. **Reflection Entry:**
   ```
   "Reflection: [thought/insight]"
   ```

4. **Meeting/Conversation Entry:**
   ```
   "Meeting with [person/team] - [topic/outcome]"
   ```

5. **Energy/Mood Entry:**
   ```
   "Energy: [level] - [context/reason]"
   ```

6. **Decision Entry:**
   ```
   "Decision: [what was decided] - [reason/impact]"
   ```

7. **Gratitude Entry:**
   ```
   "Gratitude: [what you're grateful for]"
   ```

8. **Blocker/Challenge Entry:**
   ```
   "Blocker: [what's blocking] - [attempted solutions]"
   ```

**Best Practices:**
- Be specific and concrete
- Include context when helpful
- Use clear, concise language
- Add timestamps automatically (handled by tool)

**Next Step:** Proceed to Step 4.

---

### Step 4: Add Entry to Daily Log

**Action:** Call `gtd_add_daily_log_entry(entry="[formatted entry]", date="today")` to add the entry.

**Expected Output:** Confirmation that entry was added successfully.

**Validation:**
- ✅ Entry added successfully
- ✅ Entry appears in log file
- ❌ If error, report clearly and suggest retry

**Error Handling:**
- If date is invalid, use "today" as default
- If entry is empty, ask user for content
- If tool fails, report error and suggest manual entry

**Next Step:** Proceed to Step 5.

---

### Step 5: Verify Entry Was Added

**Action:** Optionally call `gtd_read_daily_log(date="today")` to verify the entry appears.

**Expected Output:** Daily log content including the newly added entry.

**Validation:**
- ✅ Entry appears in log
- ✅ Entry has correct timestamp
- ✅ Entry format is correct

**Note:** This step is optional but recommended for important entries.

**Next Step:** Proceed to Step 6.

---

### Step 6: Suggest Additional Entries (Optional)

**Action:** Based on what was logged, suggest related entries that might be valuable.

**What to Suggest:**
- Related activities that might be worth logging
- Follow-up thoughts or reflections
- Tasks that should be created from the entry
- Patterns or connections to other log entries

**Suggestion Format:**
```
You might also want to log:
- [related entry suggestion]
- [another suggestion]
```

**Next Step:** Complete runbook.

---

## Runbook Completion

**Final Output Should Include:**
1. ✅ Entry content determined and structured
2. ✅ Date/time context retrieved
3. ✅ Entry added to daily log
4. ✅ Entry verified (optional)
5. ✅ Additional suggestions provided (optional)

**Success Criteria:**
- Entry successfully added to log
- Entry is properly formatted
- User has confirmation
- Optional suggestions provided

## Error Handling

**If entry is empty:**
- Ask user: "What would you like to add to your daily log?"
- Provide examples of what can be logged
- Wait for user input

**If date is invalid:**
- Use "today" as default
- Inform user: "Using today's date for the entry"
- Continue with entry addition

**If tool fails:**
- Report error clearly: "Failed to add entry: [error]"
- Suggest manual entry: "You can add this manually using: addInfoToDailyLog '[entry]'"
- Offer to retry

**If entry format is unclear:**
- Ask clarifying questions
- Suggest a format based on content type
- Proceed once format is clear

## Usage

**To use this runbook:**
1. Ask: "Add [information] to my daily log using the runbook"
2. Or: "Update my daily log using the runbook"
3. Or: "Log [activity/thought] using the runbook"
4. Or: "Use the runbook to add [entry] to my daily log"

The system will automatically follow all steps in sequence.

## Examples

### Example 1: Activity Entry
**User:** "Add 'worked on project X for 2 hours' to my daily log using the runbook"

**Runbook Execution:**
1. Understand: Activity entry about work on project
2. Get date/time: Current date and time
3. Structure: "Worked on project X for 2 hours"
4. Add entry: `gtd_add_daily_log_entry(entry="Worked on project X for 2 hours")`
5. Verify: Check log contains entry
6. Suggest: "You might also want to log any blockers or insights from this work"

### Example 2: Reflection Entry
**User:** "Log my reflection about today's meeting using the runbook"

**Runbook Execution:**
1. Understand: Reflection about a meeting
2. Get date/time: Current date and time
3. Structure: "Reflection: [meeting thoughts]"
4. Add entry: `gtd_add_daily_log_entry(entry="Reflection: [thoughts]")`
5. Verify: Check log contains entry
6. Suggest: "Consider creating tasks for any action items from the meeting"

### Example 3: Multiple Entries
**User:** "Add several things to my daily log using the runbook"

**Runbook Execution:**
1. Understand: Multiple entries needed
2. For each entry:
   - Get date/time
   - Structure appropriately
   - Add to log
   - Verify
3. Provide summary of all entries added
4. Suggest related entries

## Integration with Other Runbooks

This runbook can be used:
- **With Daily Log Review Runbook:** Update log, then review it
- **With Morning Check-In:** Add morning log entries
- **With Evening Check-In:** Add evening reflections
- **With Task Creation:** Log activities, then create tasks from them

## Best Practices

1. **Be Specific:** Encourage detailed, concrete entries
2. **Add Context:** Include relevant details (who, what, when, why)
3. **Use Timestamps:** Tool automatically adds timestamps
4. **Suggest Follow-ups:** Recommend related entries or tasks
5. **Verify Important Entries:** Check that critical entries were added correctly

## Tips for Effective Logging

- **Log in the moment:** Capture thoughts and activities as they happen
- **Be honest:** Include challenges and blockers, not just wins
- **Include energy/mood:** Track how you're feeling throughout the day
- **Note patterns:** Log recurring themes or concerns
- **Capture decisions:** Record important decisions and their reasoning
- **Express gratitude:** Regular gratitude entries build positive patterns

## Next Steps After Logging

After adding entries, consider:
- Reviewing the log (use Daily Log Review Runbook)
- Creating tasks from action items mentioned
- Reflecting on patterns over time
- Planning based on logged activities
