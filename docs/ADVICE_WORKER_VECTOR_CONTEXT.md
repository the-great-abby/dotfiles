# Advice Worker Vector Database Context

## Overview

The advice worker now searches your vector database for relevant context before answering questions. This allows the AI to reference your stored knowledge (Pathfinder sessions, notes, tasks, projects, etc.) when providing advice.

## Default Configuration

By default, the advice worker uses **maximum context** settings:

- **20 results** from vector database
- **0.5 similarity threshold** (lower = more results included)
- **1000 characters per result** (more detail per item)
- **8000 characters total context** (comprehensive context)

## Customizing Context Amount

You can customize how much context is included via environment variables:

### Maximum Results

```bash
# Get more results (default: 20)
export GTD_ADVICE_VECTOR_LIMIT=50

# Get fewer results (faster, less context)
export GTD_ADVICE_VECTOR_LIMIT=10
```

### Similarity Threshold

```bash
# Lower threshold = more results included (default: 0.5)
export GTD_ADVICE_VECTOR_THRESHOLD=0.3  # Very permissive, includes more results

# Higher threshold = only very relevant results (default: 0.5)
export GTD_ADVICE_VECTOR_THRESHOLD=0.7  # Stricter, only highly relevant
```

### Characters Per Result

```bash
# More detail per result (default: 1000)
export GTD_ADVICE_VECTOR_CHARS_PER_RESULT=2000

# Less detail per result (default: 1000)
export GTD_ADVICE_VECTOR_CHARS_PER_RESULT=500
```

### Total Context Limit

```bash
# Maximum total context (default: 8000)
export GTD_ADVICE_VECTOR_MAX_CONTEXT=15000  # Even more context

# Less total context (default: 8000)
export GTD_ADVICE_VECTOR_MAX_CONTEXT=4000  # More focused
```

## Maximum Context Configuration

For **as much context as possible**, set these environment variables:

```bash
export GTD_ADVICE_VECTOR_LIMIT=50          # Get 50 results
export GTD_ADVICE_VECTOR_THRESHOLD=0.3     # Very permissive threshold
export GTD_ADVICE_VECTOR_CHARS_PER_RESULT=2000  # More detail per result
export GTD_ADVICE_VECTOR_MAX_CONTEXT=15000  # Large total context limit
```

## Adding to Config File

You can also add these to your `.gtd_config` or `.gtd_config_ai` file:

```bash
# Maximum context for advice requests
GTD_ADVICE_VECTOR_LIMIT=50
GTD_ADVICE_VECTOR_THRESHOLD=0.3
GTD_ADVICE_VECTOR_CHARS_PER_RESULT=2000
GTD_ADVICE_VECTOR_MAX_CONTEXT=15000
```

## How It Works

1. **Question received**: "What happened in Pathfinder session 12?"
2. **Vector search**: Searches your vector database for relevant content
3. **Context building**: Includes top N results with similarity >= threshold
4. **Enhanced prompt**: Question + vector context sent to deep AI model
5. **Response**: AI answers using your stored knowledge

## Example

**Question**: "What happened in Pathfinder session 12?"

**Vector Search Results**:
- `daily_log:2025-12-05` (relevance: 0.85): "Session 12: The party explored the Old Sycamore..."
- `note:pathfinder_campaign` (relevance: 0.78): "Session 12 summary: The party discovered..."
- `task:pathfinder_prep` (relevance: 0.72): "Prepare for session 12: Include encounter with..."

**AI Response**: Uses the actual session notes and campaign information from your database.

## Performance Considerations

- **More context = slower processing** (more tokens to process)
- **More context = better answers** (more information available)
- **Balance**: Default settings provide good balance, but you can increase for comprehensive answers

## Simple Mode

Vector database search is **skipped** in "simple" mode (for factual questions that don't need GTD context).

## Troubleshooting

If vector search fails:
- The worker will continue without vector context
- Check that your vector database is set up correctly
- Verify that content has been vectorized (run `make filewatcher-scan`)
