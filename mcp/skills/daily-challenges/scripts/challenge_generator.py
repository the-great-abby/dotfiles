#!/usr/bin/env python3
"""
Random Daily Challenge Generator - Create fun productivity challenges
"""

import json
import os
import sys
import random
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

def get_challenges_data_dir() -> Path:
    """Get directory for storing challenge data."""
    data_dir = Path.home() / "Documents" / "gtd" / ".daily_challenges"
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir

def get_current_season() -> str:
    """Detect current season for seasonal challenges."""
    today = date.today()
    month = today.month
    
    if month == 10:
        return "halloween"
    elif month == 12:
        return "christmas"
    elif month == 1:
        return "new_year"
    elif month == 2 and today.day <= 18:
        return "valentine"
    elif month in [3, 4, 5]:
        return "spring"
    elif month in [6, 7, 8]:
        return "summer"
    elif month == 11:
        return "thanksgiving"
    else:
        return "regular"

def get_day_context() -> Dict[str, Any]:
    """Get context about current day for smart challenge selection."""
    today = date.today()
    return {
        "weekday": today.weekday(),  # 0=Monday, 6=Sunday
        "day_name": today.strftime("%A"),
        "is_weekend": today.weekday() >= 5,
        "is_monday": today.weekday() == 0,
        "is_friday": today.weekday() == 4,
        "season": get_current_season(),
        "month": today.month
    }

# Challenge database organized by category and difficulty
CHALLENGE_DATABASE = {
    "productivity": {
        "easy": [
            {
                "name": "Two-Minute Rule Warrior",
                "description": "Immediately do EVERYTHING that takes less than 2 minutes - no exceptions!",
                "instructions": "Set a 2-minute timer for small tasks. If it's under 2 minutes, do it immediately instead of adding to your list.",
                "tips": "Amazing for inbox management and quick tidying tasks!",
                "estimated_impact": "High - clears mental clutter fast",
                "emoji": "⚡"
            },
            {
                "name": "Single-Task Samurai", 
                "description": "Absolutely no multitasking today - one task at a time with laser focus",
                "instructions": "Close all extra tabs, put phone away, focus on ONE task until complete before starting another.",
                "tips": "You'll be amazed how much faster you actually work!",
                "estimated_impact": "Medium-High - dramatically improves focus quality",
                "emoji": "🎯"
            },
            {
                "name": "Email Zero Hero",
                "description": "Clear your entire inbox and keep it at zero all day",
                "instructions": "Process every email: delete, delegate, respond, or convert to task. Then maintain inbox zero.",
                "tips": "Use the 2-minute rule: if response takes under 2 minutes, do it now!",
                "estimated_impact": "High - creates sense of control and clarity",
                "emoji": "📧"
            }
        ],
        "medium": [
            {
                "name": "Backwards Day",
                "description": "Do your daily tasks in completely reverse order for fresh perspective", 
                "instructions": "Start with your last planned task and work backwards through your list.",
                "tips": "Often reveals dependencies and priorities you never noticed!",
                "estimated_impact": "Medium - provides new insights into task relationships",
                "emoji": "🔄"
            },
            {
                "name": "Time Block Tetris",
                "description": "Fit all tasks into perfectly arranged time blocks like puzzle pieces",
                "instructions": "Create visual time blocks for your day, then arrange tasks like Tetris pieces to fit perfectly.",
                "tips": "Leave small gaps between blocks for unexpected needs!",
                "estimated_impact": "High - creates satisfying, structured day",
                "emoji": "🧩"
            },
            {
                "name": "Priority Pyramid",
                "description": "Organize tasks in strict pyramid: 1 top priority, 2 medium, 3 small",
                "instructions": "Select exactly 1 must-do task, 2 important tasks, 3 smaller tasks. No more!",
                "tips": "Forces you to really think about what matters most today.",
                "estimated_impact": "High - creates crystal clear daily focus",
                "emoji": "🔺"
            }
        ],
        "hard": [
            {
                "name": "Digital Sunrise Mode",
                "description": "No digital devices until you've completed 3 meaningful tasks",
                "instructions": "Use paper, physical tools only. Earn your screen time through task completion.",
                "tips": "Prepare paper task list the night before!",
                "estimated_impact": "Very High - forces intentional, focused work",
                "emoji": "🌅"
            },
            {
                "name": "One-Touch Rule Extreme",
                "description": "Handle every single item, email, or task exactly once today",
                "instructions": "No re-reading emails, no postponing decisions. Touch it once, make the call, move on.",
                "tips": "Trust your first instinct - it's usually right!",
                "estimated_impact": "Very High - eliminates decision fatigue",
                "emoji": "👆"
            }
        ]
    },
    
    "creativity": {
        "easy": [
            {
                "name": "Emoji Everything",
                "description": "Add meaningful emojis to every task, note, and message today",
                "instructions": "Make everything more visual and fun with appropriate emojis throughout your work.",
                "tips": "Emojis can actually help you process information faster!",
                "estimated_impact": "Medium - adds joy and visual processing",
                "emoji": "😄"
            },
            {
                "name": "Color Coordination Day",
                "description": "Organize everything by color schemes and use colored pens/tools",
                "instructions": "Group similar items by color, use different colored pens for different types of tasks.",
                "tips": "Red for urgent, blue for calm work, green for growth tasks!",
                "estimated_impact": "Medium - creates beautiful, visual organization",
                "emoji": "🌈"
            },
            {
                "name": "Story Mode Light",
                "description": "Describe your tasks using adventure language and epic terminology",
                "instructions": "Turn 'answer emails' into 'respond to urgent communications from allies across the realm.'",
                "tips": "Makes mundane tasks feel like part of an epic quest!",
                "estimated_impact": "Medium - transforms perspective on boring tasks",
                "emoji": "📖"
            }
        ],
        "medium": [
            {
                "name": "Pirate Mode Monday",
                "description": "Do everything while speaking like a pirate - Arrr, matey!",
                "instructions": "Add 'Arrr', 'matey', 'ye scurvy dog' to your vocabulary. Make everything nautical!",
                "tips": "'Tis more fun than ye might expect, ye landlubber!",
                "estimated_impact": "High - adds humor and lightness to entire day",
                "emoji": "🏴‍☠️"
            },
            {
                "name": "Rhyme Time Productivity",
                "description": "Write all notes, emails, and task lists in rhyming verses",
                "instructions": "Every written communication must rhyme. Tasks become poetic masterpieces!",
                "tips": "Don't worry about perfect poetry - just have fun with it!",
                "estimated_impact": "Medium-High - exercises creativity while working",
                "emoji": "🎵"
            },
            {
                "name": "Random Word Integration",
                "description": "Pick a random word and work it into every task description creatively",
                "instructions": "Choose random word (butterfly, telescope, pizza) and incorporate it meaningfully into all tasks.",
                "tips": "Forces creative thinking about ordinary activities!",
                "estimated_impact": "Medium - stretches creative thinking muscles",
                "emoji": "🎲"
            }
        ],
        "hard": [
            {
                "name": "Haiku Communication",
                "description": "All written communication must be in haiku format (5-7-5 syllables)",
                "instructions": "Emails, notes, texts - everything becomes poetry. 5 syllables, 7 syllables, 5 syllables.",
                "tips": "Forces you to be concise and thoughtful with every word!",
                "estimated_impact": "Very High - completely transforms communication style",
                "emoji": "🎋"
            },
            {
                "name": "Character Mode Complete",
                "description": "Spend the entire day as a different professional character (scientist, artist, CEO)",
                "instructions": "Pick a profession and embody it completely. How would a detective organize? How would an artist prioritize?",
                "tips": "Research the profession first for authentic perspective!",
                "estimated_impact": "Very High - provides completely fresh approach to work",
                "emoji": "🎭"
            }
        ]
    },
    
    "organization": {
        "easy": [
            {
                "name": "10-Item Declutter",
                "description": "Find exactly 10 unnecessary items and remove them from your space",
                "instructions": "Choose any area, identify exactly 10 items that don't belong or aren't needed, remove them.",
                "tips": "Start with obvious clutter like old papers, broken items, or duplicates!",
                "estimated_impact": "Medium - creates immediate visual improvement",
                "emoji": "🗂️"
            },
            {
                "name": "Marie Kondo Speedrun",
                "description": "Apply 'does it spark joy?' to 20 items in 20 minutes",
                "instructions": "Set timer for 20 minutes, touch 20 items, ask the question, keep or donate based on answer.",
                "tips": "Trust your gut reaction - the first feeling is usually right!",
                "estimated_impact": "Medium-High - creates mindful relationship with possessions",
                "emoji": "✨"
            },
            {
                "name": "Digital Desktop Detox",
                "description": "Organize computer desktop, downloads folder, and phone home screen",
                "instructions": "Clear desktop to zero files, organize downloads into folders, arrange phone apps logically.",
                "tips": "Create folders named by action: 'To Read', 'To Process', 'Archive'",
                "estimated_impact": "High - improves digital productivity immediately",
                "emoji": "💻"
            }
        ],
        "medium": [
            {
                "name": "5S Sensei",
                "description": "Apply Japanese 5S methodology (Sort, Straighten, Shine, Standardize, Sustain) to your workspace",
                "instructions": "Sort (remove unnecessary), Straighten (arrange logically), Shine (clean), Standardize (create system), Sustain (maintain).",
                "tips": "Focus on one S per hour for a systematic transformation!",
                "estimated_impact": "Very High - creates professional-grade organization",
                "emoji": "🎌"
            },
            {
                "name": "Feng Shui Flow",
                "description": "Rearrange your workspace for optimal energy flow according to feng shui principles",
                "instructions": "Clear pathways, position desk to see entrance, add plants, remove clutter from corners.",
                "tips": "Even small changes can dramatically improve how the space feels!",
                "estimated_impact": "Medium-High - improves workspace energy and mood",
                "emoji": "🌿"
            },
            {
                "name": "System Documentation Day",
                "description": "Document 3 processes you do regularly but have never written down",
                "instructions": "Pick recurring activities (morning routine, weekly review, etc.) and create step-by-step guides.",
                "tips": "Future you will thank present you for these clear instructions!",
                "estimated_impact": "Very High - creates reusable systems for efficiency",
                "emoji": "📋"
            }
        ]
    },
    
    "wellness": {
        "easy": [
            {
                "name": "Hydration Hero",
                "description": "Drink a full glass of water before starting every new task",
                "instructions": "Keep water bottle nearby, drink before task transitions. Track your increased hydration!",
                "tips": "You'll be amazed how much better you feel and think!",
                "estimated_impact": "High - improves energy and cognitive function",
                "emoji": "💧"
            },
            {
                "name": "Gratitude Bomber",
                "description": "Send genuine appreciation messages to 3 different people throughout the day",
                "instructions": "Text, email, or call 3 people to specifically thank them for something meaningful.",
                "tips": "Be specific about what you appreciate - it means more!",
                "estimated_impact": "Very High - improves relationships and personal mood",
                "emoji": "🙏"
            },
            {
                "name": "Deep Breathing Boss",
                "description": "Take 3 conscious deep breaths before starting any difficult or stressful task",
                "instructions": "Pause, breathe in for 4 counts, hold for 4, out for 4. Three times before hard tasks.",
                "tips": "Creates space between trigger and reaction, improves decision making!",
                "estimated_impact": "High - reduces stress and improves task approach",
                "emoji": "🫁"
            }
        ],
        "medium": [
            {
                "name": "Standing Desk Warrior",
                "description": "Do ALL computer work while standing up today",
                "instructions": "Create standing workspace (books to raise laptop, etc.). Take sitting breaks for eating only.",
                "tips": "Start with shorter sessions if new to standing work!",
                "estimated_impact": "High - improves posture, energy, and alertness",
                "emoji": "🚶"
            },
            {
                "name": "Pomodoro Power Walker",
                "description": "Take a 5-10 minute walk during every break between focused work sessions",
                "instructions": "Work for 25 minutes, walk for 5-10 minutes, repeat. Get outside if possible!",
                "tips": "Even indoor pacing counts - movement is the key!",
                "estimated_impact": "Very High - combines productivity with physical activity",
                "emoji": "🚶‍♀️"
            },
            {
                "name": "Natural Light Seeker",
                "description": "Work near windows or outside whenever possible today",
                "instructions": "Move laptop to window spot, take calls outside, do paperwork in natural light.",
                "tips": "Natural light dramatically improves mood and alertness!",
                "estimated_impact": "High - improves mood, sleep, and vitamin D",
                "emoji": "☀️"
            }
        ]
    },
    
    "learning": {
        "easy": [
            {
                "name": "Question Quest",
                "description": "Ask 'why?' or 'how could this be better?' for every single task today",
                "instructions": "Before and after each task, genuinely ask these questions. Document interesting insights.",
                "tips": "You'll discover improvement opportunities everywhere!",
                "estimated_impact": "High - develops critical thinking and improvement mindset",
                "emoji": "❓"
            },
            {
                "name": "15-Minute Skill Sampler",
                "description": "Spend exactly 15 minutes learning something completely new and random",
                "instructions": "Pick skill unrelated to work (origami, language, instrument) and explore for 15 focused minutes.",
                "tips": "YouTube University is perfect for this - lots of 15-minute tutorials!",
                "estimated_impact": "Medium-High - exercises learning muscles and creativity",
                "emoji": "🎓"
            }
        ],
        "medium": [
            {
                "name": "Wikipedia Wanderer",
                "description": "Learn about something completely random and find a way to apply it to your work",
                "instructions": "Click Wikipedia random article, learn about it, then creatively connect it to current projects.",
                "tips": "The more random the connection, the more creative thinking you exercise!",
                "estimated_impact": "Medium - expands knowledge and creative thinking",
                "emoji": "📚"
            },
            {
                "name": "Teaching Tuesday",
                "description": "Explain your productivity approach or a work skill to someone else today",
                "instructions": "Find someone (colleague, friend, family) and teach them something you know well.",
                "tips": "Teaching reveals gaps in your own understanding and reinforces learning!",
                "estimated_impact": "Very High - deepens understanding and helps others",
                "emoji": "👨‍🏫"
            }
        ]
    }
}

# Seasonal challenge modifications
SEASONAL_MODIFICATIONS = {
    "halloween": {
        "prefix_phrases": ["Spooky", "Haunted", "Ghostly", "Phantom", "Witch's"],
        "task_words": {"task": "haunting", "project": "curse", "completion": "exorcism"},
        "special_challenges": [
            {
                "name": "Ghost Hunter Mode",
                "description": "Eliminate tasks that have been 'haunting' your list the longest",
                "instructions": "Identify your oldest, most avoided tasks and 'exorcise' them today!",
                "emoji": "👻"
            }
        ]
    },
    "christmas": {
        "prefix_phrases": ["Festive", "Jolly", "Merry", "Santa's", "Elf"],
        "task_words": {"task": "present", "project": "Christmas miracle", "completion": "gift delivery"},
        "special_challenges": [
            {
                "name": "Elf Mode Productivity", 
                "description": "Help others complete their tasks before focusing on your own",
                "instructions": "Be Santa's helper - assist colleagues, family, or friends with their to-dos first!",
                "emoji": "🎅"
            }
        ]
    },
    "spring": {
        "prefix_phrases": ["Blooming", "Fresh", "Growing", "Renewal", "Garden"],
        "task_words": {"task": "seed", "project": "garden", "completion": "harvest"},
        "special_challenges": [
            {
                "name": "Growth Mode Challenge",
                "description": "Start three completely new habits, projects, or learning goals",
                "instructions": "Like planting seeds - start small but commit to nurturing them daily!",
                "emoji": "🌱"
            }
        ]
    }
}

def apply_seasonal_modification(challenge: Dict[str, Any], season: str) -> Dict[str, Any]:
    """Apply seasonal modifications to a base challenge."""
    if season not in SEASONAL_MODIFICATIONS:
        return challenge
    
    modifications = SEASONAL_MODIFICATIONS[season]
    modified_challenge = challenge.copy()
    
    # Add seasonal prefix to name
    if "prefix_phrases" in modifications:
        prefix = random.choice(modifications["prefix_phrases"])
        modified_challenge["name"] = f"{prefix} {challenge['name']}"
    
    # Modify description with seasonal vocabulary
    if "task_words" in modifications:
        description = challenge["description"]
        for old_word, new_word in modifications["task_words"].items():
            description = description.replace(old_word, new_word)
        modified_challenge["description"] = description
    
    return modified_challenge

def get_challenge_history() -> List[Dict[str, Any]]:
    """Load challenge completion history."""
    history_file = get_challenges_data_dir() / "history.json"
    
    if not history_file.exists():
        return []
    
    try:
        with open(history_file, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return []

def save_challenge_to_history(challenge: Dict[str, Any], completed: bool = False) -> None:
    """Save challenge to history."""
    history = get_challenge_history()
    
    history_entry = {
        "challenge": challenge,
        "date": date.today().isoformat(),
        "completed": completed,
        "timestamp": datetime.now().isoformat()
    }
    
    history.append(history_entry)
    
    # Keep only last 30 days
    cutoff_date = date.today() - timedelta(days=30)
    history = [h for h in history if datetime.fromisoformat(h["date"]).date() >= cutoff_date]
    
    history_file = get_challenges_data_dir() / "history.json"
    with open(history_file, 'w') as f:
        json.dump(history, f, indent=2)

def get_recent_challenge_types(days: int = 7) -> List[str]:
    """Get types of challenges completed in recent days."""
    history = get_challenge_history()
    cutoff_date = date.today() - timedelta(days=days)
    
    recent_categories = []
    for entry in history:
        entry_date = datetime.fromisoformat(entry["date"]).date()
        if entry_date >= cutoff_date:
            # Extract category from challenge (this is simplified - could be more sophisticated)
            challenge_name = entry["challenge"]["name"].lower()
            if any(word in challenge_name for word in ["pirate", "story", "color", "emoji"]):
                recent_categories.append("creativity")
            elif any(word in challenge_name for word in ["organize", "declutter", "clean"]):
                recent_categories.append("organization")
            elif any(word in challenge_name for word in ["standing", "walk", "hydration", "breathing"]):
                recent_categories.append("wellness")
            elif any(word in challenge_name for word in ["learn", "skill", "teach", "question"]):
                recent_categories.append("learning")
            else:
                recent_categories.append("productivity")
    
    return recent_categories

def smart_challenge_selection(challenge_type: Optional[str] = None, difficulty: str = "medium") -> Dict[str, Any]:
    """Intelligently select a challenge based on context and history."""
    context = get_day_context()
    recent_types = get_recent_challenge_types()
    
    # Determine challenge type if not specified
    if not challenge_type:
        # Avoid recently used types
        available_types = [t for t in CHALLENGE_DATABASE.keys() if t not in recent_types[-3:]]
        
        if not available_types:
            available_types = list(CHALLENGE_DATABASE.keys())
        
        # Monday motivation
        if context["is_monday"]:
            challenge_type = "productivity" if "productivity" in available_types else random.choice(available_types)
        # Friday fun
        elif context["is_friday"]:
            challenge_type = "creativity" if "creativity" in available_types else random.choice(available_types)
        # Weekend wellness
        elif context["is_weekend"]:
            challenge_type = "wellness" if "wellness" in available_types else random.choice(available_types)
        else:
            challenge_type = random.choice(available_types)
    
    # Select from appropriate difficulty level
    if difficulty not in CHALLENGE_DATABASE[challenge_type]:
        difficulty = "medium"  # Fallback to medium if difficulty not available
    
    challenges = CHALLENGE_DATABASE[challenge_type][difficulty]
    base_challenge = random.choice(challenges)
    
    # Apply seasonal modifications
    challenge = apply_seasonal_modification(base_challenge, context["season"])
    
    # Add metadata
    challenge.update({
        "category": challenge_type,
        "difficulty": difficulty,
        "date_generated": date.today().isoformat(),
        "season": context["season"],
        "day_context": context
    })
    
    return challenge

def get_persona_presentation(challenge: Dict[str, Any]) -> str:
    """Get persona-appropriate presentation of the challenge."""
    category = challenge.get("category", "productivity")
    season = challenge.get("season", "regular")
    
    # Select presenter persona based on challenge type
    if category == "creativity":
        presenter = "🎪 Chaos Gremlin"
        intro = f"OOH! EXCITING CHALLENGE TIME! Today's creative chaos mission is {challenge['emoji']} **{challenge['name']}**!"
        encouragement = "PLOT TWIST! This is going to make your day MAGNIFICENTLY unpredictable! Embrace the beautiful chaos!"
    elif category == "organization":
        presenter = "🏠 Cozy Hobbit" 
        intro = f"Ah, a lovely organizing adventure awaits! Today's cozy mission: {challenge['emoji']} **{challenge['name']}**"
        encouragement = "Even small steps create beautiful, peaceful spaces. You'll feel so much better afterward, dear!"
    elif category == "wellness":
        presenter = "🤖 Zen Robot"
        intro = f"Processing wellness optimization... Today's health protocol: {challenge['emoji']} **{challenge['name']}**"
        encouragement = "System analysis indicates 94% probability of improved well-being. Initiating self-care subroutines..."
    elif category == "learning":
        presenter = "🎮 Quest Master"
        intro = f"⭐ NEW KNOWLEDGE QUEST AVAILABLE! Today's learning adventure: {challenge['emoji']} **{challenge['name']}**"
        encouragement = "Every skill point earned makes you more powerful! This quest will unlock new abilities!"
    else:  # productivity
        presenter = "📣 Hype Squad Captain"
        intro = f"🏆 CHALLENGE ACCEPTED! Today's productivity championship event: {challenge['emoji']} **{challenge['name']}**!"
        encouragement = "YOU'VE GOT THIS, CHAMPION! TIME TO SHOW THAT TO-DO LIST WHO'S THE REAL PRODUCTIVITY SUPERHERO!"
    
    # Seasonal adjustments
    if season == "halloween":
        intro = intro.replace("mission", "spooky mission").replace("adventure", "haunted adventure")
    elif season == "christmas":
        intro = intro.replace("mission", "Christmas mission").replace("adventure", "festive adventure")
        encouragement += " Ho ho ho!"
    
    return f"""
{intro}

📋 **Challenge:** {challenge['description']}

🎯 **Your Mission:** {challenge['instructions']}

💡 **Pro Tip:** {challenge['tips']}

⚡ **Expected Impact:** {challenge['estimated_impact']}

💬 **{presenter}:** "{encouragement}"

🏆 **Difficulty:** {challenge['difficulty'].title()} | **Category:** {challenge['category'].title()}
"""

def mark_challenge_complete(challenge_id: str, success: bool = True) -> str:
    """Mark a challenge as complete and generate celebration."""
    # In a real implementation, you'd load the specific challenge by ID
    # For now, we'll generate a generic celebration
    
    if success:
        celebrations = [
            "🎉 CHALLENGE CONQUERED! 🎉\n\n🏆 You absolutely CRUSHED it! Your productivity powers have grown stronger!",
            "⚡ LEGENDARY PERFORMANCE! ⚡\n\n🌟 Challenge complete! You've unlocked new levels of awesome!",
            "🎊 MISSION ACCOMPLISHED! 🎊\n\n💪 Outstanding work! Your determination paid off in epic fashion!"
        ]
        
        persona_reactions = [
            "🎪 Chaos Gremlin: 'MAGNIFICENT CHAOS MASTERY! You turned challenge into BEAUTIFUL VICTORY!'",
            "📣 Hype Squad: 'CHAMPION-LEVEL PERFORMANCE! THE CROWD GOES ABSOLUTELY WILD!'",
            "🏠 Cozy Hobbit: 'Well done, dear! You should feel proud of this lovely accomplishment!'",
            "🤖 Zen Robot: 'Challenge completion algorithm successful. Productivity levels optimized. Well executed.'",
            "🎮 Quest Master: '⭐ QUEST COMPLETE! +200 XP earned! Your character has grown stronger!'"
        ]
        
        celebration = random.choice(celebrations)
        reaction = random.choice(persona_reactions)
        
        return f"{celebration}\n\n{reaction}\n\n🎯 **Tomorrow brings a new adventure!**"
    
    else:
        encouragements = [
            "💙 No worries! Challenges are meant to stretch us - you still learned something valuable!",
            "🌟 Every attempt makes you stronger! The real victory is in trying new approaches!",
            "🎯 Challenge incomplete, but effort complete! You're building resilience and courage!"
        ]
        
        return f"{random.choice(encouragements)}\n\n💡 **Tomorrow's challenge will be perfectly suited for you!**"

def main():
    """Main CLI interface for daily challenges."""
    if len(sys.argv) < 2:
        print("Usage: python challenge_generator.py <action> [arguments...]")
        print("Actions: generate, complete, history, suggest")
        return
    
    action = sys.argv[1]
    
    if action == "generate":
        # Parse optional arguments
        challenge_type = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] != "random" else None
        difficulty = sys.argv[3] if len(sys.argv) > 3 else "medium"
        
        # Generate challenge
        challenge = smart_challenge_selection(challenge_type, difficulty)
        
        # Save to history (as generated, not completed)
        save_challenge_to_history(challenge, completed=False)
        
        # Display with persona presentation
        print("🎲 **DAILY CHALLENGE GENERATED!** 🎲")
        print(get_persona_presentation(challenge))
        
        print(f"\n📅 **Generated for:** {challenge['date_generated']}")
        print(f"🌟 **Season:** {challenge['season'].title()} theme active")
        
    elif action == "complete":
        challenge_id = sys.argv[2] if len(sys.argv) > 2 else "today"
        success = sys.argv[3].lower() == "true" if len(sys.argv) > 3 else True
        
        celebration = mark_challenge_complete(challenge_id, success)
        print(celebration)
        
    elif action == "history":
        history = get_challenge_history()
        
        if not history:
            print("📋 **No challenge history found**")
            print("💡 Generate your first challenge with: python challenge_generator.py generate")
            return
        
        print(f"📊 **Challenge History** (Last {len(history)} challenges)\n")
        
        for entry in history[-10:]:  # Show last 10
            challenge = entry["challenge"]
            status = "✅ Completed" if entry["completed"] else "📝 Generated"
            
            print(f"{challenge['emoji']} **{challenge['name']}** - {entry['date']}")
            print(f"   {status} | {challenge['difficulty'].title()} {challenge['category'].title()}")
            print(f"   {challenge['description'][:80]}...")
            print()
    
    elif action == "suggest":
        # Show what challenge would be generated without actually generating it
        context = get_day_context()
        recent_types = get_recent_challenge_types()
        
        print(f"🎯 **Challenge Suggestion for {context['day_name']}**\n")
        print(f"🌟 **Current season:** {context['season'].title()}")
        print(f"📊 **Recent challenge types:** {', '.join(recent_types[-3:]) if recent_types else 'None'}")
        
        # Generate suggestion
        suggestion = smart_challenge_selection()
        
        print(f"\n💡 **Suggested Challenge:**")
        print(f"{suggestion['emoji']} **{suggestion['name']}**")
        print(f"   Category: {suggestion['category'].title()} | Difficulty: {suggestion['difficulty'].title()}")
        print(f"   {suggestion['description']}")
        
        print(f"\n🎲 **Generate this challenge with:** python challenge_generator.py generate")
    
    else:
        print(f"❌ Unknown action: {action}")
        print("Available actions: generate, complete, history, suggest")

if __name__ == "__main__":
    main()