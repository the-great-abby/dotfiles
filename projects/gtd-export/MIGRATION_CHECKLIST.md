# GTD System Migration Checklist

This checklist tracks the migration of the GTD system from the dotfiles repository to a standalone repository.

## Pre-Migration

### Planning
- [x] Create export plan document
- [x] Create file inventory
- [x] Document dependencies
- [ ] Review and approve export plan
- [ ] Identify shared vs GTD-specific files
- [ ] Plan for backward compatibility

### Preparation
- [ ] Create new repository (`gtd-organization-system`)
- [ ] Set up repository structure
- [ ] Create initial README.md
- [ ] Create LICENSE file
- [ ] Create .gitignore
- [ ] Create export script
- [ ] Test export script in isolated location

## Export Phase

### File Copying
- [ ] Copy all `bin/gtd-*` scripts
- [ ] Copy all `zsh/.gtd_config*` files
- [ ] Copy all `zsh/functions/gtd_*` files
- [ ] Copy all `zsh/gtd-*` files
- [ ] Copy all `mcp/gtd_*` files
- [ ] Copy all `mcp/skills/` directory
- [ ] Copy GTD documentation from `docs/`
- [ ] Copy GTD tests from `tests/`
- [ ] Copy GTD launchd plists
- [ ] Copy GTD web interface files (if applicable)
- [ ] Copy Makefile GTD targets

### Path Updates
- [ ] Update all `$HOME/code/dotfiles` references
- [ ] Update `bin/` script paths
- [ ] Update `zsh/` config paths
- [ ] Update `mcp/` paths
- [ ] Update documentation paths
- [ ] Update test paths
- [ ] Update Makefile paths
- [ ] Update shebang lines if needed

### Configuration Updates
- [ ] Update `.gtd_config` file paths
- [ ] Update function loading paths
- [ ] Update alias definitions
- [ ] Update environment variable paths
- [ ] Update virtual environment paths
- [ ] Update external service references

## Integration Updates

### Shell Integration
- [ ] Update zshrc to load from new location
- [ ] Update PATH additions
- [ ] Update function autoload paths
- [ ] Update alias definitions
- [ ] Test shell integration

### Makefile Updates
- [ ] Create new Makefile for GTD system
- [ ] Move GTD targets to new Makefile
- [ ] Update paths in Makefile targets
- [ ] Remove GTD targets from dotfiles Makefile
- [ ] Test Makefile targets

### Documentation
- [ ] Update all internal documentation links
- [ ] Update installation instructions
- [ ] Update configuration examples
- [ ] Update path references in docs
- [ ] Create migration guide
- [ ] Create installation guide
- [ ] Update README.md

## Testing Phase

### Core Functionality
- [ ] Test `gtd-wizard` command
- [ ] Test capture functionality
- [ ] Test inbox processing
- [ ] Test task management
- [ ] Test project management
- [ ] Test area management
- [ ] Test review system
- [ ] Test daily logging
- [ ] Test calendar integration
- [ ] Test advice system

### Advanced Features
- [ ] Test MCP server
- [ ] Test all workers
- [ ] Test RabbitMQ integration
- [ ] Test PostgreSQL integration
- [ ] Test vector database
- [ ] Test AI/LLM integration
- [ ] Test web interface (if applicable)
- [ ] Test gamification system
- [ ] Test learning system

### Integration Testing
- [ ] Test external service connections
- [ ] Test worker communication
- [ ] Test queue processing
- [ ] Test database operations
- [ ] Test file operations
- [ ] Test notification system

## Cleanup Phase (Future)

### Dotfiles Repository
- [ ] Remove GTD scripts from `bin/`
- [ ] Remove GTD configs from `zsh/`
- [ ] Remove GTD MCP files from `mcp/`
- [ ] Remove GTD docs from `docs/`
- [ ] Remove GTD tests from `tests/`
- [ ] Remove GTD Makefile targets
- [ ] Update dotfiles README.md
- [ ] Update dotfiles .gitignore if needed

### Verification
- [ ] Verify no broken references in dotfiles
- [ ] Verify GTD system works standalone
- [ ] Verify all tests pass
- [ ] Verify documentation is accurate
- [ ] Verify installation process works

## Documentation

### New Repository
- [ ] Create comprehensive README.md
- [ ] Create installation guide
- [ ] Create configuration guide
- [ ] Create migration guide
- [ ] Create troubleshooting guide
- [ ] Document dependencies
- [ ] Document external services
- [ ] Document architecture
- [ ] Create API documentation (if applicable)

### Update Existing Docs
- [ ] Update dotfiles README
- [ ] Update any cross-references
- [ ] Archive or remove GTD-specific docs

## Rollback Plan

If issues are discovered:

- [ ] Keep original files in dotfiles until migration verified
- [ ] Document rollback procedure
- [ ] Test rollback process
- [ ] Maintain backup of original state

## Completion Criteria

Migration is complete when:

- [x] All files exported
- [ ] All paths updated
- [ ] All tests passing
- [ ] All functionality verified
- [ ] Documentation complete
- [ ] Installation process tested
- [ ] No broken references
- [ ] Ready for production use

## Notes

- Keep original files in dotfiles until migration is fully verified
- Test thoroughly before removing from dotfiles
- Maintain backward compatibility during transition
- Document any breaking changes
- Provide migration path for users

## Timeline

- **Start Date**: 2026-01-20
- **Target Completion**: TBD
- **Current Phase**: Planning/Preparation

## Issues & Blockers

- None currently identified

## Questions & Decisions

1. **Web Interface**: Should web interface be included?
   - Decision: TBD

2. **Shared Utilities**: How to handle shared utilities like `gtd-common.sh`?
   - Decision: Include in export, may need duplication

3. **Git History**: Should we preserve git history?
   - Decision: TBD (likely yes via git filter-branch or similar)

4. **License**: What license for new repository?
   - Decision: TBD (likely same as dotfiles)

5. **Backward Compatibility**: How long to maintain?
   - Decision: TBD
