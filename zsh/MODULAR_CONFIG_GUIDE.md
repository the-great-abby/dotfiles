# Modular Configuration Guide

The GTD system now supports modular configuration files for better organization and maintainability.

## Overview

Instead of having everything in one large `.gtd_config` file, you can now split configuration into separate, focused files:

- **`.gtd_config`** - Main configuration file (still contains core settings)
- **`.gtd_acronyms`** - Acronym definitions for AI context understanding
- **Future modules** - Easy to add more as needed

## Acronyms Configuration

### Location

The acronyms file can be in any of these locations (checked in order):
1. `~/code/dotfiles/zsh/.gtd_acronyms` (dotfiles repo)
2. `~/code/personal/dotfiles/zsh/.gtd_acronyms` (personal dotfiles)
3. `~/.gtd_acronyms` (home directory)

### Format

```bash
GTD_ACRONYMS=(
  "ACRONYM|Full Definition|Optional Context"
  "AWS|Amazon Web Services|Cloud computing platform"
  "K8s|Kubernetes|Container orchestration platform"
  "GTD|Getting Things Done|Productivity methodology by David Allen"
)
```

### How It Works

1. The `.gtd_config` file automatically sources `.gtd_acronyms` if it exists
2. The persona helper (`gtd_persona_helper.py`) reads acronyms and includes them in AI prompts
3. When AI personas process your content, they understand what acronyms mean
4. This provides better context-aware advice

### Adding Acronyms

Simply edit `.gtd_acronyms` and add entries in the format:
```bash
"YOUR_ACRONYM|Full Definition|Additional context if needed"
```

The system will automatically pick them up on the next AI interaction.

### Example Acronyms Included

The default file includes common tech acronyms:
- Cloud & Infrastructure (AWS, K8s, Docker, etc.)
- Development (API, REST, JSON, etc.)
- DevOps (SRE, CI/CD, etc.)
- GTD & Productivity (GTD, PARA, MOC, etc.)
- And many more...

## Benefits of Modular Config

1. **Organization** - Related settings grouped together
2. **Maintainability** - Easier to find and update specific configs
3. **Sharing** - Can share acronym lists without exposing other config
4. **Version Control** - Easier to track changes to specific config areas
5. **Optional** - Modules are optional - system works without them

## Adding New Modular Config Files

To add a new modular config file:

1. Create the new file (e.g., `.gtd_custom`)
2. Add to `.gtd_config`:
```bash
GTD_CUSTOM_FILE="${GTD_CUSTOM_FILE:-$HOME/code/dotfiles/zsh/.gtd_custom}"
if [[ -f "$GTD_CUSTOM_FILE" ]]; then
  source "$GTD_CUSTOM_FILE"
fi
```

3. Update any scripts that need to read from it

## Best Practices

- Keep acronyms focused and relevant to your work
- Add context when the acronym might be ambiguous
- Update acronyms as your work/context changes
- Use descriptive names for custom config files
- Document custom config files

