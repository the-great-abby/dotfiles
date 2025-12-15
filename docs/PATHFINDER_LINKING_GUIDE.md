# Pathfinder Kingmaker - Adding Links Guide

## 🎯 Quick Answer

**No, you don't need to edit source `.txt` files before importing!**

Add links **after** importing by editing the markdown files.

## 📝 Workflow

### Step 1: Import (No Editing Needed)

```bash
# Import your session write-ups as-is
gtd-brain-import-pathfinder import
```

Your source `.txt` files stay unchanged. The script creates markdown copies.

### Step 2: Create Atomic Notes

```bash
# Create notes for key concepts
zet "Haps - Bandit Leader"
zet "Oleg's Trading Post"
zet "Stag Lord"
```

### Step 3: Add Links to Imported Markdown

Edit the imported markdown files (not the source `.txt` files) to add links.

## 🔗 Two Ways to Add Links

### Method 1: Links Section (Easiest)

Each imported session has a "Links" section at the bottom. Edit it:

```markdown
## Links

- Related sessions: [[Session 1]], [[Session 3]]
- Related locations: [[Oleg's Trading Post]], [[Stag Lord's Fort]]
- Related NPCs: [[Haps - Bandit Leader]], [[Kressel]]
```

### Method 2: Embedded in Narrative

Add links directly in the "Session Summary" text:

```markdown
## Session Summary

The group spent time asking questions and building fortifications against the coming [[Bandits]].
Pit traps were constructed under the existing ladders, the wagon was placed strategically.
Led by [[Haps - Bandit Leader]], the bandit group seemed nonplused as they rode up to [[Oleg's Trading Post]].
```

### Method 3: Template Sections

Fill in the template sections with links:

```markdown
## Important NPCs

- [[Haps - Bandit Leader]] - Led the bandit attack on Oleg's Trading Post
- [[Kressel]] - Stag Lord's right hand woman, runs the local bandit camp
- [[Bokken]] - Halfling alchemist to the southeast, friend of Oleg

## Locations Visited

- [[Oleg's Trading Post]] - Where the bandit ambush occurred
- [[Stag Lord's Fort]] - Main base to the south, a week's ride away
```

## 🛠️ Using Command-Line Tools

You can also use `zet-link` to create bidirectional links:

```bash
# Link atomic note to session
zet-link link \
  ~/Documents/obsidian/Second\ Brain/Zettelkasten/202501011200-haps-bandit-leader.md \
  ~/Documents/obsidian/Second\ Brain/Resources/Reference/Pathfinder\ Kingmaker/Session\ 2.md
```

## 📍 Where Files Are Located

- **Source files** (don't edit): `~/Documents/pathfinder - kingmaker/*.txt`
- **Imported markdown** (edit these): `~/Documents/obsidian/Second Brain/Resources/Reference/Pathfinder Kingmaker/*.md`

## ✅ Recommended Workflow

1. Write session summary in plain text (no links)
2. Import: `gtd-brain-import-pathfinder import`
3. Create atomic notes: `zet "NPC Name"`
4. Edit imported markdown file to add `[[links]]`
5. Update MOC: `gtd-brain-import-pathfinder moc`

## 💡 Tips

- **Use Obsidian** - It has great autocomplete for `[[links]]`
- **Start with Links section** - Easier than embedding in narrative
- **Link as you read** - When reviewing sessions, add links to related concepts
- **Don't over-link** - Only link to important, reusable concepts

## 🔄 Re-importing

If you need to re-import (maybe you edited the source file):

```bash
# Force re-import (overwrites existing markdown)
gtd-brain-import-pathfinder import --force
```

**Warning:** This will overwrite your links! Only use if you need to update the content.

## 📚 Example: Complete Linking Workflow

```bash
# 1. Import sessions
gtd-brain-import-pathfinder import

# 2. Create atomic notes
zet "Haps - Bandit Leader"
zet "Oleg's Trading Post"
zet "Stag Lord"
zet "Kressel"
zet "Bokken"

# 3. Edit Session 2.md and add:
#    - Links in the Links section
#    - Links in Important NPCs section
#    - Links embedded in narrative if helpful

# 4. Update MOC
gtd-brain-import-pathfinder moc
```

Your links will create a knowledge graph connecting sessions, NPCs, locations, and events!
