#!/usr/bin/env python3
"""
Seasonal Persona Themes - Transform personas into seasonal variants
"""

import json
import os
import sys
from datetime import datetime, date
from pathlib import Path
from typing import Dict, List, Optional, Any

# Add persona helper to path
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))

def get_seasonal_data_dir() -> Path:
    """Get directory for storing seasonal theme data."""
    data_dir = Path.home() / "Documents" / "gtd" / ".seasonal_themes"
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir

def detect_current_season() -> str:
    """Auto-detect current season based on date."""
    today = date.today()
    month = today.month
    day = today.day
    
    # Halloween (October)
    if month == 10:
        return "halloween"
    
    # Christmas season (December)
    elif month == 12:
        return "christmas"
    
    # New Year (January)
    elif month == 1:
        return "new_year"
    
    # Valentine's Day (February)
    elif month == 2 and day <= 18:
        return "valentine"
    
    # Spring (March-May)
    elif month in [3, 4, 5]:
        # Easter (approximate - first Sunday after first full moon after spring equinox)
        if month == 3 and day >= 15 or month == 4 and day <= 25:
            return "easter"
        return "spring"
    
    # Summer (June-August) 
    elif month in [6, 7, 8]:
        return "summer"
    
    # Thanksgiving (November)
    elif month == 11:
        return "thanksgiving"
    
    # Winter (December-February, but not holidays)
    else:
        return "winter"

SEASONAL_THEMES = {
    "halloween": {
        "name": "🎃 Halloween Spooky Fun",
        "description": "Spooky, mysterious, and playfully scary productivity",
        "colors": ["orange", "black", "purple"],
        "emojis": ["🎃", "👻", "🦇", "🕷️", "⚡"],
        "vocabulary": {
            "task": "spooky mission", "project": "haunted campaign", "completion": "exorcism",
            "focus": "ghost hunting", "break": "séance", "review": "ghost story"
        }
    },
    "christmas": {
        "name": "🎄 Christmas Joy & Magic", 
        "description": "Festive, warm, generous, and magically productive",
        "colors": ["red", "green", "gold"],
        "emojis": ["🎄", "🎅", "🎁", "❄️", "⭐"],
        "vocabulary": {
            "task": "Christmas present", "project": "holiday workshop", "completion": "gift delivery",
            "focus": "elf magic", "break": "cocoa time", "review": "Santa's nice list"
        }
    },
    "spring": {
        "name": "🌸 Spring Renewal & Growth",
        "description": "Fresh, growing, optimistic, and naturally productive", 
        "colors": ["green", "pink", "yellow"],
        "emojis": ["🌸", "🌱", "🦋", "☀️", "🌿"],
        "vocabulary": {
            "task": "seed to plant", "project": "garden cultivation", "completion": "harvest",
            "focus": "photosynthesis", "break": "rain shower", "review": "growth assessment"
        }
    },
    "summer": {
        "name": "☀️ Summer Adventure & Energy",
        "description": "Energetic, adventurous, bright, and dynamically productive",
        "colors": ["yellow", "blue", "orange"], 
        "emojis": ["☀️", "🏖️", "⛺", "🌊", "🦋"],
        "vocabulary": {
            "task": "adventure quest", "project": "expedition", "completion": "summit reached",
            "focus": "exploration", "break": "base camp rest", "review": "trail reflection"
        }
    },
    "winter": {
        "name": "❄️ Winter Cozy & Clarity",
        "description": "Cozy, contemplative, crisp, and crystalline productivity",
        "colors": ["white", "blue", "silver"],
        "emojis": ["❄️", "🏔️", "🔥", "🧣", "⭐"],
        "vocabulary": {
            "task": "winter preparation", "project": "hibernation plan", "completion": "spring readiness",
            "focus": "fireplace meditation", "break": "snow day", "review": "winter reflection"
        }
    },
    "valentine": {
        "name": "💝 Valentine Self-Love & Care",
        "description": "Loving, caring, gentle, and self-compassionate productivity",
        "colors": ["pink", "red", "white"],
        "emojis": ["💝", "💕", "🌹", "💖", "✨"],
        "vocabulary": {
            "task": "act of self-love", "project": "caring campaign", "completion": "heart gift",
            "focus": "loving attention", "break": "self-care moment", "review": "gratitude practice"
        }
    },
    "new_year": {
        "name": "🎊 New Year Fresh Starts",
        "description": "Fresh, determined, hopeful, and resolution-focused productivity",
        "colors": ["gold", "silver", "blue"],
        "emojis": ["🎊", "🎯", "⭐", "🚀", "✨"],
        "vocabulary": {
            "task": "resolution step", "project": "transformation quest", "completion": "goal achieved",
            "focus": "new year energy", "break": "momentum pause", "review": "progress celebration"
        }
    },
    "easter": {
        "name": "🐰 Easter Renewal & Discovery",
        "description": "Hopeful, playful, discovery-focused, and renewal-themed productivity",
        "colors": ["pastel pink", "yellow", "green"],
        "emojis": ["🐰", "🥚", "🌷", "🌱", "🎊"],
        "vocabulary": {
            "task": "easter egg hunt", "project": "spring awakening", "completion": "egg discovered",
            "focus": "bunny hop energy", "break": "nest building", "review": "spring counting"
        }
    },
    "thanksgiving": {
        "name": "🦃 Thanksgiving Gratitude & Harvest",
        "description": "Grateful, abundant, reflective, and appreciative productivity",
        "colors": ["orange", "brown", "gold"],
        "emojis": ["🦃", "🍂", "🌽", "🥧", "🙏"],
        "vocabulary": {
            "task": "gratitude practice", "project": "harvest gathering", "completion": "thanksgiving feast",
            "focus": "appreciation meditation", "break": "blessing count", "review": "gratitude reflection"
        }
    }
}

PERSONA_SEASONAL_VARIANTS = {
    "chaos_gremlin": {
        "halloween": {
            "name": "Halloween Chaos Trickster",
            "additions": "You're extra spooky and mischievous for Halloween! Add phrases like 'BOO!', 'SPOOKY PLOT TWIST!', 'haunted by procrastination', 'exorcise tasks with CHAOS ENERGY!', 'trick or treat - trick the boring task or treat yourself after!', and 'ghostly creative spirits'. Make everything delightfully spooky while maintaining your chaotic creativity.",
        },
        "christmas": {
            "name": "Christmas Chaos Elf", 
            "additions": "You're a festive Christmas elf full of holiday chaos! Add phrases like 'HO HO CHAOS!', 'Christmas magic EVERYWHERE!', 'festive mayhem', 'jingle bells and creative spells', 'Santa's favorite chaotic helper', and 'present-wrapping plot twists'. Make productivity feel like Christmas morning excitement.",
        },
        "spring": {
            "name": "Spring Chaos Sprite",
            "additions": "You're a playful spring sprite bursting with growth energy! Add phrases like 'SPRING CHAOS!', 'everything's growing everywhere!', 'let's plant creative ideas randomly!', 'blossom with possibility', 'pollination plot twists', and 'flower power creativity'. Make tasks feel like they're blooming with potential.",
        },
        "valentine": {
            "name": "Cupid Chaos Gremlin",
            "additions": "You're Cupid's chaotic assistant spreading productivity love! Add phrases like 'LOVE CHAOS!', 'Cupid's arrow of creativity strikes!', 'organize tasks by what we LOVE about them', 'love makes even spreadsheets exciting', and 'romantic plot twists'. Pair boring tasks with things they love.",
        }
    },
    
    "cozy_hobbit": {
        "halloween": {
            "name": "Harvest Hobbit",
            "additions": "You embrace autumn's cozy spookiness! Add phrases about 'autumn magic', 'cozy harvest time', 'spooky fun for hobbits too', 'candlelight productivity', 'mysteriously disappearing to-do lists', and 'halloween treats between tasks'. Stay cozy but add gentle autumn and light spooky themes.",
        },
        "christmas": {
            "name": "Christmas Elf Hobbit",
            "additions": "You're Santa's coziest workshop elf! Add phrases like 'Ho ho ho!', 'gifts to your future self', 'Christmas workshop productivity', 'wrap up tasks with care', 'productivity tree presents', and 'cheerful organized Christmas energy'. Make everything feel like gift-giving to future self.",
        },
        "spring": {
            "name": "Garden Hobbit",
            "additions": "You're a gardening hobbit who loves growing things! Add phrases about 'planting seeds of habits', 'garden of productivity', 'fresh spring starts', 'growing routines', 'seedlings becoming mighty', and 'patient care like gardening'. Make productivity feel like tending a beautiful garden.",
        },
        "winter": {
            "name": "Winter Hygge Hobbit", 
            "additions": "You're the master of winter coziness! Add phrases about 'winter's embrace', 'cozy productivity by fireplace', 'hot cocoa and organized spaces', 'gentle progress like snowflakes', 'hibernation comfort', and 'winter's quiet productivity'. Emphasize maximum comfort and hygge vibes.",
        },
        "valentine": {
            "name": "Love & Care Hobbit",
            "additions": "You focus on self-love and caring productivity! Add phrases about 'love letters to future self', 'self-care productivity', 'treating yourself with kindness', 'organized spaces as self-love', and 'gentle loving progress'. Make every task feel like an act of self-care.",
        }
    },
    
    "time_wizard": {
        "halloween": {
            "name": "Autumn Sorcerer",
            "additions": "Your time magic becomes mystically spooky! Add phrases like 'mystical October timestreams', 'Jack-o'-Lantern Focus Enchantments', 'veil between procrastination and productivity grows thin', 'banishing delay demons', and 'spooky productivity spells'. Make time management feel like dark magic (but helpful!).",
        },
        "christmas": {
            "name": "Christmas Time Wizard",
            "additions": "Your magic sparkles with Christmas joy! Add phrases like 'Christmas timestreams sparkle', 'Candy Cane Focus Spells', 'sleigh bells signal perfect timing', 'Christmas magic flows through schedules', 'Ho ho ho time enchantments', and 'holiday productivity spells'. Make scheduling feel magical and festive.",
        },
        "spring": {
            "name": "Nature Time Wizard",
            "additions": "Your magic flows with natural growth cycles! Add phrases about 'spring timestreams bring renewal magic', 'Cherry Blossom Focus Spells', 'earth awakening productivity potential', 'growth magic activated', and 'natural timing wisdom'. Align time management with natural rhythms.",
        },
        "summer": {
            "name": "Solar Time Mage",
            "additions": "Your magic is powered by summer sun! Add phrases about 'summer sun charging time magic', 'solar-powered focus spells', 'endless daylight energy', 'sunlight timestreams', 'adventure timing magic', and 'solar calendar enchantments'. Make scheduling feel bright and energetic.",
        },
        "new_year": {
            "name": "Resolution Wizard",
            "additions": "Your magic specializes in fresh starts and transformations! Add phrases about 'New Year timestreams sparkle with possibility', 'Resolution Enchantments', 'calendar reset magic', 'fresh start spells', 'transformation time magic', and 'midnight momentum spells'. Focus on new beginnings.",
        }
    },
    
    "hype_squad": {
        "christmas": {
            "name": "Santa's Hype Elf",
            "additions": "You're Santa's most enthusiastic cheerleader! Add phrases like 'HO HO HOLY PRODUCTIVITY!', 'SANTA'S FAVORITE ELF!', 'JINGLE BELLS TASK CHAMPION!', 'DECK THE HALLS WITH COMPLETED TASKS!', 'FA-LA-LA-LA-LEGENDARY!', and Christmas celebration energy. Make every win feel like Christmas morning.",
        },
        "summer": {
            "name": "Beach Hype Squad",
            "additions": "You're radiating summer beach energy! Add phrases like 'SUMMER VIBES!', 'CRUSHING IT LIKE WAVES ON BEACH!', 'SUNSHINE PRODUCTIVITY!', 'SIZZLING WITH SUCCESS!', 'VACATION ENERGY TASKS!', and 'BEACH CHAMPION PERFORMANCE!'. Make everything feel like a summer celebration.",
        },
        "new_year": {
            "name": "New Year Hype Captain",
            "additions": "You're pumped about fresh starts and resolutions! Add phrases like 'NEW YEAR NEW YOU!', 'RESOLUTION CHAMPION!', 'THIS IS YOUR YEAR!', 'MIDNIGHT MOMENTUM!', 'STARTING STRONG STAYING LEGENDARY!', and 'CALENDAR RESET CELEBRATION!'. Channel pure New Year motivation.",
        },
        "valentine": {
            "name": "Love Hype Cheerleader",
            "additions": "You celebrate self-love and caring achievements! Add phrases like 'SELF-LOVE CHAMPION!', 'VALENTINE VICTORY!', 'HEART-WARMING PERFORMANCE!', 'SWEETEST TASK COMPLETION!', 'LOVE YOUR PRODUCTIVITY!', and loving celebration energy. Make every win feel like a valentine.",
        }
    },
    
    "zen_robot": {
        "halloween": {
            "name": "Gothic Zen Android",
            "additions": "Your systems embrace spooky aesthetics while staying zen! Add phrases like 'Error 666: Spooky vibes detected', 'Installing pumpkin spice optimization', 'Gothic mode activated', 'friendly ghosts debugging stress', 'candlelight.dll installed', and mystical but calming technology references.",
        },
        "christmas": {
            "name": "Holiday Zen Bot",
            "additions": "Your systems run on Christmas peace and joy! Add phrases about 'Installing holiday cheer protocols', 'Christmas peace algorithms', 'festive zen mode activated', 'running on cocoa and kindness', 'holiday harmony optimization', and 'spreading digital Christmas calm'.",
        },
        "spring": {
            "name": "Eco Zen Android",
            "additions": "Your systems harmonize with natural growth! Add phrases about 'Installing growth.exe and renewal protocols', 'stress composted into fertile motivation', 'running on sustainable productivity energy', 'eco-mode activated', 'fresh air algorithms', and nature-tech harmony.",
        },
        "summer": {
            "name": "Beach Zen Bot",
            "additions": "Your systems run on solar power and ocean vibes! Add phrases about 'Installing vitamin-D boost', 'beach-mode relaxation protocols', 'solar power algorithms', 'ocean breeze optimization', 'productivity flowing like waves', and 'summer zen efficiency'.",
        },
        "winter": {
            "name": "Cozy Zen Android",
            "additions": "Your systems optimize for winter comfort and clarity! Add phrases about 'Installing hibernation efficiency', 'cozy algorithms activated', 'fireplace warmth protocols', 'snow-meditation subroutines', and 'crystalline winter clarity processing'.",
        }
    },
    
    "questmaster": {
        "halloween": {
            "name": "Spooky Dungeon Master",
            "additions": "You turn productivity into spooky adventures! Add phrases like 'SPOOKY QUEST ALERT!', 'Halloween Boss Battles', 'Procrastination Phantom possessed your inbox', 'Ghost Buster achievements', 'vanquish the Deadline Demon', and 'haunted quest rewards'. Make tasks feel like supernatural adventures.",
        },
        "christmas": {
            "name": "Santa's Quest Coordinator",
            "additions": "You organize Christmas productivity missions! Add phrases like 'CHRISTMAS QUEST available', 'Ho ho ho new missions', 'Nice List achievements', 'North Pole Workshop needs help', 'deliver productivity presents', and 'Christmas magic XP bonuses'. Make tasks feel like helping Santa.",
        },
        "summer": {
            "name": "Adventure Expedition Guide",
            "additions": "You lead summer productivity adventures! Add phrases like 'SUMMER EXPEDITION QUEST', 'base camp productivity', 'conquer tasks before sunset', 'morning adventure briefing', 'Email Valley expedition', and 'outdoor quest rewards'. Make tasks feel like outdoor adventures.",
        },
        "new_year": {
            "name": "Resolution Quest Master",
            "additions": "You guide New Year transformation quests! Add phrases like 'NEW YEAR NEW QUESTS!', 'character sheet updated for new year', 'Annual Quest Chain Activated', 'Resolution Boss Battles', 'hero of your own story', and 'transformation XP'. Focus on personal growth adventures.",
        }
    }
}

def get_seasonal_persona_variant(persona_id: str, season: str) -> Optional[Dict[str, str]]:
    """Get seasonal variant for a specific persona."""
    return PERSONA_SEASONAL_VARIANTS.get(persona_id, {}).get(season)

def apply_seasonal_theme(persona_id: str, season: str, base_prompt: str) -> str:
    """Apply seasonal theme to a persona's system prompt."""
    variant = get_seasonal_persona_variant(persona_id, season)
    if not variant:
        return base_prompt
    
    # Add seasonal modifications to the base prompt
    seasonal_prompt = f"{base_prompt}\n\n🎭 SEASONAL THEME - {variant['name']}: {variant['additions']}"
    
    return seasonal_prompt

def get_seasonal_vocabulary(season: str) -> Dict[str, str]:
    """Get seasonal vocabulary replacements."""
    return SEASONAL_THEMES.get(season, {}).get("vocabulary", {})

def get_seasonal_decorations(season: str) -> List[str]:
    """Get seasonal emojis and decorations.""" 
    theme = SEASONAL_THEMES.get(season, {})
    return theme.get("emojis", ["✨"])

def save_active_theme(season: str, personas: Optional[List[str]] = None) -> None:
    """Save currently active seasonal theme."""
    theme_file = get_seasonal_data_dir() / "active_theme.json"
    
    theme_data = {
        "season": season,
        "personas": personas or "all", 
        "activated_at": datetime.now().isoformat(),
        "auto_detected": season == detect_current_season()
    }
    
    with open(theme_file, 'w') as f:
        json.dump(theme_data, f, indent=2)

def load_active_theme() -> Optional[Dict[str, Any]]:
    """Load currently active seasonal theme."""
    theme_file = get_seasonal_data_dir() / "active_theme.json"
    
    if not theme_file.exists():
        return None
        
    try:
        with open(theme_file, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return None

def clear_active_theme() -> None:
    """Clear/deactivate seasonal themes."""
    theme_file = get_seasonal_data_dir() / "active_theme.json"
    if theme_file.exists():
        theme_file.unlink()

def format_seasonal_display(season: str) -> str:
    """Format seasonal theme information for display."""
    theme = SEASONAL_THEMES.get(season, {})
    if not theme:
        return f"❓ Unknown season: {season}"
    
    emojis = " ".join(theme.get("emojis", ["✨"])[:3])
    
    return f"""
🎭 **{theme['name']}**
   {emojis} {theme['description']}
   
🎨 **Theme Colors:** {', '.join(theme.get('colors', ['default']))}
🎪 **Available Personas:** {len(PERSONA_SEASONAL_VARIANTS)} personas with {season} variants
🎯 **Vocabulary:** {len(theme.get('vocabulary', {}))} themed word replacements
"""

def list_available_themes() -> str:
    """List all available seasonal themes."""
    output = "🎭 **Available Seasonal Themes:**\n\n"
    
    current_season = detect_current_season()
    
    for season_id, theme in SEASONAL_THEMES.items():
        current_marker = " 🌟 (CURRENT)" if season_id == current_season else ""
        emojis = " ".join(theme.get("emojis", ["✨"])[:2])
        
        output += f"{emojis} **{season_id}** - {theme['name']}{current_marker}\n"
        output += f"   {theme['description']}\n\n"
    
    return output

def main():
    """Main CLI interface for seasonal themes."""
    if len(sys.argv) < 2:
        print("Usage: python seasonal_themes.py <action> [arguments...]")
        print("Actions: detect, set, get, list, clear, apply")
        return
    
    action = sys.argv[1]
    
    if action == "detect":
        season = detect_current_season()
        theme = SEASONAL_THEMES[season]
        print(f"🎭 **Auto-detected season:** {season}")
        print(format_seasonal_display(season))
    
    elif action == "set":
        if len(sys.argv) < 3:
            print("Usage: python seasonal_themes.py set <season> [personas...]")
            return
        
        season = sys.argv[2]
        personas = sys.argv[3:] if len(sys.argv) > 3 else None
        
        if season not in SEASONAL_THEMES and season != "auto":
            print(f"❌ Unknown season: {season}")
            print("Available seasons:", ", ".join(SEASONAL_THEMES.keys()) + ", auto")
            return
        
        if season == "auto":
            season = detect_current_season()
        
        save_active_theme(season, personas)
        print(f"✅ **Seasonal theme activated:** {season}")
        print(format_seasonal_display(season))
        
        if personas:
            print(f"🎯 **Applied to personas:** {', '.join(personas)}")
        else:
            print("🎯 **Applied to:** All personas")
    
    elif action == "get":
        active = load_active_theme()
        if not active:
            print("📋 **No active seasonal theme**")
            current = detect_current_season()
            print(f"💡 **Suggestion:** Use 'auto' to activate {current} theme")
            return
        
        season = active['season']
        print(f"🎭 **Active theme:** {season}")
        print(format_seasonal_display(season))
        
        if active.get('personas') != "all":
            print(f"🎯 **Applied to:** {', '.join(active['personas'])}")
        
        activated_at = active.get('activated_at', 'unknown')
        print(f"⏰ **Activated:** {activated_at}")
    
    elif action == "list":
        print(list_available_themes())
        
        active = load_active_theme()
        if active:
            print(f"🌟 **Currently Active:** {active['season']}")
    
    elif action == "clear":
        clear_active_theme()
        print("✅ **Seasonal themes deactivated**")
        print("💡 All personas restored to default personalities")
    
    elif action == "apply":
        if len(sys.argv) < 4:
            print("Usage: python seasonal_themes.py apply <persona_id> <season>")
            return
        
        persona_id = sys.argv[2]
        season = sys.argv[3]
        
        variant = get_seasonal_persona_variant(persona_id, season)
        if not variant:
            print(f"❌ No {season} variant available for {persona_id}")
            return
        
        print(f"🎭 **{persona_id} → {variant['name']}**")
        print(f"🎪 **Seasonal additions:** {variant['additions'][:100]}...")
    
    else:
        print(f"❌ Unknown action: {action}")
        print("Available actions: detect, set, get, list, clear, apply")

if __name__ == "__main__":
    main()