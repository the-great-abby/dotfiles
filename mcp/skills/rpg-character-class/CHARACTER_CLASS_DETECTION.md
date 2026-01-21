# 🎭 Character Class Detection System

## Overview

Character class detection analyzes your GTD activity patterns to determine which RPG class best matches your playstyle. This adds personalization and makes the gamification system more engaging!

## How It Works

### Data Analysis

The system analyzes four key activity dimensions:

1. **Task Completion** (Execution/Strength)
   - Total tasks completed
   - Task completion rate
   - Task completion streaks
   - Priority distribution (high vs low priority tasks)

2. **Review Completion** (Reflection/Wisdom)
   - Total reviews completed
   - Review frequency (daily/weekly/monthly)
   - Review streaks
   - Review depth (time spent, thoroughness)

3. **Habit Consistency** (Routine/Dexterity)
   - Habit completion rate
   - Habit streaks
   - Number of active habits
   - Habit consistency over time

4. **Project Completion** (Goals/Constitution)
   - Total projects completed
   - Project completion rate
   - Project size distribution
   - Project duration patterns

### Class Calculation

For each dimension, calculate a normalized score (0-100):

```python
# Example calculation
task_score = (tasks_completed / max_tasks) * 100
review_score = (reviews_completed / max_reviews) * 100
habit_score = (habit_streak / max_habit_streak) * 100
project_score = (projects_completed / max_projects) * 100
```

Then determine dominant playstyle:

```python
# Find dominant dimension
scores = {
    "execution": task_score,
    "reflection": review_score,
    "routine": habit_score,
    "goals": project_score
}
dominant = max(scores, key=scores.get)
```

### Class Assignment Rules

#### Warrior (Execution-Focused)
**Requirements:**
- Task score > 60 AND task score > review_score + 20
- High task completion rate (>70%)
- Strong task streaks

**Characteristics:**
- High Strength attribute
- Bonus: +10% XP from tasks
- Special: "Execute" ability - Complete 3 tasks instantly (1/day)

**Playstyle:** Action-oriented, gets things done, focuses on execution

#### Mage (Reflection-Focused)
**Requirements:**
- Review score > 60 AND review_score > task_score + 20
- High review frequency (weekly or more)
- Strong review streaks

**Characteristics:**
- High Wisdom attribute
- Bonus: +10% XP from reviews
- Special: "Reflect" ability - Double XP from next review (1/week)

**Playstyle:** Thoughtful, reflective, focuses on understanding and planning

#### Rogue (Routine-Focused)
**Requirements:**
- Habit score > 60 AND habit_score > (task_score + review_score) / 2
- High habit consistency (>80%)
- Strong habit streaks (30+ days)

**Characteristics:**
- High Dexterity attribute
- Bonus: +10% XP from habits
- Special: "Stealth" ability - Maintain streak even if you miss one day (1/month)

**Playstyle:** Consistent, routine-focused, builds strong habits

#### Paladin (Balanced)
**Requirements:**
- All scores between 40-70 (balanced)
- OR no single score > 60
- Good performance across all dimensions

**Characteristics:**
- Balanced attributes (all moderate)
- Bonus: +5% XP from all sources
- Special: "Aura" ability - +10% XP for all activities for 1 day (1/week)

**Playstyle:** Well-rounded, balanced approach to productivity

#### Ranger (Goal-Focused)
**Requirements:**
- Project score > 60 AND project_score > task_score
- High project completion rate (>60%)
- Multiple active projects

**Characteristics:**
- High Constitution attribute
- Bonus: +10% XP from projects
- Special: "Track" ability - See all project tasks at once (1/day)

**Playstyle:** Goal-oriented, project-focused, long-term thinking

#### Bard (Creative-Focused)
**Requirements:**
- High "Express Phase" activity (creating from notes)
- High note creation/linking
- High creative project completion
- OR special creative achievements

**Characteristics:**
- Balanced attributes with Wisdom focus
- Bonus: +10% XP from creative activities
- Special: "Inspire" ability - Generate creative suggestions (1/day)

**Playstyle:** Creative, expressive, focuses on creation and expression

### Class Progression

Classes have progression levels:

1. **Apprentice** (Level 1-5)
   - Basic class bonuses
   - No special abilities yet

2. **Journeyman** (Level 6-15)
   - Enhanced bonuses (+15% instead of +10%)
   - Unlock first special ability

3. **Master** (Level 16-25)
   - Strong bonuses (+20%)
   - Unlock second special ability
   - Class-specific title

4. **Grandmaster** (Level 25+)
   - Maximum bonuses (+25%)
   - All special abilities
   - Prestige class options

### Class Re-evaluation

Your class can change as your playstyle evolves:

- **Automatic re-check**: Every 10 levels or monthly
- **Manual re-check**: On demand
- **Class history**: Track class changes over time
- **Multi-class**: Future feature - combine two classes

### Example Detection

```python
# User stats
tasks_completed = 150
reviews_completed = 25
habit_streak = 45
projects_completed = 8

# Normalized scores (assuming max values)
task_score = (150 / 500) * 100 = 30
review_score = (25 / 100) * 100 = 25
habit_score = (45 / 100) * 100 = 45
project_score = (8 / 50) * 100 = 16

# Analysis
- task_score (30) < 60 → Not Warrior
- review_score (25) < 60 → Not Mage
- habit_score (45) < 60 → Not Rogue
- All scores balanced → Paladin!

# Result: Paladin (Balanced)
```

### Class-Specific Recommendations

Each class gets personalized recommendations:

**Warrior:**
- "Focus on high-priority tasks today"
- "Complete 3 tasks to unlock daily quest"
- "Your task completion rate is 85% - excellent!"

**Mage:**
- "Time for your weekly review - gain wisdom!"
- "Reflect on last week's patterns"
- "Your review streak is 12 weeks - keep it up!"

**Rogue:**
- "Maintain your 45-day habit streak!"
- "Complete all daily habits for bonus XP"
- "Your consistency is legendary!"

**Paladin:**
- "Balance your activities across all areas"
- "Complete a task, do a review, maintain habits"
- "Your well-rounded approach is working!"

**Ranger:**
- "Focus on your active projects"
- "Complete a project milestone today"
- "Your project completion rate is 70%!"

**Bard:**
- "Create something from your notes today"
- "Express your ideas and insights"
- "Your creativity is inspiring!"

## Implementation

The class detection system:
1. Loads gamification stats
2. Calculates normalized scores for each dimension
3. Applies class assignment rules
4. Determines class and progression level
5. Provides class-specific bonuses and recommendations
6. Stores class history for tracking changes

## Future Enhancements

- **Multi-classing**: Combine two classes (e.g., Warrior-Mage)
- **Sub-classes**: Specializations within classes
- **Class quests**: Class-specific quest chains
- **Class equipment**: Equipment that synergizes with class
- **Class achievements**: Unlock class-specific achievements
- **Class leaderboards**: Compare with others of same class
