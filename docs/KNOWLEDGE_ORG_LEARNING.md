# Knowledge Organization Learning System

## Overview

The Learning System tracks your decisions about MoC/Area suggestions and automatically improves future recommendations. It learns your preferences and adjusts confidence thresholds to show you more relevant suggestions over time.

## How It Works

### 1. **Decision Tracking**

Every time you accept, reject, or skip a suggestion, the system records:
- Suggestion type (area assignment, MoC creation, area creation)
- Your decision (accepted/rejected/skipped)
- Confidence score
- Suggestion details (area name, MoC topic, etc.)

### 2. **Pattern Recognition**

The system identifies patterns in your decisions:
- **Accepted Areas**: Which areas you frequently assign projects to
- **Rejected Areas**: Which areas you tend to reject
- **MoC Topics**: Which topics you like to organize vs. ignore
- **Confidence Levels**: What confidence scores you typically accept

### 3. **Threshold Adjustment**

Confidence thresholds automatically adjust based on your acceptance rate:

| Acceptance Rate | Action | Result |
|----------------|--------|--------|
| > 90% | Lower threshold by 5% | More suggestions shown |
| 50-90% | Keep threshold | Good balance |
| < 50% | Raise threshold by 5% | Fewer, higher-quality suggestions |

**Default Thresholds:**
- Area Assignment: 70%
- MoC Creation: 75%
- Area Creation: 75%

### 4. **Confidence Boosting**

Future suggestions get confidence adjustments based on patterns:
- **+10% boost**: If you've accepted similar suggestions before
- **-10% penalty**: If you've rejected similar suggestions before

Example:
```
Original suggestion: "Assign project to Work - SRE" (80% confidence)
Pattern: You've accepted 5 "Work - SRE" assignments before
Boosted confidence: 90%
Result: Higher priority in results
```

## Using the Learning System

### View Learning Stats

```bash
# From wizard
gtd-wizard
→ 24 (AI Tools)
→ 18 (View Knowledge Organization Learning Stats)

# Or directly
python3 ~/code/dotfiles/mcp/knowledge_org_learning.py stats
```

### Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Knowledge Organization Learning Stats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Confidence Thresholds:
  area_assignment: 65%
  moc_creation: 75%
  area_creation: 80%

Total Decisions: 47

Statistics by Type:
  area_assignment:
    Accepted: 38
    Rejected: 5
    Acceptance Rate: 88%
  
  moc_creation:
    Accepted: 3
    Rejected: 1
    Acceptance Rate: 75%

Top Accepted Areas:
  • work-sre: 15x
  • health-fitness: 8x
  • home-automation: 5x

Top Accepted MoC Topics:
  • Kubernetes Operations: 2x
  • SRE Best Practices: 1x
```

### Reset Learning Data

If you want to start fresh:

```bash
# From wizard
gtd-wizard
→ 24 (AI Tools)
→ 18 (Learning Stats)
→ 1 (Reset learning data)

# Or directly
python3 ~/code/dotfiles/mcp/knowledge_org_learning.py reset
```

This creates a backup and resets to default thresholds.

## Learning in Action

### Scenario 1: High Acceptance Rate

```
Week 1: Accept 9 out of 10 area assignment suggestions
System: "User accepts almost everything, lower threshold"
Threshold: 70% → 65%
Result: More suggestions shown in future scans
```

### Scenario 2: Low Acceptance Rate

```
Week 1: Accept 2 out of 10 MoC creation suggestions
System: "User is selective, raise threshold"
Threshold: 75% → 80%
Result: Fewer, higher-confidence suggestions shown
```

### Scenario 3: Pattern Recognition

```
History:
  - Accepted "Work - SRE" 15 times
  - Rejected "Personal - Finance" 3 times

New Suggestions:
  - "Assign monitoring project to Work - SRE" (75% confidence)
    → Boosted to 85% (pattern match)
  
  - "Assign budget project to Personal - Finance" (80% confidence)
    → Reduced to 70% (rejection pattern)
```

## Data Storage

Learning data is stored in:
```
~/Documents/gtd/knowledge_org_learning.json
```

### Data Structure

```json
{
  "version": "1.0",
  "thresholds": {
    "area_assignment": 0.70,
    "moc_creation": 0.75,
    "area_creation": 0.75
  },
  "decisions": [
    {
      "timestamp": "2024-01-15T10:30:00",
      "type": "area_assignment",
      "decision": "accepted",
      "confidence": 0.85,
      "suggestion": {
        "project_slug": "dlq-monitoring",
        "suggested_area": "work-sre"
      }
    }
  ],
  "stats": {
    "area_assignment": {
      "accepted": 38,
      "rejected": 5
    }
  },
  "patterns": {
    "accepted_areas": {
      "work-sre": 15,
      "health-fitness": 8
    },
    "rejected_areas": {
      "personal-finance": 3
    }
  }
}
```

## Integration Points

### 1. Worker (`gtd_knowledge_organize_worker.py`)

When generating suggestions:
- Boosts confidence based on patterns
- Filters out low-confidence suggestions
- Includes learning stats in results

### 2. Implementation Helper (`knowledge_org_implement.py`)

When implementing suggestions:
- Records "accepted" for successful implementations
- Records "rejected" for failed implementations
- Updates learning data immediately

### 3. Wizard (`gtd-wizard-tools.sh`)

When reviewing results:
- Displays learning stats with suggestions
- Shows adjusted confidence thresholds
- Provides option to view detailed stats (Option 18)

## Benefits

### 1. **Personalized Suggestions**
System learns your preferences and shows more relevant suggestions over time.

### 2. **Reduced Noise**
Low-quality suggestions are automatically filtered out based on your acceptance patterns.

### 3. **Improved Confidence**
Suggestions you're likely to accept get boosted confidence scores.

### 4. **Adaptive Thresholds**
System adjusts to your workflow - if you're selective, it shows fewer but better suggestions.

### 5. **Pattern Recognition**
Identifies which areas/topics you care about and prioritizes those.

## Advanced Features

### Minimum Decision Threshold

System requires at least **10 decisions** before adjusting thresholds. This prevents premature adjustments from small sample sizes.

### Decision History Limit

Keeps last **1000 decisions** to prevent file bloat while maintaining good learning data.

### Confidence Bounds

- Minimum threshold: 50%
- Maximum threshold: 95%
- Boost/penalty range: ±10%

This ensures suggestions remain useful even with extreme acceptance patterns.

## Troubleshooting

### Too Many Suggestions

If you're getting overwhelmed:
1. Reject more suggestions
2. System will automatically raise thresholds
3. Or manually reset learning data

### Too Few Suggestions

If you're not seeing enough:
1. Accept more suggestions when they appear
2. System will lower thresholds
3. Or manually reset learning data

### Incorrect Patterns

If system learned wrong patterns:
```bash
# Reset and start fresh
python3 ~/code/dotfiles/mcp/knowledge_org_learning.py reset
```

### View Raw Data

```bash
# View learning file
cat ~/Documents/gtd/knowledge_org_learning.json | python3 -m json.tool
```

## Privacy & Data

- All learning data is stored **locally** on your machine
- No data is sent to external services
- Learning file can be deleted at any time
- Backups are created when resetting

## Future Enhancements

Planned improvements:
- [ ] Time-based patterns (work areas during weekdays, personal on weekends)
- [ ] Project similarity matching (suggest areas based on similar past projects)
- [ ] Confidence decay (older patterns have less weight)
- [ ] Export/import learning data
- [ ] Learning visualization dashboard

## See Also

- [Knowledge Organization System](KNOWLEDGE_ORGANIZATION_SYSTEM.md)
- [GTD System Documentation](README.md)
- [MCP Server Setup](../mcp/README.md)

