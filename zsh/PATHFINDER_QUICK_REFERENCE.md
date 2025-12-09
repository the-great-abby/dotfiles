# Pathfinder Kingmaker - Quick Reference

## 🚀 Quick Start Commands

```bash
# 1. Preview what will be imported
gtd-brain-import-pathfinder import --dry-run

# 2. Import all new sessions (skips existing)
gtd-brain-import-pathfinder import

# 3. Create/Update MOC
gtd-brain-import-pathfinder moc

# 4. View MOC
gtd-brain-moc view "Pathfinder Kingmaker"
```

**Note:** The import command is safe to run multiple times - it only imports new files and skips existing ones.

## 📋 Common Tasks

### Import a New Session
```bash
gtd-brain-import-pathfinder session "your-session-file.txt"
```

**Note:** You don't need to edit source `.txt` files before importing. Add links after importing by editing the markdown files.

### Create Atomic Notes for Campaign Elements
```bash
zet "NPC Name"
zet "Location Name"
zet "Event Name"
```

### Add Links to Session Notes
```bash
# Option 1: Edit the markdown file directly (recommended)
# Open in Obsidian/editor and add [[links]] in the Links section

# Option 2: Use command-line tool
zet-link link <atomic-note> <session-note>
```

See `PATHFINDER_LINKING_GUIDE.md` for detailed linking instructions.

### Update MOC
```bash
gtd-brain-moc auto "Pathfinder Kingmaker" pathfinder-kingmaker
```

## 📁 File Locations

- **Source**: `~/Documents/pathfinder - kingmaker/`
- **Imported**: `~/Documents/obsidian/Second Brain/Resources/Reference/Pathfinder Kingmaker/`
- **MOC**: `~/Documents/obsidian/Second Brain/MOCs/MOC - Pathfinder Kingmaker.md`

## 🔗 Integration Points

1. **Session Notes** → Second Brain Resources
2. **MOC** → Organizes all sessions
3. **Zettelkasten** → Atomic notes for NPCs, locations, events
4. **Links** → Connect everything together

## 📖 Full Guide

See `PATHFINDER_KINGMAKER_INTEGRATION.md` for complete documentation.
