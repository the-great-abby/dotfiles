# GTD System Export Guide

This guide explains how to export all GTD-related code from the dotfiles repository to a new standalone repository.

## Quick Start

To export everything in one go:

```bash
cd ~/code/dotfiles/projects/gtd-export/scripts
./export-all.sh
```

This will:
1. Copy all GTD files to `~/code/gtd-organization-system` (or set `EXPORT_ROOT` env var)
2. Update all hardcoded paths automatically
3. Create the complete directory structure

## Export Scripts

### 1. `export-all.sh` (Recommended)

**Complete export with path updates**

```bash
./export-all.sh
```

This runs both `export-gtd.sh` and `update-paths.sh` in sequence.

**Environment variables:**
- `EXPORT_ROOT` - Destination directory (default: `~/code/gtd-organization-system`)

### 2. `export-gtd.sh`

**File copying only**

```bash
./export-gtd.sh
```

Exports all GTD files but does not update paths. Use this if you want to review files before updating paths.

**What it exports:**
- All `bin/gtd-*` scripts
- All `bin/gtd_*` helper scripts
- `bin/gtd`, `bin/gtd-cli`, `bin/gtd-runbook*`
- All `zsh/.gtd_config*` files
- All `zsh/functions/gtd_*` files
- All `mcp/gtd_*` files and skills
- All GTD documentation
- All GTD tests
- Web interface (backend, frontend, configs)
- Launchd plists
- Tmux configuration

### 3. `extract-makefile-targets.py`

**Makefile target extraction**

```bash
python3 ./scripts/extract-makefile-targets.py
```

Extracts all GTD-related Makefile targets and creates a new Makefile for the exported repository. This is automatically run by `export-all.sh` and `export-gtd.sh`.

**What it extracts:**
- All `gtd-*` command targets
- Worker management targets (`worker-*`)
- Filewatcher targets (`filewatcher-*`)
- Scheduler targets (`scheduler-*`)
- Vector database targets (`vector-db-*`)
- RabbitMQ targets
- NodePort verification targets
- GTD CLI targets
- Advice worker targets
- Claude integration targets
- External services targets

**Features:**
- Automatically identifies GTD-related targets
- Updates all paths to new repository location
- Preserves target structure and comments
- Creates a standalone Makefile

### 4. `update-paths.sh`

**Path updates only**

```bash
./update-paths.sh
```

Updates all hardcoded paths in exported files. Run this after `export-gtd.sh` if you didn't use `export-all.sh`.

**What it updates:**
- `$HOME/code/dotfiles` → `$HOME/code/gtd-organization-system`
- `$HOME/code/personal/dotfiles` → `$HOME/code/gtd-organization-system`
- All references in shell scripts, Python files, config files, documentation

**Environment variables:**
- `EXPORT_ROOT` - New repository path (default: `~/code/gtd-organization-system`)
- `OLD_DOTFILES_PATH` - Old dotfiles path (default: `~/code/dotfiles`)
- `OLD_PERSONAL_PATH` - Old personal dotfiles path (default: `~/code/personal/dotfiles`)

## Custom Export Location

To export to a different location:

```bash
export EXPORT_ROOT="$HOME/code/my-gtd-system"
./export-all.sh
```

## What Gets Exported

### Core Scripts (`bin/`)
- All `gtd-*` commands (~150+ files)
- Helper scripts (`gtd-common.sh`, `gtd-select-helper.sh`)
- Standalone commands (`gtd`, `gtd-cli`, `gtd-runbook*`)
- Wizard scripts (`gtd-wizard*`)

### Configuration (`zsh/`)
- All `.gtd_config*` files
- `gtd-aliases.zsh`
- All `functions/gtd_*.py` and `functions/gtd_*.sh`
- Quiz files
- Launchd plists

### MCP Server (`mcp/`)
- All `gtd_*.py` workers
- Skills directory
- Runbooks directory
- Configuration files
- Requirements

### Documentation (`docs/`)
- All `GTD_*.md` files
- All `*GTD*.md` files
- Architecture documentation
- MCP notes

### Web Interface (`web/`)
- Backend (FastAPI)
- Frontend (Svelte)
- Nginx configuration
- Systemd service files
- Launchd plists
- Deployment scripts

### Tests (`tests/`)
- All `test_gtd_*.py` files
- All `test_gtd_*.sh` files

### Other
- Launchd plists
- Tmux configuration
- **Makefile** - All GTD-related Makefile targets (automatically extracted)

## After Export

### 1. Review Exported Files

```bash
cd ~/code/gtd-organization-system
ls -la
```

### 2. Initialize Git Repository

```bash
cd ~/code/gtd-organization-system
git init
git add .
git commit -m "Initial export from dotfiles"
```

### 3. Create README

Copy the template:

```bash
cp ~/code/dotfiles/projects/gtd-export/README_TEMPLATE.md ~/code/gtd-organization-system/README.md
```

Then edit it with your specific information.

### 4. Test the System

```bash
# Test basic commands
gtd-wizard
gtd-status
gtd-capture "Test item"

# Test Makefile targets
make gtd-status
make worker-status
make gtd-wizard
```

### 5. Update Shell Integration

Update your `~/.zshrc`:

```bash
# Old (dotfiles)
# export PATH="$HOME/code/dotfiles/bin:$PATH"
# source "$HOME/code/dotfiles/zsh/gtd-aliases.zsh"

# New (gtd-organization-system)
export PATH="$HOME/code/gtd-organization-system/bin:$PATH"
source "$HOME/code/gtd-organization-system/zsh/gtd-aliases.zsh"
```

### 6. Update Configuration Files

Review and update:
- `zsh/.gtd_config*` - Update any remaining paths
- `web/backend/main.py` - Update GTD_BASE path
- Any other configuration files

## Troubleshooting

### Export Fails

**Problem**: Script fails with "Dotfiles root does not exist"

**Solution**: Make sure you're running from the correct location or set `DOTFILES_ROOT`:

```bash
export DOTFILES_ROOT="$HOME/code/dotfiles"
./export-gtd.sh
```

### Paths Not Updated

**Problem**: Some paths still reference old dotfiles location

**Solution**: 
1. Check if file is binary (won't be updated)
2. Manually update any remaining paths
3. Re-run `update-paths.sh` with correct `OLD_DOTFILES_PATH`

### Missing Files

**Problem**: Some GTD files not exported

**Solution**:
1. Check if files match the patterns in `export-gtd.sh`
2. Manually copy any missing files
3. Update the export script if needed

## File Count Summary

Expected file counts after export:

- **Core Scripts**: ~150+ files
- **Configuration**: ~20+ files
- **MCP Server**: ~30+ files
- **Documentation**: ~50+ files
- **Tests**: ~10+ files
- **Web Interface**: ~100+ files
- **Launchd**: ~5 files
- **Makefile**: 1 file (with ~50+ GTD targets)

**Total**: ~366+ files

## Next Steps

1. ✅ Export files (done)
2. ✅ Update paths (done)
3. ⏳ Create README.md
4. ⏳ Create installation guide
5. ⏳ Test all functionality
6. ⏳ Initialize git repository
7. ⏳ Push to remote repository
8. ⏳ Update dotfiles to remove GTD code (future)

## Notes

- The export preserves file structure
- All paths are automatically updated
- Binary files are skipped during path updates
- Backup files (`.bak`) are created during path updates but removed after
- The export does not modify the original dotfiles repository

## Support

For issues with the export process:
1. Check the script output for errors
2. Review the exported files
3. Check file permissions
4. Verify paths are correct
