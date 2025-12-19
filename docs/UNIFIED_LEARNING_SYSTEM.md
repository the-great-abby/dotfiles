# GTD Unified Learning System

## Overview

The Unified Learning System is a single, centralized learning system that tracks decisions across **all suggestion types** in your GTD system. Instead of multiple separate learning systems, everything now feeds into one intelligent system that learns your preferences and improves all suggestions over time.

## What's Unified?

### Before (Fragmented)
```
Daily Log → Task Suggestions → gtd_smart_suggestions.py → Learning System #1
Projects → Area Suggestions → knowledge_org_learning.py → Learning System #2
Tasks → Project Suggestions → No learning
Analysis → Insights → No learning
```

### After (Unified)
```
All Suggestions → gtd_unified_learning.py → Single Learning System
  ├── Task from Log
  ├── Area Assignment
  ├── MoC Creation
  ├── Area Creation
  ├── Project Suggestion
  └── Insight
```

## Suggestion Types

The unified system tracks 8 types of suggestions:

| Type | Source | Example |
|------|--------|---------|
| `task_from_log` | Daily logs | "Review DLQ metrics" from log entry |
| `task_from_log_high` | Daily logs | High-confidence tasks (auto-review) |
| `task_from_log_auto` | Daily logs | Very high confidence (auto-create) |
| `area_assignment` | Projects | "Assign monitoring project to Work - SRE" |
| `moc_creation` | Notes | "Create 'Kubernetes Operations' MoC" |
| `area_creation` | Daily log themes | "Create 'Health & Fitness' area" |
| `project_suggestion` | Tasks | "Group DLQ tasks into 'Monitoring' project" |
| `insight` | Deep analysis | "You're most productive on Tuesday mornings" |

## How It Works

### 1. **Decision Tracking**

Every decision is recorded with rich context:

```python
record_decision(
    suggestion_type="area_assignment",
    suggestion={"project": "dlq-monitoring", "area": "work-sre"},
    decision="accepted",  # or "rejected", "skipped"
    confidence=0.85,
    context="work-sre",  # The specific area/project/topic
    tags=["work", "sre", "monitoring"]
)
```

### 2. **Pattern Recognition**

The system identifies patterns across **all domains**:

- **Context Patterns**: "User accepts 'work-sre' 15x → boost SRE suggestions"
- **Tag Patterns**: "User likes 'monitoring' tags → prioritize monitoring tasks"
- **Cross-Domain**: "User focuses on work (80%) vs personal (20%)"
- **Time Patterns**: (Future) "User accepts health suggestions on weekends"

### 3. **Adaptive Thresholds**

Per-type thresholds adjust automatically:

```
Type: area_assignment
├── Threshold: 70% → 65% (user accepts 90% of suggestions)
├── Result: More area suggestions shown
└── Learning: System is well-calibrated

Type: moc_creation
├── Threshold: 75% → 80% (user rejects 60% of suggestions)
├── Result: Fewer, higher-quality MoC suggestions
└── Learning: System is being more selective
```

### 4. **Confidence Boosting**

Suggestions get adjusted scores based on learned patterns:

```
Original: "Assign project to Work - SRE" (78% confidence)
Pattern: User accepted "work-sre" 15 times before
Boost: +10% (pattern match)
Final: 88% confidence
Result: Higher priority in results
```

## Migration from Old Systems

### Automatic Migration

Run the migration script to merge existing learning data:

```bash
python3 ~/code/dotfiles/mcp/migrate_to_unified_learning.py
```

This merges data from:
1. **Task Suggestions** (`gtd_smart_suggestions.py`)
2. **Knowledge Organization** (`knowledge_org_learning.py`)

### What Gets Migrated

- ✅ All decision history
- ✅ Confidence thresholds
- ✅ Acceptance/rejection stats
- ✅ Pattern data
- ✅ Context information

### Backup

Old learning files are automatically backed up during migration:
- `suggestions/.suggestion_tracking_backup_TIMESTAMP.json`
- `knowledge_org_learning_backup_TIMESTAMP.json`

## Using the Unified System

### View Overall Stats

```bash
# From wizard
gtd-wizard
→ 24 (AI Tools)
→ 18 (View Unified Learning Stats)

# Or directly
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats
```

### Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 GTD Unified Learning Stats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Decisions: 247
Overall Acceptance Rate: 82%

By Suggestion Type:

  Task from Log:
    Threshold: 60%
    Accepted: 95
    Rejected: 12
    Acceptance Rate: 89%

  Area Assignment:
    Threshold: 65%
    Accepted: 38
    Rejected: 5
    Acceptance Rate: 88%

  MoC Creation:
    Threshold: 80%
    Accepted: 3
    Rejected: 5
    Acceptance Rate: 38%

Top Accepted Contexts:
  • work-sre: 45x
  • health-fitness: 18x
  • home-automation: 12x
```

### View Cross-Domain Insights

```bash
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py insights
```

### Example Insights

```
💡 Cross-Domain Insights

• You focus heavily on work-related organization (127 work vs 28 personal accepts)
• You're an active user with 247 decisions tracked
• You accept most suggestions (82%) - system is well-tuned to your needs
```

### View Stats for Specific Type

```bash
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py stats --type=area_assignment
```

### Reset Learning Data

```bash
# From wizard
gtd-wizard → 24 → 18 → 2 (Reset)

# Or directly
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py reset
```

## Integration Points

### Workers Using Unified Learning

1. **Knowledge Organization Worker** (`gtd_knowledge_organize_worker.py`)
   - Boosts confidence for area/MoC suggestions
   - Filters low-confidence suggestions
   - Records acceptance/rejection

2. **Knowledge Org Implementation** (`knowledge_org_implement.py`)
   - Records decisions when implementing suggestions
   - Tracks context (area names, MoC topics)

3. **Task Suggestions** (via `gtd_task_suggestions_unified.py` adapter)
   - Backward-compatible adapter
   - Maps old threshold system to unified

4. **Future Workers**
   - Task Organization Worker (project suggestions)
   - Deep Analysis Worker (insights)
   - Any new suggestion types

### Worker Example

```python
from gtd_unified_learning import (
    record_decision,
    boost_confidence_for_patterns,
    filter_suggestions
)

# Generate suggestions
suggestions = generate_suggestions()

# Boost confidence based on patterns
for suggestion in suggestions:
    original = suggestion["confidence"]
    suggestion["confidence"] = boost_confidence_for_patterns(
        suggestion_type="area_assignment",
        confidence=original,
        context=suggestion.get("area"),
        tags=suggestion.get("tags", [])
    )

# Filter by learned thresholds
filtered = filter_suggestions(suggestions, "area_assignment")

# When user accepts/rejects
record_decision(
    suggestion_type="area_assignment",
    suggestion=suggestion,
    decision="accepted",
    confidence=suggestion["confidence"],
    context=suggestion["area"]
)
```

## Data Storage

Learning data stored in:
```
~/Documents/gtd/unified_learning.json
```

### Structure

```json
{
  "version": "2.0",
  "created": "2024-01-15T10:00:00",
  "last_updated": "2024-01-15T15:30:00",
  "thresholds": {
    "task_from_log": 0.60,
    "area_assignment": 0.65,
    "moc_creation": 0.80,
    ...
  },
  "decisions": [
    {
      "id": "decision-123",
      "timestamp": "2024-01-15T15:30:00",
      "type": "area_assignment",
      "decision": "accepted",
      "confidence": 0.85,
      "context": "work-sre",
      "tags": ["work", "sre"],
      "suggestion": {...}
    }
  ],
  "stats": {
    "area_assignment": {
      "accepted": 38,
      "rejected": 5,
      "skipped": 2
    },
    ...
  },
  "patterns": {
    "accepted_by_context": {
      "work-sre": 45,
      "health-fitness": 18
    },
    "rejected_by_context": {...},
    "accepted_by_tag": {...},
    "rejected_by_tag": {...}
  }
}
```

## Benefits of Unification

### 1. **Single Source of Truth**
- One learning file for all suggestions
- Consistent behavior across all workers
- Easier to understand and maintain

### 2. **Cross-Domain Intelligence**
- "User prefers work over personal across ALL suggestion types"
- "User is selective about MoCs but accepts most area assignments"
- Pattern recognition that spans multiple domains

### 3. **Unified UI**
- One place to view all learning stats
- Consistent stats dashboard
- Easy comparison across suggestion types

### 4. **Better Learning**
- More data = better patterns
- Cross-domain insights
- Faster convergence to optimal thresholds

### 5. **Easier Extension**
- Add new suggestion types easily
- Consistent API for all workers
- No need to rebuild learning logic

## Advanced Features

### Confidence Boosting Algorithm

```
1. Check context patterns:
   - accepted_count for context > rejected_count?
   - Boost: min(0.10, accepted_count * 0.02)

2. Check tag patterns:
   - For each tag, calculate boost/penalty
   - Sum all tag adjustments
   - Clamp to [-0.10, +0.10]

3. Apply adjustments:
   - new_confidence = original + boost - penalty
   - Clamp to [0.0, 1.0]
```

### Threshold Adjustment Algorithm

```
For each suggestion type:
  1. Calculate acceptance_rate = accepted / (accepted + rejected)
  
  2. If acceptance_rate > 90%:
       threshold -= 0.05  (show more)
     Else if acceptance_rate < 50%:
       threshold += 0.05  (show fewer, better)
     Else:
       threshold unchanged  (good balance)
  
  3. Clamp threshold to [0.50, 0.95]
  
  4. Require min 10 decisions before adjusting
```

### Decision History Limit

- Stores last 2000 decisions
- Older decisions automatically pruned
- Prevents file bloat
- Maintains good learning data

## Troubleshooting

### No Learning Data

If you see default thresholds, run migration:
```bash
python3 ~/code/dotfiles/mcp/migrate_to_unified_learning.py
```

### Thresholds Too High/Low

Reset and let system re-learn:
```bash
python3 ~/code/dotfiles/mcp/gtd_unified_learning.py reset
```

### Wrong Patterns

Learning might need more data. Make 10-20 more decisions and check again.

### View Raw Data

```bash
cat ~/Documents/gtd/unified_learning.json | python3 -m json.tool | less
```

## Future Enhancements

Planned improvements:

- [ ] **Time-based patterns**: "Work suggestions during weekdays, personal on weekends"
- [ ] **Similarity matching**: "This project is similar to one you accepted before"
- [ ] **Confidence decay**: Older patterns have less weight
- [ ] **Export/import**: Share learning data across machines
- [ ] **Visualization**: Dashboard showing learning trends over time
- [ ] **A/B testing**: Test different threshold strategies

## Migration Checklist

If you're upgrading from old learning systems:

- [ ] Backup your current learning data
- [ ] Run migration: `python3 mcp/migrate_to_unified_learning.py`
- [ ] Verify stats: `python3 mcp/gtd_unified_learning.py stats`
- [ ] Test a suggestion workflow end-to-end
- [ ] Check wizard (option 24 → 18) shows unified stats
- [ ] Monitor for 1 week to ensure system works correctly
- [ ] Remove old learning files (already backed up by migration)

## See Also

- [Knowledge Organization System](KNOWLEDGE_ORGANIZATION_SYSTEM.md)
- [Knowledge Organization Learning](KNOWLEDGE_ORG_LEARNING.md) (deprecated)
- [GTD System Documentation](README.md)
- [MCP Server Setup](../mcp/README.md)

