---
name: MOC Creation & Maintenance
description: Guide through creating and maintaining Maps of Content (MOCs) to organize Second Brain notes by topic. Helps discover connections, auto-populate from tags, and maintain MOC structure over time.
version: 1.0.0
tags:
  - second-brain
  - knowledge
  - organization
  - moc
  - notes
author: GTD System
---

# MOC Creation & Maintenance Workflow

A comprehensive skill for creating and maintaining Maps of Content (MOCs) - index notes that organize your Second Brain by topic. MOCs help you navigate large knowledge bases, discover connections, and maintain organized knowledge.

## When to Use

Use this skill when you need to:
- **Organize notes by topic**: Group related notes together
- **Create knowledge hubs**: Build indexes for major topics
- **Discover connections**: Find relationships between notes
- **Maintain organization**: Keep MOCs updated as you add notes
- **Navigate knowledge base**: Make it easier to find related content
- **Build topic expertise**: Organize learning and knowledge by subject

## How It Works

MOCs are index notes that link to related notes organized by topic. They use PARA categories (Projects, Areas, Resources, Archives) and can be auto-populated from tags.

## Step-by-Step Workflow

### Step 1: Identify Topic for MOC

**Purpose:** Determine what topic needs a MOC.

**Actions:**
1. Identify a topic that has multiple related notes:
   - Major areas of interest
   - Learning topics
   - Project categories
   - Areas of responsibility
   - Recurring themes in your notes
2. Consider if a MOC would be helpful:
   - Do you have 5+ notes on this topic?
   - Is this a topic you reference frequently?
   - Would organizing by topic help navigation?

**Questions to ask:**
- What topics do I have many notes about?
- What topics do I reference frequently?
- What would benefit from organization?
- What are my major areas of interest?

**Examples of good MOC topics:**
- "Productivity" - All productivity-related notes
- "Kubernetes Learning" - All Kubernetes study notes
- "Health & Wellness" - Health-related notes
- "GTD System" - GTD workflows and practices
- "Work & Career" - Professional development notes

---

### Step 2: Check if MOC Already Exists

**Purpose:** Avoid creating duplicate MOCs.

**Actions:**
1. List existing MOCs:
   ```bash
   gtd-brain-moc list
   ```
2. Check if a MOC for this topic already exists
3. If exists: Use existing MOC and add notes to it
4. If not exists: Proceed to create new MOC

**Commands:**
- `gtd-brain-moc list` - List all existing MOCs
- `gtd-brain-moc view "Topic"` - View existing MOC

**What to check:**
- Exact topic name match
- Similar topic names (might want to consolidate)
- Related MOCs that could include this topic

---

### Step 3: Create the MOC

**Purpose:** Create the MOC structure.

**Actions:**
1. Create MOC with topic name:
   ```bash
   gtd-brain-moc create "Topic Name" "Description"
   ```
2. Provide description (optional but helpful):
   - What this MOC is about
   - What types of notes it includes
   - Why it's useful
3. Verify MOC was created successfully

**Commands:**
- `gtd-brain-moc create "Topic" "Description"` - Create MOC

**MOC structure created:**
- File: `~/Documents/obsidian/Second Brain/MOCs/MOC - Topic Name.md`
- Sections: Projects, Areas, Resources, Archives
- Tags: `#moc #topic-name`
- Last updated date

**Example:**
```bash
gtd-brain-moc create "Productivity" "All notes related to productivity, GTD, time management, and efficiency"
```

---

### Step 4: Add Notes to MOC

**Purpose:** Populate the MOC with relevant notes.

**Actions:**
1. **Manual addition:**
   - Identify notes that belong to this topic
   - Add each note to the MOC:
     ```bash
     gtd-brain-moc add "Topic" <note-path> [category]
     ```
   - Category options: Projects, Areas, Resources, Archives (default: Resources)

2. **Auto-populate from tags:**
   - If notes use consistent tags:
     ```bash
     gtd-brain-moc auto "Topic" <tag>
     ```
   - This finds all notes with the tag and adds them

3. **Search and add:**
   - Use `gtd_search_second_brain(query="topic")` to find relevant notes
   - Review results and add relevant notes to MOC

**Commands:**
- `gtd-brain-moc add "Topic" <note-path> [category]` - Add note manually
- `gtd-brain-moc auto "Topic" <tag>` - Auto-populate from tags
- `gtd_search_second_brain(query="...")` - Find relevant notes

**Categories:**
- **Projects**: Notes related to specific projects
- **Areas**: Notes related to areas of responsibility
- **Resources**: General resource notes (default)
- **Archives**: Archived or historical notes

**Example:**
```bash
# Manual addition
gtd-brain-moc add "Productivity" ~/Documents/obsidian/Second\ Brain/Resources/gtd-notes.md Resources

# Auto-populate from tag
gtd-brain-moc auto "Productivity" productivity
```

---

### Step 5: Organize Notes by Category

**Purpose:** Structure notes within MOC using PARA categories.

**Actions:**
1. Review notes added to MOC
2. Organize into appropriate categories:
   - **Projects**: Notes for specific projects
   - **Areas**: Notes for areas of responsibility
   - **Resources**: General resource notes
   - **Archives**: Historical or archived notes
3. Ensure notes are in the right category
4. Add notes to multiple categories if they fit

**MCP Tools:**
- `gtd-brain-moc view "Topic"` - View MOC structure
- `gtd-brain-moc add "Topic" <note> <category>` - Add to specific category

**Best practices:**
- Use Projects for project-specific notes
- Use Areas for ongoing responsibility notes
- Use Resources for general knowledge notes
- Use Archives for historical notes

---

### Step 6: Discover and Add Connections

**Purpose:** Find related notes and add them to MOC.

**Actions:**
1. For each note in the MOC, discover connections:
   ```bash
   gtd-brain-discover <note-path>
   ```
2. Review discovered connections:
   - Related notes
   - Shared tags
   - Links
3. Add relevant connected notes to MOC:
   ```bash
   gtd-brain-moc add "Topic" <connected-note-path>
   ```

**Commands:**
- `gtd-brain-discover <note-path>` - Find connections
- `gtd-brain-moc add "Topic" <note-path>` - Add connected notes

**What to look for:**
- Notes that reference the same concepts
- Notes with similar tags
- Notes that link to each other
- Notes that cover related topics

---

### Step 7: Link to Related MOCs

**Purpose:** Connect MOCs to show relationships between topics.

**Actions:**
1. Identify related MOCs
2. Add links to related MOCs in the "Related MOCs" section
3. Update related MOCs to link back (bidirectional linking)

**Example:**
If you have "Productivity" and "GTD System" MOCs, link them:
- In "Productivity" MOC: Add link to "GTD System" MOC
- In "GTD System" MOC: Add link to "Productivity" MOC

**Benefits:**
- Shows relationships between topics
- Makes navigation easier
- Discovers connections
- Builds knowledge network

---

### Step 8: Maintain MOC Over Time

**Purpose:** Keep MOC updated as you add new notes.

**Actions:**
1. **Regular maintenance:**
   - Weekly: Review new notes and add to relevant MOCs
   - Monthly: Review MOC structure and organization
   - Quarterly: Consolidate or split MOCs if needed

2. **When adding new notes:**
   - Consider: Does this belong in a MOC?
   - Add to relevant MOC when creating note
   - Or add during weekly review

3. **When notes change:**
   - Move notes between categories if needed
   - Update MOC if note topic changes
   - Remove notes if they're no longer relevant

**Maintenance checklist:**
- [ ] Review new notes from past week
- [ ] Add relevant notes to MOCs
- [ ] Check MOC organization
- [ ] Update related MOC links
- [ ] Remove outdated notes if needed

---

## Detailed Workflow Examples

### Example 1: Create Learning MOC

**Scenario:** You want to organize all your Kubernetes learning notes.

**Steps:**
1. **Identify topic:** "Kubernetes Learning"
2. **Check existing:** `gtd-brain-moc list` - No existing MOC
3. **Create MOC:**
   ```bash
   gtd-brain-moc create "Kubernetes Learning" "All notes related to learning Kubernetes, CKA exam prep, and Kubernetes concepts"
   ```
4. **Auto-populate from tag:**
   ```bash
   gtd-brain-moc auto "Kubernetes Learning" kubernetes
   ```
5. **Add project notes:**
   ```bash
   gtd-brain-moc add "Kubernetes Learning" ~/Documents/obsidian/Second\ Brain/Projects/cka-exam-preparation.md Projects
   ```
6. **Discover connections:**
   - For each note: `gtd-brain-discover <note>`
   - Add relevant connected notes

### Example 2: Maintain Existing MOC

**Scenario:** You have a "Productivity" MOC and want to add new notes.

**Steps:**
1. **View existing MOC:**
   ```bash
   gtd-brain-moc view "Productivity"
   ```
2. **Find new notes:**
   ```bash
   gtd_search_second_brain(query="productivity")
   ```
3. **Add relevant notes:**
   ```bash
   gtd-brain-moc add "Productivity" <new-note-path> Resources
   ```
4. **Update last updated date** (automatic when adding)

### Example 3: Create MOC from Scratch

**Scenario:** Starting a new area of interest and want to organize from the beginning.

**Steps:**
1. **Create MOC early:**
   ```bash
   gtd-brain-moc create "New Topic" "Description"
   ```
2. **As you create notes, add them:**
   - When creating note: `gtd-brain create "Note" Resources`
   - Immediately add: `gtd-brain-moc add "New Topic" <note-path>`
3. **Build MOC organically** as you learn and create notes

---

## Best Practices

### When to Create a MOC

**Create MOC when:**
- ✅ You have 5+ notes on a topic
- ✅ Topic is a major area of interest
- ✅ You reference the topic frequently
- ✅ Notes are getting hard to find
- ✅ You want to build expertise in an area

**Don't need MOC for:**
- ❌ Single notes or very few notes
- ❌ Temporary topics
- ❌ Topics you rarely reference
- ❌ Very specific one-off topics

### MOC Organization

**Structure MOCs by:**
- **Topic**: Main organizing principle
- **PARA categories**: Projects, Areas, Resources, Archives
- **Chronology**: Sometimes helpful for learning MOCs
- **Type**: Sometimes helpful (articles, books, courses)

### Naming MOCs

**Good MOC names:**
- ✅ Clear and descriptive: "Kubernetes Learning"
- ✅ Specific enough: "Productivity" not "Stuff"
- ✅ Broad enough: "Health & Wellness" not "Morning Workout Jan 2025"

**Avoid:**
- ❌ Too vague: "Things"
- ❌ Too specific: "Note from Tuesday"
- ❌ Duplicate topics: "Productivity" and "GTD" (consider consolidating)

### Maintaining MOCs

**Regular maintenance:**
- **Weekly**: Add new notes during weekly review
- **Monthly**: Review MOC structure and organization
- **Quarterly**: Consolidate or split MOCs if needed

**When to update:**
- When creating new notes on the topic
- During weekly review
- When notes change categories
- When discovering new connections

---

## Integration with Other Skills

This skill works well with:
- **`progressive-summarization`**: Add distilled notes to MOCs
- **`evergreen-note-development`**: Organize evergreen notes in MOCs
- **`express-phase`**: Use MOC notes as source material
- **`knowledge-discovery`**: Discover connections for MOCs
- **`weekly-review`**: Maintain MOCs during weekly review

---

## Troubleshooting

### "I have too many notes to add manually"

**Solutions:**
- Use `gtd-brain-moc auto "Topic" <tag>` to auto-populate
- Add notes gradually over time
- Focus on most important notes first
- Add notes as you create them (easier than retroactive)

### "I don't know what category to use"

**Solutions:**
- **Resources**: Default, use for general knowledge notes
- **Projects**: Notes for specific projects
- **Areas**: Notes for ongoing responsibilities
- **Archives**: Historical or archived notes
- When in doubt, use Resources

### "My MOC is getting too large"

**Solutions:**
- Split into sub-topics (e.g., "Kubernetes Basics" and "Kubernetes Advanced")
- Create sub-MOCs for major themes
- Organize by date or type within MOC
- Archive old notes to Archives category

### "I can't find notes to add"

**Solutions:**
- Use `gtd_search_second_brain(query="topic")` to find notes
- Use `gtd-brain-discover <note>` to find connections
- Review notes by tags: `gtd-brain list` and filter
- Add notes gradually as you encounter them

---

## Success Criteria

A successful MOC:
- ✓ Has clear topic and description
- ✓ Contains 5+ relevant notes
- ✓ Notes organized by PARA categories
- ✓ Related MOCs linked
- ✓ Last updated date current
- ✓ Makes it easier to find related notes
- ✓ Helps discover connections

---

## Commands Reference

### MOC Management
```bash
# Create MOC
gtd-brain-moc create "Topic" "Description"

# Add note to MOC
gtd-brain-moc add "Topic" <note-path> [category]

# Auto-populate from tags
gtd-brain-moc auto "Topic" <tag>

# List all MOCs
gtd-brain-moc list

# View MOC
gtd-brain-moc view "Topic"
```

### Finding Notes
```bash
# Search Second Brain
gtd_search_second_brain(query="topic")

# Discover connections
gtd-brain-discover <note-path>

# List notes
gtd-brain list [category]
```

---

## Workflow Summary

```
MOC Creation & Maintenance Workflow
│
├─ 1. Identify Topic for MOC
│   └─ Determine what topic needs organization
│
├─ 2. Check if MOC Already Exists
│   └─ gtd-brain-moc list
│
├─ 3. Create the MOC
│   └─ gtd-brain-moc create "Topic" "Description"
│
├─ 4. Add Notes to MOC
│   ├─ Manual: gtd-brain-moc add "Topic" <note> [category]
│   └─ Auto: gtd-brain-moc auto "Topic" <tag>
│
├─ 5. Organize Notes by Category
│   └─ Use PARA categories (Projects/Areas/Resources/Archives)
│
├─ 6. Discover and Add Connections
│   ├─ gtd-brain-discover <note>
│   └─ Add connected notes to MOC
│
├─ 7. Link to Related MOCs
│   └─ Add bidirectional links between related MOCs
│
└─ 8. Maintain MOC Over Time
    ├─ Add new notes regularly
    ├─ Review structure monthly
    └─ Update as needed
```

---

## Common MOC Topics

### Starter MOCs to Consider

1. **Areas of Responsibility** - Organize by life areas
2. **Active Projects** - Track current projects
3. **Learning & Study** - Organize learning materials
4. **Health & Wellness** - Health-related notes
5. **Work & Career** - Professional development
6. **GTD System** - GTD workflows and practices
7. **Productivity** - Productivity and efficiency notes
8. **Technology** - Tech learning and notes
9. **Relationships** - Personal relationship notes
10. **Goals & Vision** - Goals and life vision

---

Remember: MOCs are living documents. Start simple, add notes gradually, and maintain them over time. They become more valuable as they grow and help you navigate and discover connections in your knowledge base.
