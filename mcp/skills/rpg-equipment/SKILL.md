---
name: RPG Equipment System
description: Manage your RPG equipment inventory! Equip items that provide bonuses to XP, attributes, HP, MP, and more. Unlock powerful equipment by completing achievements and quests.
version: 1.0.0
tags:
  - gamification
  - rpg
  - equipment
  - inventory
  - items
  - bonuses
author: GTD System
tool:
  type: object
  properties:
    action:
      type: string
      enum: [view, equip, unequip, inventory, available, full]
      description: Action to perform - view (current equipment), equip (equip an item), unequip (remove item), inventory (all items), available (unlockable items), full (complete equipment view)
    item:
      type: string
      description: Item ID or name (required for equip/unequip actions)
    slot:
      type: string
      enum: [weapon, armor, accessory, consumable]
      description: Equipment slot type (optional filter)
  required: []
---

# RPG Equipment System

Manage your RPG equipment to boost your productivity! Equip items that provide bonuses to XP gains, attributes, HP, MP, and more. Unlock powerful equipment by completing achievements, quests, and reaching milestones.

## When to Use

Use this skill when you want to:
- **View your current equipment** - See what items you have equipped and their bonuses
- **Equip new items** - Put on equipment you've unlocked
- **Manage inventory** - See all items you own (equipped and unequipped)
- **Discover unlockable items** - See what equipment you can earn
- **Optimize your build** - Choose equipment that matches your playstyle
- **Track item unlocks** - See progress toward unlocking new equipment

## How It Works

Equipment provides passive bonuses that enhance your productivity:
- **XP Bonuses**: Increase XP gained from specific activities
- **Attribute Bonuses**: Boost Strength, Wisdom, Dexterity, or Constitution
- **HP/MP Bonuses**: Increase daily HP or MP regeneration
- **Special Effects**: Unique bonuses like streak protection, bonus quest XP, etc.

### Equipment Slots

You can equip items in different slots:

1. **Weapon** (1 slot): Boosts task completion and XP from tasks
2. **Armor** (1 slot): Boosts reviews, reflection, and MP
3. **Accessory** (2 slots): Various bonuses (XP, attributes, special effects)
4. **Consumables** (unlimited, one-time use): Temporary bonuses

### Equipment Rarity

Items come in different rarities with different power levels:
- **Common** (Gray): Small bonuses (+5% XP, +1 attribute)
- **Uncommon** (Green): Moderate bonuses (+10% XP, +2 attributes)
- **Rare** (Blue): Good bonuses (+15% XP, +3 attributes, special effects)
- **Epic** (Purple): Great bonuses (+20% XP, +5 attributes, strong effects)
- **Legendary** (Gold): Massive bonuses (+25% XP, +7 attributes, unique effects)

## Equipment List

### Weapons

**Productivity Sword** (Common)
- Unlock: Complete 10 tasks
- Bonus: +5% XP from tasks
- Slot: Weapon

**Taskmaster Blade** (Uncommon)
- Unlock: Complete 50 tasks
- Bonus: +10% XP from tasks, +1 Strength
- Slot: Weapon

**Executioner's Axe** (Rare)
- Unlock: Complete 100 tasks
- Bonus: +15% XP from tasks, +2 Strength, +5% bonus XP on task completion streaks
- Slot: Weapon

**Legendary Task Blade** (Epic)
- Unlock: Complete 500 tasks
- Bonus: +20% XP from tasks, +3 Strength, +10% bonus XP on streaks
- Slot: Weapon

**Master's Sword of Productivity** (Legendary)
- Unlock: Complete 1000 tasks
- Bonus: +25% XP from tasks, +5 Strength, +15% bonus XP on streaks, +1 HP per task completed
- Slot: Weapon

### Armor

**Wisdom Robe** (Common)
- Unlock: Complete 5 reviews
- Bonus: +5% XP from reviews
- Slot: Armor

**Reflection Mantle** (Uncommon)
- Unlock: Complete 10 reviews
- Bonus: +10% XP from reviews, +1 Wisdom, +2 MP per day
- Slot: Armor

**Sage's Cloak** (Rare)
- Unlock: Complete 25 reviews
- Bonus: +15% XP from reviews, +2 Wisdom, +5 MP per day, +10% bonus XP on review streaks
- Slot: Armor

**Archmage's Robes** (Epic)
- Unlock: Complete 50 reviews
- Bonus: +20% XP from reviews, +3 Wisdom, +10 MP per day, +15% bonus XP on streaks
- Slot: Armor

**Grandmaster's Vestments** (Legendary)
- Unlock: Complete 100 reviews
- Bonus: +25% XP from reviews, +5 Wisdom, +15 MP per day, +20% bonus XP on streaks, +1 MP per review completed
- Slot: Armor

### Accessories

**Stamina Boots** (Common)
- Unlock: 7-day daily logging streak
- Bonus: +5 HP per day
- Slot: Accessory

**Focus Ring** (Common)
- Unlock: 7-day task completion streak
- Bonus: +5 MP per day
- Slot: Accessory

**Habit Band** (Uncommon)
- Unlock: 30-day habit streak
- Bonus: +1 Dexterity, +10% XP from habits
- Slot: Accessory

**Consistency Amulet** (Rare)
- Unlock: 100-day daily logging streak
- Bonus: +2 Constitution, +15 HP per day, streak protection (one free miss per month)
- Slot: Accessory

**Productivity Gauntlets** (Rare)
- Unlock: Complete 5 projects
- Bonus: +2 Strength, +10% XP from projects
- Slot: Accessory

**Questmaster's Badge** (Epic)
- Unlock: Complete 50 quests
- Bonus: +20% bonus XP from quest completion, +3 to all attributes
- Slot: Accessory

**Champion's Crown** (Legendary)
- Unlock: Reach Level 25
- Bonus: +5 to all attributes, +25% XP from all sources, +20 HP/MP per day
- Slot: Accessory

### Consumables

**XP Potion** (Common)
- Unlock: Complete daily quest
- Bonus: +50 XP (one-time use)
- Slot: Consumable

**Energy Elixir** (Uncommon)
- Unlock: Complete weekly quest
- Bonus: +100 XP, +10 HP/MP (one-time use)
- Slot: Consumable

**Power Boost** (Rare)
- Unlock: Complete monthly quest
- Bonus: +250 XP, +20 HP/MP, +5% XP bonus for 7 days (one-time use)
- Slot: Consumable

## Usage

### View Current Equipment

**Action:** `action="view"` or `action="full"`

**What it shows:**
- Currently equipped items in each slot
- Active bonuses from equipment
- Total bonus calculations
- Equipment stats and descriptions

**MCP Tools to use:**
1. Read equipment data from gamification file
2. Calculate active bonuses
3. Display formatted equipment view

**Display format:**
```
╔════════════════════════════════════════════════╗
║         ⚔️  EQUIPPED ITEMS ⚔️                 ║
╠════════════════════════════════════════════════╣
║ WEAPON:                                        ║
║   ⚔️  Taskmaster Blade (Uncommon)              ║
║   +10% XP from tasks, +1 Strength             ║
╠════════════════════════════════════════════════╣
║ ARMOR:                                         ║
║   🛡️  Reflection Mantle (Uncommon)            ║
║   +10% XP from reviews, +1 Wisdom, +2 MP/day ║
╠════════════════════════════════════════════════╣
║ ACCESSORIES:                                   ║
║   👢 Stamina Boots (Common)                    ║
║   +5 HP per day                                ║
║   💍 Focus Ring (Common)                       ║
║   +5 MP per day                                ║
╠════════════════════════════════════════════════╣
║ ACTIVE BONUSES:                                ║
║   • +10% XP from tasks                         ║
║   • +10% XP from reviews                       ║
║   • +1 Strength, +1 Wisdom                     ║
║   • +7 HP/day, +7 MP/day                       ║
╚════════════════════════════════════════════════╝
```

### Equip an Item

**Action:** `action="equip"` with `item="<item_id>"`

**What it does:**
- Checks if item is unlocked
- Checks if slot is available
- Equips the item (replaces existing if slot full)
- Updates equipment data
- Shows confirmation with new bonuses

**MCP Tools to use:**
1. Check item unlock status (from achievements/badges/stats)
2. Check current equipment
3. Update equipment data
4. Calculate new bonuses

### View Inventory

**Action:** `action="inventory"`

**What it shows:**
- All items you own (equipped and unequipped)
- Item status (equipped/unequipped)
- Item descriptions and bonuses
- Item rarity and unlock requirements

### View Available Items

**Action:** `action="available"`

**What it shows:**
- All unlockable items
- Your progress toward unlocking each item
- Requirements for each item
- Items you can unlock soon

**MCP Tools to use:**
1. Read stats from gamification data
2. Compare against item unlock requirements
3. Calculate progress percentages
4. Display items sorted by unlockability

## Step-by-Step Workflow

### To View Equipment

1. **Load Equipment Data**
   - Read equipment data from gamification file (or initialize if missing)
   - Get currently equipped items

2. **Calculate Bonuses**
   - Sum XP bonuses from all equipped items
   - Sum attribute bonuses
   - Sum HP/MP bonuses
   - Apply special effects

3. **Display Equipment**
   - Show items by slot (weapon, armor, accessories)
   - Show active bonuses
   - Show item descriptions and rarity

### To Equip an Item

1. **Check Item Availability**
   - Verify item is unlocked (check achievements/stats)
   - Check if item exists in inventory

2. **Check Slot Availability**
   - For weapon/armor: Check if slot is empty (or ask to replace)
   - For accessories: Check if less than 2 equipped
   - For consumables: Always allow (unlimited)

3. **Equip Item**
   - Add to equipment data
   - Remove from inventory if needed
   - If replacing, move old item back to inventory

4. **Recalculate Bonuses**
   - Update total bonuses
   - Show confirmation with new bonuses

### To Check Unlock Progress

1. **Get Current Stats**
   - Read gamification data (stats, achievements, streaks)
   - Get current level, tasks completed, reviews completed, etc.

2. **Compare Against Requirements**
   - For each item, check unlock requirements
   - Calculate progress (e.g., "45/50 tasks completed")
   - Determine unlock status

3. **Display Available Items**
   - Show unlocked items (can equip)
   - Show items close to unlock (highlight)
   - Show locked items (with requirements)

## Integration with MCP Tools

This skill uses these MCP tools:

- Gamification system - Get stats, achievements, streaks for unlock checking
- Equipment data storage - Store equipped items and inventory
- Task system - For task-based unlock requirements
- Review system - For review-based unlock requirements
- Streak system - For streak-based unlock requirements

## Equipment Data Structure

Equipment data is stored in the gamification file:

```json
{
  "equipment": {
    "equipped": {
      "weapon": "taskmaster_blade",
      "armor": "reflection_mantle",
      "accessories": ["stamina_boots", "focus_ring"]
    },
    "inventory": {
      "productivity_sword": {
        "unlocked": true,
        "unlocked_date": "2026-01-15",
        "equipped": false
      },
      "taskmaster_blade": {
        "unlocked": true,
        "unlocked_date": "2026-01-18",
        "equipped": true,
        "equipped_date": "2026-01-18"
      }
    }
  }
}
```

## Best Practices

### Equipment Selection

- **Match your playstyle**: If you focus on tasks, equip task-focused items
- **Balance bonuses**: Don't just stack one type - balance XP, attributes, HP/MP
- **Consider special effects**: Some items have unique bonuses
- **Upgrade path**: Work toward better items as you progress

### Unlocking Items

- **Focus on achievements**: Many items unlock from achievements
- **Maintain streaks**: Streak-based items require consistency
- **Complete quests**: Quest completion unlocks consumables
- **Level up**: Some items require reaching certain levels

### Managing Inventory

- **Keep backups**: Don't sell/discard items - you might want them later
- **Try different builds**: Experiment with different equipment combinations
- **Track unlocks**: Know what you're close to unlocking

## Example Interactions

### "Show me my equipment"
→ Displays: Current equipment, active bonuses, item descriptions

### "Equip the Taskmaster Blade"
→ Checks unlock status, equips item, shows new bonuses

### "What items can I unlock?"
→ Displays: Available items with progress toward unlock

### "Show me my inventory"
→ Displays: All owned items (equipped and unequipped)

### "What's the best equipment for task completion?"
→ Suggests: Task-focused weapons and accessories

## Future Enhancements

### Item Upgrading
- Upgrade items using materials/XP
- Enhance existing items to higher rarities
- Add enchantments to items

### Set Bonuses
- Equip multiple items from same "set" for bonus
- Example: "Productivity Set" (sword + boots + ring) = +5% all XP

### Item Trading/Crafting
- Combine items to create new ones
- Trade items (if multi-user system)
- Craft consumables from materials

### Item Durability
- Items degrade with use (optional)
- Repair items with resources
- Add risk/reward element

## Troubleshooting

### "Item not found"
- Check item ID/name spelling
- Verify item exists in equipment definitions
- Check if item is unlocked

### "Can't equip item"
- Check if slot is full (weapon/armor = 1, accessories = 2)
- Verify item is unlocked
- Check item slot type matches

### "Bonuses not applying"
- Verify equipment data is saved correctly
- Check bonus calculation logic
- Ensure gamification system reads equipment data

## Success Metrics

A successful equipment session means:
- ✓ You can see your current equipment and bonuses
- ✓ You understand how to unlock new items
- ✓ You can equip/unequip items easily
- ✓ You know which items work best for your playstyle
- ✓ Equipment bonuses are being applied correctly

Remember: Equipment is meant to enhance your productivity journey, not replace good habits. Use it as motivation and reward for your achievements!
