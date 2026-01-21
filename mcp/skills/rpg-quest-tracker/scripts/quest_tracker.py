#!/usr/bin/env python3
"""
RPG Quest Tracker
Tracks daily, weekly, and monthly quests with real-time progress.
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Add MCP server to path for imports
MCP_DIR = Path(__file__).parent.parent.parent.parent / "mcp"
sys.path.insert(0, str(MCP_DIR))

# Import MCP helper functions
try:
    from gtd_mcp_server import (
        find_all_task_files,
        read_task_file,
        read_daily_log_file,
        GTD_BASE_DIR
    )
    MCP_AVAILABLE = True
except ImportError:
    MCP_AVAILABLE = False
    # Fallback paths
    GTD_BASE_DIR = Path.home() / "Documents" / "gtd"

# Get gamification file path
GTD_BASE_DIR_ENV = os.environ.get("GTD_BASE_DIR", str(Path.home() / "code" / "dotfiles"))
GAMIFICATION_FILE = os.path.join(GTD_BASE_DIR_ENV, ".gtd/gamification/gamification.json")
GTD_BASE = Path(GTD_BASE_DIR_ENV) / ".gtd" if isinstance(GTD_BASE_DIR_ENV, str) else GTD_BASE_DIR_ENV / ".gtd"

# Get action from environment or args
action = os.environ.get("SKILL_ARG_action", "view")
quest_id = os.environ.get("SKILL_ARG_quest_id", "")

if len(sys.argv) > 1:
    action = sys.argv[1]
if len(sys.argv) > 2:
    quest_id = sys.argv[2]

# Quest definitions
DAILY_QUESTS = [
    {
        "id": "daily_3_tasks",
        "name": "Complete 3 Tasks",
        "description": "Complete 3 tasks today",
        "type": "daily",
        "rarity": "common",
        "xp_reward": 30,
        "requirements": {"tasks_completed_today": 3}
    },
    {
        "id": "daily_log_entry",
        "name": "Log to Daily Log",
        "description": "Make at least one daily log entry",
        "type": "daily",
        "rarity": "common",
        "xp_reward": 5,
        "requirements": {"daily_log_entries_today": 1}
    },
    {
        "id": "daily_all_habits",
        "name": "Complete All Daily Habits",
        "description": "Complete all your daily habits",
        "type": "daily",
        "rarity": "uncommon",
        "xp_reward": 25,
        "requirements": {"daily_habits_completed": "all"}
    },
    {
        "id": "daily_exercise",
        "name": "Exercise for 30+ Minutes",
        "description": "Exercise for at least 30 minutes",
        "type": "daily",
        "rarity": "uncommon",
        "xp_reward": 40,
        "requirements": {"exercise_minutes_today": 30}
    },
    {
        "id": "daily_high_priority",
        "name": "Complete High-Priority Task",
        "description": "Complete at least one high-priority task",
        "type": "daily",
        "rarity": "common",
        "xp_reward": 20,
        "requirements": {"high_priority_tasks_completed_today": 1}
    }
]

WEEKLY_QUESTS = [
    {
        "id": "weekly_review",
        "name": "Complete Weekly Review",
        "description": "Complete your weekly review",
        "type": "weekly",
        "rarity": "rare",
        "xp_reward": 50,
        "requirements": {"weekly_review_completed": True}
    },
    {
        "id": "weekly_20_tasks",
        "name": "Complete 20 Tasks",
        "description": "Complete 20 tasks this week",
        "type": "weekly",
        "rarity": "uncommon",
        "xp_reward": 100,
        "requirements": {"tasks_completed_this_week": 20}
    },
    {
        "id": "weekly_habit_streak",
        "name": "Maintain 7-Day Habit Streak",
        "description": "Maintain a 7-day habit streak",
        "type": "weekly",
        "rarity": "rare",
        "xp_reward": 75,
        "requirements": {"habit_streak": 7}
    },
    {
        "id": "weekly_log_streak",
        "name": "Log Daily Log 7 Days",
        "description": "Log to daily log for 7 consecutive days",
        "type": "weekly",
        "rarity": "uncommon",
        "xp_reward": 50,
        "requirements": {"daily_logging_streak": 7}
    },
    {
        "id": "weekly_project",
        "name": "Complete 1 Project",
        "description": "Complete at least one project this week",
        "type": "weekly",
        "rarity": "rare",
        "xp_reward": 150,
        "requirements": {"projects_completed_this_week": 1}
    }
]

MONTHLY_QUESTS = [
    {
        "id": "monthly_review",
        "name": "Complete Monthly Review",
        "description": "Complete your monthly review",
        "type": "monthly",
        "rarity": "epic",
        "xp_reward": 100,
        "requirements": {"monthly_review_completed": True}
    },
    {
        "id": "monthly_100_tasks",
        "name": "Complete 100 Tasks",
        "description": "Complete 100 tasks this month",
        "type": "monthly",
        "rarity": "rare",
        "xp_reward": 500,
        "requirements": {"tasks_completed_this_month": 100}
    },
    {
        "id": "monthly_major_project",
        "name": "Complete a Major Project",
        "description": "Complete a major project this month",
        "type": "monthly",
        "rarity": "epic",
        "xp_reward": 300,
        "requirements": {"major_project_completed_this_month": True}
    },
    {
        "id": "monthly_habit_streak",
        "name": "Maintain 30-Day Habit Streak",
        "description": "Maintain a 30-day habit streak",
        "type": "monthly",
        "rarity": "epic",
        "xp_reward": 200,
        "requirements": {"habit_streak": 30}
    },
    {
        "id": "monthly_log_streak",
        "name": "Log Daily Log 30 Days",
        "description": "Log to daily log for 30 consecutive days",
        "type": "monthly",
        "rarity": "rare",
        "xp_reward": 250,
        "requirements": {"daily_logging_streak": 30}
    }
]

ALL_QUESTS = DAILY_QUESTS + WEEKLY_QUESTS + MONTHLY_QUESTS

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

def get_tasks_completed_today():
    """Get number of tasks completed today."""
    if not MCP_AVAILABLE:
        return 0
    
    today = datetime.now().date()
    count = 0
    
    try:
        task_files = find_all_task_files()
        for task_file in task_files:
            task_data = read_task_file(task_file)
            if task_data.get("status") == "done":
                # Check if completed today
                completed = task_data.get("completed")
                if completed:
                    try:
                        completed_date = datetime.fromisoformat(completed.replace('Z', '+00:00')).date()
                        if completed_date == today:
                            count += 1
                    except:
                        # If date parsing fails, check if it's recent
                        pass
    except Exception as e:
        print(f"Error getting tasks completed today: {e}", file=sys.stderr)
    
    return count

def get_daily_log_entries_today():
    """Check if daily log entry exists for today."""
    if not MCP_AVAILABLE:
        return 0
    
    try:
        log_content = read_daily_log_file()
        if log_content and log_content.strip():
            return 1
    except Exception as e:
        print(f"Error reading daily log: {e}", file=sys.stderr)
    
    return 0

def get_tasks_completed_this_week():
    """Get number of tasks completed this week."""
    if not MCP_AVAILABLE:
        return 0
    
    today = datetime.now().date()
    week_start = today - timedelta(days=today.weekday())
    count = 0
    
    try:
        task_files = find_all_task_files()
        for task_file in task_files:
            task_data = read_task_file(task_file)
            if task_data.get("status") == "done":
                completed = task_data.get("completed")
                if completed:
                    try:
                        completed_date = datetime.fromisoformat(completed.replace('Z', '+00:00')).date()
                        if week_start <= completed_date <= today:
                            count += 1
                    except:
                        pass
    except Exception as e:
        print(f"Error getting tasks completed this week: {e}", file=sys.stderr)
    
    return count

def get_tasks_completed_this_month():
    """Get number of tasks completed this month."""
    if not MCP_AVAILABLE:
        return 0
    
    today = datetime.now().date()
    month_start = today.replace(day=1)
    count = 0
    
    try:
        task_files = find_all_task_files()
        for task_file in task_files:
            task_data = read_task_file(task_file)
            if task_data.get("status") == "done":
                completed = task_data.get("completed")
                if completed:
                    try:
                        completed_date = datetime.fromisoformat(completed.replace('Z', '+00:00')).date()
                        if month_start <= completed_date <= today:
                            count += 1
                    except:
                        pass
    except Exception as e:
        print(f"Error getting tasks completed this month: {e}", file=sys.stderr)
    
    return count

def calculate_quest_progress(quest, data):
    """Calculate progress for a quest."""
    requirements = quest.get("requirements", {})
    progress = {}
    completed = True
    
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    
    for req_key, req_value in requirements.items():
        current = 0
        
        if req_key == "tasks_completed_today":
            current = get_tasks_completed_today()
        elif req_key == "daily_log_entries_today":
            current = get_daily_log_entries_today()
        elif req_key == "tasks_completed_this_week":
            current = get_tasks_completed_this_week()
        elif req_key == "tasks_completed_this_month":
            current = get_tasks_completed_this_month()
        elif req_key == "daily_logging_streak":
            current = streaks.get("daily_logging", 0)
        elif req_key == "habit_streak":
            current = streaks.get("habits", 0) or streaks.get("task_completion", 0)
        elif req_key == "weekly_review_completed":
            # Would check review system
            current = 0
        elif req_key == "monthly_review_completed":
            # Would check review system
            current = 0
        elif req_key == "daily_habits_completed":
            # Would check habit system
            current = 0
        elif req_key == "exercise_minutes_today":
            # Would check exercise/health system
            current = 0
        elif req_key == "high_priority_tasks_completed_today":
            current = 0  # Would check task system
        elif req_key == "projects_completed_this_week":
            current = 0  # Would check project system
        elif req_key == "major_project_completed_this_month":
            current = 0  # Would check project system
        
        # Handle special cases
        if req_value == "all":
            # For "all" requirements, we'd need to check if all are completed
            # For now, assume not completed
            completed = False
            progress[req_key] = {"current": current, "required": "all", "percentage": 0}
        elif isinstance(req_value, bool):
            completed = current > 0 if req_value else True
            progress[req_key] = {"current": current, "required": 1 if req_value else 0, "percentage": 100 if completed else 0}
        else:
            percentage = min(int((current / req_value) * 100), 100) if req_value > 0 else 0
            completed = completed and (current >= req_value)
            progress[req_key] = {"current": current, "required": req_value, "percentage": percentage}
    
    # Calculate overall progress
    if progress:
        total_percentage = sum(p["percentage"] for p in progress.values()) / len(progress)
    else:
        total_percentage = 0
    
    return {
        "completed": completed,
        "progress": progress,
        "percentage": int(total_percentage)
    }

def format_progress_bar(percentage, width=20):
    """Create a text progress bar."""
    filled = int((percentage / 100) * width)
    filled = min(filled, width)
    return "█" * filled + "░" * (width - filled)

def get_time_until_reset(quest_type):
    """Get time until quest reset."""
    now = datetime.now()
    
    if quest_type == "daily":
        # Reset at midnight
        tomorrow = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
        delta = tomorrow - now
        hours = int(delta.total_seconds() / 3600)
        minutes = int((delta.total_seconds() % 3600) / 60)
        return f"{hours}h {minutes}m"
    elif quest_type == "weekly":
        # Reset on Monday
        days_until_monday = (7 - now.weekday()) % 7
        if days_until_monday == 0:
            days_until_monday = 7
        next_monday = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=days_until_monday)
        delta = next_monday - now
        days = delta.days
        hours = int((delta.total_seconds() % 86400) / 3600)
        return f"{days}d {hours}h"
    elif quest_type == "monthly":
        # Reset on 1st of next month
        if now.month == 12:
            next_month = now.replace(year=now.year + 1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        else:
            next_month = now.replace(month=now.month + 1, day=1, hour=0, minute=0, second=0, microsecond=0)
        delta = next_month - now
        days = delta.days
        return f"{days}d"
    
    return ""

def display_quest(quest, quest_progress, show_details=False):
    """Display a single quest."""
    rarity_emoji = {
        "common": "⚪",
        "uncommon": "🟢",
        "rare": "🔵",
        "epic": "🟣",
        "legendary": "🟡"
    }
    
    emoji = rarity_emoji.get(quest["rarity"], "⚪")
    status = "✅" if quest_progress["completed"] else "⏳"
    
    # Get progress summary
    if quest_progress["progress"]:
        first_progress = list(quest_progress["progress"].values())[0]
        current = first_progress["current"]
        required = first_progress["required"]
        if required == "all":
            progress_text = "In progress"
        else:
            progress_text = f"{current}/{required}"
    else:
        progress_text = "0/0"
    
    percentage = quest_progress["percentage"]
    bar = format_progress_bar(percentage)
    
    # Status icon
    if quest_progress["completed"]:
        status_icon = "✅"
        status_text = "Completed!"
    else:
        status_icon = "⏳"
        remaining = ""
        if quest_progress["progress"]:
            first_progress = list(quest_progress["progress"].values())[0]
            if isinstance(first_progress["required"], int):
                remaining_val = max(0, first_progress["required"] - first_progress["current"])
                if remaining_val > 0:
                    remaining = f"{remaining_val} remaining"
        status_text = remaining if remaining else "Not started"
    
    print(f"║ {status_icon} {quest['name']:<35} {emoji} [{bar}] {progress_text:<8} ║")
    print(f"║    +{quest['xp_reward']} XP | {status_text:<45} ║")
    if show_details and quest_progress["progress"]:
        for req_key, req_data in quest_progress["progress"].items():
            if isinstance(req_data["required"], int):
                print(f"║      {req_key}: {req_data['current']}/{req_data['required']} ({req_data['percentage']}%){' ' * 30} ║")
    print("║" + " " * 59 + "║")

def display_quests(quests, quest_type, data):
    """Display a group of quests."""
    type_name = quest_type.capitalize()
    reset_time = get_time_until_reset(quest_type)
    
    print("╠════════════════════════════════════════════════════════════╣")
    print(f"║ {type_name} QUESTS (Resets in {reset_time}){' ' * (30 - len(reset_time))} ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    completed_count = 0
    for quest in quests:
        quest_progress = calculate_quest_progress(quest, data)
        display_quest(quest, quest_progress)
        if quest_progress["completed"]:
            completed_count += 1
    
    if completed_count == len(quests):
        print("║ 🎉 All quests completed! Great work!{' ' * 20} ║")
    
    return completed_count, len(quests)

def display_all_quests(data):
    """Display all quests."""
    print("╔════════════════════════════════════════════════════════════╗")
    print("║              📋 QUEST TRACKER 📋                          ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    daily_completed, daily_total = display_quests(DAILY_QUESTS, "daily", data)
    weekly_completed, weekly_total = display_quests(WEEKLY_QUESTS, "weekly", data)
    monthly_completed, monthly_total = display_quests(MONTHLY_QUESTS, "monthly", data)
    
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    
    total_completed = daily_completed + weekly_completed + monthly_completed
    total_quests = daily_total + weekly_total + monthly_total
    
    print(f"📊 Progress: {total_completed}/{total_quests} quests completed")
    print(f"💡 Tip: Focus on daily quests for quick XP gains!")
    print(f"💡 Tip: Complete weekly review for big bonus XP!")

def display_recommendations(data):
    """Display quest recommendations."""
    print("╔════════════════════════════════════════════════════════════╗")
    print("║         🎯 QUEST RECOMMENDATIONS 🎯                     ║")
    print("╠════════════════════════════════════════════════════════════╣")
    
    all_quest_progress = []
    for quest in ALL_QUESTS:
        progress = calculate_quest_progress(quest, data)
        if not progress["completed"]:
            all_quest_progress.append((quest, progress))
    
    # Sort by completion percentage (highest first)
    all_quest_progress.sort(key=lambda x: x[1]["percentage"], reverse=True)
    
    # Show top 5-10 recommendations
    recommendations = all_quest_progress[:10]
    
    if not recommendations:
        print("║ 🎉 All quests completed! You're amazing!{' ' * 15} ║")
    else:
        print("║ TOP RECOMMENDATIONS (Closest to completion):          ║")
        print("╠════════════════════════════════════════════════════════════╣")
        
        for i, (quest, progress) in enumerate(recommendations, 1):
            percentage = progress["percentage"]
            bar = format_progress_bar(percentage, 15)
            
            # Get what's needed
            if progress["progress"]:
                first_progress = list(progress["progress"].values())[0]
                if isinstance(first_progress["required"], int):
                    needed = max(0, first_progress["required"] - first_progress["current"])
                    if needed > 0:
                        needed_text = f"Need {needed} more"
                    else:
                        needed_text = "Almost there!"
                else:
                    needed_text = "In progress"
            else:
                needed_text = "Not started"
            
            print(f"║ {i}. {quest['name']:<35} [{bar}] {percentage:3d}% ║")
            print(f"║    +{quest['xp_reward']} XP | {needed_text:<45} ║")
            print("║" + " " * 59 + "║")
    
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    print("💡 Tip: Focus on quests with highest completion percentage!")
    print("💡 Tip: Daily quests reset at midnight - complete them today!")

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
        display_all_quests(data)
    elif action == "daily":
        print("╔════════════════════════════════════════════════════════════╗")
        print("║              📋 DAILY QUESTS 📋                           ║")
        display_quests(DAILY_QUESTS, "daily", data)
        print("╚════════════════════════════════════════════════════════════╝")
    elif action == "weekly":
        print("╔════════════════════════════════════════════════════════════╗")
        print("║              📋 WEEKLY QUESTS 📋                          ║")
        display_quests(WEEKLY_QUESTS, "weekly", data)
        print("╚════════════════════════════════════════════════════════════╝")
    elif action == "monthly":
        print("╔════════════════════════════════════════════════════════════╗")
        print("║              📋 MONTHLY QUESTS 📋                          ║")
        display_quests(MONTHLY_QUESTS, "monthly", data)
        print("╚════════════════════════════════════════════════════════════╝")
    elif action == "recommendations":
        display_recommendations(data)
    elif action == "progress":
        if quest_id:
            # Find quest
            quest = None
            for q in ALL_QUESTS:
                if q["id"] == quest_id:
                    quest = q
                    break
            
            if quest:
                progress = calculate_quest_progress(quest, data)
                print(f"╔════════════════════════════════════════════════════════════╗")
                print(f"║         📋 QUEST DETAILS: {quest['name']:<25} ║")
                print("╠════════════════════════════════════════════════════════════╣")
                print(f"║ Description: {quest['description']:<47} ║")
                print(f"║ XP Reward: +{quest['xp_reward']} XP{' ' * 45} ║")
                print(f"║ Rarity: {quest['rarity'].capitalize()}{' ' * 45} ║")
                print("╠════════════════════════════════════════════════════════════╣")
                print(f"║ Progress: {progress['percentage']}%{' ' * 50} ║")
                if progress["progress"]:
                    for req_key, req_data in progress["progress"].items():
                        if isinstance(req_data["required"], int):
                            print(f"║   {req_key}: {req_data['current']}/{req_data['required']} ({req_data['percentage']}%){' ' * 30} ║")
                print("╚════════════════════════════════════════════════════════════╝")
            else:
                print(f"❌ Quest not found: {quest_id}")
        else:
            print("❌ Error: quest_id required for progress action")
            print("   Usage: progress <quest_id>")
    else:
        print(f"Unknown action: {action}")
        print("Available actions: view, daily, weekly, monthly, progress, recommendations, full")
        sys.exit(1)

if __name__ == "__main__":
    main()
