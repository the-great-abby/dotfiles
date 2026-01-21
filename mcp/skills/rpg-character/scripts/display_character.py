#!/usr/bin/env python3
"""
RPG Character Display Script
Displays your GTD productivity as an RPG character with stats, quests, and achievements.
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Get gamification file path
GTD_BASE_DIR = os.environ.get("GTD_BASE_DIR", os.path.expanduser("~/code/dotfiles"))
GAMIFICATION_FILE = os.path.join(GTD_BASE_DIR, ".gtd/gamification/gamification.json")

# Get action from environment or args
action = os.environ.get("SKILL_ARG_action", "full")
if len(sys.argv) > 1:
    action = sys.argv[1]

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

def calculate_attributes(data):
    """Calculate RPG attributes from gamification data."""
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    
    # Strength: Based on tasks completed
    tasks_completed = stats.get("tasks_completed", 0)
    strength = min(int(tasks_completed * 0.1), 30)  # Cap at 30
    
    # Wisdom: Based on reviews completed
    reviews_completed = stats.get("reviews_completed", 0)
    wisdom = min(int(reviews_completed * 0.5), 30)  # Cap at 30
    
    # Dexterity: Based on habit and task streaks
    task_streak = streaks.get("task_completion", 0)
    habit_streak = streaks.get("habits", 0)
    dexterity = min(int((task_streak + habit_streak) * 0.2), 30)  # Cap at 30
    
    # Constitution: Based on daily logging streak
    daily_logging_streak = streaks.get("daily_logging", 0)
    constitution = min(int(daily_logging_streak * 0.1), 30)  # Cap at 30
    
    return {
        "strength": max(1, strength),
        "wisdom": max(1, wisdom),
        "dexterity": max(1, dexterity),
        "constitution": max(1, constitution)
    }

def calculate_hp_mp(data):
    """Calculate HP and MP from gamification data."""
    streaks = data.get("streaks", {})
    stats = data.get("stats", {})
    
    # HP: Based on consistency (streaks)
    daily_logging_streak = streaks.get("daily_logging", 0)
    task_streak = streaks.get("task_completion", 0)
    hp = min(int((daily_logging_streak + task_streak) / 2 * 10), 100)
    
    # MP: Based on review completion (simplified)
    reviews_completed = stats.get("reviews_completed", 0)
    # Assume ~4 reviews per month (weekly + monthly), so 48 per year
    mp = min(int((reviews_completed / 48) * 100), 100) if reviews_completed > 0 else 0
    
    return {"hp": max(0, hp), "mp": max(0, mp)}

def format_progress_bar(current, max_val, width=20):
    """Create a text progress bar."""
    if max_val == 0:
        return "░" * width
    filled = int((current / max_val) * width)
    filled = min(filled, width)
    return "█" * filled + "░" * (width - filled)

def display_character_sheet(data):
    """Display full RPG character sheet."""
    level = data.get("level", 1)
    total_xp = data.get("total_xp", 0)
    current_xp = data.get("xp", 0)
    
    # Calculate XP for next level (simplified formula)
    if level < 10:
        xp_per_level = 100
    else:
        xp_per_level = int(100 * (1.2 ** (level - 10)))
    
    xp_in_level = current_xp % xp_per_level if xp_per_level > 0 else 0
    xp_needed = xp_per_level - xp_in_level
    
    attributes = calculate_attributes(data)
    hp_mp = calculate_hp_mp(data)
    streaks = data.get("streaks", {})
    badges = data.get("badges", {})
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║         🎮 YOUR RPG CHARACTER SHEET 🎮                   ║")
    print("╠════════════════════════════════════════════════════════════╣")
    print(f"║ Level: {level:2d}  |  XP: {total_xp:,}  |  Next Level: {xp_needed:,} XP  ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # HP and MP bars
    hp_bar = format_progress_bar(hp_mp["hp"], 100, 20)
    mp_bar = format_progress_bar(hp_mp["mp"], 100, 20)
    print(f"║ HP: {hp_bar} {hp_mp['hp']:3d}%  |  MP: {mp_bar} {hp_mp['mp']:3d}%  ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Attributes
    print("║ ATTRIBUTES:                                                ║")
    print(f"║   💪 Strength:     {attributes['strength']:2d} (Task completion power)      ║")
    print(f"║   🧠 Wisdom:       {attributes['wisdom']:2d} (Review & reflection power)   ║")
    print(f"║   ⚡ Dexterity:    {attributes['dexterity']:2d} (Habit consistency)         ║")
    print(f"║   ❤️  Constitution: {attributes['constitution']:2d} (Daily logging consistency) ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Streaks
    print("║ ACTIVE STREAKS:                                            ║")
    daily_logging = streaks.get("daily_logging", 0)
    task_streak = streaks.get("task_completion", 0)
    review_streak = streaks.get("review", 0)
    exercise_streak = streaks.get("exercise", 0)
    
    if daily_logging > 0:
        print(f"║   📝 Daily Logging: {daily_logging} days                              ║")
    if task_streak > 0:
        print(f"║   ✅ Task Completion: {task_streak} days                            ║")
    if review_streak > 0:
        print(f"║   📊 Reviews: {review_streak} consecutive                          ║")
    if exercise_streak > 0:
        print(f"║   💪 Exercise: {exercise_streak} days                                ║")
    if daily_logging == 0 and task_streak == 0 and review_streak == 0 and exercise_streak == 0:
        print("║   (No active streaks - start building them!)              ║")
    
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Badges
    print("║ BADGES & ACHIEVEMENTS:                                      ║")
    earned_badges = [b for b in badges.values() if b.get("earned", False)]
    if earned_badges:
        for badge in earned_badges[:5]:  # Show first 5
            name = badge.get("name", "Unknown")
            print(f"║   🎖️  {name:<45} ║")
        if len(earned_badges) > 5:
            print(f"║   ... and {len(earned_badges) - 5} more badges!                    ║")
    else:
        print("║   (No badges yet - complete quests to earn them!)       ║")
    
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    print("💡 TIP: Complete tasks, maintain streaks, and do reviews to level up!")
    print("💡 TIP: Check your quests with action='quests' to see what to do next!")

def display_stats(data):
    """Display character stats only."""
    level = data.get("level", 1)
    total_xp = data.get("total_xp", 0)
    current_xp = data.get("xp", 0)
    
    # Calculate XP for next level
    if level < 10:
        xp_per_level = 100
    else:
        xp_per_level = int(100 * (1.2 ** (level - 10)))
    
    xp_in_level = current_xp % xp_per_level if xp_per_level > 0 else 0
    xp_needed = xp_per_level - xp_in_level
    
    attributes = calculate_attributes(data)
    hp_mp = calculate_hp_mp(data)
    
    print("╔════════════════════════════════════════════════╗")
    print("║         🎮 CHARACTER STATS 🎮                ║")
    print("╠════════════════════════════════════════════════╣")
    print(f"║ Level: {level:2d}                                    ║")
    print(f"║ Total XP: {total_xp:,}                          ║")
    print(f"║ XP to Next Level: {xp_needed:,}                ║")
    print("╠════════════════════════════════════════════════╣")
    
    hp_bar = format_progress_bar(hp_mp["hp"], 100, 15)
    mp_bar = format_progress_bar(hp_mp["mp"], 100, 15)
    print(f"║ HP: {hp_bar} {hp_mp['hp']:3d}%                    ║")
    print(f"║ MP: {mp_bar} {hp_mp['mp']:3d}%                    ║")
    print("╠════════════════════════════════════════════════╣")
    print("║ ATTRIBUTES:                                    ║")
    print(f"║   💪 Strength:     {attributes['strength']:2d}                    ║")
    print(f"║   🧠 Wisdom:       {attributes['wisdom']:2d}                    ║")
    print(f"║   ⚡ Dexterity:    {attributes['dexterity']:2d}                    ║")
    print(f"║   ❤️  Constitution: {attributes['constitution']:2d}                    ║")
    print("╚════════════════════════════════════════════════╝")

def display_quests(data):
    """Display active quests."""
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║              📋 ACTIVE QUESTS 📋                         ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Daily Quests
    print("║ DAILY QUESTS:                                              ║")
    print("║   📋 Complete 3 tasks → +30 XP                           ║")
    print("║   📋 Complete all daily habits → +25 XP                   ║")
    print("║   📝 Log to daily log → +5 XP                             ║")
    print("║   💪 Exercise for 30+ minutes → +40 XP                    ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Weekly Quests
    print("║ WEEKLY QUESTS:                                             ║")
    print("║   📊 Complete weekly review → +50 XP                      ║")
    print("║   ✅ Complete 20 tasks → +100 XP                          ║")
    print("║   🔥 Maintain 7-day habit streak → +75 XP                 ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    # Monthly Quests
    print("║ MONTHLY QUESTS:                                            ║")
    print("║   📊 Complete monthly review → +100 XP                     ║")
    print("║   ✅ Complete 100 tasks → +500 XP                         ║")
    print("║   🎯 Complete a major project → +300 XP                     ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    print("💡 TIP: Complete quests to earn bonus XP and level up faster!")
    print("💡 TIP: Use 'gtd-wizard' to access tasks, reviews, and habits!")

def display_achievements(data):
    """Display achievements/badges."""
    badges = data.get("badges", {})
    badges_lost = data.get("badges_lost", [])
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║          🎖️  ACHIEVEMENTS & BADGES 🎖️                   ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    earned_badges = [b for b in badges.values() if b.get("earned", False)]
    if earned_badges:
        print("║ EARNED BADGES:                                             ║")
        for badge in earned_badges:
            name = badge.get("name", "Unknown")
            desc = badge.get("description", "")
            xp = badge.get("xp_bonus", 0)
            earned_date = badge.get("earned_date", "")
            if earned_date:
                try:
                    date_obj = datetime.fromisoformat(earned_date.replace('Z', '+00:00'))
                    date_str = date_obj.strftime("%Y-%m-%d")
                except:
                    date_str = earned_date[:10] if len(earned_date) >= 10 else earned_date
            else:
                date_str = ""
            
            print(f"║   🎖️  {name:<40} ║")
            if desc:
                print(f"║      {desc:<45} ║")
            if xp > 0:
                print(f"║      +{xp} XP bonus | Earned: {date_str:<10}        ║")
            print("║                                                      ║")
    else:
        print("║   (No badges earned yet - complete quests to unlock!)   ║")
        print("║                                                      ║")
    
    if badges_lost:
        print("╠════════════════════════════════════════════════════════════╣")
        print("║ LOST BADGES (Build streak to regain!):                   ║")
        for badge_id in badges_lost:
            badge = badges.get(badge_id, {})
            name = badge.get("name", badge_id)
            print(f"║   ❌ {name:<45} ║")
        print("║                                                      ║")
    
    print("╚════════════════════════════════════════════════════════════╝")

def display_levelup_guide(data):
    """Display level up guide."""
    level = data.get("level", 1)
    total_xp = data.get("total_xp", 0)
    current_xp = data.get("xp", 0)
    
    # Calculate XP for next level
    if level < 10:
        xp_per_level = 100
    else:
        xp_per_level = int(100 * (1.2 ** (level - 10)))
    
    xp_in_level = current_xp % xp_per_level if xp_per_level > 0 else 0
    xp_needed = xp_per_level - xp_in_level
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║            📈 LEVEL UP GUIDE 📈                           ║")
    print("╠════════════════════════════════════════════════════════════╣")
    print(f"║ Current Level: {level:2d}                                      ║")
    print(f"║ Total XP: {total_xp:,}                                    ║")
    print(f"║ XP to Next Level: {xp_needed:,}                          ║")
    print("╠════════════════════════════════════════════════════════════╣")
    print("║ WAYS TO EARN XP:                                           ║")
    print("║   📝 Daily log entry → +5 XP                               ║")
    print("║   ✅ Complete task → +10-50 XP (based on priority)          ║")
    print("║   🔄 Complete habit → +15 XP (daily), +25 XP (weekly)       ║")
    print("║   📊 Weekly review → +50 XP                                ║")
    print("║   📊 Monthly review → +100 XP                               ║")
    print("║   🎯 Complete project → +100-500 XP                         ║")
    print("║   💪 Exercise/workout → +20-40 XP                           ║")
    print("║   🎖️  Earn badge → +50-500 XP                               ║")
    print("╠════════════════════════════════════════════════════════════╣")
    print("║ RECOMMENDED ACTIVITIES:                                    ║")
    print("║   1. Log to daily log (quick +5 XP)                        ║")
    print("║   2. Complete 3 tasks (daily quest +30 XP)                 ║")
    print("║   3. Complete weekly review (+50 XP)                       ║")
    print("║   4. Maintain streaks (builds HP and attributes)           ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    print("💡 TIP: Focus on daily quests for quick XP gains!")
    print("💡 TIP: Complete reviews for big XP bonuses!")

def main():
    """Main function."""
    data = load_gamification_data()
    
    if data is None:
        print("❌ Error: Could not load gamification data.")
        print(f"   Make sure {GAMIFICATION_FILE} exists.")
        print("   Run 'gtd-gamify' to initialize the gamification system.")
        sys.exit(1)
    
    # Route to appropriate display function
    if action in ["full", "character"]:
        display_character_sheet(data)
    elif action == "stats":
        display_stats(data)
    elif action == "quests":
        display_quests(data)
    elif action == "achievements":
        display_achievements(data)
    elif action == "levelup":
        display_levelup_guide(data)
    else:
        print(f"Unknown action: {action}")
        print("Available actions: stats, quests, levelup, achievements, character, full")
        sys.exit(1)

if __name__ == "__main__":
    main()
