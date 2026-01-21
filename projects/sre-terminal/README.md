# SRE Terminal: Multi-Layer Incident Response Tool

**Status:** Design Phase - Ready for Phase 1 Implementation
**Created:** 2026-01-20
**Author:** Abby @ Filevine Inc.

## Quick Overview

An interactive Claude terminal that gives SRE engineers real-time correlation of:
- **AWS Infrastructure** (CloudWatch metrics, logs, instances, databases)
- **Deployment Pipeline** (Octopus Deploy releases and status)
- **Container Orchestration** (Kubernetes pod status, logs, events)

All in one prompt. All read-only. All safe.

**Goal:** Reduce incident diagnosis time from 10-15 minutes to 2-3 minutes.

## The Problem

Today, during an incident:
1. Check AWS CloudWatch metrics (5 mins)
2. Search logs for errors (5 mins)
3. Check if deployment succeeded (Octopus) (2 mins)
4. Check if pod is healthy (Kubernetes) (2 mins)
5. Correlate all this to figure out root cause (5 mins)

Total: ~15 minutes before you know what to fix.

## The Solution

```
$ aws-vault exec filevine-prod -- sre-terminal

🔧 SRE> Queue on shard-f is backing up

Claude: Checking infrastructure...
[AWS] Queue depth 94%, memory spike
[Octopus] Deploy v2.1.3 ran 30min ago
[K8s] Pod OOMKilled, memory leak in logs

Root cause: New deploy has memory leak.
Recommendation: Rollback to v2.1.2

Time to answer: ~3 seconds
```

## Architecture at a Glance

```
┌─────────────────────────────────────────┐
│   User (AWS-Authenticated Session)      │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Claude Opus 4.5                    │
│   (Multi-layer Analysis Intelligence)   │
└─┬──────────────┬──────────────┬─────────┘
  │              │              │
  ▼              ▼              ▼
 AWS          Octopus      Kubernetes
 CloudWatch   Deployments  Pod Status
 Logs         Releases     Logs
 Metrics      History      Events
 Instances                 Resources
```

## Phase 1: Read-Only Mode

**What Claude CAN do:**
- ✅ View all AWS metrics and logs
- ✅ Check deployment history and status
- ✅ Inspect pod status and logs
- ✅ Correlate across all systems
- ✅ Provide analysis and recommendations

**What Claude CANNOT do:**
- ❌ Execute SSM automations
- ❌ Delete DLQ messages
- ❌ Restart pods
- ❌ Scale infrastructure
- ❌ Modify anything

**Why?** Safety first. Build confidence. Add execution capabilities in Phase 2.

## Getting Started (Phase 1)

### Prerequisites

```bash
# AWS credentials via aws-vault
aws-vault add filevine-prod

# Kubernetes config
kubectl config use-context filevine-prod

# Octopus API key
export OCTOPUS_URL="https://octopus.filevine.com"
export OCTOPUS_API_KEY="API-xxxxxxxxxxxx"

# Claude API key (if not already set)
export ANTHROPIC_API_KEY="sk-..."
```

### Launch

```bash
aws-vault exec filevine-prod -- sre-terminal
```

### Example Session

```
🔧 SRE Terminal - Full Stack
User: arn:aws:iam::123456789:user/abby@filevine.com
AWS Access: ✓ Read-only
Octopus Deploy: ✓ Read-only
Kubernetes: ✓ Read-only

🔧 SRE> What's happening with shard-f?

Claude: Investigating...
[AWS] Checking CloudWatch metrics...
[Octopus] Checking recent deployments...
[K8s] Checking pod status...

Analysis:
- Queue depth at 94% (spike started 30min ago)
- Memory usage 87% on indexer pod (baseline 45%)
- Pod restarting every 5 minutes (CrashLoopBackOff)
- New deployment v2.1.3 completed 35 minutes ago
- Pod logs show: "OutOfMemoryError: Java heap space"

Root cause: Memory leak introduced in v2.1.3

Recommendation:
1. Rollback to v2.1.2 (quickest - you can do this in Octopus UI)
2. Or scale up pod memory temporarily while investigating

Command to execute: Go to Octopus > SearchIndexer > Prod > Rollback to v2.1.2
```

## Full Design Document

**See:** `PROJECT.toon`

This TOON file contains the complete specification including:
- Architecture details
- All permitted/blocked operations
- Workflow examples
- Implementation plan
- Security considerations
- Cost analysis
- Success metrics

To load in another Claude Code session:
```python
from pathlib import Path
project_spec = Path("projects/sre-terminal/PROJECT.toon").read_text()
# Pass to Claude with: "Here's the project specification in TOON format: [project_spec]"
```

## Project Structure

```
projects/sre-terminal/
├── README.md                  (this file)
├── PROJECT.toon               (Complete specification in TOON format)
├── DESIGN.md                  (Detailed architecture document)
├── IMPLEMENTATION.md          (Step-by-step build guide)
├── src/
│   ├── sre_terminal.py        (Main entry point)
│   ├── gates/
│   │   ├── aws_gate.py
│   │   ├── octopus_gate.py
│   │   └── kubernetes_gate.py
│   ├── extractors/
│   │   ├── aws_extractor.py
│   │   ├── octopus_extractor.py
│   │   └── k8s_extractor.py
│   └── utils/
│       ├── auth.py
│       └── logging.py
├── tests/
│   ├── test_gates.py
│   └── test_extractors.py
├── docs/
│   ├── SETUP.md
│   ├── USAGE.md
│   └── TROUBLESHOOTING.md
├── requirements.txt
├── Makefile
└── .env.example
```

## Implementation Phases

### Phase 1: Read-Only Observability (Current)
- Interactive Claude terminal
- AWS read-only queries
- Octopus read-only queries
- Kubernetes read-only queries
- Multi-layer correlation
- **Estimated effort:** 12-16 hours
- **Target:** Have working version within 2 days

### Phase 2: Automated Execution with Safety Gates
- SSM automation execution (with confirmation)
- Pod restart capability
- Scaling actions
- Rollback triggers
- **Target:** Add after Phase 1 is tested for 1-2 weeks

### Phase 3: Proactive Monitoring
- Background incident detection
- Alert correlation
- Predictive recommendations
- **Target:** Nice-to-have for future

## Use Cases

**Incident Response:**
- Queue backing up? → Check deploy + pod memory + AWS metrics simultaneously
- Service slow? → Check request count + pod CPU + deployment status
- Pod crashing? → Check logs + events + memory usage + recent changes

**On-Call Support:**
- Faster diagnosis means shorter incident duration
- Better recommendations mean fewer wrong moves
- Full context means fewer escalations

**Learning:**
- See patterns in incidents over time
- Understand correlations between systems
- Build better runbooks

## Key Design Decisions

1. **Read-only first** - Safety before automation
2. **User session inheritance** - Better security (all actions audited as user)
3. **Multi-layer visibility** - AWS + Octopus + K8s correlation is the power
4. **Ollama for parsing** - Cost optimization (50% token reduction)
5. **Claude Opus** - Intelligence tier needed for complex analysis

## Integration with GTD System

Daily log integration:
```
18:30 - Used SRE terminal for shard-f incident
        Claude identified memory leak from deployment
        Resolution time: 8 minutes
        Result: Deployed rollback via Octopus
        Lessons: Monitor memory trends on new deployments
```

RPG Character rewards:
- +50 XP for incident handled
- +25 bonus for fast resolution (under 15 min)
- +10 for pattern identification

## Next Steps

1. **Read the full spec:** `PROJECT.toon`
2. **Review the design:** `DESIGN.md` (will create)
3. **Follow implementation guide:** `IMPLEMENTATION.md` (will create)
4. **Start building Phase 1**

## Questions?

This project was designed based on real incidents encountered on 2026-01-20:
- shard-f queue blocking (memory leak investigation)
- DLQ analysis (dci_textractstart)
- Need for faster deployment correlation

See daily log at: `~/Documents/daily_logs/2026-01-20.md`

---

**Last Updated:** 2026-01-20
**Status:** Ready for Phase 1 Implementation
**Next Action:** Build or assign to team member
