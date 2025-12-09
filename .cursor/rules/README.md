# Cursor Rules System

This directory contains Cursor rules that guide AI-assisted coding. The system uses a central index for automatic, context-aware rule application.

## Quick Start

### Check Which Rules Apply to a File
```bash
python3 .cursor/rules/rule_helper.py check bin/gtd-wizard
```

### List All Rules
```bash
python3 .cursor/rules/rule_helper.py list
```

### Validate Rule Index
```bash
python3 .cursor/rules/rule_helper.py validate
```

## Rule Index System

The `index.json` file is the central registry that maps:
- **File patterns** (glob patterns) → Rules
- **Match strings** (keywords in code) → Rules
- **Always apply** rules → Always included

This allows the AI to automatically know which rules apply based on:
1. The file being edited (path matching)
2. The content of the file (keyword matching)
3. Always-applied rules (critical rules)

## Current Rules

### thinking-timer.mdc
- **When**: Operations taking > 2 seconds
- **Applies to**: Shell scripts, Python files, bin directory
- **Triggers**: LLM calls, API calls, web searches

### unit-testing.mdc
- **When**: Writing new code
- **Applies to**: All code files
- **Triggers**: Function definitions, new features

## Adding a New Rule

### 1. Create the Rule File
Create `your-rule.mdc` with frontmatter:

```markdown
---
description: Your rule description
globs: ["**/*.sh"]
alwaysApply: false
priority: 5
---

# Your Rule

Rule content...
```

### 2. Register in Index
Add to `index.json`:

```json
{
  "id": "your-rule-id",
  "file": "your-rule.mdc",
  "description": "Your rule description",
  "filePatterns": ["**/*.sh"],
  "matchStrings": ["keyword"],
  "alwaysApply": false,
  "priority": 5,
  "categories": ["category"]
}
```

### 3. Validate
```bash
python3 .cursor/rules/rule_helper.py validate
```

## Rule Matching Logic

A rule applies when **ANY** of these are true:
- File path matches a pattern in `filePatterns`
- File content contains a string in `matchStrings`
- Rule has `alwaysApply: true`

Rules are applied in priority order (higher priority first).

## File Structure

```
.cursor/rules/
├── index.json              # Central rule registry
├── rule_helper.py          # Helper script for managing rules
├── rule-index.mdc          # Documentation for the index system
├── thinking-timer.mdc       # Thinking timer rule
├── unit-testing.mdc        # Unit testing rule
└── README.md               # This file
```

## Benefits

1. **Automatic**: Rules apply based on context
2. **Maintainable**: Central index makes management easy
3. **Discoverable**: Easy to see what applies where
4. **Extensible**: Simple to add new rules
5. **Intelligent**: System understands file types and content

## Integration

The AI assistant automatically:
- Reads `index.json` to understand available rules
- Checks file patterns and match strings
- Applies relevant rules
- References the index when suggesting improvements

## Maintenance

- Update `index.json` when adding/removing rules
- Review match strings for effectiveness
- Adjust priorities as needed
- Validate index regularly
