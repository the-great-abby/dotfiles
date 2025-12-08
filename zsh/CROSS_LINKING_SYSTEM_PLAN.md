# Cross-Linking System Implementation Plan

## Overview

This document outlines the comprehensive linking system that allows items to be attached/linked across the GTD system.

## Current State

### ✅ Already Implemented:
- **Notes on Areas** - Notes can be added to areas (notes/ subdirectory)
- **Notes on Tasks** - Notes can be added to tasks (notes/ subdirectory)
- **Tasks on Projects** - Tasks can be moved/linked to projects
- **Projects on Areas** - Projects can be moved/linked to areas
- **Notes on MOCs** - Notes can be added to MOCs (via gtd-brain-moc add)

## Implementation Plan

### Phase 1: Notes Linking
1. ✅ Notes on Tasks (DONE)
2. ✅ Notes on Areas (DONE)
3. 🔄 **Notes on Projects** (IN PROGRESS)
   - Create `add_note_to_project()` function in `gtd-project`
   - Add wizard option "Add note to project"
   - Create notes/ subdirectory in project directory
   - Link notes in project README.md

### Phase 2: Task Linking
1. ✅ Tasks on Projects (DONE)
2. **Tasks on Areas** (NEEDED)
   - Add wizard option "Add task to area" (functionality exists in gtd-area)
3. **Tasks on MOCs** (NEEDED)
   - Create function to link tasks to MOC Projects section
   - Add wizard option

### Phase 3: Project Linking
1. ✅ Projects on Areas (DONE)
2. **Projects on MOCs** (NEEDED)
   - Create function to link projects to MOC Projects section
   - Add wizard option

### Phase 4: MOC Linking
1. **MOCs on MOCs** (NEEDED)
   - Create function to link MOCs in Related MOCs section
   - Add wizard option

## Implementation Details

### Notes on Projects
- Structure: `PROJECTS_PATH/project-name/notes/TIMESTAMP-note-title.md`
- Link format: `[[Note Title]] (notes/filename.md)` in project README.md
- Similar to areas/tasks notes implementation

### Tasks on Areas
- Use existing `gtd-area add-task` functionality
- Add wizard menu option in area_wizard()

### Tasks on MOCs
- Link task file to MOC in Projects section
- Format: `[[Task Description]]` linking to task file path

### Projects on MOCs
- Link project README.md to MOC in Projects section
- Format: `[[Project Name]]` linking to project README

### MOCs on MOCs
- Link MOC file to Related MOCs section
- Format: `[[MOC - Topic]]` linking to MOC file

## File Structure After Implementation

```
Projects/
  project-name/
    README.md
    notes/
      TIMESTAMP-note-title.md
    TIMESTAMP-task.md

Tasks/
  TASK-ID/
    notes/
      TIMESTAMP-note-title.md
  TASK-ID.md

Areas/
  area-name/
    notes/
      TIMESTAMP-note-title.md
  area-name.md

MOCs/
  MOC - Topic.md  (can link to other MOCs in Related MOCs section)
```

