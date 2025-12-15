# Persona Confidence Scoring Fix

## Problem

Fitness coaches (Dean Karnazes, David Goggins) were being selected for non-fitness log entries. For example:
- "getting the car serviced" → Dean Karnazes
- "made it to the car service shop" → David Goggins

This was happening because:
1. A single keyword match gave fitness coaches a score of 2
2. This score could beat all other personas
3. No confidence threshold was required

## Solution

Implemented a confidence-based scoring system that:
1. **Counts actual keyword matches** instead of binary yes/no
2. **Requires multiple matches for fitness coaches** (minimum 2 matches = score 4+)
3. **Filters out low-confidence matches** before selection
4. **Falls back to general personas** if confidence is too low

## How It Works

### Scoring System

**Fitness Coaches** (goggins, dean, bioneer):
- Score = `match_count * 2`
- Minimum confidence required: **score >= 4** (requires 2+ matches)
- Single match gets score 1 (too low, won't be selected)

**Other Personas**:
- Score = `match_count`
- Minimum confidence required: **score >= 1** (requires 1+ match)

### Match Counting

The system now counts how many times keywords match in the log content:
- Uses `grep -oiE` or `rg -oiE` to extract matches
- Counts total matches (multiple mentions increase confidence)
- Handles empty results gracefully

### Selection Logic

1. **Score all personas** based on keyword matches
2. **Filter by confidence threshold**:
   - Fitness coaches: Need 2+ matches (score 4+)
   - Other personas: Need 1+ match (score 1+)
3. **Select from confident matches**:
   - If confident matches exist → randomly select from them
   - If no confident matches → fall back to general productivity coaches

### Example

**Log Entry**: "getting the car serviced"

**Before Fix**:
- Dean: 1 match → score 2 → **SELECTED** ❌

**After Fix**:
- Dean: 1 match → score 1 → **REJECTED** (needs score 4+) ✅
- Falls back to general persona (Hank, David, etc.)

**Log Entry**: "leg day workout at the gym"

**After Fix**:
- Goggins: 3 matches ("leg day", "workout", "gym") → score 6 → **SELECTED** ✅

## Benefits

1. **Prevents false positives**: Fitness coaches only appear for actual fitness content
2. **Requires stronger matches**: Multiple keyword matches needed for confidence
3. **Better fallback**: Low confidence → general productivity coaches
4. **More accurate selection**: Only high-confidence matches are used

## Configuration

The confidence thresholds can be adjusted in the code:
- Fitness coach minimum: `score >= 4` (2+ matches)
- General persona minimum: `score >= 1` (1+ match)

To change thresholds, modify the selection logic around line 1046-1070 in `zsh/zshrc_mac_mise`.

## Testing

Test with:
1. **Non-fitness entry**: "getting the car serviced" → Should NOT get fitness coach
2. **Fitness entry**: "leg day workout at the gym" → Should get fitness coach
3. **Weak match**: Single fitness keyword → Should fall back to general

## Location

Changes made in:
- `zsh/zshrc_mac_mise` (lines ~984-1070)

