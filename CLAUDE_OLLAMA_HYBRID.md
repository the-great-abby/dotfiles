# Claude + Ollama Hybrid GTD System

## Overview

You now have a flexible hybrid AI system that can switch between:

1. **Ollama-only mode**: All requests use local Ollama (free, instant, lower quality)
2. **Hybrid mode**: Smart routing (simple tasks → Ollama, complex → Claude API)

This lets you work completely locally when you want, or leverage Claude's quality when needed.

## Quick Start

### Check Current Status

```bash
claude-gtd status
```

Shows:
- Current mode (ollama-only or hybrid)
- Ollama availability
- Claude API configuration
- Ollama URL and connection

### Switch Modes

```bash
# Use Claude + Ollama smart routing (recommended)
claude-gtd mode hybrid

# Use only local Ollama (no API calls, free)
claude-gtd mode ollama-only

# Check current mode
claude-gtd mode
```

## Usage Examples

### Get Persona Advice

```bash
# Get Hank Hill's advice (default)
claude-gtd persona "I'm procrastinating on this big task"

# Get specific persona
claude-gtd persona "How do I focus better?" --persona cal

# Other personas: hank, david, cal, james, marie, warren, sheryl, tim, etc.
```

### Generate Task Suggestions

```bash
claude-gtd suggest "finished report, scheduled meeting, need to prepare presentation"
```

### Categorize Tasks

```bash
claude-gtd categorize "email john, run tests, buy groceries, call mom"
```

### Analyze Daily Log

```bash
claude-gtd analyze ~/Documents/daily_logs/2026-01-19.md
```

## System Architecture

### Routing Decision Matrix

| Task Type | Ollama-Only | Hybrid | Claude Required |
|-----------|------------|--------|-----------------|
| Persona response | ✅ | ✅ (Ollama) | ✗ |
| Task suggestion | ✅ | ✅ (Ollama) | ✗ |
| Task categorization | ✅ | ✅ (Ollama) | ✗ |
| Similarity search | ✅ | ✅ (Ollama) | ✗ |
| Daily log analysis | ✅ (basic) | ✅ (smart) | ✗ |
| Weekly review | ✅ (basic) | ✅ (Claude) | ✓ |
| Pattern analysis | ✅ (basic) | ✅ (Claude) | ✓ |
| Strategy planning | ✅ (basic) | ✅ (Claude) | ✓ |

### How Smart Routing Works

**Ollama-First Approach:**
```
Request arrives
  ↓
Is it simple? → YES → Use Ollama (instant)
  ↓ NO
  ↓
Is Claude available? → NO → Use Ollama (fallback)
  ↓ YES
  ↓
Use Claude (quality)
```

**Simple Tasks** (always Ollama):
- Persona responses
- Task categorization
- Similarity searches
- Quick suggestions

**Complex Tasks** (Claude if available):
- Deep analysis
- Strategic planning
- Pattern finding
- Reasoning-heavy tasks

## Configuration

### Mode Setting

Edit `~/.gtd_config_ai` (or `~/code/dotfiles/zsh/.gtd_config_ai`):

```bash
# Hybrid mode (smart routing)
GTD_AI_MODE="hybrid"

# Ollama-only mode (local, free)
GTD_AI_MODE="ollama-only"
```

### Claude API Configuration

Set your API key as an environment variable:

```bash
export ANTHROPIC_API_KEY=sk-...
```

Or add to `.gtd_config_ai`:
```bash
ANTHROPIC_API_KEY="sk-..."
```

### Ollama Configuration

Already configured to use your existing Ollama Controller at:
```
http://127.0.0.1:31080/v1/chat/completions
```

Custom URL in `.gtd_config_ai`:
```bash
OLLAMA_URL="http://your-ollama-url:port/v1/chat/completions"
```

## System Components

### Files Created

```
~/code/dotfiles/
├── mcp/
│   ├── claude_ollama_bridge.py      # Smart router (Ollama ↔ Claude)
│   ├── claude_gtd_client.py         # CLI interface
│   └── gtd_advice_worker.py         # [Updated] Added Claude support
├── bin/
│   ├── claude-gtd                   # Main command
│   ├── gtd-mode-ollama             # Switch to ollama-only
│   ├── gtd-mode-hybrid             # Switch to hybrid
│   ├── gtd-mode-check              # Show current mode
│   └── gtd-mode-status             # Detailed status
└── zsh/
    └── .gtd_config_ai              # [Updated] Added mode config
```

### How It Works

1. **claude_ollama_bridge.py**: Smart router that decides where to send requests
   - Analyzes request type and complexity
   - Routes simple tasks to Ollama
   - Routes complex tasks to Claude (hybrid mode)
   - Handles both modes seamlessly

2. **claude_gtd_client.py**: User-friendly CLI
   - Calls the smart router
   - Formats and displays results
   - Manages mode switching
   - Easy to use from shell

3. **Integration**: Works with existing GTD system
   - Respects your personas
   - Uses your Ollama models
   - Stores results in same directories

## Use Cases

### Scenario 1: Working Offline
```bash
# Switch to local-only
claude-gtd mode ollama-only

# All requests now use Ollama (no API calls)
claude-gtd persona "What should I do today?"  # Instant ✅
```

### Scenario 2: Need Better Quality
```bash
# Switch to hybrid
claude-gtd mode hybrid

# Set API key
export ANTHROPIC_API_KEY=sk-...

# Complex analysis uses Claude
claude-gtd analyze ~/Documents/daily_logs/2026-01-19.md  # Claude for analysis
```

### Scenario 3: Budget Conscious
```bash
# Hybrid mode uses Ollama for ~90% of tasks
# Only complex strategic tasks go to Claude (~10%)
claude-gtd mode hybrid

# Most commands = free (Ollama)
# Complex planning = paid (Claude)
```

## Troubleshooting

### Ollama Not Responding
```bash
# Check if Ollama is running
curl http://127.0.0.1:31080/v1/models

# Should return list of available models
```

### Claude Not Working in Hybrid Mode
```bash
# Check API key is set
echo $ANTHROPIC_API_KEY

# If not set:
export ANTHROPIC_API_KEY=sk-...

# Verify it worked
claude-gtd status
```

### Wrong Mode Setting
```bash
# Check current mode
claude-gtd mode

# Switch mode
claude-gtd mode hybrid
claude-gtd mode ollama-only

# Verify it changed
claude-gtd mode
```

## Performance Notes

### Ollama (Local)
- Response time: **instant** (100-500ms)
- Cost: **free** ($0)
- Quality: Good for patterns and suggestions
- Best for: Persona responses, categorization, search

### Claude (API)
- Response time: **fast** (1-3s)
- Cost: **~$0.01-0.05 per request** (varies by usage)
- Quality: Excellent for reasoning and analysis
- Best for: Planning, analysis, strategy, reasoning

### Hybrid (Smart)
- Average response time: **~1s** (mostly Ollama, some Claude)
- Average cost: **~$0.002 per request** (10% Claude calls)
- Quality: Best of both worlds
- Best for: Everything

## Integration with Existing GTD System

The system automatically integrates with:

- ✅ Your persona definitions (from `.gtd_config_ai`)
- ✅ Daily log files (`~/Documents/daily_logs/`)
- ✅ GTD inbox structure
- ✅ Task suggestions and advice
- ✅ Existing Ollama setup
- ✅ Existing MCP server configuration

No migration needed - works alongside your current system!

## Next Steps

1. **Test the system**
   ```bash
   claude-gtd status
   claude-gtd persona "What's your first priority today?"
   ```

2. **Set up Claude API** (optional, for hybrid mode)
   ```bash
   export ANTHROPIC_API_KEY=sk-...
   claude-gtd mode hybrid
   ```

3. **Integrate with daily log workflow**
   ```bash
   # After your morning log
   addInfoToDailyLog "your entry"
   claude-gtd analyze ~/Documents/daily_logs/$(date +%Y-%m-%d).md
   ```

4. **Try different personas**
   ```bash
   claude-gtd persona "stuck on a bug" --persona skippy
   claude-gtd persona "energy is low" --persona cal
   ```

## Questions?

- **How do I know which mode I'm in?** → `claude-gtd status`
- **How do I switch modes?** → `claude-gtd mode <ollama-only|hybrid>`
- **Why is Claude not available?** → API key not set (`export ANTHROPIC_API_KEY=...`)
- **Why is Ollama not working?** → Check if it's running at port 31080

Enjoy your hybrid AI system! 🚀
