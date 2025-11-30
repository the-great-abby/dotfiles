# GTD + Second Brain Integration Guide

This guide explains how to use your GTD system as a Second Brain, combining David Allen's Getting Things Done methodology with Tiago Forte's Building a Second Brain approach.

## Overview

Your GTD system now includes full Second Brain capabilities:

- **PARA Method**: Organize notes into Projects, Areas, Resources, and Archives
- **Progressive Summarization**: Build knowledge through layers of notes
- **Bidirectional Linking**: Connect GTD items and Second Brain notes
- **Knowledge Discovery**: Find connections and insights across your knowledge base
- **Automatic Syncing**: Keep GTD and Second Brain in sync

## Core Commands

### `gtd-brain` - Main Second Brain Operations

The primary command for Second Brain operations.

#### Create a Note
```bash
# Create a note in Resources (default)
gtd-brain create "Productivity Tips"

# Create a note in a specific PARA category
gtd-brain create "My Project" Projects
gtd-brain create "Health Goals" Areas
gtd-brain create "Research Notes" Resources
```

#### Link GTD Items to Second Brain
```bash
# Link a GTD project to a Second Brain note
gtd-brain link ~/Documents/gtd/1-projects/myproject.md ~/Documents/Second\ Brain/Projects/myproject.md

# Link a task to a resource note
gtd-brain link ~/Documents/gtd/tasks/task.md ~/Documents/Second\ Brain/Resources/related-note.md
```

#### Progressive Summarization
```bash
# Level 1: Highlight key points (manual)
gtd-brain summarize ~/Documents/Second\ Brain/Resources/note.md 1

# Level 2: Create summary section
gtd-brain summarize ~/Documents/Second\ Brain/Resources/note.md 2

# Level 3: Distill to core insights
gtd-brain summarize ~/Documents/Second\ Brain/Resources/note.md 3
```

#### Discover Connections
```bash
# Find related notes, tags, and links
gtd-brain discover ~/Documents/Second\ Brain/Resources/note.md
```

#### Move Notes Between Categories
```bash
# Move a note from Resources to Projects
gtd-brain move ~/Documents/Second\ Brain/Resources/note.md Projects

# Archive a note
gtd-brain archive ~/Documents/Second\ Brain/Projects/old-project.md
```

#### Search Your Second Brain
```bash
# Search all notes
gtd-brain search "productivity"

# Search in a specific category
gtd-brain search "productivity" Projects

# Find notes by term
gtd-brain find "GTD"
```

#### List Notes
```bash
# List all notes by category
gtd-brain list

# List notes in a specific category
gtd-brain list Projects
gtd-brain list Areas
gtd-brain list Resources
gtd-brain list Archives
```

### `gtd-brain-sync` - Sync GTD and Second Brain

Automatically creates bidirectional links between GTD items and Second Brain notes.

```bash
# Full sync (projects, areas, references)
gtd-brain-sync

# Sync only projects
gtd-brain-sync projects

# Sync only areas
gtd-brain-sync areas

# Sync only references
gtd-brain-sync references
```

This command:
- Creates Second Brain notes for GTD projects and areas
- Links GTD items to corresponding Second Brain notes
- Maintains bidirectional links (if enabled in config)

### `gtd-brain-discover` - Knowledge Discovery

Find connections and insights across your knowledge base.

#### Find by Tag
```bash
# Find all notes with a specific tag
gtd-brain-discover tag productivity
gtd-brain-discover tag #gtd
```

#### Find Orphaned Notes
```bash
# Find notes with no connections
gtd-brain-discover orphan
```

#### Find Similar Notes
```bash
# Find notes similar to a given note
gtd-brain-discover similar ~/Documents/Second\ Brain/Resources/note.md

# With custom threshold (minimum matching terms)
gtd-brain-discover similar ~/Documents/Second\ Brain/Resources/note.md 5
```

#### Find by Date
```bash
# Find notes from a date range
gtd-brain-discover date 2025-01-01 2025-12-31

# Find notes from a specific date onwards
gtd-brain-discover date 2025-11-01
```

#### Show Connection Graph
```bash
# See all connections for a note
gtd-brain-discover connections ~/Documents/Second\ Brain/Projects/myproject.md
```

#### Statistics
```bash
# Show Second Brain statistics
gtd-brain-discover stats
```

## Workflow Examples

### 1. Capture and Process with Second Brain

```bash
# 1. Capture a fleeting note
gtd-capture "Interesting article about productivity"

# 2. Process it
gtd-process

# 3. If it becomes a reference, create a Second Brain note
gtd-brain create "Productivity Article Notes" Resources

# 4. Link the GTD reference to the Second Brain note
gtd-brain link ~/Documents/gtd/3-reference/article.md ~/Documents/Second\ Brain/Resources/productivity-article-notes.md
```

### 2. Project Workflow

```bash
# 1. Create a GTD project
gtd-project create "Website Redesign"

# 2. Sync to Second Brain (creates note in Projects)
gtd-brain-sync projects

# 3. Add project notes to the Second Brain note
# (Edit the file directly or use your editor)

# 4. Discover connections
gtd-brain-discover connections ~/Documents/Second\ Brain/Projects/website-redesign.md
```

### 3. Progressive Summarization Workflow

```bash
# 1. Create a resource note
gtd-brain create "GTD Best Practices" Resources

# 2. Add content (manually or via capture)

# 3. Level 1: Highlight key points (manual)
gtd-brain summarize ~/Documents/Second\ Brain/Resources/gtd-best-practices.md 1
# Then manually highlight important sentences

# 4. Level 2: Create summary
gtd-brain summarize ~/Documents/Second\ Brain/Resources/gtd-best-practices.md 2
# Add summary to the file

# 5. Level 3: Distill insights
gtd-brain summarize ~/Documents/Second\ Brain/Resources/gtd-best-practices.md 3
# Add core insights to the file
```

### 4. Knowledge Discovery Workflow

```bash
# 1. Find all notes about a topic
gtd-brain-discover tag productivity

# 2. See connections for a specific note
gtd-brain-discover connections ~/Documents/Second\ Brain/Resources/note.md

# 3. Find similar notes
gtd-brain-discover similar ~/Documents/Second\ Brain/Resources/note.md

# 4. Check for orphaned notes
gtd-brain-discover orphan
```

## PARA Method Integration

The PARA method organizes information into four categories:

### Projects
- **GTD**: Active projects with end dates
- **Second Brain**: Project notes, plans, and documentation
- **Sync**: GTD projects automatically sync to Second Brain Projects

### Areas
- **GTD**: Ongoing areas of responsibility
- **Second Brain**: Area notes, goals, and maintenance
- **Sync**: GTD areas automatically sync to Second Brain Areas

### Resources
- **GTD**: Reference materials
- **Second Brain**: Knowledge base, articles, research
- **Usage**: Create resource notes for things you want to learn or reference

### Archives
- **GTD**: Completed/archived items
- **Second Brain**: Archived notes and completed projects
- **Usage**: Move notes here when projects complete or they're no longer active

## Linking System

### Wiki-Style Links
The system uses wiki-style links: `[[note name]]`

### Bidirectional Links
When enabled in config (`GTD_BIDIRECTIONAL_LINKS="true"`):
- GTD items link to Second Brain notes
- Second Brain notes link back to GTD items
- Both stay in sync automatically

### Link Format
Links can be:
- **Wiki style**: `[[note name]]` → `note-name.md`
- **Markdown style**: `[text](link)` (if configured)
- **Plain text**: Just the note name (if configured)

## Configuration

Key settings in `.gtd_config`:

```bash
# Second Brain directory
SECOND_BRAIN="$HOME/Documents/Second Brain"

# Auto-link GTD items
GTD_AUTO_LINK_BRAIN="true"

# Bidirectional links
GTD_BIDIRECTIONAL_LINKS="true"

# Link format
GTD_LINK_FORMAT="wiki"  # wiki, markdown, plain
```

## Tips and Best Practices

1. **Regular Syncing**: Run `gtd-brain-sync` regularly to keep systems in sync
2. **Progressive Summarization**: Use the 3-level system to build knowledge over time
3. **Tag Everything**: Use tags (`#tag`) to enable better discovery
4. **Link Liberally**: Create links between related notes
5. **Review Orphans**: Periodically check for orphaned notes and connect them
6. **Archive Regularly**: Move completed projects to Archives
7. **Discover Connections**: Use discovery commands to find insights

## Integration with Daily Logs

Your daily logs can reference Second Brain notes:

```bash
# In your daily log
addInfoToDailyLog "Working on [[website-redesign]] project"
```

The system will recognize the link and you can discover connections later.

## Next Steps

1. Run `gtd-brain-sync` to sync existing GTD items
2. Create your first Second Brain note: `gtd-brain create "My First Note" Resources`
3. Explore connections: `gtd-brain-discover stats`
4. Set up regular syncing in your workflow

## Troubleshooting

**Links not working?**
- Check that `GTD_BIDIRECTIONAL_LINKS="true"` in config
- Run `gtd-brain-sync` to create links

**Can't find notes?**
- Check the directory structure exists
- Use `gtd-brain list` to see all notes
- Use `gtd-brain search` to find by content

**Sync not working?**
- Ensure GTD directories exist
- Check file permissions
- Verify config paths are correct

