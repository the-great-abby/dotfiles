# Acronym Filtering Enhancement

## Overview

Enhanced the advisor system to intelligently filter acronyms, only including those that are relevant to the current conversation. This reduces token bloat and prevents advisors from being overloaded with unnecessary information.

## What Changed

### Before
- All acronyms (up to 50) were included in every advisor call
- No context awareness - same acronyms sent regardless of conversation topic
- Could overwhelm advisors with irrelevant information

### After
- Only **relevant acronyms** are included (default: max 10)
- Context-aware filtering - only acronyms mentioned in the conversation are included
- Core GTD acronyms (GTD, PARA, MOC, Zettelkasten) are always included
- Configurable limit to control how many acronyms to include

## How It Works

The filtering system uses a smart algorithm:

1. **Core GTD Acronyms** (always included, up to 3):
   - GTD
   - PARA
   - MOC
   - Zettelkasten

2. **Context-Based Filtering**:
   - Scans the conversation content for acronym mentions
   - Only includes acronyms that appear in the content
   - Also checks if key terms from acronym definitions appear in content
   - Limits total acronyms to prevent overload

3. **Priority**:
   - Core acronyms added first
   - Then context-relevant acronyms
   - Stops when limit is reached

## Configuration

You can configure the maximum number of acronyms in your `.gtd_config` file:

```bash
# Maximum number of acronyms to include with advisors (default: 10)
# Lower = less context, faster responses, less token usage
# Higher = more context, potentially more relevant acronyms
GTD_MAX_ACRONYMS=10
```

**Recommended values:**
- `5-10`: Minimal context, fast responses (recommended for most use cases)
- `10-15`: Balanced context and performance
- `15-20`: Maximum context (use if you frequently discuss technical topics)

## Examples

### Example 1: Kubernetes Discussion
**Your question:** "Help me prepare for my CKA certification"

**Acronyms included:**
- GTD (core)
- PARA (core)
- MOC (core)
- CKA (appears in content)

**Total: 4 acronyms** (much less than 50!)

### Example 2: AWS Project
**Your question:** "I'm working on deploying to AWS using Terraform and need to set up VPC networking"

**Acronyms included:**
- GTD (core)
- PARA (core)
- AWS (appears in content)
- Terraform (appears in content)
- VPC (appears in content)

**Total: 5 acronyms**

### Example 3: General Productivity
**Your question:** "What should I focus on today?"

**Acronyms included:**
- GTD (core)
- PARA (core)
- MOC (core)

**Total: 3 acronyms** (minimal, only core GTD concepts)

## Benefits

1. **Reduced Token Usage**: Only relevant acronyms are sent, saving tokens
2. **Faster Responses**: Less context to process means faster advisor responses
3. **More Focused**: Advisors aren't distracted by irrelevant acronym definitions
4. **Better Performance**: Lower token counts mean better performance, especially with smaller models
5. **Still Complete**: Core GTD acronyms always included, so GTD conversations work perfectly

## Technical Details

### Filtering Algorithm

The system uses multiple strategies to identify relevant acronyms:

1. **Direct Mention**: Checks if acronym appears in content (case-insensitive, whole-word matching)
2. **Definition Matching**: Checks if key terms from the acronym's definition appear in content
3. **Stop Word Filtering**: Ignores common words when matching definitions

### Configuration

The limit can be set in `.gtd_config`:
- `GTD_MAX_ACRONYMS`: Maximum acronyms to include (default: 10)
- Falls back to 10 if not configured or invalid value

### Fallback Behavior

- If content is empty or no acronyms match, only core GTD acronyms are included
- If filtering fails, falls back to including a small subset (core acronyms only)
- Never exceeds the configured maximum

## Migration

No migration needed! The enhancement is backward compatible:
- Existing configurations continue to work
- Default limit (10) is applied if not configured
- Previous behavior can be restored by setting `GTD_MAX_ACRONYMS=50` (not recommended)

## Tips

1. **Start with default (10)**: This works well for most conversations
2. **Adjust based on your needs**: If you discuss many technical topics, you might want 15-20
3. **Monitor token usage**: If responses are slow, try reducing the limit
4. **Core acronyms always included**: Don't worry about missing GTD concepts

## Troubleshooting

### Too few acronyms?
- Increase `GTD_MAX_ACRONYMS` in your config
- Check that acronyms are spelled correctly in your content

### Too many acronyms?
- Decrease `GTD_MAX_ACRONYMS` in your config
- Consider if all acronyms are really necessary

### Core GTD acronyms missing?
- They should always be included - this shouldn't happen
- Check that your `.gtd_acronyms` file has GTD, PARA, MOC entries

