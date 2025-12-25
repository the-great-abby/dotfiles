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

# Helper function to get incident notes directory
get_incident_notes_dir() {
  local SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
  local incident_dir="${SECOND_BRAIN}/Resources/Incidents"
  mkdir -p "$incident_dir"
  echo "$incident_dir"
}

# Helper function to list active incidents
list_active_incidents() {
  local incident_dir=$(get_incident_notes_dir)
  local incidents=()
  
  if [[ -d "$incident_dir" ]]; then
    while IFS= read -r -d '' file; do
      # Extract incident title from filename (remove timestamp and .md)
      local basename=$(basename "$file" .md)
      local title=$(echo "$basename" | sed 's/^[0-9]\{8\}[0-9]\{6\}-//')
      # Check if incident is active (not resolved)
      if grep -q "status:.*active\|status:.*open\|status:.*ongoing" "$file" 2>/dev/null; then
        incidents+=("$file|$title")
      fi
    done < <(find "$incident_dir" -type f -name "*.md" -print0 2>/dev/null | sort -z)
  fi
  
  printf '%s\n' "${incidents[@]}"
}

# Helper function to generate handoff report
generate_handoff_report() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}📋 Generating Handoff Report${NC}"
  echo ""
  
  local report_date=$(date +"%Y-%m-%d %H:%M")
  local report_content=""
  
  # Gather active oncall tasks
  echo "Gathering active oncall tasks..."
  local oncall_tasks=()
  if command -v gtd-task &>/dev/null; then
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        oncall_tasks+=("$line")
      fi
    done < <(gtd-task list --status=active 2>/dev/null | grep -i "#oncall" || true)
  fi
  
  # Gather active incidents
  echo "Gathering active incidents..."
  local active_incidents=$(list_active_incidents)
  
  # Gather on-deck tasks
  echo "Gathering on-deck tasks..."
  local ondeck_tasks=()
  if command -v gtd-task &>/dev/null; then
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        ondeck_tasks+=("$line")
      fi
    done < <(gtd-task list --status=active 2>/dev/null | grep -i "#on-deck\|#ondeck" || true)
  fi
  
  # Build report
  report_content="# Oncall Handoff Report - $report_date\n\n"
  report_content="${report_content}## Active Incidents\n\n"
  
  if [[ -n "$active_incidents" ]]; then
    local count=1
    local incidents_section=""
    while IFS='|' read -r file title; do
      if [[ -n "$file" && -n "$title" ]]; then
        incidents_section="${incidents_section}$count. **$title**\n"
        # Extract key info from incident file
        if [[ -f "$file" ]]; then
          local severity=$(grep -i "^severity:" "$file" 2>/dev/null | head -1 | sed 's/.*severity:[[:space:]]*//i' || echo "")
          local status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*status:[[:space:]]*//i' || echo "")
          if [[ -n "$severity" ]]; then
            incidents_section="${incidents_section}   - Severity: $severity\n"
          fi
          if [[ -n "$status" ]]; then
            incidents_section="${incidents_section}   - Status: $status\n"
          fi
          incidents_section="${incidents_section}   - File: $file\n\n"
        fi
        count=$((count + 1))
      fi
    done <<< "$active_incidents"
    report_content="${report_content}${incidents_section}"
  else
    report_content="${report_content}No active incidents.\n\n"
  fi
  
  report_content="${report_content}## Active Oncall Tasks\n\n"
  if [[ ${#oncall_tasks[@]} -gt 0 ]]; then
    for task in "${oncall_tasks[@]}"; do
      report_content="${report_content}- $task\n"
    done
    report_content="${report_content}\n"
  else
    report_content="${report_content}No active oncall tasks.\n\n"
  fi
  
  report_content="${report_content}## On-Deck Tasks\n\n"
  if [[ ${#ondeck_tasks[@]} -gt 0 ]]; then
    for task in "${ondeck_tasks[@]}"; do
      report_content="${report_content}- $task\n"
    done
    report_content="${report_content}\n"
  else
    report_content="${report_content}No active on-deck tasks.\n\n"
  fi
  
  # Display report
  echo -e "$report_content"
  
  # Save to file
  local handoff_file="${HOME}/Documents/oncall_handoff_$(date +%Y%m%d_%H%M%S).md"
  echo -e "$report_content" > "$handoff_file"
  echo ""
  echo -e "${GREEN}✓ Handoff report saved to: $handoff_file${NC}"
  
  # Also create a note
  gtd-capture --type=note "Handoff Report Generated - $report_date #oncall #handoff" 2>/dev/null || true
  
  echo ""
  gtd_quick_pause
}

# Oncall capture wizard - guided workflow for oncall shifts
oncall_capture_wizard() {
  while true; do
    clear
    gtd_print_header "Oncall Capture Wizard" "📞"
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
    echo -e "${BOLD}🎯 On Deck (First Day Focus):${NC}"
    echo "  1) On deck task (on deck responsibilities)"
    echo ""
    echo -e "${BOLD}📞 Oncall Shift:${NC}"
    echo "  2) Shift start (begin oncall shift)"
    echo "  3) Shift end (complete oncall shift)"
    echo ""
    echo -e "${BOLD}🚨 Incidents:${NC}"
    echo "  4) New incident (track a new incident)"
    echo "  5) Update incident (add notes to existing incident)"
    echo "  6) View active incidents (list all active incidents)"
    echo ""
    echo -e "${BOLD}📋 Other:${NC}"
    echo "  7) Post-mortem (create post-mortem task/note)"
    echo "  8) Runbook update (documentation improvement)"
    echo "  9) Alert tuning (reduce noise/improve alerts)"
    echo " 10) Oncall task (general oncall action item)"
    echo " 11) Oncall note (general oncall observation)"
    echo " 12) Handoff report (generate shift handoff report)"
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
        # On deck task
        clear
        echo ""
        echo -e "${BOLD}${CYAN}🎯 On Deck Task${NC}"
        echo ""
        echo "On deck responsibilities include:"
        echo "  • Post daily infra changes before 3pm MST"
        echo "  • Attend Infrastructure Pre-Release meeting"
        echo "  • Handle permission requests in #rebel-alliance-reliability"
        echo "  • Watch reliability channels for inquiries"
        echo ""
        echo -n "What on deck task needs to be done? "
        read ondeck_task_content
        if [[ -z "$ondeck_task_content" ]]; then
          echo "❌ Task description required"
          echo ""
    gtd_quick_pause
          continue
        fi
        
        # Create task with oncall and on-deck tags
        if command -v gtd-task &>/dev/null; then
          gtd-task add "$ondeck_task_content #oncall #on-deck" --non-interactive --context=computer --energy=medium --priority=not_urgent_important 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ On deck task created${NC}"
        else
          gtd-capture --type=task "$ondeck_task_content #oncall #on-deck"
          echo ""
          echo -e "${GREEN}✓ On deck task captured${NC}"
        fi
        ;;
      2)
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
          gtd-task add "Complete oncall shift handoff #oncall #shift-end" --non-interactive --context=computer --energy=medium --priority=not_urgent_important 2>/dev/null || true
        fi
        
        echo ""
        echo -e "${GREEN}✓ Oncall shift started and logged!${NC}"
        ;;
      3)
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
      4)
        # New incident tracking - create persistent note
        clear
        echo ""
        echo -e "${BOLD}${RED}🚨 New Incident Tracking${NC}"
        echo ""
        echo -n "Incident title/description: "
        read incident_title
        if [[ -z "$incident_title" ]]; then
          echo "❌ Incident title required"
          echo ""
    gtd_quick_pause
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
        echo -n "Initial notes (press Enter to skip): "
        read incident_notes
        
        # Create persistent incident note
        local incident_dir=$(get_incident_notes_dir)
        local timestamp=$(date +"%Y%m%d%H%M%S")
        local safe_title=$(echo "$incident_title" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]' | cut -c1-50)
        local incident_file="${incident_dir}/${timestamp}-${safe_title}.md"
        
        # Create incident note file
        cat > "$incident_file" <<EOF
---
type: incident
status: active
severity: ${severity:-unknown}
created: $(date +"%Y-%m-%d %H:%M:%S")
tags: [oncall, incident${severity:+, $severity}]
---

# Incident: $incident_title

**Status:** Active  
**Severity:** ${severity:-Not specified}  
**Created:** $(date +"%Y-%m-%d %H:%M:%S")

## Timeline

- **Detected:** $(date +"%Y-%m-%d %H:%M:%S")${mttd:+ (MTTD: ${mttd}m)}${mttr:+ (MTTR: ${mttr}m)}

## Initial Notes

${incident_notes:-No initial notes provided.}

## Updates

$(date +"%Y-%m-%d %H:%M:%S") - Incident created

## Resolution

_To be filled in when incident is resolved._

EOF
        
        # Log to daily log
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
        
        if command -v gtd-daily-log &>/dev/null; then
          gtd-daily-log "🚨 $incident_content" --tags="oncall,incident${severity:+,$severity}"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-daily-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-daily-log" "🚨 $incident_content" --tags="oncall,incident${severity:+,$severity}"
        elif command -v addInfoToDailyLog &>/dev/null || type addInfoToDailyLog &>/dev/null 2>/dev/null; then
          addInfoToDailyLog "🚨 $incident_content (oncall,incident${severity:+,$severity})"
        else
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
            gtd-task add "Post-mortem: $incident_title #oncall #post-mortem #$severity" --non-interactive --context=computer --energy=high --priority=urgent_important 2>/dev/null || true
            echo ""
            echo -e "${YELLOW}📝 Post-mortem task created (P0/P1 incidents require post-mortems)${NC}"
          fi
        fi
        
        echo ""
        echo -e "${GREEN}✓ Incident logged and saved to: $incident_file${NC}"
        echo -e "${GRAY}  You can update this incident later using option 5) Update incident${NC}"
        ;;
      5)
        # Update existing incident
        clear
        echo ""
        echo -e "${BOLD}${RED}📝 Update Incident${NC}"
        echo ""
        
        local active_incidents=$(list_active_incidents)
        if [[ -z "$active_incidents" ]]; then
          echo "No active incidents found."
          echo ""
          gtd_quick_pause
          continue
        fi
        
        echo "Active incidents:"
        echo ""
        local count=1
        local incident_files=()
        while IFS='|' read -r file title; do
          if [[ -n "$file" && -n "$title" ]]; then
            echo "  $count) $title"
            incident_files+=("$file")
            count=$((count + 1))
          fi
        done <<< "$active_incidents"
        echo ""
        echo -n "Select incident to update (1-$((count-1))): "
        read incident_choice
        
        if [[ ! "$incident_choice" =~ ^[0-9]+$ ]] || [[ "$incident_choice" -lt 1 ]] || [[ "$incident_choice" -ge "$count" ]]; then
          echo "❌ Invalid selection"
          echo ""
          gtd_quick_pause
          continue
        fi
        
        local selected_file="${incident_files[$((incident_choice - 1))]}"
        if [[ ! -f "$selected_file" ]]; then
          echo "❌ Incident file not found"
          echo ""
          gtd_quick_pause
          continue
        fi
        
        echo ""
        echo "What would you like to add?"
        echo "  1) Status update"
        echo "  2) Additional notes"
        echo "  3) Resolution notes"
        echo ""
        echo -n "Choose: "
        read update_type
        
        case "$update_type" in
          1)
            echo ""
            echo "New status:"
            echo "  1) Active"
            echo "  2) Investigating"
            echo "  3) Resolved"
            echo "  4) Monitoring"
            echo ""
            echo -n "Choose: "
            read status_choice
            local new_status=""
            case "$status_choice" in
              1) new_status="active" ;;
              2) new_status="investigating" ;;
              3) new_status="resolved" ;;
              4) new_status="monitoring" ;;
            esac
            
            if [[ -n "$new_status" ]]; then
              # Update frontmatter status (macOS compatible)
              if grep -q "^status:" "$selected_file" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i '' "s/^status:.*/status: $new_status/" "$selected_file"
                else
                  sed -i "s/^status:.*/status: $new_status/" "$selected_file"
                fi
              fi
              
              # Add to updates section
              local update_text="$(date +"%Y-%m-%d %H:%M:%S") - Status changed to: $new_status"
              if grep -q "^## Updates" "$selected_file"; then
                # Use a temporary file for safer editing
                local temp_file=$(mktemp)
                local in_updates=false
                while IFS= read -r line; do
                  echo "$line" >> "$temp_file"
                  if [[ "$line" == "## Updates" ]]; then
                    in_updates=true
                    echo "" >> "$temp_file"
                    echo "$update_text" >> "$temp_file"
                  fi
                done < "$selected_file"
                mv "$temp_file" "$selected_file"
              else
                # Add Updates section if it doesn't exist
                echo "" >> "$selected_file"
                echo "## Updates" >> "$selected_file"
                echo "" >> "$selected_file"
                echo "$update_text" >> "$selected_file"
              fi
              
              echo ""
              echo -e "${GREEN}✓ Status updated to: $new_status${NC}"
            fi
            ;;
          2)
            echo ""
            echo -n "Enter additional notes: "
            read additional_notes
            if [[ -n "$additional_notes" ]]; then
              local update_text="$(date +"%Y-%m-%d %H:%M:%S") - $additional_notes"
              if grep -q "^## Updates" "$selected_file"; then
                # Use a temporary file for safer editing
                local temp_file=$(mktemp)
                local in_updates=false
                while IFS= read -r line; do
                  echo "$line" >> "$temp_file"
                  if [[ "$line" == "## Updates" ]]; then
                    in_updates=true
                    echo "" >> "$temp_file"
                    echo "$update_text" >> "$temp_file"
                  fi
                done < "$selected_file"
                mv "$temp_file" "$selected_file"
              else
                # Add Updates section if it doesn't exist
                echo "" >> "$selected_file"
                echo "## Updates" >> "$selected_file"
                echo "" >> "$selected_file"
                echo "$update_text" >> "$selected_file"
              fi
              
              echo ""
              echo -e "${GREEN}✓ Notes added to incident${NC}"
            fi
            ;;
          3)
            echo ""
            echo -n "Enter resolution notes: "
            read resolution_notes
            if [[ -n "$resolution_notes" ]]; then
              # Update status to resolved (macOS compatible)
              if grep -q "^status:" "$selected_file" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i '' "s/^status:.*/status: resolved/" "$selected_file"
                else
                  sed -i "s/^status:.*/status: resolved/" "$selected_file"
                fi
              fi
              
              # Add resolution section
              if grep -q "^## Resolution" "$selected_file"; then
                # Replace resolution section
                local temp_file=$(mktemp)
                local in_resolution=false
                while IFS= read -r line; do
                  if [[ "$line" == "## Resolution" ]]; then
                    in_resolution=true
                    echo "## Resolution" >> "$temp_file"
                    echo "" >> "$temp_file"
                    echo "**Resolved:** $(date +"%Y-%m-%d %H:%M:%S")" >> "$temp_file"
                    echo "" >> "$temp_file"
                    echo "$resolution_notes" >> "$temp_file"
                  elif [[ "$in_resolution" == "true" ]] && [[ "$line" =~ ^## ]]; then
                    # Next section found, stop replacing
                    in_resolution=false
                    echo "$line" >> "$temp_file"
                  elif [[ "$in_resolution" != "true" ]]; then
                    echo "$line" >> "$temp_file"
                  fi
                done < "$selected_file"
                mv "$temp_file" "$selected_file"
              else
                echo "" >> "$selected_file"
                echo "## Resolution" >> "$selected_file"
                echo "" >> "$selected_file"
                echo "**Resolved:** $(date +"%Y-%m-%d %H:%M:%S")" >> "$selected_file"
                echo "" >> "$selected_file"
                echo "$resolution_notes" >> "$selected_file"
              fi
              
              # Add to updates
              local update_text="$(date +"%Y-%m-%d %H:%M:%S") - Incident resolved: $resolution_notes"
              if grep -q "^## Updates" "$selected_file"; then
                local temp_file=$(mktemp)
                local in_updates=false
                while IFS= read -r line; do
                  echo "$line" >> "$temp_file"
                  if [[ "$line" == "## Updates" ]]; then
                    in_updates=true
                    echo "" >> "$temp_file"
                    echo "$update_text" >> "$temp_file"
                  fi
                done < "$selected_file"
                mv "$temp_file" "$selected_file"
              fi
              
              echo ""
              echo -e "${GREEN}✓ Incident marked as resolved${NC}"
            fi
            ;;
          *)
            echo "❌ Invalid choice"
            ;;
        esac
        ;;
      6)
        # View active incidents
        clear
        echo ""
        echo -e "${BOLD}${RED}🚨 Active Incidents${NC}"
        echo ""
        
        local active_incidents=$(list_active_incidents)
        if [[ -z "$active_incidents" ]]; then
          echo "No active incidents found."
          echo ""
          gtd_quick_pause
          continue
        fi
        
        local count=1
        while IFS='|' read -r file title; do
          if [[ -n "$file" && -n "$title" ]]; then
            echo -e "${BOLD}$count. $title${NC}"
            if [[ -f "$file" ]]; then
              local severity=$(grep -i "^severity:" "$file" 2>/dev/null | head -1 | sed 's/.*severity:[[:space:]]*//i' || echo "")
              local status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*status:[[:space:]]*//i' || echo "")
              local created=$(grep -i "^created:" "$file" 2>/dev/null | head -1 | sed 's/.*created:[[:space:]]*//i' || echo "")
              
              echo "   File: $file"
              [[ -n "$severity" ]] && echo "   Severity: $severity"
              [[ -n "$status" ]] && echo "   Status: $status"
              [[ -n "$created" ]] && echo "   Created: $created"
            fi
            echo ""
            count=$((count + 1))
          fi
        done <<< "$active_incidents"
        
        echo ""
        gtd_quick_pause
        ;;
      7)
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
    gtd_quick_pause
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
              gtd-task add "Post-mortem: $pm_title #oncall #post-mortem" --non-interactive --context=computer --energy=high --priority=urgent_important 2>/dev/null || true
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
      8)
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
    gtd_quick_pause
          continue
        fi
        
        echo ""
        echo -n "What needs to be updated? "
        read update_details
        
        local runbook_content="Update runbook: $runbook_name"
        if [[ -n "$update_details" ]]; then
          runbook_content="$runbook_content - $update_details"
        fi
        
        # Create task (non-interactive to avoid delays)
        if command -v gtd-task &>/dev/null; then
          gtd-task add "$runbook_content" --non-interactive --context=computer --energy=medium --priority=not_urgent_important 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ Runbook update task created${NC}"
          echo -e "${GRAY}  (Area: Work & Career, Tags: oncall,runbook,documentation)${NC}"
        else
          gtd-capture --type=task "$runbook_content #oncall #runbook #documentation"
          echo ""
          echo -e "${GREEN}✓ Runbook update captured${NC}"
        fi
        ;;
      9)
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
    gtd_quick_pause
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
          gtd-task add "$alert_content #oncall #alert-tuning #monitoring" --non-interactive --context=computer --energy=medium --priority=not_urgent_important 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ Alert tuning task created${NC}"
        else
          gtd-capture --type=task "$alert_content #oncall #alert-tuning #monitoring"
          echo ""
          echo -e "${GREEN}✓ Alert tuning captured${NC}"
        fi
        ;;
      10)
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
    gtd_quick_pause
          continue
        fi
        
        # Create task with oncall tag
        if command -v gtd-task &>/dev/null; then
          gtd-task add "$task_content #oncall" --non-interactive --context=computer --energy=medium --priority=not_urgent_important 2>/dev/null || true
          echo ""
          echo -e "${GREEN}✓ Oncall task created${NC}"
        else
          gtd-capture --type=task "$task_content #oncall"
          echo ""
          echo -e "${GREEN}✓ Oncall task captured${NC}"
        fi
        ;;
      11)
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
    gtd_quick_pause
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
      12)
        # Handoff report
        generate_handoff_report
        ;;
      *)
        echo "❌ Invalid choice"
        echo ""
        gtd_quick_pause
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
    gtd_print_header "Capture Wizard" "📥"
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
      gtd_quick_pause
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
    gtd_print_header "Process Inbox Wizard" "📋"
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
        gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
  echo "  1) Yes, get feedback from a random persona (background)"
  echo "  2) Yes, choose a specific persona (background)"
  echo "  3) No, skip feedback"
  echo ""
  echo -n "Choose: "
  read feedback_choice
  
  # Source wizard tools to get queue_advice_request function
  WIZARD_TOOLS="$HOME/code/dotfiles/bin/gtd-wizard-tools.sh"
  if [[ ! -f "$WIZARD_TOOLS" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-tools.sh" ]]; then
    WIZARD_TOOLS="$HOME/code/personal/dotfiles/bin/gtd-wizard-tools.sh"
  fi
  if [[ -f "$WIZARD_TOOLS" ]]; then
    source "$WIZARD_TOOLS"
  fi
  
  # Source select helper to get select_persona function
  SELECT_HELPER="$HOME/code/dotfiles/bin/gtd-select-helper.sh"
  if [[ ! -f "$SELECT_HELPER" && -f "$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh" ]]; then
    SELECT_HELPER="$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh"
  fi
  if [[ -f "$SELECT_HELPER" ]]; then
    source "$SELECT_HELPER"
  fi
  
  case "$feedback_choice" in
    1)
      echo ""
      echo -e "${CYAN}📤 Queuing feedback request for background processing...${NC}"
      
      # Queue request for background processing
      if declare -f queue_advice_request &>/dev/null; then
        local request_id=$(queue_advice_request "random" "I just logged this: $log_entry. What are your thoughts?" "random" "false")
        echo -e "${GREEN}✓ Request queued (ID: $request_id)${NC}"
        echo ""
        echo "💡 You'll receive a Discord notification when the feedback is ready."
        echo "   Review results: gtd-wizard → 11) Get Advice → 6) Review Background Advice Results"
        echo ""
        
        # Start worker if not running
        if ! pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1 && ! pgrep -f "gtd_advice_worker.py" >/dev/null 2>&1; then
          echo "Starting advice worker..."
          if command -v gtd-advice-worker &>/dev/null; then
            nohup gtd-advice-worker daemon >/tmp/advice-worker.log 2>&1 &
            echo "✓ Worker started (PID: $!)"
            echo "   Logs: tail -f /tmp/advice-worker.log"
            echo ""
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-advice-worker" ]]; then
            nohup "$HOME/code/dotfiles/bin/gtd-advice-worker" daemon >/tmp/advice-worker.log 2>&1 &
            echo "✓ Worker started (PID: $!)"
            echo "   Logs: tail -f /tmp/advice-worker.log"
            echo ""
          fi
        fi
      else
        echo "⚠️  queue_advice_request function not found. Skipping feedback."
      fi
      ;;
    2)
      echo ""
      persona=$(select_persona)
      if [[ -n "$persona" ]]; then
        echo ""
        echo -e "${CYAN}📤 Queuing feedback request for background processing...${NC}"
        
        # Queue request for background processing
        if declare -f queue_advice_request &>/dev/null; then
          local request_id=$(queue_advice_request "$persona" "I just logged this: $log_entry. What are your thoughts?" "normal" "false")
          echo -e "${GREEN}✓ Request queued (ID: $request_id)${NC}"
          echo ""
          echo "💡 You'll receive a Discord notification when the feedback is ready."
          echo "   Review results: gtd-wizard → 11) Get Advice → 6) Review Background Advice Results"
          echo ""
          
          # Start worker if not running
          if ! pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1 && ! pgrep -f "gtd_advice_worker.py" >/dev/null 2>&1; then
            echo "Starting advice worker..."
            if command -v gtd-advice-worker &>/dev/null; then
              nohup gtd-advice-worker daemon >/tmp/advice-worker.log 2>&1 &
              echo "✓ Worker started (PID: $!)"
              echo "   Logs: tail -f /tmp/advice-worker.log"
              echo ""
            elif [[ -f "$HOME/code/dotfiles/bin/gtd-advice-worker" ]]; then
              nohup "$HOME/code/dotfiles/bin/gtd-advice-worker" daemon >/tmp/advice-worker.log 2>&1 &
              echo "✓ Worker started (PID: $!)"
              echo "   Logs: tail -f /tmp/advice-worker.log"
              echo ""
            fi
          fi
        else
          echo "⚠️  queue_advice_request function not found. Skipping feedback."
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
  gtd_quick_pause
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
  
  # Check for pending review analysis results
  RESULTS_DIR="${HOME}/Documents/gtd/deep_analysis_results"
  local morning_results=0
  local evening_results=0
  
  if [[ -d "$RESULTS_DIR" ]]; then
    morning_results=$(find "$RESULTS_DIR" -name "morning_review_*.json" -type f -mtime -1 2>/dev/null | wc -l | tr -d ' ')
    evening_results=$(find "$RESULTS_DIR" -name "evening_review_*.json" -type f -mtime -1 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  if [[ "$morning_results" -gt 0 ]] || [[ "$evening_results" -gt 0 ]]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💡 Review Analysis Status${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ "$morning_results" -gt 0 ]]; then
      echo -e "${GREEN}  ✓ $morning_results morning review result(s) available${NC}"
    fi
    if [[ "$evening_results" -gt 0 ]]; then
      echo -e "${GREEN}  ✓ $evening_results evening review result(s) available${NC}"
    fi
    echo ""
  fi
  
  echo "What type of check-in?"
  echo ""
  echo "  1) 🌅 Morning Check-In"
  echo "  2) 🌙 Evening Check-In"
  if [[ "$morning_results" -gt 0 ]] || [[ "$evening_results" -gt 0 ]]; then
    echo "  3) 📋 Review Background Analysis Results"
  fi
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
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📋 Review Background Analysis Results${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      RESULTS_DIR="${HOME}/Documents/gtd/deep_analysis_results"
      if [[ ! -d "$RESULTS_DIR" ]]; then
        echo "No analysis results directory found."
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Find morning and evening review results
      local morning_results=()
      local evening_results=()
      
      while IFS= read -r result_file; do
        [[ -f "$result_file" ]] && morning_results+=("$result_file")
      done < <(find "$RESULTS_DIR" -name "morning_review_*.json" -type f -exec ls -t {} + 2>/dev/null | head -10)
      
      while IFS= read -r result_file; do
        [[ -f "$result_file" ]] && evening_results+=("$result_file")
      done < <(find "$RESULTS_DIR" -name "evening_review_*.json" -type f -exec ls -t {} + 2>/dev/null | head -10)
      
      if [[ ${#morning_results[@]} -eq 0 ]] && [[ ${#evening_results[@]} -eq 0 ]]; then
        echo "No morning or evening review results found."
        echo ""
        echo "Results are stored in: $RESULTS_DIR"
        echo ""
        echo "💡 Tip: Analysis is automatically queued when you complete a check-in!"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Display results
      echo "Available review analysis results:"
      echo ""
      
      local all_results=()
      local i=1
      
      # Add morning results
      for result_file in "${morning_results[@]}"; do
        local result_id=$(basename "$result_file" .json)
        local timestamp=$(echo "$result_id" | grep -oE '[0-9]{8}_[0-9]{6}' || echo "")
        local date_display="${timestamp:0:4}-${timestamp:4:2}-${timestamp:6:2} ${timestamp:9:2}:${timestamp:11:2}:${timestamp:13:2}"
        echo -e "  ${i}) [${CYAN}Morning${NC}] ${date_display}"
        all_results+=("$result_file")
        i=$((i + 1))
      done
      
      # Add evening results
      for result_file in "${evening_results[@]}"; do
        local result_id=$(basename "$result_file" .json)
        local timestamp=$(echo "$result_id" | grep -oE '[0-9]{8}_[0-9]{6}' || echo "")
        local date_display="${timestamp:0:4}-${timestamp:4:2}-${timestamp:6:2} ${timestamp:9:2}:${timestamp:11:2}:${timestamp:13:2}"
        echo -e "  ${i}) [${MAGENTA}Evening${NC}] ${date_display}"
        all_results+=("$result_file")
        i=$((i + 1))
      done
      
      echo ""
      echo -n "Select result to view (number) or 0 to go back: "
      read selection
      
      if [[ "$selection" == "0" ]] || [[ -z "$selection" ]]; then
        return 0
      fi
      
      # Validate selection
      if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#all_results[@]} ]]; then
        echo "Invalid selection"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Get selected result
      local selected_file="${all_results[$((selection - 1))]}"
      local result_type="Morning"
      [[ "$selected_file" =~ evening_review ]] && result_type="Evening"
      
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📋 ${result_type} Review Analysis${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Display result using Python to parse JSON
      python3 <<PYTHON_EOF
import json
import sys

try:
    with open("$selected_file", "r") as f:
        result = json.load(f)
    
    # Display key fields
    if "timestamp" in result:
        print(f"Timestamp: {result['timestamp']}")
    print("")
    
    # Display analysis content
    if "analysis" in result:
        print("Analysis:")
        print(result["analysis"])
        print("")
    elif "insights" in result:
        print("Insights:")
        if isinstance(result["insights"], list):
            for insight in result["insights"]:
                print(f"  • {insight}")
        else:
            print(result["insights"])
        print("")
    elif "summary" in result:
        print("Summary:")
        print(result["summary"])
        print("")
    elif "error" in result:
        print(f"Error: {result['error']}")
        print("")
    else:
        # Display full JSON if structure is unknown
        print(json.dumps(result, indent=2))
    
    # Display suggestions if present
    if "suggestions" in result and result["suggestions"]:
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("Suggestions:")
        if isinstance(result["suggestions"], list):
            for suggestion in result["suggestions"]:
                if isinstance(suggestion, dict):
                    print(f"  • {suggestion.get('title', suggestion.get('text', str(suggestion)))}")
                else:
                    print(f"  • {suggestion}")
        else:
            print(result["suggestions"])
        print("")
        
except Exception as e:
    print(f"Error reading result file: {e}")
PYTHON_EOF
      
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      gtd_quick_pause
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
    gtd_quick_pause
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
    gtd_quick_pause
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
    gtd_quick_pause
}

