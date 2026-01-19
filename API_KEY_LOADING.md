# Claude API Key Loading - Dynamic File Support

Your Claude API key is now loaded **dynamically** from multiple sources. No environment variables needed!

## How It Works

The system checks for your API key in this order (first found = used):

### **Priority 1: Environment Variable (Highest)**
```bash
export ANTHROPIC_API_KEY=sk-ant-...
```
Use this when you want to override everything temporarily.

### **Priority 2: Dedicated API Key File (Recommended)**
```
~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```
Or fallback to: `~/ANTHROPIC_API_KEY`

This is the **easiest** - just store your key in a file. System reads it automatically!

### **Priority 3: Config File (Lowest)**
```
~/.gtd_config_ai or ~/code/dotfiles/zsh/.gtd_config_ai
```
Stored as: `ANTHROPIC_API_KEY="sk-ant-..."`

## Setting It Up

### **Option 1: Use the API Key File (Easiest)**

You already have this set up! The system is already reading from:
```
~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```

**Check current status:**
```bash
claude-check-api
```

### **Option 2: Create API Key File**

If you don't have one yet:

```bash
# Create the directory
mkdir -p ~/code/dotfiles/zsh

# Save your API key to the file
echo 'sk-ant-api03-YOUR-KEY-HERE' > ~/code/dotfiles/zsh/ANTHROPIC_API_KEY

# Make it read-only for security
chmod 600 ~/code/dotfiles/zsh/ANTHROPIC_API_KEY

# Verify it works
claude-check-api
```

### **Option 3: Set Environment Variable**

Temporary (this session only):
```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

Permanent (add to `~/.zshrc`):
```bash
echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.zshrc
source ~/.zshrc
```

### **Option 4: Add to Config File**

Add to `~/.gtd_config_ai`:
```bash
ANTHROPIC_API_KEY="sk-ant-..."
```

## Checking Your Setup

**Quick status check:**
```bash
claude-check-api
```

Shows:
- Where API key is loaded from
- Priority order
- Whether Claude is ready to use

**In Python code:**
```python
from mcp.claude_ollama_bridge import SmartAIRouter
router = SmartAIRouter()
print(f"Claude available: {bool(router.anthropic_api_key)}")
```

**In Shell:**
```bash
source ~/code/dotfiles/bin/gtd-wizard-claude-integration.sh
api_key=$(load_anthropic_api_key)
echo "API key loaded: $api_key"
```

## Your Current Setup

✅ **File-based loading is active**

Your key is stored at:
```
~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```

The system automatically reads it when you use:
- `claude-ask "question"`
- `claude-gtd ask "question"`
- `gtd-wizard → 11) → 8) → 5)`

No manual setup needed - it just works!

## How the Code Works

### Python (claude_ollama_bridge.py)
```python
# Checks in order:
# 1. Environment: ANTHROPIC_API_KEY
# 2. File: ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
# 3. File: ~/ANTHROPIC_API_KEY
# 4. Config: ~/.gtd_config_ai or ~/code/dotfiles/zsh/.gtd_config_ai

api_key_file = Path.home() / "code" / "dotfiles" / "zsh" / "ANTHROPIC_API_KEY"
if api_key_file.exists():
    with open(api_key_file) as f:
        api_key = f.read().strip()
        if api_key.startswith("sk-"):
            config["anthropic_api_key"] = api_key
```

### Shell (gtd-wizard-claude-integration.sh)
```bash
# load_anthropic_api_key function checks:
# 1. ANTHROPIC_API_KEY env var
# 2. ~/code/dotfiles/zsh/ANTHROPIC_API_KEY file
# 3. ~/.gtd_config_ai file

load_anthropic_api_key() {
    if [[ -n "${ANTHROPIC_API_KEY}" ]]; then
        echo "${ANTHROPIC_API_KEY}"
    fi
    # ... check files ...
}
```

## Security Notes

⚠️ **Important:**

1. **File Permissions:**
   ```bash
   chmod 600 ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
   ```
   This makes the file readable/writable only by you.

2. **Git Ignored:**
   The file is already in `.gitignore`:
   ```
   ANTHROPIC_API_KEY
   ```
   Your key won't be committed to git.

3. **Never commit your key** - it's automatically ignored.

4. **Rotate keys regularly** - if compromised, generate a new one in Anthropic dashboard.

## Troubleshooting

### "Claude API key not configured"

**Check status:**
```bash
claude-check-api
```

**Solution:**
Create or update your API key file:
```bash
echo 'sk-ant-your-actual-key' > ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
chmod 600 ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```

### Key not loading despite file existing

**Debug:**
```bash
# Check file content
cat ~/code/dotfiles/zsh/ANTHROPIC_API_KEY

# Check Python can read it
cd ~/code/dotfiles/mcp
python3 << 'EOF'
import sys
sys.path.insert(0, '..')
from claude_ollama_bridge import SmartAIRouter
router = SmartAIRouter()
print(f"API Key: {router.anthropic_api_key[:20]}...")
EOF
```

### File exists but still not working

Possible issues:
- File permissions wrong (should be 600)
- Key doesn't start with `sk-`
- Leading/trailing whitespace in file

**Fix:**
```bash
# Check file
cat ~/code/dotfiles/zsh/ANTHROPIC_API_KEY | od -c

# If there are weird characters, recreate it:
echo 'sk-ant-YOUR-KEY' > ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
chmod 600 ~/code/dotfiles/zsh/ANTHROPIC_API_KEY

# Verify it's clean
cat ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```

## Testing It Works

**Option 1: Quick test**
```bash
claude-check-api
```

**Option 2: Use Claude directly**
```bash
# If this works, your key is loaded
claude-ask "What's 2+2?"
```

**Option 3: From wizard**
```bash
gtd-wizard
# 11) Get advice
# 8) Quick Claude + Ollama
# 5) Ask Claude directly
# Type your question
```

## Loading Priority in Action

Given all three sources set:

```bash
# Environment variable set
export ANTHROPIC_API_KEY=sk-ant-env-KEY

# File exists
~/code/dotfiles/zsh/ANTHROPIC_API_KEY = sk-ant-file-KEY

# Config set
ANTHROPIC_API_KEY="sk-ant-config-KEY"
```

**Result:** Uses `sk-ant-env-KEY` (environment wins)

Delete env var:
```bash
unset ANTHROPIC_API_KEY
```

**Result:** Uses `sk-ant-file-KEY` (file wins)

Delete file:
```bash
rm ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```

**Result:** Uses `sk-ant-config-KEY` (config is last resort)

## Summary

✅ **Your setup:**
- API key file automatically loaded from `~/code/dotfiles/zsh/ANTHROPIC_API_KEY`
- No environment variables needed
- System checks automatically at startup
- Use `claude-check-api` to verify status
- Works everywhere: CLI, wizard, Python

🚀 **You're all set!** Just use:
```bash
claude-ask "your question"
```
