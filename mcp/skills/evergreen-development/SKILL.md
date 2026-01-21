---
name: Evergreen Note Development
description: Guides the process of developing evergreen notes - notes that grow in value over time through continuous refinement. Helps identify, mark, refine, and connect evergreen notes.
version: 1.0.0
tags:
  - second-brain
  - evergreen
  - knowledge
  - refinement
  - learning
author: GTD System
---

# Evergreen Note Development Workflow

A comprehensive skill for developing evergreen notes - notes that represent core concepts and grow in value over time through continuous refinement and connection.

## When to Use

Use this skill when you need to:
- **Identify evergreen candidates**: Find notes that should be evergreen
- **Mark evergreen notes**: Designate notes as evergreen
- **Refine evergreen notes**: Improve and deepen notes
- **Connect evergreen notes**: Link related concepts
- **Develop knowledge**: Build understanding over time

## How It Works

This workflow guides through identifying, marking, refining, and connecting evergreen notes using Second Brain commands.

## Step-by-Step Workflow

### Step 1: Understand Evergreen Notes

**Purpose:** Know what makes a note evergreen.

**Characteristics of evergreen notes:**
- **Core concepts**: Fundamental ideas, principles, insights
- **Grow in value**: Improve with each refinement
- **Timeless**: Not tied to specific events/dates
- **Connective**: Link to many other notes
- **Refinable**: Can be improved over time

**Examples:**
- Principles (e.g., "GTD Principles", "Productivity Principles")
- Concepts (e.g., "Progressive Summarization", "Energy Management")
- Insights (e.g., "What I've Learned About Learning")
- Frameworks (e.g., "Eisenhower Matrix", "PARA Method")

**Not evergreen:**
- Event notes (meetings, specific dates)
- Project notes (temporary, project-specific)
- Reference material (static, doesn't improve)

---

### Step 2: Identify Evergreen Candidates

**Purpose:** Find notes that should be evergreen.

**Actions:**
1. Review existing notes:
   ```bash
   gtd-brain list
   ```
2. Look for notes that:
   - Represent core concepts
   - Contain insights or principles
   - Are referenced frequently
   - Could be improved over time
   - Connect to many other notes

**Commands:**
- `gtd-brain list` - List all notes
- `gtd-brain search "query"` - Search for concepts

**Questions to ask:**
- Does this note represent a core concept?
- Will this note improve with refinement?
- Is this note referenced often?
- Does this note connect to many others?
- Is this note timeless (not event-specific)?

---

### Step 3: Mark Notes as Evergreen

**Purpose:** Designate notes as evergreen.

**Actions:**
1. For each candidate note:
   ```bash
   gtd-brain-evergreen mark <note-path>
   ```
2. This will:
   - Add evergreen tag/metadata
   - Mark for regular refinement
   - Include in evergreen list

**Commands:**
- `gtd-brain-evergreen mark <note-path>` - Mark as evergreen

**What to mark:**
- Core concepts
- Principles and frameworks
- Key insights
- Important learnings
- Frequently referenced notes

**Don't mark:**
- Event notes
- Project notes
- Temporary notes
- Reference material (unless it's a core concept)

---

### Step 4: Review Existing Evergreen Notes

**Purpose:** See what's already marked evergreen.

**Actions:**
1. List all evergreen notes:
   ```bash
   gtd-brain-evergreen list
   ```
2. Review each note:
   - When was it last refined?
   - Is it still relevant?
   - Does it need refinement?
   - Are connections up to date?

**Commands:**
- `gtd-brain-evergreen list` - List all evergreen notes

**What to review:**
- Total number of evergreen notes
- Last refinement date
- Connection count
- Quality assessment

---

### Step 5: Refine Evergreen Notes

**Purpose:** Improve and deepen notes over time.

**Actions:**
1. Select note to refine:
   ```bash
   gtd-brain-evergreen refine <note-path>
   ```
2. Review note content:
   - Is it clear and complete?
   - Can it be improved?
   - Are examples helpful?
   - Is structure good?
3. Refine:
   - Add new insights
   - Clarify concepts
   - Update examples
   - Improve structure
   - Deepen understanding

**Commands:**
- `gtd-brain-evergreen refine <note-path>` - Refine note

**Refinement process:**
1. Read current note
2. Identify improvements
3. Add new insights
4. Update examples
5. Improve clarity
6. Strengthen connections

**What to refine:**
- Clarity and completeness
- Examples and illustrations
- Structure and organization
- Depth of understanding
- Connections to other notes

---

### Step 6: Discover Connections

**Purpose:** Link evergreen notes to related concepts.

**Actions:**
1. Find connections for note:
   ```bash
   gtd-brain-evergreen connections <note-path>
   ```
2. Review connections:
   - What notes are connected?
   - Are connections accurate?
   - Are there missing connections?
3. Add connections:
   ```bash
   gtd-brain-connect create <note1> <note2>
   ```

**Commands:**
- `gtd-brain-evergreen connections <note-path>` - Show connections
- `gtd-brain-connect create <note1> <note2>` - Create connection
- `gtd-brain-discover <note>` - Discover new connections

**Connection types:**
- **Related concepts**: Similar ideas
- **Prerequisites**: Required knowledge
- **Applications**: Uses of the concept
- **Examples**: Instances of the concept
- **Opposites**: Contrasting ideas

---

### Step 7: Progressive Summarization

**Purpose:** Distill evergreen notes to core insights.

**Actions:**
1. Apply progressive summarization:
   ```bash
   gtd-brain summarize <note> 1  # Highlights
   gtd-brain summarize <note> 2  # Summary
   gtd-brain summarize <note> 3  # Core insights
   ```
2. Review summaries:
   - Are highlights accurate?
   - Is summary complete?
   - Are core insights clear?

**Commands:**
- `gtd-brain summarize <note> 1` - Level 1 (highlights)
- `gtd-brain summarize <note> 2` - Level 2 (summary)
- `gtd-brain summarize <note> 3` - Level 3 (core insights)

**Use `progressive-summarization` skill for detailed workflow.**

---

### Step 8: Review Evergreen Note Quality

**Purpose:** Assess note quality and improvement.

**Actions:**
1. Review note quality metrics:
   ```bash
   gtd-brain-metrics dashboard
   ```
2. Assess:
   - Connection count (more = better)
   - Refinement frequency
   - Reference frequency
   - Quality score

**Commands:**
- `gtd-brain-metrics dashboard` - Quality metrics

**Quality indicators:**
- **High connection count**: Well-integrated
- **Regular refinement**: Actively developed
- **Frequent references**: Useful and relevant
- **High quality score**: Well-structured

---

### Step 9: Create New Evergreen Notes

**Purpose:** Capture new concepts as evergreen.

**Actions:**
1. When you learn a core concept:
   ```bash
   gtd-brain create "Concept Name" Resources
   ```
2. Immediately mark as evergreen:
   ```bash
   gtd-brain-evergreen mark <note-path>
   ```
3. Add initial content:
   - Core concept definition
   - Key insights
   - Examples
   - Connections

**Commands:**
- `gtd-brain create "Concept Name" Resources` - Create note
- `gtd-brain-evergreen mark <note-path>` - Mark evergreen

**Best practices:**
- Create immediately when learning
- Mark as evergreen if it's a core concept
- Add initial content
- Start building connections

---

### Step 10: Maintain Evergreen Notes

**Purpose:** Keep notes current and valuable.

**Actions:**
1. Regular review schedule:
   - Weekly: Review 1-2 evergreen notes
   - Monthly: Refine all evergreen notes
   - Quarterly: Major evergreen audit
2. For each review:
   - Check if still relevant
   - Refine if needed
   - Update connections
   - Improve quality

**Maintenance tasks:**
- Regular refinement
- Connection updates
- Quality improvements
- Relevance checks

---

## Detailed Workflow Examples

### Example 1: Mark New Evergreen Note

**Scenario:** Learned about "Energy Management" concept.

**Steps:**
1. **Create note:**
   ```bash
   gtd-brain create "Energy Management" Resources
   ```

2. **Add initial content:**
   - Definition: Managing energy levels for productivity
   - Key insights: Match tasks to energy, track patterns
   - Examples: Morning high energy, afternoon low

3. **Mark as evergreen:**
   ```bash
   gtd-brain-evergreen mark "Energy Management.md"
   ```

4. **Discover connections:**
   ```bash
   gtd-brain-discover "Energy Management.md"
   ```
   - Found connections to: Productivity, Task Management, Health

5. **Create connections:**
   ```bash
   gtd-brain-connect create "Energy Management.md" "Productivity Principles.md"
   ```

### Example 2: Refine Existing Evergreen Note

**Scenario:** Refining "GTD Principles" note.

**Steps:**
1. **Review note:**
   ```bash
   gtd-brain-evergreen list
   ```
   - Found "GTD Principles" - last refined 2 months ago

2. **Refine note:**
   ```bash
   gtd-brain-evergreen refine "GTD Principles.md"
   ```

3. **Add new insights:**
   - Learned about context-based task selection
   - Discovered energy matching
   - Added examples from experience

4. **Update connections:**
   ```bash
   gtd-brain-connect create "GTD Principles.md" "Context-Based Task Selection.md"
   ```

5. **Progressive summarization:**
   ```bash
   gtd-brain summarize "GTD Principles.md" 3
   ```
   - Updated core insights

### Example 3: Evergreen Note Audit

**Scenario:** Quarterly review of all evergreen notes.

**Steps:**
1. **List all evergreen notes:**
   ```bash
   gtd-brain-evergreen list
   ```
   - Found 15 evergreen notes

2. **Review each note:**
   - Check relevance
   - Check last refinement date
   - Check connection count
   - Assess quality

3. **Refine notes needing work:**
   - 5 notes need refinement
   - Refine each one
   - Update connections

4. **Archive if needed:**
   - 1 note no longer relevant
   - Archive it
   - Remove from evergreen list

---

## Best Practices

### Note Selection

**Choose wisely:**
- Only mark truly core concepts
- Not every note should be evergreen
- Focus on principles and insights
- Avoid event-specific notes

**Quality over quantity:**
- Better to have 10 excellent evergreen notes
- Than 50 mediocre ones
- Focus on depth, not breadth

### Refinement

**Refine regularly:**
- Weekly: 1-2 notes
- Monthly: All notes
- Quarterly: Deep audit

**Improve incrementally:**
- Small improvements over time
- Don't try to perfect in one session
- Build understanding gradually

### Connections

**Build connections:**
- Link to related concepts
- Connect to examples
- Link to applications
- Build knowledge network

**Review connections:**
- Are connections accurate?
- Are there missing connections?
- Should any be removed?

### Maintenance

**Regular maintenance:**
- Schedule refinement time
- Review connections
- Update examples
- Improve quality

**Don't let notes stagnate:**
- Evergreen notes should grow
- Regular refinement is key
- Update as you learn more

---

## Integration with Other Skills

This skill works well with:
- **`progressive-summarization`**: Distill evergreen notes
- **`moc-creation`**: Add evergreen notes to MOCs
- **`knowledge-discovery`**: Discover connections for evergreen notes
- **`express-phase`**: Use evergreen notes in content creation

---

## Troubleshooting

### "I don't know what should be evergreen"

**Solutions:**
- Focus on core concepts and principles
- Look for frequently referenced notes
- Mark notes that improve with refinement
- Start with obvious ones, refine over time

### "I have too many evergreen notes"

**Solutions:**
- Be selective - only core concepts
- Archive notes that aren't truly evergreen
- Focus on quality over quantity
- Review and consolidate

### "I forget to refine evergreen notes"

**Solutions:**
- Schedule regular refinement time
- Add to weekly/monthly review
- Set reminders
- Make it a habit

### "Evergreen notes feel overwhelming"

**Solutions:**
- Start with a few notes
- Refine incrementally
- Don't try to perfect everything
- Focus on one note at a time

---

## Success Criteria

Successful evergreen development:
- ✓ Evergreen candidates identified
- ✓ Notes marked as evergreen
- ✓ Notes refined regularly
- ✓ Connections built
- ✓ Quality improved over time
- ✓ Notes grow in value

---

## Commands Reference

### Evergreen Management
```bash
# Mark note as evergreen
gtd-brain-evergreen mark <note-path>

# List all evergreen notes
gtd-brain-evergreen list

# Refine evergreen note
gtd-brain-evergreen refine <note-path>

# Show connections
gtd-brain-evergreen connections <note-path>
```

### Note Creation
```bash
# Create new note
gtd-brain create "Note Title" Resources
```

### Connection Building
```bash
# Discover connections
gtd-brain-discover <note>

# Create connection
gtd-brain-connect create <note1> <note2>
```

### Progressive Summarization
```bash
# Level 1: Highlights
gtd-brain summarize <note> 1

# Level 2: Summary
gtd-brain summarize <note> 2

# Level 3: Core insights
gtd-brain summarize <note> 3
```

### Quality Metrics
```bash
# View quality dashboard
gtd-brain-metrics dashboard
```

---

## Workflow Summary

```
Evergreen Note Development Workflow
│
├─ 1. Understand Evergreen Notes
│   └─ Know what makes a note evergreen
│
├─ 2. Identify Evergreen Candidates
│   ├─ gtd-brain list
│   └─ Look for core concepts
│
├─ 3. Mark Notes as Evergreen
│   └─ gtd-brain-evergreen mark <note-path>
│
├─ 4. Review Existing Evergreen Notes
│   └─ gtd-brain-evergreen list
│
├─ 5. Refine Evergreen Notes
│   └─ gtd-brain-evergreen refine <note-path>
│
├─ 6. Discover Connections
│   ├─ gtd-brain-evergreen connections
│   └─ gtd-brain-connect create
│
├─ 7. Progressive Summarization
│   └─ gtd-brain summarize <note> 1/2/3
│
├─ 8. Review Evergreen Note Quality
│   └─ gtd-brain-metrics dashboard
│
├─ 9. Create New Evergreen Notes
│   ├─ gtd-brain create
│   └─ Mark as evergreen immediately
│
└─ 10. Maintain Evergreen Notes
    └─ Regular refinement schedule
```

---

Remember: Evergreen notes are your knowledge foundation - core concepts that grow in value over time. Focus on quality over quantity, refine regularly, and build connections. These notes become the building blocks of your understanding.
