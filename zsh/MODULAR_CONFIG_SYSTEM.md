# GTD Modular Configuration System

## Overview

The GTD configuration system has been split into modular files for better organization and maintainability, similar to how `.gtd_acronyms` is handled separately.

## Structure

### Main Config File
- **`.gtd_config`** - Main configuration file (backwards compatible)
  - Contains Discord webhook and other legacy settings
  - Automatically loads modular config files at the end

### Modular Config Files

All modular files are located in the same directory as `.gtd_config` (typically `~/code/dotfiles/zsh/` or `~/code/personal/dotfiles/zsh/`):

1. **`.gtd_config_core`** - Core settings
   - User name
   - Directory structure
   - File templates
   - Search settings

2. **`.gtd_config_ai`** - AI backend and personas
   - AI backend configuration (LM Studio, Ollama)
   - Persona definitions
   - Persona trigger rules

3. **`.gtd_config_capture`** - Capture and processing
   - Capture methods
   - Auto-tagging rules
   - Processing questions and outcomes
   - Contexts, energy levels, priority matrix

4. **`.gtd_config_reviews`** - Review system
   - Daily/weekly review settings
   - Review questions
   - Reminder times

5. **`.gtd_config_integrations`** - External integrations
   - Second Brain (Obsidian) settings
   - Email integration
   - PARA method configuration

6. **`.gtd_config_calendar`** - Calendar integration
   - Google Calendar settings
   - Office 365 settings

7. **`.gtd_config_notifications`** - Notifications and reminders
   - Notification methods
   - Discord webhook settings
   - Reminder times (morning, lunch, study, health)

8. **`.gtd_config_advanced`** - Advanced features
   - Analytics and tracking
   - AI suggestions
   - Dependency tracking
   - Feature flags

9. **`.gtd_config_custom`** - Custom overrides (loaded last)
   - Your personal customizations
   - Overrides for any setting
   - This file is for you to customize

## Loading Order

The config files are loaded in this order (later files can override earlier ones):

1. `.gtd_config` (main file)
2. `.gtd_config_core`
3. `.gtd_config_ai`
4. `.gtd_config_capture`
5. `.gtd_config_reviews`
6. `.gtd_config_integrations`
7. `.gtd_config_calendar`
8. `.gtd_config_notifications`
9. `.gtd_config_advanced`
10. `.gtd_config_custom` (highest priority - can override anything)

## Usage

### For Scripts

Scripts should continue to source `.gtd_config` as before:

```bash
GTD_CONFIG_FILE="$HOME/.gtd_config"
if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
  GTD_CONFIG_FILE="$HOME/code/dotfiles/zsh/.gtd_config"
fi

if [[ -f "$GTD_CONFIG_FILE" ]]; then
  source "$GTD_CONFIG_FILE"
fi
```

The main config file will automatically load all modular files.

### For Customization

To customize settings:

1. **Edit the relevant modular file** - For example, to change AI settings, edit `.gtd_config_ai`
2. **Use `.gtd_config_custom`** - For personal overrides that you don't want to lose during updates

Example in `.gtd_config_custom`:
```bash
# Override user name
GTD_USER_NAME="Your Name"

# Switch to Ollama
AI_BACKEND="ollama"

# Custom directory
GTD_BASE_DIR="$HOME/MyGTD"
```

## Migration

If you have an existing monolithic `.gtd_config`, the modular files have been created with default values. You can:

1. **Keep using the monolithic file** - It still works! The modular files will just add defaults for missing values.

2. **Gradually migrate** - Move settings from `.gtd_config` to the appropriate modular files as you edit them.

3. **Use the splitter** - Run `gtd-config-split` for guidance (though the files are already created).

## Benefits

1. **Better Organization** - Related settings are grouped together
2. **Easier Maintenance** - Find and edit settings more easily
3. **Selective Updates** - Update specific modules without touching others
4. **Customization** - Use `.gtd_config_custom` for personal overrides
5. **Backwards Compatible** - Existing scripts continue to work

## File Locations

The system looks for config files in this order:

1. `~/code/dotfiles/zsh/` (primary)
2. `~/code/personal/dotfiles/zsh/` (fallback)
3. `~/.gtd_config` (home directory fallback)

## Notes

- All modular files are optional - if they don't exist, the system uses defaults
- Settings in later files override earlier ones
- `.gtd_config_custom` is loaded last, so it has the highest priority
- The main `.gtd_config` file is still the entry point for backwards compatibility

