# Pathfinder Adventures: Important Information to Track

## 🎲 Overview

Tracking information in Pathfinder adventures is crucial for continuity, character development, and enjoying the game. This guide covers what to remember and how to organize it in your Second Brain.

## 📋 Essential Information to Track

### 1. **Character Information**
**Critical Details:**
- Character name, class, level, race
- Ability scores (STR, DEX, CON, INT, WIS, CHA)
- Hit points (current/max)
- Armor Class (AC)
- Saving throws
- Skills and proficiencies
- Spells known/prepared (if applicable)
- Equipment and inventory
- Gold and wealth
- Experience points (XP)

**Why it matters:**
- Quick reference during sessions
- Track character growth
- Remember what you can do
- Plan character development

**How to track:**
```bash
# Create character note in Second Brain
gtd-brain create "My Pathfinder Character - [Name]" Resources

# Or use template
gtd-brain-template create "Character Sheet" "My Character" Resources
```

### 2. **Campaign & Adventure Notes**
**Critical Details:**
- Adventure name and module
- Current location
- Party members and their roles
- Session dates and summaries
- Major plot points
- Completed quests/objectives
- Active quests/objectives
- Timeline of events

**Why it matters:**
- Remember what happened last session
- Track story continuity
- Understand plot threads
- Plan next actions

**How to track:**
```bash
# Create campaign note
gtd-brain create "Pathfinder Campaign - [Campaign Name]" Resources

# Create session notes
gtd-brain create "Session 1 - [Date]" Resources
gtd-brain create "Session 2 - [Date]" Resources
```

### 3. **NPCs (Non-Player Characters)**
**Critical Details:**
- Name and description
- Role/occupation
- Location
- Relationship to party
- Important information they know
- Quests/objectives they gave
- Personality traits
- Secrets or hidden information

**Why it matters:**
- Remember who you've met
- Track relationships
- Remember quest givers
- Recall important conversations

**How to track:**
```bash
# Create NPC note
gtd-brain create "NPC - [Name]" Resources

# Link to campaign note
gtd-brain link "NPC - [Name]" "Pathfinder Campaign - [Name]"
```

### 4. **Locations & World Building**
**Critical Details:**
- Location names
- Description and atmosphere
- Important features
- NPCs found there
- Items/treasure found
- Secrets or hidden areas
- Travel routes
- Map references

**Why it matters:**
- Navigate the world
- Remember where things are
- Track exploration
- Plan travel routes

**How to track:**
```bash
# Create location note
gtd-brain create "Location - [Name]" Resources

# Link locations
gtd-brain-connect create "Location - Town" "Location - Dungeon"
```

### 5. **Quests & Objectives**
**Critical Details:**
- Quest name and description
- Quest giver (NPC)
- Objectives/steps
- Rewards (XP, gold, items)
- Status (active, completed, failed)
- Deadlines or time constraints
- Related NPCs or locations

**Why it matters:**
- Track what you're working on
- Remember quest rewards
- Prioritize objectives
- Complete quests

**How to track:**
```bash
# Create quest note
gtd-brain create "Quest - [Name]" Resources

# Or track as GTD project
gtd-project create "Pathfinder Quest: [Name]" --area="hobbies"
```

### 6. **Combat & Encounters**
**Critical Details:**
- Enemy names and types
- AC, HP, attacks, abilities
- Tactics used
- Damage dealt/taken
- Special abilities or weaknesses
- Loot obtained
- XP gained

**Why it matters:**
- Learn enemy patterns
- Track combat effectiveness
- Remember loot
- Plan future encounters

**How to track:**
```bash
# Create encounter note
gtd-brain create "Encounter - [Location/Date]" Resources

# Track in session notes
addInfoToDailyLog "Pathfinder: Defeated goblin ambush, gained 200 XP (Hobbies)"
```

### 7. **Loot & Items**
**Critical Details:**
- Item name and description
- Where it was found
- Who has it (if party item)
- Value (gold)
- Special properties
- How it's used
- Quest items vs. regular items

**Why it matters:**
- Remember what you have
- Track party inventory
- Know item values
- Use items effectively

**How to track:**
```bash
# Create inventory note
gtd-brain create "Character Inventory - [Name]" Resources

# Track valuable items
gtd-brain create "Magic Item - [Name]" Resources
```

### 8. **Rules & Mechanics**
**Critical Details:**
- Frequently used rules
- Class abilities
- Spell descriptions
- Combat rules
- Skill check DCs
- House rules (if any)
- Quick reference tables

**Why it matters:**
- Quick rule lookups
- Understand mechanics
- Make informed decisions
- Speed up gameplay

**How to track:**
```bash
# Create rules reference
gtd-brain create "Pathfinder Rules Reference" Resources

# Create spell/ability notes
gtd-brain create "Spell - [Name]" Resources
```

### 9. **Party Information**
**Critical Details:**
- Party member names and classes
- Their roles and specialties
- Relationships between characters
- Shared resources
- Party goals
- Group decisions made

**Why it matters:**
- Coordinate with party
- Remember party dynamics
- Track group resources
- Plan group actions

**How to track:**
```bash
# Create party note
gtd-brain create "Party - [Campaign Name]" Resources

# Link character notes
gtd-brain-connect create "My Character" "Party - [Campaign]"
```

### 10. **Plot Threads & Mysteries**
**Critical Details:**
- Unanswered questions
- Clues discovered
- Mysteries to solve
- Plot threads to follow
- Foreshadowing noticed
- Theories and speculation

**Why it matters:**
- Track story mysteries
- Remember clues
- Follow plot threads
- Solve puzzles

**How to track:**
```bash
# Create mystery/plot thread note
gtd-brain create "Mystery - [Name]" Resources

# Use divergence thinking for theories
gtd-brain-diverge "Who is the mysterious figure?"
```

## 🗺️ Organizing Pathfinder Information

### MOC Structure

Create a MOC for your Pathfinder campaign:

```bash
gtd-brain-moc create "Pathfinder Campaign"
```

**MOC Sections:**
- Characters (PCs and NPCs)
- Locations
- Quests
- Items & Loot
- Rules Reference
- Session Notes
- Plot Threads

### PARA Method Organization

**Projects:**
- Active quests
- Character development goals
- Campaign objectives

**Areas:**
- Hobbies (Pathfinder as ongoing hobby)
- Gaming (if you play multiple games)

**Resources:**
- Character sheets
- Campaign notes
- NPCs
- Locations
- Rules reference
- Session notes

**Archives:**
- Completed campaigns
- Old characters
- Finished quests

## 📝 Session Note Template

Create a template for session notes:

```markdown
# Session [Number] - [Date]

## Summary
Brief overview of what happened.

## Location
Where the session took place.

## NPCs Encountered
- [Name] - [Description/Notes]

## Quests
- [Quest Name] - [Progress/Status]

## Combat
- [Encounter Description]
- XP Gained: [Amount]
- Loot Obtained: [Items]

## Important Information
Key plot points, clues, or discoveries.

## Next Session
What to remember for next time.

## Links
- [[Campaign - [Name]]]
- [[Character - [Name]]]
- [[Quest - [Name]]]
```

## 🎯 Quick Reference Checklist

### Before Each Session:
- [ ] Review last session notes
- [ ] Check character sheet (HP, spells, etc.)
- [ ] Review active quests
- [ ] Check inventory
- [ ] Review party status

### During Session:
- [ ] Take notes on important NPCs
- [ ] Track combat encounters
- [ ] Record loot obtained
- [ ] Note plot developments
- [ ] Mark quest progress

### After Session:
- [ ] Update character sheet
- [ ] Write session summary
- [ ] Update quest status
- [ ] Add new NPCs/locations
- [ ] Link related notes
- [ ] Update campaign timeline

## 💡 Pro Tips

### 1. **Use Tags**
Tag your Pathfinder notes:
- `#pathfinder`
- `#rpg`
- `#campaign-[name]`
- `#character-[name]`
- `#session-[number]`

### 2. **Link Everything**
Create connections:
- Characters → Campaigns
- Quests → NPCs
- Locations → Encounters
- Items → Characters

### 3. **Regular Updates**
- Update character sheet after each session
- Write session notes within 24 hours
- Update quest status regularly
- Review and organize monthly

### 4. **Use Templates**
Create templates for:
- Character sheets
- Session notes
- NPC profiles
- Quest tracking
- Location descriptions

### 5. **Track in Daily Logs**
Quick notes in daily logs:
```bash
addInfoToDailyLog "Pathfinder session: Defeated boss, gained level 5 (Hobbies)"
```

## 🚀 Quick Start Setup

### 1. Create Campaign Structure
```bash
# Create main campaign note
gtd-brain create "Pathfinder Campaign - [Name]" Resources

# Create MOC
gtd-brain-moc create "Pathfinder Campaign"

# Create character note
gtd-brain create "My Character - [Name]" Resources
```

### 2. Set Up Templates
```bash
# Create session note template
gtd-brain-template create "Session Notes" "Session 1" Resources

# Create NPC template
gtd-brain-template create "NPC Profile" "NPC Name" Resources
```

### 3. Track in GTD
```bash
# Create area for hobbies
gtd-area create "Hobbies"

# Create project for active quest
gtd-project create "Pathfinder Quest: [Name]" --area="hobbies"
```

### 4. Link Everything
```bash
# Link character to campaign
gtd-brain-connect create "My Character" "Pathfinder Campaign"

# Add to MOC
gtd-brain-moc add "Pathfinder Campaign" "My Character"
```

## 📊 Information Priority

### Must Remember (Critical):
1. Character stats and abilities
2. Active quests and objectives
3. Important NPCs and their information
4. Current location and travel plans
5. Party composition and roles

### Should Remember (Important):
6. Session summaries
7. Loot and inventory
8. Plot threads and mysteries
9. Rules and mechanics
10. Campaign timeline

### Nice to Remember (Helpful):
11. World building details
12. Character backstories
13. Past encounters
14. Theories and speculation
15. House rules

## 🎲 Example Workflow

### Before Session:
```bash
# Review last session
gtd-brain view "Session 5 - [Date]"

# Check character
gtd-brain view "My Character - [Name]"

# Review active quests
gtd-brain search "quest active"
```

### During Session:
- Take quick notes
- Track combat
- Record NPCs
- Note loot

### After Session:
```bash
# Create session note
gtd-brain-template create "Session Notes" "Session 6" Resources

# Update character
gtd-brain update "My Character - [Name]"

# Update quests
gtd-brain update "Quest - [Name]"

# Link in MOC
gtd-brain-moc add "Pathfinder Campaign" "Session 6"
```

## 🎯 Next Steps

1. **Create your campaign structure:**
   ```bash
   gtd-brain create "Pathfinder Campaign - [Name]" Resources
   gtd-brain-moc create "Pathfinder Campaign"
   ```

2. **Set up character tracking:**
   ```bash
   gtd-brain create "My Character - [Name]" Resources
   ```

3. **Create templates:**
   - Session notes
   - NPC profiles
   - Quest tracking

4. **Start tracking:**
   - Take notes during sessions
   - Update after each session
   - Link everything together

Your Pathfinder adventure tracking system is ready! 🎲✨

