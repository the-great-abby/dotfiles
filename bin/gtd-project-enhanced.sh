#!/bin/bash
# Enhanced Project & Goal Tracking Features
# Provides project health dashboard, stalled project detection, and Goal → Project → Task hierarchy

# Load config
GTD_CONFIG_FILE="$HOME/.gtd_config"
if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
  GTD_CONFIG_FILE="$HOME/code/dotfiles/zsh/.gtd_config"
elif [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
  GTD_CONFIG_FILE="$HOME/code/personal/dotfiles/zsh/.gtd_config"
fi

if [[ -f "$GTD_CONFIG_FILE" ]]; then
  source "$GTD_CONFIG_FILE"
fi

# Source common GTD helpers (DRY - reuse existing helpers)
GTD_COMMON="$HOME/code/dotfiles/bin/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON"
else
  echo "Warning: gtd-common.sh not found. Some features may not work." >&2
fi

# GTD_BASE_DIR is already set by init_gtd_paths in gtd-common.sh (DRY - reuse existing helper)
PROJECTS_PATH="${PROJECTS_PATH:-${GTD_BASE_DIR}/${GTD_PROJECTS_DIR:-1-projects}}"
TASKS_PATH="${TASKS_PATH:-${GTD_BASE_DIR}/${GTD_TASKS_DIR:-3-tasks}}"
GOALS_DIR="${GOALS_DIR:-${GTD_BASE_DIR}/${GTD_GOALS_DIR:-goals}}"
ARCHIVE_PATH="${GTD_BASE_DIR}/${GTD_ARCHIVE_DIR:-6-archive}"

# Helper: Get frontmatter value
get_frontmatter_value() {
  local file="$1"
  local key="$2"
  grep "^${key}:" "$file" 2>/dev/null | head -1 | cut -d':' -f2 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

# Helper: Get last activity date for a project
get_project_last_activity() {
  local project_dir="$1"
  local latest_date=""
  
  # Check README modification time
  local readme="${project_dir}/README.md"
  if [[ -f "$readme" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      latest_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$readme" 2>/dev/null)
    else
      latest_date=$(stat -c "%y" "$readme" 2>/dev/null | cut -d' ' -f1)
    fi
  fi
  
  # Check task modification times
  for task_file in "${project_dir}"/*.md; do
    if [[ -f "$task_file" ]] && [[ "$(basename "$task_file")" != "README.md" ]]; then
      local task_date
      if [[ "$OSTYPE" == "darwin"* ]]; then
        task_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$task_file" 2>/dev/null)
      else
        task_date=$(stat -c "%y" "$task_file" 2>/dev/null | cut -d' ' -f1)
      fi
      
      if [[ "$task_date" > "$latest_date" ]]; then
        latest_date="$task_date"
      fi
    fi
  done
  
  echo "${latest_date:-unknown}"
}

# Helper: Count blocked tasks in a project
count_blocked_tasks() {
  local project_dir="$1"
  local blocked=0
  
  for task_file in "${project_dir}"/*.md; do
    if [[ -f "$task_file" ]] && [[ "$(basename "$task_file")" != "README.md" ]]; then
      local status=$(get_frontmatter_value "$task_file" "status")
      # Check if task has "blocked" tag or "blocked: true" in frontmatter
      local blocked_tag=$(get_frontmatter_value "$task_file" "blocked")
      if [[ "$status" == "blocked" ]] || [[ "$blocked_tag" == "true" ]] || grep -q "blocked\|blocking" "$task_file" 2>/dev/null; then
        ((blocked++))
      fi
    fi
  done
  
  echo "$blocked"
}

# Project Health Dashboard
project_health_dashboard() {
  echo "📊 Project Health Dashboard"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
  
  if [[ ${#projects[@]} -eq 0 ]]; then
    echo "No projects found."
    return 0
  fi
  
  # Color codes
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  NC='\033[0m'
  
  for project_dir in "${projects[@]}"; do
    local project_name=$(basename "$project_dir")
    local readme="${project_dir}/README.md"
    
    if [[ ! -f "$readme" ]]; then
      continue
    fi
    
    local status=$(get_frontmatter_value "$readme" "status")
    if [[ "$status" != "active" ]]; then
      continue
    fi
    
    # Get project metrics
    local tasks=($(find "$project_dir" -name "*.md" ! -name "README.md" 2>/dev/null))
    local active_tasks=0
    local completed_tasks=0
    local blocked_tasks=$(count_blocked_tasks "$project_dir")
    
    for task_file in "${tasks[@]}"; do
      local task_status=$(get_frontmatter_value "$task_file" "status")
      if [[ "$task_status" == "active" ]]; then
        ((active_tasks++))
      elif [[ "$task_status" == "done" ]] || [[ "$task_status" == "completed" ]]; then
        ((completed_tasks++))
      fi
    done
    
    local total_tasks=${#tasks[@]}
    local last_activity=$(get_project_last_activity "$project_dir")
    
    # Determine health status
    local health_status=""
    local health_color=""
    
    if [[ $blocked_tasks -gt 0 ]]; then
      health_status="⚠️  BLOCKED"
      health_color="$RED"
    elif [[ $active_tasks -eq 0 ]] && [[ $total_tasks -gt 0 ]]; then
      health_status="✅ COMPLETE"
      health_color="$GREEN"
    elif [[ $active_tasks -gt 0 ]]; then
      health_status="🟢 ACTIVE"
      health_color="$GREEN"
    else
      health_status="🟡 NO TASKS"
      health_color="$YELLOW"
    fi
    
    # Calculate days since last activity
    local days_since_activity=""
    if [[ "$last_activity" != "unknown" ]] && [[ "$last_activity" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      local today=$(date +"%Y-%m-%d")
      local today_ts
      local last_ts
      
      if [[ "$OSTYPE" == "darwin"* ]]; then
        today_ts=$(date -j -f "%Y-%m-%d" "$today" +%s 2>/dev/null || echo "0")
        last_ts=$(date -j -f "%Y-%m-%d" "$last_activity" +%s 2>/dev/null || echo "0")
      else
        today_ts=$(date -d "$today" +%s 2>/dev/null || echo "0")
        last_ts=$(date -d "$last_activity" +%s 2>/dev/null || echo "0")
      fi
      
      if [[ "$today_ts" != "0" ]] && [[ "$last_ts" != "0" ]]; then
        local diff=$(( (today_ts - last_ts) / 86400 ))
        days_since_activity=" ($diff days ago)"
        
        if [[ $diff -gt 14 ]]; then
          health_status="🔴 STALLED"
          health_color="$RED"
        elif [[ $diff -gt 7 ]]; then
          health_status="🟡 INACTIVE"
          health_color="$YELLOW"
        fi
      fi
    fi
    
    # Get outcome if defined
    local outcome=$(get_frontmatter_value "$readme" "outcome")
    local goal=$(get_frontmatter_value "$readme" "goal")
    
    echo -e "${health_color}${health_status}${NC} ${project_name}"
    echo "   Active Tasks: $active_tasks | Completed: $completed_tasks | Blocked: $blocked_tasks | Total: $total_tasks"
    echo "   Last Activity: $last_activity${days_since_activity}"
    if [[ -n "$outcome" ]]; then
      echo "   Outcome: $outcome"
    fi
    if [[ -n "$goal" ]]; then
      echo "   Goal: $goal"
    fi
    echo ""
  done
}

# Detect stalled projects (AI-powered)
detect_stalled_projects() {
  echo "🔍 Detecting Stalled Projects"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  local stalled_projects=()
  local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
  
  for project_dir in "${projects[@]}"; do
    local project_name=$(basename "$project_dir")
    local readme="${project_dir}/README.md"
    
    if [[ ! -f "$readme" ]]; then
      continue
    fi
    
    local status=$(get_frontmatter_value "$readme" "status")
    if [[ "$status" != "active" ]]; then
      continue
    fi
    
    local last_activity=$(get_project_last_activity "$project_dir")
    
    # Check if stalled (no activity in 14+ days)
    if [[ "$last_activity" != "unknown" ]] && [[ "$last_activity" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      local today=$(date +"%Y-%m-%d")
      local diff
      local today_ts
      local last_ts
      
      if [[ "$OSTYPE" == "darwin"* ]]; then
        today_ts=$(date -j -f "%Y-%m-%d" "$today" +%s 2>/dev/null || echo "0")
        last_ts=$(date -j -f "%Y-%m-%d" "$last_activity" +%s 2>/dev/null || echo "0")
      else
        today_ts=$(date -d "$today" +%s 2>/dev/null || echo "0")
        last_ts=$(date -d "$last_activity" +%s 2>/dev/null || echo "0")
      fi
      
      if [[ "$today_ts" != "0" ]] && [[ "$last_ts" != "0" ]]; then
        diff=$(( (today_ts - last_ts) / 86400 ))
        
        if [[ $diff -ge 14 ]]; then
          # Additional checks: blocked tasks or no active tasks
          local blocked_tasks=$(count_blocked_tasks "$project_dir")
          local tasks=($(find "$project_dir" -name "*.md" ! -name "README.md" 2>/dev/null))
          local active_tasks=0
          
          for task_file in "${tasks[@]}"; do
            local task_status=$(get_frontmatter_value "$task_file" "status")
            if [[ "$task_status" == "active" ]]; then
              ((active_tasks++))
            fi
          done
          
          # Consider stalled if: no activity in 14+ days AND (blocked tasks OR no active tasks)
          if [[ $blocked_tasks -gt 0 ]] || [[ $active_tasks -eq 0 ]]; then
            stalled_projects+=("${project_name}:${diff}:${blocked_tasks}:${active_tasks}")
          fi
        fi
      fi
    fi
  done
  
  if [[ ${#stalled_projects[@]} -eq 0 ]]; then
    echo "✅ No stalled projects detected!"
    echo ""
    return 0
  fi
  
  echo "⚠️  Found ${#stalled_projects[@]} potentially stalled project(s):"
  echo ""
  
  for project_info in "${stalled_projects[@]}"; do
    local project_name="${project_info%%:*}"
    local remaining="${project_info#*:}"
    local days="${remaining%%:*}"
    local blocked="${remaining#*:}"
    blocked="${blocked%%:*}"
    local active="${remaining##*:}"
    
    echo "🔴 $project_name"
    echo "   • No activity for $days days"
    echo "   • Blocked tasks: $blocked"
    echo "   • Active tasks: $active"
    echo ""
  done
  
  # Use AI to suggest actions if available
  if command -v gtd-advise &>/dev/null; then
    echo "💡 Getting AI suggestions for stalled projects..."
    echo ""
    
    local stalled_list=""
    for project_info in "${stalled_projects[@]}"; do
      local project_name="${project_info%%:*}"
      local remaining="${project_info#*:}"
      local days="${remaining%%:*}"
      stalled_list="${stalled_list}\n- ${project_name} (inactive for ${days} days)"
    done
    
    echo "AI Analysis:"
    gtd-advise project_manager "I have these stalled projects:${stalled_list}\n\nWhat actions should I take? Should I revive them, break them down into smaller tasks, or archive them?" 2>/dev/null | head -30 || echo "  (AI analysis unavailable)"
    echo ""
  fi
}

# Link project to goal
link_project_to_goal() {
  local project_name="$1"
  local goal_name="$2"
  
  if [[ -z "$project_name" ]] || [[ -z "$goal_name" ]]; then
    echo "Usage: gtd-project-enhanced link-goal <project-name> <goal-name>"
    return 1
  fi
  
  project_name=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  local project_dir="${PROJECTS_PATH}/${project_name}"
  local readme="${project_dir}/README.md"
  
  if [[ ! -f "$readme" ]]; then
    echo "❌ Project not found: $project_name"
    return 1
  fi
  
  # Check if file has frontmatter (starts with ---)
  local has_frontmatter=false
  if head -1 "$readme" 2>/dev/null | grep -q "^---"; then
    has_frontmatter=true
  fi
  
  if [[ "$has_frontmatter" == "true" ]]; then
    # File has frontmatter - update or add goal field
    if grep -q "^goal:" "$readme" 2>/dev/null; then
      # Update existing goal field
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^goal:.*/goal: ${goal_name}/" "$readme"
      else
        sed -i "s/^goal:.*/goal: ${goal_name}/" "$readme"
      fi
    else
      # Add goal field after status (or after first frontmatter line if no status)
      if grep -q "^status:" "$readme" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "/^status:/a\\
goal: ${goal_name}
" "$readme"
        else
          sed -i "/^status:/a\\goal: ${goal_name}" "$readme"
        fi
      else
        # No status field, add after first line of frontmatter (after ---)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "1a\\
goal: ${goal_name}
" "$readme"
        else
          sed -i "1a\\goal: ${goal_name}" "$readme"
        fi
      fi
    fi
  else
    # File doesn't have frontmatter - add it at the beginning
    local temp_file=$(mktemp)
    echo "---" > "$temp_file"
    echo "goal: ${goal_name}" >> "$temp_file"
    echo "---" >> "$temp_file"
    echo "" >> "$temp_file"
    cat "$readme" >> "$temp_file"
    mv "$temp_file" "$readme"
  fi
  
  echo "✓ Linked project '$project_name' to goal '$goal_name'"
}

# Get projects for a goal
get_projects_for_goal() {
  local goal_name="$1"
  
  if [[ -z "$goal_name" ]]; then
    echo "Usage: gtd-project-enhanced projects-for-goal <goal-name>"
    return 1
  fi
  
  echo "📁 Projects linked to goal: $goal_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
  local found=0
  
  for project_dir in "${projects[@]}"; do
    local readme="${project_dir}/README.md"
    if [[ ! -f "$readme" ]]; then
      continue
    fi
    
    local linked_goal=$(get_frontmatter_value "$readme" "goal")
    if [[ "$linked_goal" == "$goal_name" ]]; then
      ((found++))
      local project_name=$(basename "$project_dir")
      local status=$(get_frontmatter_value "$readme" "status")
      local tasks=($(find "$project_dir" -name "*.md" ! -name "README.md" 2>/dev/null))
      
      echo "[$found] $project_name"
      echo "     Status: $status | Tasks: ${#tasks[@]}"
      echo ""
    fi
  done
  
  if [[ $found -eq 0 ]]; then
    echo "No projects linked to this goal."
  fi
}

# Show Goal → Project → Task hierarchy
show_goal_hierarchy() {
  local goal_name="${1:-}"
  
  echo "🎯 Goal → Project → Task Hierarchy"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if [[ -n "$goal_name" ]]; then
    # Show hierarchy for specific goal
    local goal_file="${GOALS_DIR}/${goal_name// /_}.md"
    if [[ ! -f "$goal_file" ]]; then
      echo "❌ Goal not found: $goal_name"
      return 1
    fi
    
    local progress=$(get_frontmatter_value "$goal_file" "progress")
    local goal_status=$(get_frontmatter_value "$goal_file" "status")
    
    echo "Goal: $goal_name"
    echo "Progress: ${progress}% | Status: $goal_status"
    echo ""
    echo "Projects:"
    
    get_projects_for_goal "$goal_name" | grep -v "^━━" | grep -v "^$" | sed 's/^/  /'
    
  else
    # Show all goals with their projects
    for goal_file in "$GOALS_DIR"/*.md; do
      [[ ! -f "$goal_file" ]] && continue
      
      local goal_name=$(get_frontmatter_value "$goal_file" "name")
      local progress=$(get_frontmatter_value "$goal_file" "progress")
      local goal_status=$(get_frontmatter_value "$goal_file" "status")
      
      if [[ "$goal_status" != "active" ]]; then
        continue
      fi
      
      echo "🎯 $goal_name (${progress}%)"
      echo ""
      
      # Find projects linked to this goal
      local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
      local project_count=0
      
      for project_dir in "${projects[@]}"; do
        local readme="${project_dir}/README.md"
        if [[ ! -f "$readme" ]]; then
          continue
        fi
        
        local linked_goal=$(get_frontmatter_value "$readme" "goal")
        if [[ "$linked_goal" == "$goal_name" ]]; then
          ((project_count++))
          local project_name=$(basename "$project_dir")
          local tasks=($(find "$project_dir" -name "*.md" ! -name "README.md" 2>/dev/null))
          local active_tasks=0
          
          for task_file in "${tasks[@]}"; do
            local task_status=$(get_frontmatter_value "$task_file" "status")
            if [[ "$task_status" == "active" ]]; then
              ((active_tasks++))
            fi
          done
          
          echo "  📁 $project_name"
          echo "     Tasks: $active_tasks active / ${#tasks[@]} total"
          
          # Show first few active tasks
          local shown=0
          for task_file in "${tasks[@]}"; do
            if [[ $shown -ge 3 ]]; then
              break
            fi
            local task_status=$(get_frontmatter_value "$task_file" "status")
            if [[ "$task_status" == "active" ]]; then
              local task_title=$(grep "^# " "$task_file" 2>/dev/null | head -1 | sed 's/^# //')
              if [[ -n "$task_title" ]]; then
                echo "     • $task_title"
                ((shown++))
              fi
            fi
          done
          echo ""
        fi
      done
      
      if [[ $project_count -eq 0 ]]; then
        echo "  (No projects linked to this goal)"
        echo ""
      fi
      
      echo ""
    done
  fi
}

# Main function
main() {
  case "${1:-dashboard}" in
    dashboard)
      project_health_dashboard
      ;;
    detect-stalled)
      detect_stalled_projects
      ;;
    link-goal)
      shift
      link_project_to_goal "$1" "$2"
      ;;
    projects-for-goal)
      shift
      get_projects_for_goal "$1"
      ;;
    hierarchy)
      shift
      show_goal_hierarchy "$1"
      ;;
    *)
      echo "Usage: gtd-project-enhanced [command]"
      echo ""
      echo "Commands:"
      echo "  dashboard                  - Show project health dashboard"
      echo "  detect-stalled             - Detect stalled projects"
      echo "  link-goal <proj> <goal>    - Link project to goal"
      echo "  projects-for-goal <goal>   - Show projects for a goal"
      echo "  hierarchy [goal]           - Show Goal → Project → Task hierarchy"
      exit 1
      ;;
  esac
}

# If run directly, execute main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
