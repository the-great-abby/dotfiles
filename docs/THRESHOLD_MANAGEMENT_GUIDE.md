# Suggestion Threshold Management Guide

## Overview

The GTD system uses **confidence thresholds** to determine which suggestions to show you. If you've been rejecting many suggestions, the system automatically raises thresholds (showing fewer suggestions). This guide shows you how to view and adjust these thresholds.

## Quick Access

### Through Wizard (Recommended)
```
gtd-wizard → 24) AI Suggestions & MCP Tools → 20) Manage Suggestion Thresholds
```

### Standalone Script
```bash
gtd-learning-controls
```

### Diagnostic Tool
```bash
gtd-diagnose-suggestions
```

## Understanding Thresholds

**What are thresholds?**
- A confidence score (0-100%) that a suggestion must meet to be shown
- Lower threshold = more suggestions shown
- Higher threshold = fewer, higher-quality suggestions shown

**Why do they change?**
- System learns from your accept/reject decisions
- If acceptance rate < 50% → threshold raises by 5%
- If acceptance rate > 90% → threshold lowers by 5%

**Default Thresholds:**
- Task from Log: 60%
- Area Assignment: 70%
- MoC Creation: 75%
- Area Creation: 75%
- Project Suggestion: 70%
- Insight: 65%

## Viewing Current Thresholds

### Option 1: Through Wizard
1. `gtd-wizard → 24 → 20`
2. View current thresholds at the top of the menu

### Option 2: Diagnostic Script
```bash
gtd-diagnose-suggestions
```
Shows:
- Current vs default thresholds
- Acceptance rates
- How many suggestions are being filtered out
- Recommendations

### Option 3: Learning Stats
```bash
gtd-wizard → 24 → 18  # View Unified Learning Stats
```

## Adjusting Thresholds

### Show MORE Suggestions (Lower Threshold)

**Through Wizard:**
1. `gtd-wizard → 24 → 20 → 1`
2. Select suggestion type
3. Threshold lowers by 5%

**Standalone:**
```bash
gtd-learning-controls
# Choose: 2) Show more of a suggestion type
```

**Manual (Python):**
```python
from gtd_unified_learning import adjust_threshold
adjust_threshold("task_from_log", "more")  # Lowers by 5%
```

### Show LESS Suggestions (Raise Threshold)

**Through Wizard:**
1. `gtd-wizard → 24 → 20 → 2`
2. Select suggestion type
3. Threshold raises by 5%

**Standalone:**
```bash
gtd-learning-controls
# Choose: 3) Show less of a suggestion type
```

**Manual (Python):**
```python
from gtd_unified_learning import adjust_threshold
adjust_threshold("area_assignment", "less")  # Raises by 5%
```

### Set Custom Threshold

**Through Wizard:**
1. `gtd-wizard → 24 → 20 → 3`
2. Select suggestion type
3. Enter percentage (0-100%)

**Standalone:**
```bash
gtd-learning-controls
# Choose: 4) Set custom threshold
```

**Manual (Python):**
```python
from gtd_unified_learning import set_threshold
set_threshold("task_from_log", 0.55)  # Set to 55%
```

### Reset to Defaults

**Through Wizard:**
1. `gtd-wizard → 24 → 20 → 5`
2. Confirm reset

**Standalone:**
```bash
gtd-learning-controls
# Choose: 6) Reset all thresholds to defaults
```

**Manual (Python):**
```python
from gtd_unified_learning import load_learning_data, save_learning_data, SUGGESTION_TYPES

data = load_learning_data()
for stype, info in SUGGESTION_TYPES.items():
    data['thresholds'][stype] = info['default_threshold']
save_learning_data(data)
```

## Getting Explanations

### View Explanation for a Type

**Through Wizard:**
1. `gtd-wizard → 24 → 20 → 4`
2. Select suggestion type

Shows:
- Current threshold vs default
- Acceptance rate
- Stats (accepted/rejected)
- Why threshold was adjusted

**Standalone:**
```bash
gtd-learning-controls
# Choose: 5) View explanation for a suggestion type
```

## Troubleshooting

### "I'm not seeing many suggestions"

1. **Run diagnostic:**
   ```bash
   gtd-diagnose-suggestions
   ```
   Or: `gtd-wizard → 24 → 20 → 6`

2. **Check if thresholds are too high:**
   - Look for thresholds marked with `(↑ showing less)`
   - Compare to defaults

3. **Lower thresholds:**
   - `gtd-wizard → 24 → 20 → 1` (Show more)
   - Or reset to defaults: `gtd-wizard → 24 → 20 → 5`

### "I'm seeing too many low-quality suggestions"

1. **Raise thresholds:**
   - `gtd-wizard → 24 → 20 → 2` (Show less)

2. **Set custom higher threshold:**
   - `gtd-wizard → 24 → 20 → 3`
   - Enter a higher percentage (e.g., 80%)

### "I want to see what's being filtered"

Run the diagnostic:
```bash
gtd-diagnose-suggestions
```

It shows:
- How many pending suggestions exist
- How many are filtered out by thresholds
- Which suggestions would be shown

## File Location

Thresholds are stored in:
```
~/Documents/gtd/unified_learning.json
```

You can edit this file directly if needed, but using the wizard or scripts is recommended.

## Best Practices

1. **Start with defaults** - The system learns from your decisions
2. **Adjust gradually** - Use 5% adjustments first
3. **Monitor acceptance rates** - If you're accepting most suggestions, thresholds will lower automatically
4. **Use diagnostic** - Run `gtd-diagnose-suggestions` if suggestions seem off
5. **Reset if needed** - If thresholds get too high/low, reset to defaults and let the system relearn

## Examples

### Example 1: Too Few Suggestions

**Problem:** Not seeing many task suggestions from daily logs

**Solution:**
```bash
gtd-wizard → 24 → 20 → 1 → 1  # Show more Task from Log
```

**Result:** Threshold lowers from 60% → 55% (more suggestions shown)

### Example 2: Too Many Low-Quality Suggestions

**Problem:** Seeing too many area assignment suggestions that you reject

**Solution:**
```bash
gtd-wizard → 24 → 20 → 2 → 2  # Show less Area Assignment
```

**Result:** Threshold raises from 70% → 75% (fewer, better suggestions)

### Example 3: Reset After Many Rejections

**Problem:** Rejected many suggestions, now seeing very few

**Solution:**
```bash
gtd-wizard → 24 → 20 → 5  # Reset all to defaults
```

**Result:** All thresholds reset to defaults, system starts fresh

## Related Commands

- `gtd-diagnose-suggestions` - Diagnostic tool
- `gtd-learning-controls` - Standalone threshold manager
- `gtd-wizard → 24 → 18` - View learning stats
- `gtd-wizard → 24 → 20` - Manage thresholds (new!)

## See Also

- [Unified Learning System Documentation](UNIFIED_LEARNING_SYSTEM.md)
- [Auto-Suggest System](AUTO_SUGGEST_SYSTEM.md)
- [Knowledge Organization Learning](KNOWLEDGE_ORG_LEARNING.md)

