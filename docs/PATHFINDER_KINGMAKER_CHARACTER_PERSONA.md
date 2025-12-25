# Pathfinder Kingmaker Character Persona Setup Guide

## 🎲 Overview

This guide explains how to set up and use a character persona for your Pathfinder Kingmaker campaign. The persona allows you to ask your character how they would act in different situations, providing roleplay advice based on your character's personality, alignment, and background.

## ✅ What's Already Set Up

1. **Campaign Area**: Created `pathfinder-kingmaker` area in your GTD system
2. **Character Persona Template**: Added `kingmaker-char` persona (needs customization)
3. **Configuration Files**: Updated both `.gtd_config_ai` and `gtd_persona_helper.py`

## 📝 Step 1: Customize Your Character Persona

You need to replace the placeholders in the persona configuration with your actual character details.

### Option A: Edit `.gtd_config_ai` (Shell Config)

Edit `/Users/abby/code/dotfiles/zsh/.gtd_config_ai` and find the line starting with `"kingmaker-char|`. Replace the placeholders:

```bash
# Find this line (around line 90):
"kingmaker-char|You are [CHARACTER_NAME], a [CLASS] [RACE] from the Pathfinder Kingmaker campaign..."

# Replace with your character details, for example:
"kingmaker-char|You are Lyra Moonwhisper, a Rogue Halfling from the Pathfinder Kingmaker campaign. Your alignment is Chaotic Good. You're quick-witted, curious, and have a mischievous streak, but you have a strong moral compass and care deeply about your friends. You grew up as a street urchin in Restov, learning to survive through wit and agility. You speak in character, using phrases like 'Well, that's interesting...', 'I've got a plan', and 'Trust me on this one.' When asked how you would act in a situation, respond as this character would - considering your alignment, personality, background, class abilities, and the context of the Kingmaker campaign. Think about what motivates you, what you value, and how your past experiences shape your decisions. Be true to the character while providing helpful roleplay advice. Consider the political, social, and combat aspects of situations in the Stolen Lands. Help the player understand how you would react, what you would say, and what actions you would take based on your character's nature.|pathfinder_roleplay|0.8"
```

### Option B: Edit `gtd_persona_helper.py` (Python Config)

Edit `/Users/abby/code/dotfiles/zsh/functions/gtd_persona_helper.py` and find the `"kingmaker-char"` entry (around line 320). Replace the placeholders in the `system_prompt`:

```python
"kingmaker-char": {
    "name": "Lyra Moonwhisper",  # Replace [CHARACTER_NAME]
    "system_prompt": "You are Lyra Moonwhisper, a Rogue Halfling from the Pathfinder Kingmaker campaign. Your alignment is Chaotic Good. You're quick-witted, curious, and have a mischievous streak, but you have a strong moral compass and care deeply about your friends. You grew up as a street urchin in Restov, learning to survive through wit and agility. You speak in character, using phrases like 'Well, that's interesting...', 'I've got a plan', and 'Trust me on this one.' When asked how you would act in a situation, respond as this character would - considering your alignment, personality, background, class abilities, and the context of the Kingmaker campaign. Think about what motivates you, what you value, and how your past experiences shape your decisions. Be true to the character while providing helpful roleplay advice. Consider the political, social, and combat aspects of situations in the Stolen Lands. Help the player understand how you would react, what you would say, and what actions you would take based on your character's nature.",
    "expertise": "pathfinder_roleplay",
    "temperature": 0.8
}
```

### What to Replace

- `[CHARACTER_NAME]`: Your character's name (e.g., "Lyra Moonwhisper")
- `[CLASS]`: Your character's class (e.g., "Rogue", "Fighter", "Wizard")
- `[RACE]`: Your character's race (e.g., "Halfling", "Human", "Elf")
- `[ALIGNMENT]`: Your character's alignment (e.g., "Chaotic Good", "Lawful Neutral")
- `[PERSONALITY_TRAITS]`: Describe your character's personality (e.g., "You're quick-witted, curious, and have a mischievous streak, but you have a strong moral compass")
- `[BACKSTORY]`: Brief summary of your character's background (e.g., "You grew up as a street urchin in Restov, learning to survive through wit and agility")
- `[CATCHPHRASES]`: Examples of how your character speaks (e.g., "'Well, that's interesting...', 'I've got a plan', 'Trust me on this one'")

## 🎯 Step 2: Using Your Character Persona

Once you've customized the persona, you can ask your character for advice:

### 🎯 Recommended Method: Background Processing (Includes Session Notes!)

**Use `--background` to queue requests that automatically include context from your session notes and campaign MOC:**

```bash
# Ask your character with full campaign context (includes session notes!)
gtd-advise --background kingmaker-char "How would you react if we encountered bandits on the road?"

# Ask about dialogue (includes relevant session notes)
gtd-advise --background kingmaker-char "What would you say to the mayor when asking for help?"

# Ask about decision-making (includes campaign context from MOC)
gtd-advise --background kingmaker-char "The party is split on whether to help the kobolds or fight them. What would you do?"
```

**Why use `--background`?**
- ✅ **Includes session notes** - Automatically pulls in relevant Pathfinder Kingmaker session notes
- ✅ **Includes MOC context** - Gets information from your Pathfinder Kingmaker MOC
- ✅ **No hanging** - Processes in background, you get notified when done
- ✅ **Full context** - Your character can reference past sessions and campaign details
- ✅ **Vector search** - Searches your knowledge base for relevant information

**View results:**
```bash
# Check results via wizard
gtd-wizard → 11) Get Advice → 6) Review Background Advice Results

# Or check directly (find the latest result)
ls -t ~/Documents/gtd/advice_results/*_answer.txt | head -1 | xargs cat
```

### Quick Method (No Context)

For quick questions without session note context, use the wrapper:

```bash
# Fast response, no context gathering
gtd-kingmaker-advise "How would you react if we encountered bandits on the road?"
```

### Alternative: Immediate Processing

You can also process immediately (may hang if context gathering is slow):

```bash
# Process immediately (may hang)
gtd-advise kingmaker-char "How would you react if we encountered bandits on the road?"
```

**Note:** The persona name is a positional argument, not a flag. Use `gtd-advise kingmaker-char "question"` not `gtd-advise --persona=kingmaker-char "question"`.

### Example Questions

- **Combat Situations**: "How would you approach this combat encounter?"
- **Social Interactions**: "What would you say to convince the merchant to lower his prices?"
- **Moral Dilemmas**: "The party found stolen goods. What would you do with them?"
- **Political Decisions**: "The baron is asking us to take sides in a dispute. How would you respond?"
- **Exploration**: "We found a mysterious door. How would you investigate it?"

## 📚 Step 3: Organizing Your Campaign Notes

### Session Notes

Create session notes in your Second Brain:

```bash
# Create a session note
gtd-brain create "Session 1 - 2025-12-22" Resources

# Or use the wizard
gtd-wizard
# Then navigate to Second Brain → Create Note
```

### Character Notes

Create detailed character notes:

```bash
# Create character sheet note
gtd-brain create "Character - [Your Character Name]" Resources

# Link to campaign
gtd-brain-connect create "Character - [Name]" "Pathfinder Campaign - Kingmaker"
```

### Campaign Structure

Organize your campaign using the area:

```bash
# View your campaign area
gtd-area view pathfinder-kingmaker

# Add projects for quests
gtd-area add-project pathfinder-kingmaker "Quest: Clear the Stag Lord's Fort"

# Add tasks
gtd-area add-task pathfinder-kingmaker "Update character sheet after session"
```

## 🔧 Troubleshooting

### Persona Not Found

If you get an error that the persona isn't found:

1. **Check both config files**: Make sure you updated BOTH `.gtd_config_ai` AND `gtd_persona_helper.py`
2. **Restart your shell**: Close and reopen your terminal to reload config
3. **Check persona name**: Use `kingmaker-char` (or whatever you named it)

### Persona Not Acting Like Your Character

If the persona doesn't match your character:

1. **Review the system prompt**: Make sure you included all important personality traits
2. **Add more detail**: Include specific examples of how your character has acted in the past
3. **Adjust temperature**: Higher temperature (0.9) = more creative/varied, Lower (0.6) = more consistent
4. **Add context**: When asking questions, provide context about the situation

### Want Multiple Characters?

You can create multiple character personas! Just add more entries:

```bash
# In .gtd_config_ai, add:
"kingmaker-char2|You are [SECOND_CHARACTER_NAME]..." 

# In gtd_persona_helper.py, add:
"kingmaker-char2": {
    "name": "[SECOND_CHARACTER_NAME]",
    ...
}
```

## 💡 Tips for Better Roleplay Advice

1. **Be Specific**: Include details about your character's past experiences, relationships, and motivations
2. **Include Alignment**: Alignment significantly affects decision-making
3. **Add Class Abilities**: Mention how your class abilities might influence decisions
4. **Campaign Context**: Reference specific events from your Kingmaker campaign
5. **Party Dynamics**: Consider how your character interacts with party members

## 📖 Example: Complete Character Setup

Here's a complete example for a character named "Thorin Ironforge":

### In `.gtd_config_ai`:
```
"kingmaker-char|You are Thorin Ironforge, a Fighter Dwarf from the Pathfinder Kingmaker campaign. Your alignment is Lawful Good. You're honorable, stubborn, and value tradition and duty above all else. You have a deep respect for craftsmanship and a strong sense of justice. You grew up in a dwarven stronghold, trained as a warrior from a young age, and left to seek glory and protect the innocent. You speak in character, using phrases like 'By my beard!', 'That's not how we do things', 'Honor demands...', and 'Aye, I'll stand with you.' When asked how you would act in a situation, respond as this character would - considering your alignment, personality, background, class abilities, and the context of the Kingmaker campaign. Think about what motivates you, what you value, and how your past experiences shape your decisions. Be true to the character while providing helpful roleplay advice. Consider the political, social, and combat aspects of situations in the Stolen Lands. Help the player understand how you would react, what you would say, and what actions you would take based on your character's nature.|pathfinder_roleplay|0.8"
```

### Usage:
```bash
# With session note context (recommended)
gtd-advise --background kingmaker-char "We found a group of bandits. How would you approach this?"

# Quick response without context
gtd-kingmaker-advise "We found a group of bandits. How would you approach this?"
```

## 🎮 Next Steps

1. ✅ Customize the character persona with your character's details
2. ✅ Test it with a few questions
3. ✅ Create your character notes in Second Brain
4. ✅ Start tracking session notes
5. ✅ Use the persona during sessions for roleplay inspiration!

Enjoy your Pathfinder Kingmaker campaign! 🎲✨

