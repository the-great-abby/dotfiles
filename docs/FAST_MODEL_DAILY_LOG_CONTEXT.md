# Fast Model with Daily Log Context Pre-loading

## Overview

The fast model can now be pre-loaded with daily log context, making it aware of your daily logs before answering questions. This makes responses faster and more context-aware when asking about your daily activities.

## How It Works

When you pre-load daily log context:
1. **Context is loaded** from your daily log files
2. **Context is added to the system prompt** so the model is aware of it
3. **Model answers questions** with full awareness of your daily logs
4. **Responses are faster** because context is already loaded

## Usage

### Method 1: Using the Convenience Wrapper

```python
from mcp.gtd_mcp_server import call_fast_ai_with_daily_log

# Ask a question with today's daily log context pre-loaded
response = call_fast_ai_with_daily_log(
    "What did I work on today?",
    date_range="today"
)

# Ask with this week's context
response = call_fast_ai_with_daily_log(
    "What patterns do you see in my work this week?",
    date_range="week"
)

# Ask with this month's context
response = call_fast_ai_with_daily_log(
    "What are my main focus areas this month?",
    date_range="month"
)
```

### Method 2: Manual Context Loading

```python
from mcp.gtd_mcp_server import call_fast_ai, load_daily_log_context

# Load context manually
context = load_daily_log_context(date_range="today", max_length=2000)

# Call fast AI with context
response = call_fast_ai(
    "What did I accomplish today?",
    context=context
)
```

### Method 3: Custom Context

```python
from mcp.gtd_mcp_server import call_fast_ai

# Pre-load any context you want
custom_context = """
Today's tasks:
- Completed project proposal
- Had meeting with team
- Started new feature
"""

response = call_fast_ai(
    "What should I focus on next?",
    context=custom_context
)
```

## Date Ranges

- `"today"` - Today's daily log only
- `"week"` - Last 7 days
- `"month"` - Last 30 days
- `"all"` - All logs (limited to last 30 days for performance)
- `"YYYY-MM-DD"` - Specific date (e.g., `"2024-12-22"`)

## Benefits

1. **Faster Responses**: Context is pre-loaded, so the model doesn't need to search for it
2. **More Context-Aware**: Model has full awareness of your daily logs before answering
3. **Better Answers**: Responses reference your actual activities and patterns
4. **Flexible**: Can use any date range or custom context

## Example Use Cases

### Quick Daily Review
```python
response = call_fast_ai_with_daily_log(
    "Give me a quick summary of today",
    date_range="today"
)
```

### Pattern Analysis
```python
response = call_fast_ai_with_daily_log(
    "What patterns do you notice in my work this week?",
    date_range="week"
)
```

### Goal Tracking
```python
response = call_fast_ai_with_daily_log(
    "Am I making progress on my goals this month?",
    date_range="month"
)
```

### Specific Date Review
```python
response = call_fast_ai_with_daily_log(
    "What did I do on December 15th?",
    date_range="2024-12-15"
)
```

## Configuration

The context length is limited to 2000 characters by default to avoid token limits. You can adjust this:

```python
context = load_daily_log_context(date_range="week", max_length=4000)
```

## Integration with Existing Code

If you're already using `call_fast_ai`, you can easily add context:

```python
# Before
response = call_fast_ai("What should I do next?")

# After (with daily log context)
context = load_daily_log_context("today")
response = call_fast_ai("What should I do next?", context=context)
```

## Notes

- Context is added to the system prompt, so it's always available to the model
- The model is instructed to reference the context when relevant
- Context is truncated if too long (keeps most recent content)
- Works with both regular chat models and instruct models

