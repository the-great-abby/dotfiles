# Claude + Ollama Integration with GTD Wizard

Your Claude + Ollama hybrid system is now fully integrated with your GTD wizard. You can access it directly from the advice wizard menu!

## Quick Access from Wizard

### From Main Wizard Menu

```bash
gtd-wizard
```

Then go to:
```
Main Menu → 11) 🤖 Get advice from personas
```

You'll now see two new options:

```
8) ⚡ Quick Claude + Ollama (instant advice, suggestions, categorization)
9) 🤖 AI System Configuration (switch modes, check status)
```

## Option 8: Quick Claude + Ollama Commands

Access instant advice, suggestions, and task categorization without background processing.

### What You Can Do:

**1) Get Persona Advice**
- Choose a persona (Hank, David, Cal, James, etc.)
- Ask a question
- Get instant response (usually 1-3 seconds)
- No background processing - response appears immediately

**2) Generate Task Suggestions**
- Paste what you've been working on
- Get 3-5 concrete task suggestions
- Automatically categorized by context

**3) Categorize Tasks**
- List your tasks (comma or space separated)
- Get categorization by context (@computer, @phone, etc.)
- Ready to add to your GTD system

**4) Analyze Daily Log**
- Point to your daily log file
- Get instant analysis and insights
- Suggestions for improvement

## Option 9: AI System Configuration

Manage your Claude + Ollama system directly from the wizard.

### Available Options:

**1) Switch to ollama-only mode**
- All requests use local Ollama
- No API calls
- Free and instant
- Good for offline work

**2) Switch to hybrid mode**
- Smart routing between Ollama and Claude
- Simple tasks → Ollama (instant)
- Complex tasks → Claude (quality)
- Best overall quality

**3) View system status**
- Check if Ollama is running
- Check if Claude API is configured
- See current mode

**4) Quick test**
- Test the system with a simple question
- Verify everything is working

**5) Configure Claude API key**
- Set your Anthropic API key
- Saved to configuration
- Enables hybrid mode

## Full Integration Features

### From Within the Wizard

**View AI Status**
- When you access option 9, you see:
  - Current mode (ollama-only or hybrid)
  - Ollama availability status
  - Claude API configuration status

**Quick Persona Advice**
- Much faster than background advice queue (instant vs. waiting)
- Perfect for quick questions
- Follows your existing persona definitions

**Task Management**
- Generate suggestions from daily notes
- Categorize tasks instantly
- Ready to add to your inbox

**Mode Management**
- Switch between modes without leaving the wizard
- No restart needed
- Changes take effect immediately

## Workflow Examples

### Example 1: Morning Routine with Claude

```
1. Open wizard: gtd-wizard
2. Choose: 11) Get advice from personas
3. Choose: 8) Quick Claude + Ollama
4. Choose: 1) Get persona advice
5. Select: 2) David Allen (for GTD)
6. Ask: "What should my focus be today?"
7. Get instant advice
```

### Example 2: Process Daily Notes

```
1. Finish your morning log
2. Open wizard: gtd-wizard
3. Choose: 11) Get advice from personas
4. Choose: 8) Quick Claude + Ollama
5. Choose: 2) Generate task suggestions
6. Paste: (your morning notes)
7. Get: 3-5 actionable tasks
```

### Example 3: Categorize Your Inbox

```
1. Copy all your inbox items
2. Open wizard: gtd-wizard
3. Choose: 11) Get advice from personas
4. Choose: 8) Quick Claude + Ollama
5. Choose: 3) Categorize tasks
6. Paste: (your tasks list)
7. Get: Tasks categorized by context
```

### Example 4: Switch to Local-Only Mode

```
1. Open wizard: gtd-wizard
2. Choose: 11) Get advice from personas
3. Choose: 9) AI System Configuration
4. Choose: 1) Switch to ollama-only mode
5. Confirm: Now using local Ollama
```

## System Files & Structure

### Integration Files Created

```
~/code/dotfiles/
├── bin/
│   ├── gtd-wizard-claude-integration.sh    # ← New integration script
│   ├── claude-gtd                           # ← CLI command
│   ├── gtd-mode-ollama                      # ← Mode switcher
│   ├── gtd-mode-hybrid                      # ← Mode switcher
│   └── gtd-wizard                           # ← Updated to source integration
├── mcp/
│   ├── claude_ollama_bridge.py             # ← Smart router
│   └── claude_gtd_client.py                # ← CLI interface
└── zsh/
    └── .gtd_config_ai                      # ← Updated with GTD_AI_MODE
```

### How It Works

1. **Wizard loads integration script** (`gtd-wizard-claude-integration.sh`)
2. **Functions become available** in the advice wizard menu
3. **User selects option 8 or 9**
4. **Claude integration functions execute**
5. **Results displayed immediately**

## Troubleshooting

### "Claude integration not loaded" Error

This means the integration script didn't load properly. Try:

```bash
# Check if the file exists
ls -la ~/code/dotfiles/bin/gtd-wizard-claude-integration.sh

# Test the integration directly
bash -c 'source ~/code/dotfiles/bin/gtd-wizard-claude-integration.sh && show_ai_mode_status'
```

### Option 8/9 Not Showing in Advice Wizard

Make sure you're in the latest version:

```bash
# Check for updates
grep "8)" ~/code/dotfiles/bin/gtd-wizard-tools.sh | grep "Quick Claude"
```

If not there, update the file or re-source the wizard:

```bash
source ~/code/dotfiles/bin/gtd-wizard
```

### Ollama Not Responding

Check if Ollama is running:

```bash
curl http://127.0.0.1:31080/v1/models
```

If not running, start your Ollama service.

### Claude API Not Working in Hybrid Mode

Verify your API key:

```bash
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-(not set)}"
```

Set it if needed:

```bash
export ANTHROPIC_API_KEY=sk-...
```

Or add to `~/.gtd_config_ai`:

```bash
ANTHROPIC_API_KEY="sk-..."
```

## Comparison: Wizard vs. CLI

### Using the Wizard (Recommended for GTD workflow)

```bash
gtd-wizard → 11) Get advice → 8) Quick Claude + Ollama
```

**Pros:**
- Integrated with GTD workflow
- No terminal navigation
- Part of your daily routine
- Status information available
- Mode switching available

**Cons:**
- Requires going through wizard menu
- Not available from command line

### Using CLI Directly

```bash
claude-gtd persona "What should I focus on?" --persona cal
```

**Pros:**
- Direct command-line access
- Can be scripted
- Useful for automation

**Cons:**
- Outside of wizard workflow
- Less context about GTD system

## Integration Architecture

```
GTD Wizard (main entry point)
    ↓
gtd-wizard-core.sh (main menu)
    ↓
gtd-wizard-tools.sh (advice wizard)
    ├─ Option 11: advice_wizard()
    │   ├─ Option 8: quick_claude_from_advice_wizard()
    │   └─ Option 9: ai_mode_configuration_wizard()
    │       (from gtd-wizard-claude-integration.sh)
    │
    └─ gtd-wizard-claude-integration.sh (NEW)
        ├─ get_current_ai_mode()
        ├─ show_ai_mode_status()
        ├─ switch_ai_mode()
        ├─ quick_claude_advice()
        ├─ quick_task_suggestion()
        ├─ quick_task_categorize()
        ├─ ai_mode_configuration_wizard()
        └─ quick_claude_from_advice_wizard()
```

## Keyboard Shortcuts & Flow

### Fastest Path to Quick Advice

```
Press: gtd-wizard (or just 'w' if you have an alias)
Shortcut: 11 (Get advice)
Shortcut: 8 (Quick Claude)
Shortcut: 1 (Persona advice)
Result: Advice in ~3-5 seconds
```

### Fastest Path to Mode Switch

```
Press: gtd-wizard
Shortcut: 11 (Get advice)
Shortcut: 9 (AI Config)
Shortcut: 1 or 2 (Switch mode)
Result: Switched immediately
```

## Next Steps

1. **Try it out**: `gtd-wizard → 11 → 8`
2. **Test both modes**: Ollama-only and hybrid
3. **Integrate into morning routine**: Use for daily prioritization
4. **Add to aliases** (optional):
   ```bash
   alias gtd-quick='gtd-wizard && gtd-quick-choose-advice'
   ```

## Tips & Best Practices

1. **Use ollama-only for offline work**
   - No internet needed
   - Instant responses
   - Great for writing/focused work

2. **Use hybrid for complex decisions**
   - Strategic planning
   - Important decisions
   - When you need Claude's quality

3. **Combine with daily log**
   - Log your morning notes
   - Get suggestions from wizard
   - Finalize your day

4. **Save useful advice**
   - Advice wizard saves to files
   - Can review later
   - Build a knowledge base

---

Enjoy your integrated Claude + Ollama GTD system! The wizard now gives you instant access to both smart routing and local-only processing.
