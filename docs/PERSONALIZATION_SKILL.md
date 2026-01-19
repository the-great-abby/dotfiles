# Personalization Information Skill

## Overview

The **Personalization Information** skill makes your personalization data available to the AI system, allowing it to provide more context-aware, personalized assistance.

## What It Does

This skill provides the AI with access to information about you, including:
- Relationships (who "Louiza" is, family members, etc.)
- Goals and values
- Work patterns and energy management
- Communication preferences
- Learning style and knowledge areas
- And more...

## How the AI Uses It

When the AI needs context about you, it can:

1. **Discover the skill**: `list_agent_skills(query="personalization")`
2. **Get skill details**: `get_agent_skill(skill_name="personalization-info")`
3. **Read your data**: `execute_agent_skill(skill_name="personalization-info", method="script:read_personalization.py")`

## Example: How Claude Uses It

When you ask Claude something like "Help me do my morning check-in", Claude will:

1. Discover available skills (including personalization-info)
2. Read your personalization data to understand:
   - Your goals (e.g., "Learn Kubernetes", "CKA exam")
   - Your energy patterns (when you're most productive)
   - Your partner's name (so it knows who "Louiza" is)
   - Your communication preferences
3. Use this information to provide personalized advice

## Benefits

### 1. Correct Context Understanding

**Before:**
- AI might confuse you with people mentioned in logs
- Doesn't know who "Louiza" is
- Doesn't understand your relationships

**After:**
- AI knows you are "Abby" (or your name)
- Knows "Louiza" is your partner
- Understands relationship context

### 2. Goal-Aligned Suggestions

**Before:**
- Generic suggestions that may not match your goals
- Doesn't know what you're working toward

**After:**
- Suggestions align with your actual goals
- References your goals when relevant
- Helps you make progress on what matters

### 3. Personalized Communication

**Before:**
- One-size-fits-all communication style
- May be too detailed or too brief

**After:**
- Matches your preferred tone (direct, supportive, etc.)
- Provides appropriate detail level
- Communicates in your style

### 4. Respects Your Patterns

**Before:**
- Suggests tasks at random times
- Doesn't consider your energy levels

**After:**
- Suggests tasks during your peak hours
- Understands your work schedule
- Respects your focus duration

## Setup

### Step 1: Configure Personalization

First, set up your personalization data:

```bash
gtd-wizard
# Select: 67) 👤 Personalization Setup
```

Fill in the categories that matter to you. You don't need to fill everything - start with the most important.

### Step 2: Skill is Auto-Discovered

The skill is automatically discovered from `mcp/skills/personalization-info/`. No additional setup needed!

### Step 3: AI Uses It Automatically

When you interact with Claude (via `claude-ask` or other tools), the AI can access your personalization data through this skill.

## Usage Examples

### Example 1: Morning Check-In

```python
# Claude automatically uses personalization when you ask:
# "Help me do my morning check-in"

# Claude will:
# 1. Get your personalization data
personalization = execute_agent_skill(
    skill_name="personalization-info",
    method="script:read_personalization.py"
)

# 2. Use your goals to set priorities
goals = personalization["goals"]["career"]
# Suggests tasks aligned with "Learn Kubernetes", "CKA exam", etc.

# 3. Consider your energy patterns
peak_hours = personalization["energy_patterns"]["peak_hours"]
# Suggests deep work during your peak hours (e.g., 09:00-12:00)

# 4. Use your preferred communication style
tone = personalization["communication_style"]["tone_preference"]
# Communicates in your preferred style
```

### Example 2: Processing Logs

```python
# When processing daily logs, Claude uses personalization to:

# 1. Identify you correctly
user_name = personalization.get("user_name", "User")
# Knows you are "Abby", not "Louiza" or others mentioned in logs

# 2. Understand relationships
partner_name = personalization["relationships"]["partner"].get("name")
# Knows "Louiza" is your partner when mentioned in logs

# 3. Provide context-aware advice
# Understands your situation, goals, and patterns
```

### Example 3: Creating Suggestions

```python
# When creating task suggestions, Claude uses personalization to:

# 1. Align with your goals
goals = personalization["goals"]["career"]
# Only suggests tasks that match your goals

# 2. Match your preferences
communication_style = personalization["communication_style"]
# Provides suggestions in your preferred style

# 3. Consider your patterns
energy_patterns = personalization["energy_patterns"]
# Suggests timing based on your energy patterns
```

## Manual Access

You can also manually access your personalization data:

### Via Python

```python
from pathlib import Path
import json

personalization_file = Path.home() / ".gtd_personalization.json"
with open(personalization_file) as f:
    data = json.load(f)
    
print(json.dumps(data, indent=2))
```

### Via Command Line

```bash
cat ~/.gtd_personalization.json | python3 -m json.tool
```

### Via Skill Script

```bash
python3 ~/code/dotfiles/mcp/skills/personalization-info/scripts/read_personalization.py
```

## Updating Personalization

To update your personalization data:

```bash
gtd-wizard
# Select: 67) 👤 Personalization Setup
# Then choose which category to update
```

The AI will automatically use the updated information on the next interaction.

## Privacy

- ✅ All data stored locally in `~/.gtd_personalization.json`
- ✅ No external sharing
- ✅ You control what information to share
- ✅ You can update or delete anytime

## Troubleshooting

### Skill Not Found

If the skill doesn't appear:
1. Check that the skill directory exists: `mcp/skills/personalization-info/`
2. Reload skills: `reload_agent_skills()` (if available)
3. Restart the MCP server if needed

### Personalization File Not Found

If the AI reports the file doesn't exist:
1. Run the personalization wizard: `gtd-wizard` → option 67
2. Fill in at least one category
3. The file will be created automatically

### Outdated Information

If the AI seems to have outdated information:
1. Update your personalization: `gtd-wizard` → option 67
2. The AI will use updated data on next interaction

## Related Documentation

- [Personalization Capabilities](./PERSONALIZATION_CAPABILITIES.md) - What information is helpful
- [Personalization Wizard](./PERSONALIZATION_WIZARD.md) - How to set up personalization
- [Agent Skills Guide](../mcp/AGENT_SKILLS.md) - How skills work in general

## Next Steps

1. **Set up personalization**: Run the wizard and fill in key categories
2. **Use the system**: The AI will automatically use your personalization data
3. **Refine over time**: Add more details as you think of them
4. **Update regularly**: Keep goals and preferences current

The more complete your personalization data, the better the AI can assist you!
