# TOON Format for Personalization

## Overview

The personalization system now uses **TOON (Token Output Object Notation)** format instead of JSON for storing personalization data. This provides significant token savings (30-60% reduction) when the AI reads and processes personalization information.

## What is TOON?

TOON is a compact, lossless, human-readable serialization format designed especially for large language models (LLMs). It uses:
- YAML-like indentation for object nesting
- CSV-style/tabular layout for uniform arrays of objects
- Minimal syntax to reduce token usage

## Benefits

1. **Token Efficiency**: 30-60% fewer tokens compared to JSON
2. **AI-Friendly**: Designed specifically for LLM consumption
3. **Lossless**: Full fidelity with JSON data model
4. **Automatic Migration**: Existing JSON files are automatically migrated

## File Location

- **TOON Format**: `~/.gtd_personalization.toon`
- **Legacy JSON**: `~/.gtd_personalization.json` (automatically migrated)

## Implementation

### TOON Helper Module

The system uses `zsh/functions/gtd_toon_helper.py` which provides:

- `load_toon_file(path)` - Load TOON file with JSON fallback
- `save_toon_file(path, data)` - Save data to TOON format
- `get_personalization_file_path()` - Get the personalization file path
- `migrate_json_to_toon()` - Migrate existing JSON to TOON

### Automatic Fallback

If a TOON library is not installed, the system automatically falls back to JSON format. This ensures the system continues to work even without TOON support.

### Migration

When the system detects an existing `.gtd_personalization.json` file:
1. It automatically loads the JSON data
2. Converts it to TOON format
3. Saves as `.gtd_personalization.toon`
4. Creates a backup of the original JSON file

## Installing TOON Libraries

To use TOON format, install one of these Python libraries:

```bash
# Option 1: py-toon-format (recommended)
pip install py-toon-format

# Option 2: python-toon
pip install python-toon

# Option 3: toon-python
pip install toon-python
```

The system will automatically detect and use whichever library is available.

## Example TOON Format

### JSON (before):
```json
{
  "goals": {
    "career": ["Learn Kubernetes", "Pass CKA exam"],
    "personal": ["Maintain work-life balance"]
  },
  "values": ["Continuous learning", "Work-life balance"]
}
```

### TOON (after):
```
goals:
  career[2]: Learn Kubernetes,Pass CKA exam
  personal[1]: Maintain work-life balance
values[2]: Continuous learning,Work-life balance
```

Notice the significant reduction in tokens while maintaining the same information.

## Updated Files

The following files have been updated to use TOON:

1. `zsh/functions/gtd_toon_helper.py` - New TOON helper module
2. `bin/gtd-wizard-personalization.sh` - Wizard uses TOON
3. `zsh/functions/gtd_tool_registry.py` - Tool registry uses TOON
4. `mcp/gtd_mcp_server.py` - MCP server uses TOON
5. `mcp/skills/personalization-info/scripts/read_personalization.py` - Skill script uses TOON

## Backward Compatibility

The system maintains full backward compatibility:
- Existing JSON files are automatically migrated
- If TOON library is not available, falls back to JSON
- All existing functionality continues to work

## Usage

No changes needed in how you use the personalization system:

```bash
# Still works the same way
gtd-wizard
# Select: 67) Personalization Setup
```

The system automatically handles TOON format behind the scenes.

## Benefits for AI Processing

When the AI reads personalization data:
- **Before (JSON)**: ~500 tokens for typical personalization data
- **After (TOON)**: ~200-300 tokens (40-60% reduction)

This means:
- Faster processing
- Lower API costs
- More context available for other information
- Better token efficiency in prompts

## Troubleshooting

### TOON library not found

If you see warnings about TOON library not being available:
1. Install one of the TOON libraries (see above)
2. The system will automatically use it on next access
3. Or continue using JSON format (fully supported)

### Migration issues

If migration fails:
1. Check that you have write permissions to `~/.gtd_personalization.json`
2. The system will continue using JSON format
3. No data loss occurs

### File not found

If the system can't find the personalization file:
1. Check both `.toon` and `.json` files exist
2. Run the wizard to initialize: `gtd-wizard → 67`
3. The system will create the appropriate format

## Future Enhancements

Potential improvements:
- Automatic TOON library installation
- Format validation
- Performance metrics
- Token usage tracking
