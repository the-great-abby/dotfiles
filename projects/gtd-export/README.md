# GTD System Export Project

This directory contains the planning and tools for exporting the GTD (Getting Things Done) organization system from the dotfiles repository into a standalone repository.

## Overview

The GTD system has grown significantly and would benefit from being in its own repository. This export project prepares for that migration while maintaining all functionality.

## Project Structure

```
projects/gtd-export/
├── README.md                 # This file
├── EXPORT_PLAN.md            # Comprehensive export plan
├── FILE_INVENTORY.md         # Complete file inventory
├── MIGRATION_CHECKLIST.md    # Step-by-step migration checklist
├── DEPENDENCIES.md           # External dependencies documentation
└── scripts/
    └── export-gtd.sh         # Automated export script
```

## Quick Start

### 1. Review the Plan

Read `EXPORT_PLAN.md` to understand the overall strategy and approach.

### 2. Check File Inventory

Review `FILE_INVENTORY.md` to see all files that will be exported.

### 3. Understand Dependencies

Read `DEPENDENCIES.md` to understand external service requirements.

### 4. Run Export Script

```bash
cd projects/gtd-export
./scripts/export-gtd.sh
```

This will export all GTD files to `~/code/gtd-organization-system` (or set `EXPORT_ROOT` environment variable).

## Status

- **Phase**: Planning/Preparation
- **Status**: 🟡 In Progress
- **Started**: 2026-01-20

## Documents

### EXPORT_PLAN.md

Comprehensive plan covering:
- Repository structure
- File inventory
- Dependencies
- Migration checklist
- Path updates required
- Integration points

### FILE_INVENTORY.md

Complete catalog of:
- Core scripts (~150+ files)
- Configuration files (~20+ files)
- MCP server files (~30+ files)
- Documentation (~50+ files)
- Tests (~10+ files)
- Launchd plists (~5 files)

### MIGRATION_CHECKLIST.md

Step-by-step checklist for:
- Pre-migration preparation
- File copying
- Path updates
- Configuration updates
- Testing
- Cleanup

### DEPENDENCIES.md

Documentation of:
- External service repositories
- System dependencies
- AI/LLM backends
- Data directories
- Configuration requirements

## Export Script

The `scripts/export-gtd.sh` script automates the export process:

**Features**:
- Creates directory structure
- Copies all GTD files
- Preserves directory structure
- Provides progress feedback
- Error handling

**Usage**:
```bash
# Default export location
./scripts/export-gtd.sh

# Custom export location
EXPORT_ROOT=/path/to/export ./scripts/export-gtd.sh
```

## Next Steps

1. ✅ Create export plan
2. ✅ Create file inventory
3. ✅ Create dependencies documentation
4. ✅ Create export script
5. ⏳ Test export script
6. ⏳ Create new repository
7. ⏳ Perform export
8. ⏳ Update paths and references
9. ⏳ Test exported system
10. ⏳ Document migration process

## Notes

- Original files remain in dotfiles until migration is verified
- Export is non-destructive (copies, doesn't move)
- All paths need updating after export
- External dependencies must be documented
- Installation process needs to be straightforward

## Questions & Decisions

See `EXPORT_PLAN.md` for open questions and decisions needed.

## Contributing

This is a planning/documentation project. Changes should be discussed before implementation.

## License

TBD - Will match the license of the new repository.
