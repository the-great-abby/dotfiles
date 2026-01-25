# Using Sequential Thinking in Claude Ask TUI

## Overview

Sequential Thinking tools are now available in the Claude Ask TUI! They help Claude break down complex problems into structured, step-by-step reasoning, which reduces hallucination and improves accuracy.

## Available Tools

The TUI now includes 4 Sequential Thinking tools:

1. **`create_thoughts`** - Start a structured thinking process
2. **`revise_thought`** - Revise a previous thought
3. **`branch_thought`** - Create alternative reasoning paths
4. **`summarize_thoughts`** - Get a summary of the thinking process

## How to Use

### Method 1: Ask Claude to Use Sequential Thinking

Simply ask Claude to use Sequential Thinking for complex problems:

```
"Help me plan my week using sequential thinking"
"Break down this problem step by step using sequential thinking"
"Use sequential thinking to analyze my productivity patterns"
```

Claude will automatically use the `create_thoughts` tool to start a structured thinking process.

### Method 2: Explicitly Request Sequential Thinking

You can be more explicit:

```
"Use the create_thoughts tool to analyze how I should organize my tasks"
"Start a sequential thinking process about my project priorities"
```

### Method 3: For Complex Analysis

When reviewing daily logs or analyzing patterns:

```
"Review my daily log using sequential thinking to identify patterns"
"Use sequential thinking to break down my weekly review"
```

## Example Workflow

**User:** "Help me plan my week using sequential thinking"

**Claude's Process:**
1. Calls `gtd_read_daily_log(date='today')` to get today's log
2. Calls `gtd_list_tasks(status='active')` to see current tasks
3. Calls `create_thoughts(thought="First, I need to understand what's on the user's plate...", nextThoughtNeeded=True)`
4. Continues with more thoughts, analyzing priorities
5. Calls `summarize_thoughts()` to provide final recommendations

## When to Use Sequential Thinking

✅ **Use for:**
- Complex problem analysis
- Strategic planning
- Breaking down large projects
- Analyzing patterns and trends
- Multi-step decision making
- When you want structured, step-by-step reasoning

❌ **Don't need for:**
- Simple questions ("What's 2+2?")
- Quick lookups ("What tasks do I have?")
- Single-step operations ("Create a task")

## Requirements

Sequential Thinking tools require the Sequential Thinking MCP server to be available. The system will try:

1. **Docker** (if `mcp/sequentialthinking` image exists)
2. **NPX** (if Node.js is available)

If neither is available, you'll get an error message with instructions.

## Verification

Press `Ctrl+T` in the TUI to see if Sequential Thinking tools are loaded. You should see:
- Total tools count
- Sequential Thinking tools listed (if available)

## Troubleshooting

### Tools Not Available

**Error:** "Sequential Thinking MCP not available"

**Solutions:**
1. **Install Docker image:**
   ```bash
   docker pull mcp/sequentialthinking
   ```

2. **Or ensure NPX is available:**
   ```bash
   which npx  # Should show npx path
   ```

3. **Check Docker is running:**
   ```bash
   docker ps  # Should not error
   ```

### Tools Load But Don't Work

If tools appear in `Ctrl+T` but fail when used:

1. Check Docker image exists: `docker images | grep sequential`
2. Test Docker command: `docker run --rm -i mcp/sequentialthinking`
3. Check Cursor DevTools for MCP errors

## Benefits

Using Sequential Thinking helps:
- ✅ **Reduce hallucination** - Structured reasoning prevents making up data
- ✅ **Better analysis** - Step-by-step breakdown of complex problems
- ✅ **Traceable logic** - You can see how Claude reached conclusions
- ✅ **Revisable** - Can revise earlier thoughts if needed
- ✅ **Branching** - Explore alternative approaches

## Integration with GTD Tools

Sequential Thinking works seamlessly with GTD tools:

```
1. Use create_thoughts to analyze a problem
2. Use gtd_list_tasks to get real task data
3. Use gtd_read_daily_log to understand context
4. Use gtd_create_task to create tasks based on analysis
5. Use summarize_thoughts to get final recommendations
```

This combination gives you structured reasoning with real GTD data!
