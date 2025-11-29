# GTD System Quick Start Guide

## What I've Created For You

### 1. Configuration Files
- **`.gtd_config`** - Comprehensive GTD system configuration with all features
- **`.daily_log_config`** - Your existing daily log config (already set up)

### 2. Core Commands (Ready to Use)
- **`gtd-capture`** - Quick capture command for inbox
- **`gtd_persona_helper.py`** - Multi-persona advice system

### 3. Documentation
- **`GTD_SYSTEM_DESIGN.md`** - Complete system architecture
- **`GTD_FEATURES_SUMMARY.md`** - Features you might not have considered
- **`GTD_QUICK_START.md`** - This file

## Quick Start

### 1. Set Up Directories
```bash
mkdir -p ~/Documents/gtd/{0-inbox,1-projects,2-areas,3-reference,4-someday-maybe,5-waiting-for,6-archive,daily-logs,weekly-reviews}
```

### 2. Test Capture Command
```bash
# Quick capture
gtd-capture "Call John about project"

# Capture with type
gtd-capture --type=task "Fix the bug"

# Interactive capture
gtd-capture --interactive
```

### 3. Test Multi-Persona Advice
```bash
# Get advice from Hank (default)
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py hank "What should I focus on today?"

# Get GTD advice from David Allen
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py david "Help me organize my tasks"

# Get deep work advice from Cal Newport
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py cal "I'm struggling with distractions"

# Get habit advice from James Clear
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py james "I want to build a morning routine"

# Get satirical commentary from George Carlin
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py george "I'm overwhelmed with productivity systems"

# Get witty analysis from John Oliver
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py john "Help me understand why I procrastinate"

# Get sharp insights from Jon Stewart
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py jon "Review my daily log and tell me what's really going on"
```

### 4. Integrate with Your Daily Log
You can enhance your `addInfoToDailyLog` function to use different personas based on context. For example:

```bash
# In your zshrc, you could add:
gtd-advise() {
  local persona="${1:-hank}"
  local content="${2:-$(cat)}"
  python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py "$persona" "$content"
}
```

## Available Personas

### Productivity Experts
| Persona | Key | Expertise | Best For |
|---------|-----|-----------|----------|
| Hank Hill | `hank` | General productivity | Daily reminders, practical advice |
| David Allen | `david` | GTD methodology | Organization, processing, workflow |
| Cal Newport | `cal` | Deep work | Focus, eliminating distractions |
| James Clear | `james` | Habits | Habit formation, systems thinking |
| Marie Kondo | `marie` | Organization | Decluttering, organization |
| Warren Buffett | `warren` | Strategy | Prioritization, long-term thinking |
| Sheryl Sandberg | `sheryl` | Execution | Leadership, getting things done |
| Tim Ferriss | `tim` | Optimization | Life hacks, system optimization |

### Comedians (Satirical & Critical Perspectives)
| Persona | Key | Expertise | Best For |
|---------|-----|-----------|----------|
| George Carlin | `george` | Satirical critique | Brutally honest, dark humor commentary |
| John Oliver | `john` | Witty analysis | Intelligent, British humor, deep dives |
| Jon Stewart | `jon` | Satirical insight | Sharp commentary, calling out BS |

## Next Steps to Build Out

### Phase 1: Core GTD Commands
1. **`gtd-process`** - Inbox processing command
2. **`gtd-task`** - Task management (add, list, complete, update)
3. **`gtd-project`** - Project management
4. **`gtd-review`** - Daily/weekly review commands

### Phase 2: Advanced Features
1. **`gtd-advise`** - Wrapper for multi-persona advice
2. **`gtd-search`** - Advanced search and filtering
3. **`gtd-context`** - Context-based task suggestions
4. **`gtd-area`** - Areas of responsibility management

### Phase 3: Integration
1. Calendar sync
2. Email integration
3. Second Brain sync
4. Analytics and reporting

## Example Workflows

### Morning Routine
```bash
# 1. Review daily log
addInfoToDailyLog "Starting my day"

# 2. Get advice on priorities
gtd-advise david "What should I focus on today?"

# 3. Process inbox
gtd-process --all

# 4. View tasks by context
gtd-task list --context=computer --energy=high
```

### Weekly Review
```bash
# 1. Process all inbox items
gtd-process --all

# 2. Review projects
gtd-project list --status=active

# 3. Get review advice from multiple personas
gtd-advise david "Help me with my weekly review"
gtd-advise warren "What are my strategic priorities?"
```

### Quick Capture Workflow
```bash
# Capture throughout the day
gtd-capture "Meeting with team at 2pm"
gtd-capture --type=idea "New feature idea"
gtd-capture --type=link "https://interesting-article.com"

# Process at end of day
gtd-process --all
```

## Configuration

Edit `~/code/personal/dotfiles/zsh/.gtd_config` to customize:
- Directory structure
- Personas and their prompts
- Capture types
- Processing questions
- Contexts and energy levels
- Review schedules

## Integration with Existing System

Your existing commands work alongside the new GTD system:
- `new_fleeting_note` → Can be enhanced to use `gtd-capture`
- `new_task` → Can integrate with `gtd-task`
- `project` → Can integrate with `gtd-project`
- `addInfoToDailyLog` → Can use multi-persona advice

## Tips

1. **Start Simple**: Use capture and one persona first
2. **Build Gradually**: Add commands as you need them
3. **Customize Personas**: Edit persona prompts in `.gtd_config`
4. **Use Contexts**: Tag tasks with contexts for better filtering
5. **Regular Reviews**: Set up daily/weekly review reminders

## Getting Help

- See `GTD_SYSTEM_DESIGN.md` for complete architecture
- See `GTD_FEATURES_SUMMARY.md` for feature ideas
- Check `.gtd_config` for all configuration options

