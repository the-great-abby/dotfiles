# MCP Scripts Virtualenv Setup

## Overview

All MCP (Model Context Protocol) Python scripts now use a virtualenv to isolate dependencies. This ensures that the `mcp` package and other dependencies don't conflict with system Python packages.

## Virtualenv Location

The virtualenv is located at:
```
~/code/dotfiles/mcp/venv/
```

Or if using personal dotfiles:
```
~/code/personal/dotfiles/mcp/venv/
```

## Setup

### Initial Setup

Run the setup script to create the virtualenv and install dependencies:

```bash
cd ~/code/dotfiles/mcp
./setup.sh
```

This will:
1. Create a virtualenv at `mcp/venv/`
2. Install all dependencies from `requirements.txt` (including `mcp` package)
3. Test that imports work correctly

### Manual Setup

If you prefer to set it up manually:

```bash
cd ~/code/dotfiles/mcp
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
```

## How It Works

### Automatic Detection

All scripts that use MCP Python scripts automatically:
1. Check for the virtualenv at `mcp/venv/bin/python3`
2. Use it if available
3. Fall back to system Python if virtualenv doesn't exist

### Scripts That Use Virtualenv

- `bin/gtd-wizard` - Banter generation
- `bin/gtd-daily-log` - Auto-suggestions
- `bin/gtd-healthkit-log` - Auto-suggestions
- Any script calling `gtd_auto_suggest.py` or other MCP scripts

### Manual Usage

To run MCP scripts manually with the virtualenv:

```bash
# Option 1: Activate virtualenv first
source ~/code/dotfiles/mcp/venv/bin/activate
python gtd_auto_suggest.py banter "your log entry"
deactivate

# Option 2: Use virtualenv Python directly
~/code/dotfiles/mcp/venv/bin/python3 gtd_auto_suggest.py banter "your log entry"
```

## Benefits

1. **Isolated Dependencies**: MCP packages don't pollute system Python
2. **Version Control**: Easy to manage specific package versions
3. **No Conflicts**: Won't interfere with other Python projects
4. **Easy Updates**: Update MCP dependencies independently
5. **Reproducible**: Same environment across different systems

## Updating Dependencies

To update dependencies:

```bash
cd ~/code/dotfiles/mcp
source venv/bin/activate
pip install --upgrade -r requirements.txt
deactivate
```

## Troubleshooting

### "mcp package not installed" Error

1. Check if virtualenv exists:
   ```bash
   ls -la ~/code/dotfiles/mcp/venv/bin/python3
   ```

2. If virtualenv doesn't exist, run setup:
   ```bash
   cd ~/code/dotfiles/mcp && ./setup.sh
   ```

3. If virtualenv exists but packages aren't installed:
   ```bash
   source ~/code/dotfiles/mcp/venv/bin/activate
   pip install -r requirements.txt
   deactivate
   ```

### Virtualenv Not Found

Scripts automatically fall back to system Python. To ensure virtualenv is used:
1. Make sure `mcp/venv/` directory exists
2. Run `./setup.sh` to create it

## Requirements

The virtualenv includes:
- `mcp>=0.9.0` - Model Context Protocol SDK
- `pika>=1.3.0` - RabbitMQ client (optional, for background processing)

All other dependencies (json, pathlib, datetime, etc.) are part of Python's standard library.

