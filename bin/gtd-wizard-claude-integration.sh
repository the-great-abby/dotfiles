#!/bin/bash
# GTD Wizard Integration for Claude + Ollama Hybrid System
# Functions for managing and using the hybrid AI system within the wizard

# ============================================================================
# AI Mode Management Functions
# ============================================================================

get_current_ai_mode() {
  # Get current AI mode from config
  local config_file="${HOME}/.gtd_config_ai"
  if [[ ! -f "$config_file" && -f "${HOME}/code/dotfiles/zsh/.gtd_config_ai" ]]; then
    config_file="${HOME}/code/dotfiles/zsh/.gtd_config_ai"
  fi

  if [[ -f "$config_file" ]]; then
    # Extract mode, handling bash variable syntax
    local mode=$(grep "GTD_AI_MODE=" "$config_file" | head -1 | sed 's/.*GTD_AI_MODE="\?${GTD_AI_MODE:-\([^}]*\)}.*/\1/' | sed 's/.*GTD_AI_MODE="\([^"]*\)".*/\1/' | sed 's/.*GTD_AI_MODE=\([^ ]*\).*/\1/')
    echo "${mode:-hybrid}"
  else
    echo "hybrid"
  fi
}

show_ai_mode_status() {
  # Display current AI mode and availability status
  local current_mode=$(get_current_ai_mode)

  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}🤖 AI System Status${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Check Ollama
  local ollama_status="❌"
  if timeout 2 curl -s "http://127.0.0.1:31080/v1/models" > /dev/null 2>&1; then
    ollama_status="✅"
  fi

  # Check Claude API
  local claude_status="❌"
  if [[ -n "${ANTHROPIC_API_KEY}" ]]; then
    claude_status="✅"
  fi

  echo -e "  Current Mode:       ${BOLD}${GREEN}$current_mode${NC}"
  echo -e "  Ollama:             $ollama_status (http://127.0.0.1:31080)"
  echo -e "  Claude API:         $claude_status${ANTHROPIC_API_KEY:+ ($(echo -n "$ANTHROPIC_API_KEY" | head -c 10)...)}"
  echo ""

  if [[ "$current_mode" == "hybrid" ]]; then
    echo -e "  ${CYAN}📋 How it works:${NC}"
    echo -e "     • Simple tasks → Ollama (instant)"
    echo -e "     • Complex tasks → Claude (quality)"
  else
    echo -e "  ${CYAN}📋 Mode: All requests use local Ollama${NC}"
  fi
  echo ""
}

switch_ai_mode() {
  # Switch between ollama-only and hybrid modes
  local target_mode="$1"

  if [[ "$target_mode" != "ollama-only" && "$target_mode" != "hybrid" ]]; then
    echo -e "${RED}❌ Invalid mode: $target_mode${NC}"
    return 1
  fi

  local config_file="${HOME}/.gtd_config_ai"
  if [[ ! -f "$config_file" && -f "${HOME}/code/dotfiles/zsh/.gtd_config_ai" ]]; then
    config_file="${HOME}/code/dotfiles/zsh/.gtd_config_ai"
  fi

  if [[ ! -f "$config_file" ]]; then
    echo -e "${RED}❌ Config file not found${NC}"
    return 1
  fi

  # Update the config file
  if grep -q "GTD_AI_MODE=" "$config_file"; then
    sed -i '' "s/GTD_AI_MODE=.*/GTD_AI_MODE=\"$target_mode\"/" "$config_file" 2>/dev/null || \
    sed -i "s/GTD_AI_MODE=.*/GTD_AI_MODE=\"$target_mode\"/" "$config_file"
  else
    echo "GTD_AI_MODE=\"$target_mode\"" >> "$config_file"
  fi

  echo -e "${GREEN}✅ Switched to $target_mode mode${NC}"
  return 0
}

load_anthropic_api_key() {
  # Load Claude API key from multiple sources
  # Returns the API key or empty string if not found

  # 1. Check environment variable first
  if [[ -n "${ANTHROPIC_API_KEY}" ]]; then
    echo "${ANTHROPIC_API_KEY}"
    return 0
  fi

  # 2. Try reading from dedicated API key file
  local api_key_file="${HOME}/code/dotfiles/zsh/ANTHROPIC_API_KEY"
  if [[ ! -f "$api_key_file" ]]; then
    api_key_file="${HOME}/ANTHROPIC_API_KEY"
  fi

  if [[ -f "$api_key_file" ]]; then
    local api_key=$(cat "$api_key_file" 2>/dev/null | tr -d '\n' | xargs)
    if [[ -n "$api_key" ]]; then
      echo "$api_key"
      return 0
    fi
  fi

  # 3. Try .gtd_config_ai
  local config_file="${HOME}/.gtd_config_ai"
  if [[ ! -f "$config_file" && -f "${HOME}/code/dotfiles/zsh/.gtd_config_ai" ]]; then
    config_file="${HOME}/code/dotfiles/zsh/.gtd_config_ai"
  fi

  if [[ -f "$config_file" ]]; then
    local api_key=$(grep "ANTHROPIC_API_KEY=" "$config_file" | head -1 | sed 's/.*ANTHROPIC_API_KEY="\(.*\)".*/\1/' | sed 's/.*ANTHROPIC_API_KEY=\([^ ]*\).*/\1/')
    if [[ -n "$api_key" && "$api_key" != "-" ]]; then
      echo "$api_key"
      return 0
    fi
  fi

  return 1
}

# ============================================================================
# Quick Claude-GTD Functions
# ============================================================================

quick_claude_advice() {
  # 
  local persona="${1:-hank}"
  local question="$2"

  if [[ -z "$question" ]]; then
    echo -n "Question: "
    read -r question
  fi

  if [[ -z "$question" ]]; then
    return
  fi

  # Get MCP Python (venv if available)
  local PYTHON_CMD
  if type -t gtd_get_mcp_python >/dev/null 2>&1; then
    PYTHON_CMD=$(gtd_get_mcp_python)
  else
    PYTHON_CMD="python3"
  fi

  echo ""
  "$PYTHON_CMD" "${HOME}/code/dotfiles/mcp/claude_gtd_client.py" persona "$question" --persona "$persona" 2>/dev/null || true
  echo ""
}

quick_task_suggestion() {
  # 
  local context="$1"

  if [[ -z "$context" ]]; then
    echo "Describe what you've been working on:"
    read -r context
  fi

  if [[ -z "$context" ]]; then
    return
  fi

  # Get MCP Python (venv if available)
  local PYTHON_CMD
  if type -t gtd_get_mcp_python >/dev/null 2>&1; then
    PYTHON_CMD=$(gtd_get_mcp_python)
  else
    PYTHON_CMD="python3"
  fi

  echo ""
  "$PYTHON_CMD" "${HOME}/code/dotfiles/mcp/claude_gtd_client.py" suggest "$context" 2>/dev/null || true
  echo ""
}

quick_task_categorize() {
  # 
  local tasks="$1"

  if [[ -z "$tasks" ]]; then
    echo "List your tasks (comma-separated or one per line):"
    read -r tasks
  fi

  if [[ -z "$tasks" ]]; then
    return
  fi

  # Get MCP Python (venv if available)
  local PYTHON_CMD
  if type -t gtd_get_mcp_python >/dev/null 2>&1; then
    PYTHON_CMD=$(gtd_get_mcp_python)
  else
    PYTHON_CMD="python3"
  fi

  echo ""
  "$PYTHON_CMD" "${HOME}/code/dotfiles/mcp/claude_gtd_client.py" categorize "$tasks" 2>/dev/null || true
  echo ""
}

# ============================================================================
# AI Mode Configuration Wizard
# ============================================================================

ai_mode_configuration_wizard() {
  # 
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🤖 AI System Configuration${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  show_ai_mode_status

  echo -e "${BOLD}Choose an option:${NC}"
  echo ""
  echo "  1) Switch to ${BOLD}ollama-only${NC} mode (local, free, no API calls)"
  echo "  2) Switch to ${BOLD}hybrid${NC} mode (smart routing: Ollama + Claude)"
  echo "  3) View system status"
  echo "  4) Quick test"
  echo "  5) Configure Claude API key"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read config_choice

  case "$config_choice" in
    1)
      echo ""
      switch_ai_mode "ollama-only"
      echo ""
      echo "✅ Switched to ollama-only mode - all requests use local Ollama"
      sleep 2
      ;;
    2)
      echo ""
      switch_ai_mode "hybrid"
      echo ""
      echo "✅ Switched to hybrid mode"
      echo ""
      if [[ -z "${ANTHROPIC_API_KEY}" ]]; then
        echo -e "${YELLOW}⚠️  Claude API key not set${NC}"
        echo "   Set it with: export ANTHROPIC_API_KEY=sk-..."
        echo "   Or add to ~/.gtd_config_ai"
      fi
      sleep 2
      ;;
    3)
      echo ""
      show_ai_mode_status
      echo -n "Press Enter to continue: "
      read
      ;;
    4)
      echo ""
      echo -e "${CYAN}Testing Claude + Ollama system...${NC}"
      echo ""
      quick_claude_advice "hank" "What should I do first today?"
      echo -n "Press Enter to continue: "
      read
      ;;
    5)
      echo ""
      echo "Your current Claude API key: ${ANTHROPIC_API_KEY:-(not set)}"
      echo ""
      echo -n "Enter new API key (or leave blank to skip): "
      read -s new_key
      echo ""

      if [[ -n "$new_key" ]]; then
        export ANTHROPIC_API_KEY="$new_key"

        # Save to config
        local config_file="${HOME}/.gtd_config_ai"
        if [[ ! -f "$config_file" && -f "${HOME}/code/dotfiles/zsh/.gtd_config_ai" ]]; then
          config_file="${HOME}/code/dotfiles/zsh/.gtd_config_ai"
        fi

        if grep -q "ANTHROPIC_API_KEY=" "$config_file"; then
          sed -i '' "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=\"$new_key\"|" "$config_file" 2>/dev/null || \
          sed -i "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=\"$new_key\"|" "$config_file"
        else
          echo "ANTHROPIC_API_KEY=\"$new_key\"" >> "$config_file"
        fi

        echo -e "${GREEN}✅ API key saved${NC}"
      fi
      sleep 2
      ;;
  esac
}

# ============================================================================
# Quick Claude Advice from Advice Wizard
# ============================================================================

quick_claude_from_advice_wizard() {
  # 
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚡ Quick Claude Advice${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  show_ai_mode_status

  echo "What would you like?"
  echo ""
  echo "  1) Get persona advice (smart routing)"
  echo "  2) Generate task suggestions (smart routing)"
  echo "  3) Categorize tasks (smart routing)"
  echo "  4) Analyze daily log (smart routing)"
  echo "  5) Ask Claude directly (always Claude, bypasses router)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read quick_choice

  case "$quick_choice" in
    1)
      echo ""
      # Use the same persona selector as the rest of the wizard
      # This will show ALL available personas from your config
      if type -t select_persona >/dev/null 2>&1; then
        local persona=$(select_persona)
        if [[ -z "$persona" ]]; then
          echo "No persona selected. Going back..."
          return 0
        fi
      else
        # Fallback if select_persona isn't available
        echo "Available personas: hank, david, cal, james, marie, warren, sheryl, tim, louiza, skippy, george, john, jon, bob, fred, etc."
        echo ""
        echo -n "Enter persona name: "
        read persona

        if [[ -z "$persona" ]]; then
          echo "No persona entered. Going back..."
          return 0
        fi
      fi

      echo ""
      echo -n "Question: "
      read question

      if [[ -n "$question" ]]; then
        quick_claude_advice "$persona" "$question"
      fi
      ;;
    2)
      echo ""
      echo "Describe what you've been working on (or paste your log):"
      read -r context
      if [[ -n "$context" ]]; then
        quick_task_suggestion "$context"
      fi
      ;;
    3)
      echo ""
      echo "List your tasks (comma-separated or space-separated):"
      read -r tasks
      if [[ -n "$tasks" ]]; then
        quick_task_categorize "$tasks"
      fi
      ;;
    4)
      echo ""
      echo -n "Path to daily log file: "
      read log_file

      if [[ -f "$log_file" ]]; then
        # Get MCP Python (venv if available)
        local PYTHON_CMD
        if type -t gtd_get_mcp_python >/dev/null 2>&1; then
          PYTHON_CMD=$(gtd_get_mcp_python)
        else
          PYTHON_CMD="python3"
        fi
        
        echo ""
        "$PYTHON_CMD" "${HOME}/code/dotfiles/mcp/claude_gtd_client.py" analyze "$log_file" 2>/dev/null || true
      else
        echo -e "${RED}❌ File not found: $log_file${NC}"
      fi
      ;;
    5)
      echo ""
      echo -e "${BOLD}🧠 Ask Claude Directly${NC}"
      echo -e "${CYAN}(Always uses Claude API, bypasses smart router)${NC}"
      echo ""
      echo -n "Your question: "
      read question

      if [[ -n "$question" ]]; then
        # Get MCP Python (venv if available)
        local PYTHON_CMD
        if type -t gtd_get_mcp_python >/dev/null 2>&1; then
          PYTHON_CMD=$(gtd_get_mcp_python)
        else
          PYTHON_CMD="python3"
        fi
        
        echo ""
        if "$PYTHON_CMD" "${HOME}/code/dotfiles/mcp/claude_gtd_client.py" ask "$question"; then
          # Success - show response and pause so user can read it
          echo ""
          gtd_enter_to_continue
        else
          # Error occurred - show error message
          echo ""
          echo -e "${RED}❌ Error: Failed to get response from Claude${NC}"
          echo -e "${YELLOW}   Check that your ANTHROPIC_API_KEY is set correctly${NC}"
          echo -e "${YELLOW}   Also verify the anthropic package is installed in the MCP venv${NC}"
          gtd_quick_pause
        fi
      else
        echo -e "${YELLOW}⚠️  No question provided${NC}"
        gtd_quick_pause
      fi
      ;;
    esac

    # Only show generic pause if we didn't already pause in the case statement
    # (This handles other options that don't have their own pause)
    if [[ "$quick_choice" != "5" ]]; then
      echo ""
      echo -n "Press Enter to continue: "
      read
    fi
}

# Export functions so they're available to the wizard
export -f get_current_ai_mode
export -f show_ai_mode_status
export -f switch_ai_mode
export -f load_anthropic_api_key
export -f quick_claude_advice
export -f quick_task_suggestion
export -f quick_task_categorize
export -f ai_mode_configuration_wizard
export -f quick_claude_from_advice_wizard
