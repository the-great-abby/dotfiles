# Cross-Linking System Implementation Status

## Overview

This document tracks the implementation of comprehensive cross-linking functionality across the GTD system, allowing items to be attached/linked to each other through the wizard interface.

## Requested Features

### 1. Notes can go on:
- ✅ Tasks (DONE)
- ✅ Areas (DONE)  
- ✅ Projects (IN PROGRESS - function added, wizard option added)
- 🔄 MOCs (functionality exists via gtd-brain-moc add, needs wizard enhancement)

### 2. Tasks can go on:
- ✅ Projects (DONE)
- 🔄 Areas (functionality exists in gtd-area add-task, needs wizard option)
- 🔄 MOCs (NEEDED)

### 3. Projects can go on:
- ✅ Areas (DONE)
- 🔄 MOCs (NEEDED)

### 4. MOCs can go on:
- 🔄 MOCs (NEEDED - link in Related MOCs section)

## Implementation Plan

### Phase 1: Notes on Projects ✅ (IN PROGRESS)
- [x] Add `add_note_to_project()` function to `gtd-project`
- [x] Add command handler for `add-note`
- [x] Add wizard menu option "Add note to project"
- [ ] Test and verify

### Phase 2: Tasks on Areas
- [ ] Add wizard option "Add task to area" in area_wizard()
- [ ] Use existing `gtd-area add-task` functionality

### Phase 3: Tasks on MOCs
- [ ] Create function to link task files to MOC Projects section
- [ ] Add wizard option in moc_wizard()

### Phase 4: Projects on MOCs
- [ ] Create function to link project README to MOC Projects section
- [ ] Add wizard option in moc_wizard()

### Phase 5: MOCs on MOCs
- [ ] Create function to link MOC in Related MOCs section
- [ ] Add wizard option in moc_wizard()

### Phase 6: Notes on MOCs (Wizard Enhancement)
- [ ] Enhance existing "Add note to MOC" option to show existing notes
- [ ] Similar to tasks/areas notes functionality

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
  MOC - Topic.md  (can link to other MOCs, tasks, projects, notes)
```

## Next Steps

1. Complete Phase 1 (Notes on Projects)
2. Implement Phase 2 (Tasks on Areas)
3. Implement Phase 3 (Tasks on MOCs)
4. Implement Phase 4 (Projects on MOCs)
5. Implement Phase 5 (MOCs on MOCs)
6. Enhance Phase 6 (Notes on MOCs wizard)

