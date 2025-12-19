# Enhanced Learning System Features

## Overview

Your GTD system now has a **comprehensive, intelligent learning system** with:
- ✅ Unified learning across ALL suggestion types
- ✅ Explainability (see WHY suggestions were made)
- ✅ Nuanced feedback (1-5 star ratings + reasons)
- ✅ Manual controls (fine-tune thresholds)
- ✅ Cross-domain intelligence

## What's New

### 1. Nuanced Feedback System ⭐

**Before**: Binary accept/reject
```
Accept or reject? (y/N): 
```

**Now**: Rated feedback with reasons
```
Rate this suggestion (1-5 stars):
  1 ⭐ - Not relevant at all
  2 ⭐⭐ - Wrong timing/context
  3 ⭐⭐⭐ - Okay but not perfect
  4 ⭐⭐⭐⭐ - Good suggestion
  5 ⭐⭐⭐⭐⭐ - Excellent, exactly what I needed

Rating: 4

Why not 5 stars? (optional):
  - wrong-context
  - wrong-time
  - not-relevant
  - other (specify)
```

**How It Works:**
- Ratings 4-5: Counted as "accepted", boost similar suggestions
- Rating 3: Neutral feedback, provides data without strong signal
- Ratings 1-2: Counted as "rejected", reduce similar suggestions
- Feedback reasons: Used for pattern recognition

### 2. Explainability System 🔍

**Before**: No explanation
```
Assign "dlq-monitoring" to "Work - SRE" (85% confidence)
```

**Now**: Full explanation
```
Assign "dlq-monitoring" to "Work - SRE"

📊 Confidence Analysis:
  Original: 78%
  Adjustments:
    +7% - You've accepted 'work-sre' 15x before
    +2% - Tags match: #sre, #monitoring
  Final: 87%

💡 Why this suggestion:
  • Pattern match: 'work-sre' frequently accepted
  • Tags match your interests
  • High acceptance rate (88%) for this type
```

**CLI Usage:**
```bash
# Explain a suggestion
python3 ~/code/dotfiles/mcp/gtd_explain_suggestions.py \
  area_assignment 0.78 work-sre sre monitoring

# Output shows:
# - Original vs final confidence
# - Each adjustment with reasoning
# - Pattern explanations
```

### 3. Manual Threshold Controls 🎛️

**Interactive CLI:**
```bash
gtd-learning-controls
```

**Features:**
```
🎛️  GTD Learning System Controls

1) View current thresholds
2) Show more of a suggestion type (lower threshold)
3) Show less of a suggestion type (raise threshold)
4) Set custom threshold
5) View explanation for a suggestion type
6) Reset all thresholds to defaults
7) View stats
```

**Example Session:**
```
Choose: 2 (Show more)
→ MoC Creation
Current: 75% → 70%
✓ You'll see more MoC suggestions now

Choose: 5 (Explain)
→ Area Assignment

🎚️  Threshold for Area Assignment:
  Current: 65%
  Default: 70%
  Status: Lowered (showing more suggestions)
  Reason: High acceptance rate (88%)
  
  Stats: 38 accepted, 5 rejected
  Acceptance rate: 88%
```

**Programmatic API:**
```python
from gtd_unified_learning import set_threshold, adjust_threshold

# Show more area assignments
adjust_threshold("area_assignment", "more")  # 70% → 65%

# Show less MoC suggestions
adjust_threshold("moc_creation", "less")  # 75% → 80%

# Set custom threshold
set_threshold("project_suggestion", 0.60)  # Exactly 60%
```

### 4. Decision Impact Preview 🔮

**See how your decision affects future:**
```
Accept "Assign project to Work - SRE"?

🔮 Impact of accepting:
  ✓ Similar suggestions will get +confidence boost
  ✓ Future 'work-sre' suggestions prioritized
  ✓ If you accept >90%, threshold will lower (more suggestions)
  
Press 'y' to accept, 'n' to reject, 'r' to rate
```

## Using the Enhanced Features

### Scenario 1: Get Explanation for Suggestion

```bash
# When reviewing suggestions in wizard
gtd-wizard → 24 → 17 (Review Knowledge Org Results)

# For each suggestion, press 'e' for explanation
[1] Assign "monitoring-automation" to "Work - SRE" (87%)
    
Action: e (explain)

📊 Confidence Analysis:
  Original: 78%
  Adjustments:
    +7% - You've accepted 'work-sre' 15x before
    +2% - Tag match: #sre (+1%), #monitoring (+1%)
  Final: 87%

💡 Why this suggestion:
  • Pattern match: 'work-sre' frequently accepted
  • Tags align with your interests
  • Similar projects assigned before
```

### Scenario 2: Give Nuanced Feedback

```bash
# When a suggestion is close but not perfect
Rate this suggestion (1-5): 3

Reason (optional): wrong-time

# System learns:
# - Suggestion was okay (not rejected)
# - But timing was off
# - May suggest again later
```

### Scenario 3: Fine-Tune System

```bash
gtd-learning-controls

# "I'm getting too many MoC suggestions"
Choose: 3 (Show less)
→ MoC Creation
✓ Threshold raised: 75% → 80%

# "I want more task suggestions"
Choose: 2 (Show more)
→ Task from Log
✓ Threshold lowered: 60% → 55%

# "Set exact threshold for areas"
Choose: 4 (Custom)
→ Area Assignment
→ 72%
✓ Threshold set to 72%
```

### Scenario 4: Understand System Behavior

```bash
gtd-learning-controls

Choose: 5 (Explain type)
→ Area Assignment

🎚️  Threshold for Area Assignment:
  Current: 65%
  Default: 70%
  Status: Lowered (showing more suggestions)
  Reason: High acceptance rate (88%)
  
  Stats: 38 accepted, 5 rejected
  Acceptance rate: 88%
  
  Interpretation:
    You accept most area assignment suggestions,
    so the system lowered the threshold to show
    you more. This is working well.
```

## API Reference

### Record Decision with Nuanced Feedback

```python
from gtd_unified_learning import record_decision

record_decision(
    suggestion_type="area_assignment",
    suggestion={"project": "monitoring", "area": "work-sre"},
    decision="rated",
    confidence=0.85,
    context="work-sre",
    tags=["sre", "monitoring"],
    rating=4,  # 1-5 stars
    feedback_reason="wrong-time"  # Optional
)
```

### Get Explainable Confidence Boost

```python
from gtd_unified_learning import boost_confidence_for_patterns

adjusted, explanation = boost_confidence_for_patterns(
    suggestion_type="area_assignment",
    confidence=0.78,
    context="work-sre",
    tags=["sre", "monitoring"],
    explain=True  # Returns explanation dict
)

print(f"Original: {explanation['original_confidence']:.0%}")
print(f"Final: {explanation['final_confidence']:.0%}")
for adj in explanation['adjustments']:
    print(f"  {adj['value']}: {adj['reason']}")
```

### Manual Threshold Adjustment

```python
from gtd_unified_learning import adjust_threshold, set_threshold

# Relative adjustment
adjust_threshold("moc_creation", "more")  # -5%
adjust_threshold("moc_creation", "less")  # +5%

# Absolute setting
set_threshold("project_suggestion", 0.65)  # Exactly 65%
```

## File Reference

| File | Purpose |
|------|---------|
| `mcp/gtd_unified_learning.py` | Core system with nuanced feedback |
| `mcp/gtd_explain_suggestions.py` | Explainability helper |
| `bin/gtd-learning-controls` | Interactive CLI for manual controls |
| `~/Documents/gtd/unified_learning.json` | Learning data storage |

## Benefits of Enhanced Features

### 1. Better Learning from Ambiguous Cases

**Before:**
- Binary: Accept or reject
- Lost nuance: "It's good but timing is wrong"

**Now:**
- Give 3-star rating with "wrong-time" reason
- System learns: "Good suggestion, show later"

### 2. Understand System Decisions

**Before:**
- "Why is this suggestion here?"
- "Why 85% confidence?"

**Now:**
- See exact confidence calculation
- Understand which patterns influenced it
- Know why it was boosted/penalized

### 3. Fine-Tune Without Waiting

**Before:**
- Wait for 10+ decisions for auto-adjustment
- Can't control suggestion volume

**Now:**
- Immediately adjust any threshold
- See current vs default
- Understand why adjustments happened

### 4. Rich Feedback Data

**Before:**
- Limited data: accept/reject only
- Can't distinguish "bad" from "wrong timing"

**Now:**
- Star ratings: 5 levels of feedback
- Reasons: wrong-time, wrong-context, not-relevant
- Better pattern recognition

## Example: Full Workflow

```bash
# 1. Get suggestions
gtd-wizard → 24 → 17

# 2. See suggestion with explanation
[1] Assign "dlq-automation" to "Work - SRE" (87%)
    Original: 78% → Final: 87% (+9% pattern boost)
    
# 3. Not quite right, give nuanced feedback
Rate (1-5): 3
Reason: wrong-time

# 4. Check if too many suggestions
gtd-learning-controls → 1 (View thresholds)
Area Assignment: 65% (↓ showing more)

# 5. Adjust
gtd-learning-controls → 3 (Show less)
→ Area Assignment
✓ 65% → 70%

# 6. Verify
gtd-learning-controls → 5 (Explain)
→ Area Assignment
Shows: Threshold raised, will show fewer suggestions

# 7. Check stats
gtd-learning-controls → 7 (Stats)
Overall acceptance: 82%
Area assignments: 88% (38 accepted, 5 rejected)
```

## Migration Notes

All existing learning data is compatible. The enhanced features add:
- `rating` field (optional, defaults to null)
- `feedback_reason` field (optional, defaults to null)
- Explanation data (computed on-demand, not stored)

No migration needed! Just start using the new features.

## Next Steps

1. **Try the CLI**: `gtd-learning-controls`
2. **Get explanations**: Press 'e' when reviewing suggestions
3. **Give nuanced feedback**: Use 1-5 ratings instead of accept/reject
4. **Fine-tune thresholds**: Adjust to your preference
5. **Check impact**: See how decisions affect future

Your GTD system is now significantly smarter and more transparent! 🎉

