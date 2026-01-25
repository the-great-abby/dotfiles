# GTD Wizard TUI

A modern Text User Interface (TUI) for the GTD Wizard, built with Python's `textual` library.

## Features

- 🎨 **Modern TUI**: Beautiful, keyboard-driven interface
- 🔍 **Search/Filter**: Quickly find menu items by typing
- 📊 **Status Panel**: Real-time system status display
- ⌨️ **Keyboard Navigation**: Arrow keys, Enter, and shortcuts
- 🎯 **Full Integration**: Works with all existing bash wizard functions

## Installation

### Prerequisites

- Python 3.8+
- `textual` library

### Setup

1. **Install textual**:
   ```bash
   pip install textual
   ```
   
   Or if using the MCP virtualenv:
   ```bash
   cd ~/code/dotfiles/mcp
   source venv/bin/activate
   pip install textual
   ```

2. **Make sure the script is executable**:
   ```bash
   chmod +x ~/code/dotfiles/bin/gtd-wizard-tui.py
   ```

## Usage

### Starting the TUI

```bash
gtd-wizard-tui
```

Or if it's in your PATH:
```bash
gtd-wizard-tui.py
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate menu items |
| `Enter` | Select/Execute menu item |
| `f` | Focus search box |
| `Esc` | Clear search |
| `r` | Refresh status and menu |
| `?` | Show help |
| `q` | Quit |

### Navigation

- Use arrow keys to navigate the menu
- Press Enter to execute a menu item
- Type in the search box to filter menu items
- The status panel on the right shows system information

## How It Works

The TUI provides a modern interface to the existing bash wizard functions:

1. **Menu Display**: Shows all wizard options in organized sections
2. **Selection**: When you select an item, it calls the corresponding bash function
3. **Seamless Flow**: Exits TUI mode to run interactive bash functions, then **automatically restarts the TUI** when the function completes

## Architecture

- **Frontend**: Python + Textual (TUI framework)
- **Backend**: Existing bash wizard functions
- **Integration**: Subprocess calls to bash scripts

## Comparison with Bash Wizard

| Feature | Bash Wizard | TUI Wizard |
|---------|-------------|------------|
| Interface | Text menus | Modern TUI |
| Navigation | Number input | Arrow keys + Enter |
| Search | No | Yes (real-time filter) |
| Status | Bottom of screen | Side panel |
| Visual | Basic | Enhanced with colors/formatting |

## Future Enhancements

Potential improvements:

- [ ] In-TUI execution (without exiting)
- [ ] Terminal widget for bash function output
- [ ] Keyboard shortcuts for common actions
- [ ] Customizable themes
- [ ] Recent items / favorites
- [ ] Command history

## Troubleshooting

### "textual library not installed"

Install it:
```bash
pip install textual
```

### "Wizard script not found"

Make sure your `GTD_BASE_DIR` is set correctly, or the dotfiles are in the expected location:
- `~/code/dotfiles` or
- `~/code/personal/dotfiles`

### Menu items don't execute

Check that:
1. The bash wizard scripts are in `bin/` directory
2. You have execute permissions
3. The scripts can be sourced properly

## Contributing

The TUI is built with Python and Textual. To modify:

1. Edit `bin/gtd-wizard-tui.py`
2. Test changes
3. Update this documentation if needed

## See Also

- [GTD Wizard Guide](./GTD_WIZARD_GUIDE.md) - Main wizard documentation
- [Architecture Decisions](./architecture/architecture_decisions.md) - ADR-010 discusses TUI vs printed menus
