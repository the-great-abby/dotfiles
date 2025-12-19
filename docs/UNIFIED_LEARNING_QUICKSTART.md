# Unified Learning System - Quick Start Guide

## What Is It?

One learning system that tracks ALL your suggestion decisions across:
- ✅ Task suggestions from daily logs
- ✅ Area assignments for projects
- ✅ MoC creation from notes
- ✅ Area creation from themes
- ✅ Project suggestions from tasks
- ✅ Insights from deep analysis

Instead of 2-3 separate learning systems, everything is now unified!

## Migration (First Time Only)

Run once to merge your existing learning data:

```bash
python3 ~/code/dotfiles/mcp/migrate_to_unified_learning.py
```

This will:
1. Merge task suggestion learning data
2. Merge knowledge organization learning data
3. Backup old files
4. Create unified learning file

## Verify Migration

Check that it worked:

```bash
# View stats
gtd-wizard
→ 24 (AI Tools)
→ 18 (View Unified Learning Stats)

# Should show combined stats from all suggestion types
```

## Key Benefits

### Before (Fragmented)
```
Task suggestions:     85% acceptance, threshold 0.60
Knowledge org:        88% acceptance, threshold 0.70

Separate learning, no cross-domain insights
```

### After (Unified)
```
Overall:              82% acceptance across all types
Work focus:           127 work vs 28 personal decisions
System tuning:        "Well-tuned to your needs"

One learning system, cross-domain intelligence
```

## New Features

### 1. Cross-Domain Insights

```
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py insights
```

Shows patterns across all suggestion types:
- Work vs personal focus
- Overall engagement level
- System calibration quality

### 2. Per-Type Stats

```
# View stats for specific suggestion type
gtd-wizard → 24 → 18 → 1 (View by type)
```

### 3. Unified Dashboard

All suggestion types in one view:
- Total decisions: 247
- Overall acceptance: 82%
- Breakdown by type
- Top patterns across all domains

## How It Improves Suggestions

### Pattern Recognition

```
Decision: Accept "Assign project to Work - SRE"
Learning: "User likes work-sre assignments"
Result: Next SRE suggestion gets +10% confidence boost
```

### Threshold Adjustment

```
Type: moc_creation
Stats: 3 accepted, 5 rejected (38% acceptance)
Action: Threshold 75% → 80%
Result: Fewer, higher-quality MoC suggestions
```

### Cross-Domain Intelligence

```
Pattern: User accepts 80% of work suggestions
Insight: Focus recommendations on work-related content
Result: Better suggestion quality across all types
```

## Verification Checklist

After migration, verify:

- [ ] Stats show combined data from old systems
- [ ] Total decisions > 0
- [ ] Thresholds are reasonable (0.50-0.95)
- [ ] Top contexts show your actual areas
- [ ] Wizard option 18 works
- [ ] New suggestions still get generated
- [ ] Accepting/rejecting updates unified stats

## Files Created

| File | Purpose |
|------|---------|
| `mcp/gtd_unified_learning.py` | Core unified learning system |
| `mcp/migrate_to_unified_learning.py` | One-time migration script |
| `mcp/gtd_task_suggestions_unified.py` | Adapter for task suggestions |
| `~/Documents/gtd/unified_learning.json` | Learning data storage |
| `docs/UNIFIED_LEARNING_SYSTEM.md` | Full documentation |

## Files Updated

| File | Changes |
|------|---------|
| `mcp/gtd_knowledge_organize_worker.py` | Uses unified learning |
| `mcp/knowledge_org_implement.py` | Records to unified system |
| `bin/gtd-wizard-tools.sh` | Option 18 shows unified stats |

## Troubleshooting

### Migration fails

**Problem**: Migration script errors

**Solution**: 
```bash
# Check if old files exist
ls ~/Documents/gtd/knowledge_org_learning.json
ls ~/Documents/gtd/suggestions/.suggestion_tracking.json

# If missing, skip migration - system will create new
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats
```

### No stats showing

**Problem**: Wizard option 18 shows empty stats

**Solution**: Make some decisions first! The system needs data to learn from.

### Thresholds seem wrong

**Problem**: Too many/few suggestions

**Solution**: Reset and let system re-learn:
```bash
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py reset
```

## Next Steps

1. **Run migration** (one time)
2. **Make decisions** on suggestions (system learns)
3. **Check stats** after 10-20 decisions
4. **Watch it improve** over time

## Need Help?

View full documentation:
```bash
cat ~/code/dotfiles/docs/UNIFIED_LEARNING_SYSTEM.md | less
```

Check current stats:
```bash
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats
```

View insights:
```bash
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py insights
```

## Summary

You now have ONE intelligent learning system that:
- ✅ Tracks ALL suggestion types
- ✅ Learns your preferences across domains
- ✅ Provides cross-domain insights
- ✅ Automatically adjusts thresholds
- ✅ Boosts confidence for preferred patterns
- ✅ Shows unified stats dashboard

Enjoy your smarter GTD system! 🎉

