# Diagram Tool MCP Data Integration

## Current State

### The Problem
The diagramming tool (`gtd-diagram`) currently **does NOT** use MCP tools to access GTD data. It simply sends a text prompt to the AI model and asks it to generate a diagram based on that description alone.

### Why MCP Tools Can't Be Used Directly by Small Models
Small models like **Gemma 3 4B** (your configured deep model) typically **do not support tool calling** (function calling). Tool calling requires:
- Understanding the MCP protocol
- Making tool calls and handling responses
- Managing tool call sequences
- More sophisticated reasoning capabilities

This is usually only available in larger models (GPT-4, Claude Opus, etc.).

## The Solution: Data Gathering Before Model Call

Instead of asking the model to use tools, we can **gather GTD data on our side** (using MCP tools or direct file access) and **include that data in the prompt**. This way:

✅ Works with small models (no tool calling needed)
✅ Model gets rich, accurate context
✅ Diagrams based on actual GTD data
✅ More accurate and useful diagrams

## How It Would Work

### Example: "Create a mindmap of my projects"

**Current approach:**
```
User: "Create a mindmap of my projects"
→ AI gets: "Create a mindmap of my projects"
→ AI guesses what projects might look like
→ Generates generic diagram
```

**Enhanced approach:**
```
User: "Create a mindmap of my projects"
→ Tool detects this is about GTD data
→ Calls `list_projects` MCP tool (or reads files directly)
→ Gets actual project data:
  - Project A (status: active, 5 tasks)
  - Project B (status: on-hold, 2 tasks)
  - Project C (status: active, 10 tasks)
→ Includes this data in prompt:
  "Create a mindmap of these projects:
   - Project A (active, 5 tasks)
   - Project B (on-hold, 2 tasks)
   - Project C (active, 10 tasks)
  ..."
→ AI generates accurate diagram with real data
```

## Implementation Options

### Option 1: Use MCP Tools Directly (Recommended)
Call the MCP server functions directly from Python (import the server module and call the tool handlers).

**Pros:**
- Uses existing, tested code
- Consistent with other GTD tools
- Handles all edge cases

**Cons:**
- Requires importing the MCP server module
- Slight dependency coupling

### Option 2: Call Shell Commands
Call `gtd-project list`, `gtd-task list`, etc. and parse output.

**Pros:**
- Simple, no imports needed
- Works independently

**Cons:**
- Requires parsing text output
- Less structured data
- Potential inconsistencies

### Option 3: Read Files Directly
Read project/task files directly from the GTD directory structure.

**Pros:**
- Fastest
- Most direct
- No dependencies

**Cons:**
- Duplicates file-reading logic
- Must maintain consistency with GTD structure

## Recommended Implementation

**Best approach:** Use Option 1 (MCP server functions) because:
1. The MCP server already has all the logic for reading GTD data
2. Functions like `list_projects()`, `list_tasks()`, `read_project_file()` are already available
3. We can import and call them directly without going through the MCP protocol

## What Data Can Be Gathered

The diagramming tool could detect and gather:

### Projects
- List all active/on-hold/done projects
- Get project details (tasks, status, description)
- Get project hierarchy/structure

### Tasks
- List tasks by context, energy, priority, project
- Get task relationships and dependencies
- Get task status and progress

### Areas
- List areas of responsibility
- Get area-related projects and tasks

### Daily Logs
- Read recent daily log entries
- Extract health data, mood, activities
- Analyze patterns over time

### Goals
- List active goals
- Get goal progress and milestones
- Get goal-related projects

## Detection Logic

The tool should detect GTD-related requests by looking for keywords:

```python
GTD_KEYWORDS = {
    "projects": ["project", "projects", "my projects", "all projects"],
    "tasks": ["task", "tasks", "my tasks", "all tasks", "todo"],
    "areas": ["area", "areas", "responsibilities"],
    "goals": ["goal", "goals", "my goals"],
    "logs": ["daily log", "log", "recent", "past week"],
}
```

When detected, gather relevant data and include in prompt.

## Example Enhanced Prompts

### Before (Current)
```
"Create a flowchart of my GTD workflow"
```

### After (Enhanced)
```
"Create a flowchart of my GTD workflow. 

Here's my actual GTD system structure:

ACTIVE PROJECTS:
- Project A: 5 active tasks, 2 on-hold
- Project B: 10 active tasks
- Project C: 3 active tasks

ACTIVE TASKS BY CONTEXT:
- Computer: 15 tasks
- Phone: 3 tasks
- Home: 7 tasks
- Office: 5 tasks

Use this real data to create an accurate workflow diagram."
```

## Status

This enhancement is **✅ IMPLEMENTED**! The diagramming tool now:
- ✅ Uses the deep analysis model for better diagram generation
- ✅ **Gathers GTD data before calling the model**
- ✅ **Detects GTD-related requests automatically**
- ✅ **Enhances prompts with real data context**

## How It Works (Implementation Details)

The enhancement is implemented in `bin/gtd_deep_model_helper.py`:

1. **Detection**: The `detect_gtd_data_needs()` function analyzes prompts for GTD-related keywords
2. **Data Gathering**: Multiple functions gather data directly from files:
   - `gather_projects_data()` - Reads project directories
   - `gather_tasks_data()` - Reads task files from tasks directory and project directories
   - `gather_areas_data()` - Reads area files
   - `gather_goals_data()` - Reads goal files
   - `gather_daily_logs_data()` - Reads recent daily logs
3. **Prompt Enhancement**: The `enhance_prompt_with_gtd_data()` function:
   - Detects what data is needed
   - Gathers relevant data
   - Prepends data to the prompt with clear structure
   - Adds instructions to use real data
4. **Automatic Integration**: The `call_deep_model()` function automatically enhances prompts before sending to the AI model

## Usage

The enhancement is **automatic** - no changes needed to how you use the diagramming tool:

```bash
# Automatically gathers project data
gtd-diagram mindmap "my projects"

# Automatically gathers task data
gtd-diagram flowchart "my tasks workflow"

# Automatically gathers all GTD data
gtd-diagram mindmap "my GTD system"
```

To disable GTD data gathering (use original behavior):
- Set `enhance_with_gtd_data=False` when calling the helper programmatically
- Or use `--no-gtd-data` flag if calling directly

## Benefits

✅ **Works with small models** - No tool calling needed, data is gathered before model call
✅ **More accurate diagrams** - Based on your actual GTD system
✅ **Automatic detection** - No need to specify what data to gather
✅ **Backward compatible** - Still works for non-GTD diagram requests

