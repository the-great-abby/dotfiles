# RPG Character Skill

Transform your GTD productivity into an epic RPG adventure! View your character stats, level, XP, quests, and achievements in a fun, game-like format.

## Quick Start

### From Wizard
The skill is automatically available in the wizard's skill menu. Select it to view your character!

### From Command Line
```bash
# View full character sheet
python3 mcp/skills/rpg-character/scripts/display_character.py full

# View stats only
python3 mcp/skills/rpg-character/scripts/display_character.py stats

# View quests
python3 mcp/skills/rpg-character/scripts/display_character.py quests

# View achievements
python3 mcp/skills/rpg-character/scripts/display_character.py achievements

# View level up guide
python3 mcp/skills/rpg-character/scripts/display_character.py levelup
```

### From MCP/Claude
```python
# Get skill instructions
get_agent_skill(skill_name="rpg-character")

# Execute skill
execute_agent_skill(
    skill_name="rpg-character",
    method="script:execute.sh",
    args={"action": "full"}
)
```

## Features

- **Character Stats**: Level, XP, HP, MP, and attributes (Strength, Wisdom, Dexterity, Constitution)
- **Quest System**: Daily, weekly, and monthly quests with XP rewards
- **Achievement Tracking**: View all earned badges and achievements
- **Level Up Guide**: See how to earn XP and level up
- **Streak Display**: View active streaks (daily logging, tasks, reviews, exercise)

## Character Attributes

- **Strength**: Based on tasks completed (task completion power)
- **Wisdom**: Based on reviews completed (review & reflection power)
- **Dexterity**: Based on habit and task streaks (habit consistency)
- **Constitution**: Based on daily logging streak (daily logging consistency)

## HP and MP

- **HP (Health Points)**: Based on consistency streaks (daily logging + task completion)
- **MP (Mana Points)**: Based on review completion (focus/mental energy)

## Integration

This skill integrates with:
- `gtd-gamify` - Gamification system for XP, level, badges
- Daily log system - For quest tracking
- Task system - For task completion tracking
- Habit system - For habit streak tracking
- Review system - For review completion tracking

## Requirements

- Gamification system initialized (`gtd-gamify` must be run at least once)
- Python 3.6+
- Access to gamification data file: `~/.gtd/gamification/gamification.json`

## Future Enhancements

- Character classes (Warrior, Mage, Rogue, Paladin)
- Equipment system with bonuses
- Prestige system for high levels
- More detailed quest progress tracking
- Integration with task/project system for real-time quest updates
