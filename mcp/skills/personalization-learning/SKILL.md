---
name: Personalization Learning
description: Learn and update personalization data based on insights discovered about the user during conversations. This skill guides when and how to update personalization preferences to improve future interactions.
version: 1.0.0
tags:
  - personalization
  - learning
  - adaptation
  - context
  - user-understanding
author: GTD System
---

# Personalization Learning

This skill guides you on when and how to update personalization data based on insights you discover about the user during conversations.

## When to Use

Use this skill when you discover new, reliable information about the user that would be helpful to remember for future interactions. Update personalization when you learn:

### Relationships & Context
- **Partner/spouse name**: When the user mentions their partner's name (e.g., "Louiza")
- **Family members**: When you learn about family relationships
- **Important people**: When you discover key relationships in their life
- **Relationship details**: When you learn specific details about important people:
  - **Interests/hobbies**: "Louiza is a foodie", "She loves hiking
  - **Birthdays/anniversaries**: "Her birthday is in February", "Our anniversary is in June"
  - **Gift ideas**: "I should buy her a watch band", "She'd love tickets to that show"
  - **Preferences**: Favorite foods, activities, communication style
  - **Notes**: Any other relevant details that would help provide better assistance

### Goals & Values
- **Career goals**: When the user mentions specific career objectives
- **Personal goals**: When you learn about personal aspirations
- **Values**: When the user expresses core values or principles

### Work Patterns & Energy
- **Peak hours**: When you notice patterns in when they're most productive
- **Energy patterns**: When you learn what drains or recharges them
- **Work schedule**: When you understand their typical schedule

### Communication Preferences
- **Tone preference**: When you notice how they prefer to communicate
- **Detail level**: When you learn how much detail they want
- **Feedback style**: When you understand how they like to receive feedback

### Learning & Knowledge
- **Current learning**: When they mention what they're studying
- **Tools/technologies**: When you learn what tools they use
- **Expertise areas**: When you discover their areas of expertise

### Patterns & Insights
- **What works**: When you notice effective strategies they use
- **What doesn't work**: When you learn what hasn't worked for them
- **Stress indicators**: When you identify patterns in their stress

## How It Works

### Step 1: Discover Information

During conversations, pay attention to:
- Direct statements: "My partner Louiza...", "I'm learning Kubernetes...", "I'm most productive in the morning..."
- Patterns: Repeated mentions, consistent behaviors, recurring themes
- Preferences: How they respond to different communication styles

### Step 2: Verify Reliability

Before updating, ensure the information is:
- ✅ **Clear and explicit**: Not inferred or assumed
- ✅ **Reliable**: Mentioned multiple times or clearly stated
- ✅ **Relevant**: Would be useful for future interactions
- ✅ **Accurate**: You're confident it's correct

**Don't update if:**
- ❌ Information is uncertain or inferred
- ❌ It's a one-time mention that might not be important
- ❌ You're guessing or assuming
- ❌ The information conflicts with existing data (verify first)

### Step 3: Update Personalization

Use the `gtd_update_personalization` tool to save the information:

```python
# Example 1: Learning partner's name
# IMPORTANT: For relationships.partner, you can pass either:
# - A string (just the name): value="Louiza" - handler will convert to object
# - An object: value={"name": "Louiza", "relationship_type": "partner"}
gtd_update_personalization(
    category="relationships",
    field="partner",
    value="Louiza",  # String is fine - handler preserves object structure
    operation="set"
)

# Example 2: Learning partner's interests (using dot notation)
gtd_update_personalization(
    category="relationships",
    field="partner.interests",  # Dot notation for nested fields
    value="foodie",  # Will be added to interests list
    operation="append"
)

# Example 3: Learning partner's birthday
gtd_update_personalization(
    category="relationships",
    field="partner.birthday",
    value="February",  # Single value field
    operation="set"
)

# Example 4: Learning gift ideas for partner
gtd_update_personalization(
    category="relationships",
    field="partner.gift_ideas",
    value="watch band",  # Will be added to gift_ideas list
    operation="append"
)

# Example 5: Adding a goal
gtd_update_personalization(
    category="goals",
    field="career",
    value="Learn Kubernetes",
    operation="append"
)

# Example 6: Noting energy pattern
gtd_update_personalization(
    category="energy_patterns",
    field="peak_hours",
    value="09:00-12:00",
    operation="append"
)
```

### Step 4: Confirm Update

After updating, briefly acknowledge what you learned:
- "I've noted that [information] - I'll remember this for future conversations."
- Keep it brief and natural, don't make it feel like data entry

## Best Practices

### When to Update

**DO update when:**
- User explicitly states information: "My partner is Louiza"
- Pattern is clear: User consistently mentions morning productivity
- Goal is mentioned: "I'm working toward my CKA exam"
- Preference is expressed: "I prefer direct communication"

**DON'T update when:**
- Information is uncertain or inferred
- It's a one-time mention that might not be important
- You're guessing based on limited context
- Information conflicts with existing data (verify first)

### How to Update

**Use appropriate operations:**
- **`set`**: For single values or replacing existing data
  - Example: Setting partner name, communication style
- **`append`**: For adding to lists without duplicates
  - Example: Adding goals, energy rechargers, tools
- **`remove`**: For removing items from lists
  - Example: Removing outdated goals or preferences

**Use appropriate categories:**
- `relationships`: Partner, family, friends
  - **Detailed relationship info**: Use dot notation for nested fields
    - `partner.interests`: List of interests/hobbies (e.g., "foodie", "cooking")
    - `partner.birthday`: Birthday month or date (e.g., "February")
    - `partner.gift_ideas`: Gift suggestions (e.g., "watch band", "concert tickets")
    - `partner.preferences`: Preferences (favorite foods, activities, etc.)
    - `partner.notes`: Any other relevant details
- `goals`: Career, personal, financial, learning goals
- `values`: Core values and principles
- `energy_patterns`: Peak hours, rechargers, drainers
- `work_patterns`: Schedule, focus duration, on-call patterns
- `communication_style`: Tone, detail level, feedback style
- `knowledge_areas`: Expertise, learning topics, tools
- `lessons_learned`: What works, what doesn't, patterns

### Be Discreet

- Update in the background when possible
- Don't interrupt the conversation flow
- Acknowledge briefly if appropriate, but don't make it the focus
- Let the update happen naturally as part of the conversation

## Examples

### Example 1: Learning Partner's Name

**Conversation:**
- User: "I had a great conversation with Louiza about this"
- You: [Recognize "Louiza" as partner name]

**Update:**
```python
# You can pass just the name as a string - the handler will preserve object structure
gtd_update_personalization(
    category="relationships",
    field="partner",
    value="Louiza",  # String is fine - handler converts to object automatically
    operation="set"
)
```

**Response:**
- "That's great! I'll remember that Louiza is your partner."

**Note:** The handler automatically converts string values to the proper object structure `{"name": "Louiza", "relationship_type": "partner"}` to maintain consistency.

### Example 1b: Learning Partner's Interests and Details

**Conversation:**
- User: "Louiza is a foodie, and her birthday is in February. I should probably buy her a watch band for her birthday."

**Updates:**
```python
# Store interests
gtd_update_personalization(
    category="relationships",
    field="partner.interests",
    value="foodie",
    operation="append"
)

# Store birthday
gtd_update_personalization(
    category="relationships",
    field="partner.birthday",
    value="February",
    operation="set"
)

# Store gift idea
gtd_update_personalization(
    category="relationships",
    field="partner.gift_ideas",
    value="watch band",
    operation="append"
)
```

**Response:**
- "I'll remember that Louiza is a foodie, her birthday is in February, and that a watch band would be a good gift idea for her."

**Result:** Future conversations, you can reference these details when suggesting activities, gifts, or planning.

### Example 2: Discovering Goals

**Conversation:**
- User: "I'm really focused on learning Kubernetes for my CKA exam"
- You: [Recognize career goal]

**Update:**
```python
gtd_update_personalization(
    category="goals",
    field="career",
    value="Learn Kubernetes for CKA exam",
    operation="append"
)
```

**Response:**
- "I've noted your focus on Kubernetes and the CKA exam - I'll keep this in mind when suggesting tasks."

### Example 3: Noting Energy Patterns

**Conversation:**
- User: "I always do my best work in the morning, around 9-12"
- You: [Recognize energy pattern]

**Update:**
```python
gtd_update_personalization(
    category="energy_patterns",
    field="peak_hours",
    value="09:00-12:00",
    operation="append"
)
```

**Response:**
- "I'll remember that you're most productive in the morning - I'll suggest important tasks for that time."

### Example 4: Understanding Communication Style

**Conversation:**
- User: "I prefer when you're direct and to the point"
- You: [Recognize communication preference]

**Update:**
```python
gtd_update_personalization(
    category="communication_style",
    field="tone_preference",
    value="direct",
    operation="set"
)
```

**Response:**
- "Got it - I'll be more direct and concise in my responses."

## Integration with Other Skills

This skill works well with:
- **`personalization-info`**: Read existing personalization before updating
- **`interactive-morning-review-runbook`**: Learn patterns during morning routines
- **`daily-review`**: Discover insights during reviews

## Success Criteria

Personalization learning is working well when:
- ✓ You remember important details across conversations
- ✓ You provide increasingly personalized assistance
- ✓ You avoid asking for information you've already learned
- ✓ The user notices you "remember" things about them
- ✓ Updates are accurate and don't conflict with existing data

## Troubleshooting

### Information Conflicts

If new information conflicts with existing data:
1. Check existing personalization first: `gtd_get_personalization(category="...")`
2. Verify which is correct (ask user if needed)
3. Update accordingly

### Uncertain Information

If you're not sure about information:
- Don't update - it's better to ask or wait for confirmation
- You can ask: "Should I remember that [information] for future conversations?"

### Over-Updating

Don't update for every small detail:
- Focus on information that will be useful in future interactions
- Don't update one-time mentions that aren't important
- Prioritize relationships, goals, and preferences over minor details

## Remember

The goal is to make the system more helpful by remembering what matters to the user. Update thoughtfully, verify accuracy, and let the learning happen naturally as part of the conversation.
