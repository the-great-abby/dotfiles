#!/bin/bash
# GTD Wizard Input Functions
# Input/capture wizards for the GTD system

# Get inspirational message for daily log
get_log_inspiration() {
  # Array of inspirational/encouraging messages
  local messages=(
    "✨ What's on your mind today? Every thought matters."
    "💭 Take a moment to reflect. What stands out from today?"
    "🌟 Your experiences are worth capturing. What would you like to remember?"
    "📝 Journaling helps clarity. What's been on your mind?"
    "🎯 What progress did you make today, big or small?"
    "💡 What insight or learning would you like to capture?"
    "🌱 Growth happens in reflection. What did you notice today?"
    "🎨 Your story matters. What moment would you like to preserve?"
    "🔍 What pattern or connection did you observe today?"
    "💪 Celebrate your wins! What went well today?"
    "🌊 Life flows in moments. Which one stands out to you?"
    "🔮 Future you will appreciate this. What should they know?"
    "🎭 Every day is a chapter. What's in today's page?"
    "🌻 What brought you joy or challenged you today?"
    "🚀 What's the next step you're thinking about?"
    "🎪 Life is an adventure. What happened in yours today?"
    "💎 What gem of wisdom or experience would you like to save?"
    "🌈 Every day has its colors. What did you experience?"
    "🦋 Transformation happens in small moments. What changed today?"
    "🎵 What's the rhythm of your day been like?"
  )
  
  # Use day of year to rotate messages (ensures variety across the year)
  local day_of_year=$(date +%j 2>/dev/null || echo "1")
  local message_index=$((day_of_year % ${#messages[@]}))
  
  # Fallback to random if day_of_year calculation fails
  if [[ -z "$day_of_year" || "$day_of_year" == "1" ]]; then
    message_index=$((RANDOM % ${#messages[@]}))
  fi
  
  echo -e "${YELLOW}${messages[$message_index]}${NC}"
}

# Oncall capture wizard - guided workflow for oncall shifts
oncall_capture_wizard() {
  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📞 Oncall Capture Wizard${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    # Show oncall guide if function exists
    if command -v show_oncall_guide &>/dev/null || type show_oncall_guide &>/dev/null 2>/dev/null; then
      show_oncall_guide
    elif [[ -f "$HOME/code/dotfiles/bin/gtd-guides.sh" ]]; then
      source "$HOME/code/dotfiles/bin/gtd-guides.sh" 2>/dev/null
      if command -v gtd_show_oncall_guide &>/dev/null; then
        gtd_show_oncall_guide
      fi
    fi
    echo ""
    echo "What would you like to capture?"
    echo ""
    echo "  1) Shift start (begin oncall shift)"
    echo "  2) Shift end (complete oncall shift)"
    echo "  3) Incident (track an incident)"
    echo "  4) Post-mortem (create post-mortem task/note)"
    echo "  5) Runbook update (documentation improvement)"
    echo "  6) Alert tuning (reduce noise/improve alerts)"
    echo "  7) Oncall task (general oncall action item)"
    echo "  8) Oncall note (general oncall observation)"
    echo "  9) Handoff notes (shift handoff information)"
    echo ""
    echo -e "${YELLOW}  0) Back to capture menu${NC}"
    echo ""
    echo -n "Choose: "
    read oncall_choice
    
    if [[ "$oncall_choice" == "0" ]]; then
      return 0
    fi
    
    case "$oncall_choice" in
      1)
        # Shift start
        clear
        echo ""
        echo -e "${BOLD}${GREEN}📞 Starting Oncall Shift${NC}"
        echo ""
        local shift_start_time=$(date +"%Y-%m-%d %H:%M")
        local shift_date=$(date +"%Y-%m-%d")
        echo "Shift start time: $shift_start_time"
        echo ""
        echo -n "Any notes about this shift? (press Enter to skip): "
        read shift_notes
        
        local shift_content="Oncall shift started at $shift_start_time"
        if [[ -n "$shift_notes" ]]; then
          shift_content="$shift_content - $shift_notes"
        fi
        
        # Log to daily log with oncall tag
        if command -v gtd-daily-log &>/dev/null; then
          gtd-daily-log "📞 $shift_content" --tags="oncall,shift-start"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-daily-log" "📞 $shift_content" --tags="oncall,shift-start"
        elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
          addInfoToDailyLog "📞 $shift_content (oncall,shift-start)"
        else
          # Fallback
          local log_dir="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
          local log_file="${log_dir}/${shift_date}.md"
          mkdir -p "$log_dir"
          if [[ ! -f "$log_file" ]]; then
            echo "# Daily Log - $shift_date" > "$log_file"
            echo "" >> "$log_file"
          fi
          echo "$(date +"%H:%M") - 📞 $shift_content #oncall #shift-start" >> "$log_file"
        fi
        
        # Create a task to track shift completion
        if command -v gtd-task &>/dev/null; then
          gtd-task add "Complete oncall shift handoff" --area="Work & Career" --tags="oncall,shift-end" 2>/dev/null || true
        fi
        
        echo ""
        echo -e "${GREEN}✓ Oncall shift started and logged!${NC}"
        ;;
      2)
        # Shift end
        clear
        echo ""
        echo -e "${BOLD}${GREEN}✅ Ending Oncall Shift${NC}"
        echo ""
        local shift_end_time=$(date +"%Y-%m-%d %H:%M")
        local shift_date=$(date +"%Y-%m-%d")
        echo "Shift end time: $shift_end_time"
        echo ""
        echo -n "How many incidents did you handle? (press Enter to skip): "
        read incident_count
        echo -n "Any notable issues or observations? (press Enter to skip): "
        read shift_summary
        
        local shift_content="Oncall shift ended at $shift_end_time"
        if [[ -n "$incident_count" ]] && [[ "$incident_count" =~ ^[0-9]+$ ]]; then
          shift_content="$shift_content - Handled $incident_count incident(s)"
        fi
        if [[ -n "$shift_summary" ]]; then
          shift_content="$shift_content - $shift_summary"
        fi
        
        # Log to daily log
        if command -v gtd-daily-log &>/dev/null; then
          gtd-daily-log "✅ $shift_content" --tags="oncall,shift-end"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-daily-log" "✅ $shift_content" --tags="oncall,shift-end"
        elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
          addInfoToDailyLog "✅ $shift_content (oncall,shift-end)"
        else
          # Fallback
          local log_dir="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
          local log_file="${log_dir}/${shift_date}.md"
          mkdir -p "$log_dir"
          if [[ ! -f "$log_file" ]]; then
            echo "# Daily Log - $shift_date" > "$log_file"
            echo "" >> "$log_file"
          fi
          echo "$(date +"%H:%M") - ✅ $shift_content #oncall #shift-end" >> "$log_file"
        fi
        
        echo ""
        echo -e "${GREEN}✓ Oncall shift completed and logged!${NC}"
        ;;
      3)
        # Incident tracking
        clear
        echo ""
        echo -e "${BOLD}${RED}🚨 Incident Tracking${NC}"
        echo ""
        echo -n "Incident title/description: "
        read incident_title
        if [[ -z "$incident_title" ]]; then
          echo "❌ Incident title required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo "Severity level:"
        echo "  1) P0 - Critical (service down)"
        echo "  2) P1 - High (major impact)"
        echo "  3) P2 - Medium (moderate impact)"
        echo "  4) P3 - Low (minor impact)"
        echo "  0) Skip severity"
        echo ""
        echo -n "Choose: "
        read severity_choice
        
        local severity=""
        case "$severity_choice" in
          1) severity="P0" ;;
          2) severity="P1" ;;
          3) severity="P2" ;;
          4) severity="P3" ;;
        esac
        
        echo ""
        echo -n "Time to detection (minutes, press Enter to skip): "
        read mttd
        echo -n "Time to resolution (minutes, press Enter to skip): "
        read mttr
        echo -n "Additional notes (press Enter to skip): "
        read incident_notes
        
        local incident_content="Incident: $incident_title"
        if [[ -n "$severity" ]]; then
          incident_content="$incident_content [Severity: $severity]"
        fi
        if [[ -n "$mttd" ]] && [[ "$mttd" =~ ^[0-9]+$ ]]; then
          incident_content="$incident_content [MTTD: ${mttd}m]"
        fi
        if [[ -n "$mttr" ]] && [[ "$mttr" =~ ^[0-9]+$ ]]; then
          incident_content="$incident_content [MTTR: ${mttr}m]"
        fi
        if [[ -n "$incident_notes" ]]; then
          incident_content="$incident_content - $incident_notes"
        fi
        
        # Log to daily log
        if command -v gtd-daily-log &>/dev/null; then
          gtd-daily-log "🚨 $incident_content" --tags="oncall,incident${severity:+,$severity}"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-daily-log" "🚨 $incident_content" --tags="oncall,incident${severity:+,$severity}"
        elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
          addInfoToDailyLog "🚨 $incident_content (oncall,incident${severity:+,$severity})"
        else
          # Fallback
          local log_dir="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
          local today=$(date +"%Y-%m-%d")
          local log_file="${log_dir}/${today}.md"
          mkdir -p "$log_dir"
          if [[ ! -f "$log_file" ]]; then
            echo "# Daily Log - $today" > "$log_file"
            echo "" >> "$log_file"
          fi
          echo "$(date +"%H:%M") - 🚨 $incident_content #oncall #incident${severity:+ #$severity}" >> "$log_file"
        fi
        
        # Create post-mortem task if P0 or P1
        if [[ "$severity" == "P0" ]] || [[ "$severity" == "P1" ]]; then
          if command -v gtd-task &>/dev/null; then
            gtd-task add "Post-mortem: $incident_title" --area="Work & Career" --tags="oncall,post-mortem,$severity" 2>/dev/null || true
            echo ""
            echo -e "${YELLOW}📝 Post-mortem task created (P0/P1 incidents require post-mortems)${NC}"
          fi
        fi
        
        echo ""
        echo -e "${GREEN}✓ Incident logged!${NC}"
        ;;
      4)
        # Post-mortem
        clear
        echo ""
        echo -e "${BOLD}${BLUE}📝 Post-Mortem${NC}"
        echo ""
        echo -n "Post-mortem title (incident name): "
        read pm_title
        if [[ -z "$pm_title" ]]; then
          echo "❌ Post-mortem title required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo "What would you like to do?"
        echo "  1) Create post-mortem task"
        echo "  2) Create post-mortem note"
        echo "  3) Both (task + note)"
        echo ""
        echo -n "Choose: "
        read pm_choice
        
        case "$pm_choice" in
          1|3)
            # Create task
            if command -v gtd-task &>/dev/null; then
              gtd-task add "Post-mortem: $pm_title" --area="Work & Career" --tags="oncall,post-mortem" 2>/dev/null || true
              echo -e "${GREEN}✓ Post-mortem task created${NC}"
            else
              gtd-capture --type=task "Post-mortem: $pm_title #oncall #post-mortem"
              echo -e "${GREEN}✓ Post-mortem task captured${NC}"
            fi
            ;;
        esac
        
        case "$pm_choice" in
          2|3)
            # Create note
            echo ""
            echo -n "Post-mortem notes (press Enter to skip): "
            read pm_notes
            local pm_content="Post-mortem: $pm_title"
            if [[ -n "$pm_notes" ]]; then
              pm_content="$pm_content - $pm_notes"
            fi
            gtd-capture --type=note "$pm_content #oncall #post-mortem"
            echo -e "${GREEN}✓ Post-mortem note captured${NC}"
            ;;
        esac
        ;;
      5)
        # Runbook update
        clear
        echo ""
        echo -e "${BOLD}${BLUE}📚 Runbook Update${NC}"
        echo ""
        echo -n "What runbook needs updating? "
        read runbook_name
        if [[ -z "$runbook_name" ]]; then
          echo "❌ Runbook name required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo -n "What needs to be updated? "
        read update_details
        
        local runbook_content="Update runbook: $runbook_name"
        if [[ -n "$update_details" ]]; then
          runbook_content="$runbook_content - $update_details"
        fi
        
        # Create task
        if command -v gtd-task &>/dev/null; then
          gtd-task add "$runbook_content" --area="Work & Career" --tags="oncall,runbook,documentation" 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ Runbook update task created${NC}"
        else
          gtd-capture --type=task "$runbook_content #oncall #runbook #documentation"
          echo ""
          echo -e "${GREEN}✓ Runbook update captured${NC}"
        fi
        ;;
      6)
        # Alert tuning
        clear
        echo ""
        echo -e "${BOLD}${YELLOW}🔔 Alert Tuning${NC}"
        echo ""
        echo -n "What alert needs tuning? "
        read alert_name
        if [[ -z "$alert_name" ]]; then
          echo "❌ Alert name required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo "What action is needed?"
        echo "  1) Reduce noise (too many false positives)"
        echo "  2) Increase sensitivity (missed incidents)"
        echo "  3) Update threshold"
        echo "  4) Disable alert"
        echo "  5) Other"
        echo ""
        echo -n "Choose: "
        read alert_action_choice
        
        local action_desc=""
        case "$alert_action_choice" in
          1) action_desc="Reduce noise (too many false positives)" ;;
          2) action_desc="Increase sensitivity (missed incidents)" ;;
          3) action_desc="Update threshold" ;;
          4) action_desc="Disable alert" ;;
          5)
            echo -n "Describe the action needed: "
            read action_desc
            ;;
        esac
        
        echo ""
        echo -n "Additional notes (press Enter to skip): "
        read alert_notes
        
        local alert_content="Alert tuning: $alert_name - $action_desc"
        if [[ -n "$alert_notes" ]]; then
          alert_content="$alert_content - $alert_notes"
        fi
        
        # Create task
        if command -v gtd-task &>/dev/null; then
          gtd-task add "$alert_content" --area="Work & Career" --tags="oncall,alert-tuning,monitoring" 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ Alert tuning task created${NC}"
        else
          gtd-capture --type=task "$alert_content #oncall #alert-tuning #monitoring"
          echo ""
          echo -e "${GREEN}✓ Alert tuning captured${NC}"
        fi
        ;;
      7)
        # Oncall task
        clear
        echo ""
        echo -e "${BOLD}${CYAN}✅ Oncall Task${NC}"
        echo ""
        echo -n "What task needs to be done? "
        read task_content
        if [[ -z "$task_content" ]]; then
          echo "❌ Task description required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        # Create task with oncall tag
        if command -v gtd-task &>/dev/null; then
          gtd-task add "$task_content" --area="Work & Career" --tags="oncall" 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ Oncall task created${NC}"
        else
          gtd-capture --type=task "$task_content #oncall"
          echo ""
          echo -e "${GREEN}✓ Oncall task captured${NC}"
        fi
        ;;
      8)
        # Oncall note
        clear
        echo ""
        echo -e "${BOLD}${CYAN}📝 Oncall Note${NC}"
        echo ""
        echo -n "What would you like to note? "
        read note_content
        if [[ -z "$note_content" ]]; then
          echo "❌ Note content required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        # Log to daily log
        if command -v gtd-daily-log &>/dev/null; then
          gtd-daily-log "📝 Oncall: $note_content" --tags="oncall"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-daily-log" "📝 Oncall: $note_content" --tags="oncall"
        elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
          addInfoToDailyLog "📝 Oncall: $note_content (oncall)"
        else
          gtd-capture --type=note "$note_content #oncall"
        fi
        
        echo ""
        echo -e "${GREEN}✓ Oncall note captured!${NC}"
        ;;
      9)
        # Handoff notes
        clear
        echo ""
        echo -e "${BOLD}${CYAN}🤝 Shift Handoff Notes${NC}"
        echo ""
        echo -n "Handoff notes for next oncall engineer: "
        read handoff_content
        if [[ -z "$handoff_content" ]]; then
          echo "❌ Handoff notes required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        # Create note with handoff tag
        gtd-capture --type=note "Handoff: $handoff_content #oncall #handoff"
        echo ""
        echo -e "${GREEN}✓ Handoff notes captured!${NC}"
        ;;
      *)
        echo "❌ Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        continue
        ;;
    esac
    
    echo ""
    echo "What would you like to do next?"
    echo "  1) Capture another oncall item"
    echo "  2) Back to capture menu"
    echo ""
    echo -n "Choose: "
    read continue_choice
    
    if [[ "$continue_choice" == "2" ]]; then
      return 0
    fi
    # If choice is 1 or anything else, loop continues
  done
}

# Capture wizard
capture_wizard() {
  # Loop to stay in capture mode
  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📥 Capture Wizard${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    show_capture_guide
    echo "What type of item are you capturing?"
    echo ""
    echo "  1) Task (actionable item)"
    echo "  2) Idea (someday/maybe)"
    echo "  3) Reference (information to keep)"
    echo "  4) Link (URL to save)"
    echo "  5) Call (phone call notes)"
    echo "  6) Email (email action)"
    echo "  7) General note"
    echo "  8) Zettelkasten note (atomic idea)"
    echo "  9) Daily log entry"
    echo " 10) Oncall capture (guided oncall workflow)"
    echo ""
    echo -e "${YELLOW}  0) Exit capture mode${NC}"
    echo ""
    echo -n "Choose: "
    read capture_type
    
    # Check if user wants to exit
    if [[ "$capture_type" == "0" ]]; then
      echo ""
      echo "Exiting capture mode..."
      return 0
    fi
    
    echo ""
    echo -n "What do you want to capture? "
    read capture_content
    
    if [[ -z "$capture_content" ]]; then
      echo "❌ No content provided"
      echo ""
      echo "Press Enter to continue..."
      read
      continue  # Loop back to capture menu
    fi
    
    # For certain capture types, walk through 5 horizons
    if [[ "$capture_type" == "1" ]] || [[ "$capture_type" == "2" ]] || [[ "$capture_type" == "7" ]]; then
      echo ""
      echo -e "${BOLD}🎯 5 Horizons of Focus - Where does this fit?${NC}"
      echo ""
      echo "The 5 Horizons help you see the bigger picture:"
      echo ""
      echo -e "  ${CYAN}Runway (Ground)${NC} - Current actions & tasks"
      echo -e "  ${CYAN}10,000 ft${NC} - Current projects (outcomes with deadlines)"
      echo -e "  ${CYAN}20,000 ft${NC} - Areas of responsibility (ongoing roles)"
      echo -e "  ${CYAN}30,000 ft${NC} - 1-2 year goals & objectives"
      echo -e "  ${CYAN}40,000 ft${NC} - 3-5 year vision & long-term goals"
      echo ""
      echo "Where does this item fit in your horizons?"
      echo ""
      echo "  1) Runway (Ground) - Just a task/action"
      echo "  2) 10,000 ft - Part of a current project"
      echo "  3) 20,000 ft - Related to an area of responsibility"
      echo "  4) 30,000 ft - Supports a 1-2 year goal"
      echo "  5) 40,000 ft - Aligns with long-term vision"
      echo "  0) Skip horizons (just capture it)"
      echo ""
      echo -n "Choose: "
      read horizon_choice
      
      case "$horizon_choice" in
        1)
          # Runway - just capture as task
          horizon_context="runway"
          ;;
        2)
          # 10,000 ft - project level
          horizon_context="project"
          echo ""
          echo "Which project does this relate to?"
          if [[ -d "$PROJECTS_PATH" ]] && [[ -n "$(find "$PROJECTS_PATH" -type d -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
            selected_project=$(select_from_list "project" "$PROJECTS_PATH" "project")
            if [[ -n "$selected_project" ]]; then
              project_name=$(echo "$selected_project" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
              horizon_context="project:$project_name"
            fi
          else
            echo -n "Project name (or press Enter to skip): "
            read project_input
            if [[ -n "$project_input" ]]; then
              horizon_context="project:$project_input"
            fi
          fi
          ;;
        3)
          # 20,000 ft - area level
          horizon_context="area"
          echo ""
          echo "Which area of responsibility does this relate to?"
          if [[ -d "$AREAS_PATH" ]] && [[ -n "$(find "$AREAS_PATH" -name "*.md" -type f 2>/dev/null)" ]]; then
            selected_area=$(select_from_list "area" "$AREAS_PATH" "area")
            if [[ -n "$selected_area" ]]; then
              area_name=$(echo "$selected_area" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
              horizon_context="area:$area_name"
            fi
          else
            echo -n "Area name (or press Enter to skip): "
            read area_input
            if [[ -n "$area_input" ]]; then
              horizon_context="area:$area_input"
            fi
          fi
          ;;
        4)
          # 30,000 ft - 1-2 year goals
          horizon_context="goal_1_2yr"
          echo ""
          echo -n "What 1-2 year goal does this support? (optional note): "
          read goal_note
          if [[ -n "$goal_note" ]]; then
            horizon_context="goal_1_2yr:$goal_note"
          fi
          ;;
        5)
          # 40,000 ft - long-term vision
          horizon_context="vision_3_5yr"
          echo ""
          echo -n "What long-term vision/goal does this align with? (optional note): "
          read vision_note
          if [[ -n "$vision_note" ]]; then
            horizon_context="vision_3_5yr:$vision_note"
          fi
          ;;
        0|"")
          # Skip horizons
          horizon_context=""
          ;;
        *)
          horizon_context=""
          ;;
      esac
    else
      horizon_context=""
    fi
    
    case "$capture_type" in
      1)
        # Tasks should go directly to tasks directory, not inbox
        # This allows them to appear in task management immediately
        echo ""
        echo "Creating task..."
        if [[ -n "$horizon_context" ]]; then
          # Extract project/area from horizon context if present
          if [[ "$horizon_context" == project:* ]]; then
            project_name="${horizon_context#project:}"
            gtd-task add "$capture_content" --project="$project_name"
          elif [[ "$horizon_context" == area:* ]]; then
            area_name="${horizon_context#area:}"
            gtd-task add "$capture_content" --area="$area_name"
          else
            gtd-task add "$capture_content"
          fi
        else
          gtd-task add "$capture_content"
        fi
        ;;
      2)
        # Idea - add horizon context to content if provided
        if [[ -n "$horizon_context" ]]; then
          horizon_note=""
          case "$horizon_context" in
            runway)
              horizon_note="[Horizon: Runway - Current action]"
              ;;
            project:*)
              project_name="${horizon_context#project:}"
              horizon_note="[Horizon: 10k ft - Project: $project_name]"
              ;;
            area:*)
              area_name="${horizon_context#area:}"
              horizon_note="[Horizon: 20k ft - Area: $area_name]"
              ;;
            goal_1_2yr*)
              goal_note="${horizon_context#goal_1_2yr:}"
              if [[ -n "$goal_note" ]]; then
                horizon_note="[Horizon: 30k ft - Goal: $goal_note]"
              else
                horizon_note="[Horizon: 30k ft - 1-2 year goal]"
              fi
              ;;
            vision_3_5yr*)
              vision_note="${horizon_context#vision_3_5yr:}"
              if [[ -n "$vision_note" ]]; then
                horizon_note="[Horizon: 40k ft - Vision: $vision_note]"
              else
                horizon_note="[Horizon: 40k ft - Long-term vision]"
              fi
              ;;
          esac
          gtd-capture --type=idea "$capture_content $horizon_note"
        else
          gtd-capture --type=idea "$capture_content"
        fi
        ;;
      3)
        gtd-capture --type=reference "$capture_content"
        ;;
      4)
        gtd-capture --type=link "$capture_content"
        ;;
      5)
        gtd-capture --type=call "$capture_content"
        ;;
      6)
        gtd-capture --type=email "$capture_content"
        ;;
      7)
        # General note - add horizon context to content if provided
        if [[ -n "$horizon_context" ]]; then
          horizon_note=""
          case "$horizon_context" in
            runway)
              horizon_note="[Horizon: Runway - Current action]"
              ;;
            project:*)
              project_name="${horizon_context#project:}"
              horizon_note="[Horizon: 10k ft - Project: $project_name]"
              ;;
            area:*)
              area_name="${horizon_context#area:}"
              horizon_note="[Horizon: 20k ft - Area: $area_name]"
              ;;
            goal_1_2yr*)
              goal_note="${horizon_context#goal_1_2yr:}"
              if [[ -n "$goal_note" ]]; then
                horizon_note="[Horizon: 30k ft - Goal: $goal_note]"
              else
                horizon_note="[Horizon: 30k ft - 1-2 year goal]"
              fi
              ;;
            vision_3_5yr*)
              vision_note="${horizon_context#vision_3_5yr:}"
              if [[ -n "$vision_note" ]]; then
                horizon_note="[Horizon: 40k ft - Vision: $vision_note]"
              else
                horizon_note="[Horizon: 40k ft - Long-term vision]"
              fi
              ;;
          esac
          gtd-capture "$capture_content $horizon_note"
        else
          gtd-capture "$capture_content"
        fi
        ;;
      8)
        zet "$capture_content"
        ;;
      9)
        # Daily log entry - can be captured while staying in capture mode
        # Use gtd-daily-log script (standalone version of addInfoToDailyLog)
        if command -v gtd-daily-log &>/dev/null; then
          gtd-daily-log "$capture_content"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-daily-log" "$capture_content"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-daily-log" "$capture_content"
        elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
          addInfoToDailyLog "$capture_content"
        else
          echo "❌ Daily log command not found. Using fallback..."
          # Fallback: implement basic logging directly
          local log_dir="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
          local today=$(date +"%Y-%m-%d")
          local current_time=$(date +"%H:%M")
          local log_file="${log_dir}/${today}.md"
          mkdir -p "$log_dir"
          if [[ ! -f "$log_file" ]]; then
            echo "# Daily Log - $today" > "$log_file"
            echo "" >> "$log_file"
          fi
          echo "${current_time} - ${capture_content}" >> "$log_file"
          echo "✓ Added: ${current_time} - ${capture_content}"
        fi
        ;;
      10)
        # Oncall capture - guided workflow
        oncall_capture_wizard
        ;;
      *)
        gtd-capture "$capture_content"
        ;;
    esac
  
    echo ""
    echo -e "${GREEN}✓ Captured!${NC}"
    echo ""
    echo "What would you like to do next?"
    echo "  1) Capture another item (stay in capture mode)"
    echo "  2) Exit capture mode"
    echo ""
    echo -n "Choose: "
    read continue_choice
    
    if [[ "$continue_choice" == "2" ]]; then
      echo ""
      echo "Exiting capture mode..."
      return 0
    fi
    # If choice is 1 or anything else, loop continues
  done
}
# Process wizard
process_wizard() {
  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📋 Process Inbox Wizard${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    show_process_guide
    
    # Check inbox count
    local inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$inbox_count" -eq 0 ]]; then
      echo "✅ Your inbox is empty!"
      echo ""
      echo "Press Enter to return to main menu..."
      read
      return 0
    fi
  
  echo "You have ${inbox_count} item(s) in your inbox."
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Options:"
  echo "  1) Process next item"
  echo "  2) Process all remaining items"
  echo "  0) Return to main menu"
  echo ""
  read -p "Choose (1/2/0): " choice
  
  case "$choice" in
    1)
      # Process one item
      gtd-process
      local remaining=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$remaining" -gt 0 ]]; then
        echo ""
        echo "📥 $remaining item(s) remaining in inbox"
        echo ""
        echo "Press Enter to continue..."
        read
      else
        echo ""
        echo "✅ All items processed! Inbox is now empty."
        echo ""
        echo "Press Enter to return to main menu..."
        read
        return 0
      fi
      ;;
    2)
      # Process all items
      gtd-process --all
      echo ""
      echo "✅ Finished processing all items!"
      echo ""
      echo "Press Enter to return to main menu..."
      read
      return 0
      ;;
    0|"")
      # Return to main menu
      return 0
      ;;
    *)
      echo "Invalid choice. Please choose 1, 2, or 0."
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
  esac
  done
}

# Daily log wizard
log_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📝 Daily Log Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "What would you like to do?"
  echo ""
  echo -e "${GREEN}1)${NC} 📝 Add entry to daily log"
  echo -e "${GREEN}2)${NC} 👁️  View today's daily log"
  echo -e "${GREEN}3)${NC} 📅 View specific date"
  echo -e "${GREEN}4)${NC} 📚 List available logs"
  echo -e "${GREEN}5)${NC} 🔍 Search logs"
  echo -e "${GREEN}6)${NC} 📋 Show recent entries"
  echo ""
  echo -n "Choose: "
  read log_choice
  
  case "$log_choice" in
    1)
      # Original logging functionality
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📝 Add to Daily Log${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      show_daily_log_guide
      
      # Display inspirational message
      get_log_inspiration
      echo ""
      
      echo -n "What would you like to log? "
      read log_entry
      ;;
    2)
      # View today's log
      clear
      echo ""
      if command -v gtd-log &>/dev/null; then
        gtd-log today
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/dotfiles/bin/gtd-log" today
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-log" today
      else
        echo "❌ gtd-log command not found"
        return 1
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      return 0
      ;;
    3)
      # View specific date
      clear
      echo ""
      echo -n "Enter date (YYYY-MM-DD): "
      read view_date
      if [[ -z "$view_date" ]]; then
        echo "❌ No date provided"
        return 1
      fi
      if command -v gtd-log &>/dev/null; then
        gtd-log view "$view_date"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/dotfiles/bin/gtd-log" view "$view_date"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-log" view "$view_date"
      else
        echo "❌ gtd-log command not found"
        return 1
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      return 0
      ;;
    4)
      # List available logs
      clear
      echo ""
      if command -v gtd-log &>/dev/null; then
        gtd-log list
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/dotfiles/bin/gtd-log" list
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-log" list
      else
        echo "❌ gtd-log command not found"
        return 1
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      return 0
      ;;
    5)
      # Search logs
      clear
      echo ""
      echo -n "Enter search pattern: "
      read search_pattern
      if [[ -z "$search_pattern" ]]; then
        echo "❌ No search pattern provided"
        return 1
      fi
      if command -v gtd-log &>/dev/null; then
        gtd-log search "$search_pattern"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/dotfiles/bin/gtd-log" search "$search_pattern"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-log" search "$search_pattern"
      else
        echo "❌ gtd-log command not found"
        return 1
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      return 0
      ;;
    6)
      # Show recent entries
      clear
      echo ""
      if command -v gtd-log &>/dev/null; then
        gtd-log recent
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/dotfiles/bin/gtd-log" recent
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-log" recent
      else
        echo "❌ gtd-log command not found"
        return 1
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      return 0
      ;;
    *)
      echo "Invalid choice"
      return 1
      ;;
  esac
  
  # If we got here, user chose option 1 (log entry)
  if [[ -z "$log_entry" ]]; then
    echo "❌ No entry provided"
    return 1
  fi
  
  if [[ -z "$log_entry" ]]; then
    echo "❌ No entry provided"
    return 1
  fi
  
  # Use gtd-daily-log script (standalone version of addInfoToDailyLog)
  local log_saved=false
  if command -v gtd-daily-log &>/dev/null; then
    gtd-daily-log "$log_entry"
    log_saved=true
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
    "$HOME/code/dotfiles/bin/gtd-daily-log" "$log_entry"
    log_saved=true
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-daily-log" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-daily-log" "$log_entry"
    log_saved=true
  elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
    addInfoToDailyLog "$log_entry"
    log_saved=true
  else
    echo "❌ Daily log command not found."
    echo "   Trying fallback method..."
    # Fallback: implement basic logging directly
    local log_dir="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
    local today=$(date +"%Y-%m-%d")
    local current_time=$(date +"%H:%M")
    local log_file="${log_dir}/${today}.md"
    mkdir -p "$log_dir"
    if [[ ! -f "$log_file" ]]; then
      echo "# Daily Log - $today" > "$log_file"
      echo "" >> "$log_file"
    fi
    echo "${current_time} - ${log_entry}" >> "$log_file"
    echo "✓ Added: ${current_time} - ${log_entry}"
    log_saved=true
  fi
  
  # Vectorize the log entry if saved successfully
  if [[ "$log_saved" == "true" ]]; then
    local today=$(date +"%Y-%m-%d")
    local current_time=$(date +"%H:%M")
    local entry_id="${today}_${current_time}"
    # Vectorize in background (don't block user)
    if command -v gtd-vectorize-content &>/dev/null; then
      gtd-vectorize-content "daily_log" "$entry_id" "$log_entry" &
    elif [[ -f "$HOME/code/dotfiles/bin/gtd-vectorize-content" ]]; then
      "$HOME/code/dotfiles/bin/gtd-vectorize-content" "daily_log" "$entry_id" "$log_entry" &
    elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-vectorize-content" ]]; then
      "$HOME/code/personal/dotfiles/bin/gtd-vectorize-content" "daily_log" "$entry_id" "$log_entry" &
    fi
    
    # Trigger energy analysis if enabled (event-driven)
    if command -v gtd-deep-analysis-scheduler &>/dev/null; then
      gtd-deep-analysis-scheduler --trigger energy &
    elif [[ -f "$HOME/code/dotfiles/bin/gtd-deep-analysis-scheduler" ]]; then
      "$HOME/code/dotfiles/bin/gtd-deep-analysis-scheduler" --trigger energy &
    elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-deep-analysis-scheduler" ]]; then
      "$HOME/code/personal/dotfiles/bin/gtd-deep-analysis-scheduler" --trigger energy &
    fi
  fi
  
  # Ask if user wants to log weather
  echo ""
  echo -e "${CYAN}💡 Tip:${NC} Logging weather conditions can help identify patterns"
  echo "       between weather and your energy levels, mood, and productivity."
  echo ""
  echo -n "Would you like to log current weather conditions? (y/n, default n): "
  read log_weather
  
  # Log weather if requested
  if [[ "$log_weather" == "y" || "$log_weather" == "Y" ]]; then
    echo ""
    echo "🌤️  Logging weather conditions..."
    if command -v gtd-log-weather &>/dev/null; then
      gtd-log-weather
    elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-weather" ]]; then
      "$HOME/code/dotfiles/bin/gtd-log-weather"
    elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-weather" ]]; then
      "$HOME/code/personal/dotfiles/bin/gtd-log-weather"
    else
      echo "⚠️  Weather logging command not found (gtd-log-weather)"
      echo "   Weather will not be logged."
    fi
  fi
  
  echo ""
  echo "Would you like AI feedback on this log entry?"
  echo "  1) Yes, get feedback from a random persona"
  echo "  2) Yes, choose a specific persona"
  echo "  3) No, skip feedback"
  echo ""
  echo -n "Choose: "
  read feedback_choice
  
  case "$feedback_choice" in
    1)
      echo ""
      echo "Getting feedback from a random persona..."
      echo ""
      if command -v gtd-advise &>/dev/null; then
        gtd-advise --random "I just logged this: $log_entry. What are your thoughts?"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-advise" ]]; then
        "$HOME/code/dotfiles/bin/gtd-advise" --random "I just logged this: $log_entry. What are your thoughts?"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-advise" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-advise" --random "I just logged this: $log_entry. What are your thoughts?"
      else
        echo "⚠️  gtd-advise command not found. Skipping feedback."
      fi
      ;;
    2)
      echo ""
      persona=$(select_persona)
      if [[ -n "$persona" ]]; then
        echo ""
        echo "Getting feedback from $persona..."
        echo ""
        if command -v gtd-advise &>/dev/null; then
          gtd-advise "$persona" "I just logged this: $log_entry. What are your thoughts?"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-advise" ]]; then
          "$HOME/code/dotfiles/bin/gtd-advise" "$persona" "I just logged this: $log_entry. What are your thoughts?"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-advise" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-advise" "$persona" "I just logged this: $log_entry. What are your thoughts?"
        else
          echo "⚠️  gtd-advise command not found. Skipping feedback."
        fi
      fi
      ;;
    3|"")
      # Skip feedback
      ;;
    *)
      echo "Invalid choice. Skipping feedback."
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}

# Check-in wizard
checkin_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🌅🌙 Morning/Evening Check-In${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_checkin_guide
  echo "What type of check-in?"
  echo ""
  echo "  1) 🌅 Morning Check-In"
  echo "  2) 🌙 Evening Check-In"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read checkin_choice
  
  case "$checkin_choice" in
    1)
      gtd-checkin morning
      ;;
    2)
      gtd-checkin evening
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}

# Mood logging wizard
mood_log_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}😊 Mood & Energy Tracker${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_mood_tracking_guide
  if command -v gtd-log-mood &>/dev/null; then
    gtd-log-mood
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-mood" ]]; then
    "$HOME/code/dotfiles/bin/gtd-log-mood"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-mood" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-log-mood"
  else
    echo "❌ gtd-log-mood command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}
# Calendar log wizard
calendar_log_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📅 Log Calendar Events${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  local cmd_found=false
  if command -v gtd-log-calendar &>/dev/null; then
    gtd-log-calendar
    cmd_found=true
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-calendar" ]]; then
    "$HOME/code/dotfiles/bin/gtd-log-calendar"
    cmd_found=true
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-calendar" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-log-calendar"
    cmd_found=true
  fi
  
  if [[ "$cmd_found" == "false" ]]; then
    echo "❌ gtd-log-calendar command not found"
    echo ""
    echo "💡 This feature logs calendar events to your daily log."
    echo "   Make sure the command is installed and in your PATH."
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

# Collect all metrics wizard
collect_all_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Collect All Metrics${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "This will collect all available metrics (health, calendar, weather, etc.)"
  echo ""
  local cmd_found=false
  local output=""
  if command -v gtd-collect-all &>/dev/null; then
    output=$(gtd-collect-all 2>&1)
    cmd_found=true
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-collect-all" ]]; then
    output=$("$HOME/code/dotfiles/bin/gtd-collect-all" 2>&1)
    cmd_found=true
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-collect-all" ]]; then
    output=$("$HOME/code/personal/dotfiles/bin/gtd-collect-all" 2>&1)
    cmd_found=true
  fi
  
  if [[ "$cmd_found" == "false" ]]; then
    echo "❌ gtd-collect-all command not found"
    echo ""
    echo "💡 This feature batch-collects all metrics at once."
    echo "   Make sure the command is installed and in your PATH."
  elif [[ -n "$output" ]]; then
    echo "$output"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

