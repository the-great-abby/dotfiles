# Diagram Generation with Claude API

## ✅ Integration Complete!

Diagram and mindmap generation now uses the **Claude API** (via `claude_ollama_bridge`) as the preferred method. Claude API provides better diagram generation with accurate syntax and structure.

**Fallback options:**
- If Claude API is not configured, falls back to deep analysis model (GPT-OSS 20b)
- If deep model is not available, falls back to persona helper

**NEW:** The diagram tool now automatically gathers GTD data (projects, tasks, areas, etc.) when you ask for diagrams about your GTD system, making diagrams based on your actual data! See `DIAGRAM_MCP_DATA_INTEGRATION.md` for details.

## 🎯 Why Claude API?

Claude API is the preferred method because it:
- ✅ Provides excellent diagram generation with accurate syntax
- ✅ Handles complex diagram requirements well
- ✅ Produces syntactically valid output
- ✅ Works reliably with all diagram formats (Mermaid, PlantUML, DOT, Text)
- ✅ Automatically gathers GTD data when needed

**Fallback:** If Claude API is not configured, the system falls back to the deep analysis model or persona helper.

## ⚙️ Configuration

### Claude API Configuration (Preferred)

The diagram generator automatically uses Claude API if configured. Set your Anthropic API key:

**Option 1: Environment Variable**
```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

**Option 2: Config File**
Add to your `.gtd_config_ai`:
```bash
ANTHROPIC_API_KEY="sk-ant-..."
```

**Option 3: API Key File**
```bash
echo 'sk-ant-...' > ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
chmod 600 ~/code/dotfiles/zsh/ANTHROPIC_API_KEY
```

### Fallback Configuration (Deep Model)

If Claude API is not configured, the system falls back to the deep model. Add to your `.gtd_config` or `.gtd_config_ai`:

```bash
# Deep model URL (defaults to LM Studio URL)
GTD_DEEP_MODEL_URL="http://localhost:1234/v1/chat/completions"

# Deep model name (defaults to "gpt-oss-20b")
GTD_DEEP_MODEL_NAME="gpt-oss-20b"
```

## 🚀 How It Works

### Priority Order
1. **Claude API** (preferred) - Uses `gtd_claude_diagram_helper.py` via `claude_ollama_bridge`
2. **Deep Model** (fallback) - Uses `gtd_deep_model_helper.py` with GPT-OSS 20b
3. **Persona Helper** (last resort) - Uses `gtd_persona_helper.py` with Tim Ferriss persona

### Benefits of Claude API
- More reliable diagram generation
- Better syntax accuracy
- Automatic GTD data gathering
- Works with all diagram formats

## 📊 Usage

No changes needed! Just use diagram generation as before:

```bash
# Create mindmap
gtd-diagram mindmap "GTD System Overview"

# Create flowchart
gtd-diagram flowchart "Daily Review Process"

# With specific format
gtd-diagram mindmap "Topic" --format plantuml
gtd-diagram flowchart "Process" --format dot
```

## 🔧 Technical Details

### Helper Script

A new helper script was created:
- **Location:** `bin/gtd_deep_model_helper.py`
- **Purpose:** Call deep model directly for diagram generation
- **Configuration:** Reads from config files and environment variables

### Fallback Behavior

If deep model is not available:
1. Tries to use deep model helper
2. Falls back to persona helper (Tim Ferriss persona)
3. Shows warning message about fallback

## 💡 Benefits

- ✅ **Better diagrams** - Deep model generates more accurate syntax
- ✅ **Fewer errors** - Less post-processing needed
- ✅ **More reliable** - Better understanding of visual structures
- ✅ **Automatic** - No configuration needed (uses defaults)
- ✅ **Flexible** - Can configure custom model/URL if needed

## 🔍 Verification

To verify deep model is being used:

1. Run diagram generation:
   ```bash
   gtd-diagram mindmap "Test Topic"
   ```

2. Look for this message:
   ```
   🤖 Using deep analysis model for better diagram generation...
   ```

3. If you see:
   ```
   ⚠️  Using persona helper (deep model helper not found)...
   ```
   Then the deep model helper wasn't found. Check that:
   - `bin/gtd_deep_model_helper.py` exists
   - It's executable: `chmod +x bin/gtd_deep_model_helper.py`

## 🐛 Troubleshooting

### Deep Model Not Available

If the deep model isn't working:

1. **Check LM Studio is running** with deep model loaded
2. **Verify model name** matches your LM Studio model
3. **Check URL** is correct (default: `http://localhost:1234`)
4. **Test connection:**
   ```bash
   curl http://localhost:1234/v1/models
   ```

### Fallback to Persona Helper

If you see the fallback warning:
- Diagram generation still works (uses persona helper)
- Deep model just isn't available
- You can continue using it or fix deep model configuration

### Configuration Issues

If deep model isn't found:
- Check config files: `.gtd_config`, `.gtd_config_ai`
- Verify environment variables if using them
- Default model name is `gpt-oss-20b`
- Default URL is same as LM Studio URL

## 📚 Related Documentation

- **Diagram Generation:** `zsh/DIAGRAM_GENERATION_GUIDE.md`
- **Diagram Formats:** `zsh/DIAGRAM_FORMATS_QUICK_START.md`
- **Deep Analysis Worker:** `mcp/README.md` (for background analysis)
- **LM Studio Setup:** `mcp/LM_STUDIO_SETUP.md`

## 🎉 Result

Your diagrams should now be:
- More accurate syntactically
- Better structured
- More reliable
- Requiring fewer fixes

Enjoy your improved diagram generation! 🎨📊

