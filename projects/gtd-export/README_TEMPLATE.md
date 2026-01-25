# GTD Organization System

A comprehensive Getting Things Done (GTD) organization system with AI integration, task management, project tracking, and more.

## Overview

This is a standalone GTD system extracted from the dotfiles repository. It provides a complete productivity system with:

- **Task Management**: Capture, process, and organize tasks
- **Project Management**: Track projects and their associated tasks
- **Area Management**: Organize by areas of responsibility
- **Review System**: Daily, weekly, monthly, quarterly, and yearly reviews
- **AI Integration**: Get advice and suggestions from AI models
- **Calendar Integration**: Sync with Google Calendar
- **Second Brain Sync**: Integration with Obsidian
- **Web Interface**: Modern web UI for GTD operations
- **MCP Server**: Model Context Protocol server for AI assistants

## Quick Start

### Prerequisites

- **macOS** (primary platform) or Linux
- **Bash 3.2+** (macOS compatibility)
- **Python 3.11+**
- **Zsh** (for interactive shell integration)
- **Git**

### Installation

1. **Clone the repository**:
```bash
git clone <repository-url> ~/code/gtd-organization-system
cd ~/code/gtd-organization-system
```

2. **Set up Python dependencies**:
```bash
cd mcp
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. **Configure the system**:
```bash
# Copy and edit configuration files
cp zsh/.gtd_config.example zsh/.gtd_config
# Edit zsh/.gtd_config with your settings
```

4. **Set up shell integration**:
Add to your `~/.zshrc`:
```bash
# GTD System
export PATH="$HOME/code/gtd-organization-system/bin:$PATH"
source "$HOME/code/gtd-organization-system/zsh/gtd-aliases.zsh"
```

5. **Initialize data directories**:
```bash
mkdir -p ~/Documents/gtd/{0-inbox,1-projects,2-areas,3-reference,4-someday-maybe,5-waiting-for,6-archive}
mkdir -p ~/Documents/daily_logs
```

6. **Test the installation**:
```bash
gtd-wizard
```

## Configuration

### Main Configuration Files

All configuration files are in the `zsh/` directory:

- **`.gtd_config`** - Main configuration file
- **`.gtd_config_core`** - Core settings (directories, templates)
- **`.gtd_config_ai`** - AI/LLM backend configuration
- **`.gtd_config_capture`** - Capture and processing settings
- **`.gtd_config_reviews`** - Review system settings
- **`.gtd_config_calendar`** - Calendar integration
- **`.gtd_config_database`** - Database and RabbitMQ settings
- **`.gtd_config_notifications`** - Notification settings
- **`.gtd_config_integrations`** - External integrations
- **`.gtd_config_advanced`** - Advanced features
- **`.gtd_config_custom`** - Your custom overrides

### Data Directories

The system uses the following data directories (configurable in `.gtd_config_core`):

- `~/Documents/gtd/` - Main GTD data directory
  - `0-inbox/` - Inbox items
  - `1-projects/` - Projects
  - `2-areas/` - Areas of responsibility
  - `3-reference/` - Reference materials
  - `4-someday-maybe/` - Someday/Maybe items
  - `5-waiting-for/` - Waiting for items
  - `6-archive/` - Archived items
- `~/Documents/daily_logs/` - Daily log entries
- `~/.gtd_personalization.toon` - Personalization data

## Usage

### Basic Commands

- **`gtd-wizard`** - Interactive wizard for all GTD operations
- **`gtd-capture`** - Quick capture to inbox
- **`gtd-process`** - Process inbox items
- **`gtd-review`** - Run reviews (daily/weekly/monthly/etc.)
- **`gtd-task`** - Task management
- **`gtd-project`** - Project management
- **`gtd-area`** - Area management
- **`gtd-advise`** - Get AI advice
- **`gtd-dashboard`** - View system dashboard

### Wizard Interface

The main interface is the interactive wizard:

```bash
gtd-wizard
```

This provides a menu-driven interface for all GTD operations.

### Web Interface

Start the web interface:

```bash
cd web
./start.sh
```

Then access at `http://localhost:5173` (development) or your configured domain.

## External Dependencies

### Optional but Recommended

1. **PostgreSQL with pgvector** - Vector database for semantic search
2. **RabbitMQ** - Message queue for async processing
3. **LM Studio or Ollama** - AI/LLM backend
4. **Kubernetes** - For deploying external services

See `docs/DEPENDENCIES.md` for detailed setup instructions.

## Documentation

- **Quick Start**: This file
- **Installation Guide**: `docs/INSTALLATION.md`
- **Configuration Guide**: `docs/CONFIGURATION.md`
- **Command Reference**: `docs/COMMANDS.md`
- **Architecture**: `docs/architecture/`
- **Dependencies**: `docs/DEPENDENCIES.md`

## Project Structure

```
gtd-organization-system/
├── bin/                    # All GTD command scripts
├── zsh/                    # Configuration files and functions
│   ├── .gtd_config*       # Configuration files
│   ├── functions/          # Python and shell functions
│   └── quizzes/            # Quiz questions
├── mcp/                    # MCP server and workers
│   ├── skills/             # MCP skills
│   └── runbooks/           # Runbooks
├── docs/                   # Documentation
├── web/                    # Web interface
│   ├── backend/            # FastAPI backend
│   └── frontend/           # Svelte frontend
├── tests/                  # Test files
├── launchd/                # macOS launchd plists
└── scripts/                # Utility scripts
```

## Development

### Running Tests

```bash
cd tests
./run_tests.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

[Specify your license here]

## Support

For issues, questions, or contributions, please open an issue on GitHub.

## Migration from Dotfiles

If you're migrating from the dotfiles repository:

1. Export your configuration files
2. Update paths in configuration files
3. Test all functionality
4. Update shell integration

See `docs/MIGRATION.md` for detailed migration instructions.
