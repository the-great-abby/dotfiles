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
# Capture wizard
capture_wizard() {
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
  echo ""
  echo -n "Choose: "
  read capture_type
  
  echo ""
  echo -n "What do you want to capture? "
  read capture_content
  
  if [[ -z "$capture_content" ]]; then
    echo "❌ No content provided"
    return 1
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
  
  if [[ -z "$capture_content" ]]; then
    echo "❌ No content provided"
    return 1
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
    *)
      gtd-capture "$capture_content"
      ;;
  esac
  
  echo ""
  echo "✓ Captured! Press Enter to continue..."
  read
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
  show_daily_log_guide
  
  # Display inspirational message
  get_log_inspiration
  echo ""
  
  echo -n "What would you like to log? "
  read log_entry
  
  if [[ -z "$log_entry" ]]; then
    echo "❌ No entry provided"
    return 1
  fi
  
  # Use gtd-daily-log script (standalone version of addInfoToDailyLog)
  if command -v gtd-daily-log &>/dev/null; then
    gtd-daily-log "$log_entry"
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
    "$HOME/code/dotfiles/bin/gtd-daily-log" "$log_entry"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-daily-log" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-daily-log" "$log_entry"
  elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
    addInfoToDailyLog "$log_entry"
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

