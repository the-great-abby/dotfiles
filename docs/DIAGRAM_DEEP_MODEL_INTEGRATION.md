# Diagram Generation with Deep Analysis Model

## ✅ Integration Complete!

Diagram and mindmap generation now uses the **deep analysis model** (GPT-OSS 20b) instead of the regular persona model. The deep model handles visual information better and generates more accurate diagrams.

**NEW:** The diagram tool now automatically gathers GTD data (projects, tasks, areas, etc.) when you ask for diagrams about your GTD system, making diagrams based on your actual data! See `DIAGRAM_MCP_DATA_INTEGRATION.md` for details.

## 🎯 Why Deep Model?

The deep analysis model (GPT-OSS 20b) is better at:
- ✅ Understanding visual structures and relationships
- ✅ Generating correct diagram syntax
- ✅ Creating well-organized mindmaps
- ✅ Handling complex diagram requirements
- ✅ Producing syntactically valid output

## ⚙️ Configuration

### Automatic Configuration

The diagram generator automatically:
1. Loads deep model settings from config files
2. Falls back to persona helper if deep model not available
3. Uses environment variables if configured

### Manual Configuration (Optional)

Add to your `.gtd_config` or `.gtd_config_ai`:

```bash
# Deep model URL (defaults to LM Studio URL)
GTD_DEEP_MODEL_URL="http://localhost:1234/v1/chat/completions"

# Deep model name (defaults to "gpt-oss-20b")
GTD_DEEP_MODEL_NAME="gpt-oss-20b"
```

Or use environment variables:
```bash
export GTD_DEEP_MODEL_URL="http://localhost:1234/v1/chat/completions"
export GTD_DEEP_MODEL_NAME="gpt-oss-20b"
```

## 🚀 How It Works

### Before (Persona Helper)
- Used Tim Ferriss persona with regular model
- Sometimes generated incorrect syntax
- Required post-processing to fix errors

### After (Deep Model)
- Uses deep analysis model directly
- Better understanding of diagram structures
- More accurate syntax generation
- Still has fallback to persona helper if needed

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

