# Enhanced Cursor Rules System

## Overview

The enhanced cursor rules system provides **automatic, context-aware rule application** based on file patterns and content match strings. This makes the coding system more intelligent and reduces the need for manual rule management.

## Key Features

### 1. Central Index (`index.json`)
- Single source of truth for all rules
- Maps file patterns → rules
- Maps match strings → rules
- Defines priorities and categories
- Enables automatic rule discovery

### 2. Automatic Rule Selection
The system automatically determines which rules apply by:
- **File Path Matching**: Checks if file path matches glob patterns
- **Content Matching**: Scans file content for keywords/phrases
- **Always Apply**: Includes critical rules regardless of matches
- **Priority Ordering**: Applies rules in priority order

### 3. Rule Helper Script (`rule_helper.py`)
Provides utilities for:
- Checking which rules apply to a file
- Listing all available rules
- Validating the rule index
- Testing match strings

## Usage Examples

### Check Rules for a File
```bash
python3 .cursor/rules/rule_helper.py check bin/gtd-wizard
```

Output:
```
Rules applicable to: bin/gtd-wizard
================================================================================

✓ thinking-timer (priority: 10)
  Show thinking timer for operations taking longer than 2 seconds
  Reason: alwaysApply=true

✓ unit-testing (priority: 9)
  Require unit tests for all new code
  Reason: alwaysApply=true
```

### List All Rules
```bash
python3 .cursor/rules/rule_helper.py list
```

### Validate Index
```bash
python3 .cursor/rules/rule_helper.py validate
```

## Rule Matching Logic

A rule applies when **ANY** of these conditions are met:

1. **File Pattern Match**: File path matches a pattern in `filePatterns`
   ```json
   "filePatterns": ["**/*.sh", "**/bin/**"]
   ```

2. **Content Match**: File content contains a string in `matchStrings`
   ```json
   "matchStrings": ["show_thinking_timer", "LLM", "API call"]
   ```

3. **Always Apply**: Rule has `alwaysApply: true`
   ```json
   "alwaysApply": true
   ```

Rules are applied in **priority order** (higher priority first).

## Rule Structure

### In `index.json`:
```json
{
  "id": "rule-id",
  "file": "rule-file.mdc",
  "description": "Rule description",
  "filePatterns": ["**/*.sh", "**/*.py"],
  "matchStrings": ["keyword1", "keyword2"],
  "alwaysApply": false,
  "priority": 5,
  "categories": ["category1", "category2"]
}
```

### In Rule File (`.mdc`):
```markdown
---
description: Rule description
globs: ["**/*.sh", "**/*.py"]
alwaysApply: false
priority: 5
---

# Rule Name

Rule content...
```

## Benefits

### 1. **Intelligent Context Awareness**
- Rules apply automatically based on file type and content
- No need to manually specify which rules to use
- System understands what you're working on

### 2. **Maintainability**
- Central index makes it easy to manage rules
- Single place to update rule metadata
- Clear structure for adding new rules

### 3. **Discoverability**
- Easy to see which rules apply to what
- Helper script provides visibility
- Clear documentation of rule purposes

### 4. **Extensibility**
- Simple process to add new rules
- Flexible matching system
- Category-based organization

### 5. **Performance**
- Priority-based application
- Efficient matching algorithms
- Minimal overhead

## Adding a New Rule

### Step 1: Create Rule File
```bash
# Create .cursor/rules/my-rule.mdc
```

```markdown
---
description: My new rule
globs: ["**/*.sh"]
alwaysApply: false
priority: 5
---

# My New Rule

Rule content...
```

### Step 2: Register in Index
Edit `index.json`:

```json
{
  "id": "my-rule",
  "file": "my-rule.mdc",
  "description": "My new rule",
  "filePatterns": ["**/*.sh"],
  "matchStrings": ["keyword"],
  "alwaysApply": false,
  "priority": 5,
  "categories": ["category"]
}
```

### Step 3: Validate
```bash
python3 .cursor/rules/rule_helper.py validate
```

### Step 4: Test
```bash
python3 .cursor/rules/rule_helper.py check path/to/test/file.sh
```

## Best Practices

### File Patterns
- Use specific patterns: `**/bin/**` not `**/**`
- Group related files: `["**/*.sh", "**/*.bash"]`
- Consider subdirectories: `**/zsh/functions/**`

### Match Strings
- Use specific keywords: `show_thinking_timer`
- Include common patterns: `def `, `function `
- Add domain terms: `LLM`, `API call`, `web search`
- Avoid generic words: `the`, `a`, `is`

### Priorities
- **10+**: Critical rules (always apply)
- **5-9**: Important rules (context-dependent)
- **1-4**: General rules (context-dependent)
- **0**: Default rules

### Categories
Use categories to group related rules:
- `performance` - Performance optimization
- `ux` - User experience
- `testing` - Testing and QA
- `quality` - Code quality
- `bash` - Bash-specific
- `python` - Python-specific
- `security` - Security-related

## Integration with AI

The AI assistant should:
1. **Read the index** to understand available rules
2. **Check file patterns** when working on files
3. **Scan for match strings** in file content
4. **Apply relevant rules** automatically
5. **Reference the index** when suggesting improvements

## Current Rules

### thinking-timer
- **Priority**: 10
- **Always Apply**: Yes
- **Applies to**: Shell scripts, Python files
- **Triggers**: LLM calls, API calls, web searches

### unit-testing
- **Priority**: 9
- **Always Apply**: Yes
- **Applies to**: All code files
- **Triggers**: Function definitions, new features

## Future Enhancements

Potential improvements:
- Rule dependencies (rule A requires rule B)
- Rule conflicts (rule A conflicts with rule B)
- Rule suggestions based on code analysis
- Rule effectiveness metrics
- Automatic rule generation from patterns
- Rule templates for common scenarios

## Troubleshooting

### Rule Not Applying
1. Check file pattern matches: `python3 .cursor/rules/rule_helper.py check <file>`
2. Verify match strings are in file content
3. Check rule priority (lower priority rules may be overridden)
4. Ensure `alwaysApply` is set correctly

### Index Validation Fails
1. Check JSON syntax
2. Verify all required fields are present
3. Ensure rule files exist
4. Check for duplicate rule IDs

### Helper Script Issues
1. Ensure Python 3 is available
2. Check file permissions
3. Verify index.json exists and is valid JSON

## Resources

- **Index**: `.cursor/rules/index.json`
- **Helper**: `.cursor/rules/rule_helper.py`
- **Documentation**: `.cursor/rules/README.md`
- **Rule Index Doc**: `.cursor/rules/rule-index.mdc`
