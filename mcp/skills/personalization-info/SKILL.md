---
name: Personalization Information
description: Access and use personalization data to provide context-aware, personalized assistance. This skill provides information about the user's relationships, goals, preferences, work patterns, and more.
version: 1.0.0
tags:
  - personalization
  - context
  - user-info
  - relationships
  - goals
  - preferences
author: GTD System
---

# Personalization Information

This skill provides access to personalization data that helps the AI understand the user better and provide more context-aware, personalized assistance.

## When to Use

Use this skill when you need to:

- **Understand context**: Know who important people are (e.g., "Louiza" is the user's partner)
- **Align with goals**: Reference the user's actual goals and priorities
- **Match communication style**: Use the user's preferred tone and detail level
- **Respect patterns**: Consider energy patterns, work schedules, and preferences
- **Provide relevant advice**: Tailor suggestions to the user's situation and values
- **Avoid confusion**: Correctly identify the user vs. people mentioned in logs

## How It Works

This skill provides access to personalization data stored in `~/.gtd_personalization.json`. The data includes:

1. **Relationships & Life Situation**
   - Partner/spouse information
   - Family members
   - Living arrangement
   - Timezone and life phase

2. **Goals, Values & Priorities**
   - Career goals
   - Personal goals
   - Financial goals
   - Core values
   - Current focus areas

3. **Work Patterns & Energy Management**
   - Peak productivity hours
   - Energy rechargers
   - Typical work schedule
   - Focus duration

4. **Health & Wellness**
   - Sleep needs
   - Exercise patterns
   - Wellness tracking

5. **Communication Preferences**
   - Preferred tone (direct, supportive, casual, formal)
   - Detail level (concise, moderate, detailed)
   - Feedback style

6. **Learning Style & Knowledge**
   - Currently learning topics
   - Tools/technologies in use
   - Learning preferences

7. **Decision-Making & Problem-Solving**
   - Decision style
   - Problem-solving approach

8. **Stress & Coping Mechanisms**
   - Effective coping strategies
   - Stress indicators

9. **Interests & Personal Life**
   - Hobbies
   - Creative pursuits
   - Personal projects

10. **Professional Context**
    - Role/title
    - Industry
    - Career stage
    - Key responsibilities

11. **Tools & Systems**
    - Tools in regular use
    - Tools being learned
    - Preferred editors

12. **Lessons Learned**
    - What has worked well
    - What hasn't worked
    - Patterns noticed

## Usage

### Method 1: Get Full Personalization Data

```python
# Get all personalization information
execute_agent_skill(
    skill_name="personalization-info",
    method="script:read_personalization.py"
)
```

This returns the complete personalization JSON data.

### Method 2: Get Specific Category

```python
# Get specific category (e.g., relationships, goals, energy_patterns)
execute_agent_skill(
    skill_name="personalization-info",
    method="script:read_personalization.py",
    args={"category": "relationships"}
)
```

### Method 3: Read Instructions (Default)

```python
# Get instructions on how to use personalization data
execute_agent_skill(
    skill_name="personalization-info",
    method="instructions"
)
```

## Integration with AI Interactions

### When Providing Advice

1. **Check personalization data** before giving advice
2. **Reference user's goals** when relevant
3. **Use preferred communication style** (tone, detail level)
4. **Consider energy patterns** when suggesting task timing
5. **Respect values** when making recommendations

### When Processing Logs

1. **Identify the user correctly** (use personalization to know the user's name)
2. **Understand relationships** (know who "Louiza" is, etc.)
3. **Recognize context** (understand life situation, work patterns)
4. **Detect patterns** (match against known stress indicators, energy patterns)

### When Creating Suggestions

1. **Align with goals** (prioritize suggestions that match user's goals)
2. **Match preferences** (suggest tasks at optimal times based on energy patterns)
3. **Respect values** (avoid suggesting things that conflict with user's values)
4. **Consider context** (understand work schedule, on-call patterns, etc.)

## Best Practices

### Always Check Personalization

Before providing advice or suggestions:
1. Call `execute_agent_skill(skill_name="personalization-info", method="script:read_personalization.py")`
2. Review relevant categories
3. Use the information to personalize your response

### Use Relationships Correctly

- **User name**: Use the name from personalization (not from logs)
- **Partner/spouse**: Reference correctly (e.g., "Louiza" is the partner)
- **Family**: Know who family members are
- **Avoid confusion**: Don't confuse the user with people mentioned in logs

### Align with Goals

- Reference user's actual goals when relevant
- Suggest tasks that align with goals
- Remind user of goals when appropriate
- Celebrate progress toward goals

### Match Communication Style

- **Tone**: Use preferred tone (direct, supportive, casual, formal)
- **Detail level**: Provide appropriate detail (concise, moderate, detailed)
- **Feedback style**: Match feedback approach

### Respect Patterns

- **Energy patterns**: Suggest tasks at optimal times
- **Work schedule**: Understand typical schedule and on-call patterns
- **Focus duration**: Respect attention span
- **Recovery needs**: Understand what helps user recharge

## Example Workflows

### Example 1: Morning Check-In with Personalization

```python
# 1. Get personalization data
personalization = execute_agent_skill(
    skill_name="personalization-info",
    method="script:read_personalization.py"
)

# 2. Use energy patterns to suggest task timing
peak_hours = personalization["energy_patterns"]["peak_hours"]
# Suggest deep work during peak hours

# 3. Reference goals when setting priorities
goals = personalization["goals"]["career"]
# Align daily priorities with career goals

# 4. Use preferred communication style
tone = personalization["communication_style"]["tone_preference"]
# Adjust response tone accordingly
```

### Example 2: Processing Log Entry with Context

```python
# 1. Get personalization to understand relationships
personalization = execute_agent_skill(
    skill_name="personalization-info",
    method="script:read_personalization.py"
)

# 2. Identify user correctly
user_name = personalization.get("user_name", "User")

# 3. Understand relationships
partner_name = personalization["relationships"]["partner"].get("name")
# Now you know who "Louiza" is if mentioned in logs

# 4. Provide context-aware response
# Address user correctly, understand relationship context
```

### Example 3: Creating Personalized Suggestions

```python
# 1. Get personalization data
personalization = execute_agent_skill(
    skill_name="personalization-info",
    method="script:read_personalization.py"
)

# 2. Align suggestions with goals
goals = personalization["goals"]["career"]
# Filter suggestions to match career goals

# 3. Consider energy patterns
peak_hours = personalization["energy_patterns"]["peak_hours"]
# Schedule important tasks during peak hours

# 4. Match communication style
detail_level = personalization["communication_style"]["detail_level"]
# Provide appropriate level of detail in suggestions
```

## Data Privacy

- All personalization data is stored locally in `~/.gtd_personalization.json`
- No data is shared externally
- User controls what information to share
- User can update or delete data anytime

## Troubleshooting

### Personalization File Not Found

If the personalization file doesn't exist:
- The user hasn't set up personalization yet
- Suggest running the personalization wizard: `gtd-wizard` → option 67
- You can still provide assistance, just without personalization context

### Missing Categories

If a category is missing:
- User may not have filled it out yet
- Use available information
- Don't assume values for missing categories

### Outdated Information

- Personalization data may become outdated
- User can update via wizard anytime
- Consider suggesting updates if you notice inconsistencies

## Related Skills

- **`morning-checkin`**: Uses personalization to set daily priorities aligned with goals
- **`daily-review`**: Uses personalization to provide personalized reflection
- **`inbox-processing`**: Uses personalization to suggest contexts and priorities

## Success Criteria

Personalization is working well when:
- ✓ AI correctly identifies the user (not confusing with others)
- ✓ Suggestions align with user's actual goals
- ✓ Communication style matches user's preferences
- ✓ Task timing respects energy patterns
- ✓ Advice considers user's values and situation

Remember: Personalization makes the AI more helpful by understanding the user's unique context, goals, and preferences.
