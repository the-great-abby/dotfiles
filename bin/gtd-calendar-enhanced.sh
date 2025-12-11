#!/bin/bash
# Enhanced Calendar Features
# Provides calendar-aware planning, over-scheduling warnings, time-blocking suggestions, and energy optimization

# Load config first
GTD_CONFIG_FILE="$HOME/.gtd_config"
if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
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
GOOGLE_CALENDAR_NAME="${GTD_GOOGLE_CALENDAR_NAME:-GTD}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper: Get date by offset
get_date_by_offset() {
  local offset="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    date -v${offset}d +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
  else
    date -d "${offset} days" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
  fi
}

# Helper: Check if gcalcli is installed
check_gcalcli() {
  if command -v gcalcli &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Helper: Get Google Calendar events (simplified version)
get_google_events_simple() {
  local start_date="${1:-today}"
  local end_date="${2:-tomorrow}"
  local calendar="${3:-$GOOGLE_CALENDAR_NAME}"
  
  if ! check_gcalcli; then
    return 1
  fi
  
  # Normalize common date formats
  if [[ "$start_date" == "today" ]]; then
    start_date=$(date +"%Y-%m-%d")
  elif [[ "$start_date" == "tomorrow" ]]; then
    start_date=$(get_date_by_offset 1)
  fi
  
  if [[ "$end_date" == "today" ]]; then
    end_date=$(date +"%Y-%m-%d")
  elif [[ "$end_date" == "tomorrow" ]]; then
    end_date=$(get_date_by_offset 1)
  fi
  
  gcalcli --calendar "$calendar" agenda "$start_date" "$end_date" 2>/dev/null || echo ""
}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper: Get date by offset (must be defined before get_google_events_simple)
get_date_by_offset() {
  local offset="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    date -v${offset}d +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
  else
    date -d "${offset} days" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
  fi
}

# Count events for a specific date
count_events_for_date() {
  local target_date="$1"
  
  if ! check_gcalcli 2>/dev/null; then
    echo "0"
    return 1
  fi
  
  # Get events for that date
  local events
  events=$(get_google_events_simple "$target_date" "$target_date" "$GOOGLE_CALENDAR_NAME" 2>/dev/null)
  
  if [[ -z "$events" ]] || [[ "$events" == *"No Events Found"* ]]; then
    echo "0"
    return 0
  fi
  
  # Count lines that look like events (contain time patterns like "09:00" or "9am")
  local count=$(echo "$events" | grep -E "[0-9]{1,2}:[0-9]{2}|[0-9]{1,2}(am|pm)" | wc -l | tr -d ' ')
  echo "${count:-0}"
}

# Analyze calendar density for a date range
analyze_calendar_density() {
  local start_date="$1"
  local end_date="${2:-$start_date}"
  
  if ! check_gcalcli 2>/dev/null; then
    echo "Calendar not available"
    return 1
  fi
  
  # Parse dates
  local current_date="$start_date"
  local over_scheduled_days=()
  local total_events=0
  local day_count=0
  
  # Convert dates to timestamps for iteration
  local start_ts
  local end_ts
  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_ts=$(date -j -f "%Y-%m-%d" "$start_date" +%s 2>/dev/null || echo "0")
    end_ts=$(date -j -f "%Y-%m-%d" "$end_date" +%s 2>/dev/null || echo "0")
  else
    start_ts=$(date -d "$start_date" +%s 2>/dev/null || echo "0")
    end_ts=$(date -d "$end_date" +%s 2>/dev/null || echo "0")
  fi
  
  if [[ "$start_ts" == "0" || "$end_ts" == "0" ]]; then
    echo "Invalid date format"
    return 1
  fi
  
  local current_ts=$start_ts
  while [[ $current_ts -le $end_ts ]]; do
    if [[ "$OSTYPE" == "darwin"* ]]; then
      current_date=$(date -r $current_ts +"%Y-%m-%d" 2>/dev/null)
    else
      current_date=$(date -d "@$current_ts" +"%Y-%m-%d" 2>/dev/null)
    fi
    
    local event_count=$(count_events_for_date "$current_date")
    ((total_events += event_count))
    ((day_count++))
    
    # Consider 3+ events as over-scheduled, 5+ as very busy
    if [[ $event_count -ge 3 ]]; then
      over_scheduled_days+=("$current_date:$event_count")
    fi
    
    # Move to next day
    current_ts=$((current_ts + 86400))
  done
  
  # Output results
  echo "Calendar Density Analysis ($start_date to $end_date):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Total Events: $total_events"
  echo "  Days Analyzed: $day_count"
  echo "  Average Events/Day: $(( total_events / day_count ))"
  echo ""
  
  if [[ ${#over_scheduled_days[@]} -gt 0 ]]; then
    echo "⚠️  Over-Scheduled Days (3+ events):"
    for day_info in "${over_scheduled_days[@]}"; do
      local day="${day_info%%:*}"
      local count="${day_info##*:}"
      echo "    • $day: $count events"
    done
  else
    echo "✓ No over-scheduled days detected"
  fi
}

# Get upcoming events in context (for planning)
get_upcoming_events_context() {
  local days_ahead="${1:-7}"
  local end_date=$(get_date_by_offset $days_ahead)
  
  echo "📅 Upcoming Events (Next $days_ahead days)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if ! check_gcalcli 2>/dev/null; then
    echo "⚠️  Calendar not available (gcalcli not configured)"
    return 1
  fi
  
  local events
  events=$(get_google_events_simple "today" "$end_date" "$GOOGLE_CALENDAR_NAME" 2>/dev/null)
  
  if [[ -z "$events" ]] || [[ "$events" == *"No Events Found"* ]]; then
    echo "  No upcoming events"
    return 0
  fi
  
  echo "$events" | head -30 | sed 's/^/  /'
}

# Warn about over-scheduled days during task creation
check_over_scheduled_warning() {
  local target_date="${1:-tomorrow}"
  
  # Normalize date
  if [[ "$target_date" == "today" ]]; then
    target_date=$(date +"%Y-%m-%d")
  elif [[ "$target_date" == "tomorrow" ]]; then
    target_date=$(get_date_by_offset 1)
  fi
  
  local event_count=$(count_events_for_date "$target_date")
  
  if [[ $event_count -ge 3 ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Calendar Warning: $target_date has $event_count scheduled events${NC}"
    echo ""
    
    if [[ $event_count -ge 5 ]]; then
      echo -e "${RED}🚨 Very Busy Day Detected!${NC}"
      echo ""
      echo "   • Consider scheduling this task for a different day"
      echo "   • Or block time specifically for this task"
      echo "   • High-stress day - schedule recovery time if possible"
      echo ""
    elif [[ $event_count -ge 3 ]]; then
      echo -e "${YELLOW}   • You have $event_count meetings/events${NC}"
      echo -e "${YELLOW}   • Consider time-blocking this task${NC}"
      echo ""
    fi
    
    # Show events for context
    echo "Upcoming events on $target_date:"
    if check_gcalcli 2>/dev/null; then
      local events
      events=$(get_google_events_simple "$target_date" "$target_date" "$GOOGLE_CALENDAR_NAME" 2>/dev/null)
      if [[ -n "$events" ]] && [[ "$events" != *"No Events Found"* ]]; then
        echo "$events" | head -10 | sed 's/^/  /'
      fi
    fi
    echo ""
    
    return 0
  fi
  
  return 1
}

# Suggest time-blocking for tasks
suggest_time_blocking() {
  local task_title="$1"
  local target_date="${2:-tomorrow}"
  local duration_minutes="${3:-60}"
  
  # Normalize date
  if [[ "$target_date" == "today" ]]; then
    target_date=$(date +"%Y-%m-%d")
  elif [[ "$target_date" == "tomorrow" ]]; then
    target_date=$(get_date_by_offset 1)
  fi
  
  echo "⏰ Time-Blocking Suggestion for: $task_title"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if ! check_gcalcli 2>/dev/null; then
    echo "⚠️  Calendar not available for time-blocking suggestions"
    return 1
  fi
  
  # Get events for the day
  local events
  events=$(get_google_events_simple "$target_date" "$target_date" "$GOOGLE_CALENDAR_NAME" 2>/dev/null)
  
  if [[ -z "$events" ]] || [[ "$events" == *"No Events Found"* ]]; then
    echo "✓ Day is completely free!"
    echo ""
    echo "Suggested time blocks:"
    echo "  • Morning (9:00 AM - 11:00 AM) - High energy period"
    echo "  • Afternoon (2:00 PM - 4:00 PM) - Good for focused work"
    echo "  • Evening (7:00 PM - 9:00 PM) - If needed"
    echo ""
    return 0
  fi
  
  echo "Existing events on $target_date:"
  echo "$events" | head -20 | sed 's/^/  /'
  echo ""
  
  echo "💡 Time-Blocking Suggestions:"
  echo ""
  echo "  • Look for gaps between meetings (minimum $duration_minutes minutes)"
  echo "  • Consider blocking time before/after important meetings"
  echo "  • Schedule during your peak energy hours if possible"
  echo ""
  echo "Would you like to add this task to your calendar? (y/n): "
  read add_to_cal
  
  if [[ "$add_to_cal" == "y" || "$add_to_cal" == "Y" ]]; then
    echo ""
    echo -n "When? (e.g., '2024-12-05 10:00' or 'tomorrow 2pm'): "
    read when
    if [[ -n "$when" ]]; then
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar google add "$task_title" "$when" "$duration_minutes"
      fi
    fi
  fi
}

# Energy pattern → calendar optimization
optimize_calendar_for_energy() {
  local target_date="${1:-tomorrow}"
  
  # Normalize date
  if [[ "$target_date" == "today" ]]; then
    target_date=$(date +"%Y-%m-%d")
  elif [[ "$target_date" == "tomorrow" ]]; then
    target_date=$(get_date_by_offset 1)
  fi
  
  echo "⚡ Energy Pattern → Calendar Optimization"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if ! check_gcalcli 2>/dev/null; then
    echo "⚠️  Calendar not available"
    return 1
  fi
  
  # Count events
  local event_count=$(count_events_for_date "$target_date")
  
  # Get events
  local events
  events=$(get_google_events_simple "$target_date" "$target_date" "$GOOGLE_CALENDAR_NAME" 2>/dev/null)
  
  echo "Calendar Analysis for $target_date:"
  echo ""
  echo "  Events scheduled: $event_count"
  echo ""
  
  # Analyze event density
  if [[ $event_count -ge 3 ]]; then
    echo -e "${YELLOW}⚠️  High Meeting Density Detected${NC}"
    echo ""
    
    if [[ $event_count -ge 5 ]]; then
      echo -e "${RED}🚨 Very High Stress Day${NC}"
      echo ""
      echo "Recommendations:"
      echo "  • Schedule recovery time (lunch break, walk, buffer time)"
      echo "  • Block 15-30 min buffers between meetings"
      echo "  • Avoid scheduling additional high-energy tasks"
      echo "  • Plan for lower energy afternoon/evening"
      echo ""
      
      # Suggest recovery time blocks
      echo "💡 Suggested Recovery Time Blocks:"
      echo ""
      if [[ "$events" != *"12:"* ]] && [[ "$events" != *"noon"* ]] && [[ "$events" != *"lunch"* ]]; then
        echo "  • 12:00 PM - 1:00 PM: Lunch break (recovery time)"
      fi
      echo "  • Add 15-min buffers before/after key meetings"
      echo "  • End-of-day buffer (4:00 PM - 5:00 PM) for processing"
      echo ""
      
      echo "Would you like to add recovery time blocks? (y/n): "
      read add_recovery
      if [[ "$add_recovery" == "y" || "$add_recovery" == "Y" ]]; then
        echo ""
        echo "Adding recovery time block..."
        if command -v gtd-calendar &>/dev/null; then
          # Add lunch break if not present
          if [[ "$events" != *"12:"* ]] && [[ "$events" != *"noon"* ]] && [[ "$events" != *"lunch"* ]]; then
            gtd-calendar google add "Recovery Time / Lunch" "${target_date} 12:00" "60" "Buffer time between meetings"
          fi
          # Add end-of-day buffer
          gtd-calendar google add "End-of-Day Processing Buffer" "${target_date} 16:00" "30" "Time to process meeting notes and plan next steps"
        fi
        echo "✓ Recovery time blocks added"
      fi
    elif [[ $event_count -ge 3 ]]; then
      echo "Recommendations:"
      echo "  • Consider adding 15-min buffers between meetings"
      echo "  • Schedule focused work in gaps"
      echo "  • Plan for recovery time if meetings are back-to-back"
      echo ""
    fi
  else
    echo "✓ Moderate schedule - good balance"
    echo ""
    echo "Suggestions:"
    echo "  • Good opportunity for focused work"
    echo "  • Consider time-blocking important tasks"
    echo ""
  fi
  
  # Show events for context
  if [[ -n "$events" ]] && [[ "$events" != *"No Events Found"* ]]; then
    echo "Scheduled events:"
    echo "$events" | sed 's/^/  /'
    echo ""
  fi
}

# Get calendar insights for a date
get_calendar_insights() {
  local target_date="${1:-tomorrow}"
  
  # Normalize date
  if [[ "$target_date" == "today" ]]; then
    target_date=$(date +"%Y-%m-%d")
  elif [[ "$target_date" == "tomorrow" ]]; then
    target_date=$(get_date_by_offset 1)
  fi
  
  local event_count=$(count_events_for_date "$target_date")
  
  echo "📊 Calendar Insights for $target_date"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if [[ $event_count -eq 0 ]]; then
    echo "✓ Free day - good for focused work or planning"
    return 0
  fi
  
  echo "Events: $event_count"
  echo ""
  
  # Get event details
  if check_gcalcli 2>/dev/null; then
    local events
    events=$(get_google_events_simple "$target_date" "$target_date" "$GOOGLE_CALENDAR_NAME" 2>/dev/null)
    
    if [[ -n "$events" ]] && [[ "$events" != *"No Events Found"* ]]; then
      echo "Schedule:"
      echo "$events" | sed 's/^/  /'
      echo ""
      
      # Analyze pattern
      if [[ $event_count -ge 3 ]]; then
        echo "💡 Insights:"
        echo ""
        if [[ $event_count -ge 5 ]]; then
          echo -e "  ${RED}• Very busy day - high stress likely${NC}"
          echo "  • Schedule recovery time if possible"
          echo "  • Avoid adding complex tasks"
        else
          echo -e "  ${YELLOW}• Moderately busy day${NC}"
          echo "  • Time-block important tasks in gaps"
          echo "  • Consider adding buffers between meetings"
        fi
      fi
    fi
  fi
}
