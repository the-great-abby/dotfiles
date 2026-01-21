#!/bin/bash
# GTD Wizard Personalization Functions
# Interactive wizard to capture personalization information
# Uses TOON (Token Output Object Notation) format for efficient storage

PERSONALIZATION_FILE="$HOME/.gtd_personalization.toon"
PERSONALIZATION_JSON_FILE="$HOME/.gtd_personalization.json"  # For migration

# Initialize personalization file
init_personalization_file() {
  # Check if TOON file exists, or if JSON exists (for migration)
  if [[ ! -f "$PERSONALIZATION_FILE" ]]; then
    # Try to migrate from JSON if it exists
    if [[ -f "$PERSONALIZATION_JSON_FILE" ]]; then
      python3 <<EOF
import sys
from pathlib import Path
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
try:
    from gtd_toon_helper import migrate_json_to_toon, get_personalization_file_path
    migrate_json_to_toon()
except ImportError:
    # Fallback: use JSON directly
    import json
    from datetime import datetime
    json_path = Path("$PERSONALIZATION_JSON_FILE")
    toon_path = Path("$PERSONALIZATION_FILE")
    if json_path.exists():
        with open(json_path) as f:
            data = json.load(f)
        # Save as JSON for now (TOON library not available)
        with open(toon_path.with_suffix('.json'), 'w') as f:
            json.dump(data, f, indent=2)
EOF
    fi
    
    # Initialize new file if still doesn't exist
    if [[ ! -f "$PERSONALIZATION_FILE" ]]; then
      python3 <<EOF
import sys
from pathlib import Path
from datetime import datetime

# Try to use TOON helper
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
try:
    from gtd_toon_helper import save_toon_file, get_personalization_file_path
    
    personalization = {
        "created": datetime.now().isoformat(),
        "last_updated": datetime.now().isoformat(),
        "name": "",
        "relationships": {
            "partner": {},
            "family": [],
            "close_friends": [],
            "professional": []
        },
        "life_situation": {
            "living_arrangement": "",
            "timezone": "",
            "life_phase": ""
        },
        "goals": {
            "career": [],
            "personal": [],
            "financial": [],
            "learning": []
        },
        "values": [],
        "current_focus": [],
        "energy_patterns": {
            "peak_hours": [],
            "low_energy_hours": [],
            "energy_drainers": [],
            "energy_rechargers": []
        },
        "work_patterns": {
            "typical_schedule": "",
            "oncall_schedule": "",
            "deep_work_preferred_times": [],
            "focus_duration": ""
        },
        "health_routines": {
            "medications": [],
            "exercise_patterns": "",
            "sleep_needs": "",
            "meal_patterns": ""
        },
        "wellness_tracking": {
            "tracked_metrics": [],
            "patterns_noticed": []
        },
        "communication_style": {
            "tone_preference": "",
            "feedback_style": "",
            "detail_level": "",
            "reminder_style": ""
        },
        "ai_interaction": {
            "proactivity_level": "",
            "context_memory": "",
            "suggestion_frequency": ""
        },
        "learning_style": {
            "preferred_methods": [],
            "explanation_depth": "",
            "practice_style": ""
        },
        "knowledge_areas": {
            "expertise": [],
            "learning": [],
            "tools": []
        },
        "decision_making": {
            "style": "",
            "information_needs": "",
            "decision_speed": "",
            "confidence_factors": []
        },
        "problem_solving": {
            "approach": "",
            "thinking_aids": [],
            "stuck_indicators": [],
            "unstuck_methods": []
        },
        "stress_indicators": {
            "verbal_cues": [],
            "situations": [],
            "patterns": []
        },
        "coping_mechanisms": {
            "effective": [],
            "ineffective": []
        },
        "recovery": {
            "typical_duration": "",
            "helps": []
        },
        "interests": {
            "hobbies": [],
            "creative_pursuits": [],
            "social_activities": []
        },
        "personal_projects": [],
        "professional": {
            "role": "",
            "industry": "",
            "career_stage": "",
            "key_responsibilities": [],
            "current_focus": []
        },
        "tools": {
            "regular_use": [],
            "learning": [],
            "preferred_editors": []
        },
        "workflows": {
            "organization_style": "",
            "tracking_preferences": "",
            "automation_level": ""
        },
        "lessons_learned": {
            "what_works": [],
            "what_doesnt_work": [],
            "patterns": []
        }
    }
    
    file_path = get_personalization_file_path()
    save_toon_file(file_path, personalization)
except ImportError:
    # Fallback to JSON if TOON helper not available
    import json
    personalization = {
        "created": datetime.now().isoformat(),
        "last_updated": datetime.now().isoformat(),
        "name": "",
        "relationships": {"partner": {}, "family": [], "close_friends": [], "professional": []},
        "life_situation": {"living_arrangement": "", "timezone": "", "life_phase": ""},
        "goals": {"career": [], "personal": [], "financial": [], "learning": []},
        "values": [],
        "current_focus": [],
        "energy_patterns": {"peak_hours": [], "low_energy_hours": [], "energy_drainers": [], "energy_rechargers": []},
        "work_patterns": {"typical_schedule": "", "oncall_schedule": "", "deep_work_preferred_times": [], "focus_duration": ""},
        "health_routines": {"medications": [], "exercise_patterns": "", "sleep_needs": "", "meal_patterns": ""},
        "wellness_tracking": {"tracked_metrics": [], "patterns_noticed": []},
        "communication_style": {"tone_preference": "", "feedback_style": "", "detail_level": "", "reminder_style": ""},
        "ai_interaction": {"proactivity_level": "", "context_memory": "", "suggestion_frequency": ""},
        "learning_style": {"preferred_methods": [], "explanation_depth": "", "practice_style": ""},
        "knowledge_areas": {"expertise": [], "learning": [], "tools": []},
        "decision_making": {"style": "", "information_needs": "", "decision_speed": "", "confidence_factors": []},
        "problem_solving": {"approach": "", "thinking_aids": [], "stuck_indicators": [], "unstuck_methods": []},
        "stress_indicators": {"verbal_cues": [], "situations": [], "patterns": []},
        "coping_mechanisms": {"effective": [], "ineffective": []},
        "recovery": {"typical_duration": "", "helps": []},
        "interests": {"hobbies": [], "creative_pursuits": [], "social_activities": []},
        "personal_projects": [],
        "professional": {"role": "", "industry": "", "career_stage": "", "key_responsibilities": [], "current_focus": []},
        "tools": {"regular_use": [], "learning": [], "preferred_editors": []},
        "workflows": {"organization_style": "", "tracking_preferences": "", "automation_level": ""},
        "lessons_learned": {"what_works": [], "what_doesnt_work": [], "patterns": []}
    }
    with open("$PERSONALIZATION_JSON_FILE", 'w') as f:
        json.dump(personalization, f, indent=2)
EOF
      echo "✓ Initialized personalization file: $PERSONALIZATION_FILE"
    fi
  fi
}

# Load personalization data
load_personalization() {
  python3 <<EOF
import sys
from pathlib import Path
import json

# Try to use TOON helper
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
try:
    from gtd_toon_helper import load_toon_file, get_personalization_file_path
    
    try:
        file_path = get_personalization_file_path()
        data = load_toon_file(file_path)
        if data is None:
            data = {}
        print(json.dumps(data))
    except Exception as e:
        # If TOON loading fails, try JSON fallback
        prefs_file = Path("$PERSONALIZATION_FILE")
        json_file = Path("$PERSONALIZATION_JSON_FILE")
        if prefs_file.exists() and prefs_file.suffix == '.json':
            try:
                with open(prefs_file) as f:
                    data = json.load(f)
                    print(json.dumps(data))
            except:
                print("{}")
        elif json_file.exists():
            try:
                with open(json_file) as f:
                    data = json.load(f)
                    print(json.dumps(data))
            except:
                print("{}")
        else:
            print("{}")
except ImportError:
    # Fallback to JSON
    prefs_file = Path("$PERSONALIZATION_FILE")
    json_file = Path("$PERSONALIZATION_JSON_FILE")
    if prefs_file.exists() and prefs_file.suffix == '.json':
        try:
            with open(prefs_file) as f:
                data = json.load(f)
                print(json.dumps(data))
        except:
            print("{}")
    elif json_file.exists():
        try:
            with open(json_file) as f:
                data = json.load(f)
                print(json.dumps(data))
        except:
            print("{}")
    else:
        print("{}")
EOF
}

# Save personalization data
save_personalization() {
  local json_data="$1"
  python3 <<EOF
import sys
from pathlib import Path
import json

# Try to use TOON helper
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
try:
    from gtd_toon_helper import save_toon_file, get_personalization_file_path
    
    data = json.loads('''$json_data''')
    file_path = get_personalization_file_path()
    save_toon_file(file_path, data)
except ImportError:
    # Fallback to JSON
    from datetime import datetime
    prefs_file = Path("$PERSONALIZATION_FILE")
    json_file = Path("$PERSONALIZATION_JSON_FILE")
    
    data = json.loads('''$json_data''')
    data["last_updated"] = datetime.now().isoformat()
    
    # Save to JSON file
    with open(json_file, 'w') as f:
        json.dump(data, f, indent=2)
EOF
}

# Helper to collect list items (returns pipe-separated string for Python processing)
collect_list() {
  local prompt="$1"
  local items=""
  local item=""
  
  echo "$prompt"
  echo "(Enter items one at a time, press Enter with empty input to finish)"
  echo ""
  
  while true; do
    read -p "  → " item
    if [[ -z "$item" ]]; then
      break
    fi
    if [[ -z "$items" ]]; then
      items="$item"
    else
      items="$items|$item"
    fi
  done
  
  echo "$items"
}

# Helper to collect a single value
collect_value() {
  local prompt="$1"
  local default="$2"
  local value=""
  
  if [[ -n "$default" ]]; then
    read -p "$prompt (default: $default): " value
    value="${value:-$default}"
  else
    read -p "$prompt: " value
  fi
  
  echo "$value"
}

# Main personalization wizard
personalization_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}👤 Personalization Setup${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Help the AI understand you better by sharing information about yourself."
  echo "You can skip any section or come back to update it later."
  echo ""
  echo "What would you like to configure?"
  echo ""
  echo "  0) 👤 Basic Information (Name)"
  echo "  1) 👥 Relationships & Life Situation"
  echo "  2) 🎯 Goals, Values & Priorities"
  echo "  3) ⚡ Work Patterns & Energy Management"
  echo "  4) 💚 Health & Wellness"
  echo "  5) 💬 Communication Preferences"
  echo "  6) 📚 Learning Style & Knowledge"
  echo "  7) 🤔 Decision-Making & Problem-Solving"
  echo "  8) 😰 Stress & Coping Mechanisms"
  echo "  9) 🎨 Interests & Personal Life"
  echo " 10) 💼 Professional Context"
  echo " 11) 🛠️  Tools & Systems"
  echo " 12) 📖 Lessons Learned"
  echo " 13) 📊 View Current Personalization"
  echo " 14) 🔄 Reset Personalization (start fresh)"
  echo ""
  echo -e "${YELLOW} 99)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    0)
      basic_info_wizard
      ;;
    1)
      relationships_wizard
      ;;
    2)
      goals_wizard
      ;;
    3)
      work_patterns_wizard
      ;;
    4)
      health_wizard
      ;;
    5)
      communication_wizard
      ;;
    6)
      learning_wizard
      ;;
    7)
      decision_making_wizard
      ;;
    8)
      stress_wizard
      ;;
    9)
      interests_wizard
      ;;
    10)
      professional_wizard
      ;;
    11)
      tools_wizard
      ;;
    12)
      lessons_wizard
      ;;
    13)
      view_personalization
      ;;
    14)
      reset_personalization
      ;;
    99|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      gtd_quick_pause
      ;;
  esac
}

# Basic Information (Name)
basic_info_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  # Ensure data is valid JSON (handle empty or None cases)
  if [[ -z "$data" ]]; then
    data="{}"
  fi
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}👤 Basic Information${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "What's your name?"
  echo "(This helps the AI address you properly and avoid confusion)"
  echo ""
  
  local name=$(collect_value "  Your name (or skip):" "")
  
  if [[ -n "$name" ]]; then
    # Escape the data for safe passing to Python
    data=$(python3 <<EOF
import json

# Safely parse the JSON data passed from bash
data_str = '''$data'''
if not data_str or data_str.strip() == "":
    data = {}
else:
    try:
        data = json.loads(data_str)
    except (json.JSONDecodeError, ValueError, TypeError):
        data = {}

# Update name
data["name"] = "$name"
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  if [[ -n "$name" ]]; then
    echo "✓ Name saved: $name"
  else
    echo "✓ Basic information updated (no name provided)"
  fi
  gtd_enter_to_continue
}

# Relationships & Life Situation
relationships_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}👥 Relationships & Life Situation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Partner
  echo "Partner/Spouse Information:"
  local partner_name=$(collect_value "  Partner name (or skip):" "")
  if [[ -n "$partner_name" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
data["relationships"]["partner"]["name"] = "$partner_name"
data["relationships"]["partner"]["relationship_type"] = "partner"
print(json.dumps(data))
EOF
    )
  fi
  echo ""
  
  # Family
  echo "Family Members:"
  echo "(Enter names one at a time, empty to finish)"
  local family_list=""
  while true; do
    read -p "  Family member name (or Enter to finish): " name
    if [[ -z "$name" ]]; then
      break
    fi
    if [[ -z "$family_list" ]]; then
      family_list="$name"
    else
      family_list="$family_list|$name"
    fi
  done
  
  if [[ -n "$family_list" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
family = [name for name in """$family_list""".split('|') if name]
data["relationships"]["family"] = family
print(json.dumps(data))
EOF
    )
  fi
  echo ""
  
  # Life Situation
  echo "Life Situation:"
  local living=$(collect_value "  Living arrangement (alone/with_partner/family/roommates):" "")
  local timezone=$(collect_value "  Timezone (e.g., America/Los_Angeles):" "")
  local life_phase=$(collect_value "  Life phase (student/early_career/established/etc):" "")
  
  if [[ -n "$living" || -n "$timezone" || -n "$life_phase" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
if "$living":
    data["life_situation"]["living_arrangement"] = "$living"
if "$timezone":
    data["life_situation"]["timezone"] = "$timezone"
if "$life_phase":
    data["life_situation"]["life_phase"] = "$life_phase"
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Relationships & Life Situation updated"
  gtd_enter_to_continue
}

# Goals, Values & Priorities
goals_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 Goals, Values & Priorities${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Career Goals
  echo "Career Goals:"
  echo "(Enter goals one at a time, empty to finish)"
  local career_goals=""
  while true; do
    read -p "  Career goal: " goal
    if [[ -z "$goal" ]]; then
      break
    fi
    if [[ -z "$career_goals" ]]; then
      career_goals="$goal"
    else
      career_goals="$career_goals|$goal"
    fi
  done
  
  if [[ -n "$career_goals" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
goals = [g for g in """$career_goals""".split('|') if g]
data["goals"]["career"] = goals
print(json.dumps(data))
EOF
    )
  fi
  echo ""
  
  # Personal Goals
  echo "Personal Goals:"
  local personal_goals=""
  while true; do
    read -p "  Personal goal: " goal
    if [[ -z "$goal" ]]; then
      break
    fi
    if [[ -z "$personal_goals" ]]; then
      personal_goals="$goal"
    else
      personal_goals="$personal_goals|$goal"
    fi
  done
  
  if [[ -n "$personal_goals" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
goals = [g for g in """$personal_goals""".split('|') if g]
data["goals"]["personal"] = goals
print(json.dumps(data))
EOF
    )
  fi
  echo ""
  
  # Values
  echo "Core Values:"
  local values=""
  while true; do
    read -p "  Value: " value
    if [[ -z "$value" ]]; then
      break
    fi
    if [[ -z "$values" ]]; then
      values="$value"
    else
      values="$values|$value"
    fi
  done
  
  if [[ -n "$values" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
vals = [v for v in """$values""".split('|') if v]
data["values"] = vals
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Goals, Values & Priorities updated"
  gtd_enter_to_continue
}

# Work Patterns & Energy Management
work_patterns_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚡ Work Patterns & Energy Management${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Peak Hours
  echo "When are you most productive? (Enter time ranges like '09:00-12:00')"
  local peak_hours=""
  while true; do
    read -p "  Peak hour range (or Enter to finish): " hour
    if [[ -z "$hour" ]]; then
      break
    fi
    if [[ -z "$peak_hours" ]]; then
      peak_hours="$hour"
    else
      peak_hours="$peak_hours|$hour"
    fi
  done
  
  if [[ -n "$peak_hours" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
hours = [h for h in """$peak_hours""".split('|') if h]
data["energy_patterns"]["peak_hours"] = hours
print(json.dumps(data))
EOF
    )
  fi
  echo ""
  
  # Energy Rechargers
  echo "What helps you recharge? (Enter items one at a time)"
  local rechargers=""
  while true; do
    read -p "  Energy recharger: " item
    if [[ -z "$item" ]]; then
      break
    fi
    if [[ -z "$rechargers" ]]; then
      rechargers="$item"
    else
      rechargers="$rechargers|$item"
    fi
  done
  
  if [[ -n "$rechargers" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
items = [i for i in """$rechargers""".split('|') if i]
data["energy_patterns"]["energy_rechargers"] = items
print(json.dumps(data))
EOF
    )
  fi
  echo ""
  
  # Work Schedule
  local schedule=$(collect_value "Typical work schedule (e.g., 09:00-17:00):" "")
  local focus_duration=$(collect_value "Typical focus duration (e.g., 90 minutes):" "")
  
  if [[ -n "$schedule" || -n "$focus_duration" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
if "$schedule":
    data["work_patterns"]["typical_schedule"] = "$schedule"
if "$focus_duration":
    data["work_patterns"]["focus_duration"] = "$focus_duration"
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Work Patterns & Energy Management updated"
  gtd_enter_to_continue
}

# Health & Wellness
health_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💚 Health & Wellness${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local sleep_needs=$(collect_value "Sleep needs (e.g., 7-8 hours):" "")
  local exercise=$(collect_value "Exercise patterns (e.g., regular/irregular/weekly):" "")
  
  if [[ -n "$sleep_needs" || -n "$exercise" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
if "$sleep_needs":
    data["health_routines"]["sleep_needs"] = "$sleep_needs"
if "$exercise":
    data["health_routines"]["exercise_patterns"] = "$exercise"
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Health & Wellness updated"
  gtd_enter_to_continue
}

# Communication Preferences
communication_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💬 Communication Preferences${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "How do you prefer to communicate?"
  echo "  1) Direct and to the point"
  echo "  2) Supportive but direct"
  echo "  3) Casual and friendly"
  echo "  4) Formal and professional"
  echo ""
  read -p "Choose (1-4): " tone_choice
  
  local tone=""
  case "$tone_choice" in
    1) tone="direct" ;;
    2) tone="supportive_but_direct" ;;
    3) tone="casual_friendly" ;;
    4) tone="formal_professional" ;;
  esac
  
  if [[ -n "$tone" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
data["communication_style"]["tone_preference"] = "$tone"
print(json.dumps(data))
EOF
    )
  fi
  
  echo ""
  echo "How much detail do you prefer?"
  echo "  1) Concise (just the essentials)"
  echo "  2) Moderate (enough context)"
  echo "  3) Detailed (comprehensive information)"
  echo ""
  read -p "Choose (1-3): " detail_choice
  
  local detail=""
  case "$detail_choice" in
    1) detail="concise" ;;
    2) detail="moderate" ;;
    3) detail="detailed" ;;
  esac
  
  if [[ -n "$detail" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
data["communication_style"]["detail_level"] = "$detail"
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Communication Preferences updated"
  gtd_enter_to_continue
}

# Learning Style & Knowledge
learning_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📚 Learning Style & Knowledge${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "What are you currently learning?"
  local learning=""
  while true; do
    read -p "  Learning topic (or Enter to finish): " topic
    if [[ -z "$topic" ]]; then
      break
    fi
    if [[ -z "$learning" ]]; then
      learning="$topic"
    else
      learning="$learning|$topic"
    fi
  done
  
  if [[ -n "$learning" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
topics = [t for t in """$learning""".split('|') if t]
data["knowledge_areas"]["learning"] = topics
print(json.dumps(data))
EOF
    )
  fi
  
  echo ""
  echo "What tools/technologies do you use regularly?"
  local tools=""
  while true; do
    read -p "  Tool/technology (or Enter to finish): " tool
    if [[ -z "$tool" ]]; then
      break
    fi
    if [[ -z "$tools" ]]; then
      tools="$tool"
    else
      tools="$tools|$tool"
    fi
  done
  
  if [[ -n "$tools" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
tool_list = [t for t in """$tools""".split('|') if t]
data["tools"]["regular_use"] = tool_list
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Learning Style & Knowledge updated"
  gtd_enter_to_continue
}

# Decision-Making & Problem-Solving
decision_making_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🤔 Decision-Making & Problem-Solving${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "How do you typically make decisions?"
  echo "  1) Analytical (data-driven, systematic)"
  echo "  2) Intuitive (gut feeling, quick)"
  echo "  3) Collaborative (discuss with others)"
  echo "  4) Analytical with intuition"
  echo ""
  read -p "Choose (1-4): " decision_choice
  
  local style=""
  case "$decision_choice" in
    1) style="analytical" ;;
    2) style="intuitive" ;;
    3) style="collaborative" ;;
    4) style="analytical_with_intuition" ;;
  esac
  
  if [[ -n "$style" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
data["decision_making"]["style"] = "$style"
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Decision-Making & Problem-Solving updated"
  gtd_enter_to_continue
}

# Stress & Coping Mechanisms
stress_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}😰 Stress & Coping Mechanisms${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "What helps you manage stress? (Enter items one at a time)"
  local effective=""
  while true; do
    read -p "  Effective coping mechanism: " item
    if [[ -z "$item" ]]; then
      break
    fi
    if [[ -z "$effective" ]]; then
      effective="$item"
    else
      effective="$effective|$item"
    fi
  done
  
  if [[ -n "$effective" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
items = [i for i in """$effective""".split('|') if i]
data["coping_mechanisms"]["effective"] = items
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Stress & Coping Mechanisms updated"
  gtd_enter_to_continue
}

# Interests & Personal Life
interests_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎨 Interests & Personal Life${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "What are your hobbies or interests?"
  local hobbies=""
  while true; do
    read -p "  Hobby/interest (or Enter to finish): " hobby
    if [[ -z "$hobby" ]]; then
      break
    fi
    if [[ -z "$hobbies" ]]; then
      hobbies="$hobby"
    else
      hobbies="$hobbies|$hobby"
    fi
  done
  
  if [[ -n "$hobbies" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
hobby_list = [h for h in """$hobbies""".split('|') if h]
data["interests"]["hobbies"] = hobby_list
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Interests & Personal Life updated"
  gtd_enter_to_continue
}

# Professional Context
professional_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💼 Professional Context${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local role=$(collect_value "Role/title:" "")
  local industry=$(collect_value "Industry:" "")
  local career_stage=$(collect_value "Career stage (e.g., early/mid/senior):" "")
  
  if [[ -n "$role" || -n "$industry" || -n "$career_stage" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
if "$role":
    data["professional"]["role"] = "$role"
if "$industry":
    data["professional"]["industry"] = "$industry"
if "$career_stage":
    data["professional"]["career_stage"] = "$career_stage"
print(json.dumps(data))
EOF
    )
  fi
  
  echo ""
  echo "Key responsibilities:"
  local responsibilities=""
  while true; do
    read -p "  Responsibility (or Enter to finish): " resp
    if [[ -z "$resp" ]]; then
      break
    fi
    if [[ -z "$responsibilities" ]]; then
      responsibilities="$resp"
    else
      responsibilities="$responsibilities|$resp"
    fi
  done
  
  if [[ -n "$responsibilities" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
resp_list = [r for r in """$responsibilities""".split('|') if r]
data["professional"]["key_responsibilities"] = resp_list
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Professional Context updated"
  gtd_enter_to_continue
}

# Tools & Systems
tools_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🛠️  Tools & Systems${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "What tools are you currently learning?"
  local learning_tools=""
  while true; do
    read -p "  Tool (or Enter to finish): " tool
    if [[ -z "$tool" ]]; then
      break
    fi
    if [[ -z "$learning_tools" ]]; then
      learning_tools="$tool"
    else
      learning_tools="$learning_tools|$tool"
    fi
  done
  
  if [[ -n "$learning_tools" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
tools = [t for t in """$learning_tools""".split('|') if t]
data["tools"]["learning"] = tools
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Tools & Systems updated"
  gtd_enter_to_continue
}

# Lessons Learned
lessons_wizard() {
  clear
  init_personalization_file
  
  local data=$(load_personalization)
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📖 Lessons Learned${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "What has worked well for you?"
  local what_works=""
  while true; do
    read -p "  What works: " item
    if [[ -z "$item" ]]; then
      break
    fi
    if [[ -z "$what_works" ]]; then
      what_works="$item"
    else
      what_works="$what_works|$item"
    fi
  done
  
  if [[ -n "$what_works" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
items = [i for i in """$what_works""".split('|') if i]
data["lessons_learned"]["what_works"] = items
print(json.dumps(data))
EOF
    )
  fi
  
  echo ""
  echo "What hasn't worked for you?"
  local what_doesnt=""
  while true; do
    read -p "  What doesn't work: " item
    if [[ -z "$item" ]]; then
      break
    fi
    if [[ -z "$what_doesnt" ]]; then
      what_doesnt="$item"
    else
      what_doesnt="$what_doesnt|$item"
    fi
  done
  
  if [[ -n "$what_doesnt" ]]; then
    data=$(python3 <<EOF
import json
data = json.loads('''$data''')
items = [i for i in """$what_doesnt""".split('|') if i]
data["lessons_learned"]["what_doesnt_work"] = items
print(json.dumps(data))
EOF
    )
  fi
  
  save_personalization "$data"
  echo ""
  echo "✓ Lessons Learned updated"
  gtd_enter_to_continue
}

# View current personalization
view_personalization() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Current Personalization${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Check both TOON and JSON files
  if [[ ! -f "$PERSONALIZATION_FILE" && ! -f "$PERSONALIZATION_JSON_FILE" ]]; then
    echo "No personalization data found. Run the wizard to set it up."
    echo ""
    gtd_enter_to_continue
    return
  fi
  
  python3 <<EOF
import sys
from pathlib import Path
import json

# Try to use TOON helper
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
try:
    from gtd_toon_helper import load_toon_file, get_personalization_file_path
    file_path = get_personalization_file_path()
    data = load_toon_file(file_path)
except ImportError:
    # Fallback to JSON
    prefs_file = Path("$PERSONALIZATION_FILE")
    json_file = Path("$PERSONALIZATION_JSON_FILE")
    if prefs_file.exists():
        with open(prefs_file) as f:
            data = json.load(f)
    elif json_file.exists():
        with open(json_file) as f:
            data = json.load(f)
    else:
        data = {}

if data:
    
    # Pretty print key sections
    if data.get("name"):
        print(f"👤 Name: {data['name']}")
        print()
    
    print("👥 Relationships:")
    if data.get("relationships", {}).get("partner", {}).get("name"):
        print(f"  Partner: {data['relationships']['partner']['name']}")
    if data.get("relationships", {}).get("family"):
        print(f"  Family: {', '.join(data['relationships']['family'])}")
    print()
    
    print("🎯 Goals:")
    if data.get("goals", {}).get("career"):
        print(f"  Career: {', '.join(data['goals']['career'])}")
    if data.get("goals", {}).get("personal"):
        print(f"  Personal: {', '.join(data['goals']['personal'])}")
    if data.get("values"):
        print(f"  Values: {', '.join(data['values'])}")
    print()
    
    print("⚡ Energy Patterns:")
    if data.get("energy_patterns", {}).get("peak_hours"):
        print(f"  Peak hours: {', '.join(data['energy_patterns']['peak_hours'])}")
    if data.get("energy_patterns", {}).get("energy_rechargers"):
        print(f"  Rechargers: {', '.join(data['energy_patterns']['energy_rechargers'])}")
    print()
    
    print("💬 Communication:")
    if data.get("communication_style", {}).get("tone_preference"):
        print(f"  Tone: {data['communication_style']['tone_preference']}")
    if data.get("communication_style", {}).get("detail_level"):
        print(f"  Detail level: {data['communication_style']['detail_level']}")
    print()
    
    print("📚 Learning:")
    if data.get("knowledge_areas", {}).get("learning"):
        print(f"  Currently learning: {', '.join(data['knowledge_areas']['learning'])}")
    if data.get("tools", {}).get("regular_use"):
        print(f"  Tools: {', '.join(data['tools']['regular_use'])}")
    print()
    
    print("💼 Professional:")
    if data.get("professional", {}).get("role"):
        print(f"  Role: {data['professional']['role']}")
    if data.get("professional", {}).get("key_responsibilities"):
        print(f"  Responsibilities: {', '.join(data['professional']['key_responsibilities'])}")
    print()
    
    print(f"Last updated: {data.get('last_updated', 'Unknown')}")
else:
    print("No personalization file found.")
EOF
  
  echo ""
  gtd_enter_to_continue
}

# Reset personalization
reset_personalization() {
  clear
  echo ""
  echo -e "${BOLD}${YELLOW}⚠️  Reset Personalization${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "This will delete all personalization data and start fresh."
  echo ""
  read -p "Are you sure? (yes/no): " confirm
  if [[ "$confirm" == "yes" ]]; then
    if [[ -f "$PERSONALIZATION_FILE" ]]; then
      rm "$PERSONALIZATION_FILE"
      echo "✓ Personalization reset (TOON file removed)"
    fi
    if [[ -f "$PERSONALIZATION_JSON_FILE" ]]; then
      rm "$PERSONALIZATION_JSON_FILE"
      echo "✓ Personalization reset (JSON file removed)"
    fi
    if [[ -f "$PERSONALIZATION_FILE" || -f "$PERSONALIZATION_JSON_FILE" ]]; then
      echo ""
      echo "Run the wizard again to set up personalization."
    else
      echo "No personalization file found."
    fi
  else
    echo "Cancelled"
  fi
  echo ""
  gtd_enter_to_continue
}
