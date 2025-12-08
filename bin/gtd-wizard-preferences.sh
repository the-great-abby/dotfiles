#!/bin/bash
# GTD Wizard Preferences Learning Functions

preferences_learning_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📚 Learning System Preferences${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "The system learns from your behavior to adapt to your preferences."
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) 📊 View learned preferences"
  echo "  2) 📚 Learn from existing tasks"
  echo "  3) 🎯 Set manual preference overrides"
  echo "  4) 🔄 Reset preferences (start fresh)"
  echo "  5) 📝 View preferences config file"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read pref_choice
  
  case "$pref_choice" in
    1)
      clear
      if command -v gtd-preferences-learn &>/dev/null; then
        gtd-preferences-learn show
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-preferences-learn" ]]; then
        "$HOME/code/dotfiles/bin/gtd-preferences-learn" show
      else
        echo "❌ gtd-preferences-learn command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    2)
      clear
      echo "Learning from existing tasks..."
      echo ""
      if command -v gtd-preferences-learn &>/dev/null; then
        gtd-preferences-learn learn
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-preferences-learn" ]]; then
        "$HOME/code/dotfiles/bin/gtd-preferences-learn" learn
      else
        echo "❌ gtd-preferences-learn command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}Manual Preference Overrides${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Edit preferences config file to override learned preferences:"
      echo ""
      echo "  $HOME/.gtd_preferences_config"
      echo ""
      echo "This file allows you to manually set preferences that override"
      echo "what the system learns from your behavior."
      echo ""
      read -p "Open in editor? (y/n): " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -n "$EDITOR" ]]; then
          $EDITOR "$HOME/.gtd_preferences_config"
        else
          ${EDITOR:-nano} "$HOME/.gtd_preferences_config"
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    4)
      clear
      echo ""
      echo -e "${BOLD}${YELLOW}⚠️  Reset Preferences${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will delete all learned preferences and start fresh."
      echo ""
      read -p "Are you sure? (yes/no): " confirm
      if [[ "$confirm" == "yes" ]]; then
        if [[ -f "$HOME/.gtd_preferences.json" ]]; then
          rm "$HOME/.gtd_preferences.json"
          echo "✓ Preferences reset"
          echo ""
          echo "Run 'gtd-preferences-learn init' to reinitialize"
        else
          echo "No preferences file found"
        fi
      else
        echo "Cancelled"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    5)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}Preferences Config File${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      if [[ -f "$HOME/.gtd_preferences_config" ]]; then
        cat "$HOME/.gtd_preferences_config"
      else
        echo "Config file not found. Creating template..."
        cat > "$HOME/.gtd_preferences_config" <<'EOF'
# GTD Preferences Config
# Manual overrides for learned preferences
# This file overrides what the system learns from your behavior

# Preferred contexts (override learned preferences)
# Format: context=preference_score (0.0-1.0)
# Example:
# computer=0.8
# home=0.6

# Priority calibration (override learned patterns)
# Example: If you rarely use "urgent_important", you might want to adjust
# priority_urgent_important=0.1  # Only 10% of tasks should be urgent_important

# Feature usage preferences
# Disable suggestions for features you never use
# Example:
# disable_suggestions_for=feature_name

# Review timing preferences (override learned times)
# Example:
# preferred_daily_review_time=18:00
# preferred_weekly_review_day=Sunday
# preferred_weekly_review_time=09:00
EOF
        echo "✓ Created template config file"
        echo ""
        echo "File location: $HOME/.gtd_preferences_config"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
}
