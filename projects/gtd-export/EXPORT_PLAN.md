# GTD System Export Plan

## Overview

This document outlines the plan to export the GTD (Getting Things Done) organization system from the dotfiles repository into a standalone repository. The goal is to prepare the GTD system for eventual removal from this repository while maintaining all functionality.

## Export Status

- **Status**: 🟡 In Progress
- **Started**: 2026-01-20
- **Target Completion**: TBD

## Repository Structure

### Proposed New Repository: `gtd-organization-system`

```
gtd-organization-system/
├── README.md
├── LICENSE
├── .gitignore
├── Makefile
├── bin/                    # All gtd-* scripts
├── zsh/                    # GTD config files and functions
├── mcp/                    # MCP server and workers
├── docs/                   # GTD documentation
├── web/                    # Web interface (if applicable)
├── tests/                  # GTD-specific tests
├── launchd/                # macOS launchd plists
├── scripts/                # Export/migration scripts
└── projects/               # Export documentation
```

## File Inventory

### 1. Core Scripts (`bin/`)

All scripts starting with `gtd-` or containing `gtd` in their name:

- `gtd-wizard*` - Main wizard scripts
- `gtd-*` - All GTD command scripts
- Helper scripts that are GTD-specific

**Count**: ~150+ files

### 2. Configuration Files (`zsh/`)

- `.gtd_config*` - All GTD configuration files
- `gtd-aliases.zsh` - GTD aliases
- `functions/gtd_*.py` - GTD Python functions
- `functions/gtd_*.sh` - GTD shell functions
- `quizzes/` - GTD quiz files
- `com.abby.gtd.*.plist` - macOS launchd plists

**Count**: ~20+ files

### 3. MCP Server (`mcp/`)

- `gtd_*.py` - All GTD MCP workers and server
- `gtd_skills.py` - Skills system
- `skills/` - All GTD skills
- `requirements.txt` - Python dependencies
- `claude_gtd_client.py` - Claude integration
- `claude_ollama_bridge.py` - Ollama bridge

**Count**: ~30+ files

### 4. Documentation (`docs/`)

All documentation files related to GTD:

- `GTD_*.md` - GTD guides
- `*GTD*.md` - GTD-related docs
- `architecture/gtd_*.md` - Architecture docs
- `mcp_notes/` - MCP-related notes

**Count**: ~50+ files

### 5. Web Interface (`web/`)

- GTD-specific web components
- API endpoints
- Frontend components

**Count**: TBD

### 6. Tests (`tests/`)

- `test_gtd_*.py` - Python tests
- `test_gtd_*.sh` - Shell script tests

**Count**: ~10+ files

### 7. Launchd (`launchd/`)

- `com.gtd.*.plist` - macOS launchd configurations

**Count**: ~5 files

## Dependencies

### External Services

1. **PostgreSQL with pgvector**
   - Location: External repository (`postgres_databases`)
   - Purpose: Vector database for semantic search
   - Connection: Via `.gtd_config_database`

2. **RabbitMQ**
   - Location: External repository (`rabbitmq`)
   - Purpose: Message queue for async processing
   - Connection: Via `.gtd_config_database`

3. **Ollama/LM Studio**
   - Purpose: AI/LLM backend
   - Configuration: Via `.gtd_config` and `.gtd_config_ai`

### System Dependencies

1. **Python 3.11+**
   - Required for MCP server and workers
   - Virtual environment in `mcp/venv/`

2. **Bash 3.2+**
   - macOS compatibility requirement
   - All scripts must be bash 3.2 compatible

3. **Zsh**
   - For interactive shell integration
   - Aliases and functions

4. **Kubernetes** (optional)
   - For deploying external services
   - NodePort configuration

### Data Directories

1. **`~/Documents/gtd/`**
   - Main GTD data directory
   - Contains: inbox, projects, areas, tasks, etc.

2. **`~/Documents/daily_logs/`**
   - Daily log entries
   - Format: `YYYY-MM-DD.txt`

3. **`~/.gtd_personalization.toon`**
   - Personalization data
   - TOON format

## Migration Checklist

### Phase 1: Preparation ✅

- [x] Create export plan document
- [x] Inventory all GTD files
- [ ] Document dependencies
- [ ] Create export script
- [ ] Test export in isolated location

### Phase 2: Export

- [ ] Create new repository structure
- [ ] Copy all GTD files
- [ ] Update paths and references
- [ ] Create new README.md
- [ ] Create installation guide
- [ ] Create migration guide

### Phase 3: Update References

- [ ] Update all hardcoded paths
- [ ] Update configuration file paths
- [ ] Update Makefile references
- [ ] Update documentation links
- [ ] Update test paths

### Phase 4: Testing

- [ ] Test all core commands
- [ ] Test wizard functionality
- [ ] Test MCP server
- [ ] Test workers
- [ ] Test integrations (RabbitMQ, PostgreSQL)
- [ ] Test web interface (if applicable)

### Phase 5: Cleanup (Future)

- [ ] Remove GTD files from dotfiles repo
- [ ] Update dotfiles README
- [ ] Update dotfiles Makefile
- [ ] Archive or remove GTD references

## Path Updates Required

### Hardcoded Paths to Update

1. **Script paths**:
   - `$HOME/code/dotfiles/bin/` → `$HOME/code/gtd-organization-system/bin/`
   - `$HOME/code/dotfiles/zsh/` → `$HOME/code/gtd-organization-system/zsh/`
   - `$HOME/code/dotfiles/mcp/` → `$HOME/code/gtd-organization-system/mcp/`

2. **Configuration paths**:
   - Update all references in scripts
   - Update `.gtd_config*` file paths
   - Update function loading paths

3. **Documentation paths**:
   - Update all internal links
   - Update example paths in docs

## Integration Points

### Dotfiles Integration (to be removed)

1. **Makefile targets**
   - All `gtd-*` targets
   - Worker management targets
   - Status targets

2. **Zsh configuration**
   - GTD aliases loading
   - GTD function loading
   - GTD config sourcing

3. **Shell PATH**
   - `bin/` directory in PATH
   - Function paths

## Export Script

See `scripts/export-gtd.sh` for automated export script.

## Next Steps

1. ✅ Create export plan (this document)
2. ⏳ Create file inventory
3. ⏳ Create export script
4. ⏳ Test export process
5. ⏳ Create new repository
6. ⏳ Perform export
7. ⏳ Update all references
8. ⏳ Test exported system
9. ⏳ Document migration process

## Notes

- The export should maintain all functionality
- External service dependencies should be documented
- Installation process should be straightforward
- Migration from dotfiles should be reversible initially

## Questions to Resolve

1. Should the web interface be included?
2. Should tests be included?
3. What license should the new repository use?
4. Should we maintain git history?
5. How to handle shared utilities (e.g., `gtd-common.sh`)?
