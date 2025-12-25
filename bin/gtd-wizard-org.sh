#!/bin/bash
# IMPORTANT: This script must be compatible with bash 3.2 (macOS default)
# See .cursorrules for bash compatibility guidelines
# DO NOT use associative arrays (declare -A) or bash 4+ features
#
# GTD Wizard Organization Functions
# Organization wizards for tasks, projects, areas, MOCs, habits

# Show Eisenhower Matrix Dashboard
show_matrix_dashboard() {
  # Paths are already set by init_gtd_paths in gtd-common.sh (DRY - reuse existing helper)
  # Use standardized helper function for frontmatter (DRY - reuse existing helper)
  # gtd_get_frontmatter_value is available from gtd-common.sh
  
  # Collect all active tasks
  local all_tasks=()
  
  # Get tasks from tasks directory
  if [[ -d "$TASKS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" ]] && continue
      # Use standardized helper function (DRY - reuse existing helper)
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        all_tasks+=("$task_file")
      fi
    done < <(find "$TASKS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  # Get tasks from project directories
  if [[ -d "$PROJECTS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
      # Use standardized helper function (DRY - reuse existing helper)
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        all_tasks+=("$task_file")
      fi
    done < <(find "$PROJECTS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  # Group tasks by priority
  local urgent_important=()
  local not_urgent_important=()
  local urgent_not_important=()
  local not_urgent_not_important=()
  local no_priority=()
  
  for task_file in "${all_tasks[@]}"; do
    # Use standardized helper functions (DRY - reuse existing helpers)
    local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
    local task_name=$(head -20 "$task_file" | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
    local task_id=$(basename "$task_file" .md)
    local project=$(gtd_get_frontmatter_value "$task_file" "project")
    local context=$(gtd_get_frontmatter_value "$task_file" "context")
    
    case "$priority" in
      urgent_important)
        urgent_important+=("$task_file|$task_name|$task_id|$project|$context")
        ;;
      not_urgent_important)
        not_urgent_important+=("$task_file|$task_name|$task_id|$project|$context")
        ;;
      urgent_not_important)
        urgent_not_important+=("$task_file|$task_name|$task_id|$project|$context")
        ;;
      not_urgent_not_important)
        not_urgent_not_important+=("$task_file|$task_name|$task_id|$project|$context")
        ;;
      *)
        no_priority+=("$task_file|$task_name|$task_id|$project|$context")
        ;;
    esac
  done
  
  clear
  gtd_print_header "Eisenhower Matrix Dashboard" "📊"
  echo ""
  echo -e "${BOLD}The Eisenhower Matrix helps you prioritize by urgency and importance:${NC}"
  echo ""
  echo -e "  ${RED}🔴 Urgent & Important${NC} = Do First (Crises, deadlines, emergencies)"
  echo -e "  ${BLUE}🔵 Not Urgent & Important${NC} = Schedule (Goals, planning, prevention)"
  echo -e "  ${YELLOW}🟡 Urgent & Not Important${NC} = Delegate (Interruptions, some meetings)"
  echo -e "  ${GRAY}⚪ Not Urgent & Not Important${NC} = Eliminate (Time wasters, distractions)"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Display matrix
  echo -e "${BOLD}                        URGENT              NOT URGENT${NC}"
  echo -e "${BOLD}                    ─────────────────────────────────────${NC}"
  echo ""
  
  # Quadrant 1: Urgent & Important
  echo -e "${RED}${BOLD}IMPORTANT    🔴 DO FIRST${NC}${NC}"
  echo -e "${RED}(${#urgent_important[@]} tasks)${NC}"
  echo ""
  if [[ ${#urgent_important[@]} -eq 0 ]]; then
    gtd_empty_state "tasks" ""  # Empty state without hint
  else
    for task_entry in "${urgent_important[@]}"; do
      IFS='|' read -r task_file task_name task_id project context <<< "$task_entry"
      echo -e "  • ${BOLD}${task_name}${NC}"
      echo "    ID: $task_id"
      if [[ -n "$project" ]]; then
        echo "    Project: $project"
      fi
      if [[ -n "$context" ]]; then
        echo "    Context: $context"
      fi
      echo ""
    done
  fi
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Quadrant 2: Not Urgent & Important
  echo -e "${BLUE}${BOLD}             📅 SCHEDULE${NC}${NC}"
  echo -e "${BLUE}(${#not_urgent_important[@]} tasks)${NC}"
  echo ""
  if [[ ${#not_urgent_important[@]} -eq 0 ]]; then
    gtd_empty_state "tasks" ""  # Empty state without hint
  else
    for task_entry in "${not_urgent_important[@]}"; do
      IFS='|' read -r task_file task_name task_id project context <<< "$task_entry"
      echo -e "  • ${BOLD}${task_name}${NC}"
      echo "    ID: $task_id"
      if [[ -n "$project" ]]; then
        echo "    Project: $project"
      fi
      if [[ -n "$context" ]]; then
        echo "    Context: $context"
      fi
      echo ""
    done
  fi
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Quadrant 3: Urgent & Not Important
  echo -e "${YELLOW}${BOLD}NOT          ⚡ DELEGATE${NC}${NC}"
  echo -e "${YELLOW}IMPORTANT  (${#urgent_not_important[@]} tasks)${NC}"
  echo ""
  if [[ ${#urgent_not_important[@]} -eq 0 ]]; then
    gtd_empty_state "tasks" ""  # Empty state without hint
  else
    for task_entry in "${urgent_not_important[@]}"; do
      IFS='|' read -r task_file task_name task_id project context <<< "$task_entry"
      echo -e "  • ${BOLD}${task_name}${NC}"
      echo "    ID: $task_id"
      if [[ -n "$project" ]]; then
        echo "    Project: $project"
      fi
      if [[ -n "$context" ]]; then
        echo "    Context: $context"
      fi
      echo ""
    done
  fi
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Quadrant 4: Not Urgent & Not Important
  echo -e "${GRAY}             ❌ ELIMINATE${NC}"
  echo -e "${GRAY}(${#not_urgent_not_important[@]} tasks)${NC}"
  echo ""
  if [[ ${#not_urgent_not_important[@]} -eq 0 ]]; then
    gtd_empty_state "tasks" ""  # Empty state without hint
  else
    for task_entry in "${not_urgent_not_important[@]}"; do
      IFS='|' read -r task_file task_name task_id project context <<< "$task_entry"
      echo -e "  • ${BOLD}${task_name}${NC}"
      echo "    ID: $task_id"
      if [[ -n "$project" ]]; then
        echo "    Project: $project"
      fi
      if [[ -n "$context" ]]; then
        echo "    Context: $context"
      fi
      echo ""
    done
  fi
  
  # Show tasks without priority
  if [[ ${#no_priority[@]} -gt 0 ]]; then
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Tasks without priority (${#no_priority[@]}):${NC}"
    echo ""
    for task_entry in "${no_priority[@]}"; do
      IFS='|' read -r task_file task_name task_id project context <<< "$task_entry"
      echo -e "  • ${task_name} (ID: $task_id)"
    done
    echo ""
    echo "💡 Tip: Update priorities using 'gtd-task update <task-id>'"
  fi
  
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}Summary:${NC}"
  echo "  🔴 Do First: ${#urgent_important[@]}"
  echo "  📅 Schedule: ${#not_urgent_important[@]}"
  echo "  ⚡ Delegate: ${#urgent_not_important[@]}"
  echo "  ❌ Eliminate: ${#not_urgent_not_important[@]}"
  echo "  ⚠️  No Priority: ${#no_priority[@]}"
  echo ""
    gtd_quick_pause
}

# Prioritization wizard - review and manage priorities across the system
prioritization_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}🎯 Prioritization Review Wizard${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}What is Prioritization?${NC}"
    echo "  This wizard helps you review and manage priorities across your"
    echo "  entire GTD system - tasks, projects, areas, and MOCs."
    echo ""
    echo -e "${BOLD}What would you like to do?${NC}"
    echo ""
    echo "  1) 📋 View high-priority tasks"
    echo "  2) 📁 View prioritized areas"
    echo "  3) 📂 View prioritized projects"
    echo "  4) 🗺️  Create/Update Prioritization MOC"
    echo "  5) 🔄 Review and update priorities"
    echo "  6) 📊 Priority dashboard (all priorities at a glance)"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read priority_choice
    
    case "$priority_choice" in
      1)
        echo ""
        echo -e "${BOLD}${CYAN}📋 High-Priority Tasks${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Urgent & Important Tasks:"
        gtd-task list --priority=urgent_important --status=active 2>/dev/null || echo "  (none found)"
        echo ""
        echo "Not Urgent but Important Tasks:"
        gtd-task list --priority=not_urgent_important --status=active 2>/dev/null | head -10 || echo "  (none found)"
        echo ""
        gtd_quick_pause
        ;;
      2)
        echo ""
        echo -e "${BOLD}${CYAN}📁 Prioritized Areas${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Areas with current priorities:"
        echo ""
        # Use standardized path variable (DRY - reuse existing helper)
        if [[ -d "$AREAS_PATH" ]]; then
          local found_areas=false
          for area_dir in "$AREAS_PATH"/*/; do
            if [[ -d "$area_dir" ]]; then
              local area_name=$(basename "$area_dir")
              local area_file="${area_dir}${area_name}.md"
              if [[ -f "$area_file" ]]; then
                # Check if area has priorities section
                if grep -q "Current Priorities" "$area_file" 2>/dev/null; then
                  local priorities=$(grep -A 10 "Current Priorities" "$area_file" | grep -v "^###" | head -5 | sed 's/^/  /')
                  if [[ -n "$priorities" ]]; then
                    echo -e "${BOLD}${area_name}:${NC}"
                    echo "$priorities" | sed '/^$/d'
                    echo ""
                    found_areas=true
                  fi
                fi
              fi
            fi
          done
          if [[ "$found_areas" == "false" ]]; then
            echo "  No areas with priorities found."
            echo "  Use 'gtd-area review <area-name>' to add priorities to areas."
          fi
        else
          echo "  No areas directory found."
        fi
        echo ""
        gtd_quick_pause
        ;;
      3)
        echo ""
        echo -e "${BOLD}${CYAN}📂 Prioritized Projects${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Projects with high-priority tasks:"
        echo ""
        # Use standardized path variable (DRY - reuse existing helper)
        if [[ -d "$PROJECTS_PATH" ]]; then
          local found_projects=false
          for project_dir in "$PROJECTS_PATH"/*/; do
            if [[ -d "$project_dir" ]]; then
              local project_name=$(basename "$project_dir")
              # Check for high-priority tasks in this project
              local urgent_tasks=$(gtd-task list --priority=urgent_important --status=active 2>/dev/null | grep -i "$project_name" | head -3)
              if [[ -n "$urgent_tasks" ]]; then
                echo -e "${BOLD}${project_name}:${NC}"
                echo "$urgent_tasks" | sed 's/^/  /'
                echo ""
                found_projects=true
              fi
            fi
          done
          if [[ "$found_projects" == "false" ]]; then
            echo "  No projects with urgent/important tasks found."
          fi
        else
          echo "  No projects directory found."
        fi
        echo ""
        gtd_quick_pause
        ;;
      4)
        echo ""
        echo -e "${BOLD}${CYAN}🗺️  Prioritization MOC${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "This will create or update a 'Prioritization Review' MOC that"
        echo "organizes all your priority items (tasks, projects, areas) in one place."
        echo ""
        echo -e "${GREEN}y${NC} - Create/Update Prioritization MOC"
        echo -e "${YELLOW}n${NC} - Cancel"
        echo ""
        read -p "Choice: " create_moc
        
        if [[ "$create_moc" == "y" || "$create_moc" == "Y" ]]; then
          if command -v gtd-brain-moc &>/dev/null; then
            # Create or update the Prioritization MOC
            gtd-brain-moc create "Prioritization Review" "Central hub for reviewing and managing priorities across tasks, projects, areas, and MOCs. Updated regularly to track what matters most." 2>/dev/null || true
            
            echo ""
            echo "✓ Prioritization MOC created/updated!"
            echo ""
            echo "Next steps:"
            echo "  1. Add high-priority tasks: gtd-brain-moc add \"Prioritization Review\" <task-file> \"Projects\""
            echo "  2. Add prioritized areas: gtd-brain-moc add \"Prioritization Review\" <area-file> \"Areas\""
            echo "  3. Review regularly: gtd-wizard → Prioritization Review → View Prioritization MOC"
            echo ""
          else
            echo "⚠️  gtd-brain-moc command not found."
            echo "  MOCs are part of the Second Brain system."
          fi
        fi
        echo ""
        gtd_quick_pause
        ;;
      5)
        echo ""
        echo -e "${BOLD}${CYAN}🔄 Review and Update Priorities${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "What would you like to update?"
        echo ""
        echo "  1) Update task priorities"
        echo "  2) Update area priorities"
        echo "  3) Review project priorities"
        echo ""
        echo -e "${YELLOW}0)${NC} Cancel"
        echo ""
        read -p "Choice: " update_choice
        
        case "$update_choice" in
          1)
            echo ""
            echo "Listing tasks for priority update:"
            echo ""
            gtd-task list --status=active 2>/dev/null | head -20
            echo ""
            echo -n "Enter task ID to update priority (or press Enter to skip): "
            read task_id
            if [[ -n "$task_id" ]]; then
              gtd-task update "$task_id"
            fi
            ;;
          2)
            echo ""
            echo "Listing areas for priority review:"
            echo ""
            if command -v gtd-area &>/dev/null; then
              gtd-area list 2>/dev/null || echo "  No areas found"
              echo ""
              echo -n "Enter area name to review priorities (or press Enter to skip): "
              read area_name
              if [[ -n "$area_name" ]]; then
                gtd-area review "$area_name"
              fi
            else
              echo "  gtd-area command not available"
            fi
            ;;
          3)
            echo ""
            echo "Projects with tasks (review priorities by reviewing project tasks):"
            echo ""
            # Use standardized path variable (DRY - reuse existing helper)
            if [[ -d "$PROJECTS_PATH" ]]; then
              ls -1 "$PROJECTS_PATH" 2>/dev/null | head -10
            fi
            echo ""
            echo "Use 'gtd-wizard → Manage projects → Review project' to review project priorities"
            ;;
          0|"")
            ;;
          *)
            echo "Invalid choice"
            ;;
        esac
        echo ""
        gtd_quick_pause
        ;;
      6)
        show_matrix_dashboard
        ;;
      0|"")
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        gtd_quick_pause
        ;;
    esac
  done
}

task_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    gtd_print_header "Task Management Wizard" "✅"
    show_tasks_guide
    echo "What would you like to do?"
    echo ""
    echo "  1) Add a new task"
    echo "  2) List tasks"
    echo "  3) View a task"
    echo "  4) Complete a task"
    echo "  5) Update a task"
    echo "  6) Move task to project"
    echo "  7) Move task to area"
    echo "  8) Add note to task"
    echo "  9) 💬 Restructure with natural language"
    echo "  10) 🧹 Organize tasks (clean up backlog)"
    echo "  11) 📊 Review tasks by priority/project"
    echo "  12) ⭐ Favorite/Unfavorite Task"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read task_choice
    
    case "$task_choice" in
    1)
      echo ""
      echo -n "Task description: "
      read task_desc
      
      if [[ -z "$task_desc" ]]; then
        gtd_feedback error "No task description provided"
        return 1
      fi
      
      echo ""
      echo "Optional: Link to a project?"
      echo ""
      local project_name=""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        echo "Available projects:"
        selected_project=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$selected_project" ]]; then
          # Convert display name to slug format
          project_name=$(echo "$selected_project" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
        fi
      else
        echo -n "Project name (or press Enter to skip): "
        read project_input
        if [[ -n "$project_input" ]]; then
          project_name="$project_input"
        fi
      fi
      
      echo ""
      echo -n "Repository URL (GitHub/GitLab, or press Enter to skip): "
      read repo_url
      
      if [[ -n "$project_name" ]]; then
        if [[ -n "$repo_url" ]]; then
          gtd-task add "$task_desc" --project="$project_name" --repository="$repo_url"
        else
          gtd-task add "$task_desc" --project="$project_name"
        fi
      else
        if [[ -n "$repo_url" ]]; then
          gtd-task add "$task_desc" --repository="$repo_url"
        else
          gtd-task add "$task_desc"
        fi
      fi
      echo ""
      gtd_action_success "created" "task" "$task_desc"
      gtd_quick_pause
      ;;
    2)
      echo ""
      echo "What type of tasks would you like to review?"
      echo ""
      echo "  1) All tasks"
      echo "  2) Tasks with projects (project-related)"
      echo "  3) Tasks without projects (standalone tasks)"
      echo ""
      echo -n "Choose: "
      read list_choice
      
      case "$list_choice" in
        1)
          echo ""
          gtd-task list
          ;;
        2)
          echo ""
          gtd-task list --project-only
          ;;
        3)
          echo ""
          gtd-task list --no-project
          ;;
        *)
          echo ""
          gtd-task list
          ;;
      esac
      echo ""
      gtd_quick_pause
      ;;
    3)
      echo ""
      echo "Select a task to view:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        local task_list_output=$(gtd-task list)
        echo "$task_list_output"
        echo ""
        echo -n "Task number or ID to view: "
        read task_input
        
        if [[ -z "$task_input" ]]; then
          gtd_feedback error "No task provided"
          gtd_quick_pause
          return 0
        fi
        
        task_id=$(get_task_id_by_number "$task_input" "$task_list_output")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "Task not found: $task_input"
          gtd_quick_pause
          return 0
        fi
      fi
      
      gtd-task view "$task_id"
      echo ""
      gtd_quick_pause
      ;;
    4)
      echo ""
      echo "Select a task to complete:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        local task_list_output=$(gtd-task list)
        echo "$task_list_output"
        echo ""
        echo -n "Task number or ID to complete: "
        read task_input
        
        if [[ -z "$task_input" ]]; then
          gtd_feedback error "No task provided"
          gtd_quick_pause
          return 0
        fi
        
        task_id=$(get_task_id_by_number "$task_input" "$task_list_output")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "Task not found: $task_input"
          gtd_quick_pause
          return 0
        fi
      fi
      
      gtd-task complete "$task_id"
      echo ""
      gtd_quick_pause
      ;;
    5)
      echo ""
      echo "Select a task to update:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        local task_list_output=$(gtd-task list)
        echo "$task_list_output"
        echo ""
        echo -n "Task number or ID to update: "
        read task_input
        
        if [[ -z "$task_input" ]]; then
          gtd_feedback error "No task provided"
          gtd_quick_pause
          return 0
        fi
        
        task_id=$(get_task_id_by_number "$task_input" "$task_list_output")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "Task not found: $task_input"
          gtd_quick_pause
          return 0
        fi
      fi
      
      echo -n "New description: "
      read new_desc
      gtd-task update "$task_id" "$new_desc"
      echo ""
      gtd_quick_pause
      ;;
    6)
      echo ""
      echo "Moving a task to a project..."
      echo ""
      echo "Select a task to move:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        local task_list_output=$(gtd-task list)
        echo "$task_list_output"
        echo ""
        echo -n "Task number or ID to move: "
        read task_input
        
        if [[ -z "$task_input" ]]; then
          gtd_feedback error "No task provided"
          gtd_quick_pause
          return 0
        fi
        
        task_id=$(get_task_id_by_number "$task_input" "$task_list_output")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "Task not found: $task_input"
          gtd_quick_pause
          return 0
        fi
      fi
      
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        echo "Select project to move task to:"
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          # Convert to slug format
          project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          gtd-task move "$task_id" "$project_slug"
          gtd_action_success "moved" "task" "to project"
        fi
      else
        echo -n "Project name (or press Enter to skip): "
        read project_input
        if [[ -n "$project_input" ]]; then
          gtd-task move "$task_id" "$project_input"
          gtd_action_success "moved" "task" "to project"
        fi
      fi
      echo ""
      gtd_quick_pause
      ;;
    7)
      echo ""
      echo "Moving a task to an area..."
      echo ""
      echo "Select a task to move:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        local task_list_output=$(gtd-task list)
        echo "$task_list_output"
        echo ""
        echo -n "Task number or ID to move to area: "
        read task_input
        
        if [[ -z "$task_input" ]]; then
          gtd_feedback error "No task provided"
          gtd_quick_pause
          return 0
        fi
        
        task_id=$(get_task_id_by_number "$task_input" "$task_list_output")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "Task not found: $task_input"
          gtd_quick_pause
          return 0
        fi
      fi
      
      # Find the task file
      # Use standardized helper function (DRY - reuse existing helper)
      local task_file=$(find_task_file "$task_id")
      
      if [[ -z "$task_file" || ! -f "$task_file" ]]; then
        gtd_feedback error "Task file not found: $task_id"
        gtd_quick_pause
        return 0
      fi
      
      echo ""
      # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
        echo "Select area to move task to:"
        area_name=$(select_from_list "area" "$AREAS_PATH" "name")
        if [[ -n "$area_name" ]]; then
          # Normalize area name
          area_slug=$(echo "$area_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          # Update the task's area field
          if grep -q "^area:" "$task_file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "s/^area:.*/area: ${area_slug}/" "$task_file"
            else
              sed -i "s/^area:.*/area: ${area_slug}/" "$task_file"
            fi
          else
            # Add area field after type or status field
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "/^status:/a\\
area: ${area_slug}
" "$task_file"
            else
              sed -i "/^status:/a\\area: ${area_slug}" "$task_file"
            fi
          fi
          
          gtd_action_success "moved" "task" "to area '$area_name'"
        fi
      else
        echo -n "Area name: "
        read area_input
        if [[ -n "$area_input" ]]; then
          area_slug=$(echo "$area_input" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          # Update the task's area field
          if grep -q "^area:" "$task_file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "s/^area:.*/area: ${area_slug}/" "$task_file"
            else
              sed -i "s/^area:.*/area: ${area_slug}/" "$task_file"
            fi
          else
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "/^status:/a\\
area: ${area_slug}
" "$task_file"
            else
              sed -i "/^status:/a\\area: ${area_slug}" "$task_file"
            fi
          fi
          
          gtd_action_success "moved" "task" "to area '$area_input'"
        fi
      fi
      echo ""
      gtd_quick_pause
      ;;
    8)
      echo ""
      echo "Adding a note to a task..."
      echo ""
      echo "Select a task to add a note to:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        gtd-task list
        echo ""
        echo "💡 Look at the task list above. Each task shows an 'ID:' line."
        echo "   Copy the task ID (e.g., 20240101120000-task) and paste it below."
        echo ""
        echo -n "Task ID to add note to (copy from the list above): "
        read task_id
        
        if [[ -z "$task_id" ]]; then
          echo "❌ No task ID provided"
          return 1
        fi
      fi
      
      # Check if task has existing notes
      # bash 3.2 compatible - get_task_notes uses global variables with prefix
      local notes_prefix="existing"
      if get_task_notes "$task_id" "$notes_prefix"; then
        # Access arrays using eval (bash 3.2 compatible)
        local note_count=$(eval "echo \${#${notes_prefix}_notes_files[@]}")
        if [[ $note_count -gt 0 ]]; then
          # Copy to local arrays for easier access
          local existing_note_files=()
          local existing_note_titles=()
          eval "existing_note_files=(\"\${${notes_prefix}_notes_files[@]}\")"
          eval "existing_note_titles=(\"\${${notes_prefix}_notes_titles[@]}\")"
          
          # Notes exist - show menu
          echo ""
          echo "This task already has ${#existing_note_files[@]} note(s)."
        echo ""
        echo "Existing notes:"
        local note_index=1
        for note_title in "${existing_note_titles[@]}"; do
          echo "  $note_index) $note_title"
          ((note_index++))
        done
        echo ""
        echo "What would you like to do?"
        echo ""
        echo "  1) View existing notes"
        echo "  2) Create new note"
        echo ""
        echo -n "Choose: "
        read note_choice
        
        case "$note_choice" in
          1)
            # View existing notes
            echo ""
            echo "Select a note to view:"
            echo ""
            note_index=1
            for note_title in "${existing_note_titles[@]}"; do
              echo "  $note_index) $note_title"
              ((note_index++))
            done
            echo ""
            echo -n "Note number to view: "
            read view_num
            
            if [[ "$view_num" =~ ^[0-9]+$ ]] && [[ $view_num -ge 1 && $view_num -le ${#existing_note_files[@]} ]]; then
              local note_file="${existing_note_files[$((view_num - 1))]}"
              
              if [[ -f "$note_file" ]]; then
                if command -v ${PAGER:-less} &>/dev/null; then
                  ${PAGER:-less} "$note_file"
                elif command -v cat &>/dev/null; then
                  cat "$note_file"
                fi
              fi
            else
              echo "Invalid selection"
            fi
            ;;
          2)
            # Create new note
            echo ""
            echo -n "Note title (or press Enter to be prompted): "
            read note_title
            
            if [[ -n "$note_title" ]]; then
              gtd-task add-note "$task_id" "$note_title"
            else
              gtd-task add-note "$task_id"
            fi
            ;;
            *)
              echo "Invalid choice"
              ;;
          esac
        fi
      else
        # No existing notes, just create new one
        echo ""
        echo -n "Note title (or press Enter to be prompted): "
        read note_title
        
        if [[ -n "$note_title" ]]; then
          gtd-task add-note "$task_id" "$note_title"
        else
          gtd-task add-note "$task_id"
        fi
      fi
      echo ""
      gtd_quick_pause
      ;;
    9)
      echo ""
      echo -e "${BOLD}💬 Restructure Task with Natural Language${NC}"
      echo ""
      echo "Select a task to restructure:"
      if declare -f select_from_tasks &>/dev/null; then
        task_id=$(select_from_tasks "task")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "No task selected"
          gtd_quick_pause
          return 0
        fi
      else
        # Fallback to old method
        local task_list_output=$(gtd-task list)
        echo "$task_list_output"
        echo ""
        echo -n "Task number or ID to restructure: "
        read task_input
        
        if [[ -z "$task_input" ]]; then
          gtd_feedback error "No task provided"
          gtd_quick_pause
          return 0
        fi
        
        task_id=$(get_task_id_by_number "$task_input" "$task_list_output")
        if [[ -z "$task_id" ]]; then
          gtd_feedback error "Task not found: $task_input"
          gtd_quick_pause
          return 0
        fi
      fi
      
      echo ""
      echo -e "${CYAN}Example commands:${NC}"
      echo "  • \"Make this more prominent\""
      echo "  • \"Archive but keep searchable\""
      echo "  • \"Focus on this week\""
      echo "  • \"I'm done with this\""
      echo ""
      
      echo ""
      echo -n "What would you like to do with this task? "
      read nl_command
      
      if [[ -z "$nl_command" ]]; then
        echo "❌ No command provided"
        gtd_quick_pause
        return 0
      fi
      
      echo ""
      if command -v gtd-restructure &>/dev/null; then
        gtd-restructure --task "$task_id" --command "$nl_command"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-restructure" ]]; then
        "$HOME/code/dotfiles/bin/gtd-restructure" --task "$task_id" --command "$nl_command"
      else
        echo "❌ gtd-restructure command not found"
      fi
      echo ""
      gtd_quick_pause
      ;;
    10)
      echo ""
      gtd_print_header "Organize Tasks - Clean Up Backlog" "🧹"
      echo "This will help you:"
      echo "  • Review tasks without projects"
      echo "  • Clean up completed tasks"
      echo "  • Bulk organize with AI suggestions"
      echo ""
      gtd_quick_pause
      
      # Find and launch task organizer
      local organizer_script=""
      if command -v gtd-task-organize &>/dev/null; then
        organizer_script="gtd-task-organize"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-task-organize" ]]; then
        organizer_script="$HOME/code/dotfiles/bin/gtd-task-organize"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-task-organize" ]]; then
        organizer_script="$HOME/code/personal/dotfiles/bin/gtd-task-organize"
      fi
      
      if [[ -n "$organizer_script" ]]; then
        # Launch the organizer
        if [[ -x "$organizer_script" ]] || command -v "$organizer_script" &>/dev/null; then
          "$organizer_script"
        else
          gtd_feedback error "Task organizer script found but is not executable: $organizer_script"
          gtd_quick_pause
        fi
      else
        gtd_feedback error "gtd-task-organize command not found"
        echo ""
        echo "Please ensure the script exists at:"
        echo "  $HOME/code/dotfiles/bin/gtd-task-organize"
        echo "  or"
        echo "  $HOME/code/personal/dotfiles/bin/gtd-task-organize"
        echo ""
        gtd_quick_pause
      fi
      ;;
    11)
      review_tasks_by_priority_project
      ;;
    12)
      echo ""
      echo -e "${BOLD}⭐ Favorite/Unfavorite Task${NC}"
      echo ""
      
      # Collect all tasks (standalone + project tasks)
      local all_task_files=()
      local all_task_names=()
      local all_task_ids=()
      
      # Get standalone tasks
      if [[ -d "${TASKS_PATH:-}" ]]; then
        while IFS= read -r task_file; do
          [[ ! -f "$task_file" ]] && continue
          local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
          local task_id=$(basename "$task_file" .md)
          local project=$(gtd_get_frontmatter_value "$task_file" "project" 2>/dev/null || echo "")
          
          # Build display name
          local display_name="$task_name"
          if [[ -n "$project" ]]; then
            display_name="$task_name (Project: $project)"
          fi
          
          all_task_files+=("$task_file")
          all_task_names+=("$display_name")
          all_task_ids+=("$task_id")
        done < <(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | sort)
      fi
      
      # Get project tasks
      if [[ -d "${PROJECTS_PATH:-}" ]]; then
        while IFS= read -r task_file; do
          [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
          local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
          local task_id=$(basename "$task_file" .md)
          local project_dir=$(dirname "$task_file")
          local project_slug=$(basename "$project_dir")
          local project_name="$project_slug"
          
          # Get project display name
          local project_readme="${project_dir}/README.md"
          if [[ -f "$project_readme" ]]; then
            project_name=$(gtd_get_frontmatter_value "$project_readme" "name" 2>/dev/null || echo "$project_slug")
            [[ -z "$project_name" ]] && project_name=$(gtd_get_frontmatter_value "$project_readme" "project" 2>/dev/null || echo "$project_slug")
          fi
          
          local display_name="$task_name (Project: $project_name)"
          
          all_task_files+=("$task_file")
          all_task_names+=("$display_name")
          all_task_ids+=("$task_id")
        done < <(find "${PROJECTS_PATH}" -name "*.md" -type f 2>/dev/null | sort)
      fi
      
      if [[ ${#all_task_files[@]} -eq 0 ]]; then
        gtd_feedback error "No tasks found"
        gtd_quick_pause
        return 0
      fi
      
      # Display tasks
      echo "Select a task to favorite/unfavorite:"
      echo ""
      for i in "${!all_task_names[@]}"; do
        local num=$((i + 1))
        echo "  ${num}) ${all_task_names[$i]}"
      done
      echo ""
      
      # Get user input with fuzzy search support
      local fuzzy_hint=""
      if [[ "${GTD_FUZZY_SEARCH:-false}" == "true" ]]; then
        fuzzy_hint=" (fuzzy search enabled)"
      fi
      echo -n "Task number or name${fuzzy_hint}: "
      read task_input
      
      if [[ -z "$task_input" ]]; then
        gtd_feedback error "No task selected"
        gtd_quick_pause
        return 0
      fi
      
      # Find selected task
      local task_file=""
      local task_name=""
      
      # Check if it's a number
      if [[ "$task_input" =~ ^[0-9]+$ ]]; then
        local selected_index=$((task_input - 1))
        if [[ $selected_index -ge 0 && $selected_index -lt ${#all_task_files[@]} ]]; then
          task_file="${all_task_files[$selected_index]}"
          task_name="${all_task_names[$selected_index]}"
        else
          gtd_feedback error "Invalid task number"
          gtd_quick_pause
          return 0
        fi
      else
        # Try fuzzy/partial matching
        local use_fuzzy="${GTD_FUZZY_SEARCH:-false}"
        local matches=()
        local match_indices=()
        
        if [[ "$use_fuzzy" == "true" ]]; then
          # Get the correct Python executable
          local python_cmd=""
          if declare -f gtd_get_mcp_python &>/dev/null; then
            python_cmd=$(gtd_get_mcp_python 2>/dev/null || echo "")
          fi
          if [[ -z "$python_cmd" ]]; then
            if [[ -f "/opt/homebrew/bin/python3" ]]; then
              python_cmd="/opt/homebrew/bin/python3"
            elif command -v python3 &>/dev/null; then
              python_cmd="python3"
            fi
          fi
          
          if [[ -n "$python_cmd" ]] && command -v "$python_cmd" &>/dev/null; then
            local python_script=$(cat <<'PYTHON_SCRIPT'
import sys
import difflib

user_input = sys.stdin.readline().strip()
task_names = []
task_ids = []
while True:
    name = sys.stdin.readline().strip()
    if not name:
        break
    task_id = sys.stdin.readline().strip()
    task_names.append(name)
    task_ids.append(task_id)

matches = []
match_indices = []
match_scores = []

for i, task_name in enumerate(task_names):
    task_id = task_ids[i]
    task_name_lower = task_name.lower()
    task_id_lower = task_id.lower()
    user_input_lower = user_input.lower()
    
    if user_input_lower in task_name_lower or user_input_lower in task_id_lower:
        matches.append(task_name)
        match_indices.append(i)
        match_scores.append(1.0)
    else:
        name_score = difflib.SequenceMatcher(None, user_input_lower, task_name_lower).ratio()
        id_score = difflib.SequenceMatcher(None, user_input_lower, task_id_lower).ratio()
        score = max(name_score, id_score)
        if score >= 0.2:
            matches.append(task_name)
            match_indices.append(i)
            match_scores.append(score)

if matches:
    sorted_data = sorted(zip(match_scores, matches, match_indices), reverse=True)
    match_scores, matches, match_indices = zip(*sorted_data)
    for score, name, idx in zip(match_scores, matches, match_indices):
        name_clean = name.replace('\n', ' ').replace('\r', ' ')
        print(f"{score}|{name_clean}|{idx}")
PYTHON_SCRIPT
)
            local fuzzy_output=$({
              printf "%s\n" "$task_input"
              for i in "${!all_task_names[@]}"; do
                printf "%s\n" "${all_task_names[$i]}"
                printf "%s\n" "${all_task_ids[$i]}"
              done
            } | "$python_cmd" -c "$python_script" 2>/dev/null)
            
            if [[ -n "$fuzzy_output" ]]; then
              while IFS='|' read -r score name idx; do
                [[ -z "$score" || -z "$name" || -z "$idx" ]] && continue
                if [[ "$idx" =~ ^[0-9]+$ ]]; then
                  matches+=("$name")
                  match_indices+=($idx)
                fi
              done <<< "$fuzzy_output"
            fi
          fi
        fi
        
        # Fallback to partial matching
        if [[ ${#matches[@]} -eq 0 ]]; then
          for i in "${!all_task_names[@]}"; do
            local display_name="${all_task_names[$i]}"
            local task_id="${all_task_ids[$i]}"
            local display_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
            local task_id_lower=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
            local input_lower=$(echo "$task_input" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$display_lower" == *"$input_lower"* ]] || [[ "$task_id_lower" == *"$input_lower"* ]]; then
              matches+=("$display_name")
              match_indices+=($i)
            fi
          done
        fi
        
        # Handle matches
        local match_count=${#matches[@]}
        if [[ $match_count -eq 0 ]]; then
          gtd_feedback error "No tasks found matching '$task_input'"
          gtd_quick_pause
          return 0
        elif [[ $match_count -eq 1 ]]; then
          local selected_index="${match_indices[0]}"
          task_file="${all_task_files[$selected_index]}"
          task_name="${all_task_names[$selected_index]}"
        else
          # Multiple matches - show them
          echo ""
          echo "Multiple matches found:"
          echo ""
          for i in "${!matches[@]}"; do
            local num=$((i + 1))
            echo "  ${num}) ${matches[$i]}"
          done
          echo ""
          echo -n "Select task (number): "
          read task_num
          
          if [[ "$task_num" =~ ^[0-9]+$ ]] && [[ "$task_num" -ge 1 ]] && [[ "$task_num" -le $match_count ]]; then
            local selected_match_index=$((task_num - 1))
            local selected_index="${match_indices[$selected_match_index]}"
            task_file="${all_task_files[$selected_index]}"
            task_name="${all_task_names[$selected_index]}"
          else
            gtd_feedback error "Invalid selection"
            gtd_quick_pause
            return 0
          fi
        fi
      fi
      
      if [[ -f "$task_file" ]]; then
        # Check current favorite status
        local current_favorite=$(gtd_get_frontmatter_value "$task_file" "favorite" 2>/dev/null || echo "")
        # Extract just the task name (without project info) for display
        local task_name_display=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
        
        if [[ "$current_favorite" == "true" ]]; then
          # Unfavorite
          if grep -q "^favorite:" "$task_file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "s/^favorite:.*/favorite: false/" "$task_file"
            else
              sed -i "s/^favorite:.*/favorite: false/" "$task_file"
            fi
            echo ""
            echo -e "${GREEN}✓${NC} Task '$task_name_display' unfavorited"
            echo "   You won't receive reminders about this task anymore."
          fi
        else
          # Favorite
          if grep -q "^favorite:" "$task_file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "s/^favorite:.*/favorite: true/" "$task_file"
            else
              sed -i "s/^favorite:.*/favorite: true/" "$task_file"
            fi
          else
            # Add favorite field to frontmatter
            if [[ "$OSTYPE" == "darwin"* ]]; then
              sed -i '' "/^status:/a\\
favorite: true
" "$task_file"
            else
              sed -i "/^status:/a\\favorite: true" "$task_file"
            fi
          fi
          echo ""
          echo -e "${GREEN}✓${NC} Task '$task_name_display' favorited"
          echo "   You'll see quick access to this task in the main menu!"
        fi
        echo ""
        gtd_quick_pause
      else
        echo "❌ Task file not found"
        echo ""
        gtd_quick_pause
      fi
      ;;
    0|"")
      pop_menu
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      gtd_quick_pause
      ;;
  esac
  done
}

# Review tasks by priority and/or project
review_tasks_by_priority_project() {
  push_menu "Task Management"
  
  while true; do
    clear
    show_breadcrumb
    gtd_print_header "Review Tasks by Priority/Project" "📊"
    echo ""
    echo "How would you like to review your active tasks?"
    echo ""
    echo "  1) By task priority (urgent_important, not_urgent_important, etc.)"
    echo "  2) By project (grouped by project)"
    echo "  3) By project priority (if projects have priorities)"
    echo "  4) Combined view (priority + project)"
    echo "  5) Filter by specific priority"
    echo "  6) Filter by specific project"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Task Management"
    echo ""
    echo -n "Choose: "
    read review_choice
    
    case "$review_choice" in
      0)
        pop_menu
        return 0
        ;;
      1)
        review_tasks_by_task_priority
        ;;
      2)
        review_tasks_by_project
        ;;
      3)
        review_tasks_by_project_priority
        ;;
      4)
        review_tasks_combined_view
        ;;
      5)
        filter_tasks_by_priority
        ;;
      6)
        filter_tasks_by_project
        ;;
      *)
        gtd_feedback error "Invalid choice"
        gtd_quick_pause
        ;;
    esac
  done
}

# Review tasks grouped by task priority
review_tasks_by_task_priority() {
  clear
  gtd_print_header "Tasks by Priority" "📊"
  echo ""
  
  # Collect all active tasks
  local all_tasks=()
  
  # Get tasks from tasks directory
  if [[ -d "$TASKS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" ]] && continue
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        all_tasks+=("$task_file")
      fi
    done < <(find "$TASKS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  # Get tasks from project directories
  if [[ -d "$PROJECTS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        all_tasks+=("$task_file")
      fi
    done < <(find "$PROJECTS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  if [[ ${#all_tasks[@]} -eq 0 ]]; then
    echo "No active tasks found."
    echo ""
    gtd_enter_to_continue
    return 0
  fi
  
  # Group by priority
  local urgent_important=()
  local not_urgent_important=()
  local urgent_not_important=()
  local not_urgent_not_important=()
  local no_priority=()
  
  for task_file in "${all_tasks[@]}"; do
    local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
    local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
    local project=$(gtd_get_frontmatter_value "$task_file" "project")
    
    # Determine project name
    local project_display=""
    if [[ -n "$project" ]]; then
      local project_dir="${PROJECTS_PATH}/${project}"
      if [[ -d "$project_dir" ]] && [[ -f "${project_dir}/README.md" ]]; then
        project_display=$(gtd_get_frontmatter_value "${project_dir}/README.md" "name")
        [[ -z "$project_display" ]] && project_display="$project"
      else
        project_display="$project"
      fi
    fi
    
    case "$priority" in
      urgent_important)
        urgent_important+=("$task_file|$task_name|$project_display")
        ;;
      not_urgent_important)
        not_urgent_important+=("$task_file|$task_name|$project_display")
        ;;
      urgent_not_important)
        urgent_not_important+=("$task_file|$task_name|$project_display")
        ;;
      not_urgent_not_important)
        not_urgent_not_important+=("$task_file|$task_name|$project_display")
        ;;
      *)
        no_priority+=("$task_file|$task_name|$project_display")
        ;;
    esac
  done
  
  # Display grouped by priority
  local total=${#all_tasks[@]}
  echo "Total active tasks: $total"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if [[ ${#urgent_important[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}${RED}🔴 Urgent & Important (${#urgent_important[@]})${NC}"
    echo ""
    
    # Build display items for two-column layout
    local display_items=()
    for task_info in "${urgent_important[@]}"; do
      IFS='|' read -r task_file task_name project_display <<< "$task_info"
      local display_text="• $task_name"
      [[ -n "$project_display" ]] && display_text="$display_text ($project_display)"
      display_items+=("$display_text")
    done
    
    # Display in two columns
    gtd_print_two_columns "${display_items[@]}"
  fi
  
  if [[ ${#not_urgent_important[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}${YELLOW}🟡 Not Urgent & Important (${#not_urgent_important[@]})${NC}"
    echo ""
    
    # Build display items for two-column layout
    local display_items=()
    for task_info in "${not_urgent_important[@]}"; do
      IFS='|' read -r task_file task_name project_display <<< "$task_info"
      local display_text="• $task_name"
      [[ -n "$project_display" ]] && display_text="$display_text ($project_display)"
      display_items+=("$display_text")
    done
    
    # Display in two columns
    gtd_print_two_columns "${display_items[@]}"
  fi
  
  if [[ ${#urgent_not_important[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}🔵 Urgent & Not Important (${#urgent_not_important[@]})${NC}"
    echo ""
    
    # Build display items for two-column layout
    local display_items=()
    for task_info in "${urgent_not_important[@]}"; do
      IFS='|' read -r task_file task_name project_display <<< "$task_info"
      local display_text="• $task_name"
      [[ -n "$project_display" ]] && display_text="$display_text ($project_display)"
      display_items+=("$display_text")
    done
    
    # Display in two columns
    gtd_print_two_columns "${display_items[@]}"
  fi
  
  if [[ ${#not_urgent_not_important[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}${GRAY}⚪ Not Urgent & Not Important (${#not_urgent_not_important[@]})${NC}"
    echo ""
    
    # Build display items for two-column layout
    local display_items=()
    for task_info in "${not_urgent_not_important[@]}"; do
      IFS='|' read -r task_file task_name project_display <<< "$task_info"
      local display_text="• $task_name"
      [[ -n "$project_display" ]] && display_text="$display_text ($project_display)"
      display_items+=("$display_text")
    done
    
    # Display in two columns
    gtd_print_two_columns "${display_items[@]}"
  fi
  
  if [[ ${#no_priority[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}${GRAY}⚫ No Priority Set (${#no_priority[@]})${NC}"
    echo ""
    
    # Build display items for two-column layout
    local display_items=()
    for task_info in "${no_priority[@]}"; do
      IFS='|' read -r task_file task_name project_display <<< "$task_info"
      local display_text="• $task_name"
      [[ -n "$project_display" ]] && display_text="$display_text ($project_display)"
      display_items+=("$display_text")
    done
    
    # Display in two columns
    gtd_print_two_columns "${display_items[@]}"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Offer interactive task selection
  echo ""
  echo "What would you like to do?"
  echo "  1) Select a task to view/edit/complete"
  echo "  2) Just review (no action)"
  echo ""
  echo -n "Choose: "
  read action_choice
  
  case "$action_choice" in
    1)
      # Build task selection list with fuzzy search support
      local task_names=()
      local task_files_list=()
      local task_ids=()
      
      for task_file in "${all_tasks[@]}"; do
        local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
        local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
        local project=$(gtd_get_frontmatter_value "$task_file" "project")
        local project_display=""
        if [[ -n "$project" ]]; then
          local project_dir="${PROJECTS_PATH}/${project}"
          if [[ -d "$project_dir" ]] && [[ -f "${project_dir}/README.md" ]]; then
            project_display=$(gtd_get_frontmatter_value "${project_dir}/README.md" "name")
            [[ -z "$project_display" ]] && project_display="$project"
          else
            project_display="$project"
          fi
        fi
        
        local display_name="$task_name"
        [[ -n "$priority" ]] && display_name="$display_name [$priority]"
        [[ -n "$project_display" ]] && display_name="$display_name (Project: $project_display)"
        
        local task_id=$(basename "$task_file" .md)
        task_names+=("$display_name")
        task_files_list+=("$task_file")
        task_ids+=("$task_id")
      done
      
      # Display numbered list
      echo ""
      echo "Select a task:"
      for i in "${!task_names[@]}"; do
        local num=$((i + 1))
        echo "  ${num}) ${task_names[$i]}"
      done
      echo ""
      
      # Get user input with fuzzy search support
      local fuzzy_hint=""
      if [[ "${GTD_FUZZY_SEARCH:-false}" == "true" ]]; then
        fuzzy_hint=" (fuzzy search enabled)"
      fi
      echo -n "Task number or name${fuzzy_hint}: "
      read task_input
      
      if [[ -z "$task_input" ]]; then
        gtd_feedback error "No task selected"
        gtd_enter_to_continue
        return 0
      fi
      
      # Check if it's a number
      if [[ "$task_input" =~ ^[0-9]+$ ]]; then
        local selected_index=$((task_input - 1))
        if [[ $selected_index -ge 0 && $selected_index -lt ${#task_files_list[@]} ]]; then
          local selected_file="${task_files_list[$selected_index]}"
          interact_with_task "$selected_file"
        else
          gtd_feedback error "Invalid task number"
          gtd_enter_to_continue
        fi
      else
        # Try fuzzy/partial matching
        local use_fuzzy="${GTD_FUZZY_SEARCH:-false}"
        local matches=()
        local match_indices=()
        
        if [[ "$use_fuzzy" == "true" ]] && [[ ${#task_names[@]} -gt 0 ]]; then
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
          
          if [[ -z "$python_cmd" ]] || ! command -v "$python_cmd" &>/dev/null; then
            # Fallback to partial matching if Python not available
            for i in "${!task_names[@]}"; do
              local display_name="${task_names[$i]}"
              local task_id="${task_ids[$i]}"
              local display_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
              local task_id_lower=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
              local input_lower=$(echo "$task_input" | tr '[:upper:]' '[:lower:]')
              
              if [[ "$display_lower" == *"$input_lower"* ]] || [[ "$task_id_lower" == *"$input_lower"* ]]; then
                matches+=("$display_name")
                match_indices+=($i)
              fi
            done
          else
            # Use Python difflib for fuzzy matching
            local fuzzy_output=""
            # Create a temporary Python script to avoid heredoc stdin conflicts
            local python_script=$(cat <<'PYTHON_SCRIPT'
import sys
import difflib

user_input = sys.stdin.readline().strip()
task_names = []
task_ids = []
while True:
    name = sys.stdin.readline().strip()
    if not name:
        break
    task_id = sys.stdin.readline().strip()
    task_names.append(name)
    task_ids.append(task_id)

matches = []
match_indices = []
match_scores = []

for i, task_name in enumerate(task_names):
    task_id = task_ids[i]
    task_name_lower = task_name.lower()
    task_id_lower = task_id.lower()
    user_input_lower = user_input.lower()
    
    # First check for substring match (case-insensitive) - this is a perfect match
    if user_input_lower in task_name_lower or user_input_lower in task_id_lower:
        # Substring match gets highest score
        matches.append(task_name)
        match_indices.append(i)
        match_scores.append(1.0)
    else:
        # Use fuzzy matching for partial/typo matches
        name_score = difflib.SequenceMatcher(None, user_input_lower, task_name_lower).ratio()
        id_score = difflib.SequenceMatcher(None, user_input_lower, task_id_lower).ratio()
        score = max(name_score, id_score)
        # Lower threshold to 0.2 to catch more matches
        if score >= 0.2:
            matches.append(task_name)
            match_indices.append(i)
            match_scores.append(score)

if matches:
    sorted_data = sorted(zip(match_scores, matches, match_indices), reverse=True)
    match_scores, matches, match_indices = zip(*sorted_data)
    for score, name, idx in zip(match_scores, matches, match_indices):
        # Ensure we output valid data (no newlines in name that would break parsing)
        name_clean = name.replace('\n', ' ').replace('\r', ' ')
        print(f"{score}|{name_clean}|{idx}")
PYTHON_SCRIPT
)
          fuzzy_output=$({
            printf "%s\n" "$task_input"
            for i in "${!task_names[@]}"; do
              printf "%s\n" "${task_names[$i]}"
              printf "%s\n" "${task_ids[$i]}"
            done
          } | "$python_cmd" -c "$python_script")
          
          # Parse fuzzy results
          if [[ -n "$fuzzy_output" ]]; then
            while IFS='|' read -r score name idx; do
              # Skip empty lines
              [[ -z "$score" || -z "$name" || -z "$idx" ]] && continue
              # Validate that idx is a number
              if [[ "$idx" =~ ^[0-9]+$ ]]; then
                matches+=("$name")
                match_indices+=($idx)
              fi
            done <<< "$fuzzy_output"
          fi
          fi  # Close the if at line 1388 (python_cmd check)
        else
          # Fallback to partial matching if fuzzy search disabled or no tasks
          for i in "${!task_names[@]}"; do
            local display_name="${task_names[$i]}"
            local task_id="${task_ids[$i]}"
            local display_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
            local task_id_lower=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
            local input_lower=$(echo "$task_input" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$display_lower" == *"$input_lower"* ]] || [[ "$task_id_lower" == *"$input_lower"* ]]; then
              matches+=("$display_name")
              match_indices+=($i)
            fi
          done
        fi
        
        local match_count=${#matches[@]}
        if [[ $match_count -eq 0 ]]; then
          gtd_feedback error "No tasks found matching '$task_input'"
          gtd_enter_to_continue
        elif [[ $match_count -eq 1 ]]; then
          # Single match - use it
          local selected_index="${match_indices[0]}"
          local selected_file="${task_files_list[$selected_index]}"
          interact_with_task "$selected_file"
        else
          # Multiple matches - show them
          echo ""
          echo "Multiple matches found:"
          echo ""
          for i in "${!matches[@]}"; do
            local num=$((i + 1))
            echo "  ${num}) ${matches[$i]}"
          done
          echo ""
          echo -n "Select task (number): "
          read task_num
          
          if [[ "$task_num" =~ ^[0-9]+$ ]] && [[ "$task_num" -ge 1 ]] && [[ "$task_num" -le $match_count ]]; then
            local selected_match_index=$((task_num - 1))
            local selected_index="${match_indices[$selected_match_index]}"
            local selected_file="${task_files_list[$selected_index]}"
            interact_with_task "$selected_file"
          else
            gtd_feedback error "Invalid selection"
            gtd_enter_to_continue
          fi
        fi
      fi
      ;;
    2)
      gtd_enter_to_continue
      ;;
    *)
      gtd_enter_to_continue
      ;;
  esac
}

# Review tasks grouped by project
review_tasks_by_project() {
  clear
  gtd_print_header "Tasks by Project" "📊"
  echo ""
  
  # Collect all active tasks with their projects (bash 3.2 compatible - use array with delimiter)
  local all_task_data=()
  
  # Get tasks from tasks directory
  if [[ -d "$TASKS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" ]] && continue
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        local project=$(gtd_get_frontmatter_value "$task_file" "project")
        local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
        local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
        
        if [[ -z "$project" ]]; then
          project="_no_project"
        fi
        
        all_task_data+=("${project}|||${task_file}|||${task_name}|||${priority}")
      fi
    done < <(find "$TASKS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  # Get tasks from project directories
  if [[ -d "$PROJECTS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        local project_dir=$(dirname "$task_file")
        local project=$(basename "$project_dir")
        local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
        local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
        
        all_task_data+=("${project}|||${task_file}|||${task_name}|||${priority}")
      fi
    done < <(find "$PROJECTS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  if [[ ${#all_task_data[@]} -eq 0 ]]; then
    echo "No active tasks found."
    echo ""
    gtd_enter_to_continue
    return 0
  fi
  
  # Get unique projects
  local unique_projects=()
  for task_data in "${all_task_data[@]}"; do
    local project="${task_data%%|||*}"
    local found=0
    for existing_project in "${unique_projects[@]}"; do
      if [[ "$existing_project" == "$project" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      unique_projects+=("$project")
    fi
  done
  
  # Sort projects
  local sorted_projects=($(printf '%s\n' "${unique_projects[@]}" | sort))
  
  echo "Total active tasks: ${#all_task_data[@]}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  for project in "${sorted_projects[@]}"; do
    local project_display="$project"
    if [[ "$project" != "_no_project" ]]; then
      local project_dir="${PROJECTS_PATH}/${project}"
      if [[ -d "$project_dir" ]] && [[ -f "${project_dir}/README.md" ]]; then
        project_display=$(gtd_get_frontmatter_value "${project_dir}/README.md" "name")
        [[ -z "$project_display" ]] && project_display="$project"
      fi
    else
      project_display="(No Project)"
    fi
    
    # Count tasks for this project
    local count=0
    local project_tasks=()
    for task_data in "${all_task_data[@]}"; do
      local task_project="${task_data%%|||*}"
      if [[ "$task_project" == "$project" ]]; then
        ((count++))
        project_tasks+=("$task_data")
      fi
    done
    
    echo ""
    echo -e "${BOLD}📁 $project_display (${count} task(s))${NC}"
    echo ""
    
    # Display tasks in this project
    for task_data in "${project_tasks[@]}"; do
      local rest="${task_data#*|||}"
      local task_file="${rest%%|||*}"
      rest="${rest#*|||}"
      local task_name="${rest%%|||*}"
      local priority="${rest#*|||}"
      
      echo "  • $task_name"
      [[ -n "$priority" ]] && echo "    Priority: $priority"
    done
  done
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Offer interactive task selection
  echo ""
  echo "What would you like to do?"
  echo "  1) Select a task to view/edit/complete"
  echo "  2) Just review (no action)"
  echo ""
  echo -n "Choose: "
  read action_choice
  
  case "$action_choice" in
    1)
      # Build task selection list from all projects with fuzzy search support
      local task_names=()
      local task_files_list=()
      local task_ids=()
      
      for project in "${sorted_projects[@]}"; do
        for task_data in "${all_task_data[@]}"; do
          local task_project="${task_data%%|||*}"
          if [[ "$task_project" == "$project" ]]; then
            local rest="${task_data#*|||}"
            local task_file="${rest%%|||*}"
            rest="${rest#*|||}"
            local task_name="${rest%%|||*}"
            local priority="${rest#*|||}"
            
            local project_display="$project"
            if [[ "$project" != "_no_project" ]]; then
              local project_dir="${PROJECTS_PATH}/${project}"
              if [[ -d "$project_dir" ]] && [[ -f "${project_dir}/README.md" ]]; then
                project_display=$(gtd_get_frontmatter_value "${project_dir}/README.md" "name")
                [[ -z "$project_display" ]] && project_display="$project"
              fi
            else
              project_display="(No Project)"
            fi
            
            local display_name="$task_name"
            [[ -n "$priority" ]] && display_name="$display_name [$priority]"
            display_name="$display_name (Project: $project_display)"
            
            local task_id=$(basename "$task_file" .md)
            task_names+=("$display_name")
            task_files_list+=("$task_file")
            task_ids+=("$task_id")
          fi
        done
      done
      
      # Display numbered list
      echo ""
      echo "Select a task:"
      for i in "${!task_names[@]}"; do
        local num=$((i + 1))
        echo "  ${num}) ${task_names[$i]}"
      done
      echo ""
      
      # Get user input with fuzzy search support
      local fuzzy_hint=""
      if [[ "${GTD_FUZZY_SEARCH:-false}" == "true" ]]; then
        fuzzy_hint=" (fuzzy search enabled)"
      fi
      echo -n "Task number or name${fuzzy_hint}: "
      read task_input
      
      if [[ -z "$task_input" ]]; then
        gtd_feedback error "No task selected"
        gtd_enter_to_continue
        return 0
      fi
      
      # Check if it's a number
      if [[ "$task_input" =~ ^[0-9]+$ ]]; then
        local selected_index=$((task_input - 1))
        if [[ $selected_index -ge 0 && $selected_index -lt ${#task_files_list[@]} ]]; then
          local selected_file="${task_files_list[$selected_index]}"
          interact_with_task "$selected_file"
        else
          gtd_feedback error "Invalid task number"
          gtd_enter_to_continue
        fi
      else
        # Try fuzzy/partial matching
        local use_fuzzy="${GTD_FUZZY_SEARCH:-false}"
        local matches=()
        local match_indices=()
        
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
            local fuzzy_output=""
            # Create a temporary Python script to avoid heredoc stdin conflicts
            local python_script=$(cat <<'PYTHON_SCRIPT'
import sys
import difflib

user_input = sys.stdin.readline().strip()
task_names = []
task_ids = []
while True:
    name = sys.stdin.readline().strip()
    if not name:
        break
    task_id = sys.stdin.readline().strip()
    task_names.append(name)
    task_ids.append(task_id)

matches = []
match_indices = []
match_scores = []

for i, task_name in enumerate(task_names):
    task_id = task_ids[i]
    task_name_lower = task_name.lower()
    task_id_lower = task_id.lower()
    user_input_lower = user_input.lower()
    
    # First check for substring match (case-insensitive) - this is a perfect match
    if user_input_lower in task_name_lower or user_input_lower in task_id_lower:
        # Substring match gets highest score
        matches.append(task_name)
        match_indices.append(i)
        match_scores.append(1.0)
    else:
        # Use fuzzy matching for partial/typo matches
        name_score = difflib.SequenceMatcher(None, user_input_lower, task_name_lower).ratio()
        id_score = difflib.SequenceMatcher(None, user_input_lower, task_id_lower).ratio()
        score = max(name_score, id_score)
        # Lower threshold to 0.2 to catch more matches
        if score >= 0.2:
            matches.append(task_name)
            match_indices.append(i)
            match_scores.append(score)

if matches:
    sorted_data = sorted(zip(match_scores, matches, match_indices), reverse=True)
    match_scores, matches, match_indices = zip(*sorted_data)
    for score, name, idx in zip(match_scores, matches, match_indices):
        # Ensure we output valid data (no newlines in name that would break parsing)
        name_clean = name.replace('\n', ' ').replace('\r', ' ')
        print(f"{score}|{name_clean}|{idx}")
PYTHON_SCRIPT
)
            fuzzy_output=$({
              printf "%s\n" "$task_input"
              for i in "${!task_names[@]}"; do
                printf "%s\n" "${task_names[$i]}"
                printf "%s\n" "${task_ids[$i]}"
              done
            } | "$python_cmd" -c "$python_script")
          
          if [[ -n "$fuzzy_output" ]]; then
            while IFS='|' read -r score name idx; do
              if [[ -n "$score" && -n "$name" && -n "$idx" ]]; then
                matches+=("$name")
                match_indices+=($idx)
              fi
            done <<< "$fuzzy_output"
          fi
          else
            # Fallback to partial matching if Python not available
            for i in "${!task_names[@]}"; do
            local display_name="${task_names[$i]}"
            local task_id="${task_ids[$i]}"
            local display_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
            local task_id_lower=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
            local input_lower=$(echo "$task_input" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$display_lower" == *"$input_lower"* ]] || [[ "$task_id_lower" == *"$input_lower"* ]]; then
              matches+=("$display_name")
              match_indices+=($i)
            fi
          done
          fi  # Close the if at line 1758 (python_cmd check)
        else
          # Fallback to partial matching if fuzzy search disabled
          for i in "${!task_names[@]}"; do
            local display_name="${task_names[$i]}"
            local task_id="${task_ids[$i]}"
            local display_lower=$(echo "$display_name" | tr '[:upper:]' '[:lower:]')
            local task_id_lower=$(echo "$task_id" | tr '[:upper:]' '[:lower:]')
            local input_lower=$(echo "$task_input" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$display_lower" == *"$input_lower"* ]] || [[ "$task_id_lower" == *"$input_lower"* ]]; then
              matches+=("$display_name")
              match_indices+=($i)
            fi
          done
        fi  # Close the if at line 1743 (use_fuzzy check)
        
        local match_count=${#matches[@]}
        if [[ $match_count -eq 0 ]]; then
          gtd_feedback error "No tasks found matching '$task_input'"
          gtd_enter_to_continue
        elif [[ $match_count -eq 1 ]]; then
          local selected_index="${match_indices[0]}"
          local selected_file="${task_files_list[$selected_index]}"
          interact_with_task "$selected_file"
        else
          echo ""
          echo "Multiple matches found:"
          echo ""
          for i in "${!matches[@]}"; do
            local num=$((i + 1))
            echo "  ${num}) ${matches[$i]}"
          done
          echo ""
          echo -n "Select task (number): "
          read task_num
          
          if [[ "$task_num" =~ ^[0-9]+$ ]] && [[ "$task_num" -ge 1 ]] && [[ "$task_num" -le $match_count ]]; then
            local selected_match_index=$((task_num - 1))
            local selected_index="${match_indices[$selected_match_index]}"
            local selected_file="${task_files_list[$selected_index]}"
            interact_with_task "$selected_file"
          else
            gtd_feedback error "Invalid selection"
            gtd_enter_to_continue
          fi
        fi
      fi  # Close the else at line 1737 (not a number)
      ;;
    2)
      gtd_enter_to_continue
      ;;
    *)
      gtd_enter_to_continue
      ;;
  esac
}

# Review tasks by project priority (if projects have priorities)
review_tasks_by_project_priority() {
  clear
  gtd_print_header "Tasks by Project Priority" "📊"
  echo ""
  
  # This would require projects to have priority fields
  # For now, show a message and fall back to project grouping
  echo "Note: Project priorities are not yet implemented."
  echo "Showing tasks grouped by project instead..."
  echo ""
  gtd_enter_to_continue
  review_tasks_by_project
}

# Combined view: priority within projects
review_tasks_combined_view() {
  clear
  gtd_print_header "Tasks: Priority within Projects" "📊"
  echo ""
  
  # Collect all tasks (bash 3.2 compatible)
  local all_task_data=()
  
  # Collect tasks from tasks directory
  if [[ -d "$TASKS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" ]] && continue
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        local project=$(gtd_get_frontmatter_value "$task_file" "project")
        local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
        local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
        
        if [[ -z "$project" ]]; then
          project="_no_project"
        fi
        
        all_task_data+=("${project}|||${task_file}|||${task_name}|||${priority}")
      fi
    done < <(find "$TASKS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  if [[ -d "$PROJECTS_PATH" ]]; then
    while IFS= read -r task_file; do
      [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
      local status=$(gtd_get_frontmatter_value "$task_file" "status")
      if [[ "$status" == "active" ]]; then
        local project_dir=$(dirname "$task_file")
        local project=$(basename "$project_dir")
        local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
        local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
        
        all_task_data+=("${project}|||${task_file}|||${task_name}|||${priority}")
      fi
    done < <(find "$PROJECTS_PATH" -name "*.md" -type f 2>/dev/null)
  fi
  
  if [[ ${#all_task_data[@]} -eq 0 ]]; then
    echo "No active tasks found."
    echo ""
    gtd_enter_to_continue
    return 0
  fi
  
  # Get unique projects
  local unique_projects=()
  for task_data in "${all_task_data[@]}"; do
    local project="${task_data%%|||*}"
    local found=0
    for existing_project in "${unique_projects[@]}"; do
      if [[ "$existing_project" == "$project" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      unique_projects+=("$project")
    fi
  done
  
  local sorted_projects=($(printf '%s\n' "${unique_projects[@]}" | sort))
  
  echo "Total active tasks: ${#all_task_data[@]}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  for project in "${sorted_projects[@]}"; do
    local project_display="$project"
    if [[ "$project" != "_no_project" ]]; then
      local project_dir="${PROJECTS_PATH}/${project}"
      if [[ -d "$project_dir" ]] && [[ -f "${project_dir}/README.md" ]]; then
        project_display=$(gtd_get_frontmatter_value "${project_dir}/README.md" "name")
        [[ -z "$project_display" ]] && project_display="$project"
      fi
    else
      project_display="(No Project)"
    fi
    
    # Group tasks by priority within this project
    local urgent_important=()
    local not_urgent_important=()
    local urgent_not_important=()
    local not_urgent_not_important=()
    local no_priority=()
    
    for task_data in "${all_task_data[@]}"; do
      local task_project="${task_data%%|||*}"
      if [[ "$task_project" == "$project" ]]; then
        local rest="${task_data#*|||}"
        rest="${rest#*|||}"
        local task_name="${rest%%|||*}"
        local priority="${rest#*|||}"
        
        case "$priority" in
          urgent_important)
            urgent_important+=("$task_name")
            ;;
          not_urgent_important)
            not_urgent_important+=("$task_name")
            ;;
          urgent_not_important)
            urgent_not_important+=("$task_name")
            ;;
          not_urgent_not_important)
            not_urgent_not_important+=("$task_name")
            ;;
          *)
            no_priority+=("$task_name")
            ;;
        esac
      fi
    done
    
    local count=$((${#urgent_important[@]} + ${#not_urgent_important[@]} + ${#urgent_not_important[@]} + ${#not_urgent_not_important[@]} + ${#no_priority[@]}))
    
    echo ""
    echo -e "${BOLD}📁 $project_display (${count} task(s))${NC}"
    
    if [[ ${#urgent_important[@]} -gt 0 ]]; then
      echo ""
      echo -e "  ${RED}🔴 Urgent & Important:${NC}"
      for task_name in "${urgent_important[@]}"; do
        echo "    • $task_name"
      done
    fi
    
    if [[ ${#not_urgent_important[@]} -gt 0 ]]; then
      echo ""
      echo -e "  ${YELLOW}🟡 Not Urgent & Important:${NC}"
      for task_name in "${not_urgent_important[@]}"; do
        echo "    • $task_name"
      done
    fi
    
    if [[ ${#urgent_not_important[@]} -gt 0 ]]; then
      echo ""
      echo -e "  ${CYAN}🔵 Urgent & Not Important:${NC}"
      for task_name in "${urgent_not_important[@]}"; do
        echo "    • $task_name"
      done
    fi
    
    if [[ ${#not_urgent_not_important[@]} -gt 0 ]]; then
      echo ""
      echo -e "  ${GRAY}⚪ Not Urgent & Not Important:${NC}"
      for task_name in "${not_urgent_not_important[@]}"; do
        echo "    • $task_name"
      done
    fi
    
    if [[ ${#no_priority[@]} -gt 0 ]]; then
      echo ""
      echo -e "  ${GRAY}⚫ No Priority:${NC}"
      for task_name in "${no_priority[@]}"; do
        echo "    • $task_name"
      done
    fi
  done
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Offer interactive task selection
  echo ""
  echo "What would you like to do?"
  echo "  1) Select a task to view/edit/complete"
  echo "  2) Just review (no action)"
  echo ""
  echo -n "Choose: "
  read action_choice
  
  case "$action_choice" in
    1)
      # Build task selection list from all projects
      local task_list=()
      local task_files_list=()
      local count=1
      
      for project in "${sorted_projects[@]}"; do
        for task_data in "${all_task_data[@]}"; do
          local task_project="${task_data%%|||*}"
          if [[ "$task_project" == "$project" ]]; then
            local rest="${task_data#*|||}"
            local task_file="${rest%%|||*}"
            rest="${rest#*|||}"
            local task_name="${rest%%|||*}"
            local priority="${rest#*|||}"
            
            local project_display="$project"
            if [[ "$project" != "_no_project" ]]; then
              local project_dir="${PROJECTS_PATH}/${project}"
              if [[ -d "$project_dir" ]] && [[ -f "${project_dir}/README.md" ]]; then
                project_display=$(gtd_get_frontmatter_value "${project_dir}/README.md" "name")
                [[ -z "$project_display" ]] && project_display="$project"
              fi
            else
              project_display="(No Project)"
            fi
            
            local display_name="$task_name"
            [[ -n "$priority" ]] && display_name="$display_name [$priority]"
            display_name="$display_name (Project: $project_display)"
            
            task_list+=("$count|$display_name")
            task_files_list+=("$task_file")
            ((count++))
          fi
        done
      done
      
      echo ""
      echo "Select a task:"
      for task_item in "${task_list[@]}"; do
        IFS='|' read -r num name <<< "$task_item"
        echo "  $num) $name"
      done
      echo ""
      echo -n "Task number: "
      read task_num
      
      if [[ "$task_num" =~ ^[0-9]+$ ]] && [[ "$task_num" -ge 1 ]] && [[ "$task_num" -le ${#task_files_list[@]} ]]; then
        local selected_file="${task_files_list[$((task_num - 1))]}"
        interact_with_task "$selected_file"
      else
        gtd_feedback error "Invalid task number"
        gtd_enter_to_continue
      fi
      ;;
    2)
      gtd_enter_to_continue
      ;;
    *)
      gtd_enter_to_continue
      ;;
  esac
}

# Filter tasks by specific priority
filter_tasks_by_priority() {
  clear
  gtd_print_header "Filter Tasks by Priority" "📊"
  echo ""
  echo "Select priority level:"
  echo ""
  echo "  1) Urgent & Important"
  echo "  2) Not Urgent & Important"
  echo "  3) Urgent & Not Important"
  echo "  4) Not Urgent & Not Important"
  echo ""
  echo -n "Choose: "
  read priority_choice
  
  local priority_filter=""
  case "$priority_choice" in
    1) priority_filter="urgent_important" ;;
    2) priority_filter="not_urgent_important" ;;
    3) priority_filter="urgent_not_important" ;;
    4) priority_filter="not_urgent_not_important" ;;
    *)
      gtd_feedback error "Invalid choice"
      gtd_enter_to_continue
      return 0
      ;;
  esac
  
  echo ""
  gtd-task list --priority="$priority_filter" --status=active
  echo ""
  gtd_enter_to_continue
}

# Filter tasks by specific project
filter_tasks_by_project() {
  clear
  gtd_print_header "Filter Tasks by Project" "📊"
  echo ""
  
  if [[ ! -d "$PROJECTS_PATH" ]] || [[ -z "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    echo "No projects found."
    echo ""
    gtd_enter_to_continue
    return 0
  fi
  
  echo "Select project:"
  echo ""
  local selected_project=$(select_from_list "project" "$PROJECTS_PATH" "project")
  
  if [[ -z "$selected_project" ]]; then
    gtd_feedback error "No project selected"
    gtd_enter_to_continue
    return 0
  fi
  
  local project_slug=$(echo "$selected_project" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  
  echo ""
  gtd-task list --project="$project_slug" --status=active
  echo ""
  gtd_enter_to_continue
}

# Interactive task actions (view, edit, update, complete)
interact_with_task() {
  local task_file="$1"
  
  if [[ ! -f "$task_file" ]]; then
    gtd_feedback error "Task file not found"
    gtd_enter_to_continue
    return 1
  fi
  
  local task_id=$(basename "$task_file" .md)
  local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || echo "$task_id")
  
  while true; do
    clear
    gtd_print_header "Task: $task_name" "✅"
    echo ""
    
    # Show task details
    gtd-task view "$task_id" 2>/dev/null || {
      echo "Task ID: $task_id"
      echo "File: $task_file"
      echo ""
      echo "Content:"
      head -30 "$task_file" 2>/dev/null | tail -20
    }
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "What would you like to do with this task?"
    echo ""
    echo "  1) View full task details"
    echo "  2) Update task (edit description, priority, context, etc.)"
    echo "  3) Complete task"
    echo "  4) Add note to task"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to review"
    echo ""
    echo -n "Choose: "
    read task_action
    
    case "$task_action" in
      0)
        return 0
        ;;
      1)
        clear
        gtd_print_header "Task Details: $task_name" "✅"
        echo ""
        gtd-task view "$task_id"
        echo ""
        gtd_enter_to_continue
        ;;
      2)
        clear
        gtd_print_header "Update Task: $task_name" "✏️"
        echo ""
        echo "Current task details shown above."
        echo ""
        echo "You can update:"
        echo "  • Task description"
        echo "  • Priority"
        echo "  • Context"
        echo "  • Energy level"
        echo "  • Project assignment"
        echo ""
        echo -n "Press Enter to open task editor, or 'q' to cancel: "
        read edit_choice
        if [[ "$edit_choice" != "q" && "$edit_choice" != "Q" ]]; then
          if command -v gtd-task &>/dev/null; then
            gtd-task update "$task_id"
          else
            # Fallback: open in editor
            if [[ -n "$EDITOR" ]]; then
              $EDITOR "$task_file"
            else
              gtd_feedback error "No editor configured. Set EDITOR environment variable."
            fi
          fi
        fi
        ;;
      3)
        clear
        gtd_print_header "Complete Task: $task_name" "✅"
        echo ""
        echo -n "Are you sure you want to complete this task? (y/n): "
        read confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
          if command -v gtd-task &>/dev/null; then
            gtd-task complete "$task_id"
            echo ""
            gtd_action_success "completed" "task" "$task_name"
            gtd_enter_to_continue
            return 0
          else
            # Fallback: update status manually
            if grep -q "^status:" "$task_file" 2>/dev/null; then
              if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/^status:.*/status: completed/" "$task_file"
              else
                sed -i "s/^status:.*/status: completed/" "$task_file"
              fi
              echo ""
              gtd_action_success "completed" "task" "$task_name"
              gtd_enter_to_continue
              return 0
            fi
          fi
        fi
        ;;
      4)
        clear
        gtd_print_header "Add Note to Task: $task_name" "📝"
        echo ""
        if command -v gtd-task &>/dev/null; then
          echo -n "Note title (or press Enter to be prompted): "
          read note_title
          if [[ -n "$note_title" ]]; then
            gtd-task add-note "$task_id" "$note_title"
          else
            gtd-task add-note "$task_id"
          fi
        else
          echo "Note: gtd-task command not available. Please use the task wizard to add notes."
        fi
        echo ""
        gtd_enter_to_continue
        ;;
      *)
        gtd_feedback error "Invalid choice"
        gtd_enter_to_continue
        ;;
    esac
  done
}

area_wizard() {
  push_menu "Main Menu"
  
  while true; do
  clear
    show_breadcrumb
    gtd_print_header "Areas of Responsibility Wizard" "🎯"
    show_areas_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) Create a new area"
  echo "  2) Use starter areas wizard (recommended)"
  echo "  3) List areas"
  echo "  4) View an area"
  echo "  5) Update an area"
    echo "  6) Add note to area"
    echo "  7) Archive an area"
    echo "  8) Review all areas"
    echo "  9) 💬 Restructure with natural language"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read area_choice
  
  case "$area_choice" in
    1)
      echo ""
      echo -n "Area name: "
      read area_name
      
      if [[ -z "$area_name" ]]; then
        gtd_feedback error "No area name provided"
        return 1
      fi
      
      echo ""
      echo -n "Area description (optional): "
      read area_desc
      
      if [[ -n "$area_desc" ]]; then
        gtd-area create "$area_name" "$area_desc"
      else
        gtd-area create "$area_name"
      fi
      gtd_action_success "created" "area" "$area_name"
      ;;
    2)
      gtd-area-starter
      ;;
    3)
      echo ""
      gtd-area list
      ;;
    4)
      echo ""
      # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
        area_name=$(select_from_list "area" "$AREAS_PATH" "name")
        if [[ -n "$area_name" ]]; then
          gtd-area view "$area_name"
        fi
      else
        gtd_empty_state "areas" "Press 1 to create your first area"
      fi
      ;;
    5)
      echo ""
      # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
        area_name=$(select_from_list "area" "$AREAS_PATH" "name")
        if [[ -n "$area_name" ]]; then
          echo -n "New description: "
          read new_desc
          if [[ -n "$new_desc" ]]; then
            gtd-area update "$area_name" "$new_desc"
            gtd_action_success "updated" "area" "$area_name"
          fi
        fi
      else
        gtd_empty_state "areas" "Press 1 to create your first area"
      fi
      ;;
    6)
      echo ""
      # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
        area_name=$(select_from_list "area" "$AREAS_PATH" "name")
        if [[ -n "$area_name" ]]; then
          echo -n "Note title: "
          read note_title
          if [[ -n "$note_title" ]]; then
            gtd-area add-note "$area_name" "$note_title"
            gtd_action_success "added" "note" "'$note_title' to area"
          else
            gtd_feedback error "No note title provided"
          fi
        fi
      else
        gtd_empty_state "areas" "Press 1 to create your first area"
      fi
      ;;
    7)
      echo ""
      # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
        area_name=$(select_from_list "area" "$AREAS_PATH" "name")
        if [[ -n "$area_name" ]]; then
          gtd-area archive "$area_name"
        fi
      else
        echo "No areas found."
      fi
      ;;
    8)
      echo ""
      echo "Reviewing all areas..."
      gtd-area review-all
      ;;
    9)
      echo ""
      echo -e "${BOLD}💬 Restructure Area with Natural Language${NC}"
      echo ""
      # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
        echo "Available areas:"
        area_name=$(select_from_list "area" "$AREAS_PATH" "name")
        if [[ -n "$area_name" ]]; then
          area_slug=$(echo "$area_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo ""
          echo -e "${CYAN}Example commands:${NC}"
          echo "  • \"Make this more prominent\""
          echo "  • \"Archive but keep searchable\""
          echo "  • \"Focus on this week\""
          echo ""
          echo -n "What would you like to do with this area? "
          read nl_command
          
          if [[ -z "$nl_command" ]]; then
            echo "❌ No command provided"
    gtd_quick_pause
            return 0
          fi
          
          echo ""
          if command -v gtd-restructure &>/dev/null; then
            gtd-restructure --area "$area_slug" --command "$nl_command"
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-restructure" ]]; then
            "$HOME/code/dotfiles/bin/gtd-restructure" --area "$area_slug" --command "$nl_command"
          else
            echo "❌ gtd-restructure command not found"
          fi
        fi
      else
        echo "No areas found."
      fi
      echo ""
      gtd_quick_pause
      ;;
    0|"")
      pop_menu
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  if [[ "$area_choice" != "0" ]] && [[ -n "$area_choice" ]]; then
  echo ""
    gtd_quick_pause
  fi
  done
}

project_wizard() {
  push_menu "Main Menu"
  
  # Paths are already set by init_gtd_paths in gtd-common.sh (DRY - reuse existing helper)
  GOALS_DIR="${GOALS_DIR:-${GTD_BASE_DIR}/goals}"
  
  while true; do
  clear
    show_breadcrumb
    gtd_print_header "Project Management Wizard" "📁"
    show_projects_guide
  echo "What would you like to do?"
  echo ""
    echo "  1) Create a new project"
    echo "  2) List projects"
    echo "  3) View a project"
    echo "  4) Add task to project"
    echo "  5) Add note to project"
    echo "  6) Update project status"
    echo "  7) Move project to area"
    echo "  8) Archive a project"
    echo ""
    echo -e "${BOLD}Enhanced Features:${NC}"
    echo "  9) 📊 Project Health Dashboard"
    echo "  10) 🔍 Detect Stalled Projects"
    echo "  11) 🎯 Link Project to Goal"
    echo "  12) 🌳 Show Goal → Project → Task Hierarchy"
    echo "  13) 💬 Restructure with natural language"
    echo "  14) 🤖 AI Planning Assistant"
    echo "  15) ⭐ Favorite/Unfavorite Project"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read project_choice
  
  case "$project_choice" in
    1)
      echo ""
      echo -n "Project name: "
      read project_name
      
      if [[ -z "$project_name" ]]; then
        gtd_feedback error "No project name provided"
        return 1
      fi
      
      echo ""
      echo -n "Repository URL (GitHub/GitLab, or press Enter to skip): "
      read repo_url
      
      local project_created=false
      if [[ -n "$repo_url" ]]; then
        if gtd-project create "$project_name" --repository="$repo_url"; then
          project_created=true
        fi
      else
        if gtd-project create "$project_name"; then
          project_created=true
        fi
      fi
      
      # Show success confirmation
      if [[ "$project_created" == "true" ]]; then
        gtd_action_success "created" "project" "$project_name"
      fi
      
      # Vectorize the project if created successfully
      if [[ "$project_created" == "true" ]]; then
        # Get project content (read from README if available)
        local project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
        local project_dir="${PROJECTS_PATH}/${project_slug}"
        local project_readme="${project_dir}/README.md"
        local project_content=""
        
        if [[ -f "$project_readme" ]]; then
          project_content=$(cat "$project_readme" | head -100)  # First 100 lines
        else
          project_content="$project_name"
        fi
        
        # Vectorize in background (don't block user)
        if command -v gtd-vectorize-content &>/dev/null; then
          gtd-vectorize-content "project" "$project_slug" "$project_content" &
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-vectorize-content" ]]; then
          "$HOME/code/dotfiles/bin/gtd-vectorize-content" "project" "$project_slug" "$project_content" &
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-vectorize-content" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-vectorize-content" "project" "$project_slug" "$project_content" &
        fi
      fi
      ;;
    2)
      echo ""
      gtd-project list
      ;;
    3)
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          # select_from_list already returns the exact directory name, use it directly
          # Don't modify it - it's already the correct directory name
          project_slug="$project_name"
          project_dir="${PROJECTS_PATH}/${project_slug}"
          project_readme="${project_dir}/README.md"
          
          # Check if README exists before trying to view
          if [[ -f "$project_readme" ]]; then
            # View the project (gtd-project view requires README)
            gtd-project view "$project_slug" 2>/dev/null || true
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "What would you like to do?"
            echo ""
            gtd_format_list_item "1" "Review and complete tasks"
            gtd_format_list_item "2" "Edit project file contents"
            gtd_format_list_item "3" "Rename project"
            echo ""
            echo -e "${YELLOW}0)${NC} Back to project menu"
            echo ""
            echo -n "Choose: "
            read edit_choice
            
            case "$edit_choice" in
              1)
                # Review and complete tasks in this project
                review_project_tasks "$project_slug" "$project_name"
                ;;
              2)
                # Edit project file contents
                if [[ ! -f "$project_readme" ]]; then
                  echo "❌ Project README not found: $project_readme"
                  echo ""
    gtd_quick_pause
                else
                # Check if editor is available
                local editor="${EDITOR:-vim}"
                if ! command -v "$editor" &>/dev/null && [[ "$editor" == "vim" ]]; then
                  if ! command -v vim &>/dev/null; then
                    echo "❌ vim not found. Please install vim or set EDITOR environment variable."
                    echo ""
    gtd_quick_pause
                  else
                    editor="vim"
                  fi
                fi
                
                if command -v "$editor" &>/dev/null; then
                  echo ""
                  echo -e "${CYAN}Opening ${BOLD}${project_readme}${NC}${CYAN} in ${editor}...${NC}"
                  echo -e "${YELLOW}Tip:${NC} When done editing, save with ${BOLD}:wq${NC} or exit without saving with ${BOLD}:q!${NC}"
                  echo ""
    gtd_quick_pause
                  
                  # Edit file
                  if "$editor" "$project_readme"; then
                    echo ""
                    echo -e "${GREEN}✅ Project file updated!${NC}"
                  else
                    echo ""
                    echo -e "${YELLOW}⚠️  File editing cancelled or failed${NC}"
                  fi
                else
                  echo "❌ Editor not found: $editor"
                  echo ""
    gtd_quick_pause
                fi
              fi
                ;;
              3)
                # Rename project
                if [[ ! -d "$project_dir" ]]; then
                  echo "❌ Project directory not found: $project_dir"
                  echo ""
    gtd_quick_pause
                else
                  echo ""
                  echo "Current project name: $project_name"
                echo ""
                echo -n "New project name: "
                read new_project_name
                
                if [[ -z "$new_project_name" ]]; then
                  echo "❌ No new name provided. Cancelling rename."
                  echo ""
    gtd_quick_pause
                else
                  # Convert new name to slug format
                  new_project_slug=$(echo "$new_project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
                  new_project_dir="${PROJECTS_PATH}/${new_project_slug}"
                  
                  # Check if new name already exists
                  if [[ -d "$new_project_dir" ]]; then
                    echo "❌ Project with name '$new_project_name' already exists!"
                    echo ""
    gtd_quick_pause
                  else
                    # Rename the directory
                    if mv "$project_dir" "$new_project_dir" 2>/dev/null; then
                      # Update project reference in README if it exists
                      if [[ -f "${new_project_dir}/README.md" ]]; then
                        # Update frontmatter project field
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                          sed -i '' "s/^project:.*$/project: ${new_project_slug}/" "${new_project_dir}/README.md" 2>/dev/null
                        else
                          sed -i "s/^project:.*$/project: ${new_project_slug}/" "${new_project_dir}/README.md" 2>/dev/null
                        fi
                      fi
                      
                      # Update project references in task files
                      for task_file in "${new_project_dir}"/*.md; do
                        [[ ! -f "$task_file" || "$task_file" == "${new_project_dir}/README.md" ]] && continue
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                          sed -i '' "s/^project:.*$/project: ${new_project_slug}/" "$task_file" 2>/dev/null
                        else
                          sed -i "s/^project:.*$/project: ${new_project_slug}/" "$task_file" 2>/dev/null
                        fi
                      done
                      
                      echo ""
                      echo -e "${GREEN}✅ Project renamed from '$project_name' to '$new_project_name'${NC}"
                    else
                      echo ""
                      echo "❌ Failed to rename project directory"
                    fi
                    echo ""
    gtd_quick_pause
                  fi
                fi
              fi
              ;;
            0|"")
              # Back to menu - do nothing
              ;;
            *)
              echo "Invalid choice"
              ;;
          esac
          else
            # No README - offer to create one
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📁 Project: $project_slug"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "This project doesn't have a README.md file yet."
            echo ""
            read -p "Would you like to create one? (Y/n): " create_readme
            if [[ -z "$create_readme" || "$create_readme" =~ ^[Yy]$ ]]; then
              if command -v gtd-project &>/dev/null; then
                # Use the exact project_slug (directory name) returned from select_from_list
                # Don't convert it again - it's already the correct directory name
                gtd-project init-readme "$project_slug"
                echo ""
    gtd_quick_pause
              else
                echo "❌ gtd-project command not found"
                echo ""
    gtd_quick_pause
              fi
            else
              echo ""
    gtd_quick_pause
            fi
          fi
        fi
      else
        echo "No projects found."
      fi
      ;;
    4)
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          # Convert to slug format
          project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo ""
          echo "How would you like to add a task?"
          echo ""
          echo "  1) Select from existing tasks"
          echo "  2) Create new task"
          echo ""
          echo -n "Choose: "
          read task_choice
          
          case "$task_choice" in
            1)
              # Select from existing tasks
              if [[ -d "$TASKS_PATH" ]] && [[ -n "$(find "$TASKS_PATH" -type f -name "*.md" 2>/dev/null)" ]]; then
                echo ""
                echo "Select a task to attach to this project:"
                task_id=$(select_from_tasks "task")
                if [[ -n "$task_id" ]]; then
                  gtd-task move "$task_id" "$project_slug"
          gtd_action_success "moved" "task" "to project"
                fi
              else
                gtd_empty_state "standalone tasks" "Would you like to create a new task instead?"
                read -p "(y/N): " create_new
                if [[ "$create_new" =~ ^[Yy]$ ]]; then
                  echo -n "Task description: "
                  read task_desc
                  if [[ -n "$task_desc" ]]; then
                    gtd-project add-task "$project_slug" "$task_desc"
                    gtd_action_success "added" "task" "'$task_desc' to project"
                  fi
                fi
              fi
              ;;
            2)
              # Create new task
              echo -n "Task description: "
              read task_desc
              if [[ -n "$task_desc" ]]; then
                gtd-project add-task "$project_slug" "$task_desc"
                gtd_action_success "added" "task" "'$task_desc' to project"
              fi
              ;;
            *)
              echo "Invalid choice"
              ;;
          esac
        fi
      else
        echo "No projects found."
      fi
      ;;
    5)
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          # Convert to slug format
          project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo ""
          echo -n "Note title (or press Enter to be prompted): "
          read note_title
          
          if [[ -n "$note_title" ]]; then
            gtd-project add-note "$project_slug" "$note_title"
          else
            gtd-project add-note "$project_slug"
          fi
        fi
      else
        echo "No projects found."
      fi
      ;;
    6)
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          echo -n "New status: "
          read new_status
          if [[ -n "$new_status" ]]; then
            # Convert to slug format
            project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            gtd-project status "$project_slug" "$new_status"
          fi
        fi
      else
        echo "No projects found."
      fi
      ;;
    7)
      echo ""
      echo "Moving a project to an area..."
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        echo "Select project to move:"
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          # Convert to slug format
          project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo ""
          # Use standardized helper function (DRY - reuse existing helper)
      if directory_has_files "$AREAS_PATH"; then
            echo "Select area to assign project to:"
            area_name=$(select_from_list "area" "$AREAS_PATH" "name")
            if [[ -n "$area_name" ]]; then
              # Convert to slug format
              area_slug=$(echo "$area_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
              gtd-area add-project "$area_slug" "$project_slug"
            fi
          else
            echo -n "Area name (or press Enter to skip): "
            read area_input
            if [[ -n "$area_input" ]]; then
              area_slug=$(echo "$area_input" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
              gtd-area add-project "$area_slug" "$project_slug"
            fi
          fi
        fi
      else
        echo "No projects found."
      fi
      ;;
    8)
      echo ""
      # Check for projects using the same method as gtd-project list
      local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
      local has_projects=false
      for project_dir in "${projects[@]}"; do
        local readme="${project_dir}/README.md"
        if [[ -f "$readme" ]]; then
          has_projects=true
          break
        fi
      done
      
      if [[ "$has_projects" == "true" ]]; then
        # select_from_list now returns the directory name for projects (not display name)
        project_slug=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_slug" ]]; then
          # Verify the project exists before archiving
          if [[ -d "${PROJECTS_PATH}/${project_slug}" && -f "${PROJECTS_PATH}/${project_slug}/README.md" ]]; then
            gtd-project archive "$project_slug"
          else
            echo "❌ Project directory not found: $project_slug"
            echo "   Searched in: ${PROJECTS_PATH}/${project_slug}"
    gtd_quick_pause
          fi
        fi
      else
        echo "No projects found."
      fi
      ;;
    9)
      echo ""
      ENHANCED_SCRIPT="$HOME/code/dotfiles/bin/gtd-project-enhanced.sh"
      if [[ ! -f "$ENHANCED_SCRIPT" ]]; then
        ENHANCED_SCRIPT="$HOME/code/personal/dotfiles/bin/gtd-project-enhanced.sh"
      fi
      if [[ -f "$ENHANCED_SCRIPT" ]]; then
        source "$ENHANCED_SCRIPT"
        project_health_dashboard
        echo ""
        gtd_enter_to_continue
      else
        echo "Enhanced project features not available"
        echo ""
        gtd_quick_pause
      fi
      ;;
    10)
      echo ""
      ENHANCED_SCRIPT="$HOME/code/dotfiles/bin/gtd-project-enhanced.sh"
      if [[ ! -f "$ENHANCED_SCRIPT" ]]; then
        ENHANCED_SCRIPT="$HOME/code/personal/dotfiles/bin/gtd-project-enhanced.sh"
      fi
      if [[ -f "$ENHANCED_SCRIPT" ]]; then
        source "$ENHANCED_SCRIPT"
        detect_stalled_projects
      else
        echo "Enhanced project features not available"
      fi
      ;;
    11)
      echo ""
      # Check for projects using the same method as gtd-project list
      local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
      local has_projects=false
      for project_dir in "${projects[@]}"; do
        local readme="${project_dir}/README.md"
        if [[ -f "$readme" ]]; then
          has_projects=true
          break
        fi
      done
      
      if [[ "$has_projects" == "true" ]]; then
        # Use select_from_list to get display name, then find the matching directory
        project_display_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_display_name" ]]; then
          # Find the actual project directory by matching the display name
          # Since select_from_list uses get_display_name which can return the directory name,
          # we need to match using the same logic
          project_slug=""
          
          # Normalize the selected display name for comparison
          local selected_normalized=$(echo "$project_display_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
          
          # Check if the display name IS the directory name (common case)
          if [[ -d "${PROJECTS_PATH}/${project_display_name}" ]]; then
            project_slug="$project_display_name"
          else
            # Try to find by matching display names from README files
            for project_dir in "${PROJECTS_PATH}"/*/; do
              [[ ! -d "$project_dir" ]] && continue
              local readme="${project_dir}README.md"
              if [[ -f "$readme" ]]; then
                # Use the same logic as get_display_name in select_from_list
                # Use standardized helper function (DRY - reuse existing helper)
                local display_name=$(get_project_name "$readme")
                if [[ -z "$display_name" ]]; then
                  display_name=$(basename "$project_dir")
                fi
                
                # Normalize for comparison
                local display_normalized=$(echo "$display_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
                
                if [[ "$display_normalized" == "$selected_normalized" ]]; then
                  project_slug=$(basename "$project_dir")
                  break
                fi
              fi
            done
          fi
          
          # Final fallback: try the display name as-is (in case it's already a slug)
          if [[ -z "$project_slug" ]]; then
            # Try various slug conversions
            local try_slug=$(echo "$project_display_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
            if [[ -d "${PROJECTS_PATH}/${try_slug}" ]]; then
              project_slug="$try_slug"
            fi
          fi
          
          # Verify the project directory exists
          if [[ -z "$project_slug" ]] || [[ ! -d "${PROJECTS_PATH}/${project_slug}" ]]; then
            echo "❌ Could not find project directory for: $project_display_name"
            echo "   Searched in: ${PROJECTS_PATH}"
            echo "   Tried slug: ${project_slug:-<empty>}"
            echo ""
    gtd_quick_pause
            return 1
          fi
          
          # List available goals
          echo ""
          echo "Available goals:"
          local goal_files=()
          local goal_names=()
          local goal_count=0
          if [[ -d "$GOALS_DIR" ]]; then
            for goal_file in "$GOALS_DIR"/*.md; do
              [[ ! -f "$goal_file" ]] && continue
              local goal_name=$(grep "^name:" "$goal_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//')
              local goal_status=$(grep "^status:" "$goal_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//')
              if [[ "$goal_status" == "active" ]]; then
                ((goal_count++))
                goal_files+=("$goal_file")
                goal_names+=("$goal_name")
                echo "  $goal_count) $goal_name"
              fi
            done
          fi
          
          echo ""
          echo -n "Goal number or name to link (or press Enter to skip): "
          read goal_input
          
          if [[ -n "$goal_input" ]]; then
            local goal_name=""
            # Check if input is a number
            if [[ "$goal_input" =~ ^[0-9]+$ ]] && [[ "$goal_input" -ge 1 ]] && [[ "$goal_input" -le ${#goal_names[@]} ]]; then
              # User entered a number, get the goal name
              goal_name="${goal_names[$((goal_input - 1))]}"
            else
              # User entered a name (or partial name), try to find it
              goal_name="$goal_input"
              # Try exact match first
              local found=false
              for i in "${!goal_names[@]}"; do
                if [[ "${goal_names[$i]}" == "$goal_input" ]]; then
                  goal_name="${goal_names[$i]}"
                  found=true
                  break
                fi
              done
              # If not found, try partial match
              if [[ "$found" != "true" ]]; then
                for i in "${!goal_names[@]}"; do
                  if [[ "${goal_names[$i]}" == *"$goal_input"* ]]; then
                    goal_name="${goal_names[$i]}"
                    found=true
                    break
                  fi
                done
              fi
            fi
            
            if [[ -n "$goal_name" ]]; then
              ENHANCED_SCRIPT="$HOME/code/dotfiles/bin/gtd-project-enhanced.sh"
              if [[ ! -f "$ENHANCED_SCRIPT" ]]; then
                ENHANCED_SCRIPT="$HOME/code/personal/dotfiles/bin/gtd-project-enhanced.sh"
              fi
              if [[ -f "$ENHANCED_SCRIPT" ]]; then
                source "$ENHANCED_SCRIPT"
                link_project_to_goal "$project_slug" "$goal_name"
              else
                echo "Enhanced project features not available"
              fi
            else
              echo "Goal not found: $goal_input"
              gtd_quick_pause
            fi
          fi
        fi
      else
        echo "No projects found."
      fi
      ;;
    12)
      echo ""
      ENHANCED_SCRIPT="$HOME/code/dotfiles/bin/gtd-project-enhanced.sh"
      if [[ ! -f "$ENHANCED_SCRIPT" ]]; then
        ENHANCED_SCRIPT="$HOME/code/personal/dotfiles/bin/gtd-project-enhanced.sh"
      fi
      if [[ -f "$ENHANCED_SCRIPT" ]]; then
        source "$ENHANCED_SCRIPT"
        show_goal_hierarchy
        echo ""
        gtd_enter_to_continue
      else
        echo "Enhanced project features not available"
        gtd_quick_pause
      fi
      ;;
    13)
      echo ""
      echo -e "${BOLD}💬 Restructure Project with Natural Language${NC}"
      echo ""
      # Check for projects using the same method as gtd-project list
      local projects=($(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null))
      local has_projects=false
      for project_dir in "${projects[@]}"; do
        local readme="${project_dir}/README.md"
        if [[ -f "$readme" ]]; then
          has_projects=true
          break
        fi
      done
      
      if [[ "$has_projects" == "true" ]]; then
        echo "Available projects:"
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo ""
          echo -e "${CYAN}Example commands:${NC}"
          echo "  • \"Make this more prominent\""
          echo "  • \"Archive but keep searchable\""
          echo "  • \"Focus on this week\""
          echo "  • \"I'm done with this\""
          echo ""
          echo -n "What would you like to do with this project? "
          read nl_command
          
          if [[ -z "$nl_command" ]]; then
            echo "❌ No command provided"
    gtd_quick_pause
            return 0
          fi
          
          echo ""
          # Use thinking timer for AI-powered restructuring (gtd-common.sh is already sourced by main wizard)
          if command -v gtd-restructure &>/dev/null; then
            run_with_thinking_timer "Restructuring project" gtd-restructure --project "$project_slug" --command "$nl_command"
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-restructure" ]]; then
            run_with_thinking_timer "Restructuring project" "$HOME/code/dotfiles/bin/gtd-restructure" --project "$project_slug" --command "$nl_command"
          else
            echo "❌ gtd-restructure command not found"
          fi
        fi
      else
        echo "No projects found."
      fi
      echo ""
      gtd_quick_pause
      ;;
    14)
      echo ""
      echo -e "${BOLD}🤖 AI Planning Assistant${NC}"
      echo ""
      if command -v gtd-plan &>/dev/null; then
        gtd-plan
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-plan" ]]; then
        "$HOME/code/dotfiles/bin/gtd-plan"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-plan" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-plan"
      else
        echo "❌ gtd-plan command not found"
      fi
      echo ""
      gtd_quick_pause
      ;;
    15)
      echo ""
      echo -e "${BOLD}⭐ Favorite/Unfavorite Project${NC}"
      echo ""
      if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
        if [[ -n "$project_name" ]]; then
          # Convert to slug format
          project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          project_dir="${PROJECTS_PATH}/${project_slug}"
          project_readme="${project_dir}/README.md"
          
          if [[ -f "$project_readme" ]]; then
            # Check current favorite status
            local current_favorite=$(gtd_get_frontmatter_value "$project_readme" "favorite" 2>/dev/null || echo "")
            
            if [[ "$current_favorite" == "true" ]]; then
              # Unfavorite
              if grep -q "^favorite:" "$project_readme" 2>/dev/null; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                  sed -i '' "s/^favorite:.*/favorite: false/" "$project_readme"
                else
                  sed -i "s/^favorite:.*/favorite: false/" "$project_readme"
                fi
                echo ""
                echo -e "${GREEN}✓${NC} Project '$project_name' unfavorited"
                echo "   You won't receive reminders about this project anymore."
              fi
            else
              # Favorite
              if grep -q "^favorite:" "$project_readme" 2>/dev/null; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                  sed -i '' "s/^favorite:.*/favorite: true/" "$project_readme"
                else
                  sed -i "s/^favorite:.*/favorite: true/" "$project_readme"
                fi
              else
                # Add favorite field to frontmatter
                # Check if file has frontmatter (starts with ---)
                local has_frontmatter=false
                if head -1 "$project_readme" 2>/dev/null | grep -q "^---"; then
                  has_frontmatter=true
                fi
                
                if [[ "$has_frontmatter" == "true" ]]; then
                  # File has frontmatter - add favorite field
                  if grep -q "^status:" "$project_readme" 2>/dev/null; then
                    # Add after status field
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "/^status:/a\\
favorite: true
" "$project_readme"
                    else
                      sed -i "/^status:/a\\favorite: true" "$project_readme"
                    fi
                  elif grep -q "^goal:" "$project_readme" 2>/dev/null; then
                    # Add after goal field (common in projects)
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "/^goal:/a\\
favorite: true
" "$project_readme"
                    else
                      sed -i "/^goal:/a\\favorite: true" "$project_readme"
                    fi
                  else
                    # Add after first line of frontmatter (after ---)
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "1a\\
favorite: true
" "$project_readme"
                    else
                      sed -i "1a\\favorite: true" "$project_readme"
                    fi
                  fi
                else
                  # File doesn't have frontmatter - add it at the beginning
                  local temp_file=$(mktemp)
                  echo "---" > "$temp_file"
                  echo "favorite: true" >> "$temp_file"
                  echo "---" >> "$temp_file"
                  echo "" >> "$temp_file"
                  cat "$project_readme" >> "$temp_file"
                  mv "$temp_file" "$project_readme"
                fi
              fi
              echo ""
              echo -e "${GREEN}✓${NC} Project '$project_name' favorited"
              echo "   You'll receive reminders about this project in smart suggestions!"
            fi
            echo ""
            gtd_quick_pause
          else
            echo "❌ Project README not found: $project_readme"
            echo ""
            gtd_quick_pause
          fi
        fi
      else
        echo "No projects found."
        echo ""
        gtd_quick_pause
      fi
      ;;
    0|"")
      pop_menu
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  if [[ "$project_choice" != "0" ]] && [[ -n "$project_choice" ]]; then
  echo ""
    gtd_quick_pause
  fi
  done
}

moc_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}🗺️  Maps of Content (MOC) Wizard${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    show_moc_guide
    echo "What would you like to do?"
    echo ""
    echo "  1) Create a new MOC"
    echo "  2) List all MOCs"
    echo "  3) View a MOC"
    echo "  4) Add note to MOC"
    echo "  5) Add task to MOC"
    echo "  6) Add project to MOC"
    echo "  7) Add MOC to MOC (link related MOCs)"
    echo "  8) Auto-populate MOC from tags"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read moc_choice
    
    case "$moc_choice" in
      1)
        echo ""
        echo -n "MOC topic: "
        read topic
        if [[ -z "$topic" ]]; then
          echo "❌ Topic required"
          echo ""
    gtd_quick_pause
          continue
        fi
        echo -n "Description (optional): "
        read desc
        if command -v gtd-brain-moc &>/dev/null; then
          gtd-brain-moc create "$topic" "$desc"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-moc" create "$topic" "$desc"
        fi
        echo ""
        gtd_quick_pause
        ;;
      2)
        echo ""
        if command -v gtd-brain-moc &>/dev/null; then
          gtd-brain-moc list
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-moc" list
        fi
        echo ""
        gtd_quick_pause
        ;;
      3)
        echo ""
        # Get MOC names directly from file system (like areas/projects)
        local moc_names=()
        while IFS= read -r moc_name; do
          [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
        done < <(get_moc_names_array)
        
        if [[ ${#moc_names[@]} -eq 0 ]]; then
          echo "No MOCs found."
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Use numbered selection (automatically shows numbers)
        local topic=""
          local selected_moc=$(select_from_numbered_list "${moc_names[@]}")
          if [[ -n "$selected_moc" ]]; then
            topic="$selected_moc"
          else
            echo "❌ No MOC selected"
            echo ""
    gtd_quick_pause
            continue
        fi
        
        if [[ -n "$topic" ]]; then
          if command -v gtd-brain-moc &>/dev/null; then
            gtd-brain-moc view "$topic"
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-moc" view "$topic"
          fi
        fi
        echo ""
        gtd_quick_pause
        ;;
      4)
        echo ""
        # Get MOC names directly from file system
        local moc_names=()
        while IFS= read -r moc_name; do
          [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
        done < <(get_moc_names_array)
        
        if [[ ${#moc_names[@]} -eq 0 ]]; then
          echo "No MOCs found."
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Use numbered selection (automatically shows numbers)
        local topic=""
          local selected_moc=$(select_from_numbered_list "${moc_names[@]}")
          if [[ -n "$selected_moc" ]]; then
            topic="$selected_moc"
          else
            echo "❌ No MOC selected"
            echo ""
    gtd_quick_pause
            continue
          fi
        
        # Get all notes from Second Brain
        echo ""
        echo "📚 Loading notes from Second Brain..."
        local notes_data=()
        while IFS='|' read -r category note_path note_name; do
          notes_data+=("${category}|${note_path}|${note_name}")
        done < <(get_second_brain_notes)
        
        if [[ ${#notes_data[@]} -eq 0 ]]; then
          echo "❌ No notes found in Second Brain"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Group notes by category for display
        local selectable_notes=()  # Array of note paths
        local selectable_categories=()  # Array of categories
        local selectable_names=()  # Array of display names
        
        local current_category=""
        local note_counter=0
        
        # Build arrays of selectable notes
        for note_entry in "${notes_data[@]}"; do
          IFS='|' read -r category note_path note_name <<< "$note_entry"
          selectable_notes+=("$note_path")
          selectable_categories+=("$category")
          selectable_names+=("$note_name")
        done
        
        if [[ ${#selectable_notes[@]} -eq 0 ]]; then
          echo "❌ No notes found"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Display notes grouped by category with numbers
        echo ""
        echo "Select a note to add to MOC:"
        echo ""
        
        current_category=""
        note_counter=0
        for i in "${!selectable_notes[@]}"; do
          local category="${selectable_categories[$i]}"
          
          # Print category header if new category
          if [[ "$category" != "$current_category" ]]; then
            if [[ -n "$current_category" ]]; then
              echo ""  # Blank line between categories
            fi
            echo -e "${YELLOW}━━━ $category ━━━${NC}"
            current_category="$category"
          fi
          
          # Print numbered note
          note_counter=$((note_counter + 1))
          echo -e "  ${GREEN}${note_counter})${NC} ${selectable_names[$i]}"
        done
        echo ""
        
        # Get user selection
        echo -n "Select note (number): " >&2
        read note_choice
        
        if [[ -z "$note_choice" || ! "$note_choice" =~ ^[0-9]+$ ]]; then
          echo "❌ Invalid selection"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        local selected_idx=$((note_choice - 1))
        if [[ $selected_idx -ge 0 && $selected_idx -lt ${#selectable_notes[@]} ]]; then
          local selected_path="${selectable_notes[$selected_idx]}"
          local selected_category="${selectable_categories[$selected_idx]}"
          
          # Add note to MOC
        if command -v gtd-brain-moc &>/dev/null; then
            gtd-brain-moc add "$topic" "$selected_path" "$selected_category"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-moc" add "$topic" "$selected_path" "$selected_category"
          fi
        else
          echo "❌ Invalid number. Please select 1-${#selectable_notes[@]}"
          echo ""
    gtd_quick_pause
          continue
        fi
        echo ""
        gtd_quick_pause
        ;;
      5)
        echo ""
        echo "Adding a task to a MOC..."
        echo ""
        # Select MOC
        local moc_names=()
        while IFS= read -r moc_name; do
          [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
        done < <(get_moc_names_array)
        
        if [[ ${#moc_names[@]} -eq 0 ]]; then
          echo "No MOCs found."
          echo ""
    gtd_quick_pause
          continue
        fi
        
        local topic=""
        local selected_moc=$(select_from_numbered_list "${moc_names[@]}")
        if [[ -n "$selected_moc" ]]; then
          topic="$selected_moc"
        else
          echo "❌ No MOC selected"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Select task
        echo ""
        gtd-task list
        echo ""
        echo "💡 Look at the task list above. Each task shows an 'ID:' line."
        echo "   Copy the task ID (e.g., 20240101120000-task) and paste it below."
        echo ""
        echo -n "Task ID to add to MOC (copy from the list above): "
        read task_id
        
        if [[ -z "$task_id" ]]; then
          echo "❌ No task ID provided"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Find task file
        local task_file=""
        if [[ -d "$TASKS_PATH" ]]; then
          # Use standardized helper function (DRY - reuse existing helper)
          task_file=$(find_task_file "$task_id")
        fi
        
        if [[ -z "$task_file" || ! -f "$task_file" ]]; then
          echo "❌ Task not found: $task_id"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Add task to MOC in Projects section
        if command -v gtd-brain-moc &>/dev/null; then
          gtd-brain-moc add "$topic" "$task_file" "Projects"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-moc" add "$topic" "$task_file" "Projects"
        fi
        echo ""
        gtd_quick_pause
        ;;
      6)
        echo ""
        echo "Adding a project to a MOC..."
        echo ""
        # Select MOC
        local moc_names=()
        while IFS= read -r moc_name; do
          [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
        done < <(get_moc_names_array)
        
        if [[ ${#moc_names[@]} -eq 0 ]]; then
          echo "No MOCs found."
          echo ""
    gtd_quick_pause
          continue
        fi
        
        local topic=""
        local selected_moc=$(select_from_numbered_list "${moc_names[@]}")
        if [[ -n "$selected_moc" ]]; then
          topic="$selected_moc"
        else
          echo "❌ No MOC selected"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Select project
        echo ""
        if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
          project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
          if [[ -n "$project_name" ]]; then
            project_slug=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            local project_readme="${PROJECTS_PATH}/${project_slug}/README.md"
            
            if [[ -f "$project_readme" ]]; then
              # Add project to MOC in Projects section
              if command -v gtd-brain-moc &>/dev/null; then
                gtd-brain-moc add "$topic" "$project_readme" "Projects"
              elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
                "$HOME/code/dotfiles/bin/gtd-brain-moc" add "$topic" "$project_readme" "Projects"
              fi
            else
              echo "❌ Project README not found: $project_readme"
            fi
          fi
        else
          echo "No projects found."
        fi
        echo ""
        gtd_quick_pause
        ;;
      7)
        echo ""
        echo "Linking MOCs (adding to Related MOCs section)..."
        echo ""
        # Select target MOC (the one to add to)
        local moc_names=()
        while IFS= read -r moc_name; do
          [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
        done < <(get_moc_names_array)
        
        if [[ ${#moc_names[@]} -eq 0 ]]; then
          echo "No MOCs found."
          echo ""
    gtd_quick_pause
          continue
        fi
        
        echo "Select MOC to add related MOC to:"
        local target_topic=""
        local selected_moc=$(select_from_numbered_list "${moc_names[@]}")
        if [[ -n "$selected_moc" ]]; then
          target_topic="$selected_moc"
        else
          echo "❌ No MOC selected"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Select source MOC (the one to link)
        echo ""
        echo "Select MOC to link (add to Related MOCs):"
        local source_topic=""
        local selected_moc2=$(select_from_numbered_list "${moc_names[@]}")
        if [[ -n "$selected_moc2" ]]; then
          source_topic="$selected_moc2"
        else
          echo "❌ No MOC selected"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        if [[ "$target_topic" == "$source_topic" ]]; then
          echo "⚠️  Cannot link MOC to itself"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Get MOC file paths
        local MOC_DIR="${SECOND_BRAIN}/MOCs"
        local target_moc_file="${MOC_DIR}/MOC - ${target_topic}.md"
        local source_moc_file="${MOC_DIR}/MOC - ${source_topic}.md"
        
        if [[ ! -f "$target_moc_file" ]]; then
          echo "❌ Target MOC not found: $target_moc_file"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        if [[ ! -f "$source_moc_file" ]]; then
          echo "❌ Source MOC not found: $source_moc_file"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Check if link already exists
        local moc_link="[[MOC - ${source_topic}]]"
        if grep -q "$moc_link" "$target_moc_file" 2>/dev/null; then
          echo "⚠️  MOC already linked in Related MOCs section"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Add to Related MOCs section
        local temp_file=$(mktemp)
        local related_section_found=false
        local in_related_section=false
        local link_added=false
        local today=$(date +"%Y-%m-%d")
        
        while IFS= read -r line || [[ -n "$line" ]]; do
          # Check if we're entering the Related MOCs section
          if [[ "$line" == "## Related MOCs" ]]; then
            related_section_found=true
            in_related_section=true
            echo "$line" >> "$temp_file"
            continue
          fi
          
          # Check if we're leaving the Related MOCs section (hitting next header or Tags)
          if [[ "$in_related_section" == "true" ]] && [[ "$line" =~ ^## ]]; then
            # Add the link before leaving the section if not already added
            if [[ "$link_added" == "false" ]]; then
              # Remove placeholder "- " line if it exists
              if grep -q "^- $" "$temp_file" 2>/dev/null; then
                sed -i.bak '/^- $/d' "$temp_file" 2>/dev/null && rm -f "${temp_file}.bak" 2>/dev/null
              fi
              echo "- ${moc_link}" >> "$temp_file"
              link_added=true
            fi
            in_related_section=false
          fi
          
          # Skip placeholder "- " line in Related MOCs section
          if [[ "$in_related_section" == "true" ]] && [[ "$line" == "- " ]]; then
            continue
          fi
          
          # Skip comment lines in Related MOCs section (we'll add our own)
          if [[ "$in_related_section" == "true" ]] && [[ "$line" =~ ^'<!--' ]]; then
            continue
          fi
          
          echo "$line" >> "$temp_file"
        done < "$target_moc_file"
        
        # If Related MOCs section wasn't found, add it before Tags section
        if [[ "$related_section_found" == "false" ]]; then
          local temp_file2=$(mktemp)
          while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == "## Tags" ]]; then
              echo "## Related MOCs" >> "$temp_file2"
              echo "<!-- Link to related MOCs -->" >> "$temp_file2"
              echo "- ${moc_link}" >> "$temp_file2"
              echo "" >> "$temp_file2"
            fi
            echo "$line" >> "$temp_file2"
          done < "$temp_file"
          mv "$temp_file2" "$temp_file"
        elif [[ "$link_added" == "false" ]]; then
          # Section exists but link wasn't added (e.g., section was at end of file)
          echo "- ${moc_link}" >> "$temp_file"
        fi
        
        # Update last updated date
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "s/^## Last Updated.*/## Last Updated\n${today}/" "$temp_file"
        else
          sed -i "s/^## Last Updated.*/## Last Updated\n${today}/" "$temp_file"
        fi
        
        mv "$temp_file" "$target_moc_file"
        
        echo "✓ Linked MOC '${source_topic}' to '${target_topic}' in Related MOCs section"
        echo ""
        gtd_quick_pause
        ;;
      8)
        echo ""
        # Get MOC names directly from file system
        local moc_names=()
        while IFS= read -r moc_name; do
          [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
        done < <(get_moc_names_array)
        
        if [[ ${#moc_names[@]} -eq 0 ]]; then
          echo "No MOCs found."
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Use numbered selection (automatically shows numbers)
        local topic=""
          local selected_moc=$(select_from_numbered_list "${moc_names[@]}")
          if [[ -n "$selected_moc" ]]; then
            topic="$selected_moc"
          else
            echo "❌ No MOC selected"
            echo ""
    gtd_quick_pause
            continue
        fi
        
        echo -n "Tag to search for (optional, uses topic if empty): "
        read tag
        if command -v gtd-brain-moc &>/dev/null; then
          gtd-brain-moc auto "$topic" "$tag"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-moc" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-moc" auto "$topic" "$tag"
        fi
        echo ""
        gtd_quick_pause
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        gtd_quick_pause
        ;;
    esac
  done
}

quick_complete_habits() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}✅ Quick Complete Habits${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Load config to get HABITS_PATH
  GTD_CONFIG_FILE="$HOME/.gtd_config"
  if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
    GTD_CONFIG_FILE="$HOME/code/dotfiles/zsh/.gtd_config"
  elif [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
    GTD_CONFIG_FILE="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  if [[ -f "$GTD_CONFIG_FILE" ]]; then
    source "$GTD_CONFIG_FILE"
  fi
  
  # Paths are already set by init_gtd_paths in gtd-common.sh (DRY - reuse existing helper)
  HABITS_PATH="${HABITS_PATH:-${GTD_BASE_DIR}/habits}"
  
  # Get date command
  get_date_cmd() {
    if [[ -x "/usr/bin/date" ]]; then
      echo "/usr/bin/date"
    elif [[ -x "/bin/date" ]]; then
      echo "/bin/date"
    else
      echo "date"
    fi
  }
  
  DATE_CMD=$(get_date_cmd)
  TODAY=$($DATE_CMD +"%Y-%m-%d")
  
  if [[ ! -d "$HABITS_PATH" ]]; then
    echo "No habits directory found. Create habits first."
    echo ""
    return
  fi
  
  # Find all active habits
  local habits=()
  local habit_names=()
  local habit_index=1
  
  for habit_file in "$HABITS_PATH"/*.md; do
    [[ ! -f "$habit_file" ]] && continue
    
    local status=$(grep "^status:" "$habit_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo "active")
    if [[ "$status" != "active" ]]; then
      continue
    fi
    
    local habit_name=$(grep "^name:" "$habit_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//' || basename "$habit_file" .md)
    local frequency=$(grep "^frequency:" "$habit_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo "")
    local last_completed=$(grep "^last_completed:" "$habit_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo "")
    local streak=$(grep "^streak:" "$habit_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo "0")
    
    # Check if due
    local is_due=false
    if [[ "$frequency" == "daily" && "$last_completed" != "$TODAY" ]]; then
      is_due=true
    elif [[ "$frequency" == "weekly" ]]; then
      # Check if it's been a week
      if [[ -n "$last_completed" && "$last_completed" != "Never" ]]; then
        local days_since=$(( ($($DATE_CMD +%s) - $($DATE_CMD -j -f "%Y-%m-%d" "$last_completed" +%s 2>/dev/null || echo 0)) / 86400 ))
        if [[ $days_since -ge 7 ]]; then
          is_due=true
        fi
      else
        is_due=true
      fi
    elif [[ "$frequency" == "monthly" ]]; then
      # Check if it's been a month
      if [[ -n "$last_completed" && "$last_completed" != "Never" ]]; then
        local days_since=$(( ($($DATE_CMD +%s) - $($DATE_CMD -j -f "%Y-%m-%d" "$last_completed" +%s 2>/dev/null || echo 0)) / 86400 ))
        if [[ $days_since -ge 30 ]]; then
          is_due=true
        fi
      else
        is_due=true
      fi
    elif [[ -z "$last_completed" || "$last_completed" == "Never" ]]; then
      is_due=true
    fi
    
    if [[ "$is_due" == "true" ]]; then
      habits+=("$habit_file")
      habit_names+=("$habit_name")
      
      # Show habit with status
      local status_icon="⭕"
      if [[ "$last_completed" == "$TODAY" ]]; then
        status_icon="✅"
      fi
      
      echo -e "  ${GREEN}${habit_index})${NC} ${status_icon} ${BOLD}${habit_name}${NC}"
      echo "     Frequency: ${frequency} | Streak: ${streak} days"
      if [[ "$last_completed" != "$TODAY" && -n "$last_completed" && "$last_completed" != "Never" ]]; then
        echo "     Last completed: ${last_completed}"
      fi
      echo ""
      
      ((habit_index++))
    fi
  done
  
  if [[ ${#habits[@]} -eq 0 ]]; then
    echo "🎉 No habits due today! All caught up."
    echo ""
    return
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Which habits did you complete? (Enter numbers separated by spaces, or 'all' for all, or 'none' to skip)"
  echo ""
  read -p "Your choice: " selected
  
  if [[ "$selected" == "all" || "$selected" == "ALL" ]]; then
    echo ""
    echo "Completing all habits..."
    for habit_name in "${habit_names[@]}"; do
      echo -n "  Completing '${habit_name}'... "
      gtd-habit log "$habit_name" >/dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${RED}✗${NC}"
      fi
    done
    echo ""
    echo -e "${GREEN}✓ All habits completed!${NC}"
  elif [[ "$selected" == "none" || "$selected" == "NONE" || -z "$selected" ]]; then
    echo ""
    echo "Skipping habit completion."
  else
    echo ""
    echo "Completing selected habits..."
    for num in $selected; do
      if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#habits[@]} ]]; then
        local idx=$((num - 1))
        local habit_name="${habit_names[$idx]}"
        echo -n "  Completing '${habit_name}'... "
        gtd-habit log "$habit_name" >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
          echo -e "${GREEN}✓${NC}"
        else
          echo -e "${RED}✗${NC}"
        fi
      fi
    done
    echo ""
    echo -e "${GREEN}✓ Selected habits completed!${NC}"
  fi
  
  echo ""
}

habit_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔁 Habits & Recurring Tasks${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) ✅ Quick Complete (check off due habits)"
  echo "  2) Create a new habit"
  echo "  3) Log habit completion (by name)"
  echo "  4) View habit dashboard"
  echo "  5) List all habits"
  echo "  6) View habit details"
  echo "  7) Archive a habit"
  echo ""
  echo -n "Choose: "
  read habit_choice
  
  case "$habit_choice" in
    1)
      quick_complete_habits
      ;;
    2)
      echo ""
      echo -n "Habit name: "
      read habit_name
      if [[ -n "$habit_name" ]]; then
        gtd-habit create "$habit_name"
      fi
      ;;
    3)
      echo ""
      gtd-habit list
      echo ""
      echo -n "Habit name to log: "
      read habit_name
      if [[ -n "$habit_name" ]]; then
        gtd-habit log "$habit_name"
      fi
      ;;
    4)
      gtd-habit dashboard
      ;;
    5)
      gtd-habit list
      ;;
    6)
      echo ""
      gtd-habit list
      echo ""
      echo -n "Habit name to view: "
      read habit_name
      if [[ -n "$habit_name" ]]; then
        gtd-habit view "$habit_name"
      fi
      ;;
    7)
      echo ""
      gtd-habit list
      echo ""
      echo -n "Habit name to archive: "
      read habit_name
      if [[ -n "$habit_name" ]]; then
        gtd-habit archive "$habit_name"
      fi
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  echo ""
    gtd_quick_pause
}

zettelkasten_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔗 Zettelkasten (Atomic Notes) Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_zettelkasten_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) Create atomic note (inbox)"
  echo "  2) Create atomic note (Zettelkasten directory)"
  echo "  3) Create atomic note (Resources - PARA)"
  echo "  4) Create atomic note (Projects - PARA)"
  echo "  5) Create atomic note (Areas - PARA)"
  echo "  6) Link note to Second Brain/PARA"
  echo "  7) Link note to GTD item"
  echo "  8) Move note to PARA category"
  echo "  9) List notes in inbox"
  echo "  10) List notes in Zettelkasten directory"
  echo "  11) Process inbox (move to organized location)"
  echo "  12) 🔗 AI: Suggest connections for a note"
  echo "  13) 🔍 AI: Find orphaned notes (no connections)"
  echo "  14) 📝 AI: Suggest log entries → permanent notes"
  echo ""
  echo -n "Choose: "
  read zet_choice
  
  case "$zet_choice" in
    1)
      echo ""
      echo -n "Note title: "
      read note_title
      if [[ -n "$note_title" ]]; then
        zet "$note_title"
      else
        echo "❌ No title provided"
      fi
      ;;
    2)
      echo ""
      echo -n "Note title: "
      read note_title
      if [[ -n "$note_title" ]]; then
        zet -z "$note_title"
      else
        echo "❌ No title provided"
      fi
      ;;
    3)
      echo ""
      echo -n "Note title: "
      read note_title
      if [[ -n "$note_title" ]]; then
        zet -r "$note_title"
      else
        echo "❌ No title provided"
      fi
      ;;
    4)
      echo ""
      echo -n "Note title: "
      read note_title
      if [[ -n "$note_title" ]]; then
        zet -p "$note_title"
      else
        echo "❌ No title provided"
      fi
      ;;
    5)
      echo ""
      echo -n "Note title: "
      read note_title
      if [[ -n "$note_title" ]]; then
        zet -a "$note_title"
      else
        echo "❌ No title provided"
      fi
      ;;
    6)
      echo ""
      echo "Link Zettelkasten note to Second Brain"
      echo ""
      # Find notes in common locations
      local zet_inbox="${SECOND_BRAIN}/0-inbox"
      local zet_dir="${SECOND_BRAIN}/Zettelkasten"
      local zet_note_path=""
      
      # Try to find notes
      if [[ -d "$zet_inbox" ]] && [[ -n "$(find "$zet_inbox" -maxdepth 1 -name "*.md" -type f 2>/dev/null)" ]]; then
        echo "Available notes (inbox):"
        zet_note_path=$(select_from_list "note" "$zet_inbox" "name")
      elif [[ -d "$zet_dir" ]] && [[ -n "$(find "$zet_dir" -name "*.md" -type f 2>/dev/null | head -20)" ]]; then
        echo "Available notes (zettelkasten):"
        zet_note_path=$(select_from_list "note" "$zet_dir" "name")
      fi
      
      if [[ -z "$zet_note_path" ]]; then
        echo -n "Zettelkasten note path: "
        read zet_note
      else
        # Find the full path to the selected note
        zet_note=$(find "$zet_inbox" "$zet_dir" -name "${zet_note_path}.md" -o -name "*${zet_note_path}*.md" 2>/dev/null | head -1)
        if [[ -z "$zet_note" ]]; then
          zet_note="$zet_note_path"
        fi
      fi
      
      echo ""
      echo "Link to:"
      echo "  1) Projects (PARA)"
      echo "  2) Areas (PARA)"
      echo "  3) Resources (PARA)"
      echo "  4) Specific Second Brain note"
      echo ""
      echo -n "Choose: "
      read link_choice
      
      case "$link_choice" in
        1)
          zet-link link "$zet_note" Projects
          ;;
        2)
          zet-link link "$zet_note" Areas
          ;;
        3)
          zet-link link "$zet_note" Resources
          ;;
        4)
          echo -n "Second Brain note path: "
          read brain_note
          zet-link link "$zet_note" "$brain_note"
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      ;;
    7)
      echo ""
      echo -e "${BOLD}Link Zettelkasten Note to GTD Item${NC}"
      echo ""
      
      # Set SECOND_BRAIN if not already set
      SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
      
      # Find notes in common locations
      local zet_inbox="${SECOND_BRAIN}/0-inbox"
      local zet_dir="${SECOND_BRAIN}/Zettelkasten"
      local zet_note_path=""
      
      if [[ -d "$zet_inbox" ]] && [[ -n "$(find "$zet_inbox" -maxdepth 1 -name "*.md" -type f 2>/dev/null)" ]]; then
        echo "Available notes (inbox):"
        zet_note_path=$(select_from_list "note" "$zet_inbox" "name")
      elif [[ -d "$zet_dir" ]] && [[ -n "$(find "$zet_dir" -name "*.md" -type f 2>/dev/null | head -20)" ]]; then
        echo "Available notes (zettelkasten):"
        zet_note_path=$(select_from_list "note" "$zet_dir" "name")
      fi
      
      if [[ -z "$zet_note_path" ]]; then
        echo -n "Zettelkasten note path: "
        read zet_note
      else
        zet_note=$(find "$zet_inbox" "$zet_dir" -name "${zet_note_path}.md" -o -name "*${zet_note_path}*.md" 2>/dev/null | head -1)
        if [[ -z "$zet_note" ]]; then
          zet_note="$zet_note_path"
        fi
      fi
      
      if [[ -z "$zet_note" ]]; then
        echo "❌ No note selected"
        echo ""
        gtd_quick_pause
        continue
      fi
      
      # Set up GTD paths
      # Paths are already set by init_gtd_paths in gtd-common.sh (DRY - reuse existing helper)
      GOALS_PATH="${GOALS_PATH:-${GTD_BASE_DIR}/goals}"
      
      # Show GTD item type selection menu
      echo ""
      echo -e "${BOLD}What type of GTD item?${NC}"
      echo ""
      echo "  1) Area"
      echo "  2) Project"
      echo "  3) Task"
      echo "  4) Goal"
      echo "  5) MOC (Map of Content)"
      echo ""
      echo -n "Choose: "
      read gtd_type_choice
      
      local gtd_item=""
      
      case "$gtd_type_choice" in
        1)
          # Area selection
          if [[ -d "$AREAS_PATH" ]]; then
            local area_name=$(select_from_list "area" "$AREAS_PATH" "name")
            if [[ -n "$area_name" ]]; then
              # Find the area file
              gtd_item=$(find "$AREAS_PATH" -name "${area_name}.md" -o -name "*${area_name}*.md" 2>/dev/null | head -1)
              if [[ -z "$gtd_item" ]]; then
                # Try to find by display name in frontmatter
                while IFS= read -r area_file; do
                  # Use standardized helper function (DRY - reuse existing helper)
                  local file_name=$(gtd_get_frontmatter_value "$area_file" "name")
                  if [[ "$file_name" == "$area_name" ]]; then
                    gtd_item="$area_file"
                    break
                  fi
                done < <(find "$AREAS_PATH" -name "*.md" -type f 2>/dev/null)
              fi
            fi
          fi
          ;;
        2)
          # Project selection
          if [[ -d "$PROJECTS_PATH" ]]; then
            local project_name=$(select_from_list "project" "$PROJECTS_PATH" "project")
            if [[ -n "$project_name" ]]; then
              # Projects are directories with README.md
              gtd_item=$(find "$PROJECTS_PATH" -type d -name "*${project_name}*" 2>/dev/null | head -1)
              if [[ -n "$gtd_item" && -f "${gtd_item}/README.md" ]]; then
                gtd_item="${gtd_item}/README.md"
              else
                # Try to find by display name in README.md
                while IFS= read -r project_dir; do
                  local readme="${project_dir}/README.md"
                  if [[ -f "$readme" ]]; then
                    # Use standardized helper function (DRY - reuse existing helper)
                    local file_name=$(get_project_name "$readme")
                    if [[ "$file_name" == "$project_name" ]]; then
                      gtd_item="$readme"
                      break
                    fi
                  fi
                done < <(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)
              fi
            fi
          fi
          ;;
        3)
          # Task selection
          if [[ -d "$TASKS_PATH" ]]; then
            # Use select_from_tasks if available, otherwise use select_from_list
            if declare -f select_from_tasks &>/dev/null; then
              local task_id=$(select_from_tasks "task")
              if [[ -n "$task_id" ]]; then
                # Use standardized helper function (DRY - reuse existing helper)
                gtd_item=$(find_task_file "$task_id")
              fi
            else
              # Fallback to select_from_list
              local task_name=$(select_from_list "task" "$TASKS_PATH" "name")
              if [[ -n "$task_name" ]]; then
                gtd_item=$(find "$TASKS_PATH" -name "*${task_name}*.md" 2>/dev/null | head -1)
              fi
            fi
          fi
          ;;
        4)
          # Goal selection
          if [[ -d "$GOALS_PATH" ]]; then
            local goal_name=$(select_from_list "goal" "$GOALS_PATH" "name")
            if [[ -n "$goal_name" ]]; then
              # Find the goal file
              gtd_item=$(find "$GOALS_PATH" -name "${goal_name}.md" -o -name "*${goal_name}*.md" 2>/dev/null | head -1)
              if [[ -z "$gtd_item" ]]; then
                # Try to find by display name in frontmatter
                while IFS= read -r goal_file; do
                  # Use standardized helper function (DRY - reuse existing helper)
                  local file_name=$(gtd_get_frontmatter_value "$goal_file" "name")
                  if [[ "$file_name" == "$goal_name" ]]; then
                    gtd_item="$goal_file"
                    break
                  fi
                done < <(find "$GOALS_PATH" -name "*.md" -type f 2>/dev/null)
              fi
            fi
          fi
          ;;
        5)
          # MOC selection
          if declare -f get_moc_names_array &>/dev/null; then
            local moc_names=()
            while IFS= read -r moc_name; do
              [[ -n "$moc_name" ]] && moc_names+=("$moc_name")
            done < <(get_moc_names_array)
            
            if [[ ${#moc_names[@]} -eq 0 ]]; then
              echo "No MOCs found."
            else
              local selected_moc=""
              if declare -f select_from_numbered_list &>/dev/null; then
                selected_moc=$(select_from_numbered_list "${moc_names[@]}")
              else
                # Fallback: simple selection
                echo ""
                for i in "${!moc_names[@]}"; do
                  local num=$((i + 1))
                  echo "  ${num}) ${moc_names[$i]}"
                done
                echo ""
                echo -n "Select MOC (number): "
                read moc_choice
                if [[ "$moc_choice" =~ ^[0-9]+$ ]]; then
                  local moc_index=$((moc_choice - 1))
                  if [[ $moc_index -ge 0 && $moc_index -lt ${#moc_names[@]} ]]; then
                    selected_moc="${moc_names[$moc_index]}"
                  fi
                fi
              fi
              
              if [[ -n "$selected_moc" ]]; then
                # MOCs are in SECOND_BRAIN/MOCs/
                local moc_file="${SECOND_BRAIN}/MOCs/MOC - ${selected_moc}.md"
                if [[ -f "$moc_file" ]]; then
                  gtd_item="$moc_file"
                else
                  # Try alternative naming
                  moc_file=$(find "${SECOND_BRAIN}/MOCs" -name "*${selected_moc}*.md" 2>/dev/null | head -1)
                  if [[ -n "$moc_file" ]]; then
                    gtd_item="$moc_file"
                  fi
                fi
              fi
            fi
          fi
          ;;
        *)
          echo "❌ Invalid choice"
          echo ""
    gtd_quick_pause
          continue
          ;;
      esac
      
      if [[ -z "$gtd_item" ]]; then
        echo "❌ No GTD item selected or item not found"
        echo ""
        gtd_quick_pause
        continue
      fi
      
      # Verify the file exists
      if [[ ! -f "$gtd_item" ]]; then
        echo "❌ GTD item file not found: $gtd_item"
        echo ""
        gtd_quick_pause
        continue
      fi
      
      # Link the note to the GTD item
      if [[ -n "$zet_note" && -n "$gtd_item" ]]; then
        zet-link gtd "$zet_note" "$gtd_item"
        echo ""
        gtd_quick_pause
      else
        echo "❌ Both note and GTD item required"
        echo ""
        gtd_quick_pause
      fi
      ;;
    8)
      echo ""
      echo -n "Zettelkasten note path: "
      read zet_note
      echo ""
      echo "Move to:"
      echo "  1) Projects"
      echo "  2) Areas"
      echo "  3) Resources"
      echo "  4) Archives"
      echo ""
      echo -n "Choose: "
      read move_choice
      
      case "$move_choice" in
        1)
          zet-link move "$zet_note" Projects
          ;;
        2)
          zet-link move "$zet_note" Areas
          ;;
        3)
          zet-link move "$zet_note" Resources
          ;;
        4)
          zet-link move "$zet_note" Archives
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      ;;
    9)
      echo ""
      echo "📥 Notes in inbox:"
      echo ""
      local inbox_dir="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}/0-inbox"
      if [[ -d "$inbox_dir" ]]; then
        local count=$(ls -1 "$inbox_dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
        if [[ $count -gt 0 ]]; then
          ls -1t "$inbox_dir"/*.md 2>/dev/null | head -10 | while read -r note; do
            local title=$(head -1 "$note" 2>/dev/null | sed 's/# //' | head -c 60)
            echo "  → $(basename "$note")"
            echo "    $title"
          done
          echo ""
          echo "Total: $count note(s)"
        else
          echo "  (empty)"
        fi
      else
        echo "  Inbox directory not found"
      fi
      ;;
    10)
      echo ""
      echo "🔗 Notes in Zettelkasten directory:"
      echo ""
      local zet_dir="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}/Zettelkasten"
      if [[ -d "$zet_dir" ]]; then
        local count=$(ls -1 "$zet_dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
        if [[ $count -gt 0 ]]; then
          ls -1t "$zet_dir"/*.md 2>/dev/null | head -10 | while read -r note; do
            local title=$(head -1 "$note" 2>/dev/null | sed 's/# //' | head -c 60)
            echo "  → $(basename "$note")"
            echo "    $title"
          done
          echo ""
          echo "Total: $count note(s)"
        else
          echo "  (empty)"
        fi
      else
        echo "  Zettelkasten directory not found"
      fi
      ;;
    11)
      echo ""
      echo "📋 Process Zettelkasten inbox"
      echo ""
      local inbox_dir="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}/0-inbox"
      if [[ ! -d "$inbox_dir" ]]; then
        echo "❌ Inbox directory not found"
        echo ""
        gtd_quick_pause
        return 1
      fi
      
      # Use mapfile to properly handle paths with spaces
      local notes=()
      while IFS= read -r -d '' note; do
        notes+=("$note")
      done < <(find "$inbox_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null | sort -z -r)
      
      local count=${#notes[@]}
      
      if [[ $count -eq 0 ]]; then
        echo "✅ Zettelkasten inbox is empty!"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      echo "You have $count note(s) in Zettelkasten inbox."
      echo ""
      echo "Processing notes..."
      echo ""
      
      for note in "${notes[@]}"; do
        local note_name=$(basename "$note")
        local title=$(head -1 "$note" 2>/dev/null | sed 's/# //' | head -c 60)
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 Note: $note_name"
        echo "   Title: $title"
        echo ""
        echo "What would you like to do?"
        echo ""
        echo "  1) Move to Zettelkasten directory"
        echo "  2) Move to Resources (PARA)"
        echo "  3) Move to Projects (PARA)"
        echo "  4) Move to Areas (PARA)"
        echo "  5) Keep in inbox"
        echo "  6) Skip (process next)"
        echo ""
        echo -n "Choose: "
        read process_choice
        
        case "$process_choice" in
          1)
            local zet_dir="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}/Zettelkasten"
            mkdir -p "$zet_dir"
            mv "$note" "$zet_dir/"
            echo "✓ Moved to Zettelkasten directory"
            ;;
          2)
            zet-link move "${note}" Resources
            ;;
          3)
            zet-link move "${note}" Projects
            ;;
          4)
            zet-link move "${note}" Areas
            ;;
          5)
            echo "✓ Keeping in inbox"
            ;;
          6|"")
            echo "→ Skipping..."
            ;;
          *)
            echo "Invalid choice, skipping..."
            ;;
        esac
        echo ""
      done
      
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "✓ Processing complete!"
      ;;
    12)
      echo ""
      echo "🔗 AI Connection Suggestions"
      echo ""
      echo -n "Enter note path: "
      read note_path
      if [[ -n "$note_path" ]]; then
        if [[ ! "$note_path" =~ ^/ ]]; then
          # Try to find it in common locations
          note_path=$(find "${SECOND_BRAIN}/0-inbox" "${SECOND_BRAIN}/Zettelkasten" "${SECOND_BRAIN}" \
            -name "${note_path}.md" -o -name "*${note_path}*.md" 2>/dev/null | head -1)
        fi
        
        if [[ -f "$note_path" ]]; then
          echo ""
          echo "Suggesting connections..."
          echo ""
          if command -v gtd-brain-suggest-connections &>/dev/null; then
            gtd-brain-suggest-connections suggest "$note_path" 5
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-suggest-connections" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-suggest-connections" suggest "$note_path" 5
          else
            echo "❌ Connection suggestions not available"
          fi
        else
          echo "❌ Note not found: $note_path"
        fi
      else
        echo "❌ No path provided"
      fi
      ;;
    13)
      echo ""
      echo "🔍 Finding Orphaned Notes"
      echo ""
      echo "Looking for notes with no connections..."
      echo ""
      if command -v gtd-brain-suggest-connections &>/dev/null; then
        gtd-brain-suggest-connections orphaned 10 | while IFS='|' read -r note_path note_title; do
          if [[ -n "$note_path" && -n "$note_title" ]]; then
            echo "  → $note_title"
            echo "    $note_path"
            echo ""
          fi
        done
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-suggest-connections" ]]; then
        "$HOME/code/dotfiles/bin/gtd-brain-suggest-connections" orphaned 10 | while IFS='|' read -r note_path note_title; do
          if [[ -n "$note_path" && -n "$note_title" ]]; then
            echo "  → $note_title"
            echo "    $note_path"
            echo ""
          fi
        done
      else
        echo "❌ Orphaned note detection not available"
      fi
      ;;
    14)
      echo ""
      echo "📝 Suggest Log Entries → Permanent Notes"
      echo ""
      echo "Analyzing recent daily logs for insights worth preserving..."
      echo ""
      if command -v gtd-brain-suggest-connections &>/dev/null; then
        suggestions=$(gtd-brain-suggest-connections permanent-notes 7 5)
        if [[ -n "$suggestions" ]]; then
          echo "$suggestions"
          echo ""
          echo "💡 Create permanent notes from these suggestions using: zet \"<title>\""
        else
          echo "No suggestions found"
        fi
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-suggest-connections" ]]; then
        suggestions=$("$HOME/code/dotfiles/bin/gtd-brain-suggest-connections" permanent-notes 7 5)
        if [[ -n "$suggestions" ]]; then
          echo "$suggestions"
          echo ""
          echo "💡 Create permanent notes from these suggestions using: zet \"<title>\""
        else
          echo "No suggestions found"
        fi
      else
        echo "❌ Permanent note suggestions not available"
      fi
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  echo ""
    gtd_quick_pause
}

# Review and complete tasks in a specific project
review_project_tasks() {
  local project_slug="$1"
  local project_name="${2:-$project_slug}"
  
  local project_dir="${PROJECTS_PATH}/${project_slug}"
  if [[ ! -d "$project_dir" ]]; then
    gtd_feedback error "Project directory not found: $project_slug"
    gtd_quick_pause
    return 1
  fi
  
  # Get all tasks in this project
  local tasks=()
  while IFS= read -r task_file; do
    [[ ! -f "$task_file" ]] && continue
    [[ "$task_file" == */README.md ]] && continue
    local status=$(gtd_get_frontmatter_value "$task_file" "status")
    if [[ "$status" == "active" ]]; then
      tasks+=("$task_file")
    fi
  done < <(find "$project_dir" -name "*.md" -type f 2>/dev/null)
  
  if [[ ${#tasks[@]} -eq 0 ]]; then
    gtd_empty_state "active tasks" "No active tasks found in this project"
    gtd_quick_pause
    return 0
  fi
  
  # Filter out invalid tasks
  local valid_tasks=()
  for t in "${tasks[@]}"; do
    if [[ -f "$t" ]] && [[ -r "$t" ]]; then
      valid_tasks+=("$t")
    fi
  done
  tasks=("${valid_tasks[@]}")
  
  if [[ ${#tasks[@]} -eq 0 ]]; then
    gtd_empty_state "active tasks" "No valid tasks found in this project"
    gtd_quick_pause
    return 0
  fi
  
  local current_idx=0
  local total_tasks=${#tasks[@]}
  
  while [[ $current_idx -lt $total_tasks ]]; do
    local task_file="${tasks[$current_idx]}"
    
    # Validate task still exists
    if [[ ! -f "$task_file" ]] || [[ ! -r "$task_file" ]]; then
      local new_tasks=()
      for t in "${tasks[@]}"; do
        if [[ "$t" != "$task_file" ]] && [[ -f "$t" ]] && [[ -r "$t" ]]; then
          new_tasks+=("$t")
        fi
      done
      tasks=("${new_tasks[@]}")
      total_tasks=${#tasks[@]}
      
      if [[ $total_tasks -eq 0 ]]; then
        clear
        gtd_feedback success "All tasks have been processed!"
        echo ""
        gtd_quick_pause
        return 0
      fi
      continue
    fi
    
    clear
    local display_name=$(echo "$project_name" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
    gtd_print_header "Review Tasks: $display_name ($((current_idx + 1))/${total_tasks})" "📋"
    echo ""
    
    local task_id=$(basename "$task_file" .md)
    local task_name=""
    if [[ -f "$task_file" ]]; then
      task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || echo "$task_id")
      task_name=$(echo "$task_name" | sed -E 's/[[:space:]]*--(context|priority|energy|project|repository|repo|recurring|frequency)(=[^[:space:]]*)?[[:space:]]*/ /g' | sed 's/[[:space:]]\{2,\}/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    else
      task_name="$task_id"
    fi
    
    local context=$(gtd_get_frontmatter_value "$task_file" "context")
    local energy=$(gtd_get_frontmatter_value "$task_file" "energy")
    local priority=$(gtd_get_frontmatter_value "$task_file" "priority")
    
    echo -e "${BOLD}Task:${NC} ${task_name}"
    echo -e "${BOLD}ID:${NC} ${task_id}"
    if [[ -n "$context" ]]; then
      echo -e "${BOLD}Context:${NC} ${context}"
    fi
    if [[ -n "$energy" ]]; then
      echo -e "${BOLD}Energy:${NC} ${energy}"
    fi
    if [[ -n "$priority" ]]; then
      echo -e "${BOLD}Priority:${NC} ${priority}"
    fi
    echo ""
    echo -e "${BOLD}Content:${NC}"
    if [[ -f "$task_file" ]]; then
      head -10 "$task_file" 2>/dev/null | tail -5 | sed 's/^/  /'
    else
      echo "  (Task file not found)"
    fi
    echo ""
    gtd_section_divider "$CYAN"
    echo ""
    echo "What would you like to do?"
    echo ""
    gtd_format_list_item "1" "Mark as completed"
    gtd_format_list_item "2" "View full task"
    gtd_format_list_item "3" "Edit task details"
    gtd_format_list_item "4" "Add note to task"
    gtd_format_list_item "5" "Schedule to calendar"
    gtd_format_list_item "6" "Skip (next task)"
    gtd_format_list_item "7" "Back to project menu"
    gtd_format_list_item "8" "⭐ Favorite/Unfavorite task"
    echo ""
    echo -n "Choose (1-8): "
    read action
    
    case "$action" in
      1)
        if command -v gtd-task &>/dev/null; then
          gtd-task complete "$task_id" >/dev/null 2>&1
          if [[ -n "$task_name" ]]; then
            gtd_action_success "completed" "task" "$task_name"
          else
            gtd_feedback success "Task completed"
          fi
          
          # Remove from array
          local new_tasks=()
          for t in "${tasks[@]}"; do
            if [[ "$t" != "$task_file" ]]; then
              new_tasks+=("$t")
            fi
          done
          tasks=("${new_tasks[@]}")
          total_tasks=${#tasks[@]}
          
          if [[ $total_tasks -eq 0 ]]; then
            clear
            gtd_feedback success "All tasks in this project have been processed!"
            echo ""
            gtd_quick_pause
            return 0
          fi
          gtd_quick_pause
        else
          gtd_feedback error "gtd-task command not found"
          gtd_quick_pause
        fi
        ;;
      2)
        if command -v gtd-task &>/dev/null; then
          clear
          gtd-task view "$task_id"
          echo ""
          gtd_quick_pause
        else
          gtd_feedback error "gtd-task command not found"
          gtd_quick_pause
        fi
        ;;
      3)
        # Edit task details
        if command -v gtd-task &>/dev/null; then
          clear
          gtd-task update "$task_id"
          echo ""
          gtd_feedback success "Task updated"
          gtd_quick_pause
        else
          gtd_feedback error "gtd-task command not found"
          gtd_quick_pause
        fi
        ;;
      4)
        # Add note to task
        add_note_to_task_from_review "$task_id"
        ;;
      5)
        # Schedule to calendar
        schedule_task_to_calendar_from_review "$task_id"
        ;;
      6)
        ((current_idx++))
        continue
        ;;
      7)
        return 0
        ;;
      8)
        # Favorite/Unfavorite task
        if [[ -f "$task_file" ]]; then
          local current_favorite=$(gtd_get_frontmatter_value "$task_file" "favorite" 2>/dev/null || echo "")
          local task_name_display=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
          
          if [[ "$current_favorite" == "true" ]]; then
            # Unfavorite
            echo ""
            echo -n "Are you sure you want to unfavorite this task? (y/n): "
            read confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
              if grep -q "^favorite:" "$task_file" 2>/dev/null; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                  sed -i '' "s/^favorite:.*/favorite: false/" "$task_file"
                else
                  sed -i "s/^favorite:.*/favorite: false/" "$task_file"
                fi
                echo ""
                gtd_action_success "unfavorited" "task" "$task_name_display"
              else
                gtd_feedback error "Task is not marked as favorite in frontmatter."
              fi
            fi
          else
            # Favorite
            if grep -q "^favorite:" "$task_file" 2>/dev/null; then
              if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/^favorite:.*/favorite: true/" "$task_file"
              else
                sed -i "s/^favorite:.*/favorite: true/" "$task_file"
              fi
            else
              # Add favorite field to frontmatter
              # Check if file has frontmatter (starts with ---)
              local has_frontmatter=false
              if head -1 "$task_file" 2>/dev/null | grep -q "^---"; then
                has_frontmatter=true
              fi
              
              if [[ "$has_frontmatter" == "true" ]]; then
                # File has frontmatter - add favorite field
                if grep -q "^status:" "$task_file" 2>/dev/null; then
                  # Add after status field
                  if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "/^status:/a\\
favorite: true
" "$task_file"
                  else
                    sed -i "/^status:/a\\favorite: true" "$task_file"
                  fi
                else
                  # Add after first line of frontmatter (after ---)
                  if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "1a\\
favorite: true
" "$task_file"
                  else
                    sed -i "1a\\favorite: true" "$task_file"
                  fi
                fi
              else
                # File doesn't have frontmatter - add it at the beginning
                local temp_file=$(mktemp)
                echo "---" > "$temp_file"
                echo "favorite: true" >> "$temp_file"
                echo "---" >> "$temp_file"
                echo "" >> "$temp_file"
                cat "$task_file" >> "$temp_file"
                mv "$temp_file" "$task_file"
              fi
            fi
            echo ""
            gtd_action_success "favorited" "task" "$task_name_display"
            echo "   You'll see quick access to this task in the main menu!"
          fi
          gtd_quick_pause
        else
          gtd_feedback error "Task file not found"
          gtd_quick_pause
        fi
        ;;
      *)
        gtd_feedback error "Invalid choice"
        gtd_quick_pause
        ;;
    esac
  done
  
  # Final check
  if [[ ${#tasks[@]} -eq 0 ]]; then
    clear
    gtd_feedback success "All tasks in this project have been processed!"
  else
    echo ""
    gtd_feedback success "Finished reviewing tasks in this project!"
  fi
  echo ""
  gtd_quick_pause
}

# Helper function to add note to task (reusable across review interfaces)
add_note_to_task_from_review() {
  local task_id="$1"
  
  if [[ -z "$task_id" ]]; then
    gtd_feedback error "Task ID required"
    return 1
  fi
  
  if ! command -v gtd-task &>/dev/null; then
    gtd_feedback error "gtd-task command not found"
    return 1
  fi
  
  echo ""
  echo -n "Note title: "
  read note_title
  
  if [[ -z "$note_title" ]]; then
    gtd_feedback error "Note title required"
    gtd_quick_pause
    return 1
  fi
  
  # Call gtd-task add-note and capture output to find the note file path
  # Use tee to display output in real-time while also capturing it
  local temp_output=$(mktemp)
  local note_file=""
  local note_created=false
  
  # Run the command and display output while capturing it
  # This ensures user sees all output including any prompts
  gtd-task add-note "$task_id" "$note_title" 2>&1 | tee "$temp_output"
  local note_output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Check if note was created successfully
  if echo "$note_output" | grep -q "Created note for task:" || echo "$note_output" | grep -q "✓ Created note"; then
    note_created=true
    # Extract note file path from output (format: "File: /path/to/note.md")
    if echo "$note_output" | grep -q "File:"; then
      note_file=$(echo "$note_output" | grep "File:" | sed 's/.*File: //' | sed 's/[[:space:]]*$//')
    fi
    # Also try alternative format: "File: /path/to/note.md" or just the path
    if [[ -z "$note_file" ]]; then
      # Try to find the note file by looking for the task's notes directory
      local task_file=$(find_task_file "$task_id" 2>/dev/null || echo "")
      if [[ -n "$task_file" && -f "$task_file" ]]; then
        local task_base=$(basename "$task_file" .md)
        local task_dir=$(dirname "$task_file")
        local notes_dir="${task_dir}/${task_base}/notes"
        # Find the most recently created note file
        if [[ -d "$notes_dir" ]]; then
          note_file=$(find "$notes_dir" -name "*${note_title}*" -type f 2>/dev/null | sort | tail -1)
          # If not found by title, get the most recent note
          if [[ -z "$note_file" ]]; then
            note_file=$(find "$notes_dir" -name "*.md" -type f 2>/dev/null | sort | tail -1)
          fi
        fi
      fi
    fi
  fi
  
  if [[ "$note_created" == "true" && -n "$note_file" && -f "$note_file" ]]; then
    echo ""
    echo "Note created successfully!"
    echo ""
    echo "Would you like to add content to the note now?"
    echo ""
    echo "  1) Open in editor (recommended - full editing)"
    echo "  2) Add quick content (single prompt)"
    echo "  3) Skip (add content later)"
    echo ""
    echo -n "Choose (1-3): "
    read content_choice
    
    case "$content_choice" in
      1)
        if command -v ${EDITOR:-vim} &>/dev/null; then
          ${EDITOR:-vim} "$note_file"
        else
          gtd_feedback error "No editor found. Set EDITOR environment variable."
          echo ""
          echo "Note file location: $note_file"
        fi
        ;;
      2)
        echo ""
        echo "Enter note content (single line or short text):"
        echo -n "Content: "
        read note_content
        
        if [[ -n "$note_content" ]]; then
          # Insert content into note file (after "## Content" line)
          local temp_file=$(mktemp)
          local content_section_found=false
          while IFS= read -r line || [[ -n "$line" ]]; do
            echo "$line" >> "$temp_file"
            if [[ "$line" == "## Content" ]]; then
              content_section_found=true
              echo "" >> "$temp_file"
              echo "$note_content" >> "$temp_file"
            fi
          done < "$note_file"
          
          if [[ "$content_section_found" == "true" ]]; then
            mv "$temp_file" "$note_file"
            echo ""
            gtd_action_success "added" "content" "to note"
          else
            rm -f "$temp_file"
            gtd_feedback error "Could not find Content section in note file"
          fi
        else
          echo ""
          echo "No content added. You can edit the note later."
        fi
        ;;
      3|*)
        echo ""
        echo "Note created. You can edit it later."
        echo "  File: $note_file"
        ;;
    esac
  else
    # Show the error output
    echo "$note_output"
    gtd_feedback error "Failed to add note"
    gtd_quick_pause
    return 1
  fi
}

# Helper function to schedule task to calendar (reusable across review interfaces)
schedule_task_to_calendar_from_review() {
  local task_id="$1"
  
  if [[ -z "$task_id" ]]; then
    gtd_feedback error "Task ID required"
    return 1
  fi
  
  # Check if task has a due date
  local task_file=""
  if command -v gtd-task &>/dev/null; then
    # Try to find task file
    local gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    task_file=$(find "$gtd_base" -type f -name "*${task_id}*" 2>/dev/null | head -1)
  fi
  
  local due_date=""
  if [[ -f "$task_file" ]]; then
    due_date=$(grep "^due:" "$task_file" 2>/dev/null | head -1 | cut -d':' -f2 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi
  
  echo ""
  echo "Schedule task to calendar"
  echo ""
  
  # Ask for calendar type
  echo "Which calendar?"
  echo "  1) Google Calendar (default)"
  echo "  2) Office 365"
  echo ""
  echo -n "Choose (1 or 2, default 1): "
  read cal_type
  cal_type="${cal_type:-1}"
  
  local calendar_type="google"
  case "$cal_type" in
    1)
      calendar_type="google"
      ;;
    2)
      calendar_type="office365"
      ;;
    *)
      gtd_feedback error "Invalid choice, defaulting to Google Calendar"
      calendar_type="google"
      ;;
  esac
  
  # Ask for time if task doesn't have due date
  local when=""
  if [[ -z "$due_date" ]]; then
    echo ""
    echo "This task doesn't have a due date."
    echo -n "When should this be scheduled? (e.g., '2024-12-05 10:00' or 'tomorrow 2pm'): "
    read when
    
    if [[ -z "$when" ]]; then
      gtd_feedback error "Time required to schedule task"
      gtd_quick_pause
      return 1
    fi
  else
    echo ""
    echo "Task has due date: $due_date"
    echo -n "Use this time? (y/n, default y): "
    read use_due
    use_due="${use_due:-y}"
    
    if [[ "$use_due" =~ ^[Yy] ]]; then
      when="$due_date"
    else
      echo -n "Enter new time (e.g., '2024-12-05 10:00' or 'tomorrow 2pm'): "
      read when
      
      if [[ -z "$when" ]]; then
        gtd_feedback error "Time required to schedule task"
        gtd_quick_pause
        return 1
      fi
    fi
  fi
  
  echo ""
  echo "Syncing task to calendar..."
  
  # Call gtd-calendar sync
  if command -v gtd-calendar &>/dev/null; then
    if gtd-calendar sync "$task_id" "$calendar_type" "$when" 2>&1; then
      gtd_action_success "scheduled" "task" "to $calendar_type calendar"
    else
      gtd_feedback error "Failed to sync task to calendar"
      gtd_quick_pause
      return 1
    fi
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
    if "$HOME/code/dotfiles/bin/gtd-calendar" sync "$task_id" "$calendar_type" "$when" 2>&1; then
      gtd_action_success "scheduled" "task" "to $calendar_type calendar"
    else
      gtd_feedback error "Failed to sync task to calendar"
      gtd_quick_pause
      return 1
    fi
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
    if "$HOME/code/personal/dotfiles/bin/gtd-calendar" sync "$task_id" "$calendar_type" "$when" 2>&1; then
      gtd_action_success "scheduled" "task" "to $calendar_type calendar"
    else
      gtd_feedback error "Failed to sync task to calendar"
      gtd_quick_pause
      return 1
    fi
  else
    gtd_feedback error "gtd-calendar command not found"
    gtd_quick_pause
    return 1
  fi
  
  gtd_quick_pause
}

