#!/usr/bin/env python3
"""
RPG Equipment Manager
Manages equipment inventory, equipping items, and displaying equipment bonuses.
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

# Get gamification file path
GTD_BASE_DIR = os.environ.get("GTD_BASE_DIR", os.path.expanduser("~/code/dotfiles"))
GAMIFICATION_FILE = os.path.join(GTD_BASE_DIR, ".gtd/gamification/gamification.json")

# Get action from environment or args
action = os.environ.get("SKILL_ARG_action", "view")
item = os.environ.get("SKILL_ARG_item", "")
slot = os.environ.get("SKILL_ARG_slot", "")

if len(sys.argv) > 1:
    action = sys.argv[1]
if len(sys.argv) > 2:
    item = sys.argv[2]

# Equipment definitions
EQUIPMENT_DEFINITIONS = {
    # Weapons
    "productivity_sword": {
        "name": "Productivity Sword",
        "rarity": "Common",
        "slot": "weapon",
        "unlock": {"tasks_completed": 10},
        "bonuses": {"task_xp_bonus": 0.05}
    },
    "taskmaster_blade": {
        "name": "Taskmaster Blade",
        "rarity": "Uncommon",
        "slot": "weapon",
        "unlock": {"tasks_completed": 50},
        "bonuses": {"task_xp_bonus": 0.10, "strength": 1}
    },
    "executioners_axe": {
        "name": "Executioner's Axe",
        "rarity": "Rare",
        "slot": "weapon",
        "unlock": {"tasks_completed": 100},
        "bonuses": {"task_xp_bonus": 0.15, "strength": 2}
    },
    "legendary_task_blade": {
        "name": "Legendary Task Blade",
        "rarity": "Epic",
        "slot": "weapon",
        "unlock": {"tasks_completed": 500},
        "bonuses": {"task_xp_bonus": 0.20, "strength": 3}
    },
    "masters_sword": {
        "name": "Master's Sword of Productivity",
        "rarity": "Legendary",
        "slot": "weapon",
        "unlock": {"tasks_completed": 1000},
        "bonuses": {"task_xp_bonus": 0.25, "strength": 5}
    },
    # Armor
    "wisdom_robe": {
        "name": "Wisdom Robe",
        "rarity": "Common",
        "slot": "armor",
        "unlock": {"reviews_completed": 5},
        "bonuses": {"review_xp_bonus": 0.05}
    },
    "reflection_mantle": {
        "name": "Reflection Mantle",
        "rarity": "Uncommon",
        "slot": "armor",
        "unlock": {"reviews_completed": 10},
        "bonuses": {"review_xp_bonus": 0.10, "wisdom": 1, "mp_per_day": 2}
    },
    "sages_cloak": {
        "name": "Sage's Cloak",
        "rarity": "Rare",
        "slot": "armor",
        "unlock": {"reviews_completed": 25},
        "bonuses": {"review_xp_bonus": 0.15, "wisdom": 2, "mp_per_day": 5}
    },
    "archmages_robes": {
        "name": "Archmage's Robes",
        "rarity": "Epic",
        "slot": "armor",
        "unlock": {"reviews_completed": 50},
        "bonuses": {"review_xp_bonus": 0.20, "wisdom": 3, "mp_per_day": 10}
    },
    "grandmasters_vestments": {
        "name": "Grandmaster's Vestments",
        "rarity": "Legendary",
        "slot": "armor",
        "unlock": {"reviews_completed": 100},
        "bonuses": {"review_xp_bonus": 0.25, "wisdom": 5, "mp_per_day": 15}
    },
    # Accessories
    "stamina_boots": {
        "name": "Stamina Boots",
        "rarity": "Common",
        "slot": "accessory",
        "unlock": {"daily_logging_streak": 7},
        "bonuses": {"hp_per_day": 5}
    },
    "focus_ring": {
        "name": "Focus Ring",
        "rarity": "Common",
        "slot": "accessory",
        "unlock": {"task_streak": 7},
        "bonuses": {"mp_per_day": 5}
    },
    "habit_band": {
        "name": "Habit Band",
        "rarity": "Uncommon",
        "slot": "accessory",
        "unlock": {"habit_streak": 30},
        "bonuses": {"dexterity": 1, "habit_xp_bonus": 0.10}
    },
    "consistency_amulet": {
        "name": "Consistency Amulet",
        "rarity": "Rare",
        "slot": "accessory",
        "unlock": {"daily_logging_streak": 100},
        "bonuses": {"constitution": 2, "hp_per_day": 15}
    },
    "productivity_gauntlets": {
        "name": "Productivity Gauntlets",
        "rarity": "Rare",
        "slot": "accessory",
        "unlock": {"projects_completed": 5},
        "bonuses": {"strength": 2, "project_xp_bonus": 0.10}
    },
    "questmasters_badge": {
        "name": "Questmaster's Badge",
        "rarity": "Epic",
        "slot": "accessory",
        "unlock": {"quests_completed": 50},
        "bonuses": {"quest_xp_bonus": 0.20, "strength": 3, "wisdom": 3, "dexterity": 3, "constitution": 3}
    },
    "champions_crown": {
        "name": "Champion's Crown",
        "rarity": "Legendary",
        "slot": "accessory",
        "unlock": {"level": 25},
        "bonuses": {"all_xp_bonus": 0.25, "strength": 5, "wisdom": 5, "dexterity": 5, "constitution": 5, "hp_per_day": 20, "mp_per_day": 20}
    }
}

def load_gamification_data():
    """Load gamification data from JSON file."""
    if not os.path.exists(GAMIFICATION_FILE):
        return None
    
    try:
        with open(GAMIFICATION_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading gamification data: {e}", file=sys.stderr)
        return None

def check_item_unlocked(item_id, data):
    """Check if an item is unlocked based on requirements."""
    if item_id not in EQUIPMENT_DEFINITIONS:
        return False, "Item not found"
    
    item_def = EQUIPMENT_DEFINITIONS[item_id]
    unlock_req = item_def.get("unlock", {})
    
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    level = data.get("level", 1)
    
    # Check each requirement
    for req_key, req_value in unlock_req.items():
        if req_key == "level":
            if level < req_value:
                return False, f"Requires level {req_value} (current: {level})"
        elif req_key in stats:
            if stats[req_key] < req_value:
                return False, f"Requires {req_key.replace('_', ' ')}: {req_value} (current: {stats[req_key]})"
        elif req_key in streaks:
            if streaks[req_key] < req_value:
                return False, f"Requires {req_key.replace('_', ' ')} streak: {req_value} (current: {streaks[req_key]})"
        else:
            # Unknown requirement
            return False, f"Unknown requirement: {req_key}"
    
    return True, "Unlocked"

def get_equipment_data(data):
    """Get or initialize equipment data."""
    if "equipment" not in data:
        data["equipment"] = {
            "equipped": {
                "weapon": None,
                "armor": None,
                "accessories": []
            },
            "inventory": {}
        }
    return data["equipment"]

def calculate_bonuses(equipped_items):
    """Calculate total bonuses from equipped items."""
    bonuses = {
        "task_xp_bonus": 0.0,
        "review_xp_bonus": 0.0,
        "habit_xp_bonus": 0.0,
        "project_xp_bonus": 0.0,
        "quest_xp_bonus": 0.0,
        "all_xp_bonus": 0.0,
        "strength": 0,
        "wisdom": 0,
        "dexterity": 0,
        "constitution": 0,
        "hp_per_day": 0,
        "mp_per_day": 0
    }
    
    for item_id in equipped_items:
        if item_id and item_id in EQUIPMENT_DEFINITIONS:
            item_bonuses = EQUIPMENT_DEFINITIONS[item_id].get("bonuses", {})
            for bonus_key, bonus_value in item_bonuses.items():
                if bonus_key in bonuses:
                    if isinstance(bonus_value, (int, float)):
                        bonuses[bonus_key] += bonus_value
    
    return bonuses

def display_equipment(data):
    """Display current equipment."""
    equipment = get_equipment_data(data)
    equipped = equipment.get("equipped", {})
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║         ⚔️  EQUIPPED ITEMS ⚔️                           ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Weapon
    weapon_id = equipped.get("weapon")
    if weapon_id and weapon_id in EQUIPMENT_DEFINITIONS:
        weapon = EQUIPMENT_DEFINITIONS[weapon_id]
        rarity_emoji = {"Common": "⚪", "Uncommon": "🟢", "Rare": "🔵", "Epic": "🟣", "Legendary": "🟡"}
        print(f"║ WEAPON:                                                    ║")
        print(f"║   ⚔️  {weapon['name']} ({weapon['rarity']}) {rarity_emoji.get(weapon['rarity'], '')}  ║")
        bonuses_str = format_bonuses(weapon.get("bonuses", {}))
        if bonuses_str:
            print(f"║   {bonuses_str:<55} ║")
    else:
        print("║ WEAPON: (Empty)                                            ║")
    
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Armor
    armor_id = equipped.get("armor")
    if armor_id and armor_id in EQUIPMENT_DEFINITIONS:
        armor = EQUIPMENT_DEFINITIONS[armor_id]
        rarity_emoji = {"Common": "⚪", "Uncommon": "🟢", "Rare": "🔵", "Epic": "🟣", "Legendary": "🟡"}
        print(f"║ ARMOR:                                                     ║")
        print(f"║   🛡️  {armor['name']} ({armor['rarity']}) {rarity_emoji.get(armor['rarity'], '')}  ║")
        bonuses_str = format_bonuses(armor.get("bonuses", {}))
        if bonuses_str:
            print(f"║   {bonuses_str:<55} ║")
    else:
        print("║ ARMOR: (Empty)                                             ║")
    
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Accessories
    accessories = equipped.get("accessories", [])
    print("║ ACCESSORIES:                                                ║")
    if accessories:
        for acc_id in accessories:
            if acc_id in EQUIPMENT_DEFINITIONS:
                acc = EQUIPMENT_DEFINITIONS[acc_id]
                rarity_emoji = {"Common": "⚪", "Uncommon": "🟢", "Rare": "🔵", "Epic": "🟣", "Legendary": "🟡"}
                print(f"║   💍 {acc['name']} ({acc['rarity']}) {rarity_emoji.get(acc['rarity'], '')}  ║")
                bonuses_str = format_bonuses(acc.get("bonuses", {}))
                if bonuses_str:
                    print(f"║      {bonuses_str:<53} ║")
    else:
        print("║   (Empty - can equip up to 2 accessories)                ║")
    
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Active bonuses
    all_equipped = [weapon_id, armor_id] + accessories
    all_equipped = [x for x in all_equipped if x]
    total_bonuses = calculate_bonuses(all_equipped)
    
    print("║ ACTIVE BONUSES:                                             ║")
    if total_bonuses["task_xp_bonus"] > 0:
        print(f"║   • +{int(total_bonuses['task_xp_bonus']*100)}% XP from tasks                        ║")
    if total_bonuses["review_xp_bonus"] > 0:
        print(f"║   • +{int(total_bonuses['review_xp_bonus']*100)}% XP from reviews                     ║")
    if total_bonuses["all_xp_bonus"] > 0:
        print(f"║   • +{int(total_bonuses['all_xp_bonus']*100)}% XP from all sources                    ║")
    
    attr_bonuses = []
    if total_bonuses["strength"] > 0:
        attr_bonuses.append(f"+{total_bonuses['strength']} Strength")
    if total_bonuses["wisdom"] > 0:
        attr_bonuses.append(f"+{total_bonuses['wisdom']} Wisdom")
    if total_bonuses["dexterity"] > 0:
        attr_bonuses.append(f"+{total_bonuses['dexterity']} Dexterity")
    if total_bonuses["constitution"] > 0:
        attr_bonuses.append(f"+{total_bonuses['constitution']} Constitution")
    
    if attr_bonuses:
        print(f"║   • {', '.join(attr_bonuses):<50} ║")
    
    if total_bonuses["hp_per_day"] > 0 or total_bonuses["mp_per_day"] > 0:
        hp_mp = []
        if total_bonuses["hp_per_day"] > 0:
            hp_mp.append(f"+{total_bonuses['hp_per_day']} HP/day")
        if total_bonuses["mp_per_day"] > 0:
            hp_mp.append(f"+{total_bonuses['mp_per_day']} MP/day")
        print(f"║   • {', '.join(hp_mp):<50} ║")
    
    if not any(total_bonuses.values()):
        print("║   (No active bonuses - equip items to gain bonuses!)      ║")
    
    print("╚════════════════════════════════════════════════════════════╝")

def format_bonuses(bonuses):
    """Format bonuses as a string."""
    parts = []
    if bonuses.get("task_xp_bonus"):
        parts.append(f"+{int(bonuses['task_xp_bonus']*100)}% task XP")
    if bonuses.get("review_xp_bonus"):
        parts.append(f"+{int(bonuses['review_xp_bonus']*100)}% review XP")
    if bonuses.get("strength"):
        parts.append(f"+{bonuses['strength']} Str")
    if bonuses.get("wisdom"):
        parts.append(f"+{bonuses['wisdom']} Wis")
    if bonuses.get("hp_per_day"):
        parts.append(f"+{bonuses['hp_per_day']} HP/day")
    if bonuses.get("mp_per_day"):
        parts.append(f"+{bonuses['mp_per_day']} MP/day")
    return ", ".join(parts)

def display_available_items(data):
    """Display items that can be unlocked."""
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    level = data.get("level", 1)
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║         📦 AVAILABLE ITEMS 📦                              ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    unlocked_items = []
    close_items = []
    locked_items = []
    
    for item_id, item_def in EQUIPMENT_DEFINITIONS.items():
        is_unlocked, reason = check_item_unlocked(item_id, data)
        if is_unlocked:
            unlocked_items.append((item_id, item_def))
        else:
            # Check if close to unlock
            unlock_req = item_def.get("unlock", {})
            close = False
            for req_key, req_value in unlock_req.items():
                if req_key == "level" and level >= req_value * 0.8:
                    close = True
                elif req_key in stats and stats[req_key] >= req_value * 0.8:
                    close = True
                elif req_key in streaks and streaks[req_key] >= req_value * 0.8:
                    close = True
            
            if close:
                close_items.append((item_id, item_def, reason))
            else:
                locked_items.append((item_id, item_def, reason))
    
    # Show unlocked items
    if unlocked_items:
        print("║ ✅ UNLOCKED (Can Equip):                                   ║")
        for item_id, item_def in unlocked_items[:10]:  # Show first 10
            rarity_emoji = {"Common": "⚪", "Uncommon": "🟢", "Rare": "🔵", "Epic": "🟣", "Legendary": "🟡"}
            print(f"║   {rarity_emoji.get(item_def['rarity'], '')} {item_def['name']:<45} ║")
        if len(unlocked_items) > 10:
            print(f"║   ... and {len(unlocked_items) - 10} more unlocked items!            ║")
        print("╠════════════════════════════════════════════════════════════╣")
    
    # Show close items
    if close_items:
        print("║ 🔜 CLOSE TO UNLOCK:                                        ║")
        for item_id, item_def, reason in close_items[:5]:  # Show first 5
            rarity_emoji = {"Common": "⚪", "Uncommon": "🟢", "Rare": "🔵", "Epic": "🟣", "Legendary": "🟡"}
            print(f"║   {rarity_emoji.get(item_def['rarity'], '')} {item_def['name']:<40} ║")
            print(f"║      {reason:<53} ║")
        print("╠════════════════════════════════════════════════════════════╣")
    
    # Show locked items (summary)
    if locked_items:
        print(f"║ 🔒 LOCKED: {len(locked_items)} items available to unlock              ║")
        print("║   (Complete achievements, maintain streaks, level up!)     ║")
    
    print("╚════════════════════════════════════════════════════════════╝")

def main():
    """Main function."""
    data = load_gamification_data()
    
    if data is None:
        print("❌ Error: Could not load gamification data.")
        print(f"   Make sure {GAMIFICATION_FILE} exists.")
        print("   Run 'gtd-gamify' to initialize the gamification system.")
        sys.exit(1)
    
    # Route to appropriate function
    if action in ["view", "full"]:
        display_equipment(data)
    elif action == "available":
        display_available_items(data)
    elif action == "equip":
        if not item:
            print("❌ Error: Item ID required for equip action")
            print("   Usage: equip <item_id>")
            sys.exit(1)
        print(f"⚠️  Equip functionality not yet implemented")
        print(f"   Would equip: {item}")
        # TODO: Implement equip logic
    elif action == "inventory":
        print("⚠️  Inventory view not yet implemented")
        # TODO: Implement inventory view
    else:
        print(f"Unknown action: {action}")
        print("Available actions: view, equip, unequip, inventory, available, full")
        sys.exit(1)

if __name__ == "__main__":
    main()
