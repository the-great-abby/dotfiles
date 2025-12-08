#!/bin/bash
# Enhanced Review System Wizard
# Provides progressive review depths, templates, comparison views, and review summaries

# Source common environment
COMMON_ENV="$HOME/code/dotfiles/zsh/common_env.sh"
if [[ ! -f "$COMMON_ENV" && -f "$HOME/code/personal/dotfiles/zsh/common_env.sh" ]]; then
  COMMON_ENV="$HOME/code/personal/dotfiles/zsh/common_env.sh"
fi
if [[ -f "$COMMON_ENV" ]]; then
  source "$COMMON_ENV"
fi

# Load GTD config
GTD_CONFIG_FILE="$HOME/.gtd_config"
if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
  GTD_CONFIG_FILE="$HOME/code/personal/dotfiles/zsh/.gtd_config"
fi
if [[ -f "$GTD_CONFIG_FILE" ]]; then
  source "$GTD_CONFIG_FILE"
fi

# Default values
GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
SECOND_BRAIN="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
REVIEW_SUMMARIES_DIR="${GTD_BASE_DIR}/review-summaries"
mkdir -p "$REVIEW_SUMMARIES_DIR"

TODAY=$(date +"%Y-%m-%d")
NOW=$(date +"%Y-%m-%d %H:%M")

# Helper to get date by offset
get_date_by_offset() {
  local offset="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    date -v${offset}d +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
  else
    date -d "${offset} days" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
  fi
}

# Enhanced Review Wizard
enhanced_review_wizard() {
  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📊 Enhanced Review System${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Progressive Review Depths:${NC}"
    echo "  • Quick Daily: 5-10 min surface-level check"
    echo "  • Medium Weekly: 30-60 min comprehensive review"
    echo "  • Deep Monthly: 2-3 hour strategic review"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) 🚀 Quick Daily Review (5-10 min)"
    echo "  2) 📅 Medium Weekly Review (30-60 min)"
    echo "  3) 🎯 Deep Monthly Review (2-3 hours)"
    echo "  4) 📊 Comparison View (This week vs last week)"
    echo "  5) 📝 Review Templates (Project/Energy/Goal reviews)"
    echo "  6) 💬 View Review Summaries"
    echo "  7) 📋 Save Review Conversation Summary"
    echo "  8) ⚙️  Configure Review Settings"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read choice
    
    case "$choice" in
      1)
        quick_daily_review
        ;;
      2)
        medium_weekly_review
        ;;
      3)
        deep_monthly_review
        ;;
      4)
        comparison_view
        ;;
      5)
        review_templates_menu
        ;;
      6)
        view_review_summaries
        ;;
      7)
        save_review_summary
        ;;
      8)
        configure_review_settings
        ;;
      0|"")
        return 0
        ;;
      *)
        echo "Invalid choice"
        sleep 1
        ;;
    esac
  done
}

# Quick Daily Review (5-10 min)
quick_daily_review() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🚀 Quick Daily Review${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Quick status checks
  local inbox_count=$(find "${GTD_BASE_DIR}/0-inbox" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  local active_tasks=$(find "${GTD_BASE_DIR}/tasks" -type f -name "*.md" 2>/dev/null | grep -l "^status: active" 2>/dev/null | wc -l | tr -d ' ')
  local waiting_count=$(find "${GTD_BASE_DIR}/5-waiting-for" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  
  echo -e "${BOLD}Quick Status Check:${NC}"
  echo ""
  echo "  📥 Inbox: $inbox_count items"
  echo "  ✓ Active Tasks: $active_tasks"
  echo "  ⏳ Waiting For: $waiting_count items"
  echo ""
  
  if [[ $inbox_count -gt 5 ]]; then
    echo -e "${YELLOW}⚠️  Inbox has $inbox_count items - consider processing${NC}"
  fi
  
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "${CYAN}💡 You have $waiting_count waiting items - follow up?${NC}"
  fi
  
  echo ""
  echo "Quick Actions:"
  echo "  1) Process inbox (if needed)"
  echo "  2) Review today's priorities"
  echo "  3) Check waiting items"
  echo "  4) Skip to main review"
  echo ""
  echo -n "Choose (1-4, default 4): "
  read quick_action
  
  case "$quick_action" in
    1)
      gtd-process
      ;;
    2)
      echo ""
      echo "Today's Priorities:"
      if command -v gtd-task &>/dev/null; then
        gtd-task list --priority=urgent_important | head -10
      fi
      ;;
    3)
      echo ""
      echo "Waiting Items:"
      if command -v gtd-task &>/dev/null; then
        gtd-task list --waiting | head -10
      fi
      ;;
  esac
  
  echo ""
  echo "✓ Quick review complete!"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Medium Weekly Review (30-60 min)
medium_weekly_review() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📅 Medium Weekly Review${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "Starting comprehensive weekly review..."
  echo ""
  echo "This review includes:"
  echo "  • Processing all inbox items"
  echo "  • Reviewing active projects"
  echo "  • Checking waiting items"
  echo "  • Reviewing weekly goals"
  echo "  • Planning next week"
  echo ""
  
  # Run standard weekly review
  if command -v gtd-review &>/dev/null; then
    gtd-review weekly
  else
    echo "Running manual weekly review steps..."
    echo ""
    
    # Process inbox
    echo "1. Processing inbox..."
    gtd-process
    echo ""
    
    # Review projects
    echo "2. Reviewing active projects..."
    if command -v gtd-project &>/dev/null; then
      gtd-project list
    fi
    echo ""
    
    # Review waiting
    echo "3. Reviewing waiting items..."
    if command -v gtd-task &>/dev/null; then
      gtd-task list --waiting
    fi
  fi
  
  echo ""
  echo "✓ Weekly review complete!"
  echo ""
  echo "Would you like to save a summary of this review? (y/n): "
  read save_summary
  if [[ "$save_summary" == "y" || "$save_summary" == "Y" ]]; then
    save_review_summary "weekly" "Medium Weekly Review"
  fi
  
  echo ""
  echo "Press Enter to continue..."
  read
}

# Deep Monthly Review (2-3 hours)
deep_monthly_review() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 Deep Monthly Review${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "This is a comprehensive strategic review (2-3 hours)"
  echo ""
  echo "Review sections:"
  echo "  1) Archive completed projects"
  echo "  2) Review all active projects & areas"
  echo "  3) Strategic goal assessment"
  echo "  4) System health check"
  echo "  5) Monthly metrics & patterns"
  echo "  6) Plan for next month"
  echo ""
  
  echo -n "Ready to begin? (y/n): "
  read begin
  if [[ "$begin" != "y" && "$begin" != "Y" ]]; then
    return 0
  fi
  
  echo ""
  echo "Starting deep monthly review..."
  echo ""
  
  # Run monthly review
  if command -v gtd-review &>/dev/null; then
    gtd-review monthly
  else
    echo "Running manual monthly review steps..."
    
    # Archive completed
    echo "1. Archiving completed projects..."
    # Implementation would archive completed items
    
    # Review all projects
    echo "2. Reviewing all active projects..."
    if command -v gtd-project &>/dev/null; then
      gtd-project list --all
    fi
    
    # Review areas
    echo "3. Reviewing areas..."
    if command -v gtd-area &>/dev/null; then
      gtd-area list
    fi
  fi
  
  echo ""
  echo "✓ Deep monthly review complete!"
  echo ""
  echo "Would you like to save a summary? (y/n): "
  read save_summary
  if [[ "$save_summary" == "y" || "$save_summary" == "Y" ]]; then
    save_review_summary "monthly" "Deep Monthly Review"
  fi
  
  echo ""
  echo "Press Enter to continue..."
  read
}

# Comparison View: This week vs last week
comparison_view() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Comparison View: This Week vs Last Week${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local this_week_start=$(get_date_by_offset -7)
  local last_week_start=$(get_date_by_offset -14)
  
  echo -e "${BOLD}Comparison Period:${NC}"
  echo "  This Week: $this_week_start to $TODAY"
  echo "  Last Week: $last_week_start to $(get_date_by_offset -8)"
  echo ""
  
  # Get task counts (simplified - would need actual tracking)
  echo -e "${BOLD}Task Comparison:${NC}"
  echo ""
  echo "  This Week:"
  echo "    • Completed: (tracking needed)"
  echo "    • Created: (tracking needed)"
  echo ""
  echo "  Last Week:"
  echo "    • Completed: (tracking needed)"
  echo "    • Created: (tracking needed)"
  echo ""
  
  # Project comparison
  echo -e "${BOLD}Project Progress:${NC}"
  echo ""
  echo "  This Week:"
  if command -v gtd-project &>/dev/null; then
    local active_projects=$(gtd-project list 2>/dev/null | grep -c "active" || echo "0")
    echo "    • Active Projects: $active_projects"
  fi
  echo ""
  
  echo "💡 Tip: Enhanced tracking can be added to show detailed comparisons"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Review Templates Menu
review_templates_menu() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📝 Review Templates${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Choose a review template:"
  echo ""
  echo "  1) 📋 Project Review Template"
  echo "  2) ⚡ Energy Review Template"
  echo "  3) 🎯 Goal Review Template"
  echo "  4) 📊 Area Review Template"
  echo "  5) 🔄 Habit Review Template"
  echo ""
  echo -e "${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read template_choice
  
  case "$template_choice" in
    1)
      project_review_template
      ;;
    2)
      energy_review_template
      ;;
    3)
      goal_review_template
      ;;
    4)
      area_review_template
      ;;
    5)
      habit_review_template
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      sleep 1
      ;;
  esac
}

# Project Review Template
project_review_template() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📋 Project Review Template${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo -n "Enter project name (or press Enter to list all): "
  read project_name
  
  if [[ -z "$project_name" ]]; then
    echo ""
    echo "Available projects:"
    if command -v gtd-project &>/dev/null; then
      gtd-project list | head -20
    fi
    echo ""
    echo -n "Enter project name to review: "
    read project_name
  fi
  
  if [[ -z "$project_name" ]]; then
    echo "No project specified"
    echo ""
    echo "Press Enter to continue..."
    read
    return 0
  fi
  
  echo ""
  echo -e "${BOLD}Project Review: $project_name${NC}"
  echo ""
  echo "Questions to answer:"
  echo ""
  echo "1. What progress was made this week/month?"
  echo "2. What obstacles are blocking progress?"
  echo "3. What are the next actions?"
  echo "4. Is the project still relevant? (Should it continue?)"
  echo "5. Does the outcome/definition of done need updating?"
  echo ""
  echo "💡 Use these questions as a guide for your review"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Energy Review Template
energy_review_template() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚡ Energy Review Template${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo -e "${BOLD}Energy Review Questions:${NC}"
  echo ""
  echo "1. What activities gave you energy this week?"
  echo "2. What activities drained your energy?"
  echo "3. What patterns do you notice in your energy levels?"
  echo "4. How can you optimize your schedule for better energy?"
  echo "5. What commitments should you adjust based on energy?"
  echo ""
  echo "💡 Tip: Schedule high-energy tasks during your peak times"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Goal Review Template
goal_review_template() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 Goal Review Template${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo -e "${BOLD}Goal Review Questions:${NC}"
  echo ""
  echo "1. What progress have you made toward your goals?"
  echo "2. Are your goals still relevant and aligned with your vision?"
  echo "3. What obstacles are preventing progress?"
  echo "4. What actions will you take this week/month?"
  echo "5. Do any goals need to be modified or replaced?"
  echo ""
  echo "💡 Use this template for weekly/monthly goal check-ins"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Area Review Template
area_review_template() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Area Review Template${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo -e "${BOLD}Area Review Questions:${NC}"
  echo ""
  echo "1. Is this area being maintained at the desired standard?"
  echo "2. What projects relate to this area?"
  echo "3. What actions are needed to maintain/improve this area?"
  echo "4. Are there any issues or concerns in this area?"
  echo "5. What improvements could be made?"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Habit Review Template
habit_review_template() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔄 Habit Review Template${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo -e "${BOLD}Habit Review Questions:${NC}"
  echo ""
  echo "1. Which habits are you maintaining consistently?"
  echo "2. Which habits need improvement?"
  echo "3. What triggers or obstacles affect your habits?"
  echo "4. What new habits should you consider?"
  echo "5. Which habits are no longer serving you?"
  echo ""
  echo "Press Enter to continue..."
  read
}

# View Review Summaries
view_review_summaries() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💬 Review Summaries${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if [[ ! -d "$REVIEW_SUMMARIES_DIR" ]] || [[ -z "$(ls -A "$REVIEW_SUMMARIES_DIR" 2>/dev/null)" ]]; then
    echo "No review summaries found."
    echo ""
    echo "Summaries are saved to: $REVIEW_SUMMARIES_DIR"
    echo ""
    echo "Press Enter to continue..."
    read
    return 0
  fi
  
  echo "Recent review summaries:"
  echo ""
  
  local summaries=($(find "$REVIEW_SUMMARIES_DIR" -type f -name "*.md" 2>/dev/null | sort -r | head -10))
  
  if [[ ${#summaries[@]} -eq 0 ]]; then
    echo "No summaries found."
  else
    local count=1
    for summary in "${summaries[@]}"; do
      local basename=$(basename "$summary" .md)
      echo "  $count) $basename"
      ((count++))
    done
    
    echo ""
    echo -n "Enter number to view (or press Enter to go back): "
    read summary_choice
    
    if [[ "$summary_choice" =~ ^[0-9]+$ ]] && [[ "$summary_choice" -ge 1 ]] && [[ "$summary_choice" -le ${#summaries[@]} ]]; then
      local selected_summary="${summaries[$((summary_choice-1))]}"
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}$(basename "$selected_summary" .md)${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      cat "$selected_summary" 2>/dev/null || echo "Error reading summary"
      echo ""
      echo "Press Enter to continue..."
      read
    fi
  fi
}

# Save Review Summary
save_review_summary() {
  local review_type="${1:-general}"
  local review_title="${2:-Review Summary}"
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📋 Save Review Summary${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if [[ -n "$review_title" && "$review_title" != "Review Summary" ]]; then
    echo "Saving: $review_title"
    echo ""
  else
    echo -n "Enter review title (or press Enter for default): "
    read custom_title
    review_title="${custom_title:-$review_title}"
  fi
  
  echo ""
  echo "Enter your review summary (press Ctrl+D when done, or type 'done' on a new line):"
  echo ""
  
  local temp_file=$(mktemp)
  local summary_content=""
  
  while IFS= read -r line; do
    if [[ "$line" == "done" ]]; then
      break
    fi
    summary_content+="$line"$'\n'
  done
  
  if [[ -z "$summary_content" ]]; then
    echo "No summary content provided."
    rm -f "$temp_file"
    echo ""
    echo "Press Enter to continue..."
    read
    return 0
  fi
  
  # Create summary file
  local safe_title=$(echo "$review_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g')
  local summary_file="${REVIEW_SUMMARIES_DIR}/${safe_title}-${TODAY}.md"
  
  cat > "$summary_file" <<EOF
# $review_title

Date: $TODAY $NOW
Type: $review_type

## Summary

$summary_content

---

*Generated by Enhanced Review System*
EOF
  
  echo ""
  echo "✓ Review summary saved: $summary_file"
  
  # Optionally save to Second Brain
  echo ""
  echo "Would you like to save this to Second Brain? (y/n): "
  read save_to_brain
  
  if [[ "$save_to_brain" == "y" || "$save_to_brain" == "Y" ]]; then
    if [[ -d "$SECOND_BRAIN" ]]; then
      local brain_file="${SECOND_BRAIN}/Reviews/${review_title}-${TODAY}.md"
      mkdir -p "${SECOND_BRAIN}/Reviews"
      cp "$summary_file" "$brain_file"
      echo "✓ Also saved to Second Brain: $brain_file"
    else
      echo "⚠️  Second Brain directory not found"
    fi
  fi
  
  rm -f "$temp_file"
  echo ""
  echo "Press Enter to continue..."
  read
}

# Configure Review Settings
configure_review_settings() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚙️  Review Settings${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "Review Settings Configuration:"
  echo ""
  echo "  1) Set default review reminders"
  echo "  2) Configure review templates"
  echo "  3) Set auto-save options"
  echo "  4) Configure comparison tracking"
  echo ""
  echo -e "${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read config_choice
  
  case "$config_choice" in
    1)
      echo ""
      echo "💡 Review reminders can be configured in your GTD config"
      echo "   See: ~/.gtd_config or zsh/.gtd_config"
      ;;
    2)
      echo ""
      echo "💡 Review templates are available in the templates menu"
      ;;
    3)
      echo ""
      echo "💡 Auto-save options can be configured here"
      echo "   (Feature to be implemented)"
      ;;
    4)
      echo ""
      echo "💡 Comparison tracking requires task/project tracking"
      echo "   (Feature to be implemented)"
      ;;
    0|"")
      return 0
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}
