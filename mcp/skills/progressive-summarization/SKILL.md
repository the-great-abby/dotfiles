---
name: Progressive Summarization
description: Guide through progressive summarization workflow for distilling notes into insights. Uses three-level system (highlights → summary → core insights) to build knowledge systematically.
version: 1.0.0
tags:
  - second-brain
  - knowledge
  - summarization
  - distill
  - notes
  - productivity
author: GTD System
---

# Progressive Summarization Workflow

A comprehensive skill for guiding through progressive summarization, a core Second Brain practice that distills notes into increasingly valuable insights through three levels of refinement.

## When to Use

Use this skill when you need to:
- **Distill important notes**: Process notes that contain valuable information
- **Build knowledge systematically**: Create summaries that improve over time
- **Extract key insights**: Identify the most important points from longer content
- **Progress notes through levels**: Move notes from raw content to distilled wisdom
- **Create searchable summaries**: Make notes easier to find and reference
- **During reviews**: Process notes as part of weekly/monthly reviews

## How It Works

Progressive summarization uses a three-level system:
1. **Level 1: Highlights** - Manually identify key points
2. **Level 2: Summary** - Create structured summary section
3. **Level 3: Core Insights** - Distill to essential wisdom

Each level extracts the most important information, making notes more valuable over time.

## Step-by-Step Workflow

### Step 1: Select Note to Distill

**Purpose:** Choose which note to process.

**Actions:**
1. Identify notes that would benefit from distillation:
   - Notes with valuable information
   - Notes you reference frequently
   - Notes that are getting long
   - Notes you want to develop as evergreen notes
2. Get note path (full path or relative to Second Brain directory)

**Questions to consider:**
- Is this note important enough to invest time in?
- Will this note be referenced in the future?
- Does this note contain insights worth preserving?

---

### Step 2: Check Current Distill Status

**Purpose:** Understand where the note is in the distillation process.

**Actions:**
1. Read the note to check for existing distill sections:
   - Look for `## Summary` section (Level 2)
   - Look for `## Core Insights` section (Level 3)
   - Check for `## Distill Progress` metadata
2. Determine which level to work on:
   - No distill sections → Start with Level 1
   - Has Summary but no Insights → Work on Level 3
   - Has both → Consider refining or marking as evergreen

**Commands:**
- Read note file directly or use `gtd_search_second_brain(query="note title")` to find it

---

### Step 3: Level 1 - Highlights

**Purpose:** Identify the most important points in the note.

**Actions:**
1. Read through the entire note carefully
2. Identify key points, insights, and important information
3. Manually highlight or mark these sections (in your editor or mentally)
4. Note patterns, themes, or recurring ideas
5. Identify actionable items or next steps

**What to highlight:**
- Key concepts and definitions
- Important insights or realizations
- Actionable items or tasks
- Connections to other ideas
- Questions or areas for exploration
- Quotes or references worth preserving

**Note:** Level 1 is typically manual - you review and identify what matters. The tool `gtd-brain-distill` will guide you through this.

**Commands:**
- Use `gtd-brain-distill <note-path>` to start the workflow
- The tool will ask if you've completed Level 1 highlights

---

### Step 4: Level 2 - Create Summary

**Purpose:** Create a structured summary section that captures the essence of the note.

**Actions:**
1. Based on your Level 1 highlights, create a summary section
2. Use the command to generate Level 2 summary:
   ```bash
   gtd-brain summarize <note-path> 2
   ```
3. Review the generated summary
4. Refine if needed to ensure it captures key points accurately

**What the summary should include:**
- Main topic or theme
- Key points (3-5 most important)
- Important details or context
- Connections or relationships
- Actionable items (if any)

**Commands:**
- `gtd-brain summarize <note-path> 2` - Creates Level 2 summary
- Or use `gtd-brain-distill <note-path>` which guides through all levels

**Note:** The summary should be comprehensive but concise - enough detail to understand the note without reading the full content.

---

### Step 5: Level 3 - Distill to Core Insights

**Purpose:** Extract the essential wisdom and insights from the note.

**Actions:**
1. Based on the summary and highlights, identify the core insights
2. Use the command to generate Level 3 distillation:
   ```bash
   gtd-brain summarize <note-path> 3
   ```
3. Review the core insights
4. Refine to ensure they capture the essential wisdom

**What core insights should include:**
- The most important insight or principle
- Key takeaways (2-3 essential points)
- Why this matters
- How to apply this knowledge
- Connections to broader themes

**Commands:**
- `gtd-brain summarize <note-path> 3` - Creates Level 3 core insights
- Or use `gtd-brain-distill <note-path>` which guides through all levels

**Note:** Core insights should be the distilled wisdom - what you'd want to remember if you could only remember a few things from this note.

---

### Step 6: Update Distill Progress

**Purpose:** Track progress through the distillation process.

**Actions:**
1. The `gtd-brain-distill` command automatically updates progress
2. Check that `## Distill Progress` section exists and is updated
3. Note the date when each level was completed

**Metadata tracked:**
- Date of each distill level completion
- Current distill status
- Notes about the distillation process

---

### Step 7: Consider Next Steps

**Purpose:** Determine what to do with the distilled note.

**Actions:**
1. **If note is highly valuable:**
   - Consider marking as evergreen: `gtd-brain-evergreen mark <note-path>`
   - Add to relevant MOC: `gtd-brain-moc add "Topic" <note-path>`
   - Create connections: `gtd-brain-connect create <note1> <note2>`

2. **If note needs more work:**
   - Schedule for future refinement
   - Add to review list for next session

3. **If note is complete:**
   - Move to appropriate PARA category if needed
   - Archive if no longer active

**Commands:**
- `gtd-brain-evergreen mark <note-path>` - Mark as evergreen note
- `gtd-brain-moc add "Topic" <note-path>` - Add to MOC
- `gtd-brain-connect create <note1> <note2>` - Create connection

---

## Detailed Workflow Examples

### Example 1: Distilling a New Note

**Scenario:** You have a note from a book you read that contains valuable insights.

**Steps:**
1. **Select note:** `~/Documents/obsidian/Second Brain/Resources/productivity-book-notes.md`
2. **Check status:** No distill sections yet - start with Level 1
3. **Level 1:** Read through and identify 5 key insights about productivity
4. **Level 2:** Run `gtd-brain summarize productivity-book-notes.md 2`
   - Creates summary with main concepts
5. **Level 3:** Run `gtd-brain summarize productivity-book-notes.md 3`
   - Extracts 2-3 core principles
6. **Next steps:** Mark as evergreen since it contains timeless principles

### Example 2: Progressing an Existing Note

**Scenario:** You have a note with a summary (Level 2) but want to add core insights (Level 3).

**Steps:**
1. **Select note:** Note already has `## Summary` section
2. **Check status:** Level 2 complete, need Level 3
3. **Level 3:** Run `gtd-brain summarize note.md 3`
   - Creates `## Core Insights` section
4. **Review:** Refine insights to ensure they capture essential wisdom
5. **Next steps:** Add to relevant MOC or create connections

### Example 3: Using Distill Workflow Command

**Scenario:** You want guided workflow through all levels.

**Steps:**
1. **Start workflow:** `gtd-brain-distill note.md`
2. **Follow prompts:**
   - "Have you highlighted key points?" → Yes/No
   - If No: Review note and highlight, then continue
   - If Yes: Proceed to Level 2
3. **Level 2:** Tool creates summary section
4. **Level 3:** Tool creates core insights section
5. **Complete:** Progress automatically tracked

---

## Best Practices

### When to Distill

**Distill these notes:**
- ✅ Notes you reference frequently
- ✅ Notes with valuable insights
- ✅ Notes that are getting long
- ✅ Notes you want to develop as evergreen
- ✅ Notes from important sources (books, courses, meetings)

**Don't need to distill:**
- ❌ Temporary notes or quick captures
- ❌ Notes that are already very concise
- ❌ Notes you rarely reference
- ❌ Notes that are primarily reference material (lists, data)

### Level 1 (Highlights) Best Practices

- **Read actively:** Look for insights, not just facts
- **Identify patterns:** Note recurring themes or connections
- **Mark actionable items:** Highlight things you can do
- **Note questions:** Mark areas for further exploration
- **Consider context:** How does this relate to other knowledge?

### Level 2 (Summary) Best Practices

- **Be comprehensive:** Include all key points
- **Stay concise:** Summary should be 20-30% of original length
- **Maintain structure:** Organize by themes or topics
- **Include context:** Enough detail to understand without reading full note
- **Link to sources:** Reference where information came from

### Level 3 (Core Insights) Best Practices

- **Focus on wisdom:** What's the essential insight?
- **Be selective:** Only 2-3 core insights maximum
- **Make it actionable:** How can this be applied?
- **Connect to principles:** Link to broader themes or frameworks
- **Write for future self:** What would you want to remember?

### Progressive Approach

**Don't rush:**
- Work through levels over time
- Let insights develop as you revisit notes
- Refine summaries as understanding deepens

**Iterate:**
- You can refine summaries and insights later
- Add to core insights as you learn more
- Update as your understanding evolves

---

## Integration with Other Skills

This skill works well with:
- **`evergreen-note-development`**: Distilled notes are good candidates for evergreen notes
- **`moc-creation`**: Add distilled notes to MOCs
- **`knowledge-discovery`**: Use distilled insights to find connections
- **`express-phase`**: Use distilled notes as source material for content
- **`weekly-review`**: Distill notes as part of weekly review

---

## Troubleshooting

### "Note doesn't have enough content to distill"

**Solutions:**
- Some notes are already concise - that's fine
- Focus on notes with substantial content
- Consider combining related short notes first

### "Summary doesn't capture what I want"

**Solutions:**
- Manually refine the generated summary
- Add your own insights to the summary section
- The tool provides a starting point - customize as needed

### "I'm not sure what the core insights are"

**Solutions:**
- Revisit Level 1 highlights
- Ask: "What's the one thing I want to remember from this?"
- Consider: "How would I explain this to someone else?"
- Start with what seems most important - you can refine later

### "I don't have time to distill all my notes"

**Solutions:**
- Focus on the most valuable notes first
- Distill notes gradually over time
- Include distillation in weekly review routine
- Not every note needs to be distilled

---

## Success Criteria

A successfully distilled note:
- ✓ Has clear highlights (Level 1) - you know what matters
- ✓ Has a comprehensive summary (Level 2) - captures key points
- ✓ Has core insights (Level 3) - essential wisdom extracted
- ✓ Is more valuable than the original - easier to reference and use
- ✓ Progress is tracked - you know where it is in the process

---

## Commands Reference

### Main Workflow Command
```bash
gtd-brain-distill <note-path>
```
Guided workflow through all three levels.

### Individual Level Commands
```bash
# Level 2: Create summary
gtd-brain summarize <note-path> 2

# Level 3: Create core insights
gtd-brain summarize <note-path> 3
```

### Related Commands
```bash
# Mark as evergreen (for valuable distilled notes)
gtd-brain-evergreen mark <note-path>

# Add to MOC
gtd-brain-moc add "Topic" <note-path>

# Create connections
gtd-brain-connect create <note1> <note2>

# Discover related notes
gtd-brain-discover <note-path>
```

---

## Workflow Summary

```
Progressive Summarization Workflow
│
├─ 1. Select Note to Distill
│   └─ Choose note with valuable content
│
├─ 2. Check Current Status
│   └─ Determine which level to work on
│
├─ 3. Level 1: Highlights
│   └─ Manually identify key points
│
├─ 4. Level 2: Summary
│   └─ Create structured summary (gtd-brain summarize <note> 2)
│
├─ 5. Level 3: Core Insights
│   └─ Distill to essential wisdom (gtd-brain summarize <note> 3)
│
├─ 6. Update Progress
│   └─ Track completion (automatic with gtd-brain-distill)
│
└─ 7. Next Steps
    ├─ Mark as evergreen (if highly valuable)
    ├─ Add to MOC (if topic-related)
    └─ Create connections (if related to other notes)
```

---

Remember: Progressive summarization is about building knowledge systematically. Each level makes your notes more valuable and easier to use. Focus on the most important notes first, and work through levels gradually over time.
