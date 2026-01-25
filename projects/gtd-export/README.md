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
├── EXPORT_GUIDE.md           # Detailed export usage guide
├── README_TEMPLATE.md        # README template for new repository
└── scripts/
    ├── export-all.sh         # Complete export (recommended)
    ├── export-gtd.sh         # File copying only
    └── update-paths.sh       # Path updates only
```

## Quick Start

### Complete Export (Recommended)

Run the complete export with automatic path updates:

```bash
cd projects/gtd-export/scripts
./export-all.sh
```

This will:
1. Copy all GTD files to `~/code/gtd-organization-system`
2. Automatically update all hardcoded paths
3. Create the complete directory structure

### Step-by-Step Export

If you prefer to do it step by step:

1. **Review the Plan**: Read `EXPORT_PLAN.md` to understand the overall strategy
2. **Check File Inventory**: Review `FILE_INVENTORY.md` to see all files that will be exported
3. **Understand Dependencies**: Read `DEPENDENCIES.md` to understand external service requirements
4. **Export Files**: Run `./scripts/export-gtd.sh` to copy all files
5. **Update Paths**: Run `./scripts/update-paths.sh` to update all hardcoded paths

### Custom Export Location

To export to a different location:

```bash
export EXPORT_ROOT="$HOME/code/my-gtd-system"
./scripts/export-all.sh
```

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

## Export Scripts

### `export-all.sh` (Recommended)

Complete export with automatic path updates. This is the easiest way to export everything.

**Features**:
- Runs both export and path update in sequence
- Creates directory structure
- Copies all GTD files
- Automatically updates all hardcoded paths
- Provides progress feedback
- Error handling

**Usage**:
```bash
# Default export location
./scripts/export-all.sh

# Custom export location
EXPORT_ROOT=/path/to/export ./scripts/export-all.sh
```

### `export-gtd.sh`

File copying only. Use this if you want to review files before updating paths.

**Features**:
- Creates directory structure
- Copies all GTD files
- Preserves directory structure
- Provides progress feedback
- Error handling

**Usage**:
```bash
./scripts/export-gtd.sh
```

### `update-paths.sh`

Path updates only. Run this after `export-gtd.sh` if you didn't use `export-all.sh`.

**Features**:
- Updates all hardcoded paths in exported files
- Handles shell scripts, Python files, config files, documentation
- Creates backups before updating
- Provides progress feedback

**Usage**:
```bash
./scripts/update-paths.sh
```

**Environment Variables**:
- `EXPORT_ROOT` - New repository path (default: `~/code/gtd-organization-system`)
- `OLD_DOTFILES_PATH` - Old dotfiles path (default: `~/code/dotfiles`)
- `OLD_PERSONAL_PATH` - Old personal dotfiles path (default: `~/code/personal/dotfiles`)

For detailed usage instructions, see `EXPORT_GUIDE.md`.

## Next Steps

1. ✅ Create export plan
2. ✅ Create file inventory
3. ✅ Create dependencies documentation
4. ✅ Create export scripts
5. ✅ Create path update script
6. ✅ Create README template
7. ✅ Create export guide
8. ⏳ Test export scripts
9. ⏳ Create new repository
10. ⏳ Perform export
11. ⏳ Test exported system
12. ⏳ Document migration process

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
