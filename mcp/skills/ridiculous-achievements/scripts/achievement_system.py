#!/usr/bin/env python3
"""
Ridiculous Achievements System - Epic celebrations for mundane tasks
"""

import json
import os
import sys
import random
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

def get_achievements_data_dir() -> Path:
    """Get directory for storing achievement data."""
    data_dir = Path.home() / "Documents" / "gtd" / ".achievements"
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir

def load_user_achievements() -> Dict[str, Any]:
    """Load user's earned achievements."""
    achievements_file = get_achievements_data_dir() / "earned_achievements.json"
    
    if not achievements_file.exists():
        return {"earned": [], "progress": {}, "unlocked_on": {}}
    
    try:
        with open(achievements_file, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return {"earned": [], "progress": {}, "unlocked_on": {}}

def save_user_achievements(achievements_data: Dict[str, Any]) -> None:
    """Save user's achievement data."""
    achievements_file = get_achievements_data_dir() / "earned_achievements.json"
    with open(achievements_file, 'w') as f:
        json.dump(achievements_data, f, indent=2)

# Master achievements database with ridiculous names and celebrations
ACHIEVEMENTS_DATABASE = {
    # Email & Communication Mastery
    "email_destroyer": {
        "name": "🏆 EMAIL DESTROYER SUPREME",
        "description": "BEHOLD! The Email Apocalypse has been VANQUISHED! No message dares remain unread!",
        "trigger": {"type": "inbox_zero", "count": 5},
        "rewards": {"xp": 1000, "title": "Email Overlord", "power": "Perfect Inbox Organization"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "lightning_responder": {
        "name": "⚡ LIGHTNING RESPONDER",
        "description": "MAGNIFICENT! Your fingers move like lightning across the keyboard! Communication at the speed of light!",
        "trigger": {"type": "emails_answered", "count": 20, "time_limit": 600},  # 20 emails in 10 minutes
        "rewards": {"xp": 500, "title": "Speed Communicator", "power": "Email Velocity Boost"},
        "rarity": "rare",
        "celebration_level": "standard"
    },
    
    "sacred_inbox_master": {
        "name": "🏛️ MASTER OF THE SACRED INBOX",
        "description": "LEGENDARY STATUS ACHIEVED! You have ascended to the highest realm of inbox enlightenment!",
        "trigger": {"type": "inbox_zero_streak", "days": 7},
        "rewards": {"xp": 2000, "title": "Inbox Deity", "power": "Permanent Email Clarity"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    "diplomatic_genius": {
        "name": "🎭 DIPLOMATIC GENIUS SUPREME",
        "description": "SUPREME DIPLOMAT! Nations would envy your conflict resolution mastery!",
        "trigger": {"type": "difficult_emails_resolved", "count": 3},
        "rewards": {"xp": 750, "title": "Communication Sage", "power": "Conflict Resolution Aura"},
        "rarity": "rare",
        "celebration_level": "standard"
    },
    
    # Task Completion Glory
    "task_annihilator": {
        "name": "⚔️ TASK ANNIHILATOR SUPREME",
        "description": "LEGENDARY WARRIOR! You have ANNIHILATED the forces of procrastination with ruthless efficiency!",
        "trigger": {"type": "tasks_completed", "count": 50, "timeframe": "week"},
        "rewards": {"xp": 1500, "title": "Productivity Destroyer", "power": "Task Completion Velocity"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "laser_focus_champion": {
        "name": "🎯 LASER FOCUS CHAMPION",
        "description": "FOCUS OF THE GODS! Your concentration powers have reached mythical proportions!",
        "trigger": {"type": "tasks_without_distraction", "count": 10},
        "rewards": {"xp": 800, "title": "Focus Master", "power": "Distraction Immunity"},
        "rarity": "rare",
        "celebration_level": "standard"
    },
    
    "dawn_warrior": {
        "name": "🌅 DAWN WARRIOR SUPREME",
        "description": "RISE OF THE DAWN WARRIOR! You conquer dragons before others even wake!",
        "trigger": {"type": "hardest_task_first", "count": 5},
        "rewards": {"xp": 1000, "title": "Morning Destroyer", "power": "Dawn Energy Boost"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "productivity_phoenix": {
        "name": "🔥 PRODUCTIVITY PHOENIX",
        "description": "FROM THE ASHES OF PROCRASTINATION, YOU RISE! The Phoenix of Productivity soars!",
        "trigger": {"type": "overdue_task_completed", "age_days": 14},
        "rewards": {"xp": 1200, "title": "Phoenix of Tasks", "power": "Procrastination Resistance"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "diamond_finisher": {
        "name": "💎 DIAMOND FINISHER",
        "description": "DIAMOND-TIER EXECUTION! Your task completion skills sparkle with flawless brilliance!",
        "trigger": {"type": "perfect_tasks_completed", "count": 100},
        "rewards": {"xp": 2500, "title": "Perfection Incarnate", "power": "Flawless Execution Aura"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    # Organization Supremacy
    "castle_keeper": {
        "name": "🏰 CASTLE KEEPER SUPREME",
        "description": "MASTER OF THE REALM! Your domain has been transformed into a fortress of efficiency!",
        "trigger": {"type": "workspace_organized", "quality": "perfect"},
        "rewards": {"xp": 800, "title": "Organization Overlord", "power": "Spatial Mastery"},
        "rarity": "rare",
        "celebration_level": "standard"
    },
    
    "marie_kondo_sensei": {
        "name": "✨ MARIE KONDO SENSEI",
        "description": "JOY MASTER SUPREME! You have achieved enlightenment in the ancient art of spark detection!",
        "trigger": {"type": "spark_joy_applied", "count": 100},
        "rewards": {"xp": 1500, "title": "Joy Detection Master", "power": "Instant Joy Recognition"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "declutter_wizard": {
        "name": "🧙‍♂️ DECLUTTER WIZARD",
        "description": "WIZARDRY MOST MAGNIFICENT! You have banished clutter to the shadow realm!",
        "trigger": {"type": "items_decluttered", "count": 50, "session": True},
        "rewards": {"xp": 1000, "title": "Clutter Banisher", "power": "Instant Organization Vision"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    # Time Management Mastery
    "time_bending_sorcerer": {
        "name": "⚡ TIME BENDING SORCERER",
        "description": "MASTER OF THE TIME STREAMS! You have bent reality to your productive will!",
        "trigger": {"type": "perfect_time_blocking", "days": 7},
        "rewards": {"xp": 1800, "title": "Temporal Lord", "power": "Time Manipulation Mastery"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    "pomodoro_perfectionist": {
        "name": "🎯 POMODORO PERFECTIONIST",
        "description": "TEMPORAL MASTERY ACHIEVED! You have unlocked the secrets of focused time manipulation!",
        "trigger": {"type": "perfect_pomodoros", "count": 25},
        "rewards": {"xp": 1200, "title": "Focus Time Master", "power": "Enhanced Concentration"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "deadline_destroyer": {
        "name": "⏰ DEADLINE DESTROYER",
        "description": "DEADLINE DEMOLISHER SUPREME! No deadline dares challenge your temporal dominance!",
        "trigger": {"type": "deadlines_met", "count": 30, "consecutive": True},
        "rewards": {"xp": 2000, "title": "Time Lord", "power": "Deadline Immunity"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    # Focus & Deep Work
    "zen_focus_master": {
        "name": "🧘‍♂️ ZEN FOCUS MASTER",
        "description": "ENLIGHTENMENT ACHIEVED! Your mind has transcended mortal distraction limitations!",
        "trigger": {"type": "deep_work_session", "hours": 3, "no_distractions": True},
        "rewards": {"xp": 1500, "title": "Focus Deity", "power": "Supernatural Concentration"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "distraction_destroyer": {
        "name": "🚫 DISTRACTION DESTROYER",
        "description": "IMMUNITY TO CHAOS! Distractions bounce off your adamantium concentration!",
        "trigger": {"type": "distractions_resisted", "count": 20, "session": True},
        "rewards": {"xp": 800, "title": "Anti-Distraction Shield", "power": "Distraction Repelling Field"},
        "rarity": "rare",
        "celebration_level": "standard"
    },
    
    "digital_monk": {
        "name": "📱 DIGITAL MONK",
        "description": "DIGITAL ASCENSION! You have achieved smartphone enlightenment beyond mortal comprehension!",
        "trigger": {"type": "no_phone_checking", "hours": 4},
        "rewards": {"xp": 1000, "title": "Phone Freedom Master", "power": "Digital Detox Aura"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    # Boss Battle & Challenge
    "dragon_slayer": {
        "name": "🐉 DRAGON SLAYER SUPREME",
        "description": "LEGENDARY DRAGON SLAYER! Bards will sing of your epic victories for generations!",
        "trigger": {"type": "boss_battles_won", "count": 5},
        "rewards": {"xp": 2500, "title": "Monster Vanquisher", "power": "Boss Battle Mastery"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    "challenge_champion": {
        "name": "⚔️ CHALLENGE CHAMPION",
        "description": "CHALLENGE ANNIHILATOR! No quest is too daunting, no challenge too chaotic!",
        "trigger": {"type": "daily_challenges_completed", "count": 10},
        "rewards": {"xp": 1200, "title": "Quest Destroyer", "power": "Challenge Immunity"},
        "rarity": "legendary",
        "celebration_level": "epic"
    },
    
    "chaos_tamer": {
        "name": "💪 CHAOS TAMER",
        "description": "CHAOS WHISPERER! You have tamed the untameable and brought order to the storm!",
        "trigger": {"type": "challenge_during_stress", "stress_level": "high"},
        "rewards": {"xp": 1500, "title": "Storm Master", "power": "Stress Immunity"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    # Streak & Consistency
    "unstoppable_force": {
        "name": "🔥 UNSTOPPABLE FORCE",
        "description": "FORCE OF NATURE! Nothing can stop your relentless march toward productivity perfection!",
        "trigger": {"type": "task_streak", "days": 30},
        "rewards": {"xp": 3000, "title": "Consistency Incarnate", "power": "Momentum Field"},
        "rarity": "mythical",
        "celebration_level": "epic"
    },
    
    "diamond_dedication": {
        "name": "💎 DIAMOND DEDICATION",
        "description": "DIAMOND WILL! Your consistency has crystallized into unbreakable determination!",
        "trigger": {"type": "habit_streak", "days": 90},
        "rewards": {"xp": 5000, "title": "Willpower Deity", "power": "Unbreakable Habits"},
        "rarity": "legendary_mythical",
        "celebration_level": "epic"
    },
    
    # Spectacular Failures (Fun achievements for trying)
    "spectacular_disaster": {
        "name": "🎪 SPECTACULAR DISASTER ARTIST",
        "description": "FAILURE OF LEGENDARY PROPORTIONS! Your ambition reaches heights worthy of myth!",
        "trigger": {"type": "ambitious_failure", "scope": "extreme"},
        "rewards": {"xp": 500, "title": "Beautiful Failure Master", "power": "Fearless Ambition"},
        "rarity": "rare",
        "celebration_level": "standard"
    },
    
    "glorious_explosion": {
        "name": "🌋 GLORIOUS EXPLOSION",
        "description": "MAGNIFICENT IMPLOSION! Even your failures are executed with style and panache!",
        "trigger": {"type": "schedule_collapse", "complexity": "extreme"},
        "rewards": {"xp": 400, "title": "Ambitious Planner", "power": "Creative Chaos Energy"},
        "rarity": "common",
        "celebration_level": "quiet"
    },
    
    # Hidden/Secret Achievements
    "unicorn_productivity": {
        "name": "🦄 UNICORN PRODUCTIVITY",
        "description": "MYTHICAL BEING! You have transcended the limitations of cosmic interference!",
        "trigger": {"type": "perfect_day_mercury_retrograde", "hidden": True},
        "rewards": {"xp": 10000, "title": "Cosmic Immunity", "power": "Reality Bending"},
        "rarity": "secret_mythical",
        "celebration_level": "epic"
    },
    
    "midnight_phantom": {
        "name": "🌙 MIDNIGHT PRODUCTIVITY PHANTOM",
        "description": "PHANTOM OF PRODUCTIVITY! You haunt the witching hour with task completion!",
        "trigger": {"type": "task_at_midnight", "hidden": True},
        "rewards": {"xp": 666, "title": "Midnight Warrior", "power": "Night Energy"},
        "rarity": "secret_rare",
        "celebration_level": "standard"
    }
}

CELEBRATION_TEMPLATES = {
    "epic": """
🎺🎺🎺 LEGENDARY ACHIEVEMENT UNLOCKED! 🎺🎺🎺

        ⭐ {name} ⭐
              🏆👑🏆👑🏆👑🏆

📜 "{description}"

🎊 REWARDS EARNED:
   ✨ +{xp:,} XP (LEGENDARY BONUS!)
   👑 "{title}" Title  
   🌟 {power}
   🎖️ Special Achievement Badge
   🌟 Permanent stat boost unlocked!

💬 PERSONA CELEBRATIONS:
{persona_reactions}

🏆 Achievement unlocked on: {date}
🎯 Next legendary challenge awaits!
""",
    
    "standard": """
🎊 ACHIEVEMENT UNLOCKED! 🎊

⚡ **{name}**
"{description}"

🎁 Rewards: +{xp:,} XP, "{title}" Title, {power}
💬 {random_persona_reaction}

🏆 Unlocked: {date}
""",
    
    "quiet": """
✨ Achievement earned: {name}
"{description}"
+{xp} XP | {power}
"""
}

def get_persona_reactions(achievement: Dict[str, Any]) -> str:
    """Generate persona reactions for achievement unlock."""
    reactions = {
        "chaos_gremlin": [
            f"🎪 Chaos Gremlin: 'MAGNIFICENT {achievement['name'].upper()} CHAOS! You've turned productivity into BEAUTIFUL LEGEND!'",
            f"🎪 Chaos Gremlin: 'PLOT TWIST ACHIEVEMENT! This is even more spectacular than I imagined!'",
            f"🎪 Chaos Gremlin: 'CHAOS ENERGY OVERLOAD! Your achievement creates ripples of creative destruction!'"
        ],
        "hype_squad": [
            f"📣 Hype Squad: 'LEGENDARY PERFORMANCE! GREATEST {achievement['name']} WARRIOR IN HISTORY!'",
            f"📣 Hype Squad: 'HALL OF FAME ACHIEVEMENT! THE CROWD GOES ABSOLUTELY WILD!'",
            f"📣 Hype Squad: 'RECORD-BREAKING EXCELLENCE! YOU'RE THE PRODUCTIVITY SUPERHERO!'"
        ],
        "questmaster": [
            f"🎮 Quest Master: '⚔️ EPIC VICTORY! The {achievement['name']} achievement unlocks new character abilities!'",
            f"🎮 Quest Master: '🏆 LEGENDARY STATUS! Your character sheet glows with {achievement['name']} power!'",
            f"🎮 Quest Master: '⭐ ACHIEVEMENT COMBO! This unlocks the path to even greater adventures!'"
        ],
        "cozy_hobbit": [
            f"🏠 Cozy Hobbit: 'Oh my! {achievement['name']} is quite an accomplishment, dear! Time for celebratory tea!'",
            f"🏠 Cozy Hobbit: 'Well done! Your {achievement['name']} achievement brings such joy to the whole system!'",
            f"🏠 Cozy Hobbit: 'Lovely work! This {achievement['name']} success deserves proper celebration!'"
        ],
        "time_wizard": [
            f"🧙‍♂️ Time Wizard: 'BEHOLD! The timestreams celebrate your {achievement['name']} mastery!'",
            f"🧙‍♂️ Time Wizard: 'MAGNIFICENT! Your {achievement['name']} achievement bends reality itself!'",
            f"🧙‍♂️ Time Wizard: 'TEMPORAL MASTERY! The {achievement['name']} unlocks new time magic!'"
        ]
    }
    
    selected_personas = random.sample(list(reactions.keys()), min(3, len(reactions)))
    persona_lines = []
    
    for persona in selected_personas:
        persona_lines.append(random.choice(reactions[persona]))
    
    return "\n".join(persona_lines)

def check_achievement_trigger(achievement_id: str, event_data: Dict[str, Any]) -> bool:
    """Check if an event should trigger an achievement unlock."""
    if achievement_id not in ACHIEVEMENTS_DATABASE:
        return False
    
    achievement = ACHIEVEMENTS_DATABASE[achievement_id]
    trigger = achievement["trigger"]
    
    # Simple trigger matching (would be more sophisticated in real implementation)
    if trigger["type"] == event_data.get("type"):
        # Check count requirements
        if "count" in trigger:
            return event_data.get("count", 0) >= trigger["count"]
        
        # Check time-based requirements
        if "days" in trigger:
            return event_data.get("days", 0) >= trigger["days"]
        
        # Check boolean requirements
        if "no_distractions" in trigger:
            return event_data.get("no_distractions", False) == trigger["no_distractions"]
        
        return True
    
    return False

def unlock_achievement(achievement_id: str, user_data: Optional[Dict[str, Any]] = None) -> str:
    """Unlock an achievement and return celebration text."""
    if achievement_id not in ACHIEVEMENTS_DATABASE:
        return f"❌ Unknown achievement: {achievement_id}"
    
    # Load user achievement data
    user_achievements = load_user_achievements()
    
    # Check if already unlocked
    if achievement_id in user_achievements["earned"]:
        return f"🎖️ Achievement '{achievement_id}' already unlocked!"
    
    achievement = ACHIEVEMENTS_DATABASE[achievement_id]
    
    # Add to earned achievements
    user_achievements["earned"].append(achievement_id)
    user_achievements["unlocked_on"][achievement_id] = datetime.now().isoformat()
    
    # Save updated achievements
    save_user_achievements(user_achievements)
    
    # Generate celebration based on rarity/celebration level
    celebration_level = achievement.get("celebration_level", "standard")
    template = CELEBRATION_TEMPLATES[celebration_level]
    
    # Prepare celebration variables
    celebration_vars = {
        "name": achievement["name"],
        "description": achievement["description"],
        "xp": achievement["rewards"]["xp"],
        "title": achievement["rewards"]["title"],
        "power": achievement["rewards"]["power"],
        "date": datetime.now().strftime("%B %d, %Y")
    }
    
    if celebration_level == "epic":
        celebration_vars["persona_reactions"] = get_persona_reactions(achievement)
    elif celebration_level == "standard":
        # Single random persona reaction
        personas = ["chaos_gremlin", "hype_squad", "questmaster", "cozy_hobbit", "time_wizard"]
        selected = random.choice(personas)
        reactions = {
            "chaos_gremlin": f"🎪 Chaos Gremlin: 'SPECTACULAR {achievement['name']} CHAOS MASTERY!'",
            "hype_squad": f"📣 Hype Squad: 'LEGENDARY {achievement['name']} CHAMPION!'",
            "questmaster": f"🎮 Quest Master: 'Achievement unlocked! {achievement['name']} power gained!'",
            "cozy_hobbit": f"🏠 Cozy Hobbit: 'Lovely {achievement['name']} accomplishment, dear!'",
            "time_wizard": f"🧙‍♂️ Time Wizard: 'BEHOLD! {achievement['name']} mastery achieved!'"
        }
        celebration_vars["random_persona_reaction"] = reactions[selected]
    
    return template.format(**celebration_vars)

def list_available_achievements(category: Optional[str] = None) -> str:
    """List available achievements, optionally filtered by category."""
    output = "🏆 **Available Ridiculous Achievements:**\n\n"
    
    user_achievements = load_user_achievements()
    earned = set(user_achievements["earned"])
    
    # Group by category (simplified categorization)
    categories = {
        "Email & Communication": [],
        "Task Completion": [],
        "Organization": [],
        "Time Management": [],
        "Focus & Deep Work": [],
        "Boss Battles": [],
        "Streaks & Consistency": [],
        "Spectacular Failures": [],
        "Hidden Secrets": []
    }
    
    for achievement_id, achievement in ACHIEVEMENTS_DATABASE.items():
        # Determine category based on keywords
        name_lower = achievement["name"].lower()
        if any(word in name_lower for word in ["email", "inbox", "communication", "diplomatic"]):
            category_key = "Email & Communication"
        elif any(word in name_lower for word in ["task", "productivity", "completion", "warrior", "phoenix"]):
            category_key = "Task Completion"
        elif any(word in name_lower for word in ["organization", "declutter", "castle", "marie"]):
            category_key = "Organization"
        elif any(word in name_lower for word in ["time", "pomodoro", "deadline", "schedule"]):
            category_key = "Time Management"
        elif any(word in name_lower for word in ["focus", "zen", "distraction", "monk"]):
            category_key = "Focus & Deep Work"
        elif any(word in name_lower for word in ["dragon", "boss", "challenge", "battle"]):
            category_key = "Boss Battles"
        elif any(word in name_lower for word in ["streak", "consistency", "force", "diamond"]):
            category_key = "Streaks & Consistency"
        elif any(word in name_lower for word in ["disaster", "explosion", "failure"]):
            category_key = "Spectacular Failures"
        else:
            category_key = "Hidden Secrets"
        
        # Skip hidden achievements unless already earned
        if achievement.get("trigger", {}).get("hidden") and achievement_id not in earned:
            continue
            
        categories[category_key].append((achievement_id, achievement))
    
    # Display categories with achievements
    for cat_name, achievements in categories.items():
        if not achievements:
            continue
            
        output += f"### {cat_name}\n\n"
        
        for achievement_id, achievement in achievements[:5]:  # Limit to 5 per category
            status = "✅ EARNED" if achievement_id in earned else "🎯 Available"
            rarity_emoji = {
                "common": "⚪",
                "rare": "🟡", 
                "legendary": "🟠",
                "mythical": "🔴",
                "secret_rare": "💜",
                "secret_mythical": "🖤",
                "legendary_mythical": "🌈"
            }.get(achievement.get("rarity", "common"), "⚪")
            
            output += f"{rarity_emoji} **{achievement['name']}** - {status}\n"
            output += f"   {achievement['description'][:80]}...\n"
            output += f"   Reward: +{achievement['rewards']['xp']} XP, {achievement['rewards']['title']}\n\n"
        
        if len(categories[cat_name]) > 5:
            output += f"   ... and {len(categories[cat_name]) - 5} more in this category\n\n"
    
    earned_count = len(earned)
    total_count = len([a for a in ACHIEVEMENTS_DATABASE.values() if not a.get("trigger", {}).get("hidden")])
    output += f"🎖️ **Progress: {earned_count}/{total_count} achievements earned** ({earned_count/total_count*100:.1f}%)\n"
    
    return output

def list_earned_achievements() -> str:
    """List user's earned achievements with unlock dates."""
    user_achievements = load_user_achievements()
    earned = user_achievements["earned"]
    unlock_dates = user_achievements.get("unlocked_on", {})
    
    if not earned:
        return "📋 **No achievements earned yet!**\n\n💡 Complete some tasks to start unlocking ridiculous achievements!"
    
    output = f"🏆 **Your Legendary Achievement Collection** ({len(earned)} earned)\n\n"
    
    # Sort by unlock date (most recent first)
    earned_with_dates = []
    for achievement_id in earned:
        unlock_date = unlock_dates.get(achievement_id, "Unknown date")
        if achievement_id in ACHIEVEMENTS_DATABASE:
            earned_with_dates.append((achievement_id, unlock_date))
    
    earned_with_dates.sort(key=lambda x: x[1], reverse=True)
    
    for achievement_id, unlock_date in earned_with_dates:
        achievement = ACHIEVEMENTS_DATABASE[achievement_id]
        
        rarity_emoji = {
            "common": "⚪", "rare": "🟡", "legendary": "🟠", "mythical": "🔴",
            "secret_rare": "💜", "secret_mythical": "🖤", "legendary_mythical": "🌈"
        }.get(achievement.get("rarity", "common"), "⚪")
        
        # Format unlock date
        try:
            date_obj = datetime.fromisoformat(unlock_date.replace('Z', '+00:00'))
            formatted_date = date_obj.strftime("%B %d, %Y")
        except:
            formatted_date = unlock_date
        
        output += f"{rarity_emoji} **{achievement['name']}**\n"
        output += f"   {achievement['description']}\n"
        output += f"   🎁 Rewards: +{achievement['rewards']['xp']} XP, {achievement['rewards']['title']}, {achievement['rewards']['power']}\n"
        output += f"   📅 Earned: {formatted_date}\n\n"
    
    # Calculate total XP earned from achievements
    total_xp = sum(ACHIEVEMENTS_DATABASE[aid]["rewards"]["xp"] for aid in earned if aid in ACHIEVEMENTS_DATABASE)
    output += f"⭐ **Total Achievement XP: {total_xp:,}**\n"
    output += f"🎖️ **Achievement Mastery Level:** {len(earned)}\n"
    
    return output

def main():
    """Main CLI interface for achievements system."""
    if len(sys.argv) < 2:
        print("Usage: python achievement_system.py <action> [arguments...]")
        print("Actions: unlock, list, earned, suggest, celebrate")
        return
    
    action = sys.argv[1]
    
    if action == "unlock":
        if len(sys.argv) < 3:
            print("Usage: python achievement_system.py unlock <achievement_id>")
            return
        
        achievement_id = sys.argv[2]
        celebration = unlock_achievement(achievement_id)
        print(celebration)
    
    elif action == "list":
        category = sys.argv[2] if len(sys.argv) > 2 else None
        achievements_list = list_available_achievements(category)
        print(achievements_list)
    
    elif action == "earned":
        earned_list = list_earned_achievements()
        print(earned_list)
    
    elif action == "suggest":
        # Show some random achievements they could work toward
        available_achievements = [
            aid for aid in ACHIEVEMENTS_DATABASE.keys() 
            if aid not in load_user_achievements()["earned"]
            and not ACHIEVEMENTS_DATABASE[aid].get("trigger", {}).get("hidden")
        ]
        
        if not available_achievements:
            print("🏆 **You've earned all visible achievements!** 🏆")
            print("💫 Keep exploring - there might be hidden achievements waiting...")
            return
        
        suggestions = random.sample(available_achievements, min(3, len(available_achievements)))
        
        print("🎯 **Achievement Suggestions:**\n")
        
        for achievement_id in suggestions:
            achievement = ACHIEVEMENTS_DATABASE[achievement_id]
            print(f"🏆 **{achievement['name']}**")
            print(f"   {achievement['description']}")
            print(f"   Reward: +{achievement['rewards']['xp']} XP, {achievement['rewards']['title']}")
            print(f"   💡 Tip: Complete tasks related to {achievement['trigger']['type']}\n")
    
    elif action == "celebrate":
        # Show a random celebration for motivation
        celebrations = [
            "🎊 Keep going, achievement hunter! Your next legendary unlock awaits!",
            "🏆 Every task completed brings you closer to ridiculous achievement glory!",
            "⚡ Your productivity powers grow stronger with each achievement earned!",
            "🎯 The achievement system believes in your legendary potential!",
            "🌟 Today's mundane tasks are tomorrow's ridiculous achievement celebrations!"
        ]
        
        print(random.choice(celebrations))
    
    else:
        print(f"❌ Unknown action: {action}")
        print("Available actions: unlock, list, earned, suggest, celebrate")

if __name__ == "__main__":
    main()