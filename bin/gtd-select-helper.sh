#!/bin/bash
# GTD Selection Helper Functions
# Source this file in your scripts to use the selection functions
#
# Usage:
#   source "$(dirname "$0")/gtd-select-helper.sh"  # or full path
#   selected=$(select_from_list "projects" "$PROJECTS_PATH" "project")
#   echo "Selected: $selected"

# Source common environment (PATH setup)
COMMON_ENV="$HOME/code/dotfiles/zsh/common_env.sh"
if [[ ! -f "$COMMON_ENV" && -f "$HOME/code/personal/dotfiles/zsh/common_env.sh" ]]; then
  COMMON_ENV="$HOME/code/personal/dotfiles/zsh/common_env.sh"
fi
if [[ -f "$COMMON_ENV" ]]; then
  source "$COMMON_ENV"
fi

# Source common helpers for colors (if not already sourced)
if [[ -z "${GREEN:-}" ]]; then
  GTD_COMMON="$(dirname "$0")/gtd-common.sh"
  if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
    GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
  fi
  if [[ -f "$GTD_COMMON" ]]; then
    source "$GTD_COMMON" 2>/dev/null || true
  fi
fi

# Set default colors if still not available
GREEN="${GREEN:-\\033[0;32m}"
NC="${NC:-\\033[0m}"

# Select from a list of items (projects, areas, notes, etc.)
# Arguments:
#   $1: item_type (for display purposes)
#   $2: search_path (directory to search)
#   $3: format (name, file, project) - how to extract display name
# Returns: selected item name via stdout, empty if cancelled
select_from_list() {
  local item_type="${1:-item}"
  local search_path="${2:-}"
  local format="${3:-name}"
  
  if [[ -z "$search_path" || ! -d "$search_path" ]]; then
    echo "❌ Invalid search path: $search_path" >&2
    return 1
  fi
  
  # Collect items
  declare -a items
  declare -a item_names
  declare -a item_paths
  
  # Function to extract display name
  get_display_name() {
    local file="$1"
    local fmt="$2"
    
    case "$fmt" in
      project)
        # For projects, read from README.md
        if [[ -f "$file" ]]; then
          local name=$(grep "^project:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
          if [[ -z "$name" ]]; then
            name=$(grep "^name:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
          fi
          if [[ -z "$name" ]]; then
            name=$(basename "$(dirname "$file")")
          fi
          echo "$name"
        fi
        ;;
      name)
        # Extract from frontmatter
        local name=$(grep "^name:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
        if [[ -z "$name" ]]; then
          # Try to get from first heading (# Title)
          name=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' || echo "")
        fi
        if [[ -z "$name" ]]; then
          name=$(grep "^title:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
        fi
        if [[ -z "$name" ]]; then
          # Convert filename slug to readable format: work-&-career -> Work & Career
          local filename=$(basename "$file" .md)
          # Replace - with space, handle & specially, then capitalize words
          name=$(echo "$filename" | sed 's/-/ /g' | sed 's/ & / \& /g' | sed 's/^&/&/' | sed 's/&$/\&/' | awk '{
            for(i=1;i<=NF;i++){
              word=$i
              if(word != "&" && word != "&") {
                $i=toupper(substr(word,1,1)) substr(word,2)
              }
            }
            print
          }')
        fi
        echo "$name"
        ;;
      file|*)
        basename "$file" .md
        ;;
    esac
  }
  
  # Find items
  if [[ "$item_type" == "project" ]]; then
    # Projects are directories with README.md
    while IFS= read -r project_dir; do
      local readme="${project_dir}/README.md"
      if [[ -f "$readme" ]]; then
        item_paths+=("$readme")
        local display_name=$(get_display_name "$readme" "$format")
        item_names+=("$display_name")
      fi
    done < <(find "$search_path" -type d -mindepth 1 -maxdepth 1 2>/dev/null | sort)
  else
    # Default: markdown files
    while IFS= read -r item_file; do
      item_paths+=("$item_file")
      local display_name=$(get_display_name "$item_file" "$format")
      item_names+=("$display_name")
    done < <(find "$search_path" -type f -name "*.md" 2>/dev/null | sort)
  fi
  
  local item_count=${#item_names[@]}
  
  if [[ $item_count -eq 0 ]]; then
    echo "No ${item_type}s found." >&2
    return 1
  fi
  
  # Display numbered list to stderr so it shows even when capturing stdout
  echo "" >&2
  for i in "${!item_names[@]}"; do
    local num=$((i + 1))
    echo "  ${num}) ${item_names[$i]}" >&2
  done
  echo "" >&2
  
  # Get user input (prompt to stderr so it shows)
  echo -n "Select ${item_type} (number or partial name): " >&2
  read user_input
  
  if [[ -z "$user_input" ]]; then
    return 1
  fi
  
  # Check if it's a number
  if [[ "$user_input" =~ ^[0-9]+$ ]]; then
    local selected_index=$((user_input - 1))
    if [[ $selected_index -ge 0 && $selected_index -lt $item_count ]]; then
      echo "${item_names[$selected_index]}"
      return 0
    else
      echo "❌ Invalid number. Please select 1-$item_count" >&2
      return 1
    fi
  fi
  
  # Try partial name matching (case-insensitive)
  declare -a matches
  declare -a match_indices
  
  for i in "${!item_names[@]}"; do
    local display_name="${item_names[$i]}"
    local file_base=$(basename "${item_paths[$i]}" .md)
    
    # Case-insensitive partial match
    # Convert to lowercase for comparison (bash compatible method)
    local display_name_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
    local file_base_lower=$(echo "$file_base" | tr '[:upper:]' '[:lower:]')
    local user_input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$display_name_lower" == *"$user_input_lower"* ]] || [[ "$file_base_lower" == *"$user_input_lower"* ]]; then
      matches+=("$display_name")
      match_indices+=($i)
    fi
  done
  
  local match_count=${#matches[@]}
  
  if [[ $match_count -eq 0 ]]; then
    echo "❌ No ${item_type}s found matching '$user_input'" >&2
    return 1
  elif [[ $match_count -eq 1 ]]; then
    # Single match - return it
    echo "${matches[0]}"
    return 0
  else
    # Multiple matches - show them and ask again (to stderr so it shows)
    echo "" >&2
    echo "Multiple matches found:" >&2
    echo "" >&2
    for i in "${!matches[@]}"; do
      local num=$((i + 1))
      echo "  ${num}) ${matches[$i]}" >&2
    done
    echo "" >&2
    echo -n "Select ${item_type} (number): " >&2
    read user_input
    
    if [[ "$user_input" =~ ^[0-9]+$ ]]; then
      local selected_index=$((user_input - 1))
      if [[ $selected_index -ge 0 && $selected_index -lt $match_count ]]; then
        echo "${matches[$selected_index]}"
        return 0
      else
        echo "❌ Invalid number. Please select 1-$match_count" >&2
        return 1
      fi
    else
      echo "❌ Invalid input" >&2
      return 1
    fi
  fi
}

# Select from a numbered list of items
# Arguments:
#   $@: array of items to select from
# Returns: selected item via stdout, empty if cancelled
select_from_numbered_list() {
  local items=("$@")
  local item_count=${#items[@]}
  
  if [[ $item_count -eq 0 ]]; then
    echo "No items to select from" >&2
    return 1
  fi
  
  # Display numbered list to stderr so it shows even when capturing stdout
  echo "" >&2
  for i in "${!items[@]}"; do
    local num=$((i + 1))
    echo -e "  ${GREEN}${num})${NC} ${items[$i]}" >&2
  done
  echo "" >&2
  
  # Get user input (read from terminal, not captured)
  echo -n "Select item (number): " >&2
  read user_input
  
  if [[ -z "$user_input" ]]; then
    return 1
  fi
  
  # Check if it's a number
  if [[ "$user_input" =~ ^[0-9]+$ ]]; then
    local selected_index=$((user_input - 1))
    if [[ $selected_index -ge 0 && $selected_index -lt $item_count ]]; then
      echo "${items[$selected_index]}"
      return 0
    else
      echo "❌ Invalid number. Please select 1-$item_count" >&2
      return 1
    fi
  else
    # Try to match by name
    for i in "${!items[@]}"; do
      if [[ "${items[$i]}" == *"$user_input"* ]]; then
        echo "${items[$i]}"
        return 0
      fi
    done
    echo "❌ No match found" >&2
    return 1
  fi
}

# Select a persona from the available list
# Returns: persona key (e.g., "hank", "david") via stdout, empty if cancelled
select_persona() {
  # Available personas array
  declare -a personas=("hank" "david" "cal" "james" "marie" "warren" "sheryl" "tim" "george" "john" "jon" "bob" "fred" "louiza" "spiderman" "ironman" "squirrelgirl" "harley" "deadpool" "rogue" "esther" "gottman" "gary" "brene" "romance" "kettlebell" "maxfit" "dumbbell" "dipbar" "kelsey" "kent" "charity" "rich" "goggins" "dean" "bioneer" "harry" "murphy" "joe" "skippy" "sherlock" "picard" "sandy" "spongebob")
  
  # Function to get persona display info
  get_persona_info() {
    case "$1" in
      hank) echo "Hank Hill - General productivity, practical reminders" ;;
      david) echo "David Allen - GTD methodology, organization" ;;
      cal) echo "Cal Newport - Deep work, focus, eliminating distractions" ;;
      james) echo "James Clear - Habit formation, systems thinking" ;;
      marie) echo "Marie Kondo - Organization, decluttering" ;;
      warren) echo "Warren Buffett - Strategic thinking, prioritization" ;;
      sheryl) echo "Sheryl Sandberg - Leadership, execution" ;;
      tim) echo "Tim Ferriss - Optimization, life hacks" ;;
      george) echo "George Carlin - Satirical critique, dark humor" ;;
      john) echo "John Oliver - Witty analysis, British humor" ;;
      jon) echo "Jon Stewart - Satirical insight, calling out BS" ;;
      bob) echo "Bob Ross - Creativity, calm, finding joy in the process" ;;
      fred) echo "Fred Rogers - Kindness, self-care, emotional support" ;;
      louiza) echo "Mistress Louiza - Accountability, execution, tracking, discipline" ;;
      spiderman) echo "Spider-Man - Creative problem-solving, juggling responsibilities, relatable struggles" ;;
      ironman) echo "Iron Man - Innovation, ADHD-like hyperfocus, engineering creativity" ;;
      squirrelgirl) echo "Squirrel Girl - Positive creativity, communication, unconventional thinking" ;;
      harley) echo "Harley Quinn - Chaotic creativity, resourcefulness, outside-the-box thinking" ;;
      deadpool) echo "Deadpool - Chaotic humor, unpredictable solutions, creative problem-solving" ;;
      rogue) echo "Rogue - Adaptive creativity, working with unique abilities, resourcefulness" ;;
      esther) echo "Esther Perel - Relationships, intimacy, making partners feel special" ;;
      gottman) echo "Dr. John Gottman - Relationship science, building strong foundations" ;;
      gary) echo "Gary Chapman - Love languages, expressing love effectively" ;;
      brene) echo "Brené Brown - Vulnerability, courage, authentic connection" ;;
      romance) echo "The Romance Coach - Date planning, thoughtful gestures, making partners feel like royalty" ;;
      kettlebell) echo "Kettlebell Coach - EMOM workouts, kettlebell training, strength and functional fitness" ;;
      maxfit) echo "Maxfit Pro Coach - Cable system workouts, resistance training, functional fitness with cables" ;;
      dumbbell) echo "Dumbbell Coach - Dumbbell training, strength building, functional fitness with dumbbells" ;;
      dipbar) echo "Dip Bar Coach - Dip bar and bodyweight training, calisthenics, functional strength" ;;
      bodyweight) echo "Bodyweight Fitness Coach - EMOM workouts, bodyweight exercises (push-ups, jumping jacks, squats), calisthenics" ;;
      kelsey) echo "Kelsey Hightower - SRE pragmatism, avoiding overengineering, practical infrastructure" ;;
      kent) echo "Kent Beck - Software simplicity, YAGNI, TDD, doing the simplest thing that works" ;;
      charity) echo "Charity Majors - SRE reliability, observability, practical engineering, avoiding overengineering" ;;
      rich) echo "Rich Hickey - Software design, simplicity vs complexity, essential vs accidental complexity" ;;
      goggins) echo "David Goggins - Mental toughness, pushing limits, extreme fitness, calling out excuses, staying hard" ;;
      dean) echo "Dean Karnazes - Ultra marathon running, endurance training, long-distance running, building mental resilience" ;;
      bioneer) echo "The Bioneer (Adam) - Functional fitness, science-based training, movement quality, practical fitness advice" ;;
      harry) echo "Harry Dresden - Creative problem-solving, wizard metaphors, resourceful solutions, friendly neighborhood wizard" ;;
      murphy) echo "Karrin Murphy - Practical execution, cutting through BS, organized, methodical, no-nonsense detective" ;;
      joe) echo "General Joe Bishop - Simple explanations, breaking things down barney style, clear communication, plain language" ;;
      skippy) echo "Skippy the Magnificent - Sarcastic brilliance, snarky but helpful, cutting through BS with humor, condescending AI" ;;
      sherlock) echo "Sherlock Holmes - Analytical deduction, methodical investigation, noticing details others miss, logical problem-solving" ;;
      picard) echo "Jean-Luc Picard - Strategic leadership, diplomatic guidance, principled decision-making, inspiring others" ;;
      sandy) echo "Sandy Squirrel (SpongeBob SquarePants) - Science, karate, Texas pride, competitive spirit, practical problem-solving" ;;
      spongebob) echo "SpongeBob SquarePants - Optimism, enthusiasm, creativity, friendship, finding joy in work, positive attitude" ;;
      *) echo "Unknown persona" ;;
    esac
  }
  
  local persona_count=${#personas[@]}
  
  # Display numbered list to stderr so it shows even when capturing stdout
  echo "" >&2
  echo "Available personas:" >&2
  echo "" >&2
  for i in "${!personas[@]}"; do
    local num=$((i + 1))
    local persona_key="${personas[$i]}"
    local persona_info=$(get_persona_info "$persona_key")
    echo "  ${num}) ${persona_key} - ${persona_info}" >&2
  done
  echo "" >&2
  
  # Get user input (prompt to stderr so it shows)
  echo -n "Select persona (number or partial name): " >&2
  read user_input
  
  if [[ -z "$user_input" ]]; then
    return 1
  fi
  
  # Check if it's a number
  if [[ "$user_input" =~ ^[0-9]+$ ]]; then
    local selected_index=$((user_input - 1))
    if [[ $selected_index -ge 0 && $selected_index -lt $persona_count ]]; then
      echo "${personas[$selected_index]}"
      return 0
    else
      echo "❌ Invalid number. Please select 1-$persona_count" >&2
      return 1
    fi
  fi
  
  # Try partial name matching (case-insensitive)
  declare -a matches
  declare -a match_indices
  
  for i in "${!personas[@]}"; do
    local persona_key="${personas[$i]}"
    local persona_info=$(get_persona_info "$persona_key")
    
    # Case-insensitive partial match on key or info
    # Convert to lowercase for comparison (bash compatible method)
    local persona_key_lower=$(echo "$persona_key" | tr '[:upper:]' '[:lower:]')
    local persona_info_lower=$(echo "$persona_info" | tr '[:upper:]' '[:lower:]')
    local user_input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$persona_key_lower" == *"$user_input_lower"* ]] || [[ "$persona_info_lower" == *"$user_input_lower"* ]]; then
      matches+=("$persona_key")
      match_indices+=($i)
    fi
  done
  
  local match_count=${#matches[@]}
  
  if [[ $match_count -eq 0 ]]; then
    echo "❌ No personas found matching '$user_input'" >&2
    return 1
  elif [[ $match_count -eq 1 ]]; then
    # Single match - return it
    echo "${matches[0]}"
    return 0
  else
    # Multiple matches - show them and ask again (to stderr so it shows)
    echo "" >&2
    echo "Multiple matches found:" >&2
    echo "" >&2
    for i in "${!matches[@]}"; do
      local num=$((i + 1))
      local persona_key="${matches[$i]}"
      local persona_info=$(get_persona_info "$persona_key")
      echo "  ${num}) ${persona_key} - ${persona_info}" >&2
    done
    echo "" >&2
    echo -n "Select persona (number): " >&2
    read user_input
    
    if [[ "$user_input" =~ ^[0-9]+$ ]]; then
      local selected_index=$((user_input - 1))
      if [[ $selected_index -ge 0 && $selected_index -lt $match_count ]]; then
        echo "${matches[$selected_index]}"
        return 0
      else
        echo "❌ Invalid number. Please select 1-$match_count" >&2
        return 1
      fi
    else
      echo "❌ Invalid input" >&2
      return 1
    fi
  fi
}


