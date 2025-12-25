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
  # bash 3.2 compatible - no declare -a
  items=()
  item_names=()
  item_paths=()
  
  # Function to extract display name
  get_display_name() {
    local file="$1"
    local fmt="$2"
    
    case "$fmt" in
      project)
        # For projects, use standardized helper function (DRY - reuse existing helper)
        if [[ -f "$file" ]]; then
          local name=$(get_project_name "$file")
          echo "$name"
        fi
        ;;
      name)
        # Extract from frontmatter using standardized helper (DRY - reuse existing helper)
        local name=$(gtd_get_frontmatter_value "$file" "name")
        if [[ -z "$name" ]]; then
          # Try to get from first heading (# Title)
          name=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' || echo "")
        fi
        if [[ -z "$name" ]]; then
          name=$(gtd_get_frontmatter_value "$file" "title")
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
    # Projects are directories (with or without README.md)
    # Show all project directories, not just those with README.md
    while IFS= read -r project_dir; do
      local readme="${project_dir}/README.md"
      # Use README.md if it exists, otherwise use the directory name
      if [[ -f "$readme" ]]; then
        item_paths+=("$readme")
        local display_name=$(get_display_name "$readme" "$format")
        
        # Add task count and area to display name if available
        local task_count=$(find "$project_dir" -name "*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
        local area=""
        if command -v get_frontmatter_value &>/dev/null; then
          area=$(get_frontmatter_value "$readme" "area" 2>/dev/null)
        elif command -v gtd_get_frontmatter_value &>/dev/null; then
          area=$(gtd_get_frontmatter_value "$readme" "area" 2>/dev/null)
        fi
        
        if [[ $task_count -gt 0 ]] || [[ -n "$area" ]]; then
          local suffix=""
          if [[ $task_count -gt 0 ]]; then
            suffix=" (${task_count} task"
            [[ $task_count -ne 1 ]] && suffix="${suffix}s"
            suffix="${suffix})"
          fi
          if [[ -n "$area" ]]; then
            local area_display=$(echo "$area" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
            if [[ -n "$suffix" ]]; then
              suffix="${suffix} | Area: $area_display"
            else
              suffix=" (Area: $area_display)"
            fi
          fi
          display_name="${display_name}${suffix}"
        fi
        
        item_names+=("$display_name")
      else
        # Project without README.md - use directory name as display name
        item_paths+=("$project_dir")
        local project_slug=$(basename "$project_dir")
        # Skip empty or invalid directory names
        if [[ -z "$project_slug" || "$project_slug" == "." || "$project_slug" == ".." ]]; then
          continue
        fi
        # Remove trailing hyphens and spaces
        project_slug=$(echo "$project_slug" | sed 's/[- ]*$//')
        # Convert slug to readable format: work-&-career -> Work & Career
        # Use bash string manipulation to avoid encoding issues with awk/sed
        # First, replace hyphens with spaces
        local display_name=$(echo "$project_slug" | sed 's/-/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Capitalize using bash string manipulation (most reliable)
        if [[ -n "$display_name" ]]; then
          local capitalized=""
          local old_IFS="$IFS"
          IFS=' '
          local word_count=0
          for word in $display_name; do
            if [[ $word_count -gt 0 ]]; then
              capitalized="$capitalized "
            fi
            # Capitalize first character using bash substring and tr
            if [[ ${#word} -gt 0 ]]; then
              local first_char="${word:0:1}"
              local rest="${word:1}"
              # Uppercase first char (handle encoding issues gracefully)
              first_char=$(echo "$first_char" | tr '[:lower:]' '[:upper:]' 2>/dev/null || echo "$first_char")
              capitalized="$capitalized$first_char$rest"
            else
              capitalized="$capitalized$word"
            fi
            ((word_count++))
          done
          IFS="$old_IFS"
          
          # If capitalization produced empty result, use display name
          if [[ -z "$capitalized" ]]; then
            capitalized="$display_name"
          fi
          item_names+=("$capitalized")
        else
          # Fallback to slug if display name is empty
          item_names+=("$project_slug")
        fi
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
  local fuzzy_hint=""
  if [[ "${GTD_FUZZY_SEARCH:-false}" == "true" ]]; then
    fuzzy_hint=" (fuzzy search enabled)"
  fi
  echo -n "Select ${item_type} (number or partial name${fuzzy_hint}): " >&2
  read user_input
  
  if [[ -z "$user_input" ]]; then
    return 1
  fi
  
  # Check if it's a number
  if [[ "$user_input" =~ ^[0-9]+$ ]]; then
    local selected_index=$((user_input - 1))
    if [[ $selected_index -ge 0 && $selected_index -lt $item_count ]]; then
      # For projects, return the directory name (basename of directory)
      # For other items, return the display name
      if [[ "$item_type" == "project" ]]; then
        local project_path="${item_paths[$selected_index]}"
        # If it's a README.md file, get the parent directory
        # If it's already a directory, use it directly
        local project_dir_name=""
        if [[ -f "$project_path" ]]; then
          project_dir_name=$(basename "$(dirname "$project_path")")
        else
          project_dir_name=$(basename "$project_path")
        fi
        # Remove any trailing hyphens or spaces
        project_dir_name=$(echo "$project_dir_name" | sed 's/[- ]*$//')
        echo "$project_dir_name"
      else
        echo "${item_names[$selected_index]}"
      fi
      return 0
    else
      echo "❌ Invalid number. Please select 1-$item_count" >&2
      return 1
    fi
  fi
  
  # Check if fuzzy search is enabled (via environment variable)
  local use_fuzzy="${GTD_FUZZY_SEARCH:-false}"
  
  # Try partial name matching (case-insensitive) or fuzzy search
  # bash 3.2 compatible - no declare -a
  matches=()
  match_indices=()
  match_scores=()
  
  if [[ "$use_fuzzy" == "true" ]]; then
    # Get the correct Python executable (venv or Homebrew, not system Python)
    local python_cmd=""
    if declare -f gtd_get_mcp_python &>/dev/null; then
      python_cmd=$(gtd_get_mcp_python 2>/dev/null || echo "")
    fi
    if [[ -z "$python_cmd" ]]; then
      # Fallback: check for Homebrew Python or system python3
      if [[ -f "/opt/homebrew/bin/python3" ]]; then
        python_cmd="/opt/homebrew/bin/python3"
      elif command -v python3 &>/dev/null; then
        python_cmd="python3"
      fi
    fi
    
    if [[ -n "$python_cmd" ]] && command -v "$python_cmd" &>/dev/null; then
    # Use Python difflib for fuzzy matching (built-in, no dependencies)
    # Pass data via stdin to avoid bash array expansion issues
    local fuzzy_output=""
    fuzzy_output=$({
      echo "$user_input"
      for i in "${!item_names[@]}"; do
        echo "${item_names[$i]}"
        echo "${item_paths[$i]}"
      done
    } | "$python_cmd" <<'PYTHON_EOF'
import sys
import difflib

# Read user input (first line)
user_input = sys.stdin.readline().strip()

# Read item names and paths (pairs)
item_names = []
item_paths = []
while True:
    name = sys.stdin.readline().strip()
    if not name:
        break
    path = sys.stdin.readline().strip()
    item_names.append(name)
    item_paths.append(path)

# Calculate fuzzy match scores
matches = []
match_indices = []
match_scores = []

for i, display_name in enumerate(item_names):
    file_base = item_paths[i].split('/')[-1].replace('.md', '')
    display_name_lower = display_name.lower()
    file_base_lower = file_base.lower()
    user_input_lower = user_input.lower()
    
    # First check for substring match (case-insensitive) - this is a perfect match
    if user_input_lower in display_name_lower or user_input_lower in file_base_lower:
        # Substring match gets highest score
        matches.append(display_name)
        match_indices.append(i)
        match_scores.append(1.0)
    else:
        # Use fuzzy matching for partial/typo matches
        name_score = difflib.SequenceMatcher(None, user_input_lower, display_name_lower).ratio()
        file_score = difflib.SequenceMatcher(None, user_input_lower, file_base_lower).ratio()
        score = max(name_score, file_score)
        # Lower threshold to 0.2 to catch more matches
        if score >= 0.2:
            matches.append(display_name)
            match_indices.append(i)
            match_scores.append(score)

# Sort by score (highest first)
if matches:
    sorted_data = sorted(zip(match_scores, matches, match_indices), reverse=True)
    match_scores, matches, match_indices = zip(*sorted_data)
    
    # Output in format: score|display_name|index (one per line)
    for score, name, idx in zip(match_scores, matches, match_indices):
        print(f"{score}|{name}|{idx}")
PYTHON_EOF
)
    
    # Parse fuzzy results
    if [[ -n "$fuzzy_output" ]]; then
      while IFS='|' read -r score name idx; do
        if [[ -n "$score" && -n "$name" && -n "$idx" ]]; then
          matches+=("$name")
          match_indices+=($idx)
          match_scores+=("$score")
        fi
      done <<< "$fuzzy_output"
    fi
    else
      # Fallback to partial matching if Python not available
      for i in "${!item_names[@]}"; do
        local display_name="${item_names[$i]}"
        local item_path="${item_paths[$i]}"
        local file_base=$(basename "$item_path" .md)
        local display_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
        local file_base_lower=$(echo "$file_base" | tr '[:upper:]' '[:lower:]')
        local input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
        
        if [[ "$display_lower" == *"$input_lower"* ]] || [[ "$file_base_lower" == *"$input_lower"* ]]; then
          matches+=("$display_name")
          match_indices+=($i)
        fi
      done
    fi
  else
    # Original partial name matching (case-insensitive)
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
        match_scores+=("1.0")  # Perfect match for partial
      fi
    done
  fi
  
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
        # For projects, return the directory name instead of display name
        if [[ "$item_type" == "project" ]]; then
          local match_array_index="${match_indices[$selected_index]}"
          local project_path="${item_paths[$match_array_index]}"
          # If it's a README.md file, get the parent directory
          # If it's already a directory, use it directly
          local project_dir_name=""
          if [[ -f "$project_path" ]]; then
            project_dir_name=$(basename "$(dirname "$project_path")")
          else
            project_dir_name=$(basename "$project_path")
          fi
          # Remove any trailing hyphens or spaces
          project_dir_name=$(echo "$project_dir_name" | sed 's/[- ]*$//')
          echo "$project_dir_name"
        else
          echo "${matches[$selected_index]}"
        fi
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
  # Available personas array (bash 3.2 compatible - no declare -a)
  personas=("hank" "david" "cal" "james" "marie" "warren" "sheryl" "tim" "george" "john" "jon" "bob" "fred" "louiza" "spiderman" "ironman" "squirrelgirl" "harley" "deadpool" "rogue" "esther" "gottman" "gary" "brene" "romance" "kettlebell" "maxfit" "dumbbell" "dipbar" "kelsey" "kent" "charity" "rich" "goggins" "dean" "bioneer" "harry" "murphy" "joe" "skippy" "sherlock" "picard" "sandy" "spongebob" "matt" "brennan" "chris" "aabria" "jeremy" "kingmaker-char")
  
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
      matt) echo "Matt Mercer - Storytelling, narrative structure, character development, epic adventures, emotional depth" ;;
      brennan) echo "Brennan Lee Mulligan - Fast-paced gameplay, creative problem-solving, improvisation, high-energy storytelling" ;;
      chris) echo "Chris Perkins - Game design, world-building, creative mechanics, memorable adventures, system design" ;;
      aabria) echo "Aabria Iyengar - Collaborative storytelling, diverse narratives, inclusive stories, character development" ;;
      jeremy) echo "Jeremy Crawford - Rules expertise, game mechanics, system design, understanding complex systems" ;;
      kingmaker-char) echo "Rakasha Elka - Pathfinder Kingmaker character, roleplay advice, character decision-making" ;;
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
  # bash 3.2 compatible - no declare -a
  matches=()
  match_indices=()
  
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


