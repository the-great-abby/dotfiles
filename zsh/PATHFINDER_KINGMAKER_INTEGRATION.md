# Pathfinder Kingmaker Integration Guide

## 🎯 Overview

This guide explains how to integrate your Pathfinder Kingmaker session write-ups with your Zettelkasten, MOC (Map of Content), and Second Brain systems.

## 📁 Current Setup

Your session write-ups are stored in:
```
~/Documents/pathfinder - kingmaker/
```

These will be imported into your Second Brain at:
```
~/Documents/obsidian/Second Brain/Resources/Reference/Pathfinder Kingmaker/
```

## 🚀 Quick Start

### Step 1: Preview What Will Be Imported

```bash
# See what files will be imported (dry run)
gtd-brain-import-pathfinder import --dry-run
```

### Step 2: Import All Sessions

```bash
# Import all session write-ups
gtd-brain-import-pathfinder import
```

This will:
- Convert `.txt` files to markdown format
- Extract session numbers and dates
- Create structured markdown files with templates
- Add tags for easy organization
- **Skip files that have already been imported** (safe to run multiple times)

### Step 3: Create MOC (Map of Content)

```bash
# Create the Pathfinder Kingmaker MOC
gtd-brain-import-pathfinder moc
```

This creates a MOC that automatically organizes all your session notes.

## 📋 Detailed Workflow

### Importing Sessions

#### Import All Sessions at Once

```bash
# Import only new sessions (skips existing ones)
gtd-brain-import-pathfinder import

# Re-import all sessions (overwrites existing ones)
gtd-brain-import-pathfinder import --force
```

**Incremental Import Behavior:**
- By default, the script **skips files that have already been imported**
- This means you can safely run it multiple times as you add new session files
- Only new files will be imported; existing files remain unchanged
- Use `--force` if you want to re-import and overwrite existing files

#### Import a Single Session

```bash
gtd-brain-import-pathfinder session "message - pathfinder - session 2.txt"
```

#### List Available Files

```bash
gtd-brain-import-pathfinder list
```

### What Gets Created

Each imported session becomes a markdown file with:

- **Title**: Session number and date
- **Metadata**: Session number, date, import timestamp
- **Content**: Full session write-up
- **Sections**: 
  - Key Events
  - Important NPCs
  - Locations Visited
  - Loot & Rewards
  - Notes & Observations
  - Links (for connecting to other notes)
- **Tags**: `#pathfinder-kingmaker #session-X #rpg`

## 🗺️ Creating and Using the MOC

### Create the MOC

```bash
# Create the MOC
gtd-brain-moc create "Pathfinder Kingmaker" "Session write-ups and campaign notes"
```

### Add Sessions to MOC

```bash
# Auto-populate MOC from tags
gtd-brain-moc auto "Pathfinder Kingmaker" pathfinder-kingmaker
```

This automatically finds all notes tagged with `#pathfinder-kingmaker` and adds them to the MOC.

### View the MOC

```bash
# View the MOC
gtd-brain-moc view "Pathfinder Kingmaker"
```

### Manually Add Notes to MOC

```bash
# Add a specific note
gtd-brain-moc add "Pathfinder Kingmaker" \
  ~/Documents/obsidian/Second\ Brain/Resources/Reference/Pathfinder\ Kingmaker/Session\ 2.md
```

## 🔗 Adding Links to Session Notes

**You don't need to edit source `.txt` files before importing!** Add links after importing in the markdown files.

### Two Ways to Add Links

#### 1. Use the Links Section (Recommended)

Each imported session has a "Links" section at the bottom. Edit the markdown file to add links:

```markdown
## Links

- Related sessions: [[Session 1]], [[Session 3]]
- Related locations: [[Oleg's Trading Post]], [[Stag Lord's Fort]]
- Related NPCs: [[Haps - Bandit Leader]], [[Kressel]]
```

#### 2. Embed Links in the Narrative

You can also add links directly in the "Session Summary" text:

```markdown
## Session Summary

The group spent time asking questions and building fortifications against the coming [[Bandits]].
Pit traps were constructed under the existing ladders, the wagon was placed strategically.
Led by [[Haps - Bandit Leader]], the bandit group seemed nonplused as they rode up to [[Oleg's Trading Post]].
```

### Workflow for Adding Links

1. **Import sessions first** (don't edit source files):
   ```bash
   gtd-brain-import-pathfinder import
   ```

2. **Create atomic notes** for key concepts:
   ```bash
   zet "Haps - Bandit Leader"
   zet "Oleg's Trading Post"
   zet "Stag Lord"
   ```

3. **Edit the imported markdown files** to add links:
   - Open the session note in your editor
   - Add `[[links]]` in the Links section or embedded in text
   - Use Obsidian's autocomplete to find existing notes

4. **Or use command-line tools** to add links:
   ```bash
   # Link atomic note to session
   zet-link link \
     ~/Documents/obsidian/Second\ Brain/Zettelkasten/202501011200-haps-bandit-leader.md \
     ~/Documents/obsidian/Second\ Brain/Resources/Reference/Pathfinder\ Kingmaker/Session\ 2.md
   ```

## 🔗 Zettelkasten Integration

### Creating Atomic Notes from Sessions

Extract key concepts, NPCs, locations, and events as atomic Zettelkasten notes:

#### Create Notes for Key Concepts

**For batch creation (faster, no editor):**
```bash
# Use -n flag to skip opening editor (much faster for multiple notes)
zet -n "Haps - Bandit Leader"
zet -n "Oleg's Trading Post"
zet -n "Bandit Ambush at Trading Post"
```

**For single notes (opens in editor):**
```bash
# Opens in Neovim for immediate editing
zet "Haps - Bandit Leader"
```

#### Create Notes for Campaign Elements

```bash
# Fast batch creation (recommended for multiple notes)
zet -n "Stag Lord - Main Antagonist"
zet -n "Blue Skeleton Transformation"
zet -n "Kressel - Stag Lord's Right Hand"
zet -n "Bokken - Halfling Alchemist"
```

**Note:** The `-n` (or `--no-edit`) flag:
- Creates notes without opening Neovim (much faster)
- Skips AI connection suggestions (faster)
- Perfect for batch creating multiple notes
- You can edit them later in Obsidian or your editor

### Linking Zettelkasten Notes to Sessions

After creating atomic notes, link them to your session notes:

```bash
# Link a Zettelkasten note to a session
zet-link link \
  ~/Documents/obsidian/Second\ Brain/Zettelkasten/202501011200-haps-bandit-leader.md \
  ~/Documents/obsidian/Second\ Brain/Resources/Reference/Pathfinder\ Kingmaker/Session\ 2.md
```

### Linking Sessions to Zettelkasten Notes

Edit your session notes to add links in the template sections:

```markdown
## Important NPCs

- [[Haps - Bandit Leader]] - Led the bandit attack
- [[Kressel]] - Stag Lord's right hand woman
- [[Bokken]] - Halfling alchemist to the southeast

## Locations Visited

- [[Oleg's Trading Post]] - Where the bandit ambush occurred
- [[Stag Lord's Fort]] - Main base to the south
```

## 📚 Organizing Your Campaign Notes

### Structure Recommendations

```
Second Brain/
├── Resources/
│   └── Reference/
│       └── Pathfinder Kingmaker/
│           ├── Session 1.md
│           ├── Session 2.md
│           └── ...
├── MOCs/
│   └── MOC - Pathfinder Kingmaker.md
└── Zettelkasten/
    ├── 202501011200-haps-bandit-leader.md
    ├── 202501011201-olegs-trading-post.md
    └── ...
```

### Creating Additional Notes

#### NPC Notes

```bash
# Create detailed NPC note
gtd-brain create "Haps - Bandit Leader" Resources

# Then edit to add details from sessions
```

#### Location Notes

```bash
# Create location note
gtd-brain create "Oleg's Trading Post" Resources

# Link to relevant sessions
```

#### Campaign Timeline

```bash
# Create campaign timeline
gtd-brain create "Pathfinder Kingmaker - Campaign Timeline" Resources
```

## 🔄 Ongoing Workflow

### After Each Session

1. **Write your session summary** (as you normally do - plain text, no links needed)
2. **Import the session** (or all new sessions):
   ```bash
   # Import just this session
   gtd-brain-import-pathfinder session "your-session-file.txt"
   
   # Or import all new sessions at once (recommended)
   gtd-brain-import-pathfinder import
   ```
   The script will automatically skip any sessions that have already been imported.
   **No need to edit the source `.txt` file!**
3. **Create atomic notes** for new concepts:
   ```bash
   zet "New NPC Name"
   zet "New Location Name"
   ```
4. **Add links to the imported markdown file**:
   - Open the session note in your editor (Obsidian, VS Code, etc.)
   - Add `[[links]]` in the "Links" section or embedded in the narrative
   - Or use `zet-link` command to create bidirectional links
5. **Fill in template sections** (NPCs, Locations, Events):
   - Edit the markdown file to add details to the template sections
   - Add links to related atomic notes
6. **Update MOC** (if needed):
   ```bash
   gtd-brain-import-pathfinder moc
   # or
   gtd-brain-moc auto "Pathfinder Kingmaker" pathfinder-kingmaker
   ```

### Incremental Imports

The script is designed to be run multiple times safely:

- **First run**: Imports all 9 existing sessions
- **Later runs**: Only imports new session files you've added
- **Existing files**: Are never modified or overwritten (unless you use `--force`)

This means you can:
- Add new session files to the source directory
- Run `gtd-brain-import-pathfinder import` anytime
- Only new files will be processed

### Weekly Review

1. **Review session notes** for completeness
2. **Create missing atomic notes** for important concepts
3. **Link related notes** together
4. **Update MOC** with any new notes
5. **Create summary notes** for major story arcs

## 🎯 Best Practices

### For Session Notes

- ✅ **Don't edit source `.txt` files** - keep them as raw write-ups
- ✅ **Import first, then add links** - edit the imported markdown files
- ✅ Add links to atomic notes in the "Links" section
- ✅ Embed links in the narrative text if helpful
- ✅ Tag NPCs, locations, and events mentioned
- ✅ Fill in the template sections (Key Events, NPCs, etc.) after importing

### For Zettelkasten Notes

- ✅ One concept per note (one NPC, one location, one event)
- ✅ Link atomic notes to session notes
- ✅ Link related atomic notes together (NPCs to locations, events to NPCs)
- ✅ Use descriptive titles

### For MOC

- ✅ Let it auto-populate from tags
- ✅ Manually add important notes if needed
- ✅ Review monthly to ensure completeness
- ✅ Use it as your campaign index

## 🔍 Finding Information

### Search for Sessions

```bash
# Search Second Brain for Pathfinder content
gtd-brain search "Stag Lord"

# Or use Obsidian's search (if using Obsidian)
```

### View Campaign Overview

```bash
# View the MOC to see all sessions
gtd-brain-moc view "Pathfinder Kingmaker"
```

### Find Related Notes

```bash
# Discover connections
gtd-brain-discover ~/Documents/obsidian/Second\ Brain/Resources/Reference/Pathfinder\ Kingmaker/Session\ 2.md
```

## 📝 Example: Complete Integration

Here's a complete example workflow:

```bash
# 1. Import all sessions
gtd-brain-import-pathfinder import

# 2. Create MOC
gtd-brain-import-pathfinder moc

# 3. Create atomic notes for key concepts
zet "Haps - Bandit Leader"
zet "Stag Lord"
zet "Oleg's Trading Post"
zet "Blue Skeleton Transformation"
zet "Kressel"
zet "Bokken"

# 4. Link atomic notes to session 2
# (Edit Session 2.md and add [[links]])

# 5. View the MOC to see everything organized
gtd-brain-moc view "Pathfinder Kingmaker"
```

## 🛠️ Troubleshooting

### Files Not Found

If the import script can't find your files:

```bash
# Check source directory
ls ~/Documents/pathfinder\ -\ kingmaker/

# Override source directory
gtd-brain-import-pathfinder import --source "/path/to/your/files"
```

### MOC Not Updating

If sessions aren't appearing in the MOC:

```bash
# Check if notes have the right tag
grep -r "#pathfinder-kingmaker" ~/Documents/obsidian/Second\ Brain/Resources/Reference/Pathfinder\ Kingmaker/

# Manually add to MOC
gtd-brain-moc add "Pathfinder Kingmaker" <note-path>
```

### Session Numbers Not Extracted

If session numbers aren't being extracted correctly:

1. Check the filename format
2. Manually edit the imported note to fix the session number
3. The script tries to extract from patterns like "session 2", "session-2", etc.

## 🎮 Integration with GTD

### Create GTD Project

If Pathfinder Kingmaker is an active project:

```bash
# Create GTD project
gtd-project create "Pathfinder Kingmaker Campaign"

# Sync to Second Brain
gtd-brain-sync projects

# Link project to MOC
gtd-brain link \
  ~/Documents/gtd/1-projects/pathfinder-kingmaker-campaign.md \
  ~/Documents/obsidian/Second\ Brain/MOCs/MOC\ -\ Pathfinder\ Kingmaker.md
```

### Create Tasks from Sessions

After each session, you might create tasks:

```bash
# Create task to review session notes
gtd-capture "Review Session 2 notes and create atomic notes for new NPCs"

# Create task to update campaign timeline
gtd-capture "Update campaign timeline with Session 2 events"
```

## 📊 Summary

Your Pathfinder Kingmaker integration includes:

1. **Session Notes** → Imported as markdown in Resources/Reference
2. **MOC** → Organizes all sessions and related notes
3. **Zettelkasten Notes** → Atomic notes for NPCs, locations, events
4. **Links** → Connect sessions to atomic notes and vice versa
5. **Tags** → Easy searching and organization

This creates a knowledge graph where you can:
- Find any session quickly via MOC
- Trace NPCs across multiple sessions
- See connections between events and locations
- Build a comprehensive campaign reference

## 🚀 Next Steps

1. Run the import: `gtd-brain-import-pathfinder import`
2. Create the MOC: `gtd-brain-import-pathfinder moc`
3. Create atomic notes for key concepts from your sessions
4. Link everything together
5. Start using the MOC as your campaign index!
