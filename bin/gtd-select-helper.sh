#!/bin/bash
# GTD Selection Helper Functions
# Source this file in your scripts to use the selection functions
#
# Usage:
#   source "$(dirname "$0")/gtd-select-helper.sh"  # or full path
#   selected=$(select_from_list "projects" "$PROJECTS_PATH" "project")
#   echo "Selected: $selected"

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
          name=$(grep "^title:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
        fi
        if [[ -z "$name" ]]; then
          name=$(basename "$file" .md)
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
  
  # Display numbered list
  echo ""
  for i in "${!item_names[@]}"; do
    local num=$((i + 1))
    echo "  ${num}) ${item_names[$i]}"
  done
  echo ""
  
  # Get user input
  read -p "Select ${item_type} (number or partial name): " user_input
  
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
    if [[ "${display_name,,}" == *"${user_input,,}"* ]] || [[ "${file_base,,}" == *"${user_input,,}"* ]]; then
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
    # Multiple matches - show them and ask again
    echo ""
    echo "Multiple matches found:"
    echo ""
    for i in "${!matches[@]}"; do
      local num=$((i + 1))
      echo "  ${num}) ${matches[$i]}"
    done
    echo ""
    read -p "Select ${item_type} (number): " user_input
    
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


