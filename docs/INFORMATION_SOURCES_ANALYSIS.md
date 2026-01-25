# Information Sources Analysis

## Overview

Your GTD system has multiple information sources, but they're not all accessible to every interface. This document analyzes what's available where and identifies gaps.

## Information Sources

### 1. Personalization Data
- **Location**: `~/.gtd_personalization.json`
- **Content**: Relationships, goals, energy patterns, preferences, communication style
- **Access**:
  - ✅ Claude API: `gtd_get_personalization`, `gtd_update_personalization`
  - ✅ MCP Server: `get_personalization`, `update_personalization`
- **Status**: ✅ Fully accessible from both interfaces

### 2. Vector Database
- **Location**: PostgreSQL with pgvector extension
- **Content**: Vectorized embeddings of:
  - Daily log entries
  - Tasks (descriptions and notes)
  - Projects (READMEs and descriptions)
  - Notes/MOCs (if vectorized)
  - Files (if filewatcher is enabled)
- **Access**:
  - ✅ Claude API: `gtd_search_vector_database`, `gtd_get_vector_database_stats` (✅ **NOW AVAILABLE**)
  - ✅ MCP Server: `search_vector_database`, `get_vector_database_stats`, `get_file_vector_info`
- **Status**: ✅ **FIXED** - Claude API now has direct vector database access

### 3. Daily Logs
- **Location**: `~/.gtd/daily_log/` (text files)
- **Content**: Daily log entries with timestamps
- **Access**:
  - ✅ Claude API: `gtd_read_daily_log`, `gtd_add_daily_log_entry`
  - ✅ MCP Server: `read_daily_log`, `add_daily_log_entry`
- **Status**: ✅ Fully accessible from both interfaces
- **Note**: Also vectorized in vector database (semantic search available via MCP)

### 4. Tasks
- **Location**: `~/.gtd/tasks/` (text files)
- **Content**: Task files with metadata (priority, context, project, etc.)
- **Access**:
  - ✅ Claude API: `gtd_list_tasks`, `gtd_create_task`
  - ✅ MCP Server: `list_tasks`, `create_task`, `update_task`, `delete_task`
- **Status**: ✅ Fully accessible from both interfaces
- **Note**: Also vectorized in vector database (semantic search available via MCP)

### 5. Projects
- **Location**: `~/.gtd/projects/` (directories with README.md)
- **Content**: Project READMEs and descriptions
- **Access**:
  - ✅ Claude API: `gtd_list_projects`
  - ✅ MCP Server: `list_projects`, `create_project`, `get_project_details`
- **Status**: ✅ Fully accessible from both interfaces
- **Note**: Also vectorized in vector database (semantic search available via MCP)

### 6. Calendar
- **Location**: Google Calendar (accessed via `gcalcli`)
- **Content**: Events, meetings, appointments
- **Access**:
  - ✅ Claude API: `gtd_get_calendar_overview`
  - ✅ MCP Server: `get_calendar_overview`
- **Status**: ✅ Fully accessible from both interfaces

### 7. Second Brain / Notes
- **Location**: `~/Documents/obsidian/Second Brain/` (or `$SECOND_BRAIN`)
- **Content**: Personal notes, MOCs, Pathfinder campaign notes, etc.
- **Access**:
  - ✅ Claude API: `gtd_search_second_brain` (file-based text search, **NOT vector DB**)
  - ✅ MCP Server: `search_vector_database` (if notes are vectorized)
- **Status**: ⚠️ **PARTIAL** - Claude API uses basic file search, not semantic search
- **Note**: `gtd_search_second_brain` does NOT use the vector database - it's just filename/content matching

## Tool Availability Comparison

### Claude API Tools (via `gtd_tool_registry.py`)
**Total: 17 tools**

| Category | Tools | Vector DB Access |
|----------|-------|------------------|
| GTD | `gtd_list_tasks`, `gtd_create_task`, `gtd_list_projects`, `gtd_read_daily_log`, `gtd_add_daily_log_entry`, `gtd_get_datetime`, `gtd_get_inbox_count`, `gtd_suggest_tasks_from_text`, `gtd_get_calendar_overview` | ❌ No |
| Personalization | `gtd_get_personalization`, `gtd_update_personalization` | ❌ No |
| Knowledge | `gtd_search_second_brain` (file-based), `gtd_search_vector_database` (semantic search) | ✅ Yes |
| Skills | `list_agent_skills`, `get_agent_skill`, `execute_agent_skill` | ❌ No |
| System | `list_available_tools` | ❌ No |

### MCP Server Tools (via `gtd_mcp_server.py`)
**Total: 40+ tools**

| Category | Tools | Vector DB Access |
|----------|-------|------------------|
| GTD | All task/project/log tools | ✅ Yes (via `search_vector_database`) |
| Personalization | `get_personalization`, `update_personalization` | ✅ Yes |
| Vector DB | `search_vector_database`, `get_vector_database_stats`, `get_file_vector_info` | ✅ Yes |
| Deep Analysis | `weekly_review`, `analyze_energy`, `find_connections`, `generate_insights` | ✅ Yes |
| Skills | `list_agent_skills`, `get_agent_skill`, `execute_agent_skill` | ✅ Yes |

## Key Gaps

### 1. ✅ **FIXED** - Claude API Now Has Vector Database Access

**Status**: ✅ **RESOLVED** - Vector database tools have been added to `gtd_tool_registry.py`

**Solution Implemented**:
- ✅ `gtd_search_vector_database` - Semantic search across all vectorized content
- ✅ `gtd_get_vector_database_stats` - Get database statistics

**Impact**:
- Claude can now do semantic search across your content
- More powerful than direct file access for finding related content
- `gtd_search_second_brain` still available for file-based search (different use case)

### 2. ⚠️ Redundant Access Methods

**Problem**: Some information is accessible via multiple methods:
- Direct file access (`gtd_read_daily_log`) vs. Vector DB search (`search_vector_database`)
- Both methods work, but they serve different purposes:
  - Direct access: Get specific entries by date
  - Vector search: Find semantically similar content across time

**Impact**: 
- Not necessarily a problem - different use cases
- But could be confusing which to use when

**Recommendation**: Document when to use each method

### 3. ⚠️ Personalization Separate from Vectorized Content

**Problem**: Personalization data (`~/.gtd_personalization.json`) is separate from vectorized content in the database.

**Impact**:
- Personalization data is not searchable via vector DB
- Could be useful to have personalization insights in vector DB for semantic search

**Recommendation**: Consider vectorizing personalization updates (optional enhancement)

## Efficiency Analysis

### Current State
- ✅ Personalization: Efficiently stored and accessible
- ✅ Direct file access: Fast, works well for specific queries
- ✅ Vector database: **NOW ACCESSIBLE** via Claude API and MCP
- ⚠️ Second Brain search: Basic file search (different use case from vector search)

### Recommendations

1. ✅ **COMPLETED** - Vector DB Tools Added to Claude API
   - Semantic search now available in Claude API/TUI
   - Information more accessible
   - Multiple access methods available (choose based on use case)

2. **Enhance `gtd_search_second_brain`** (Optional Enhancement)
   - Could optionally use vector DB if available
   - Fall back to file search if not vectorized
   - Currently serves different purpose (file-based search)

3. **Documentation** (In Progress)
   - Document when to use vector search vs. direct access
   - Explain the difference between semantic and text search

## Next Steps

1. ✅ **COMPLETED** - Vector database tools added to `gtd_tool_registry.py`
2. ⏳ **Update system prompts** to guide AI on when to use vector search
3. ⏳ **Consider enhancing `gtd_search_second_brain`** to optionally use vector DB (optional)
