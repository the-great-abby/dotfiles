---
name: Knowledge Discovery Session
description: Guides discovery of connections, patterns, and insights across your Second Brain. Helps uncover hidden relationships, identify knowledge gaps, and build a more connected knowledge network.
version: 1.0.0
tags:
  - second-brain
  - discovery
  - connections
  - insights
  - knowledge
author: GTD System
---

# Knowledge Discovery Session Workflow

A comprehensive skill for discovering connections, patterns, and insights across your Second Brain knowledge base. Helps uncover hidden relationships and build a more connected understanding.

## When to Use

Use this skill when you need to:
- **Discover connections**: Find relationships between notes
- **Identify patterns**: See patterns across knowledge
- **Find knowledge gaps**: Identify missing connections
- **Build understanding**: Deepen knowledge through connections
- **Explore topics**: Dive deep into a subject area

## How It Works

This workflow uses discovery commands, connection analysis, and pattern recognition to uncover relationships and insights in your knowledge base.

## Step-by-Step Workflow

### Step 1: Select Starting Point

**Purpose:** Choose what to explore.

**Actions:**
1. **Option A: Start with a specific note**
   - Choose a note you want to explore
   - Discover connections from that note

2. **Option B: Start with a topic**
   - Search for notes on a topic
   - Explore the topic area

3. **Option C: Start with a question**
   - Ask a question
   - Discover notes that answer it

**Commands:**
- `gtd-brain list` - List all notes
- `gtd-brain search "query"` - Search for topic
- `gtd-brain find "term"` - Find notes with term

**Questions to ask:**
- What do I want to explore?
- What question am I trying to answer?
- What topic interests me?
- What note needs more connections?

---

### Step 2: Discover Connections for Note

**Purpose:** Find related notes and concepts.

**Actions:**
1. For a specific note:
   ```bash
   gtd-brain-discover <note-path>
   ```
2. Review discovered connections:
   - Related notes
   - Similar concepts
   - Prerequisites
   - Applications
   - Examples

**Commands:**
- `gtd-brain-discover <note-path>` - Discover connections

**What to look for:**
- Notes with similar content
- Notes that reference this note
- Notes this note should reference
- Missing connections
- Unexpected relationships

---

### Step 3: Review Existing Connections

**Purpose:** See what's already connected.

**Actions:**
1. Review note connections:
   - What notes are linked?
   - Are connections accurate?
   - Are connections bidirectional?
2. Assess connection quality:
   - Are connections meaningful?
   - Do they add value?
   - Should any be removed?

**Commands:**
- `gtd-brain-connect list <note>` - List connections (if available)
- Review note content for links

**Connection types:**
- **Direct links**: Explicitly linked notes
- **Implicit connections**: Related but not linked
- **Bidirectional**: Both notes link to each other
- **One-way**: Only one note links to the other

---

### Step 4: Create New Connections

**Purpose:** Link related notes.

**Actions:**
1. For each discovered connection:
   ```bash
   gtd-brain-connect create <note1> <note2> "Description"
   ```
2. Add connection description:
   - Why are they connected?
   - What's the relationship?
   - How do they relate?

**Commands:**
- `gtd-brain-connect create <note1> <note2> "Description"` - Create connection

**When to create connections:**
- Notes are related
- One note builds on another
- Notes share concepts
- Notes are examples of each other

**Connection descriptions:**
- "Builds on concept from..."
- "Example of..."
- "Related to..."
- "Prerequisite for..."

---

### Step 5: Search for Related Topics

**Purpose:** Find notes on related topics.

**Actions:**
1. Search for related terms:
   ```bash
   gtd-brain search "related term"
   ```
2. Review search results:
   - Which notes are relevant?
   - Which should be connected?
   - What patterns emerge?

**Commands:**
- `gtd-brain search "query"` - Search notes
- `gtd-brain find "term"` - Find notes with term

**Search strategies:**
- Use related keywords
- Search for concepts
- Search for examples
- Search for applications

---

### Step 6: Identify Knowledge Gaps

**Purpose:** Find missing connections or notes.

**Actions:**
1. Review discovered connections:
   - Are there obvious missing notes?
   - Are there missing connections?
   - What concepts are referenced but not explained?
2. Identify gaps:
   - Missing prerequisite notes
   - Missing example notes
   - Missing application notes
   - Missing connection notes

**Questions to ask:**
- What notes are referenced but don't exist?
- What concepts need explanation?
- What examples are missing?
- What connections are missing?

---

### Step 7: Create Missing Notes

**Purpose:** Fill knowledge gaps.

**Actions:**
1. For each identified gap:
   ```bash
   gtd-brain create "Note Title" Resources
   ```
2. Add content:
   - Core concept
   - Key insights
   - Examples
   - Connections

**Commands:**
- `gtd-brain create "Note Title" Resources` - Create note

**What to create:**
- Prerequisite notes
- Example notes
- Application notes
- Connection notes

---

### Step 8: Review MOCs for Topic

**Purpose:** See how topic is organized.

**Actions:**
1. List MOCs:
   ```bash
   gtd-brain-moc list
   ```
2. Review relevant MOCs:
   - Does topic have a MOC?
   - Should topic have a MOC?
   - Are notes organized well?

**Commands:**
- `gtd-brain-moc list` - List all MOCs
- `gtd-brain-moc view "Topic"` - View MOC

**MOC review:**
- Is topic covered in MOC?
- Are notes in MOC?
- Should notes be added?
- Should new MOC be created?

**Use `moc-creation` skill for MOC management.**

---

### Step 9: Identify Patterns

**Purpose:** See patterns across knowledge.

**Actions:**
1. Review discovered connections:
   - What patterns emerge?
   - What themes appear?
   - What relationships repeat?
2. Document patterns:
   - Common concepts
   - Recurring themes
   - Relationship patterns

**Pattern types:**
- **Conceptual patterns**: Similar concepts across notes
- **Thematic patterns**: Common themes
- **Relationship patterns**: Similar connection types
- **Structural patterns**: Similar note structures

---

### Step 10: Request Deep Analysis

**Purpose:** Get AI insights on connections.

**Actions:**
1. Request connection analysis:
   ```python
   find_connections(scope="second_brain")
   generate_insights(focus="knowledge_connections")
   ```
2. Review analysis:
   - New connections identified
   - Patterns discovered
   - Insights generated

**MCP Tools:**
- `find_connections(scope="second_brain")` - Find connections
- `generate_insights(focus="knowledge_connections")` - Generate insights

**What to look for:**
- Unexpected connections
- Hidden patterns
- New insights
- Knowledge gaps

---

### Step 11: Build Knowledge Network

**Purpose:** Strengthen knowledge connections.

**Actions:**
1. Review connection network:
   - Which notes are well-connected?
   - Which notes are isolated?
   - How can network be strengthened?
2. Strengthen network:
   - Add connections to isolated notes
   - Create hub notes (MOCs)
   - Build bidirectional links
   - Add connection notes

**Network building:**
- Connect isolated notes
- Create hub notes
- Build bidirectional links
- Strengthen weak connections

---

### Step 12: Document Discoveries

**Purpose:** Record insights and connections.

**Actions:**
1. Document discoveries:
   - New connections found
   - Patterns identified
   - Insights generated
   - Gaps identified
2. Create discovery note or update existing:
   - Connection map
   - Pattern summary
   - Insight collection
   - Gap list

**What to document:**
- Key discoveries
- New connections
- Patterns identified
- Insights generated
- Next steps

---

## Detailed Workflow Examples

### Example 1: Discover Connections for Single Note

**Scenario:** Exploring "Energy Management" note.

**Steps:**
1. **Discover connections:**
   ```bash
   gtd-brain-discover "Energy Management.md"
   ```

2. **Review discovered:**
   - Found: Productivity, Task Management, Health
   - Missing: Time Management, Focus

3. **Create connections:**
   ```bash
   gtd-brain-connect create "Energy Management.md" "Productivity Principles.md" "Energy affects productivity"
   gtd-brain-connect create "Energy Management.md" "Task Management.md" "Match tasks to energy"
   ```

4. **Search for related:**
   ```bash
   gtd-brain search "time management"
   ```
   - Found "Time Blocking" note
   - Should connect to Energy Management

5. **Create connection:**
   ```bash
   gtd-brain-connect create "Energy Management.md" "Time Blocking.md" "Time block based on energy"
   ```

### Example 2: Explore Topic Area

**Scenario:** Exploring "Productivity" topic.

**Steps:**
1. **Search for topic:**
   ```bash
   gtd-brain search "productivity"
   ```
   - Found 8 notes on productivity

2. **Review each note:**
   - Discover connections for each
   - Identify relationships
   - Find patterns

3. **Identify patterns:**
   - Common themes: Energy, Focus, Systems
   - Recurring concepts: GTD, Time Management
   - Relationship pattern: Many notes connect to "GTD Principles"

4. **Create MOC:**
   ```bash
   gtd-brain-moc create "Productivity"
   ```
   - Add all productivity notes to MOC

5. **Request deep analysis:**
   ```python
   find_connections(scope="productivity")
   generate_insights(focus="productivity_patterns")
   ```

### Example 3: Answer Question Through Discovery

**Scenario:** "How do I manage energy for productivity?"

**Steps:**
1. **Search for relevant notes:**
   ```bash
   gtd-brain search "energy"
   gtd-brain search "productivity"
   ```

2. **Discover connections:**
   - "Energy Management" note
   - "Productivity Principles" note
   - Discover connections between them

3. **Find related notes:**
   - Task Management
   - Time Blocking
   - Health & Wellness

4. **Build understanding:**
   - Read connected notes
   - Understand relationships
   - Synthesize insights

5. **Create summary note:**
   ```bash
   gtd-brain create "Energy for Productivity" Resources
   ```
   - Link to all relevant notes
   - Document insights

---

## Best Practices

### Discovery Process

**Be systematic:**
- Start with clear goal
- Follow discovery process
- Document findings
- Build connections incrementally

**Be curious:**
- Follow interesting connections
- Explore unexpected relationships
- Ask "what if" questions
- Don't limit exploration

### Connection Building

**Create meaningful connections:**
- Only connect if truly related
- Add descriptions explaining relationship
- Build bidirectional links when appropriate
- Review connections regularly

**Quality over quantity:**
- Better to have fewer, meaningful connections
- Than many weak connections
- Focus on value, not volume

### Pattern Recognition

**Look for patterns:**
- Common themes
- Recurring concepts
- Similar structures
- Relationship patterns

**Document patterns:**
- Record identified patterns
- Create pattern notes
- Link to examples
- Build pattern library

### Knowledge Gaps

**Identify gaps:**
- Missing prerequisite notes
- Missing example notes
- Missing connection notes
- Missing explanation notes

**Fill gaps:**
- Create missing notes
- Add connections
- Build understanding
- Strengthen network

---

## Integration with Other Skills

This skill works well with:
- **`evergreen-development`**: Discover connections for evergreen notes
- **`moc-creation`**: Organize discovered notes in MOCs
- **`progressive-summarization`**: Distill discovered insights
- **`express-phase`**: Use discoveries in content creation

---

## Troubleshooting

### "I don't find many connections"

**Solutions:**
- Use broader search terms
- Look for implicit connections
- Create connection notes
- Request deep analysis

### "Connections feel forced"

**Solutions:**
- Only connect if truly related
- Focus on meaningful relationships
- Don't connect everything
- Quality over quantity

### "Discovery feels overwhelming"

**Solutions:**
- Focus on one note at a time
- Set time limits
- Document as you go
- Don't try to discover everything at once

### "I don't know where to start"

**Solutions:**
- Start with a question
- Start with a topic of interest
- Start with a note you use often
- Let curiosity guide you

---

## Success Criteria

Successful knowledge discovery:
- ✓ Connections discovered
- ✓ New connections created
- ✓ Patterns identified
- ✓ Knowledge gaps found
- ✓ Missing notes created
- ✓ Network strengthened
- ✓ Insights generated
- ✓ Discoveries documented

---

## Commands Reference

### Discovery
```bash
# Discover connections for note
gtd-brain-discover <note-path>

# Search for notes
gtd-brain search "query"

# Find notes with term
gtd-brain find "term"
```

### Connection Management
```bash
# Create connection
gtd-brain-connect create <note1> <note2> "Description"

# List connections (if available)
gtd-brain-connect list <note>
```

### Note Creation
```bash
# Create new note
gtd-brain create "Note Title" Resources
```

### MOC Management
```bash
# List MOCs
gtd-brain-moc list

# View MOC
gtd-brain-moc view "Topic"

# Create MOC
gtd-brain-moc create "Topic"
```

### Deep Analysis
```python
# Find connections
find_connections(scope="second_brain")

# Generate insights
generate_insights(focus="knowledge_connections")
```

---

## Workflow Summary

```
Knowledge Discovery Session Workflow
│
├─ 1. Select Starting Point
│   ├─ Specific note
│   ├─ Topic
│   └─ Question
│
├─ 2. Discover Connections for Note
│   └─ gtd-brain-discover <note-path>
│
├─ 3. Review Existing Connections
│   └─ Check what's already connected
│
├─ 4. Create New Connections
│   └─ gtd-brain-connect create
│
├─ 5. Search for Related Topics
│   ├─ gtd-brain search
│   └─ gtd-brain find
│
├─ 6. Identify Knowledge Gaps
│   └─ Find missing notes/connections
│
├─ 7. Create Missing Notes
│   └─ gtd-brain create
│
├─ 8. Review MOCs for Topic
│   ├─ gtd-brain-moc list
│   └─ Organize in MOC if needed
│
├─ 9. Identify Patterns
│   └─ See patterns across knowledge
│
├─ 10. Request Deep Analysis
│    ├─ find_connections()
│    └─ generate_insights()
│
├─ 11. Build Knowledge Network
│    └─ Strengthen connections
│
└─ 12. Document Discoveries
    └─ Record insights and connections
```

---

Remember: Knowledge discovery is about building understanding through connections. Follow your curiosity, create meaningful connections, identify patterns, and fill knowledge gaps. A well-connected knowledge base is more valuable than isolated notes.
