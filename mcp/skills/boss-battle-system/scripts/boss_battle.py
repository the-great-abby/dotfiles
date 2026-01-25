#!/usr/bin/env python3
"""
Boss Battle System - Transform difficult tasks into epic RPG boss fights
"""

import json
import os
import sys
import random
import hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any

# Add GTD functions to path
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))

def get_boss_data_dir() -> Path:
    """Get the directory for storing boss battle data."""
    data_dir = Path.home() / "Documents" / "gtd" / ".boss_battles"
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir

def generate_boss_id(task_description: str) -> str:
    """Generate a unique boss ID from task description."""
    # Create hash from description + timestamp for uniqueness
    content = f"{task_description}_{datetime.now().isoformat()}"
    return hashlib.md5(content.encode()).hexdigest()[:12]

def estimate_boss_hp(task_description: str) -> int:
    """Estimate boss HP based on task complexity."""
    desc_lower = task_description.lower()
    base_hp = 800
    
    # Add HP based on complexity indicators
    complexity_words = {
        'project': 400, 'report': 300, 'presentation': 500,
        'analysis': 200, 'research': 300, 'design': 250,
        'quarterly': 400, 'annual': 600, 'comprehensive': 300,
        'complete': 200, 'full': 150, 'entire': 200,
        'complex': 300, 'detailed': 200, 'thorough': 150,
        'multiple': 200, 'several': 150, 'many': 100
    }
    
    for word, hp_add in complexity_words.items():
        if word in desc_lower:
            base_hp += hp_add
    
    # Add HP based on description length (longer = more complex)
    base_hp += len(task_description) * 2
    
    # Random variation (±20%)
    variation = random.randint(-int(base_hp * 0.2), int(base_hp * 0.2))
    final_hp = max(500, base_hp + variation)  # Minimum 500 HP
    
    return final_hp

def determine_boss_type(task_description: str) -> Dict[str, Any]:
    """Determine boss type and characteristics based on task."""
    desc_lower = task_description.lower()
    
    # Boss type mapping
    if any(word in desc_lower for word in ['email', 'inbox', 'message', 'correspondence']):
        return {
            'name': 'Email Dragon',
            'type': 'Communication Beast',
            'emoji': '🐉📧',
            'weakness': 'Focused email processing sessions',
            'ability': 'Spam Breath - generates more emails during battle',
            'color': 'crimson'
        }
    elif any(word in desc_lower for word in ['spreadsheet', 'data', 'numbers', 'calculation', 'excel']):
        return {
            'name': 'Spreadsheet Demon', 
            'type': 'Ancient Data Demon',
            'emoji': '👹📊',
            'weakness': 'Methodical data entry and formula crafting',
            'ability': 'Corrupt Data - introduces calculation errors',
            'color': 'green'
        }
    elif any(word in desc_lower for word in ['presentation', 'slides', 'powerpoint', 'keynote']):
        return {
            'name': 'Presentation Hydra',
            'type': 'Multi-Headed Beast',
            'emoji': '🐲📋',
            'weakness': 'Focused slide creation sessions', 
            'ability': 'Scope Creep - grows new heads (requirements) mid-battle',
            'color': 'blue'
        }
    elif any(word in desc_lower for word in ['clean', 'organize', 'tidy', 'declutter']):
        return {
            'name': 'Cleaning Golem',
            'type': 'Chaos Construct', 
            'emoji': '🗿🏠',
            'weakness': 'Systematic cleaning and organization',
            'ability': 'Mess Multiplication - creates more mess while you clean',
            'color': 'brown'
        }
    elif any(word in desc_lower for word in ['tax', 'filing', 'irs', 'forms', 'deduction']):
        return {
            'name': 'Tax Demon',
            'type': 'Bureaucratic Nightmare',
            'emoji': '👺💰', 
            'weakness': 'Organized document gathering and careful form completion',
            'ability': 'Missing Document Curse - hides required paperwork',
            'color': 'red'
        }
    elif any(word in desc_lower for word in ['report', 'analysis', 'research', 'study']):
        return {
            'name': 'Report Wraith',
            'type': 'Knowledge Phantom',
            'emoji': '👻📄',
            'weakness': 'Systematic research and writing sessions',
            'ability': 'Writers Block Curse - slows progress randomly',
            'color': 'purple'
        }
    else:
        # Generic boss for unknown task types
        return {
            'name': 'Task Titan',
            'type': 'Generic Challenge Beast',
            'emoji': '🦾📋',
            'weakness': 'Focused work sessions and systematic approach',
            'ability': 'Procrastination Aura - reduces motivation over time',
            'color': 'gray'
        }

def get_boss_level(hp: int) -> int:
    """Calculate boss level based on HP."""
    if hp < 800:
        return random.randint(1, 5)
    elif hp < 1200:
        return random.randint(6, 10)
    elif hp < 1800:
        return random.randint(11, 15)
    elif hp < 2500:
        return random.randint(16, 20)
    else:
        return random.randint(21, 30)

def calculate_damage(work_minutes: int, boss_data: Dict[str, Any]) -> Tuple[int, bool]:
    """Calculate damage dealt based on work time and boss characteristics."""
    # Base damage: ~15 HP per minute of focused work
    base_damage = work_minutes * 15
    
    # Quality multiplier based on work session length
    if work_minutes >= 45:
        quality_multiplier = 1.5  # Long session bonus
    elif work_minutes >= 25:
        quality_multiplier = 1.2  # Pomodoro bonus
    elif work_minutes >= 15:
        quality_multiplier = 1.0  # Standard
    else:
        quality_multiplier = 0.8  # Short session penalty
    
    # Random variation (±25%)
    randomness = random.uniform(0.75, 1.25)
    
    # Calculate final damage
    final_damage = int(base_damage * quality_multiplier * randomness)
    
    # Critical hit chance (15% for excellent sessions)
    is_critical = random.random() < 0.15
    if is_critical:
        final_damage = int(final_damage * 1.8)
    
    return final_damage, is_critical

def get_random_persona_comment(event_type: str, boss_data: Dict[str, Any] = None, damage: int = 0) -> Dict[str, str]:
    """Get random comments from different personas for various battle events."""
    
    if event_type == "boss_creation":
        comments = {
            "questmaster": [
                f"⚔️ BOSS BATTLE DETECTED! A Level {boss_data.get('level', '?')} {boss_data.get('boss_type', {}).get('name', 'Beast')} has appeared! Gather your party!",
                f"🎮 LEGENDARY ENCOUNTER! This {boss_data.get('boss_type', {}).get('type', 'creature')} looks dangerous! Time to prove your heroic skills!",
                f"⚡ EPIC QUEST ACTIVATED! The {boss_data.get('boss_type', {}).get('name', 'monster')} threatens the realm! Victory will bring great rewards!"
            ],
            "chaos_gremlin": [
                f"OOH! BOSS FIGHT! {boss_data.get('boss_type', {}).get('emoji', '🎪')} PLOT TWIST - what if we defeat it by doing everything backwards?!",
                f"🎪 CHAOS TIME! Big scary {boss_data.get('boss_type', {}).get('name', 'monster')}! Let's confuse it with PURE CREATIVE ENERGY!",
                f"EXCITING! BOSS BATTLE! What if we defeat it while standing on one foot and singing?! MAXIMUM CHAOS STRATEGY!"
            ],
            "time_wizard": [
                f"🧙‍♂️ The timestreams reveal this beast's weakness - focused work incantations will deal massive damage!",
                f"⏰ Behold! The {boss_data.get('boss_type', {}).get('name', 'creature')} can be defeated through the ancient art of time management!",
                f"✨ I shall cast analysis spells... Yes! This foe falls to systematic 25-minute focus enchantments!"
            ],
            "hype_squad": [
                f"📣 LEGENDARY BOSS ENCOUNTER! YOU'VE GOT THIS, CHAMPION! TIME TO SHOW WHAT A REAL HERO LOOKS LIKE!",
                f"🏆 EPIC BATTLE INCOMING! YOU'RE ABOUT TO BECOME THE GREATEST {boss_data.get('boss_type', {}).get('name', 'MONSTER')} SLAYER OF ALL TIME!",
                f"🎉 MAXIMUM HYPE! THIS IS YOUR MOMENT TO SHINE! LEGENDARY WARRIOR PERFORMANCE INCOMING!"
            ]
        }
    
    elif event_type == "attack":
        comments = {
            "questmaster": [
                f"⚔️ Excellent strike! {damage} damage dealt! The monster staggers but remains dangerous!",
                f"🎯 Direct hit! Your focused attack deals {damage} HP damage! Keep up the assault!",
                f"⚡ Critical technique! {damage} damage! The beast feels your determination!"
            ],
            "zen_robot": [
                f"🤖 Combat analysis complete. {damage} HP damage achieved through sustained focus. Optimal performance detected.",
                f"⚙️ Processing battle data... Attack successful. {damage} damage dealt. Recommend maintaining current strategy.",
                f"🧘 Mindfulness protocol active. {damage} HP removed efficiently. System running at peak performance."
            ],
            "quartermaster": [
                f"⚓ Steady as she goes! {damage} damage to the beast! We're making fine progress, Captain!",
                f"🗡️ Good strike, Captain! {damage} HP dealt! The crew is impressed with your tactics!",
                f"⛵ Aye! Another solid hit for {damage} damage! We'll have this monster defeated soon enough!"
            ],
            "cozy_hobbit": [
                f"🏠 Well done, dear! {damage} damage! Even the mightiest foes fall to patient, steady work.",
                f"🫖 Lovely progress! {damage} HP! Remember, we can have a nice cup of tea after this battle.",
                f"🌱 Gentle but effective! {damage} damage dealt! Small, consistent efforts win the day."
            ]
        }
    
    elif event_type == "critical_hit":
        comments = {
            "chaos_gremlin": [
                f"🎪 CRITICAL HIT! {damage} DAMAGE! You found the boss's secret weakness - PURE CHAOS ENERGY!",
                f"✨ PLOT TWIST CRITICAL! {damage} HP! The monster never saw that coming! BRILLIANT!",
                f"🎭 MAXIMUM CHAOS CRITICAL! {damage} DAMAGE! Pure creative destruction! BEAUTIFUL!"
            ],
            "hype_squad": [
                f"📣 CRITICAL STRIKE! {damage} DAMAGE! MAXIMUM DEVASTATION! THE CROWD GOES WILD!",
                f"🏆 LEGENDARY CRITICAL HIT! {damage} HP! HALL OF FAME PERFORMANCE! ABSOLUTELY INCREDIBLE!",
                f"🎉 CRITICAL PERFECTION! {damage} DAMAGE! YOU'RE THE GREATEST WARRIOR OF ALL TIME!"
            ],
            "time_wizard": [
                f"🧙‍♂️ BEHOLD! Your Focus Spell achieved CRITICAL MAGNITUDE! {damage} damage to the beast!",
                f"⏰ TEMPORAL CRITICAL! {damage} HP! Your timing was absolutely perfect! Masterful!",
                f"✨ CRITICAL ENCHANTMENT! {damage} damage! The timestreams align in your favor!"
            ]
        }
        
    elif event_type == "victory":
        comments = {
            "questmaster": [
                "🎉 INCREDIBLE VICTORY! The beast lies defeated! Your mastery has reached legendary status!",
                "🏆 EPIC TRIUMPH! Another monster falls to your heroic efforts! The realm celebrates!",
                "⚔️ LEGENDARY CONQUEST! Your skills have proven superior! Victory is yours!"
            ],
            "hype_squad": [
                "📣 HALL OF FAME PERFORMANCE! GREATEST WARRIOR OF ALL TIME! THEY'LL SING SONGS ABOUT THIS!",
                "🎊 MAXIMUM VICTORY CELEBRATION! LEGENDARY CHAMPION STATUS ACHIEVED! THE CROWD GOES ABSOLUTELY WILD!",
                "🏆 ULTIMATE TRIUMPH! RECORD-BREAKING PERFORMANCE! YOU'RE THE PRODUCTIVITY SUPERHERO!"
            ],
            "quartermaster": [
                "⚓ Aye, Captain! A victory worthy of legend! The crew requests shore leave to celebrate!",
                "🗡️ Magnificent battle, Captain! The monster is defeated! Huzzah for our fearless leader!",
                "⛵ Splendid work! Another successful campaign! The crew is in high spirits!"
            ],
            "time_wizard": [
                "🧙‍♂️ Behold! Your mastery of focus has grown! The timestreams celebrate your victory!",
                "⏰ Magnificent! You've unlocked new temporal abilities through this triumph!",
                "✨ Victory! The ancient arts of productivity have blessed you with power!"
            ]
        }
    
    else:
        # Default comments
        comments = {
            "questmaster": ["🎮 Epic adventure continues!"],
            "chaos_gremlin": ["🎪 CHAOS AND FUN!"],
            "time_wizard": ["🧙‍♂️ Time magic flows!"],
            "hype_squad": ["📣 YOU'RE AMAZING!"]
        }
    
    # Randomly select personas and their comments
    selected_personas = random.sample(list(comments.keys()), min(2, len(comments)))
    result = {}
    
    for persona in selected_personas:
        result[persona] = random.choice(comments[persona])
    
    return result

def create_boss_battle(task_description: str) -> Dict[str, Any]:
    """Create a new boss battle from a task description."""
    boss_id = generate_boss_id(task_description)
    max_hp = estimate_boss_hp(task_description)
    boss_type = determine_boss_type(task_description)
    level = get_boss_level(max_hp)
    
    boss_data = {
        'boss_id': boss_id,
        'task_description': task_description,
        'boss_type': boss_type,
        'level': level,
        'max_hp': max_hp,
        'current_hp': max_hp,
        'created_at': datetime.now().isoformat(),
        'attacks': [],
        'status': 'active'
    }
    
    # Save boss data
    boss_file = get_boss_data_dir() / f"{boss_id}.json"
    with open(boss_file, 'w') as f:
        json.dump(boss_data, f, indent=2)
    
    return boss_data

def load_boss_battle(boss_id: str) -> Optional[Dict[str, Any]]:
    """Load boss battle data."""
    boss_file = get_boss_data_dir() / f"{boss_id}.json"
    if not boss_file.exists():
        return None
    
    with open(boss_file, 'r') as f:
        return json.load(f)

def save_boss_battle(boss_data: Dict[str, Any]) -> None:
    """Save boss battle data."""
    boss_file = get_boss_data_dir() / f"{boss_data['boss_id']}.json"
    with open(boss_file, 'w') as f:
        json.dump(boss_data, f, indent=2)

def format_hp_bar(current_hp: int, max_hp: int, width: int = 30) -> str:
    """Format HP bar with visual representation."""
    if max_hp == 0:
        percentage = 0
    else:
        percentage = current_hp / max_hp
    
    filled = int(percentage * width)
    empty = width - filled
    
    bar = "█" * filled + "░" * empty
    return f"{bar} {current_hp:,}/{max_hp:,}"

def display_boss_status(boss_data: Dict[str, Any]) -> str:
    """Display current boss status with ASCII art."""
    boss_type = boss_data['boss_type']
    hp_percentage = boss_data['current_hp'] / boss_data['max_hp']
    
    # Determine boss status
    if hp_percentage > 0.75:
        status = "💪 Full strength, very dangerous"
    elif hp_percentage > 0.5:
        status = "😤 Wounded but still fierce"
    elif hp_percentage > 0.25:
        status = "🩸 Badly injured, getting desperate"
    else:
        status = "💀 Near death, final stand"
    
    return f"""
{boss_type['emoji']} **{boss_type['name'].upper()}** (Level {boss_data['level']})
   HP: {format_hp_bar(boss_data['current_hp'], boss_data['max_hp'])} ({hp_percentage:.0%} remaining)
   Type: {boss_type['type']}
   Status: {status}
   Weakness: {boss_type['weakness']}
   Special Ability: {boss_type['ability']}
"""

def attack_boss(boss_id: str, work_minutes: int) -> Dict[str, Any]:
    """Attack a boss with a work session."""
    boss_data = load_boss_battle(boss_id)
    if not boss_data:
        return {'error': 'Boss battle not found'}
    
    if boss_data['status'] != 'active':
        return {'error': 'Boss battle is not active'}
    
    # Calculate damage
    damage, is_critical = calculate_damage(work_minutes, boss_data)
    
    # Apply damage
    boss_data['current_hp'] = max(0, boss_data['current_hp'] - damage)
    
    # Record attack
    attack_data = {
        'timestamp': datetime.now().isoformat(),
        'work_minutes': work_minutes,
        'damage': damage,
        'is_critical': is_critical,
        'hp_after': boss_data['current_hp']
    }
    boss_data['attacks'].append(attack_data)
    
    # Check if boss is defeated
    if boss_data['current_hp'] <= 0:
        boss_data['status'] = 'defeated'
        boss_data['defeated_at'] = datetime.now().isoformat()
    
    # Save updated boss data
    save_boss_battle(boss_data)
    
    return {
        'boss_data': boss_data,
        'attack': attack_data,
        'is_defeated': boss_data['current_hp'] <= 0
    }

def list_active_bosses() -> List[Dict[str, Any]]:
    """List all active boss battles."""
    boss_dir = get_boss_data_dir()
    active_bosses = []
    
    for boss_file in boss_dir.glob("*.json"):
        try:
            with open(boss_file, 'r') as f:
                boss_data = json.load(f)
            
            if boss_data.get('status') == 'active':
                active_bosses.append(boss_data)
        except (json.JSONDecodeError, KeyError):
            continue
    
    # Sort by creation date (newest first)
    active_bosses.sort(key=lambda x: x.get('created_at', ''), reverse=True)
    return active_bosses

def main():
    """Main CLI interface for boss battle system."""
    if len(sys.argv) < 2:
        print("Usage: python boss_battle.py <action> [arguments...]")
        print("Actions: create, attack, status, victory, list")
        return
    
    action = sys.argv[1]
    
    if action == "create":
        if len(sys.argv) < 3:
            print("Usage: python boss_battle.py create <task_description>")
            return
        
        task_description = " ".join(sys.argv[2:])
        boss_data = create_boss_battle(task_description)
        
        print("⚔️ BOSS BATTLE CREATED! ⚔️\n")
        print(display_boss_status(boss_data))
        
        # Get persona comments
        comments = get_random_persona_comment("boss_creation", boss_data)
        for persona, comment in comments.items():
            print(f"\n{comment}")
        
        print(f"\n📊 **Battle Plan:**")
        estimated_sessions = max(1, boss_data['max_hp'] // 300)
        print(f"   - Each focused work session deals ~300 HP damage")
        print(f"   - Estimated {estimated_sessions} work sessions to victory")
        print(f"   - Boss ID: {boss_data['boss_id']}")
        
    elif action == "attack":
        if len(sys.argv) < 4:
            print("Usage: python boss_battle.py attack <boss_id> <work_minutes>")
            return
        
        boss_id = sys.argv[2]
        work_minutes = int(sys.argv[3])
        
        result = attack_boss(boss_id, work_minutes)
        if 'error' in result:
            print(f"❌ Error: {result['error']}")
            return
        
        attack = result['attack']
        boss_data = result['boss_data']
        
        print("⚔️ ATTACK SUCCESSFUL! ⚔️\n")
        
        if attack['is_critical']:
            print(f"💥 **CRITICAL HIT!** 💥")
            comments = get_random_persona_comment("critical_hit", boss_data, attack['damage'])
        else:
            print(f"🗡️ **{work_minutes}-Minute Focus Strike**")
            comments = get_random_persona_comment("attack", boss_data, attack['damage'])
        
        print(f"   Damage Dealt: {attack['damage']:,} HP")
        print(display_boss_status(boss_data))
        
        # Show persona comments
        for persona, comment in comments.items():
            print(f"\n{comment}")
        
        if result['is_defeated']:
            print("\n" + "="*50)
            print("🎉🏆 BOSS DEFEATED! 🏆🎉")
            victory_comments = get_random_persona_comment("victory", boss_data)
            for persona, comment in victory_comments.items():
                print(f"\n{comment}")
    
    elif action == "status":
        if len(sys.argv) < 3:
            print("Usage: python boss_battle.py status <boss_id>")
            return
        
        boss_id = sys.argv[2]
        boss_data = load_boss_battle(boss_id)
        
        if not boss_data:
            print(f"❌ Boss battle {boss_id} not found")
            return
        
        print("📊 BOSS BATTLE STATUS 📊")
        print(display_boss_status(boss_data))
        
        if boss_data['attacks']:
            print(f"\n⚔️ **Battle History:** ({len(boss_data['attacks'])} attacks)")
            for i, attack in enumerate(boss_data['attacks'][-3:], 1):  # Show last 3 attacks
                crit_mark = " 💥 CRIT!" if attack['is_critical'] else ""
                print(f"   {i}. {attack['work_minutes']} min → {attack['damage']} HP{crit_mark}")
    
    elif action == "list":
        active_bosses = list_active_bosses()
        
        if not active_bosses:
            print("📋 No active boss battles found.")
            print("\n💡 Create a new boss battle with:")
            print("   python boss_battle.py create \"Your challenging task description\"")
            return
        
        print(f"⚔️ **ACTIVE BOSS BATTLES** ({len(active_bosses)}) ⚔️\n")
        
        for boss in active_bosses:
            boss_type = boss['boss_type']
            hp_percentage = boss['current_hp'] / boss['max_hp']
            
            print(f"{boss_type['emoji']} **{boss_type['name']}** (Level {boss['level']})")
            print(f"   Task: {boss['task_description'][:60]}...")
            print(f"   HP: {format_hp_bar(boss['current_hp'], boss['max_hp'], 20)} ({hp_percentage:.0%})")
            print(f"   ID: {boss['boss_id']}")
            print()
    
    else:
        print(f"❌ Unknown action: {action}")
        print("Available actions: create, attack, status, list")

if __name__ == "__main__":
    main()