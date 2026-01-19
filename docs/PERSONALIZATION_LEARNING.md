# Personalization Learning - AI-Driven Updates

## Overview

The system now supports **AI-driven personalization learning** - Claude can discover information about you during conversations and update your personalization data automatically. This allows the system to learn and adapt over time without manual updates.

## How It Works

### 1. **Discovery During Conversations**

As you interact with Claude, it pays attention to:
- **Direct statements**: "My partner Louiza...", "I'm learning Kubernetes...", "I'm most productive in the morning..."
- **Patterns**: Repeated mentions, consistent behaviors, recurring themes
- **Preferences**: How you respond to different communication styles

### 2. **Automatic Updates**

When Claude discovers reliable information, it can update your personalization data using:
- **Tool**: `gtd_update_personalization` - Direct tool for updating data
- **Skill**: `personalization-learning` - Guidance on when and how to update

### 3. **What Gets Updated**

Claude can learn and update:
- **Relationships**: Partner name, family members, important people
- **Goals**: Career goals, personal goals, learning objectives
- **Energy Patterns**: Peak productivity hours, what recharges you
- **Communication Style**: Preferred tone, detail level
- **Work Patterns**: Typical schedule, focus duration
- **Lessons Learned**: What works, what doesn't work
- And more...

## Example Scenarios

### Scenario 1: Learning Partner's Name

**You say:**
> "I had a great conversation with Louiza about this project"

**Claude:**
1. Recognizes "Louiza" as likely the partner
2. Updates personalization: `gtd_update_personalization(category="relationships", field="partner", value={"name": "Louiza", "relationship_type": "partner"})`
3. Responds: "That's great! I'll remember that Louiza is your partner."

**Result:** Future conversations, Claude knows who "Louiza" is without asking.

### Scenario 2: Discovering Goals

**You say:**
> "I'm really focused on learning Kubernetes for my CKA exam"

**Claude:**
1. Recognizes career goal
2. Updates: `gtd_update_personalization(category="goals", field="career", value="Learn Kubernetes for CKA exam", operation="append")`
3. Responds: "I've noted your focus on Kubernetes and the CKA exam - I'll keep this in mind when suggesting tasks."

**Result:** Future suggestions align with your actual goals.

### Scenario 3: Noting Energy Patterns

**You say:**
> "I always do my best work in the morning, around 9-12"

**Claude:**
1. Recognizes energy pattern
2. Updates: `gtd_update_personalization(category="energy_patterns", field="peak_hours", value="09:00-12:00", operation="append")`
3. Responds: "I'll remember that you're most productive in the morning - I'll suggest important tasks for that time."

**Result:** Future task suggestions respect your energy patterns.

## Safety & Accuracy

### Claude's Guidelines

Claude only updates when:
- ✅ Information is **clear and explicit** (not inferred)
- ✅ Information is **reliable** (mentioned multiple times or clearly stated)
- ✅ Information is **relevant** (would be useful for future interactions)
- ✅ Information is **accurate** (Claude is confident it's correct)

Claude does NOT update when:
- ❌ Information is uncertain or inferred
- ❌ It's a one-time mention that might not be important
- ❌ Claude is guessing or assuming
- ❌ Information conflicts with existing data (verifies first)

### Verification

If Claude is uncertain, it may:
- Ask for confirmation: "Should I remember that [information] for future conversations?"
- Check existing data first before updating
- Skip updating if information is unclear

## Manual Override

You can always:
- **Review updates**: Check `~/.gtd_personalization.json` to see what Claude learned
- **Edit manually**: Use the wizard (`gtd-wizard` → option 67) to edit any category
- **Reset**: Delete the file and start fresh if needed

## Privacy

- ✅ All data stored locally in `~/.gtd_personalization.json`
- ✅ No external sharing
- ✅ You control what information Claude learns
- ✅ You can review and edit anytime

## Benefits

### For You
- **Less manual entry**: Claude learns as you talk
- **More personalized**: System adapts to you automatically
- **Better suggestions**: Aligned with your actual goals and patterns
- **Context awareness**: Claude remembers important details

### For Claude
- **Better understanding**: Learns your context, goals, and preferences
- **More helpful**: Can provide increasingly personalized assistance
- **Fewer questions**: Doesn't need to ask for information it already learned
- **Adaptive**: System improves over time

## Integration

### With Personalization Wizard

The learning system works alongside the manual wizard:
- **Wizard**: For initial setup and manual updates
- **Learning**: For automatic updates during conversations
- **Both**: Update the same file, so they work together seamlessly

### With Other Skills

The learning skill integrates with:
- **`personalization-info`**: Claude reads existing data before updating
- **`morning-checkin`**: Learns patterns during morning routines
- **`daily-review`**: Discovers insights during reviews

## Monitoring

### View What Claude Learned

```bash
# View personalization file
cat ~/.gtd_personalization.json | python3 -m json.tool

# Or use the wizard
gtd-wizard
# Select: 67) Personalization Setup
# Then: 13) View Current Personalization
```

### Check Last Updated

The file includes a `last_updated` timestamp showing when Claude last made changes.

## Best Practices

### For You
- **Be explicit**: When mentioning important information, be clear
- **Review periodically**: Check what Claude learned and correct if needed
- **Trust but verify**: Claude is careful, but review important updates

### For Claude
- **Learn thoughtfully**: Only update when information is clear and reliable
- **Be discreet**: Update in the background, don't interrupt conversation flow
- **Verify conflicts**: Check existing data before updating conflicting information

## Troubleshooting

### Claude Not Learning

If Claude doesn't seem to be learning:
1. Check if `gtd_update_personalization` tool is available
2. Verify personalization file exists (Claude can create it if needed)
3. Make sure information is clear and explicit when you mention it

### Incorrect Updates

If Claude learns something incorrectly:
1. Review the personalization file
2. Edit via wizard: `gtd-wizard` → option 67
3. Or edit the JSON file directly

### Too Many Updates

If Claude updates too frequently:
- This is normal - Claude is careful and only updates when confident
- You can review and remove updates if needed
- Claude learns to be more selective over time

## Future Enhancements

Potential improvements:
- Learning from daily logs automatically
- Pattern recognition across multiple conversations
- Confidence scoring for learned information
- User confirmation for important updates

## Related Documentation

- [Personalization Capabilities](./PERSONALIZATION_CAPABILITIES.md) - What information is helpful
- [Personalization Wizard](./PERSONALIZATION_WIZARD.md) - Manual setup and updates
- [Personalization Skill](./PERSONALIZATION_SKILL.md) - How Claude accesses personalization data

## Summary

The personalization learning system allows Claude to:
- ✅ Discover information about you during conversations
- ✅ Update personalization data automatically
- ✅ Provide increasingly personalized assistance
- ✅ Learn and adapt over time

All while maintaining privacy, accuracy, and giving you full control over your data.
