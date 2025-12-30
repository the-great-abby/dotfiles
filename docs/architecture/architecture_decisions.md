# Architecture Decisions

**Version**: 1.0  
**Last Updated**: December 2024  
**Purpose**: Document the "why" behind key architectural decisions in the GTD system

---

## Table of Contents

1. [Language & Platform Decisions](#language--platform-decisions)
2. [Storage Architecture](#storage-architecture)
3. [Infrastructure & Deployment](#infrastructure--deployment)
4. [AI & Automation Architecture](#ai--automation-architecture)
5. [User Interface & Interaction](#user-interface--interaction)
6. [Data Flow & Processing](#data-flow--processing)
7. [Cross-Device & Sync Strategy](#cross-device--sync-strategy)

---

## Language & Platform Decisions

### ADR-001: Bash 3.2 Compatibility Requirement

**Status**: Active constraint  
**Context**: macOS ships with bash 3.2 as `/bin/bash`, and system bash cannot be upgraded.

**Decision**: All shell scripts must be compatible with bash 3.2, even though the interactive shell is zsh.

**Rationale**:
- macOS system bash is locked at version 3.2 (Apple's requirement)
- Scripts using `#!/bin/bash` will use system bash, not a newer version
- AI code assistants frequently suggest bash 4+ features that break on macOS
- Scripts need to work consistently across macOS systems without additional setup

**Consequences**:
- **Positive**: Works out-of-the-box on macOS without dependencies
- **Positive**: Ensures portability across macOS versions
- **Negative**: Cannot use modern bash features (associative arrays, case modification operators, etc.)
- **Mitigation**: Use Python for complex data structures, use delimiter-based arrays or separate arrays for key-value pairs

**Alternatives Considered**:
- Using `#!/usr/bin/env bash` to allow newer bash versions → **Rejected**: Unreliable, might point to system bash anyway
- Requiring users to install bash 5+ via Homebrew → **Rejected**: Adds setup friction, breaks portability
- Using Python exclusively → **Rejected**: Overkill for simple scripts, adds startup overhead

**Implementation Notes**:
- Cursor rules enforce bash 3.2 compatibility
- Common workarounds documented in `.cursor/rules/macos-bash-compatibility.mdc`
- Python used for features requiring associative arrays or complex data manipulation

---

### ADR-002: Bash + Python Hybrid Approach

**Status**: Active  
**Context**: Complex data structures and AI processing require capabilities beyond bash 3.2.

**Decision**: Use bash for orchestration and simple scripts, Python for complex logic, data structures, and AI integration.

**Rationale**:
- Bash excels at file operations, command orchestration, and system integration
- Python provides rich data structures, JSON handling, and libraries (pika, psycopg2, etc.)
- Natural separation: bash for "glue code", Python for "business logic"
- Python's ecosystem includes excellent libraries for vector databases, message queues, and AI

**Consequences**:
- **Positive**: Best tool for each job
- **Positive**: Leverages existing Python ecosystem
- **Negative**: Language context switching required
- **Negative**: Need to handle data passing between bash and Python

**Implementation Pattern**:
```bash
# Bash orchestrates, Python does the work
result=$(python3 "$PYTHON_SCRIPT" "$arg1" "$arg2")
# Process result in bash
```

---

## Storage Architecture

### ADR-003: Markdown Files with YAML Frontmatter (Not Database)

**Status**: Active  
**Context**: Need to store GTD content (tasks, projects, logs) in a format that's human-readable, sync-friendly, and works with Obsidian.

**Decision**: Store all GTD content as markdown files with YAML frontmatter, written directly to Obsidian vault directories.

**Rationale**:
- **Human-readable**: Can be edited directly in Obsidian or any text editor
- **Obsidian integration**: Obsidian natively reads markdown files - no API needed
- **Cross-device sync**: Obsidian Sync handles file synchronization automatically
- **Version control friendly**: Text files work well with git (though not used here)
- **No database maintenance**: Avoids schema migrations, database backups, connection management
- **Work computer compatibility**: Plain text files work even without database access

**Trade-offs**:
- **Positive**: Simple, portable, works everywhere
- **Positive**: User maintains direct control over their data
- **Positive**: Can be backed up via Obsidian Sync or simple file copy
- **Negative**: No relational queries (mitigated by vector search)
- **Negative**: No transactions (mitigated by atomic file operations)
- **Negative**: Slower for complex queries (mitigated by caching and indexing)

**Alternatives Considered**:
- SQLite database → **Rejected**: Would require sync layer, less portable
- JSON files → **Rejected**: Less human-readable, harder to edit
- Database + file export → **Rejected**: Adds complexity, sync issues

**File Format Example**:
```markdown
---
id: task-20240101-001
status: active
project: my-project
tags: [urgent, bug]
---

# Task Title

Description and notes here...
```

---

### ADR-004: Vector Database as Derived Data

**Status**: Active  
**Context**: Need semantic search over GTD content, but vectors are computationally expensive to generate.

**Decision**: Store vectors in PostgreSQL with pgvector, but treat them as derived/regeneratable data, not source of truth.

**Rationale**:
- **Vectors are derived**: They're generated from markdown files, not original data
- **Can regenerate**: If database is lost, can re-scan files and regenerate vectors
- **Source of truth**: Markdown files remain the authoritative data source
- **Search performance**: Vector database enables fast semantic search that file scanning cannot provide
- **Disaster recovery**: "Just start over" - regenerate vectors from files

**Consequences**:
- **Positive**: No critical data loss if vector DB fails
- **Positive**: Can upgrade/replace vector DB without data migration
- **Positive**: Files remain portable and readable
- **Negative**: Regeneration takes time (mitigated by incremental updates)
- **Negative**: Need to keep files and vectors in sync

**Disaster Recovery Strategy**:
1. Source of truth (markdown files) never lost (Obsidian Sync)
2. Vector database can be rebuilt by scanning files
3. Recovery time: Unknown (system currently small), but acceptable since it's background work

**Indexing Strategy**:
- Currently: No index (exact search, <1000 vectors) - fast enough
- Future: IVFFlat at ~10k vectors for better performance
- Future: HNSW at 100k+ vectors for optimal performance

---

## Infrastructure & Deployment

### ADR-005: NodePort Instead of Port-Forwarding

**Status**: Active  
**Context**: Need persistent access to PostgreSQL and RabbitMQ running in Kubernetes (Rancher Desktop).

**Decision**: Use Kubernetes NodePort services instead of `kubectl port-forward`.

**Rationale**:
- **Persistent**: NodePort services persist even if kubectl processes die
- **No process dependency**: Doesn't require running `kubectl port-forward` process
- **Survives restarts**: Works across system restarts and kubectl disconnections
- **Always available**: Service accessible at static IP:port (e.g., 192.168.64.2:30003)
- **Reliability**: Solved port-forwarding reliability issues we experienced

**Port-Forwarding Problems Solved**:
- Port-forward requires active kubectl process → breaks when disconnected
- Must manually restart after system restarts
- Temporary and fragile

**Consequences**:
- **Positive**: Much more reliable for development
- **Positive**: No manual intervention required
- **Positive**: Survives system restarts
- **Neutral**: Requires Kubernetes NodePort configuration (one-time setup)

**Configuration**:
- PostgreSQL: `192.168.64.2:30003` (NodePort)
- RabbitMQ: `192.168.64.2:30672` (NodePort)

---

### ADR-006: RabbitMQ with File Queue Fallback

**Status**: Active  
**Context**: Need reliable async job processing, but system should work even if RabbitMQ is unavailable.

**Decision**: Try RabbitMQ first for queuing, always fall back to file-based queues (JSONL files) if RabbitMQ unavailable.

**Rationale**:
- **Reliability philosophy**: "Nice to have, not critical"
  - Lost messages = missed suggestions, not data loss
  - System recovers by processing next change
- **Graceful degradation**: System works in work mode (no RabbitMQ) and home mode (RabbitMQ available)
- **Development flexibility**: Can develop/test without RabbitMQ running
- **No single point of failure**: File queues always work as fallback

**Implementation Pattern**:
```python
# Try RabbitMQ first
try:
    # Publish to RabbitMQ
    return "queued_to_rabbitmq"
except:
    # Fall back to file queue
    with open(queue_file, 'a') as f:
        f.write(json.dumps(message) + '\n')
    return "queued_to_file"
```

**Consequences**:
- **Positive**: System works in all environments
- **Positive**: No critical dependencies
- **Positive**: Easy to debug (can inspect file queues)
- **Neutral**: File queues less efficient than RabbitMQ, but acceptable

**Queue Types**:
1. **Deep Work Queue**: AI processing requests (task analysis, project suggestions)
2. **Vectorization Queue**: File change events triggering vector embedding generation
3. **Task Organization Queue**: Bulk project assignment suggestions
4. **Knowledge Organization Queue**: MoC/Area opportunity detection
5. **Second Brain Sync Queue**: Bidirectional sync jobs

---

## AI & Automation Architecture

### ADR-007: Human-in-the-Loop Command Center

**Status**: Active  
**Context**: AI can make mistakes, user needs to maintain control and trust the system.

**Decision**: All AI suggestions go through Command Center review interface - user accepts/rejects before changes are applied.

**Rationale**:
- **Trust**: User maintains control over their system
- **Quality**: Human judgment catches AI mistakes
- **Learning**: User decisions train the AI (feedback loop)
- **Non-pushy**: "Something is there" reminders, not "URGENT: REVIEW NOW"
- **Transparency**: User sees what AI is suggesting, not blind automation

**v1.0 Lesson Learned**:
- v1.0 had manual organization and maintenance
- Maintenance burden killed adoption
- **Solution**: AI handles busywork, human handles strategy decisions

**Implementation**:
- Suggestions stored in review queues
- User reviews via wizard interface (printed menus, not full TUI)
- Batch review: process multiple suggestions at once
- Actions: Accept / Reject / Skip / Retry / Rate (1-5 stars)
- All decisions recorded in unified learning system

**Consequences**:
- **Positive**: User maintains agency and control
- **Positive**: System learns from decisions
- **Positive**: High-quality suggestions over time
- **Negative**: Requires user time to review (mitigated by batch processing and smart filtering)

**Design Principles**:
- Async processing: Review on your schedule, not system's
- Transparent automation: See what it's suggesting
- Minimal context switching: One review type at a time

---

### ADR-008: Unified Learning System (Not Separate Per-Type)

**Status**: Active  
**Context**: Multiple suggestion types (tasks, projects, areas, MoCs, insights) each had separate learning systems, leading to fragmentation.

**Decision**: Single unified learning system (`gtd_unified_learning.py`) that tracks decisions across ALL suggestion types.

**Rationale**:
- **Cross-domain intelligence**: Patterns learned in one area (e.g., project assignments) inform other areas (e.g., task suggestions)
- **Single source of truth**: One learning file, consistent behavior
- **Better learning**: More data = better patterns, faster convergence
- **Easier maintenance**: One system to maintain instead of multiple
- **Unified UI**: One dashboard for all learning stats

**Before (Fragmented)**:
```
Daily Log → Task Suggestions → Learning System #1
Projects → Area Suggestions → Learning System #2
Tasks → Project Suggestions → No learning
Analysis → Insights → No learning
```

**After (Unified)**:
```
All Suggestions → gtd_unified_learning.py → Single Learning System
```

**Suggestion Types Tracked**:
1. `task_from_log` - Tasks suggested from daily log entries
2. `task_from_log_high` - High-confidence tasks (auto-review)
3. `task_from_log_auto` - Very high confidence (auto-create)
4. `area_assignment` - Assigning projects to areas
5. `moc_creation` - Creating Maps of Content
6. `area_creation` - Creating new areas of responsibility
7. `project_suggestion` - Suggesting projects from related tasks
8. `insight` - Insights from deep analysis

**Consequences**:
- **Positive**: Better pattern recognition across domains
- **Positive**: Easier to extend (add new suggestion types)
- **Positive**: Consistent API for all workers
- **Positive**: Single stats dashboard
- **Neutral**: Migration needed from old fragmented systems (one-time)

---

### ADR-009: Local LLMs (Not Cloud APIs)

**Status**: Active  
**Context**: Need AI capabilities for suggestions, analysis, and advice, but want privacy, offline capability, and no API costs.

**Decision**: Use local LLMs (Qwen or Gemma via Ollama/LM Studio) instead of cloud APIs like OpenAI.

**Rationale**:
- **Privacy**: All data stays local, no sending personal information to cloud services
- **Cost**: No API costs (use local hardware)
- **Offline**: Works without internet connection
- **Control**: Full control over models, prompts, and processing
- **Work computer**: Can run locally even on work computer (if Ollama available)

**Model Selection**:
- **Fast model**: Gemma 1b for quick responses
- **Deep model**: Qwen or Gemma (larger) for complex analysis and reasoning
- **Configurable**: Can switch between Ollama and LM Studio based on availability

**Consequences**:
- **Positive**: Privacy and data control
- **Positive**: No API costs
- **Positive**: Works offline
- **Negative**: Requires local GPU/CPU resources
- **Negative**: Slower than cloud APIs (acceptable trade-off)
- **Negative**: Model quality may be lower than GPT-4 (acceptable for personal use)

**Configuration**:
- Stored in config files (`.gtd_config_ai`)
- Prompts are configurable and can be altered
- No API keys required

---

## User Interface & Interaction

### ADR-010: Printed Output Menus (Not Full TUI)

**Status**: Active  
**Context**: Need interactive menus for Command Center reviews, but want simplicity and portability.

**Decision**: Use printed output with simple bash menus (read/echo) instead of curses/dialog/fzf TUI libraries.

**Rationale**:
- **Simplicity**: No external dependencies beyond basic shell
- **Portability**: Works everywhere bash works
- **Debuggable**: Output is plain text, easy to debug
- **Accessible**: Works in all terminals, SSH sessions, etc.
- **Sufficient**: Current needs don't require complex TUI features

**Trade-offs**:
- **Positive**: Simple, portable, no dependencies
- **Positive**: Easy to test and debug
- **Negative**: Less polished UX than proper TUI
- **Negative**: No search/filter capabilities (yet)
- **Future consideration**: May migrate to proper TUI (fzf, dialog, or custom) if needs grow

**Implementation**:
- Custom bash menu functions in `gtd-wizard-core.sh`
- Printed output with colors (ANSI escape codes)
- Simple read/echo pattern for user input
- Clear sections and formatting for readability

---

### ADR-011: Command-Line First (Not GUI)

**Status**: Active  
**Context**: User works primarily in terminal, wants low-friction logging and quick access.

**Decision**: Build command-line interface as primary interface, integrate into shell workflow.

**Rationale**:
- **Low friction**: `gtd-log "completed database optimization"` - logging happens where work happens
- **Natural workflow**: Terminal is where user already works
- **Quick access**: No context switching to separate app
- **Scriptable**: Can be automated, aliased, integrated into workflows
- **tmux integration**: Works perfectly with terminal multiplexer

**Implementation**:
- Scripts installed in PATH
- zsh aliases for common operations
- zsh functions for complex workflows
- Tab completion for commands
- Primary command: `gtd-log` for freeform logging

**Consequences**:
- **Positive**: Zero friction logging
- **Positive**: Natural workflow integration
- **Positive**: Powerful and flexible
- **Negative**: Learning curve for commands (mitigated by `gtd-learn` instructor)
- **Negative**: Not accessible to non-technical users (acceptable for personal system)

---

## Data Flow & Processing

### ADR-012: Semantic Chunking at Document Structure Boundaries

**Status**: Active  
**Context**: Need to chunk markdown files for vectorization, but want to preserve semantic meaning and document structure.

**Decision**: Chunk markdown files at semantic boundaries (headers, paragraphs) rather than arbitrary character/token counts.

**Rationale**:
- **Semantic preservation**: Chunks at paragraph/header boundaries maintain meaning
- **Context preservation**: Heading hierarchy prepended to chunks ("Main Topic > Subtopic")
- **Better search**: Chunks represent complete thoughts, not fragments
- **Structure awareness**: Respects document organization

**Chunking Strategy**:
1. **Primary split**: Header boundaries (`# `, `## `, etc.)
2. **Secondary split**: Paragraph boundaries (`\n\n`)
3. **Fallback**: Sentence boundaries for oversized paragraphs
4. **Overlap**: 50 tokens (10% overlap) at chunk boundaries for context

**Context Enrichment**:
Each chunk prepended with metadata before vectorization:
```
Document: /gtd/projects/acme.md
Section: Market Analysis > Competitors

[actual chunk content]
```

**Parameters**:
- `max_tokens`: 512 per chunk
- `overlap_tokens`: 50 (10% overlap)

**Consequences**:
- **Positive**: Better semantic search results
- **Positive**: Preserves document structure
- **Positive**: Maintains context across chunks
- **Neutral**: More complex than simple token splitting (acceptable complexity)

---

### ADR-013: File Watcher with Debouncing

**Status**: Active  
**Context**: Need to automatically vectorize files when they change, but rapid edits could trigger excessive processing.

**Decision**: File watcher uses 2-second debounce timer to batch rapid file changes before processing.

**Rationale**:
- **Efficiency**: Prevents processing same file multiple times during rapid edits
- **Resource conservation**: Reduces unnecessary vectorization jobs
- **User experience**: User can make multiple edits without triggering multiple jobs
- **Still responsive**: 2 seconds is fast enough for interactive editing

**Implementation**:
- Python `watchdog` library monitors directories
- 2-second debounce timer: wait 2 seconds after last change before processing
- If file modified again during debounce, timer resets
- Only processes `.md`, `.markdown`, and `.txt` files

**Consequences**:
- **Positive**: Efficient processing
- **Positive**: Good user experience
- **Neutral**: Small delay (2 seconds) before processing (acceptable)

**Known Limitation**:
- Doesn't detect file renames properly (treats as delete + create)
- Can orphan vectors or create duplicates
- **Future**: Track content hash instead of just path

---

## Cross-Device & Sync Strategy

### ADR-014: Obsidian as Sync Bridge (Not Custom Sync)

**Status**: Active  
**Context**: Need to sync GTD content across devices (home computer, work computer, mobile), but work computer has restrictions.

**Decision**: Use Obsidian Sync as the sync mechanism - GTD system writes markdown files to Obsidian vault, Obsidian handles sync.

**Rationale**:
- **Work computer approved**: Obsidian is approved software, no IT friction
- **Cross-device**: Obsidian Sync handles synchronization automatically
- **No custom infrastructure**: Don't need to build/maintain sync system
- **Human-readable**: Files sync as plain text, work everywhere
- **Mobile support**: Obsidian mobile app can access files (though UI has issues)

**Architecture**:
- GTD system writes markdown files directly to Obsidian vault
- No Obsidian API usage - just file I/O
- Obsidian Sync detects file changes and syncs
- All devices see same files (when sync works)

**Work Computer Strategy**:
- Runs in "Work Mode" (reduced features)
- Minimalist logging (stays under IT radar)
- Plain text in Obsidian (no custom scripts needed)
- Freeform journal entries that parse on home computer
- Approved tool (Obsidian) = no organizational friction

**Consequences**:
- **Positive**: Works on work computer without IT approval needed
- **Positive**: No custom sync infrastructure to maintain
- **Positive**: Leverages existing Obsidian investment
- **Negative**: Dependent on Obsidian Sync reliability
- **Negative**: Mobile UI broken/unreliable (deprioritized)

---

### ADR-015: Work/Home Mode Split (Not Feature Parity)

**Status**: Active  
**Context**: Home computer has full infrastructure (k8s, PostgreSQL, RabbitMQ), work computer has restrictions.

**Decision**: Implement "Work Mode" with reduced features instead of trying to achieve feature parity.

**Rationale**:
- **Reality acceptance**: Work computer cannot run k8s, PostgreSQL, or custom services
- **Stay under radar**: Minimalist approach avoids IT scrutiny
- **Asymmetric is OK**: Work computer generates raw logs, home computer processes them
- **Pragmatic**: Better to have limited features on work computer than none

**Mode Differences**:

| Feature | Home Mode | Work Mode |
|---------|-----------|-----------|
| Feature Set | Full | Reduced |
| AI Endpoint | LM Studio | Ollama (if available) |
| Vectorization | Enabled | Disabled |
| Database | PostgreSQL + pgvector | None |
| Semantic Search | Available | Unavailable |
| Workers | All active | Limited subset |
| File Paths | Full GTD + Second Brain | Primarily GTD |
| Logging | Same | Same |
| Obsidian Path | `$HOME/...` | `$HOME/...` (same) |

**Mode Switching**:
- Command: `gtd-set-computer work` or `gtd-set-computer home`
- Config setting stored in ignored file (persists across sessions)
- Auto-detection partially implemented (being debugged)

**Consequences**:
- **Positive**: System works on both computers
- **Positive**: Work computer stays under IT radar
- **Positive**: Home computer gets full features
- **Negative**: Asymmetric capabilities (acceptable trade-off)
- **Negative**: AI insights only generated on home computer (acceptable)

---

## Design Philosophy Principles

These principles guide all architectural decisions:

1. **Low-friction input**: Freeform logging via command-line integration
2. **Automated organization**: AI handles categorization, linking, structure
3. **Human-in-the-loop**: All suggestions reviewed via Command Center before application
4. **Emergent structure**: Maps of Content (MoCs) and Areas emerge from actual usage patterns
5. **Collaborative intelligence**: System learns from user decisions to improve suggestions
6. **Graceful degradation**: System works even when components are unavailable
7. **Source of truth**: Markdown files are authoritative, everything else is derived
8. **Privacy first**: Local processing, no cloud APIs for personal data
9. **It's all live baby**: No separate dev/prod environments, fast iteration

---

## Lessons from v1.0 → v2.0

### What Didn't Work in v1.0
- Manual organization and maintenance → **Solution**: AI automation
- Maintenance burden killed adoption → **Solution**: AI handles busywork
- Tracking productivity overhead interfered with productivity → **Solution**: Low-friction logging

### What Works in v2.0
- Command-line integration = zero friction logging
- Obsidian as sync bridge = organizational approval
- Human-in-the-loop via Command Center = maintains control
- tmux dashboard = ambient awareness without interruption
- Freeform logging = authentic patterns emerge

---

## Future Considerations

These decisions may be revisited as the system evolves:

1. **TUI Migration**: Consider proper TUI (fzf, dialog) if review interface needs grow
2. **Caching Layer**: Prevent duplicate AI processing (currently missing)
3. **Rate Limiting**: Throttle API requests properly (partial solution exists)
4. **File Rename Detection**: Track content hash instead of path for better rename handling
5. **Mobile Experience**: Fix Obsidian mobile UI or build lightweight companion

---

**Document Maintenance**: This document should be updated when significant architectural decisions are made or revisited. Each ADR should include context, decision, rationale, and consequences.

