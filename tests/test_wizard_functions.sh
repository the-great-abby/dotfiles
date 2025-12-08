#!/bin/bash
# Test script to verify all wizard menu functions are defined
# This script sources all wizard files and checks that menu items have corresponding functions
# Part of the GTD System Testing and Confirmation suite

# Don't exit on error - we want to continue checking all functions
set +e

# Get script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0
MISSING_FUNCTIONS=()

# Function to check if a function exists
check_function() {
  local func_name="$1"
  local menu_item="$2"
  
  if declare -f "$func_name" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Menu $menu_item: ${CYAN}$func_name${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "  ${RED}✗${NC} Menu $menu_item: ${RED}$func_name${NC} ${YELLOW}(NOT FOUND)${NC}"
    MISSING_FUNCTIONS+=("Menu $menu_item: $func_name")
    ((FAILED++))
    return 1
  fi
}

# Source all wizard files (same order as gtd-wizard)
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}Testing GTD Wizard Functions${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BOLD}Sourcing wizard files...${NC}"
echo ""

# Source common
GTD_COMMON="$BIN_DIR/gtd-common.sh"
if [[ ! -f "$GTD_COMMON" && -f "$HOME/code/personal/dotfiles/bin/gtd-common.sh" ]]; then
  GTD_COMMON="$HOME/code/personal/dotfiles/bin/gtd-common.sh"
fi
if [[ -f "$GTD_COMMON" ]]; then
  source "$GTD_COMMON" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-common.sh"
else
  echo -e "  ${YELLOW}⚠${NC}  gtd-common.sh not found"
fi

# Source guides
GTD_GUIDES="$BIN_DIR/gtd-guides.sh"
if [[ ! -f "$GTD_GUIDES" && -f "$HOME/code/personal/dotfiles/bin/gtd-guides.sh" ]]; then
  GTD_GUIDES="$HOME/code/personal/dotfiles/bin/gtd-guides.sh"
fi
if [[ -f "$GTD_GUIDES" ]]; then
  source "$GTD_GUIDES" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-guides.sh"
fi

# Source wizard core
GTD_WIZARD_CORE="$BIN_DIR/gtd-wizard-core.sh"
if [[ ! -f "$GTD_WIZARD_CORE" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh" ]]; then
  GTD_WIZARD_CORE="$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh"
fi
if [[ -f "$GTD_WIZARD_CORE" ]]; then
  source "$GTD_WIZARD_CORE" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-core.sh"
fi

# Source select helper
GTD_SELECT_HELPER="$BIN_DIR/gtd-select-helper.sh"
if [[ ! -f "$GTD_SELECT_HELPER" && -f "$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh" ]]; then
  GTD_SELECT_HELPER="$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh"
fi
if [[ -f "$GTD_SELECT_HELPER" ]]; then
  source "$GTD_SELECT_HELPER" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-select-helper.sh"
fi

# Source wizard inputs
GTD_WIZARD_INPUTS="$BIN_DIR/gtd-wizard-inputs.sh"
if [[ ! -f "$GTD_WIZARD_INPUTS" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-inputs.sh" ]]; then
  GTD_WIZARD_INPUTS="$HOME/code/personal/dotfiles/bin/gtd-wizard-inputs.sh"
fi
if [[ -f "$GTD_WIZARD_INPUTS" ]]; then
  source "$GTD_WIZARD_INPUTS" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-inputs.sh"
fi

# Source wizard org
GTD_WIZARD_ORG="$BIN_DIR/gtd-wizard-org.sh"
if [[ ! -f "$GTD_WIZARD_ORG" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-org.sh" ]]; then
  GTD_WIZARD_ORG="$HOME/code/personal/dotfiles/bin/gtd-wizard-org.sh"
fi
if [[ -f "$GTD_WIZARD_ORG" ]]; then
  source "$GTD_WIZARD_ORG" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-org.sh"
fi

# Source wizard brain
GTD_WIZARD_BRAIN="$BIN_DIR/gtd-wizard-brain.sh"
if [[ ! -f "$GTD_WIZARD_BRAIN" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-brain.sh" ]]; then
  GTD_WIZARD_BRAIN="$HOME/code/personal/dotfiles/bin/gtd-wizard-brain.sh"
fi
if [[ -f "$GTD_WIZARD_BRAIN" ]]; then
  source "$GTD_WIZARD_BRAIN" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-brain.sh"
fi

# Source wizard outputs
GTD_WIZARD_OUTPUTS="$BIN_DIR/gtd-wizard-outputs.sh"
if [[ ! -f "$GTD_WIZARD_OUTPUTS" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-outputs.sh" ]]; then
  GTD_WIZARD_OUTPUTS="$HOME/code/personal/dotfiles/bin/gtd-wizard-outputs.sh"
fi
if [[ -f "$GTD_WIZARD_OUTPUTS" ]]; then
  source "$GTD_WIZARD_OUTPUTS" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-outputs.sh"
fi

# Source wizard analysis
GTD_WIZARD_ANALYSIS="$BIN_DIR/gtd-wizard-analysis.sh"
if [[ ! -f "$GTD_WIZARD_ANALYSIS" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-analysis.sh" ]]; then
  GTD_WIZARD_ANALYSIS="$HOME/code/personal/dotfiles/bin/gtd-wizard-analysis.sh"
fi
if [[ -f "$GTD_WIZARD_ANALYSIS" ]]; then
  source "$GTD_WIZARD_ANALYSIS" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-analysis.sh"
fi

# Source wizard tools
GTD_WIZARD_TOOLS="$BIN_DIR/gtd-wizard-tools.sh"
if [[ ! -f "$GTD_WIZARD_TOOLS" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-tools.sh" ]]; then
  GTD_WIZARD_TOOLS="$HOME/code/personal/dotfiles/bin/gtd-wizard-tools.sh"
fi
if [[ -f "$GTD_WIZARD_TOOLS" ]]; then
  source "$GTD_WIZARD_TOOLS" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-tools.sh"
fi

# Source wizard preferences
GTD_WIZARD_PREFERENCES="$BIN_DIR/gtd-wizard-preferences.sh"
if [[ ! -f "$GTD_WIZARD_PREFERENCES" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-preferences.sh" ]]; then
  GTD_WIZARD_PREFERENCES="$HOME/code/personal/dotfiles/bin/gtd-wizard-preferences.sh"
fi
if [[ -f "$GTD_WIZARD_PREFERENCES" ]]; then
  source "$GTD_WIZARD_PREFERENCES" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-preferences.sh"
fi

# Source wizard enhanced review
GTD_WIZARD_ENHANCED_REVIEW="$BIN_DIR/gtd-wizard-enhanced-review.sh"
if [[ ! -f "$GTD_WIZARD_ENHANCED_REVIEW" && -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-enhanced-review.sh" ]]; then
  GTD_WIZARD_ENHANCED_REVIEW="$HOME/code/personal/dotfiles/bin/gtd-wizard-enhanced-review.sh"
fi
if [[ -f "$GTD_WIZARD_ENHANCED_REVIEW" ]]; then
  source "$GTD_WIZARD_ENHANCED_REVIEW" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Sourced: gtd-wizard-enhanced-review.sh"
fi

echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Checking menu functions...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check all menu functions (based on gtd-wizard-core.sh case statement)
check_function "capture_wizard" "1"
check_function "process_wizard" "2"
check_function "task_wizard" "3"
check_function "project_wizard" "4"
check_function "area_wizard" "5"
check_function "review_wizard" "6"
check_function "sync_wizard" "7"
check_function "moc_wizard" "8"
check_function "express_wizard" "9"
check_function "template_wizard" "10"
check_function "advice_wizard" "11"
check_function "tips_wizard" "12"
check_function "learn_second_brain_wizard" "13"
check_function "life_vision_wizard" "14"
check_function "log_wizard" "15"
check_function "search_wizard" "16"
check_function "status_wizard" "17"
check_function "habit_wizard" "18"
check_function "checkin_wizard" "19"
check_function "k8s_wizard" "20"
check_function "greek_wizard" "21"
check_function "diagram_wizard" "22"
check_function "zettelkasten_wizard" "23"
check_function "ai_suggestions_wizard" "24"
check_function "goal_tracking_wizard" "25"
check_function "energy_audit_wizard" "26"
check_function "config_wizard" "27"
check_function "gamification_wizard" "28"
check_function "calendar_wizard" "29"
check_function "healthkit_wizard" "30"
check_function "morning_routine_wizard" "31"
check_function "afternoon_routine_wizard" "32"
check_function "evening_routine_wizard" "33"
check_function "log_stats_wizard" "34"
check_function "metric_correlations_wizard" "35"
check_function "pattern_recognition_wizard" "36"
check_function "weekly_progress_wizard" "37"
check_function "brain_metrics_wizard" "38"
check_function "energy_schedule_wizard" "39"
check_function "now_wizard" "40"
check_function "find_wizard" "41"
check_function "milestone_wizard" "42"
check_function "evening_summary_wizard" "43"
check_function "deployment_wizard" "44"
check_function "collect_all_wizard" "45"
check_function "quick_complete_habits" "46"
check_function "mood_log_wizard" "47"
check_function "brain_connect_wizard" "48"
check_function "brain_converge_wizard" "49"
check_function "brain_discover_wizard" "50"
check_function "brain_distill_wizard" "51"
check_function "brain_diverge_wizard" "52"
check_function "brain_evergreen_wizard" "53"
check_function "brain_packet_wizard" "54"
check_function "prioritization_wizard" "55"
check_function "success_metrics_wizard" "56"
check_function "bidirectional_sync_wizard" "57"
check_function "preferences_learning_wizard" "58"
check_function "enhanced_review_wizard" "59"

echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Test Results${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL=$((PASSED + FAILED))
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC} ($PASSED/$TOTAL functions found)"
  echo ""
  exit 0
else
  echo -e "${YELLOW}Test Summary:${NC}"
  echo -e "  ${GREEN}Passed:${NC} $PASSED"
  echo -e "  ${RED}Failed:${NC} $FAILED"
  echo ""
  
  if [[ ${#MISSING_FUNCTIONS[@]} -gt 0 ]]; then
    echo -e "${RED}Missing Functions:${NC}"
    for func in "${MISSING_FUNCTIONS[@]}"; do
      echo -e "  ${RED}✗${NC} $func"
    done
    echo ""
  fi
  
  exit 1
fi
