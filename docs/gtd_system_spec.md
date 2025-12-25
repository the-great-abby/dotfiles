# Automated GTD & Zettelkasten System
## Technical Specification

**Version**: 2.0 (Rebuild with AI Automation)  
**Last Updated**: December 2024  
**Platform**: macOS (MacBook Air, 24GB RAM)  
**Shell**: zsh (with bash 3.2 compatibility requirement for scripts)

---

## System Overview

An AI-powered personal knowledge management system combining Getting Things Done (GTD) methodology with Zettelkasten principles. The system uses background AI workers to automate task organization, completion tracking, and knowledge graph construction while maintaining human-in-the-loop decision making.

### Core Philosophy
- **Low-friction input**: Freeform logging via command-line integration
- **Automated organization**: AI handles categorization, linking, structure
- **Human-in-the-loop**: All suggestions reviewed via Command Center before application
- **Emergent structure**: Maps of Content (MoCs) and Areas emerge from actual usage patterns
- **Collaborative intelligence**: System learns from user decisions to improve suggestions

---

## Architecture

### Code Repository Structure

**Scale**: ~75+ executable scripts in `bin/` directory
- High script sprawl due to "vibe coding" development approach
- Additional MCP feature implementation in repo
- Extensive documentation alongside code
- Python helper scripts and "wizards" for complex workflows

**Organization Challenges**:
- Organic growth = less formal structure
- Scripts may call each other in undocumented ways
- "It's all live baby" - no separate dev/prod environments

### Development Constraints

**CRITICAL: Bash 3.2 Compatibility**
- macOS ships with bash 3.2 (cannot upgrade system bash)
- AI code assistants frequently suggest bash 4+ features that break
- **Known incompatibilities**:
  - `declare -A` (associative arrays) - NOT AVAILABLE in bash 3.2
  - Must use workarounds or Python for complex data structures
- **Mitigation**: Explicit reminders to AI about bash version constraints

**Script Languages**:
- Primary: bash 3.2 compatible shell scripts
- Secondary: Python for features bash can't handle
- Mix determined by: complexity, data structures needed, performance requirements

**Shell Environment**:
- Interactive shell: zsh
- Scripts: bash 3.2 compatible
- Integration: Scripts in PATH + zsh aliases + zsh functions
- **Known Issue**: Some operations clobber PATH, requires `source ~/.zshrc`

### Infrastructure Stack

**Container Orchestration**
- **Platform**: Rancher Desktop (local Kubernetes)
- **Networking**: NodePort configuration (port range 30000-32767)
  - Solved port-forwarding reliability issues
  - Stable connections for development

**Message Queue**
- **System**: RabbitMQ (containerized in k8s)
- **Client Library**: `pika` (Python)
- **Connection Handling**: 
  - Retry logic on connection failure
  - Automatic reconnection on dropped connections
  - Scripts handle transient failures gracefully
- **Queues**:
  1. **Deep Work Queue**: AI processing requests for task analysis, project suggestions, pattern detection
  2. **Vectorization Queue**: File change events triggering vector embedding generation
- **Reliability Philosophy**: "Nice to have, not critical"
  - Lost messages = missed suggestions, not data loss
  - System recovers by processing next change
- **NodePort Configuration**: *[TODO: Document actual port numbers]*

**Vector Database**
- **System**: PostgreSQL 15+ with pgvector extension
- **Client Library**: `psycopg2` (Python)
- **Connection Handling**: 
  - Retry logic on connection failure
  - Automatic reconnection on dropped connections
- **Purpose**: Semantic search over GTD content
- **Embedding Model**: Nomic embed-text v2 (768 dimensions)
- **Disaster Recovery**: "Just start over"
  - Vectors are derived data, can be regenerated
  - System knows which directories to scan
  - Recovery time: Unknown (system currently small)
- **Index Strategy**: 
  - Currently: No index (exact search, <1000 vectors)
  - Plan: Add IVFFlat at ~10k vectors
  - Future: HNSW at 100k+ vectors
- **NodePort Configuration**: *[TODO: Document actual port numbers]*

**Storage & Sync**
- **Primary Interface**: Obsidian (cross-device sync via Obsidian Sync)
- **File Format**: Markdown with YAML frontmatter
- **GTD System Interaction**: Writes files directly, no Obsidian API usage
- **Obsidian Features**: Not currently used (Dataview, Templater, etc.)
- **Frontmatter Validation**: Not yet implemented
- **Vault Structure**:
  ```
  obsidian-vault/
  ├── gtd/                    # Vectorized, AI-managed
  │   ├── tasks/
  │   ├── projects/
  │   ├── areas/
  │   ├── logs/
  │   └── reviews/
  └── second-brain/           # Not vectorized (yet)
      ├── reference/          # PDFs, articles
      ├── images/
      └── notes/              # Rich markdown notes
  ```

### AI/Automation Components

**Local LLM Setup**
- **Models**: Qwen or Gemma (not Claude)
- **Runtime**: Ollama or LM Studio (configurable)
- **Configuration**: 
  - Stored in config files (same location as `.zshrc` symlink)
  - Prompts are configurable and can be altered
  - No system prompts in use (currently)
- **Secrets Management**: 
  - Stored in config files
  - No API keys required (local models)

**MCP (Model Context Protocol) Integration**
- **Configuration**: 
  - Cursor IDE integration: separate config file
  - System integration: built into the GTD system itself
- **Available Tools** (partial list):
  - Task/Project/Area searches
  - Create task/project/area
  - Get suggestions from text
  - *[TODO: Document complete tool list from code]*

**Background Workers** (Python scripts)
1. **Task Generator**: Creates tasks from various sources (reviews, patterns, external triggers)
2. **Bulk Organizer** (`gtd_advice_worker.py`): AI-suggested project assignment for orphaned tasks
3. **Task Resolver**: Auto-closes tasks by matching log mentions to open tasks
4. **MoC Creator/Collector**: Detects opportunities for Maps of Content based on related notes
5. **Area Creator/Collector**: Suggests organizational Areas when task clusters emerge
6. **Automated Reviews**: Daily/weekly GTD review cycles
7. **AI Lesson Instructor**: Interactive command-line tutorial system

**AI Lesson Instructor**
- **Purpose**: Teaches GTD commands through conversational AI interaction
- **Command**: `gtd-learn` (must be executed manually)
- **Entry Points**:
  - Via wizard/menu interface (shows list of available lessons)
  - Direct command-line invocation
- **Knowledge Base**: Markdown documentation files in `docs/` folder
  - Organized by topic/workflow
  - Standard markdown format (no special metadata)
  - System references these docs to generate lessons
  - Documentation-driven learning (docs must be maintained)
- **Lesson Structure**:
  - Curriculum-based: Follows structured lesson plan
  - Flexible: Can deviate and ask off-topic questions
  - Topic-organized: Grouped by workflow/concept, not individual commands
  - Wizard shows: List of available lessons to choose from
- **Interaction Model**:
  - Conversational back-and-forth with AI
  - Q&A driven: Ask questions, get contextual explanations
  - Quiz feature: Built-in but untested
    - *[TODO: Test and document quiz functionality]*
  - Can provide feedback on your GTD system usage
  - Not automated/passive - user initiates and drives conversation
- **Progress Tracking**:
  - Minimal: "Sorta" tracks progress
  - Can repeat lessons as much as desired
  - Cannot resume mid-lesson (sessions are independent)
  - Recommended: Follow in order, but can jump around
  - No completion checkmarks or formal progression
- **Examples & Personalization**:
  - Primarily uses generic examples
  - Sometimes references user's actual data
  - **Active Issue**: Hallucinations being worked out
    - System may make up examples or incorrect details
    - Improvement in progress
- **Use Case**: Separate terminal session alongside work
  - Typical setup: tmux split screen
  - Learn commands in one pane, try them in another
  - Reference while working without context switching
- **Solves**: Command discoverability with 75+ scripts
  - "What commands exist?"
  - "What does this command do?"
  - "How do I accomplish X?"
  - "What's the difference between similar commands?"
  - "Am I using my GTD system effectively?"
- **Model**: Uses local LLM (Qwen/Gemma via Ollama/LM Studio)

**Worker Management**:
- **Lifecycle**: Long-running daemons (not cron jobs)
- **Startup**: Typically triggered via wizard interface
  - Can also be managed via command-line options
- **Logging**: 
  - Output to files in `/tmp` directory
  - *[TODO: Log rotation strategy? Cleanup?]*
- **Monitoring**: 
  - No automatic alerting on worker crashes
  - *[Future]: Surface worker status in Command Center*

**AI Integration**
- **Protocol**: MCP (Model Context Protocol) for tool calling
- **Models**: Uses internal LLM (Claude via API) for reasoning and suggestions
- **Rate Limiting**: 
  - Not yet implemented in main system
  - Helper project: "ollama-controller-api" (being refactored to LM Studio?)
  - Current issue: Requests can time out under load

**File Watcher**
- **Implementation**: Python `watchdog` library
- **Monitored Directories**: Specified in config file
  - *[TODO: Which config file? Document location]*
- **File Filtering**: 
  - Processes `.md`, `.markdown`, and `.txt` files
  - Excludes other file types from vectorization
- **Change Detection**: 
  - Managed via diff comparison
  - **Debouncing**: 2-second debounce timer prevents duplicate processing on rapid file changes
- **Job Publishing**: Sends vectorization jobs to RabbitMQ queue
- **Known Limitation**: Doesn't detect file renames properly
  - Treats rename as delete + create
  - Can orphan vectors or create duplicates

---

## Vector Search Implementation

### Chunking Strategy

**Markdown Files** (implemented from AI suggestions):
- Primary split: Header boundaries (`# `, `## `, etc.)
- Preserves heading hierarchy: "Main Topic > Subtopic > Detail"
- Secondary split: Paragraph boundaries (`\n\n`)
- Fallback: Sentence boundaries for oversized paragraphs
- **Parameters**:
  - `max_tokens`: 512
  - `overlap_tokens`: 50 (10% overlap at chunk boundaries)

**Context Enrichment**:
Each chunk prepended with metadata before vectorization:
```
Document: /gtd/projects/acme.md
Section: Market Analysis > Competitors

[actual chunk content]
```

### Database Schema

```sql
CREATE TABLE document_vectors (
  id SERIAL PRIMARY KEY,
  file_path TEXT NOT NULL,
  chunk_index INT NOT NULL,
  
  -- Content
  content TEXT NOT NULL,              -- Original chunk
  content_with_context TEXT,          -- With heading path prepended
  
  -- Vector
  embedding vector(768),               -- Nomic embed-text v2 dimensions
  
  -- Structure metadata
  heading_path TEXT,                   -- "Main Topic > Subtopic"
  section_chunk_index INT,             -- Which chunk within this section
  
  -- Organizational metadata (from GTD system)
  project TEXT,
  category TEXT,
  tags TEXT[],
  
  -- File metadata
  file_type TEXT,                      -- 'markdown', 'text', 'code'
  last_modified TIMESTAMP,
  
  -- Content characteristics
  has_code_block BOOLEAN,
  has_list BOOLEAN,
  has_links BOOLEAN,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(file_path, chunk_index)
);

-- Indexes
CREATE INDEX idx_file_path ON document_vectors(file_path);
CREATE INDEX idx_project ON document_vectors(project);
CREATE INDEX idx_tags ON document_vectors USING gin(tags);
```

### Search Capabilities

**Current Implementation**:
- Vector similarity search (cosine distance)
- Metadata filtering (project, tags, file_type)
- Hybrid: vector search + web search results
- Results include provenance (file path, heading path, confidence scores)

**AI Access**:
- Primary: Vectorized GTD content (tasks, projects, logs)
- Fallback: Can read from non-vectorized second-brain content when needed

---

## User Interface

### Command-Line Integration

**Primary Command**: `gtd-log`
- Recently adopted for efficiency
- Freeform text entry: `gtd-log "completed database optimization"`
- Natural workflow integration: logging happens where work happens

**Installation**:
- Scripts installed in PATH
- zsh aliases for common operations
- zsh functions for complex workflows
- Tab completion: Works for commands
  - Sometimes breaks when shell operations clobber PATH
  - Fix: `source ~/.zshrc` to restore environment

**Configuration**:
- **Location**: Same directory as `.zshrc` symlink
- **Configurable Parameters**:
  - File paths for GTD directories
  - AI endpoints (Ollama/LM Studio URLs)
  - AI system selection (Ollama vs LM Studio)
  - Computer mode: home vs work
  - Settings switch between environments
- **Secrets**: Stored in config files (no API keys, local models only)
- **Home/Work Mode**: See dedicated section below

### Home vs Work Mode

**Purpose**: Support working across different computers with different capabilities and restrictions

**Mode Switching**:
- **Command**: `gtd-set-computer work` or `gtd-set-computer home`
- **Via Wizard**: Menu option available
- **Config Setting**: Stored in ignored file (setting persists across sessions)
- **Auto-Detection**: Partially implemented, still being debugged
  - System attempts to detect mode automatically
  - Requires initial manual setting
  - Uses ignored file to remember last mode

**Configuration Architecture**:
- Maintains two parallel sets of variables: HOME and WORK
- Switching modes activates the appropriate variable set
- Most paths use `$HOME` variable (same base path on both systems)
- Differences are primarily in endpoints and feature flags

**Mode Differences**:

| Feature | Home Mode | Work Mode |
|---------|-----------|-----------|
| **Feature Set** | Full | Reduced |
| **AI Endpoint** | LM Studio | Ollama |
| **Vectorization** | Enabled | Disabled |
| **Database** | PostgreSQL + pgvector | None |
| **Semantic Search** | Available | Unavailable |
| **Workers** | All active | Limited subset |
| **File Paths** | Full GTD + Second Brain | Primarily GTD |
| **Logging** | Same | Same |
| **Obsidian Path** | `$HOME/...` | `$HOME/...` (same) |

**Work Mode Constraints**:
- Designed to stay under IT radar
- No database connections (no k8s/Postgres)
- No vectorization (no RabbitMQ workers)
- Limited to file-based operations
- Obsidian Sync handles cross-device coordination
- Can still log and create tasks/projects
- AI assistance via Ollama (if available on work machine)

**Current Status**:
- Core switching mechanism: Working
- Auto-detection: Being debugged
- Work mode still being refined (Ollama setup in progress)
- May need additional work-specific settings in future

**Known Issues**:
- Auto-detection not fully reliable
- Initial mode must be set manually
- Work mode feature parity still evolving
- *[TODO: Document which workers are disabled in work mode]*
- *[TODO: Does work mode still write to Obsidian vault normally?]*
- *[TODO: What happens if you forget to switch modes?]*

**tmux Integration**:
- Custom keybindings configured
- "Basic" bindings currently in use
- *[TODO: Document specific keybindings]*
- **Common Use Case**: Split screen for learning
  - One pane: `gtd-learn` interactive lessons
  - Other pane: actual command execution/work
  - Learn and practice simultaneously

**Shell Environment**:
- Interactive shell: zsh
- Scripts: bash 3.2 compatible
- Integration: Scripts in PATH + zsh aliases + zsh functions
- **Known Issue**: Some operations clobber PATH, requires `source ~/.zshrc`

### Command Center

**Purpose**: Human-in-the-loop review interface for AI suggestions

**Implementation**:
- **UI Type**: Printed output (not full TUI)
- **Navigation**: Custom bash menus via wizard/menu interface
- **Library**: Custom bash scripts (no curses/dialog/fzf)
- **Search/Filter**: Not currently available
- *[Future consideration]: Migrate to proper TUI for better UX*

**Structure**: Multiple review contexts/menus accessed via wizard interface:
1. Project assignments (bulk organizer suggestions)
2. Task resolutions (auto-close suggestions)
3. MoC opportunities
4. Area suggestions
5. Review items (daily/weekly review outputs)
6. Knowledge organization results (MoC/Area scanning results)
7. Analysis results (weekly reviews, energy analysis, connections, insights)
8. Task suggestions from logs (high/medium confidence)

**Note**: The unified learning system tracks 8 suggestion types (task_from_log, area_assignment, moc_creation, area_creation, project_suggestion, insight, plus variants). The review interface groups these into contextual menus for easier navigation.

**Features**:
- Batch review (process multiple suggestions at once)
- Confidence scores displayed for each suggestion
- **Nuanced feedback**: 1-5 star ratings with reasons (not just accept/reject)
- **Explainability**: See why suggestions were made, with confidence adjustments explained
- **Threshold management**: Manual controls to show more/less suggestions
- Actions: Accept / Reject / Skip / Retry (for timeouts) / Rate (1-5 stars)
- Non-pushy reminders ("something is there" vs "URGENT: REVIEW NOW")
- Learning loop: Accept/reject/rating decisions train the AI via unified learning system

**Design Principles**:
- Async processing: Review on your schedule, not system's
- Transparent automation: See what it's suggesting, not blind changes
- Minimal context switching: One review type at a time

**Unified Learning System**:
- All suggestion types feed into a single learning system (`gtd_unified_learning.py`)
- Tracks acceptance/rejection patterns across all suggestion types
- Automatically adjusts confidence thresholds based on your decisions
- Provides explainability for why suggestions were made
- Supports nuanced feedback (1-5 star ratings) beyond simple accept/reject
- Cross-domain intelligence: Patterns learned in one area (e.g., project assignments) inform other areas (e.g., task suggestions)

### tmux Dashboard

**Purpose**: Ambient awareness without interruption

**Implementation**:
- **Command**: `gtd-dashboard --compact`
- **Output**: Single line with icons for status bar
- **Update Frequency**: 
  - Watch mode: Configurable interval (default 5 seconds)
  - Single display: On-demand execution
  - For tmux status bar: Typically refreshed every 1-2 minutes by tmux configuration
- **Querying**: Script queries system state
  - *[TODO: Direct DB queries? Status files? API calls?]*
- **Interaction**: Read-only display (tmux status bar is non-interactive)

**Display**:
- Active background workers status
- Pending command center notifications
- Recent pattern detections
- Vector count and system health
- *[TODO: Document specific stats/icons shown]*

**Integration**: Lives in tmux status bar
- Always visible during terminal work
- Passive information (glanceable, not demanding)
- Motivating feedback loop: "Oh, system found 3 new connections"

---

## Workflow & Data Flow

### Learning Workflow (New User Onboarding)

```
1. User starts lesson system
   ├─ Via wizard interface: navigate to learning menu
   └─ Direct: `gtd-learn` command
   ↓
2. AI Instructor loads markdown documentation
   ↓
3. Conversational interaction begins
   - User asks questions
   - AI explains commands with context
   - User can try commands in parallel tmux pane
   ↓
4. User-driven exploration
   - No forced progression
   - Jump between topics as needed
   - Reference while working
```

**Typical tmux Setup**:
```
┌─────────────────────────────────────┐
│  gtd-learn                          │  ← Interactive lessons
│  > How do I create a new task?      │
│  AI: To create a task, you can...   │
├─────────────────────────────────────┤
│  ~/projects/current $               │  ← Try commands here
│  $ gtd task create "example"        │
└─────────────────────────────────────┘
```

### Logging → Processing → Review Cycle

```
1. User logs freeform text
   ↓
2. File watcher detects change
   ↓
3. Vectorization queue processes file
   ↓
4. AI workers analyze in background:
   - Generator: Creates relevant tasks
   - Organizer: Suggests project assignments
   - Resolver: Matches log to open tasks
   - MoC/Area: Detects patterns
   ↓
5. Command Center receives suggestions
   ↓
6. User reviews and accepts/rejects
   ↓
7. System learns from decisions
   ↓
8. [Cycle repeats with improved accuracy]
```

### Cross-Device Sync

**Current State**:
- **Desktop (MacBook)**: Full-featured, all automation running
- **Work Computer**: Logs via Obsidian, syncs automatically
- **Mobile**: Sync exists but UI broken/unreliable

**Sync Method**:
- Obsidian Sync (approved tool for work computer)
- GTD system writes markdown files → Obsidian vault
- Obsidian handles cross-device synchronization
- All devices see same files (when sync works)

**Work Computer Strategy**:
- Runs in "Work Mode" (reduced features)
- Minimalist logging (stays under IT radar)
- Plain text in Obsidian (no custom scripts needed)
- Freeform journal entries that parse on home computer
- Approved tool (Obsidian) = no organizational friction
- No database or vectorization workers
- AI via Ollama (if available, still being set up)

---

## Known Issues & Limitations

### Active Problems

1. **Duplicate Processing**: System re-processes same files/tasks on restart
   - No caching of AI suggestions
   - Wastes API calls (or local model inference) and time
   - **Proposed Fix**: Cache layer tracking "file_hash → last_processed_timestamp"

2. **Rate Limiting**: No throttling of AI requests
   - Can overwhelm local model endpoints
   - Causes timeouts and failures
   - **Partial Solution**: ollama-controller-api project
     - Status: Sidelined, waiting to be reintegrated
     - Was working in previous version
     - Being refactored from Ollama → LM Studio backend
     - Purpose: Throttle requests to prevent timeouts

3. **File Rename Detection**: File watcher treats renames as delete + create
   - Can orphan vectors from "deleted" files
   - Duplicates vectors for "new" files
   - **Proposed Fix**: Track file content hash, not just path

4. **Mobile Sync**: Obsidian sync technically works but UI unusable
   - Can't effectively capture mobile insights
   - Loses "shower thoughts" and commute ideas
   - **Status**: Deprioritized until desktop proves value

5. **First Pass Results**: Initial full-system analysis yielded no useful suggestions
   - Cold start problem: needs ongoing data, not just historical
   - System learning from live interactions now
   - **Current Phase**: Accumulating training data

6. **Worker Crash Detection**: No automatic alerting when workers fail
   - Workers log to `/tmp` but no monitoring
   - Failures go unnoticed until manual check
   - **Proposed**: Surface worker health in Command Center

7. **AI Lesson Hallucinations**: System may generate incorrect information
   - Sometimes makes up examples or wrong details
   - Can reference user data incorrectly
   - **Status**: Actively being improved
   - **Risk**: New users may learn incorrect patterns

8. **PATH Clobbering**: Some operations reset shell PATH
   - Breaks access to GTD commands
   - Requires manual `source ~/.zshrc`
   - **Root Cause**: Unknown, needs investigation

8. **Tab Completion Inconsistency**: Works "usually" but not always
   - Likely related to PATH clobbering issue
   - Affects workflow efficiency

9. **Lesson Progress Persistence**: Cannot resume mid-lesson
   - Each `gtd-learn` session starts fresh
   - No bookmarking within lessons
   - Users must remember where they left off
   - **Impact**: Friction for longer lessons or interrupted learning

10. **Work Mode Auto-Detection**: Mode switching not fully automatic
    - Requires initial manual mode setting
    - Auto-detection feature being debugged
    - Risk of using wrong mode (full features on work computer)
    - *[TODO: What happens if you forget to switch modes?]*

### Design Limitations

1. **"It's All Live Baby" - No Dev/Prod Separation**
   - All changes tested in production
   - Breaking changes break actual workflow
   - No safety net for experimentation
   - **Rollback Strategy**: "Only roll forward"
   - **Testing**: Automated tests exist but take a while to run
   - **Trade-off**: Fast iteration vs. stability

2. **Script Sprawl**: ~75+ scripts from organic growth
   - "Vibe coding" creates architectural drift
   - Scripts may call each other in undocumented ways
   - Hard to understand full dependency graph
   - **Mitigation Attempt**: AI Lesson Instructor helps with discoverability
   - **Still Needed**: Comprehensive documentation pass

3. **Documentation Dependency**: AI Instructor only as good as markdown docs
   - Docs must be kept up-to-date with code changes
   - Outdated docs = misleading lessons
   - No automatic sync between code and documentation
   - **Risk**: Documentation drift over time

4. **Work/Personal Split**: System has asymmetric capabilities
   - Work mode: Limited features (no database, no vectorization)
   - Home mode: Full feature set
   - AI insights only generated on home computer
   - Work computer generates raw logs that home computer processes
   - Detected "productive morning routine" = "when you use home computer"

5. **Incomplete Vectorization**: Second-brain PDFs/images not searchable yet
   - Reference materials isolated from GTD system
   - Links exist but semantic search doesn't cross boundary

6. **Limited Health Monitoring**: Can see vector count, unclear about orphaned files
   - No automatic detection of stale data
   - No proactive optimization suggestions
   - No system-wide health dashboard

---

## System Evolution

### Previous Version (v1.0)
- Lasted "a few years" before collapse
- Manual organization and maintenance
- Maintenance burden eventually killed adoption
- **Lesson**: Tracking productivity overhead interfered with productivity

### Current Version (v2.0)
- **Goal**: Automate maintenance to make system sustainable
- **Approach**: AI handles busywork, human handles strategy
- **Key Difference**: Built into command prompt (natural workflow integration)
- **Status**: Early phase, system still learning patterns

### Success Metrics (TBD)
- Can maintain logging habit longer than a few weeks
- Command center suggestions are >70% accepted
- System surfaces non-obvious connections/patterns
- Time spent on organization decreases while system grows
- Feels like collaboration, not maintenance

---

## Future Enhancements

### High Priority
1. **Caching Layer**: Prevent duplicate AI processing
2. **Rate Limiting**: Throttle API requests properly
3. **Health Monitoring Dashboard**: System stats, orphaned file detection
4. **File Rename Handling**: Content-hash based tracking

### Medium Priority
1. **Second Brain Vectorization**: Extend search to PDFs/images
2. **Mobile Experience**: Fix Obsidian mobile UI or build lightweight companion
3. **Query Expansion**: Auto-enrich searches with organizational context
4. **Result Feedback Loop**: Track which suggestions are actually helpful

### Low Priority / Exploratory
1. **Hybrid Search Ranking**: Unified scoring of vector + web results
2. **Intent Classification**: Tailor result presentation to query type
3. **Cross-project Pattern Detection**: "This problem similar to one in different project"
4. **Automated Report Generation**: Weekly insights summary

---

## Technical Debt

1. **Bash 3.2 Compatibility**: Must constantly remind AI code assistants
   - No associative arrays (`declare -A`)
   - Limited string manipulation
   - Must use Python for complex data structures
   - Documentation exists but easy to forget

2. **Script Organization**: 75+ scripts with organic growth patterns
   - Need to document script purposes and dependencies
   - Call graph unclear
   - Opportunity for consolidation/refactoring

3. **ollama-controller-api refactor**: Half-migrated to LM Studio, incomplete
   - Was working, now sidelined
   - Rate limiting still needed
   - Needs reintegration plan

4. **Worker Logging**: Logs to `/tmp` with unclear rotation/cleanup
   - Could fill disk over time
   - No centralized log aggregation
   - Hard to debug issues across workers

5. **Error handling**: Workers can fail silently, no alerting
   - Need health monitoring and notifications
   - Should surface in Command Center

6. **Backup strategy**: No explicit backup beyond Obsidian Sync
   - What if Obsidian Sync fails?
   - What about Postgres data?
   - What about config files?

7. **Testing**: Automated tests exist but take a while to run
   - What do they test?
   - Coverage unclear
   - Run manually or automatically?

8. **Configuration Documentation**: Multiple config files, locations unclear
   - Where is file watcher config?
   - What's in each config file?
   - What happens if config is missing/invalid?

9. **Disaster Recovery Procedures**: "Just start over" is not a plan
   - How long does full recovery actually take?
   - What if system grows to 100k+ files?
   - Need documented recovery steps

10. **MCP Tool Documentation**: "a bunch more" tools not documented
    - What tools exist?
    - What do they do?
    - How does the AI know when to use them?

11. **AI Lesson Documentation Sync**: Keep markdown docs current with code
    - As commands change, docs must be updated
    - No automatic validation
    - Outdated docs mislead new users
    - **Risk**: Instructor teaches deprecated patterns

12. **AI Lesson Hallucination Mitigation**: Improve accuracy of AI instructor
    - Currently generates incorrect info sometimes
    - Need better grounding in actual system state
    - Consider: Validate examples against real commands before presenting
    - Consider: Fact-check mode that verifies AI responses

---

## Documentation TODOs

Items to investigate/document later:

1. **Executable Scripts**: Create comprehensive helper guide
   - Script names and purposes (75+ scripts to document!)
   - Usage examples and flags
   - Dependency graph between scripts
   - Troubleshooting common issues
   - *Suggestion: Ask Cursor AI to generate this from codebase*

2. **System Stats Menu**: Document which menu shows vector count
   - What other metrics are displayed?
   - How to access it?
   - What do the numbers mean?

3. **Command Center 6th Context**: Identify the missing review area
   - Current documented: Projects, Resolutions, MoCs, Areas, Reviews
   - What's the 6th?

4. **Nomic Embed Configuration**: Verify technical specs
   - Dimensions: 768 (assumed, needs confirmation)
   - Context window size
   - Any special configuration or preprocessing

5. **ollama-controller-api Architecture**: Document when reintegrated
   - How it throttles requests
   - Integration points with main system
   - LM Studio migration details

6. **NodePort Numbers**: Document actual ports in use
   - RabbitMQ: port ?
   - PostgreSQL: port ?
   - Any other exposed services?

7. **File Watcher Configuration**:
   - Which config file contains watched directories?
   - Where is it located?
   - What's the format?
   - Verify file type filtering (.md and .txt only?)

8. **tmux Keybindings**: Document configured shortcuts
   - What keys trigger what actions?
   - Are they documented anywhere?

9. **tmux Dashboard Details**:
   - How does `gtd-dashboard --compact` query state?
   - What specific stats/icons are shown?
   - What do the icons mean?

10. **MCP Tool Complete List**: Document all available tools
    - Extract from codebase
    - Document purpose and usage of each
    - When does AI choose which tool?

11. **Testing Suite**: Document what automated tests cover
    - What do they test?
    - How long is "a while"?
    - Run manually or CI/CD?
    - How to interpret results?

12. **Configuration Files**: Map all config files and their purposes
    - Location of each config file
    - What parameters each contains
    - Format and examples
    - Validation and error handling

13. **Recovery Procedures**: Document actual disaster recovery steps
    - Full postgres rebuild
    - Full vector regeneration
    - Config restoration
    - Estimated time at current scale
    - Estimated time at 10x scale

14. **Bash 3.2 Safe Patterns**: Create reference guide
    - Common tasks and bash 3.2 compatible solutions
    - Python alternatives when bash won't work
    - Examples of what NOT to do

15. **AI Lesson Instructor**: Document lesson structure and coverage
    - What topics/modules are available? (List from wizard)
    - Which commands are documented in lessons?
    - Test quiz functionality - does it work?
    - How does it provide feedback on GTD usage?
    - Document hallucination issues and workarounds
    - Best practices for lesson order/progression
    - When is it safe to jump around vs. follow sequence?

16. **Home/Work Mode Configuration**: Document complete behavior
    - Which workers are disabled in work mode?
    - Does work mode still write to Obsidian vault normally?
    - What happens if you forget to switch modes?
    - How does auto-detection work (when fully implemented)?
    - Complete list of setting differences between modes
    - Troubleshooting guide for mode switching issues

---

## Appendix: Key Learnings

### What Worked
- Command-line integration = zero friction logging
- Obsidian as sync bridge = organizational approval
- Human-in-the-loop via Command Center = maintains control
- tmux dashboard = ambient awareness without interruption
- Freeform logging = authentic patterns emerge

### What Didn't Work
- Big-bang first pass = cold start problem
- No caching = wasted resources
- Ignoring mobile = losing valuable signal
- Pure automation without review = trust issues

### Design Philosophy Insights
- System must respect user agency (non-pushy)
- Automation should reduce friction, not create new maintenance
- Structure should emerge from actual usage, not imposed top-down
- Learning loop is essential: system must adapt to user preferences
- Integration matters more than features: built-in > bolt-on