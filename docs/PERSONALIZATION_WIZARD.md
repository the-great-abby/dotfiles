# Personalization Wizard - Quick Guide

## Overview

The Personalization Wizard helps you capture information about yourself so the AI can provide more personalized, context-aware assistance.

## Accessing the Wizard

### Via Main Wizard Menu

```bash
gtd-wizard
# Select: 67) 👤 Personalization Setup (help AI understand you)
```

### Direct Access

The wizard is also available as a standalone function (when sourced in the wizard context).

## What You Can Configure

The wizard guides you through 12 categories of personalization:

1. **👥 Relationships & Life Situation**
   - Partner/spouse information
   - Family members
   - Living arrangement
   - Timezone
   - Life phase

2. **🎯 Goals, Values & Priorities**
   - Career goals
   - Personal goals
   - Financial goals
   - Core values

3. **⚡ Work Patterns & Energy Management**
   - Peak productivity hours
   - Energy rechargers
   - Typical work schedule
   - Focus duration

4. **💚 Health & Wellness**
   - Sleep needs
   - Exercise patterns
   - Wellness tracking

5. **💬 Communication Preferences**
   - Preferred tone (direct, supportive, casual, formal)
   - Detail level (concise, moderate, detailed)
   - Feedback style

6. **📚 Learning Style & Knowledge**
   - Currently learning topics
   - Tools/technologies you use
   - Learning preferences

7. **🤔 Decision-Making & Problem-Solving**
   - Decision style (analytical, intuitive, collaborative)
   - Problem-solving approach

8. **😰 Stress & Coping Mechanisms**
   - Effective coping strategies
   - What helps you manage stress

9. **🎨 Interests & Personal Life**
   - Hobbies
   - Creative pursuits
   - Personal projects

10. **💼 Professional Context**
    - Role/title
    - Industry
    - Career stage
    - Key responsibilities

11. **🛠️ Tools & Systems**
    - Tools you're learning
    - Preferred editors
    - Workflow preferences

12. **📖 Lessons Learned**
    - What has worked well
    - What hasn't worked
    - Patterns you've noticed

## Using the Wizard

### Step-by-Step Process

1. **Start the wizard**: Select option 67 from the main wizard menu
2. **Choose a category**: Select which area you want to configure (1-12)
3. **Enter information**: Follow the prompts to enter your information
4. **Skip sections**: Press Enter with empty input to skip any field
5. **View your data**: Select option 13 to see what you've entered
6. **Update anytime**: Come back to any section to update your information

### Tips

- **Start small**: You don't need to fill everything at once. Start with the most important categories.
- **Be specific**: The more specific you are, the better the AI can help you.
- **Update regularly**: Your goals, focus, and patterns change - update your personalization accordingly.
- **Privacy**: All data is stored locally in `~/.gtd_personalization.json` - nothing is shared externally.

## Data Storage

### Location

All personalization data is stored in:
```
~/.gtd_personalization.json
```

### Format

The data is stored as JSON with the following structure:

```json
{
  "created": "2025-01-19T12:00:00",
  "last_updated": "2025-01-19T12:30:00",
  "relationships": { ... },
  "goals": { ... },
  "energy_patterns": { ... },
  ...
}
```

### Privacy

- ✅ All data stored locally on your machine
- ✅ No external sharing or syncing
- ✅ You control what information to share
- ✅ You can reset or delete anytime

## Viewing Your Data

### Via Wizard

```bash
gtd-wizard
# Select: 67) Personalization Setup
# Then: 13) View Current Personalization
```

### Direct File Access

```bash
cat ~/.gtd_personalization.json | python3 -m json.tool
```

## Resetting Personalization

If you want to start fresh:

```bash
gtd-wizard
# Select: 67) Personalization Setup
# Then: 14) Reset Personalization (start fresh)
```

Or manually:

```bash
rm ~/.gtd_personalization.json
```

## Integration with AI

Once you've set up personalization, the AI will use this information to:

- **Understand context**: Know who "Louiza" is, what your goals are, etc.
- **Provide relevant suggestions**: Align suggestions with your actual priorities
- **Match your style**: Communicate in your preferred tone and detail level
- **Respect your patterns**: Suggest tasks at optimal times based on your energy patterns
- **Learn from your experience**: Reference what has/hasn't worked for you

## Example Workflow

1. **Initial Setup** (5-10 minutes):
   ```
   gtd-wizard → 67 → 1 (Relationships)
   - Enter partner name: Louiza
   - Enter timezone: America/Los_Angeles
   
   gtd-wizard → 67 → 2 (Goals)
   - Enter career goal: Learn Kubernetes
   - Enter career goal: Pass CKA exam
   - Enter value: Continuous learning
   ```

2. **Regular Updates** (as needed):
   ```
   gtd-wizard → 67 → 2 (Goals)
   - Update goals as they change
   ```

3. **View Your Data**:
   ```
   gtd-wizard → 67 → 13 (View)
   ```

## Next Steps

After setting up personalization:

1. **Use the system normally** - The AI will start using your personalization data
2. **Refine over time** - Add more details as you think of them
3. **Update regularly** - Keep goals and focus areas current
4. **Provide feedback** - Let the AI know when suggestions are helpful or not

## Troubleshooting

### Wizard not appearing in menu

Make sure the file is executable:
```bash
chmod +x ~/code/dotfiles/bin/gtd-wizard-personalization.sh
```

### Data not saving

Check file permissions:
```bash
ls -la ~/.gtd_personalization.json
```

### Want to edit manually

You can edit the JSON file directly:
```bash
$EDITOR ~/.gtd_personalization.json
```

Make sure the JSON is valid before saving.

## Related Documentation

- [Personalization Capabilities](./PERSONALIZATION_CAPABILITIES.md) - Detailed guide on what information is helpful
- [Learning System Preferences](./LEARNING_SYSTEM_PREFERENCES.md) - How the system learns from your behavior
