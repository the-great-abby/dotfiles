# Knowledge Organization System

## Overview

The Knowledge Organization System automatically scans your GTD system to suggest:
- **MoCs (Maps of Content)** to create from note clusters
- **Areas of Responsibility** for orphaned projects
- **New Areas** based on daily log themes

## Components

### 1. Background Worker (`gtd_knowledge_organize_worker.py`)

Analyzes your GTD system in three phases:

#### Phase 1: Orphaned Projects → Area Assignments
- Scans projects without `area:` frontmatter
- Uses AI to classify projects into areas
- Suggests existing areas or new ones
- Confidence scoring for each suggestion

#### Phase 2: Note Clusters → MoC Suggestions
- Analyzes Zettelkasten notes for topic clusters
- Suggests MoCs when 5+ related notes found
- Uses vector search for similarity (when available)

#### Phase 3: Daily Log Themes → New Areas
- Scans last 30 days of daily logs
- Identifies frequently mentioned themes (10+ mentions)
- Suggests new areas of responsibility

### 2. Command-Line Tools

#### `gtd-moc` - MoC Management
```bash
gtd-moc create "Kubernetes Operations"    # Create new MoC
gtd-moc list                              # List all MoCs
gtd-moc view kubernetes-operations        # View MoC details
gtd-moc add-note k8s-ops 20240101-note   # Link note to MoC
gtd-moc link-project k8s-ops monitoring  # Link project to MoC
```

#### `gtd-area` - Area Management
```bash
gtd-area create "Health & Fitness"       # Create new area
gtd-area list                            # List all areas
gtd-area view health-fitness             # View area details
gtd-area add-project health workout-plan # Add project to area
gtd-area review health-fitness           # Review area
```

#### `gtd-knowledge-scan-setup` - Weekly Scan Management
```bash
gtd-knowledge-scan-setup status         # Check current status
gtd-knowledge-scan-setup install        # Enable weekly scans
gtd-knowledge-scan-setup test           # Run manual test
gtd-knowledge-scan-setup logs           # View recent logs
gtd-knowledge-scan-setup disable        # Disable weekly scans
```

### 3. Wizard Integration

#### Trigger Scan (Option 24 → 16)
```
Main Menu → 24 (AI Tools) → 16 (Scan for MoC/Area Opportunities)

Choose scan type:
  1) Full scan (all analysis)
  2) Area assignments only (orphaned projects)
  3) MoC suggestions only (note clusters)
  4) Theme analysis only (daily logs)
```

#### Review Results (Option 24 → 17)
```
Main Menu → 24 (AI Tools) → 17 (Review Knowledge Organization Results)

View suggestions by type:
  • Area assignments
  • MoC creations  
  • New area suggestions

Implementation options:
  1) Implement all suggestions
  2) Choose specific suggestions (e.g., 1,3,5)
  3) Cancel
```

#### Priority Alerts
When results are ready, wizard shows:
```
⚠️  Priority Actions:
  → Press 24 to Review MoC/Area Suggestions
    3 knowledge organization result(s) ready
```

### 4. Task Organizer Integration

When creating a new project in `gtd-task-organize`, the system now:
1. Prompts to assign to an area
2. Uses AI to suggest appropriate area
3. Offers to create new area if needed
4. Allows manual area selection

Example flow:
```
New project name: DLQ Monitoring Automation
Project outcome: Automated DLQ monitoring and alerting

💡 Would you like to assign this project to an area? (y/N): y

🤔 Analyzing project to suggest area...

💡 Suggested area: Work - SRE
Assign to this area? (Y/n): y
✓ Assigned project to area: work-sre
```

### 5. Weekly Scheduled Scans

Automatically runs every **Sunday at 9:00 AM** via launchd.

#### Setup
```bash
# Install weekly scan
gtd-knowledge-scan-setup install

# Check status
gtd-knowledge-scan-setup status

# Test manually
gtd-knowledge-scan-setup test

# View logs
gtd-knowledge-scan-setup logs
```

#### Logs Location
- Scan logs: `~/Documents/gtd/logs/knowledge-scan-YYYYMMDD.log`
- Stdout: `~/Documents/gtd/logs/knowledge-scan-stdout.log`
- Stderr: `~/Documents/gtd/logs/knowledge-scan-stderr.log`

## Usage Workflows

### Workflow 1: Manual On-Demand Scan

```bash
# From wizard
gtd-wizard
→ 24 (AI Tools)
→ 16 (Scan for MoC/Area Opportunities)
→ 1 (Full scan)

# Wait for background processing...

# Review results
gtd-wizard
→ 24 (AI Tools)
→ 17 (Review Knowledge Organization Results)
→ 1 (Implement all suggestions)
```

### Workflow 2: Weekly Automatic Scan

```bash
# One-time setup
gtd-knowledge-scan-setup install

# Every Sunday at 9 AM:
# - Scan runs automatically
# - Results saved to ~/Documents/gtd/knowledge_organization_results/
# - Notification sent (macOS)

# Review when ready
gtd-wizard
→ Priority action appears automatically
→ Press 24 to review
```

### Workflow 3: Task Organizer Integration

```bash
# When organizing tasks
gtd-task-organize
→ 1 (Review unassigned tasks)
→ Select task
→ 1 (Assign to project)
→ [Last option] (Create new project)
→ Enter project name and outcome
→ y (Assign to area)
→ AI suggests area
→ Accept or choose manually
```

## Example Outputs

### Area Assignment Suggestion
```
[1] DLQ Monitoring Automation
    → Work - SRE
    Confidence: 95%
    Reason: Project involves monitoring infrastructure and SRE operations
```

### MoC Creation Suggestion
```
[1] Create MoC: Kubernetes Operations
    Estimated notes: 15
    Confidence: 85%
    Reason: Multiple K8s notes scattered across Zettelkasten, no central reference
```

### New Area Suggestion
```
[1] Create Area: Health & Fitness
    Themes: gym, workout, fitness, training
    Confidence: 80%
    Reason: Mentioned 47x this month but no dedicated area of responsibility
```

## File Structure

```
dotfiles/
├── bin/
│   ├── gtd-moc                          # MoC management command
│   ├── gtd-area                         # Area management (existing)
│   ├── gtd-knowledge-scan-weekly        # Weekly scan script
│   ├── gtd-knowledge-scan-setup         # Setup & management
│   ├── gtd-task-organize                # Enhanced with area suggestions
│   └── gtd-wizard-tools.sh              # Enhanced with options 16 & 17
│
├── mcp/
│   ├── gtd_knowledge_organize_worker.py # Background worker
│   ├── gtd_mcp_server.py                # Enhanced with queue function
│   └── knowledge_org_implement.py       # Implementation helper
│
└── ~/Library/LaunchAgents/
    └── com.gtd.knowledge-scan.plist     # macOS scheduled job
```

## Results Storage

```
~/Documents/gtd/
├── knowledge_organization_results/
│   └── knowledge_org_YYYYMMDDHHMMSS.json  # Scan results
│
└── logs/
    ├── knowledge-scan-YYYYMMDD.log        # Daily scan logs
    ├── knowledge-scan-stdout.log          # Latest stdout
    └── knowledge-scan-stderr.log          # Latest stderr
```

## Implementation Details

### Queue System

Uses existing RabbitMQ/file queue infrastructure:
```python
queue_knowledge_organization(scan_type="full")
# → Queues to RabbitMQ (if available)
# → Falls back to file queue
```

### Worker Processing

Worker polls queue and processes:
```bash
# Manual run
python3 ~/code/dotfiles/mcp/gtd_knowledge_organize_worker.py --once --scan-type=full

# Continuous mode
python3 ~/code/dotfiles/mcp/gtd_knowledge_organize_worker.py
```

### Implementation

Suggestions are implemented via:
```bash
python3 ~/code/dotfiles/mcp/knowledge_org_implement.py \
  ~/Documents/gtd/knowledge_organization_results/knowledge_org_*.json \
  --indices=1,3,5
```

## Benefits

1. **Automated Discovery**: Automatically finds organization opportunities
2. **Reduced Manual Work**: AI suggests MoCs and Areas instead of manual creation
3. **Better Organization**: Projects get assigned to proper areas
4. **Knowledge Consolidation**: Scattered notes get organized into MoCs
5. **Proactive Maintenance**: Weekly scans keep system organized

## Future Enhancements

- [ ] Learning system: Track accepted/rejected suggestions
- [ ] Smart scheduling: Adjust scan frequency based on activity
- [ ] Bulk operations: Apply multiple suggestions at once
- [ ] Integration with search: Use MoCs for better search results
- [ ] Area health metrics: Track how well areas are maintained

## Troubleshooting

### Scan not queuing
```bash
# Check RabbitMQ status
launchctl list | grep rabbitmq

# Check file queue
ls -la ~/Documents/gtd/knowledge_organization_queue.jsonl
```

### Weekly scan not running
```bash
# Check launchd status
gtd-knowledge-scan-setup status

# Test manually
gtd-knowledge-scan-setup test

# View logs
gtd-knowledge-scan-setup logs
```

### Implementation failing
```bash
# Check area/moc commands exist
which gtd-area gtd-moc

# Check project README files have frontmatter
head ~/Documents/gtd/1-projects/*/README.md
```

## See Also

- [GTD System Documentation](README.md)
- [MCP Server Setup](../mcp/README.md)
- [Background Workers](../mcp/WORKERS.md)

