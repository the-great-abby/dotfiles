# Claude Ask TUI

A modern Text User Interface (TUI) for interactive Claude conversations, built with Python's `textual` library.

## Features

- 🎨 **Modern TUI**: Clean, keyboard-driven interface
- 💬 **Conversation History**: Scrollable conversation view
- 🤖 **Persona Support**: Select personas at the start
- ⌨️ **Keyboard Shortcuts**: Fast navigation and actions
- 📝 **Multi-line Input**: TextArea for longer questions
- 🔄 **Continue Mode**: Ask Claude to continue its workflow
- 🧠 **Smart Routing**: Simple questions → Ollama (free), Complex questions → Claude (API)
- 🦙 **Ollama Integration**: Automatic routing to local Ollama for simple requests

## Installation

The TUI uses the `textual` library which should already be installed in the MCP venv:

```bash
cd ~/code/dotfiles/mcp
source venv/bin/activate
pip install textual  # If not already installed
```

## Usage

### Basic Usage

```bash
# Start TUI with a question
claude-ask-tui "What's your best productivity advice?"

# Start TUI without initial question
claude-ask-tui

# Select persona interactively
claude-ask-tui --select-persona

# Use specific persona
claude-ask-tui "How do I focus?" --persona cal
```

### Via Makefile

```bash
# Using Makefile (requires QUESTION variable)
make claude-ask-interactive QUESTION="Your question here"

# Or use the direct TUI target
make claude-ask-tui QUESTION="Your question here"
```

### Via Claude GTD Client

```bash
# The --interactive flag now launches the TUI
claude-gtd ask "Your question" --interactive
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+J` | Send message |
| `Esc` | Clear input |
| `Ctrl+L` | Clear conversation |
| `Ctrl+/` | Show help |
| `Ctrl+F` | Toggle force Claude mode |
| `Ctrl+C` | Quit |

## Buttons

- **Send**: Send your current message
- **Continue**: Ask Claude to continue its workflow
- **Clear**: Clear the conversation history
- **Quit**: Exit the TUI

## How It Works

1. **Startup**: Select persona (if requested), then show welcome or ask initial question
2. **Input**: Type your question in the TextArea
3. **Send**: Press `Ctrl+J` or click "Send" button
4. **Smart Routing**: 
   - Simple questions → 🦙 Ollama (local, free, fast)
   - Complex questions → 🤖 Claude (API, better quality)
5. **Response**: AI response appears in the conversation area with source indicator
6. **Continue**: Keep chatting or use "Continue" to let Claude proceed

## Smart Routing

The TUI uses intelligent routing to save API costs:

- **Simple questions** (short, straightforward) → Ollama
- **Complex questions** (analysis, strategy, long context) → Claude
- **Status indicator** shows which AI was used: 🦙 (Ollama) or 🤖 (Claude)

### Force Claude Mode

Press `Ctrl+F` to toggle "Force Claude" mode, which bypasses smart routing and always uses Claude API. Useful when you need guaranteed Claude quality regardless of question complexity.

### Routing Examples

- "What's 2+2?" → 🦙 Ollama (simple)
- "Categorize these tasks" → 🦙 Ollama (classification)
- "Analyze my productivity patterns" → 🤖 Claude (complex analysis)
- "Help me plan a strategic approach" → 🤖 Claude (strategic thinking)

## Conversation History

The TUI maintains conversation history automatically:
- All messages are saved in the conversation
- History is sent to Claude for context
- You can clear history with `Ctrl+L` or the "Clear" button

## Persona Selection

At startup, you can:
- Select a persona interactively (if `--select-persona` is used)
- Specify a persona with `--persona NAME`
- Chat without a persona (default)

## Comparison with Legacy Mode

| Feature | Legacy (CLI) | TUI |
|---------|--------------|-----|
| Interface | Text prompts | Modern TUI |
| Conversation View | Scrolling terminal | Scrollable panel |
| Input | Single line | Multi-line TextArea |
| History | Terminal scroll | Dedicated view |
| Navigation | Arrow keys | Mouse + Keyboard |

## Troubleshooting

### "textual library not installed"

Install it:
```bash
cd ~/code/dotfiles/mcp
source venv/bin/activate
pip install textual
```

### TUI falls back to legacy mode

If the TUI file isn't found or there's an error, it automatically falls back to the legacy CLI mode.

### Conversation not updating

Make sure you're using `Ctrl+J` to send, or click the "Send" button. The TextArea doesn't submit on Enter (to allow multi-line input).

## See Also

- [Claude Direct Access Guide](./CLAUDE_DIRECT_ACCESS.md) - More about asking Claude
- [Claude Ollama Hybrid](./CLAUDE_OLLAMA_HYBRID.md) - Smart routing system
