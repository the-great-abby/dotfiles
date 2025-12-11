#!/bin/bash
# GTD Wizard Tools Functions
# Tools wizards for advice, config, learning, integrations

# Helper function to handle follow-up questions
handle_followup_questions() {
  local persona="$1"
  local initial_question="$2"
  local initial_answer="$3"
  local use_simple_mode="${4:-false}"
  local use_web_search="${5:-false}"
  
  # Store conversation
  local conversation_questions=("$initial_question")
  local conversation_answers=("$initial_answer")
  
  # Ask if they want to continue the conversation
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}Do you have any follow-up questions?${NC}"
  echo -e "${GREEN}y${NC} - Ask more questions"
  echo -e "${GREEN}n${NC} - Done (save advice)"
  echo ""
  read -p "Choice: " continue_conv
  echo ""
  
  if [[ "$continue_conv" == "y" || "$continue_conv" == "Y" ]]; then
    # Conversation loop
    while true; do
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      if [[ "$persona" == "random" ]]; then
        echo -e "${BOLD}💬 Ask a follow-up question${NC}"
      else
        echo -e "${BOLD}💬 Ask ${persona} a follow-up question${NC}"
      fi
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "${YELLOW}Type your question (or 'done' to finish):${NC}"
      echo ""
      read -p "❓ Question: " followup_question
      
      if [[ -z "$followup_question" ]]; then
        echo "Please enter a question or 'done' to continue."
        echo ""
        continue
      fi
      
      if [[ "$followup_question" == "done" || "$followup_question" == "Done" || "$followup_question" == "DONE" ]]; then
        echo ""
        echo "✓ Finished asking questions."
        echo ""
        break
      fi
      
      # Add to conversation
      conversation_questions+=("$followup_question")
      
      echo ""
      if [[ "$persona" == "random" ]]; then
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}💬 Answer${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      else
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}💬 Answer from ${persona}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      fi
      echo ""
      
      # Build follow-up prompt with context
      local followup_prompt="Context: We were discussing: ${initial_question}\n\nFollow-up question: ${followup_question}\n\nAnswer this follow-up question about the same topic. Be specific and accurate."
      
      local followup_answer=""
      if [[ "$use_simple_mode" == "true" ]]; then
        if [[ "$use_web_search" == "true" ]]; then
          # Build contextual search query
          local search_query="${initial_question} ${followup_question}"
          echo "🔍 Performing web search for follow-up question..."
          echo ""
          followup_answer=$(gtd-advise --simple --web-search "$persona" "$search_query" 2>&1)
        else
          followup_answer=$(gtd-advise --simple "$persona" "$followup_prompt" 2>&1)
        fi
      else
        # Regular mode - include context from original question
        if [[ "$persona" == "random" ]]; then
          followup_answer=$(gtd-advise --random "$followup_prompt" 2>&1)
        else
          followup_answer=$(gtd-advise "$persona" "$followup_prompt" 2>&1)
        fi
      fi
      
      echo "$followup_answer"
      conversation_answers+=("$followup_answer")
      
      echo ""
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
    done
  fi
  
  # Build full conversation text
  local full_conversation=""
  for i in "${!conversation_questions[@]}"; do
    local q_num=$((i+1))
    full_conversation="${full_conversation}**Q${q_num}:** ${conversation_questions[$i]}

**A${q_num}:**
${conversation_answers[$i]}

---

"
  done
  
  # Return conversation via global variable (bash limitation)
  FOLLOWUP_CONVERSATION="$full_conversation"
  FOLLOWUP_HAS_FOLLOWUPS=$(( ${#conversation_questions[@]} > 1 ? 1 : 0 ))
}

# Helper function to save advice conversation to GTD system
save_advice_conversation() {
  local question="$1"
  local persona="$2"
  local answer="$3"
  
  if [[ -z "$question" || -z "$answer" ]]; then
    echo "❌ Missing question or answer to save"
    return 1
  fi
  
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💾 Save Advice Conversation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "How would you like to save this conversation?"
  echo ""
  echo "  1) 📝 Note (Second Brain)"
  echo "  2) 📋 Task"
  echo "  3) 📁 Project"
  echo "  4) 🎯 Area"
  echo "  5) 🎯 Goal"
  echo "  6) 🔗 Zettelkasten Note (atomic note)"
  echo "  7) 📥 Inbox (for later processing)"
  echo ""
  echo -e "${YELLOW}0)${NC} Skip (don't save)"
  echo ""
  echo -n "Choose: "
  read save_choice
  
  # Create title from question (first 50 chars)
  local title=$(echo "$question" | cut -c1-50)
  if [[ ${#question} -gt 50 ]]; then
    title="${title}..."
  fi
  
  # Format the content
  local content=""
  if [[ -n "$persona" ]]; then
    content="# Advice from ${persona}

**Question:** ${question}

**Answer:**
${answer}"
  else
    content="# Advice Conversation

**Question:** ${question}

**Answer:**
${answer}"
  fi
  
  case "$save_choice" in
    1)
      # Save as Second Brain note
      echo ""
      echo "💾 Saving as Second Brain note..."
      if command -v gtd-brain &>/dev/null; then
        # Ask for PARA location
        echo ""
        echo "Where should this note go?"
        echo "  1) Projects"
        echo "  2) Areas"
        echo "  3) Resources"
        echo "  4) Archive"
        echo ""
        echo -n "Choose (1-4, default: Resources): "
        read para_choice
        local para_location="Resources"
        case "$para_choice" in
          1) para_location="Projects" ;;
          2) para_location="Areas" ;;
          3) para_location="Resources" ;;
          4) para_location="Archive" ;;
        esac
        
        # Create note
        if echo "$content" | gtd-brain create "$title" "$para_location" 2>/dev/null; then
          echo "✓ Saved as Second Brain note in ${para_location}"
        else
          echo "❌ Failed to create note. Saving to inbox instead..."
          echo "$content" | gtd-capture "Advice: $title"
        fi
      else
        echo "❌ gtd-brain command not found. Saving to inbox instead..."
        echo "$content" | gtd-capture "Advice: $title"
      fi
      ;;
    2)
      # Save as task
      echo ""
      echo "💾 Saving as task..."
      if command -v gtd-task &>/dev/null; then
        if echo "$content" | gtd-task add "$title" 2>/dev/null; then
          echo "✓ Saved as task"
        else
          echo "❌ Failed to create task. Saving to inbox instead..."
          echo "$content" | gtd-capture "Task: $title"
        fi
      else
        echo "❌ gtd-task command not found. Saving to inbox instead..."
        echo "$content" | gtd-capture "Task: $title"
      fi
      ;;
    3)
      # Save as project
      echo ""
      echo "💾 Saving as project..."
      if command -v gtd-project &>/dev/null; then
        if echo "$content" | gtd-project create "$title" 2>/dev/null; then
          echo "✓ Saved as project"
        else
          echo "❌ Failed to create project. Saving to inbox instead..."
          echo "$content" | gtd-capture "Project: $title"
        fi
      else
        echo "❌ gtd-project command not found. Saving to inbox instead..."
        echo "$content" | gtd-capture "Project: $title"
      fi
      ;;
    4)
      # Save as area
      echo ""
      echo "💾 Saving as area..."
      if command -v gtd-area &>/dev/null; then
        if echo "$content" | gtd-area create "$title" 2>/dev/null; then
          echo "✓ Saved as area"
        else
          echo "❌ Failed to create area. Saving to inbox instead..."
          echo "$content" | gtd-capture "Area: $title"
        fi
      else
        echo "❌ gtd-area command not found. Saving to inbox instead..."
        echo "$content" | gtd-capture "Area: $title"
      fi
      ;;
    5)
      # Save as goal
      echo ""
      echo "💾 Saving as goal..."
      if command -v gtd-goal &>/dev/null; then
        if gtd-goal create "$title" --description "$content" 2>/dev/null; then
          echo "✓ Saved as goal"
        else
          echo "❌ Failed to create goal. Saving to inbox instead..."
          echo "$content" | gtd-capture "Goal: $title"
        fi
      else
        echo "❌ gtd-goal command not found. Saving to inbox instead..."
        echo "$content" | gtd-capture "Goal: $title"
      fi
      ;;
    6)
      # Save as zettelkasten note
      echo ""
      echo "💾 Saving as Zettelkasten note..."
      if command -v zet &>/dev/null; then
        if echo "$content" | zet create "$title" 2>/dev/null; then
          echo "✓ Saved as Zettelkasten note"
        else
          echo "❌ Failed to create Zettelkasten note. Saving to inbox instead..."
          echo "$content" | gtd-capture "Zettelkasten: $title"
        fi
      else
        echo "❌ zet command not found. Saving to inbox instead..."
        echo "$content" | gtd-capture "Zettelkasten: $title"
      fi
      ;;
    7)
      # Save to inbox
      echo ""
      echo "💾 Saving to inbox..."
      if command -v gtd-capture &>/dev/null; then
        echo "$content" | gtd-capture "Advice: $title"
        echo "✓ Saved to inbox"
      else
        echo "❌ gtd-capture command not found"
        return 1
      fi
      ;;
    0|"")
      echo "Skipped saving"
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
}

advice_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🤖 Get Advice Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_advice_guide
  echo "How would you like to get advice?"
  echo ""
  echo "  1) Random persona"
  echo "  2) Specific persona"
  echo "  3) All personas"
  echo "  4) Review daily log"
  echo "  5) Simple factual question (no GTD context)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read advice_choice
  
  case "$advice_choice" in
    1)
      echo ""
      echo -n "What do you need advice about? "
      read question
        if [[ -n "$question" ]]; then
          # Run gtd-advise - it uses run_with_thinking_timer internally
          # Timer writes to stderr, advice to stdout
          # Capture stdout while stderr (timer) displays to terminal
          local temp_output=$(mktemp)
          # Run gtd-advise - timer writes to stderr (displays), advice to stdout (save to file)
          # When done, display the saved output
          gtd-advise --random "$question" > "$temp_output"
          local advice_output=$(cat "$temp_output")
          rm -f "$temp_output"
          echo ""
          echo "$advice_output"
        
        # Handle follow-up questions
        handle_followup_questions "random" "$question" "$advice_output" "false" "false"
        
        # Save conversation if there were follow-ups, or ask to save if no follow-ups
        if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]]; then
          echo ""
          echo -e "${BOLD}Save this conversation? (y/n):${NC} "
          read save_advice
          if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
            save_advice_conversation "$question" "random" "$FOLLOWUP_CONVERSATION"
          fi
        else
          echo ""
          echo -e "${BOLD}Save this advice? (y/n):${NC} "
          read save_advice
          if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
            save_advice_conversation "$question" "random" "$advice_output"
          fi
        fi
      fi
      ;;
    2)
      echo ""
      persona=$(select_persona)
      if [[ -n "$persona" ]]; then
        echo ""
        echo -n "Your question: "
        read question
        if [[ -n "$question" ]]; then
          # Run gtd-advise - timer writes to stderr (displays), advice to stdout (save to file)
          # When done, display the saved output
          # IMPORTANT: Only redirect stdout, NOT stderr, so timer can display
          local temp_output=$(mktemp)
          gtd-advise "$persona" "$question" > "$temp_output"
          local advice_output=$(cat "$temp_output")
          rm -f "$temp_output"
          echo ""
          echo "$advice_output"
          
          # Handle follow-up questions
          handle_followup_questions "$persona" "$question" "$advice_output" "false" "false"
          
          # Save conversation if there were follow-ups, or ask to save if no follow-ups
          if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]]; then
            echo ""
            echo -e "${BOLD}Save this conversation? (y/n):${NC} "
            read save_advice
            if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
              save_advice_conversation "$question" "$persona" "$FOLLOWUP_CONVERSATION"
            fi
          else
            echo ""
            echo -e "${BOLD}Save this advice? (y/n):${NC} "
            read save_advice
            if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
              save_advice_conversation "$question" "$persona" "$advice_output"
            fi
          fi
        fi
      fi
      ;;
    3)
      echo ""
      echo -n "What do you need advice about? "
      read question
      if [[ -n "$question" ]]; then
        # Run gtd-advise directly - timer writes to stderr, output to stdout
        # Capture stdout to temp file while stderr (timer) displays to terminal
        local temp_output=$(mktemp)
        # Run gtd-advise - timer writes to stderr (displays), advice to stdout (save to file)
        # When done, display the saved output
        gtd-advise --all "$question" > "$temp_output"
        local advice_output=$(cat "$temp_output")
        rm -f "$temp_output"
        echo ""
        echo "$advice_output"
        
        # Note: For "all personas", follow-ups would be complex (which persona to ask?)
        # So we'll just offer to save the initial multi-persona response
        echo ""
        echo -e "${BOLD}Save this advice? (y/n):${NC} "
        read save_advice
        if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
          save_advice_conversation "$question" "all personas" "$advice_output"
        fi
      fi
      ;;
    4)
      echo ""
      echo "Reviewing your daily log..."
      # Run gtd-advise - timer writes to /dev/tty (displays), advice to stdout (save to file)
      # When done, display the saved output
      local temp_output=$(mktemp)
      gtd-advise --daily-log > "$temp_output"
      local advice_output=$(cat "$temp_output")
      rm -f "$temp_output"
      echo ""
      echo "$advice_output"
      
      # Handle follow-up questions (using default persona)
      local default_persona="${GTD_DEFAULT_PERSONA:-skippy}"
      handle_followup_questions "$default_persona" "Daily log review" "$advice_output" "false" "false"
      
      # Save conversation if there were follow-ups, or ask to save if no follow-ups
      if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]]; then
        echo ""
        echo -e "${BOLD}Save this conversation? (y/n):${NC} "
        read save_advice
        if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
          save_advice_conversation "Daily log review" "$default_persona" "$FOLLOWUP_CONVERSATION"
        fi
      else
        echo ""
        echo -e "${BOLD}Save this review? (y/n):${NC} "
        read save_advice
        if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
          save_advice_conversation "Daily log review" "default persona" "$advice_output"
        fi
      fi
      ;;
    5)
      echo ""
      echo -e "${BOLD}💡 Simple Question Mode${NC}"
      echo ""
      echo "This mode answers factual questions without including your GTD context."
      echo "Use this for: trivia, facts, definitions, historical events, etc."
      echo ""
      persona=$(select_persona)
      if [[ -z "$persona" ]]; then
        return 0
      fi
      echo ""
      echo -e "${YELLOW}Enable web search for more accurate answers? (y/n):${NC} "
      read use_search
      echo ""
      echo -n "Your question: "
      read question
      
      if [[ -n "$persona" && -n "$question" ]]; then
        local search_flag=""
        if [[ "$use_search" == "y" || "$use_search" == "Y" ]]; then
          search_flag="--web-search"
        fi
        
        # Store conversation for saving
        local conversation_questions=("$question")
        local conversation_answers=()
        
        # Get initial answer
        # Note: --web-search must come before the persona when using --simple
        if [[ -n "$search_flag" ]]; then
          # Web search is enabled - perform search first and include results
          echo ""
          echo "🔍 Performing web search..."
          echo ""
          
          # Perform web search using browser MCP tools (via AI assistant)
          # For now, we'll output a clear request that the AI assistant should detect
          # In the future, this could be automated
          local search_url="https://www.google.com/search?q=$(echo "$question" | sed 's/ /+/g')"
          echo "⚠️  Web search requested for: $question"
          echo "⚠️  Search URL: $search_url"
          echo "⚠️  AI Assistant: Please perform this search and include results in the prompt"
          echo ""
          
          local answer_output=$(gtd-advise --simple --web-search "$persona" "$question" 2>&1)
          echo "$answer_output"
        else
          local answer_output=$(gtd-advise --simple "$persona" "$question" 2>&1)
          echo "$answer_output"
        fi
        
        # Handle follow-up questions using the helper function
        handle_followup_questions "$persona" "$question" "$answer_output" "true" "$use_search"
        
        # Save conversation if there were follow-ups, or ask to save if no follow-ups
        if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]]; then
          echo ""
          echo -e "${BOLD}Save this conversation? (y/n):${NC} "
          read save_conv
          if [[ "$save_conv" == "y" || "$save_conv" == "Y" ]]; then
            save_advice_conversation "$question" "$persona" "$FOLLOWUP_CONVERSATION"
          fi
        else
          echo ""
          echo -e "${BOLD}Save this advice? (y/n):${NC} "
          read save_conv
          if [[ "$save_conv" == "y" || "$save_conv" == "Y" ]]; then
            save_advice_conversation "$question" "$persona" "$answer_output"
          fi
        fi
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
  echo "Press Enter to continue..."
  read
}

configure_mode_specific_ai() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 Configure Mode-Specific AI (Work vs Home)${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Source wizard core to get computer mode functions
  if [[ -f "$HOME/code/dotfiles/bin/gtd-wizard-core.sh" ]]; then
    source "$HOME/code/dotfiles/bin/gtd-wizard-core.sh" 2>/dev/null || true
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh" ]]; then
    source "$HOME/code/personal/dotfiles/bin/gtd-wizard-core.sh" 2>/dev/null || true
  fi
  
  # Get current mode
  local current_mode="home"
  if declare -f get_computer_mode &>/dev/null; then
    current_mode=$(get_computer_mode)
  else
    # Fallback: read from config
    local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
    if [[ ! -f "$gtd_config" ]]; then
      gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
    fi
    if [[ -f "$gtd_config" ]]; then
      source "$gtd_config" 2>/dev/null || true
      current_mode="${GTD_COMPUTER_MODE:-home}"
    fi
  fi
  
  # Find config file
  local GTD_AI_CONFIG="$HOME/code/dotfiles/zsh/.gtd_config_ai"
  if [[ ! -f "$GTD_AI_CONFIG" ]]; then
    GTD_AI_CONFIG="$HOME/code/personal/dotfiles/zsh/.gtd_config_ai"
  fi
  
  if [[ ! -f "$GTD_AI_CONFIG" ]]; then
    echo -e "${RED}❌ Config file not found:${NC}"
    echo "   $GTD_AI_CONFIG"
    echo ""
    echo "Press Enter to continue..."
    read
    return 1
  fi
  
  echo -e "Current computer mode: ${BOLD}${CYAN}$current_mode${NC}"
  echo ""
  echo "This allows you to configure different AI systems/models for work vs home."
  echo "For example:"
  echo "  • Work: Ollama with gpt-oss-20b or gemma3-1b"
  echo "  • Home: LM Studio with qwen/qwen3-1.7b"
  echo ""
  echo "What would you like to configure?"
  echo ""
  echo "  1) 💼 Configure Work Mode AI"
  echo "  2) 🏠 Configure Home Mode AI"
  echo "  3) 📋 View Current Mode-Specific Settings"
  echo "  4) 🔄 Clear Mode-Specific Settings (use defaults)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      configure_mode_ai "work" "$GTD_AI_CONFIG"
      ;;
    2)
      configure_mode_ai "home" "$GTD_AI_CONFIG"
      ;;
    3)
      view_mode_ai_settings "$GTD_AI_CONFIG"
      ;;
    4)
      clear_mode_ai_settings "$GTD_AI_CONFIG"
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
  esac
}

configure_mode_ai() {
  local mode="$1"
  local config_file="$2"
  local mode_prefix=""
  local mode_display=""
  
  if [[ "$mode" == "work" ]]; then
    mode_prefix="WORK_"
    mode_display="💼 Work"
  else
    mode_prefix="HOME_"
    mode_display="🏠 Home"
  fi
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Configure ${mode_display} Mode AI${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Read current settings
  local current_backend=""
  local current_lm_model=""
  local current_ollama_model=""
  local current_deep_model=""
  
  if [[ -f "$config_file" ]]; then
    if grep -q "^${mode_prefix}AI_BACKEND=" "$config_file" 2>/dev/null; then
      current_backend=$(grep "^${mode_prefix}AI_BACKEND=" "$config_file" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
    fi
    if grep -q "^${mode_prefix}LM_STUDIO_CHAT_MODEL=" "$config_file" 2>/dev/null; then
      current_lm_model=$(grep "^${mode_prefix}LM_STUDIO_CHAT_MODEL=" "$config_file" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
    if grep -q "^${mode_prefix}OLLAMA_CHAT_MODEL=" "$config_file" 2>/dev/null; then
      current_ollama_model=$(grep "^${mode_prefix}OLLAMA_CHAT_MODEL=" "$config_file" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
    if grep -q "^${mode_prefix}DEEP_MODEL_NAME=" "$config_file" 2>/dev/null; then
      current_deep_model=$(grep "^${mode_prefix}DEEP_MODEL_NAME=" "$config_file" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
  fi
  
  echo -e "${BOLD}Current ${mode_display} Settings:${NC}"
  echo "  AI Backend: ${current_backend:-<not set, using default>}"
  echo "  LM Studio Model: ${current_lm_model:-<not set, using default>}"
  echo "  Ollama Model: ${current_ollama_model:-<not set, using default>}"
  echo "  Deep Model: ${current_deep_model:-<not set, using default>}"
  echo ""
  echo "Configure:"
  echo ""
  echo "  1) AI Backend (lmstudio or ollama)"
  echo "  2) LM Studio Chat Model (e.g., qwen/qwen3-1.7b, google/gemma-3-1b)"
  echo "  3) Ollama Chat Model (e.g., gemma2:1b, llama3.1:8b)"
  echo "  4) Deep Model (e.g., gpt-oss-20b, qwen/qwen3-4b-thinking-2507)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read sub_choice
  
  case "$sub_choice" in
    1)
      echo ""
      echo "Select AI Backend for ${mode_display} mode:"
      echo ""
      echo "  1) LM Studio"
      echo "  2) Ollama"
      echo ""
      echo -n "Choose: "
      read backend_choice
      
      local new_backend=""
      case "$backend_choice" in
        1) new_backend="lmstudio" ;;
        2) new_backend="ollama" ;;
        *)
          echo "Invalid choice"
          echo ""
          echo "Press Enter to continue..."
          read
          return
          ;;
      esac
      
      update_config_value "$config_file" "${mode_prefix}AI_BACKEND" "$new_backend"
      echo ""
      echo -e "${GREEN}✅ ${mode_display} AI backend set to: $new_backend${NC}"
      ;;
    2)
      echo ""
      echo "Enter LM Studio chat model name:"
      echo "Examples: qwen/qwen3-1.7b, google/gemma-3-1b, openai/gpt-oss-20b"
      echo ""
      echo -n "Model name (or press Enter to clear): "
      read model_name
      
      if [[ -n "$model_name" ]]; then
        update_config_value "$config_file" "${mode_prefix}LM_STUDIO_CHAT_MODEL" "$model_name"
        echo ""
        echo -e "${GREEN}✅ ${mode_display} LM Studio model set to: $model_name${NC}"
      else
        update_config_value "$config_file" "${mode_prefix}LM_STUDIO_CHAT_MODEL" ""
        echo ""
        echo -e "${GREEN}✅ ${mode_display} LM Studio model cleared (will use default)${NC}"
      fi
      ;;
    3)
      echo ""
      echo "Enter Ollama chat model name:"
      echo "Examples: gemma2:1b, llama3.1:8b, qwen2.5:7b"
      echo ""
      echo -n "Model name (or press Enter to clear): "
      read model_name
      
      if [[ -n "$model_name" ]]; then
        update_config_value "$config_file" "${mode_prefix}OLLAMA_CHAT_MODEL" "$model_name"
        echo ""
        echo -e "${GREEN}✅ ${mode_display} Ollama model set to: $model_name${NC}"
      else
        update_config_value "$config_file" "${mode_prefix}OLLAMA_CHAT_MODEL" ""
        echo ""
        echo -e "${GREEN}✅ ${mode_display} Ollama model cleared (will use default)${NC}"
      fi
      ;;
    4)
      echo ""
      echo "Enter deep model name (for complex analysis):"
      echo "Examples: gpt-oss-20b, qwen/qwen3-4b-thinking-2507"
      echo ""
      echo -n "Model name (or press Enter to clear): "
      read model_name
      
      if [[ -n "$model_name" ]]; then
        update_config_value "$config_file" "${mode_prefix}DEEP_MODEL_NAME" "$model_name"
        echo ""
        echo -e "${GREEN}✅ ${mode_display} deep model set to: $model_name${NC}"
      else
        update_config_value "$config_file" "${mode_prefix}DEEP_MODEL_NAME" ""
        echo ""
        echo -e "${GREEN}✅ ${mode_display} deep model cleared (will use default)${NC}"
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
  echo "Press Enter to continue..."
  read
}

update_config_value() {
  local config_file="$1"
  local key="$2"
  local value="$3"
  
  if [[ ! -f "$config_file" ]]; then
    echo -e "${RED}❌ Config file not found: $config_file${NC}" >&2
    return 1
  fi
  
  # Check if key exists
  if grep -q "^${key}=" "$config_file" 2>/dev/null; then
    # Update existing line
    if [[ "$(uname)" == "Darwin" ]]; then
      if [[ -n "$value" ]]; then
        sed -i '' "s|^${key}=.*|${key}=\"${value}\"|" "$config_file"
      else
        sed -i '' "s|^${key}=.*|${key}=\"\"|" "$config_file"
      fi
    else
      if [[ -n "$value" ]]; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$config_file"
      else
        sed -i "s|^${key}=.*|${key}=\"\"|" "$config_file"
      fi
    fi
  else
    # Add new line after mode-specific config section
    if grep -q "# Mode-Specific AI Configuration" "$config_file" 2>/dev/null; then
      # Find the line after the section header
      local insert_after="# Mode-Specific AI Configuration"
      if [[ "$(uname)" == "Darwin" ]]; then
        if [[ -n "$value" ]]; then
          sed -i '' "/^${insert_after}/a\\
${key}=\"${value}\"
" "$config_file"
        else
          sed -i '' "/^${insert_after}/a\\
${key}=\"\"\\
" "$config_file"
        fi
      else
        if [[ -n "$value" ]]; then
          sed -i "/^${insert_after}/a ${key}=\"${value}\"" "$config_file"
        else
          sed -i "/^${insert_after}/a ${key}=\"\"" "$config_file"
        fi
      fi
    else
      # Append to end of file
      if [[ -n "$value" ]]; then
        echo "${key}=\"${value}\"" >> "$config_file"
      else
        echo "${key}=\"\"" >> "$config_file"
      fi
    fi
  fi
}

view_mode_ai_settings() {
  local config_file="$1"
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📋 Mode-Specific AI Settings${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if [[ ! -f "$config_file" ]]; then
    echo -e "${RED}❌ Config file not found${NC}"
    echo ""
    echo "Press Enter to continue..."
    read
    return 1
  fi
  
  echo -e "${BOLD}💼 Work Mode:${NC}"
  local work_backend=$(grep "^WORK_AI_BACKEND=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  local work_lm=$(grep "^WORK_LM_STUDIO_CHAT_MODEL=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  local work_ollama=$(grep "^WORK_OLLAMA_CHAT_MODEL=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  local work_deep=$(grep "^WORK_DEEP_MODEL_NAME=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  
  echo "  Backend: $work_backend"
  echo "  LM Studio Model: $work_lm"
  echo "  Ollama Model: $work_ollama"
  echo "  Deep Model: $work_deep"
  echo ""
  
  echo -e "${BOLD}🏠 Home Mode:${NC}"
  local home_backend=$(grep "^HOME_AI_BACKEND=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  local home_lm=$(grep "^HOME_LM_STUDIO_CHAT_MODEL=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  local home_ollama=$(grep "^HOME_OLLAMA_CHAT_MODEL=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  local home_deep=$(grep "^HOME_DEEP_MODEL_NAME=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "<not set>")
  
  echo "  Backend: $home_backend"
  echo "  LM Studio Model: $home_lm"
  echo "  Ollama Model: $home_ollama"
  echo "  Deep Model: $home_deep"
  echo ""
  
  echo "Press Enter to continue..."
  read
}

clear_mode_ai_settings() {
  local config_file="$1"
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔄 Clear Mode-Specific AI Settings${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "This will remove all mode-specific settings and use defaults."
  echo ""
  echo "What would you like to clear?"
  echo ""
  echo "  1) Clear Work Mode settings only"
  echo "  2) Clear Home Mode settings only"
  echo "  3) Clear all mode-specific settings"
  echo ""
  echo -e "${YELLOW}0)${NC} Cancel"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      # Clear work settings
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/^WORK_AI_BACKEND=/d' "$config_file"
        sed -i '' '/^WORK_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^WORK_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^WORK_DEEP_MODEL_NAME=/d' "$config_file"
      else
        sed -i '/^WORK_AI_BACKEND=/d' "$config_file"
        sed -i '/^WORK_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '/^WORK_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '/^WORK_DEEP_MODEL_NAME=/d' "$config_file"
      fi
      echo ""
      echo -e "${GREEN}✅ Work mode settings cleared${NC}"
      ;;
    2)
      # Clear home settings
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/^HOME_AI_BACKEND=/d' "$config_file"
        sed -i '' '/^HOME_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^HOME_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^HOME_DEEP_MODEL_NAME=/d' "$config_file"
      else
        sed -i '/^HOME_AI_BACKEND=/d' "$config_file"
        sed -i '/^HOME_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '/^HOME_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '/^HOME_DEEP_MODEL_NAME=/d' "$config_file"
      fi
      echo ""
      echo -e "${GREEN}✅ Home mode settings cleared${NC}"
      ;;
    3)
      # Clear all
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/^WORK_AI_BACKEND=/d' "$config_file"
        sed -i '' '/^WORK_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^WORK_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^WORK_DEEP_MODEL_NAME=/d' "$config_file"
        sed -i '' '/^HOME_AI_BACKEND=/d' "$config_file"
        sed -i '' '/^HOME_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^HOME_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '' '/^HOME_DEEP_MODEL_NAME=/d' "$config_file"
      else
        sed -i '/^WORK_AI_BACKEND=/d' "$config_file"
        sed -i '/^WORK_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '/^WORK_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '/^WORK_DEEP_MODEL_NAME=/d' "$config_file"
        sed -i '/^HOME_AI_BACKEND=/d' "$config_file"
        sed -i '/^HOME_LM_STUDIO_CHAT_MODEL=/d' "$config_file"
        sed -i '/^HOME_OLLAMA_CHAT_MODEL=/d' "$config_file"
        sed -i '/^HOME_DEEP_MODEL_NAME=/d' "$config_file"
      fi
      echo ""
      echo -e "${GREEN}✅ All mode-specific settings cleared${NC}"
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

config_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚙️  Configuration & Setup${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_config_guide
  echo "What would you like to configure?"
  echo ""
  echo "  1) 🤖 Switch AI Backend (LM Studio ↔ Ollama)"
  echo "  2) 🎯 Configure Mode-Specific AI (Work vs Home)"
  echo "  3) 🔍 Check AI Backend Status"
  echo "  4) 📋 View Current Configuration"
  echo "  5) 📖 Installation Instructions"
  echo "  6) 🔧 Setup MCP Server & Virtualenv"
  echo "  7) 🤖 Manage AI Models (Check & Load)"
  echo "  8) ✏️  Edit Configuration Files (via vim)"
  echo "  9) 🐰 Setup RabbitMQ Connection"
  echo "  10) 📁 Setup Vector Filewatcher (Auto-queue files)"
  echo "  11) 🧠 Setup Deep Analysis Auto-Scheduler (Auto-submit jobs)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read config_choice
  
  case "$config_choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🤖 Switch AI Backend${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Find config files
      GTD_CONFIG="$HOME/.gtd_config"
      DAILY_LOG_CONFIG="$HOME/.daily_log_config"
      
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/personal/dotfiles/zsh/.gtd_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/dotfiles/zsh/.gtd_config"
      fi
      
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.daily_log_config" ]]; then
        DAILY_LOG_CONFIG="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.daily_log_config" ]]; then
        DAILY_LOG_CONFIG="$HOME/code/dotfiles/zsh/.daily_log_config"
      fi
      
      # Read current backend
      current_backend="lmstudio"
      if [[ -f "$GTD_CONFIG" ]]; then
        if grep -q '^AI_BACKEND=' "$GTD_CONFIG" 2>/dev/null; then
          current_backend=$(grep '^AI_BACKEND=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
        fi
      elif [[ -f "$DAILY_LOG_CONFIG" ]]; then
        if grep -q '^AI_BACKEND=' "$DAILY_LOG_CONFIG" 2>/dev/null; then
          current_backend=$(grep '^AI_BACKEND=' "$DAILY_LOG_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
        fi
      fi
      
      echo -e "Current backend: ${BOLD}${current_backend}${NC}"
      echo ""
      echo "Which backend would you like to use?"
      echo ""
      echo "  1) LM Studio (default: http://localhost:1234)"
      echo "  2) Ollama (default: http://localhost:11434)"
      echo ""
      echo -n "Choose: "
      read backend_choice
      
      new_backend=""
      case "$backend_choice" in
        1)
          new_backend="lmstudio"
          ;;
        2)
          new_backend="ollama"
          ;;
        *)
          echo "❌ Invalid choice"
          echo ""
          echo "Press Enter to continue..."
          read
          return
          ;;
      esac
      
      if [[ "$current_backend" == "$new_backend" ]]; then
        echo ""
        echo "✅ Already using $new_backend. No changes needed."
      else
        echo ""
        echo "Switching to $new_backend..."
        
        # Update GTD config
        if [[ -f "$GTD_CONFIG" ]]; then
          if grep -q '^AI_BACKEND=' "$GTD_CONFIG" 2>/dev/null; then
            # Update existing line
            if [[ "$(uname)" == "Darwin" ]]; then
              sed -i '' "s/^AI_BACKEND=.*/AI_BACKEND=\"$new_backend\"/" "$GTD_CONFIG"
            else
              sed -i "s/^AI_BACKEND=.*/AI_BACKEND=\"$new_backend\"/" "$GTD_CONFIG"
            fi
          else
            # Add new line after the AI Backend Configuration comment
            if grep -q '# AI Backend Configuration' "$GTD_CONFIG" 2>/dev/null; then
              if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "/# AI Backend Configuration/a\\
AI_BACKEND=\"$new_backend\"
" "$GTD_CONFIG"
              else
                sed -i "/# AI Backend Configuration/a AI_BACKEND=\"$new_backend\"" "$GTD_CONFIG"
              fi
            else
              # Add at the beginning of LM Studio section
              if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "/^# ============================================================================$/a\\
# AI backend to use: \"lmstudio\" or \"ollama\" (default: \"lmstudio\")\\
AI_BACKEND=\"$new_backend\"
" "$GTD_CONFIG"
              else
                sed -i "/^# ============================================================================$/a # AI backend to use: \"lmstudio\" or \"ollama\" (default: \"lmstudio\")\nAI_BACKEND=\"$new_backend\"" "$GTD_CONFIG"
              fi
            fi
          fi
          echo "✅ Updated $GTD_CONFIG"
        fi
        
        # Update daily log config
        if [[ -f "$DAILY_LOG_CONFIG" ]]; then
          if grep -q '^AI_BACKEND=' "$DAILY_LOG_CONFIG" 2>/dev/null; then
            # Update existing line
            if [[ "$(uname)" == "Darwin" ]]; then
              sed -i '' "s/^AI_BACKEND=.*/AI_BACKEND=\"$new_backend\"/" "$DAILY_LOG_CONFIG"
            else
              sed -i "s/^AI_BACKEND=.*/AI_BACKEND=\"$new_backend\"/" "$DAILY_LOG_CONFIG"
            fi
          else
            # Add after first line or at top
            if [[ "$(uname)" == "Darwin" ]]; then
              sed -i '' "1a\\
AI_BACKEND=\"$new_backend\"
" "$DAILY_LOG_CONFIG"
            else
              sed -i "1i AI_BACKEND=\"$new_backend\"" "$DAILY_LOG_CONFIG"
            fi
          fi
          echo "✅ Updated $DAILY_LOG_CONFIG"
        fi
        
        echo ""
        echo -e "${GREEN}✅ Successfully switched to $new_backend!${NC}"
        echo ""
        echo "Note: You may need to restart your terminal or reload your config for changes to take effect."
      fi
      ;;
    2)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🔍 AI Backend Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check current backend
      GTD_CONFIG="$HOME/.gtd_config"
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/personal/dotfiles/zsh/.gtd_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/dotfiles/zsh/.gtd_config"
      fi
      
      current_backend="lmstudio"
      if [[ -f "$GTD_CONFIG" ]]; then
        if grep -q '^AI_BACKEND=' "$GTD_CONFIG" 2>/dev/null; then
          current_backend=$(grep '^AI_BACKEND=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
        fi
      fi
      
      echo -e "${BOLD}Configured Backend:${NC} $current_backend"
      echo ""
      
      # Check LM Studio
      echo -e "${BOLD}LM Studio:${NC}"
      if curl -s "http://localhost:1234/v1/models" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Running${NC}"
        models=$(curl -s "http://localhost:1234/v1/models" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', 'unknown')[:30] for m in data.get('data', [])[:3]]))" 2>/dev/null || echo "unknown")
        echo "  Models: $models"
      else
        echo -e "  ${RED}❌ Not running${NC}"
      fi
      echo ""
      
      # Check Ollama
      echo -e "${BOLD}Ollama:${NC}"
      if curl -s "http://localhost:11434/v1/models" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Running${NC}"
        models=$(curl -s "http://localhost:11434/v1/models" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', 'unknown')[:30] for m in data.get('data', [])[:3]]))" 2>/dev/null || echo "unknown")
        echo "  Models: $models"
      else
        echo -e "  ${RED}❌ Not running${NC}"
        if command -v ollama &>/dev/null; then
          echo "  → Ollama is installed but not running. Start with: ollama serve"
        else
          echo "  → Ollama is not installed"
        fi
      fi
      echo ""
      
      if [[ "$current_backend" == "ollama" ]]; then
        if ! curl -s "http://localhost:11434/v1/models" >/dev/null 2>&1; then
          echo -e "${YELLOW}⚠️  Warning:${NC} You're configured to use Ollama, but it's not running."
          echo "  Start it with: ollama serve"
        fi
      else
        if ! curl -s "http://localhost:1234/v1/models" >/dev/null 2>&1; then
          echo -e "${YELLOW}⚠️  Warning:${NC} You're configured to use LM Studio, but it's not running."
          echo "  Open LM Studio and start the local server."
        fi
      fi
      ;;
    4)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📋 Current Configuration${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      GTD_CONFIG="$HOME/.gtd_config"
      DAILY_LOG_CONFIG="$HOME/.daily_log_config"
      
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/personal/dotfiles/zsh/.gtd_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/dotfiles/zsh/.gtd_config"
      fi
      
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.daily_log_config" ]]; then
        DAILY_LOG_CONFIG="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.daily_log_config" ]]; then
        DAILY_LOG_CONFIG="$HOME/code/dotfiles/zsh/.daily_log_config"
      fi
      
      echo -e "${BOLD}GTD Config:${NC} $GTD_CONFIG"
      if [[ -f "$GTD_CONFIG" ]]; then
        echo -e "  ${GREEN}✅ Found${NC}"
        if grep -q '^AI_BACKEND=' "$GTD_CONFIG" 2>/dev/null; then
          backend=$(grep '^AI_BACKEND=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
          echo "  AI_BACKEND: $backend"
        fi
        if grep -q '^LM_STUDIO_URL=' "$GTD_CONFIG" 2>/dev/null; then
          url=$(grep '^LM_STUDIO_URL=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
          echo "  LM_STUDIO_URL: $url"
        fi
        if grep -q '^OLLAMA_URL=' "$GTD_CONFIG" 2>/dev/null; then
          url=$(grep '^OLLAMA_URL=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
          echo "  OLLAMA_URL: $url"
        fi
      else
        echo -e "  ${RED}❌ Not found${NC}"
      fi
      echo ""
      
      echo -e "${BOLD}Daily Log Config:${NC} $DAILY_LOG_CONFIG"
      if [[ -f "$DAILY_LOG_CONFIG" ]]; then
        echo -e "  ${GREEN}✅ Found${NC}"
        if grep -q '^AI_BACKEND=' "$DAILY_LOG_CONFIG" 2>/dev/null; then
          backend=$(grep '^AI_BACKEND=' "$DAILY_LOG_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
          echo "  AI_BACKEND: $backend"
        fi
      else
        echo -e "  ${RED}❌ Not found${NC}"
      fi
      ;;
    5)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📖 Installation Instructions${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "${BOLD}LM Studio:${NC}"
      echo "  1. Download from: https://lmstudio.ai/"
      echo "  2. Install and open LM Studio"
      echo "  3. Download a model (Search tab → Download)"
      echo "  4. Load the model (Chat tab → Select model → Load)"
      echo "  5. Start local server (Server tab → Start Server)"
      echo "  6. Default port: 1234"
      echo ""
      echo -e "${BOLD}Ollama:${NC}"
      echo "  1. Install:"
      echo "     macOS: brew install ollama"
      echo "     Linux: curl -fsSL https://ollama.com/install.sh | sh"
      echo "  2. Start server: ollama serve"
      echo "  3. Pull a model: ollama pull gemma2:1b"
      echo "  4. List models: ollama list"
      echo "  5. Default port: 11434"
      echo ""
      echo -e "${BOLD}Switching Backends:${NC}"
      echo "  Use option 1 in this menu to switch between backends"
      echo "  Or edit config files directly:"
      echo "    ~/.gtd_config"
      echo "    ~/.daily_log_config"
      echo "  Set: AI_BACKEND=\"lmstudio\" or AI_BACKEND=\"ollama\""
      ;;
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🔧 Setup MCP Server & Virtualenv${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Find MCP directory
      MCP_DIR="$HOME/code/dotfiles/mcp"
      if [[ ! -d "$MCP_DIR" ]]; then
        MCP_DIR="$HOME/code/personal/dotfiles/mcp"
      fi
      
      SETUP_SCRIPT="${MCP_DIR}/setup.sh"
      
      if [[ ! -f "$SETUP_SCRIPT" ]]; then
        echo -e "${RED}❌ MCP setup script not found${NC}"
        echo ""
        echo "Expected at: $SETUP_SCRIPT"
        echo ""
        echo "Make sure the MCP directory exists and contains setup.sh"
        echo ""
        echo "Press Enter to continue..."
        read
        return 0
      fi
      
      # Check if virtualenv already exists
      VENV_DIR="${MCP_DIR}/venv"
      if [[ -d "$VENV_DIR" ]]; then
        echo -e "${YELLOW}⚠️  Virtualenv already exists at:${NC}"
        echo "   $VENV_DIR"
        echo ""
        echo "Options:"
        echo "  1) Re-run setup (update dependencies)"
        echo "  2) Skip setup"
        echo ""
        echo -n "Choose (1 or 2): "
        read setup_choice
        
        if [[ "$setup_choice" != "1" ]]; then
          echo "Skipping setup."
          echo ""
          echo "Press Enter to continue..."
          read
          return 0
        fi
      fi
      
      echo "This will:"
      echo "  1. Create a Python virtualenv for MCP scripts"
      echo "  2. Install required dependencies (mcp package, etc.)"
      echo "  3. Test that everything works"
      echo ""
      echo -e "${YELLOW}Note:${NC} This may take a few minutes to download and install packages."
      echo ""
      echo -n "Continue? (y/N): "
      read confirm
      
      if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Setup cancelled."
        echo ""
        echo "Press Enter to continue..."
        read
        return 0
      fi
      
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      
      # Run setup script
      if bash "$SETUP_SCRIPT"; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${GREEN}✅ MCP Server setup complete!${NC}"
        echo ""
        
        # Verify setup
        MCP_PYTHON=$(gtd_get_mcp_python)
        if [[ -n "$MCP_PYTHON" ]] && "$MCP_PYTHON" -c "import mcp" 2>/dev/null; then
          echo -e "${GREEN}✅ Verification successful!${NC}"
          echo "   MCP SDK is installed and working."
          if [[ "$MCP_PYTHON" == *"/venv/bin/python3" ]]; then
            echo "   Using virtualenv: $VENV_DIR"
          fi
        else
          echo -e "${YELLOW}⚠️  Warning:${NC} MCP SDK verification failed."
          echo "   Try running the setup script manually:"
          echo "   cd $MCP_DIR && ./setup.sh"
        fi
        
        echo ""
        echo "Next steps:"
        echo "  1. Configure MCP server in Cursor (see mcp/README.md)"
        echo "  2. Start LM Studio or Ollama"
        echo "  3. (Optional) Set up Vector Filewatcher for auto-vectorization"
        echo "  4. Test with: Generate banter for log entry (option 4 in AI Suggestions menu)"
        echo ""
        echo -n "Would you like to configure the Vector Filewatcher now? (y/n): "
        read setup_filewatcher
        
        if [[ "$setup_filewatcher" == "y" || "$setup_filewatcher" == "Y" ]]; then
          echo ""
          echo "Installing watchdog (required for filewatcher)..."
          VENV_PIP="$VENV_DIR/bin/pip"
          if [[ -f "$VENV_PIP" ]]; then
            "$VENV_PIP" install watchdog
            echo "✅ watchdog installed"
          else
            echo "⚠️  Could not install watchdog automatically"
          fi
          
          echo ""
          echo "Filewatcher can monitor directories and automatically queue files for vectorization."
          echo "You can configure it later via: Configuration & Setup → Setup Vector Filewatcher"
        fi
      else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${RED}❌ Setup failed${NC}"
        echo ""
        echo "Check the error messages above. Common issues:"
        echo "  • Python 3 not installed (install with: brew install python3)"
        echo "  • Network issues (check internet connection)"
        echo "  • Permission issues (check file permissions)"
      echo ""
      echo "You can try running the setup manually:"
      echo "  cd $MCP_DIR && ./setup.sh"
      fi
      ;;
    7)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🤖 Manage AI Models${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check current backend
      GTD_CONFIG="$HOME/.gtd_config"
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/personal/dotfiles/zsh/.gtd_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/dotfiles/zsh/.gtd_config"
      fi
      
      current_backend="lmstudio"
      if [[ -f "$GTD_CONFIG" ]]; then
        if grep -q '^AI_BACKEND=' "$GTD_CONFIG" 2>/dev/null; then
          current_backend=$(grep '^AI_BACKEND=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
        fi
      fi
      
      echo -e "${BOLD}Current Backend:${NC} ${CYAN}$current_backend${NC}"
      echo ""
      
      if [[ "$current_backend" == "lmstudio" ]]; then
        echo -e "${BOLD}LM Studio Model Status:${NC}"
        echo ""
        
        # Check if LM Studio is running
        if curl -s "http://localhost:1234/v1/models" >/dev/null 2>&1; then
          echo -e "${GREEN}✅ LM Studio server is running${NC}"
          echo ""
          
          # Get available models
          models_json=$(curl -s "http://localhost:1234/v1/models" 2>/dev/null)
          if [[ -n "$models_json" ]]; then
            available_models=$(echo "$models_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('data', [])
    if models:
        print('Available models:')
        for m in models:
            model_id = m.get('id', 'unknown')
            print(f'  • {model_id}')
    else:
        print('No models loaded')
except:
    print('Could not parse model list')
" 2>/dev/null || echo "Could not retrieve models")
            
            echo "$available_models"
            echo ""
            
            # Check configured model
            configured_model=""
            if [[ -f "$GTD_CONFIG" ]]; then
              if grep -q '^GTD_DEEP_MODEL_NAME=' "$GTD_CONFIG" 2>/dev/null; then
                configured_model=$(grep '^GTD_DEEP_MODEL_NAME=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
              elif grep -q '^LM_STUDIO_MODEL=' "$GTD_CONFIG" 2>/dev/null; then
                configured_model=$(grep '^LM_STUDIO_MODEL=' "$GTD_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
              fi
            fi
            
            if [[ -z "$configured_model" ]]; then
              configured_model="gpt-oss-20b"  # Default
            fi
            
            echo -e "${BOLD}Configured Model:${NC} ${CYAN}$configured_model${NC}"
            echo ""
            
            # Check if configured model is in the list
            if echo "$available_models" | grep -q "$configured_model"; then
              echo -e "${GREEN}✅ Configured model is loaded${NC}"
            else
              echo -e "${YELLOW}⚠️  Configured model '$configured_model' is not loaded${NC}"
              echo ""
              echo "To fix this:"
              echo "  1. Open LM Studio"
              echo "  2. Go to Chat tab"
              echo -e "  3. Find and load the model: ${CYAN}$configured_model${NC}"
              echo "  4. Or update your config to use one of the loaded models above"
            fi
          else
            echo -e "${YELLOW}⚠️  Could not retrieve model list${NC}"
          fi
        else
          echo -e "${RED}❌ LM Studio server is not running${NC}"
          echo ""
          echo "To start LM Studio:"
          echo "  1. Open LM Studio application"
          echo "  2. Go to Server tab"
          echo "  3. Click 'Start Server'"
          echo "  4. Make sure a model is loaded (Chat tab → Load model)"
        fi
        
        echo ""
        echo -e "${BOLD}How to Load a Model in LM Studio:${NC}"
        echo ""
        echo "  1. Open LM Studio application"
        echo -e "  2. Go to the ${CYAN}Chat${NC} tab (or Models tab)"
        echo "  3. Find your model in the list"
        echo "  4. Click on the model"
        echo -e "  5. Click the ${CYAN}Load${NC} button (or double-click)"
        echo "  6. Wait for it to load (you'll see a progress indicator)"
        echo ""
        echo "Note: Models must be downloaded first (Search tab → Download)"
        echo ""
        echo "To open LM Studio now:"
        echo -n "  Open LM Studio? (y/n): "
        read open_lm
        if [[ "$open_lm" == "y" || "$open_lm" == "Y" ]]; then
          open -a "LM Studio" 2>/dev/null || echo "Could not open LM Studio"
        fi
      fi
      ;;
    8)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}✏️  Edit Configuration Files${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Find config directory
      GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
      if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
        GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
      fi
      
      # If still not found, try home directory
      if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
        GTD_CONFIG_DIR="$HOME"
      fi
      
      # Define config files with descriptions
      declare -a config_files=(
        ".gtd_config:Main configuration file (backwards compatible)"
        ".gtd_config_core:Core settings (user name, directories, templates)"
        ".gtd_config_ai:AI backend configuration (LM Studio, Ollama, personas)"
        ".gtd_config_capture:Capture and processing settings"
        ".gtd_config_reviews:Review system settings (daily/weekly review)"
        ".gtd_config_integrations:External integrations (Second Brain, email)"
        ".gtd_config_calendar:Calendar integration (Google Calendar, Office 365)"
        ".gtd_config_notifications:Notifications and reminders"
        ".gtd_config_advanced:Advanced features and analytics"
        ".gtd_config_custom:Custom user overrides (highest priority)"
      )
      
      # Build menu
      declare -a file_paths
      local file_num=1
      
      echo "Available configuration files:"
      echo ""
      for config_entry in "${config_files[@]}"; do
        local file_name="${config_entry%%:*}"
        local file_desc="${config_entry#*:}"
        local file_path="${GTD_CONFIG_DIR}/${file_name}"
        
        file_paths+=("$file_path")
        
        # Check if file exists
        if [[ -f "$file_path" ]]; then
          echo -e "  ${GREEN}${file_num})${NC} ${BOLD}${file_name}${NC}"
          echo "     ${file_desc}"
          echo -e "     ${CYAN}Location:${NC} $file_path"
        else
          echo -e "  ${YELLOW}${file_num})${NC} ${file_name} ${YELLOW}(does not exist - will be created)${NC}"
          echo "     ${file_desc}"
          echo -e "     ${CYAN}Location:${NC} $file_path"
        fi
        echo ""
        ((file_num++))
      done
      
      echo -e "${YELLOW}0)${NC} Back to Configuration Menu"
      echo ""
      echo -n "Choose a file to edit: "
      read edit_choice
      
      if [[ -z "$edit_choice" || "$edit_choice" == "0" ]]; then
        return 0
      fi
      
      # Validate choice
      if ! [[ "$edit_choice" =~ ^[0-9]+$ ]] || [[ $edit_choice -lt 1 ]] || [[ $edit_choice -gt ${#config_files[@]} ]]; then
        echo "❌ Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        return 0
      fi
      
      local selected_index=$((edit_choice - 1))
      local selected_file="${file_paths[$selected_index]}"
      local file_name=$(basename "$selected_file")
      
      # Check if vim is available
      if ! command -v vim &>/dev/null; then
        echo "❌ vim not found. Please install vim to edit configuration files."
        echo ""
        echo "Press Enter to continue..."
        read
        return 0
      fi
      
      # Create directory if it doesn't exist
      local file_dir=$(dirname "$selected_file")
      if [[ ! -d "$file_dir" ]]; then
        echo "Creating directory: $file_dir"
        mkdir -p "$file_dir"
      fi
      
      # Create file if it doesn't exist (with basic template)
      if [[ ! -f "$selected_file" ]]; then
        echo "Creating new configuration file: $selected_file"
        {
          echo "# ============================================================================"
          echo "# $(echo "$file_name" | tr '[:lower:]' '[:upper:]' | tr '_' ' ' | sed 's/^\.GTD/GTD/')"
          echo "# ============================================================================"
          echo "# This file was created via the GTD wizard"
          echo "# Edit this file to customize your GTD system settings"
          echo ""
        } > "$selected_file"
      fi
      
      echo ""
      echo -e "${CYAN}Opening ${BOLD}${file_name}${NC}${CYAN} in vim...${NC}"
      echo -e "${YELLOW}Tip:${NC} When done editing, save with ${BOLD}:wq${NC} or exit without saving with ${BOLD}:q!${NC}"
      echo ""
      echo "Press Enter to continue..."
      read
      
      # Edit file with vim
      if vim "$selected_file"; then
        echo ""
        echo -e "${GREEN}✅ Configuration file updated!${NC}"
        echo ""
        echo -e "${YELLOW}Note:${NC} You may need to restart your terminal or reload your config for changes to take effect."
        echo ""
        echo "To reload config in current session, run:"
        echo "  source \"$selected_file\""
      else
        echo ""
        echo -e "${YELLOW}⚠️  File editing cancelled or failed${NC}"
      fi
      ;;
    9)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🐰 Setup RabbitMQ Connection${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Find config directory
      GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
      if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
        GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
      fi
      
      CONFIG_DB_FILE="${GTD_CONFIG_DIR}/.gtd_config_database"
      
      echo "RabbitMQ Setup Options:"
      echo ""
      echo "  1) 🔍 Test RabbitMQ Connection"
      echo "  2) 🔌 Start Port-Forward (for Kubernetes RabbitMQ)"
      echo "  3) ⚙️  Configure RabbitMQ Credentials"
      echo "  4) 📋 View Current RabbitMQ Configuration"
      echo "  5) 📊 View RabbitMQ Queue Status"
      echo ""
      echo -e "${YELLOW}0)${NC} Back"
      echo ""
      echo -n "Choose: "
      read rabbitmq_choice
      
      case "$rabbitmq_choice" in
        1)
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          
          # Check if test script exists
          TEST_SCRIPT="$HOME/code/dotfiles/bin/test_rabbitmq_connection.sh"
          if [[ ! -f "$TEST_SCRIPT" ]]; then
            TEST_SCRIPT="$HOME/code/personal/dotfiles/bin/test_rabbitmq_connection.sh"
          fi
          
          if [[ -f "$TEST_SCRIPT" ]]; then
            bash "$TEST_SCRIPT"
          else
            echo -e "${RED}❌ Test script not found${NC}"
            echo "Expected at: $TEST_SCRIPT"
          fi
          ;;
        2)
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          
          # Use the enhanced setup script if available
          SETUP_SCRIPT="$HOME/code/dotfiles/bin/setup_rabbitmq_local.sh"
          if [[ ! -f "$SETUP_SCRIPT" ]]; then
            SETUP_SCRIPT="$HOME/code/personal/dotfiles/bin/setup_rabbitmq_local.sh"
          fi
          
          if [[ -f "$SETUP_SCRIPT" ]]; then
            echo -e "${GREEN}Using enhanced port-forward script...${NC}"
            echo ""
            bash "$SETUP_SCRIPT"
          else
            # Fallback to direct kubectl command
            echo "Starting RabbitMQ port-forward..."
            echo ""
            
            # Check if kubectl is available
            if ! command -v kubectl &> /dev/null; then
              echo -e "${RED}❌ kubectl not found${NC}"
              echo "kubectl is required for port-forwarding to Kubernetes RabbitMQ."
              echo ""
              echo "Press Enter to continue..."
              read
              return 0
            fi
            
            # Check if RabbitMQ service exists
            if ! kubectl get svc -n rabbitmq-system rabbitmq &> /dev/null; then
              echo -e "${YELLOW}⚠️  RabbitMQ service not found in rabbitmq-system namespace${NC}"
              echo ""
              echo "Available RabbitMQ services:"
              kubectl get svc -A | grep rabbitmq || echo "  None found"
              echo ""
              echo "Press Enter to continue..."
              read
              return 0
            fi
            
            echo -e "${GREEN}Starting port-forward...${NC}"
            echo ""
            echo "Ports being forwarded:"
            echo "  📨 AMQP: localhost:5672 → rabbitmq:5672 (for queue connections)"
            echo "  🌐 Management UI: localhost:15672 → rabbitmq:15672 (web interface)"
            echo "  📊 Prometheus: localhost:15692 → rabbitmq:15692 (metrics)"
            echo ""
            echo -e "${YELLOW}Note:${NC} This will run in the foreground. Press Ctrl+C to stop."
            echo ""
            echo "Press Enter to start..."
            read
            
            kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672 15672:15672 15692:15692
          fi
          ;;
        3)
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          
          # Load current config
          if [[ -f "$CONFIG_DB_FILE" ]]; then
            source "$CONFIG_DB_FILE"
          fi
          
          # Get current values
          CURRENT_URL="${RABBITMQ_URL:-amqp://localhost:5672}"
          CURRENT_USER="${RABBITMQ_USER:-guest}"
          CURRENT_PASS="${RABBITMQ_PASS:-guest}"
          
          echo "Current RabbitMQ Configuration:"
          echo "  URL: $CURRENT_URL"
          echo "  User: $CURRENT_USER"
          echo "  Password: ${CURRENT_PASS:+***}"
          echo ""
          echo "Enter new values (press Enter to keep current):"
          echo ""
          
          echo -n "RabbitMQ URL [$CURRENT_URL]: "
          read new_url
          new_url="${new_url:-$CURRENT_URL}"
          
          echo -n "RabbitMQ Username [$CURRENT_USER]: "
          read new_user
          new_user="${new_user:-$CURRENT_USER}"
          
          echo -n "RabbitMQ Password [${CURRENT_PASS:+***}]: "
          read -s new_pass
          echo ""
          new_pass="${new_pass:-$CURRENT_PASS}"
          
          # Create config file if it doesn't exist
          if [[ ! -f "$CONFIG_DB_FILE" ]]; then
            mkdir -p "$GTD_CONFIG_DIR"
            echo "# RabbitMQ Configuration" > "$CONFIG_DB_FILE"
          fi
          
          # Update or add RabbitMQ config
          if grep -q "^RABBITMQ_URL=" "$CONFIG_DB_FILE" 2>/dev/null; then
            sed -i.bak "s|^RABBITMQ_URL=.*|RABBITMQ_URL=\"${new_url}\"|" "$CONFIG_DB_FILE"
          else
            echo "RABBITMQ_URL=\"${new_url}\"" >> "$CONFIG_DB_FILE"
          fi
          
          if grep -q "^RABBITMQ_USER=" "$CONFIG_DB_FILE" 2>/dev/null; then
            sed -i.bak "s|^RABBITMQ_USER=.*|RABBITMQ_USER=\"${new_user}\"|" "$CONFIG_DB_FILE"
          else
            echo "RABBITMQ_USER=\"${new_user}\"" >> "$CONFIG_DB_FILE"
          fi
          
          if grep -q "^RABBITMQ_PASS=" "$CONFIG_DB_FILE" 2>/dev/null; then
            sed -i.bak "s|^RABBITMQ_PASS=.*|RABBITMQ_PASS=\"${new_pass}\"|" "$CONFIG_DB_FILE"
          else
            echo "RABBITMQ_PASS=\"${new_pass}\"" >> "$CONFIG_DB_FILE"
          fi
          
          # Clean up backup file
          rm -f "${CONFIG_DB_FILE}.bak"
          
          echo ""
          echo -e "${GREEN}✅ RabbitMQ configuration updated!${NC}"
          echo ""
          echo "Configuration saved to: $CONFIG_DB_FILE"
          ;;
        4)
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          
          if [[ -f "$CONFIG_DB_FILE" ]]; then
            echo "RabbitMQ Configuration (from $CONFIG_DB_FILE):"
            echo ""
            grep "^RABBITMQ" "$CONFIG_DB_FILE" | while IFS='=' read -r key value; do
              if [[ "$key" == *"PASS"* ]]; then
                echo "  ${key}=\"***\""
              else
                echo "  ${key}=${value}"
              fi
            done
          else
            echo -e "${YELLOW}⚠️  Configuration file not found${NC}"
            echo "Expected at: $CONFIG_DB_FILE"
            echo ""
            echo "Using defaults:"
            echo "  RABBITMQ_URL=\"amqp://localhost:5672\""
            echo "  RABBITMQ_USER=\"guest\""
            echo "  RABBITMQ_PASS=\"guest\""
          fi
          
          echo ""
          echo "Current Environment Variables:"
          env | grep -i rabbitmq | sed 's/\(.*PASS.*=\).*/\1***/' | sed 's/^/  /' || echo "  (none set)"
          ;;
        5)
          # View RabbitMQ Queue Status
          echo ""
          if [[ -f "$HOME/code/dotfiles/bin/gtd-rabbitmq-status" ]]; then
            "$HOME/code/dotfiles/bin/gtd-rabbitmq-status"
          else
            echo -e "${YELLOW}⚠️  RabbitMQ status script not found${NC}"
          fi
          ;;
        0|"")
          return 0
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
          ;;
    10)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📁 Setup Vector Filewatcher${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "The filewatcher automatically monitors directories and queues files"
      echo "for vectorization when they're created or modified."
      echo ""
      echo "Filewatcher Options:"
      echo ""
      echo "  1) 📋 View Current Filewatcher Configuration"
      echo "  2) ⚙️  Configure Watch Directories"
      echo "  3) 🔗 Setup Symlinks for External Directories"
      echo "  4) 📁 Configure Watched Directory Location (for symlinks)"
      echo "  5) ▶️  Start Filewatcher"
      echo "  6) ⏹️  Stop Filewatcher"
      echo "  7) 📊 Check Filewatcher Status"
      echo "  8) 📦 Install Required Dependencies (watchdog)"
      echo ""
      echo -e "${YELLOW}0)${NC} Back"
      echo ""
      echo -n "Choose: "
      read filewatcher_choice
      
      # Find Python and config paths
      MCP_VENV_PYTHON="$HOME/code/dotfiles/mcp/venv/bin/python3"
      if [[ ! -f "$MCP_VENV_PYTHON" ]]; then
        MCP_VENV_PYTHON="$HOME/code/personal/dotfiles/mcp/venv/bin/python3"
      fi
      MCP_VENV_DIR="${MCP_VENV_PYTHON%/bin/python3}"
      if [[ -f "$MCP_VENV_PYTHON" ]]; then
        PYTHON_CMD="$MCP_VENV_PYTHON"
      else
        PYTHON_CMD="python3"
        MCP_VENV_DIR=""
      fi
      
      GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
      if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
        GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
      fi
      CONFIG_DB_FILE="${GTD_CONFIG_DIR}/.gtd_config_database"
      
      case "$filewatcher_choice" in
            1)
              echo ""
              echo -e "${BOLD}Current Filewatcher Configuration:${NC}"
              echo ""
              
              if [[ -f "$CONFIG_DB_FILE" ]]; then
                source "$CONFIG_DB_FILE"
              fi
              
              # Also load GTD config for defaults
              GTD_CONFIG_FILE="$HOME/.gtd_config"
              if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
                source "$HOME/code/dotfiles/zsh/.gtd_config"
              elif [[ -f "$GTD_CONFIG_FILE" ]]; then
                source "$GTD_CONFIG_FILE"
              fi
              
              echo "Watch Directories:"
              if [[ -n "${VECTOR_WATCH_DIRS:-}" ]]; then
                echo "$VECTOR_WATCH_DIRS" | tr ',' '\n' | sed 's/^/  📂 /'
              else
                echo -e "  ${CYAN}Using defaults:${NC}"
                echo -e "    📂 ${GTD_BASE_DIR:-$HOME/Documents/gtd}"
                echo -e "    📂 ${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
              fi
              echo ""
              echo "Watched Directory (for symlinks): ${VECTOR_WATCH_DIR:-$HOME/Documents/gtd/watched}"
              echo "Filewatcher Enabled: ${VECTOR_FILEWATCHER_ENABLED:-false}"
              echo "Vectorization Enabled: ${GTD_VECTORIZATION_ENABLED:-true}"
              echo ""
              
              # Check if running
              if pgrep -f "gtd_vector_filewatcher.py" >/dev/null; then
                pid=$(pgrep -f "gtd_vector_filewatcher.py")
                echo -e "${GREEN}✅ Filewatcher running (PID: $pid)${NC}"
              else
                echo -e "${CYAN}ℹ️  Filewatcher not running${NC}"
              fi
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            2)
              echo ""
              echo -e "${BOLD}Configure Watch Directories:${NC}"
              echo ""
              echo "Enter directories to watch (comma-separated):"
              echo "Example: $HOME/Documents/gtd,$HOME/Documents/daily_logs"
              echo ""
              echo "The filewatcher will monitor these directories for new/modified files"
              echo "and automatically queue them for vectorization."
              echo ""
              
              if [[ -f "$CONFIG_DB_FILE" ]]; then
                source "$CONFIG_DB_FILE"
              fi
              
              # Also load GTD config for defaults
              if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
                source "$HOME/code/dotfiles/zsh/.gtd_config"
              elif [[ -f "$HOME/.gtd_config" ]]; then
                source "$HOME/.gtd_config"
              fi
              
              CURRENT_DIRS="${VECTOR_WATCH_DIRS:-}"
              if [[ -z "$CURRENT_DIRS" ]]; then
                CURRENT_DIRS="${GTD_BASE_DIR:-$HOME/Documents/gtd},${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
              fi
              
              echo -n "Watch directories [$CURRENT_DIRS]: "
              read new_dirs
              new_dirs="${new_dirs:-$CURRENT_DIRS}"
              
              # Create config file if needed
              if [[ ! -f "$CONFIG_DB_FILE" ]]; then
                mkdir -p "$GTD_CONFIG_DIR"
                touch "$CONFIG_DB_FILE"
              fi
              
              # Update or add VECTOR_WATCH_DIRS
              if grep -q "^VECTOR_WATCH_DIRS=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^VECTOR_WATCH_DIRS=.*|VECTOR_WATCH_DIRS=\"${new_dirs}\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^VECTOR_WATCH_DIRS=.*|VECTOR_WATCH_DIRS=\"${new_dirs}\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "" >> "$CONFIG_DB_FILE"
                echo "# Vector Filewatcher Configuration" >> "$CONFIG_DB_FILE"
                echo "VECTOR_WATCH_DIRS=\"${new_dirs}\"" >> "$CONFIG_DB_FILE"
              fi
              
              # Enable filewatcher if not set
              if ! grep -q "^VECTOR_FILEWATCHER_ENABLED=" "$CONFIG_DB_FILE" 2>/dev/null; then
                echo "VECTOR_FILEWATCHER_ENABLED=\"${VECTOR_FILEWATCHER_ENABLED:-true}\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo ""
              echo -e "${GREEN}✅ Configuration updated!${NC}"
              echo "   Updated: $CONFIG_DB_FILE"
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            3)
              echo ""
              echo -e "${BOLD}Setup Symlinks for External Directories:${NC}"
              echo ""
              echo "This will help you set up symlinks so the filewatcher can monitor"
              echo "external directories (like ones outside ~/Documents/gtd)."
              echo ""
              
              # Load current config
              if [[ -f "$CONFIG_DB_FILE" ]]; then
                source "$CONFIG_DB_FILE"
              fi
              
              # Get watched directory location (default or configured)
              WATCHED_DIR="${VECTOR_WATCH_DIR:-$HOME/Documents/gtd/watched}"
              
              echo "Watched directory location: $WATCHED_DIR"
              echo ""
              echo "We'll create this directory and help you symlink external dirs into it."
              echo ""
              
              echo -e "${CYAN}Step 1: Create watched directory${NC}"
              mkdir -p "$WATCHED_DIR"
              echo -e "${GREEN}✅ Created: $WATCHED_DIR${NC}"
              echo ""
              
              echo -e "${CYAN}Step 2: Create symlinks${NC}"
              echo ""
              echo "Enter directories to symlink (one at a time, or press Enter to finish):"
              echo ""
              
              symlinks_created=0
              while true; do
                echo -n "Directory to symlink (or Enter to finish): "
                read external_dir
                
                if [[ -z "$external_dir" ]]; then
                  break
                fi
                
                # Expand user home and tildes
                external_dir="${external_dir//\~/$HOME}"
                external_path=$(realpath "$external_dir" 2>/dev/null || echo "")
                
                if [[ -z "$external_path" || ! -d "$external_path" ]]; then
                  echo -e "${YELLOW}⚠️  Directory not found: $external_dir${NC}"
                  continue
                fi
                
                # Create symlink name from directory name
                link_name=$(basename "$external_path")
                link_path="$WATCHED_DIR/$link_name"
                
                if [[ -e "$link_path" ]]; then
                  echo -e "${YELLOW}⚠️  Symlink already exists: $link_path${NC}"
                  echo -n "  Replace? (y/n): "
                  read replace
                  if [[ "$replace" != "y" && "$replace" != "Y" ]]; then
                    continue
                  fi
                  rm "$link_path"
                fi
                
                # Create symlink
                ln -s "$external_path" "$link_path"
                echo -e "${GREEN}✅ Created symlink: $link_name → $external_path${NC}"
                symlinks_created=$((symlinks_created + 1))
                echo ""
              done
              
              if [[ $symlinks_created -gt 0 ]]; then
                echo ""
                echo -e "${CYAN}Step 3: Configure filewatcher to use watched directory${NC}"
                echo ""
                echo -n "Update configuration to watch $WATCHED_DIR? (y/n): "
                read update_config
                
                if [[ "$update_config" == "y" || "$update_config" == "Y" ]]; then
                  if [[ ! -f "$CONFIG_DB_FILE" ]]; then
                    mkdir -p "$GTD_CONFIG_DIR"
                    touch "$CONFIG_DB_FILE"
                  fi
                  
                  if grep -q "^VECTOR_WATCH_DIRS=" "$CONFIG_DB_FILE" 2>/dev/null; then
                    if [[ "$(uname)" == "Darwin" ]]; then
                      sed -i.bak "s|^VECTOR_WATCH_DIRS=.*|VECTOR_WATCH_DIRS=\"${WATCHED_DIR}\"|" "$CONFIG_DB_FILE"
                    else
                      sed -i "s|^VECTOR_WATCH_DIRS=.*|VECTOR_WATCH_DIRS=\"${WATCHED_DIR}\"|" "$CONFIG_DB_FILE"
                    fi
                  else
                    echo "" >> "$CONFIG_DB_FILE"
                    echo "# Vector Filewatcher Configuration" >> "$CONFIG_DB_FILE"
                    echo "VECTOR_WATCH_DIRS=\"${WATCHED_DIR}\"" >> "$CONFIG_DB_FILE"
                  fi
                  
                  echo -e "${GREEN}✅ Configuration updated!${NC}"
                fi
                
                echo ""
                echo "Symlinks created in: $WATCHED_DIR"
                echo "The filewatcher will automatically follow these symlinks."
              fi
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            4)
              echo ""
              echo -e "${BOLD}Configure Watched Directory Location:${NC}"
              echo ""
              echo "This is where symlinks to external directories will be created."
              echo "The filewatcher will watch this directory and follow symlinks."
              echo ""
              
              # Load current config
              if [[ -f "$CONFIG_DB_FILE" ]]; then
                source "$CONFIG_DB_FILE"
              fi
              
              CURRENT_WATCH_DIR="${VECTOR_WATCH_DIR:-$HOME/Documents/gtd/watched}"
              
              echo "Current watched directory: $CURRENT_WATCH_DIR"
              echo ""
              echo -n "Enter new watched directory path (or Enter to keep current): "
              read new_watch_dir
              
              if [[ -z "$new_watch_dir" ]]; then
                echo "No change made."
                echo ""
                echo "Press Enter to continue..."
                read
                continue
              fi
              
              # Expand user home
              new_watch_dir="${new_watch_dir//\~/$HOME}"
              new_watch_dir=$(realpath -m "$new_watch_dir" 2>/dev/null || echo "$new_watch_dir")
              
              # Create config file if needed
              if [[ ! -f "$CONFIG_DB_FILE" ]]; then
                mkdir -p "$GTD_CONFIG_DIR"
                touch "$CONFIG_DB_FILE"
              fi
              
              # Update or add VECTOR_WATCH_DIR
              if grep -q "^VECTOR_WATCH_DIR=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^VECTOR_WATCH_DIR=.*|VECTOR_WATCH_DIR=\"${new_watch_dir}\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^VECTOR_WATCH_DIR=.*|VECTOR_WATCH_DIR=\"${new_watch_dir}\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "" >> "$CONFIG_DB_FILE"
                echo "# Vector Filewatcher Configuration" >> "$CONFIG_DB_FILE"
                echo "VECTOR_WATCH_DIR=\"${new_watch_dir}\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo ""
              echo -e "${GREEN}✅ Configuration updated!${NC}"
              echo "   Watched directory: $new_watch_dir"
              echo ""
              echo "Note: You'll need to recreate symlinks in the new location if you changed it."
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            5)
              echo ""
              echo -e "${CYAN}Starting Vector Filewatcher...${NC}"
              echo ""
              
              # Check if watchdog is installed
              if ! "$PYTHON_CMD" -c "import watchdog" 2>/dev/null; then
                echo -e "${YELLOW}⚠️  watchdog library not installed${NC}"
                echo ""
                echo "Install it first (option 8), or install now? (y/n): "
                read install_now
                if [[ "$install_now" == "y" || "$install_now" == "Y" ]]; then
                  if [[ -n "$MCP_VENV_DIR" && -d "$MCP_VENV_DIR" ]]; then
                    echo "Installing watchdog..."
                    "$MCP_VENV_DIR/bin/pip" install watchdog
                  else
                    echo "Please install manually: pip3 install watchdog"
                    echo ""
                    echo "Press Enter to continue..."
                    read
                    continue
                  fi
                else
                  echo ""
                  echo "Press Enter to continue..."
                  read
                  continue
                fi
              fi
              
              cd "$HOME/code/dotfiles" && make filewatcher-start
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            6)
              echo ""
              echo -e "${CYAN}Stopping Vector Filewatcher...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make filewatcher-stop
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            7)
              echo ""
              cd "$HOME/code/dotfiles" && make filewatcher-status
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            8)
              echo ""
              echo -e "${BOLD}Install Required Dependencies${NC}"
              echo ""
              echo "Installing watchdog library..."
              echo ""
              
              if [[ -n "$MCP_VENV_DIR" && -d "$MCP_VENV_DIR" ]]; then
                echo "Installing into virtualenv: $MCP_VENV_DIR"
                "$MCP_VENV_DIR/bin/pip" install watchdog
              else
                echo "Installing system-wide..."
                pip3 install watchdog
              fi
              
              echo ""
              if "$PYTHON_CMD" -c "import watchdog" 2>/dev/null; then
                echo -e "${GREEN}✅ watchdog installed successfully${NC}"
              else
                echo -e "${YELLOW}⚠️  Installation may have failed. Check output above.${NC}"
              fi
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            0)
              ;;
            *)
              echo "Invalid choice"
              ;;
      esac
      ;;
    11)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🧠 Setup Deep Analysis Auto-Scheduler${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "The scheduler automatically submits deep analysis jobs to the queue"
      echo "based on schedules and triggers (weekly reviews, energy analysis, etc.)."
      echo ""
      echo "Scheduler Options:"
      echo ""
      echo "  1) 📋 View Current Configuration"
      echo "  2) ⚙️  Configure Scheduled Analyses"
      echo "  3) 🎯 Configure Event-Driven Triggers"
      echo "  4) 🔔 Configure Notifications & Auto-Scan"
      echo "  5) ▶️  Start Scheduler Daemon"
      echo "  6) ⏹️  Stop Scheduler Daemon"
      echo "  7) 📊 Check Scheduler Status"
      echo "  8) 🔄 Run Scheduler Now (one-time check)"
      echo ""
      echo -e "${YELLOW}0)${NC} Back"
      echo ""
      echo -n "Choose: "
      read scheduler_choice
      
      GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
      if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
        GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
      fi
      CONFIG_DB_FILE="${GTD_CONFIG_DIR}/.gtd_config_database"
      
      case "$scheduler_choice" in
            1)
              echo ""
              echo -e "${BOLD}Current Scheduler Configuration:${NC}"
              echo ""
              
              if [[ -f "$CONFIG_DB_FILE" ]]; then
                source "$CONFIG_DB_FILE"
              fi
              
              echo "Scheduled Analyses:"
              echo "  Weekly Review: ${DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW:-false}"
              if [[ "${DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW:-false}" == "true" ]]; then
                echo "    Day: ${DEEP_ANALYSIS_WEEKLY_REVIEW_DAY:-monday}"
                echo "    Time: ${DEEP_ANALYSIS_WEEKLY_REVIEW_TIME:-09:00}"
              fi
              echo "  Energy Analysis: ${DEEP_ANALYSIS_AUTO_ENERGY:-false}"
              if [[ "${DEEP_ANALYSIS_AUTO_ENERGY:-false}" == "true" ]]; then
                echo "    Interval: Every ${DEEP_ANALYSIS_ENERGY_INTERVAL:-3} days"
                echo "    Analyze last: ${DEEP_ANALYSIS_ENERGY_DAYS:-7} days"
              fi
              echo "  Insights: ${DEEP_ANALYSIS_AUTO_INSIGHTS:-false}"
              if [[ "${DEEP_ANALYSIS_AUTO_INSIGHTS:-false}" == "true" ]]; then
                echo "    Interval: Every ${DEEP_ANALYSIS_INSIGHTS_INTERVAL:-1} days"
              fi
              echo "  Connections: ${DEEP_ANALYSIS_AUTO_CONNECTIONS:-false}"
              if [[ "${DEEP_ANALYSIS_AUTO_CONNECTIONS:-false}" == "true" ]]; then
                echo "    Interval: Every ${DEEP_ANALYSIS_CONNECTIONS_INTERVAL:-7} days"
              fi
              echo ""
              echo "Event-Driven Triggers:"
              echo "  Energy on Daily Log: ${DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG:-false}"
              echo "  Insights on Content: ${DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT:-false}"
              echo "  Connections on Task: ${DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK:-false}"
              echo ""
              echo "Notifications & Auto-Scan:"
              echo "  macOS Notifications: ${GTD_NOTIFICATIONS:-true}"
              echo "  Auto-Scan to Suggestions: ${DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS:-false}"
              if [[ "${DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS:-false}" == "true" ]]; then
                echo "    Scan Types: ${DEEP_ANALYSIS_AUTO_SCAN_TYPES:-connections,insights}"
              fi
              echo ""
              
              # Check if daemon is running
              if [[ -f "/tmp/gtd-deep-analysis-scheduler-daemon.pid" ]]; then
                pid=$(cat /tmp/gtd-deep-analysis-scheduler-daemon.pid)
                if ps -p "$pid" > /dev/null 2>&1; then
                  echo -e "${GREEN}✅ Scheduler daemon running (PID: $pid)${NC}"
                else
                  echo -e "${CYAN}ℹ️  Scheduler daemon not running${NC}"
                fi
              else
                echo -e "${CYAN}ℹ️  Scheduler daemon not running${NC}"
              fi
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            2)
              echo ""
              echo -e "${BOLD}Configure Scheduled Analyses:${NC}"
              echo ""
              echo "This allows you to set up automatic scheduled deep analysis jobs."
              echo ""
              
              if [[ ! -f "$CONFIG_DB_FILE" ]]; then
                mkdir -p "$GTD_CONFIG_DIR"
                touch "$CONFIG_DB_FILE"
              fi
              
              # Weekly Review
              echo "Weekly Review:"
              echo -n "  Enable automatic weekly review? (y/n, current: ${DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW:-false}): "
              read enable_weekly
              if [[ "$enable_weekly" == "y" || "$enable_weekly" == "Y" ]]; then
                echo -n "  Day (monday-sunday, current: ${DEEP_ANALYSIS_WEEKLY_REVIEW_DAY:-monday}): "
                read review_day
                review_day="${review_day:-monday}"
                echo -n "  Time (HH:MM, current: ${DEEP_ANALYSIS_WEEKLY_REVIEW_TIME:-09:00}): "
                read review_time
                review_time="${review_time:-09:00}"
                
                for setting in "DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=true" "DEEP_ANALYSIS_WEEKLY_REVIEW_DAY=\"$review_day\"" "DEEP_ANALYSIS_WEEKLY_REVIEW_TIME=\"$review_time\""; do
                  key=$(echo "$setting" | cut -d'=' -f1)
                  if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                    if [[ "$(uname)" == "Darwin" ]]; then
                      sed -i.bak "s|^$key=.*|$setting|" "$CONFIG_DB_FILE"
                    else
                      sed -i "s|^$key=.*|$setting|" "$CONFIG_DB_FILE"
                    fi
                  else
                    echo "" >> "$CONFIG_DB_FILE"
                    echo "# Deep Analysis Automatic Scheduler Configuration" >> "$CONFIG_DB_FILE"
                    echo "$setting" >> "$CONFIG_DB_FILE"
                  fi
                done
              fi
              
              echo ""
              echo "Energy Analysis:"
              echo -n "  Enable automatic energy analysis? (y/n, current: ${DEEP_ANALYSIS_AUTO_ENERGY:-false}): "
              read enable_energy
              if [[ "$enable_energy" == "y" || "$enable_energy" == "Y" ]]; then
                echo -n "  Run every N days (current: ${DEEP_ANALYSIS_ENERGY_INTERVAL:-3}): "
                read energy_interval
                energy_interval="${energy_interval:-3}"
                echo -n "  Analyze last N days (current: ${DEEP_ANALYSIS_ENERGY_DAYS:-7}): "
                read energy_days
                energy_days="${energy_days:-7}"
                
                for setting in "DEEP_ANALYSIS_AUTO_ENERGY=true" "DEEP_ANALYSIS_ENERGY_INTERVAL=$energy_interval" "DEEP_ANALYSIS_ENERGY_DAYS=$energy_days"; do
                  key=$(echo "$setting" | cut -d'=' -f1)
                  if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                    if [[ "$(uname)" == "Darwin" ]]; then
                      sed -i.bak "s|^$key=.*|$setting|" "$CONFIG_DB_FILE"
                    else
                      sed -i "s|^$key=.*|$setting|" "$CONFIG_DB_FILE"
                    fi
                  else
                    echo "$setting" >> "$CONFIG_DB_FILE"
                  fi
                done
              fi
              
              echo ""
              echo -e "${GREEN}✅ Configuration updated!${NC}"
              echo "Press Enter to continue..."
              read
              ;;
            3)
              echo ""
              echo -e "${BOLD}Configure Event-Driven Triggers:${NC}"
              echo ""
              echo "These trigger deep analysis automatically when content is created."
              echo ""
              
              if [[ ! -f "$CONFIG_DB_FILE" ]]; then
                mkdir -p "$GTD_CONFIG_DIR"
                touch "$CONFIG_DB_FILE"
              fi
              
              echo -n "Trigger energy analysis when daily log is created? (y/n, current: ${DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG:-false}): "
              read trigger_energy
              if [[ "$trigger_energy" == "y" || "$trigger_energy" == "Y" ]]; then
                value="true"
              else
                value="false"
              fi
              key="DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG"
              if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "" >> "$CONFIG_DB_FILE"
                echo "$key=\"$value\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo -n "Trigger insights when content is created? (y/n, current: ${DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT:-false}): "
              read trigger_insights
              if [[ "$trigger_insights" == "y" || "$trigger_insights" == "Y" ]]; then
                value="true"
              else
                value="false"
              fi
              key="DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT"
              if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "$key=\"$value\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo -n "Trigger connections when task is created? (y/n, current: ${DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK:-false}): "
              read trigger_connections
              if [[ "$trigger_connections" == "y" || "$trigger_connections" == "Y" ]]; then
                value="true"
              else
                value="false"
              fi
              key="DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK"
              if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "$key=\"$value\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo ""
              echo -e "${GREEN}✅ Configuration updated!${NC}"
              echo "Press Enter to continue..."
              read
              ;;
            4)
              echo ""
              echo -e "${BOLD}Configure Notifications & Auto-Scan:${NC}"
              echo ""
              echo "These settings control how you're notified when analysis results are ready"
              echo "and whether suggestions are automatically created from results."
              echo ""
              
              if [[ ! -f "$CONFIG_DB_FILE" ]]; then
                mkdir -p "$GTD_CONFIG_DIR"
                touch "$CONFIG_DB_FILE"
              fi
              
              # Load current config
              if [[ -f "$CONFIG_DB_FILE" ]]; then
                source "$CONFIG_DB_FILE"
              fi
              
              echo "Notifications:"
              echo -n "  Enable macOS notifications when results are ready? (y/n, current: ${GTD_NOTIFICATIONS:-true}): "
              read enable_notify
              if [[ "$enable_notify" == "y" || "$enable_notify" == "Y" ]]; then
                value="true"
              else
                value="false"
              fi
              key="GTD_NOTIFICATIONS"
              if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "" >> "$CONFIG_DB_FILE"
                echo "# Notifications" >> "$CONFIG_DB_FILE"
                echo "$key=\"$value\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo ""
              echo "Auto-Scan & Suggestions:"
              echo "  When enabled, analysis results are automatically scanned and"
              echo "  actionable suggestions are created for you to review."
              echo ""
              echo -n "  Enable auto-scan results into suggestions? (y/n, current: ${DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS:-false}): "
              read enable_scan
              if [[ "$enable_scan" == "y" || "$enable_scan" == "Y" ]]; then
                value="true"
                echo ""
                echo -n "  Which analysis types to scan? (comma-separated: connections,insights,weekly_review,analyze_energy, default: connections,insights): "
                read scan_types
                scan_types="${scan_types:-connections,insights}"
              else
                value="false"
                scan_types="${DEEP_ANALYSIS_AUTO_SCAN_TYPES:-connections,insights}"
              fi
              
              key="DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS"
              if grep -q "^$key=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "" >> "$CONFIG_DB_FILE"
                echo "# Auto-scan suggestions from analysis results" >> "$CONFIG_DB_FILE"
                echo "$key=\"$value\"" >> "$CONFIG_DB_FILE"
              fi
              
              key2="DEEP_ANALYSIS_AUTO_SCAN_TYPES"
              if grep -q "^$key2=" "$CONFIG_DB_FILE" 2>/dev/null; then
                if [[ "$(uname)" == "Darwin" ]]; then
                  sed -i.bak "s|^$key2=.*|$key2=\"$scan_types\"|" "$CONFIG_DB_FILE"
                else
                  sed -i "s|^$key2=.*|$key2=\"$scan_types\"|" "$CONFIG_DB_FILE"
                fi
              else
                echo "$key2=\"$scan_types\"" >> "$CONFIG_DB_FILE"
              fi
              
              echo ""
              echo -e "${GREEN}✅ Configuration updated!${NC}"
              echo ""
              if [[ "$value" == "true" ]]; then
                echo "When analysis completes, suggestions will be automatically created from:"
                echo "$scan_types" | tr ',' '\n' | sed 's/^/  - /'
                echo ""
                echo "Review suggestions: gtd-wizard → AI Suggestions → Review pending suggestions"
              fi
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            5)
              echo ""
              echo -e "${CYAN}Starting Scheduler Daemon...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-start
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            6)
              echo ""
              echo -e "${CYAN}Stopping Scheduler Daemon...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-stop
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            7)
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-status
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            8)
              echo ""
              echo -e "${CYAN}Running scheduler (one-time check)...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-run
              echo ""
              echo "Press Enter to continue..."
              read
              ;;
            0)
              ;;
            *)
              echo "Invalid choice"
              ;;
          esac
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

learn_second_brain_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🧠 Second Brain Learning - Where to Start${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_second_brain_learning_guide
  echo "Welcome to your Second Brain! Let's get you started."
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) 📚 Learn Second Brain basics (with Mistress Louiza)"
  echo "  2) 🎯 Quick start guide (step-by-step)"
  echo "  3) 📖 Learn specific topic (interactive menu)"
  echo "  4) 🔄 Sync your GTD with Second Brain"
  echo "  9) 📱 Sync daily logs (for switching computers)"
  echo "  5) 📋 Try a template"
  echo "  6) 🗺️  Create your first MOC"
  echo "  7) ✍️  Try Express phase"
  echo "  8) 📊 Check your Second Brain status"
  echo ""
  echo -e "${YELLOW}🎯 Quiz & Games:${NC}"
  echo "  10) 🎯 Take a Quiz (test your knowledge)"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}👑 Learning from Mistress Louiza${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      gtd-learn second-brain
      ;;
    2)
      quick_start_second_brain
      ;;
    3)
      clear
      show_second_brain_topics
      ;;
    4)
      clear
      echo ""
      echo "🔄 Syncing GTD with Second Brain..."
      echo ""
      gtd-brain-sync
      echo ""
      echo "✓ Sync complete!"
      echo ""
      echo "Your GTD projects, areas, and references are now linked to Second Brain."
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    5)
      clear
      echo ""
      echo "📋 Let's try a template!"
      echo ""
      gtd-brain-template list
      echo ""
      echo "Which template would you like to try?"
      echo "  1) Meeting Notes"
      echo "  2) Book Notes"
      echo "  3) Article Notes"
      echo "  4) Project Notes"
      echo ""
      echo -n "Choose: "
      read template_choice
      
      case "$template_choice" in
        1) template_name="Meeting Notes" ;;
        2) template_name="Book Notes" ;;
        3) template_name="Article Notes" ;;
        4) template_name="Project Notes" ;;
        *) template_name="Meeting Notes" ;;
      esac
      
      echo ""
      echo -n "What should we call this note? "
      read note_name
      
      gtd-brain-template create "$template_name" "$note_name" Resources
      echo ""
      echo "✓ Created! Open it in Obsidian to fill it in."
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    6)
      clear
      echo ""
      echo "🗺️  Let's create your first MOC!"
      echo ""
      echo "MOCs (Maps of Content) are index notes that organize related notes."
      echo ""
      echo "What would you like to do?"
      echo ""
      echo "  1) Create a custom MOC"
      echo "  2) Use starter MOC wizard (recommended)"
      echo ""
      echo -n "Choose: "
      read moc_choice
      
      case "$moc_choice" in
        1)
          echo ""
          echo -n "What topic would you like to create a MOC for? "
          read topic
          
          if [[ -n "$topic" ]]; then
            echo ""
            gtd-brain-moc create "$topic"
            echo ""
            echo "💡 Next steps:"
            echo "  • Add notes to this MOC: gtd-brain-moc add \"$topic\" <note-path>"
            echo "  • Auto-populate from tags: gtd-brain-moc auto \"$topic\" <tag>"
            echo "  • View the MOC: gtd-brain-moc view \"$topic\""
            echo ""
          fi
          ;;
        2)
          gtd-brain-moc-starter
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      
      echo "Press Enter to continue..."
      read
      ;;
    7)
      clear
      echo ""
      echo "✍️  Express Phase - Create content from your notes!"
      echo ""
      echo "The Express phase is about creating and sharing from your Second Brain."
      echo ""
      echo "First, let's see what notes you have:"
      echo ""
      gtd-brain list Resources 2>/dev/null | head -20
      echo ""
      echo "To create content from notes:"
      echo "  gtd-brain-express create \"Title\" \"note1.md,note2.md\" article"
      echo ""
      echo "Or use the Express wizard from the main menu (option 9)."
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    8)
      clear
      echo ""
      echo "📊 Your Second Brain Status"
      echo ""
      gtd-brain-metrics dashboard 2>/dev/null || echo "Run: gtd-brain-metrics dashboard"
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    9)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📱 Daily Log Sync${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Sync your daily logs for switching computers."
      echo ""
      echo "What would you like to do?"
      echo ""
      echo "  1) 🔄 Two-way sync (recommended)"
      echo "  2) 📤 Push to Second Brain (before switching computers)"
      echo "  3) 📥 Pull from Second Brain (after switching computers)"
      echo "  4) 📊 Check sync status"
      echo ""
      echo -n "Choose: "
      read sync_choice
      
      case "$sync_choice" in
        1)
          gtd-daily-log-sync sync
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        2)
          gtd-daily-log-sync push
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        3)
          gtd-daily-log-sync pull
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        4)
          gtd-daily-log-sync status
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
}

life_vision_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 Life Vision Discovery${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Not everyone has a clear life plan—and that's okay!"
  echo "This wizard helps you discover what matters to you."
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) 📖 Read the Life Vision Discovery Guide"
  echo "  2) 🔍 Review what you're already doing (discover patterns)"
  echo "  3) 💭 Answer discovery questions"
  echo "  4) 📝 Create a simple life vision document"
  echo "  5) 🎯 Review your areas (what matters to you)"
  echo "  6) 📊 Review your projects (what you're building)"
  echo "  7) 📅 Review your daily logs (patterns in your life)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to main menu"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      if [[ -f "$HOME/code/dotfiles/zsh/LIFE_VISION_DISCOVERY_GUIDE.md" ]]; then
        if command -v less &>/dev/null; then
          less "$HOME/code/dotfiles/zsh/LIFE_VISION_DISCOVERY_GUIDE.md"
        elif command -v cat &>/dev/null; then
          cat "$HOME/code/dotfiles/zsh/LIFE_VISION_DISCOVERY_GUIDE.md"
        else
          echo "Guide: $HOME/code/dotfiles/zsh/LIFE_VISION_DISCOVERY_GUIDE.md"
        fi
      else
        echo "Guide not found. Creating it now..."
        echo "See: zsh/LIFE_VISION_DISCOVERY_GUIDE.md"
      fi
      read -p "Press Enter to continue..."
      life_vision_wizard
      ;;
    2)
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🔍 Reviewing What You're Already Doing"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Let's look at your GTD system to discover patterns..."
      echo ""
      echo "📁 Your Areas of Responsibility:"
      gtd-area list 2>/dev/null || echo "  (No areas yet)"
      echo ""
      echo "📁 Your Active Projects:"
      gtd-project list 2>/dev/null || echo "  (No projects yet)"
      echo ""
      echo "📊 Your Habits:"
      gtd-habit dashboard 2>/dev/null || echo "  (No habits yet)"
      echo ""
      echo "💡 Questions to consider:"
      echo "  - What areas are you investing time in?"
      echo "  - What projects are you building?"
      echo "  - What patterns do you see?"
      echo "  - What matters to you based on what you're doing?"
      echo ""
      read -p "Press Enter to continue..."
      life_vision_wizard
      ;;
    3)
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "💭 Discovery Questions"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Answer these questions honestly (it's okay if you don't know!):"
      echo ""
      echo "1. What makes you feel good?"
      read -p "   " q1
      echo ""
      echo "2. What would you change if you could?"
      read -p "   " q2
      echo ""
      echo "3. What are you curious about?"
      read -p "   " q3
      echo ""
      echo "4. What would you do if you weren't afraid?"
      read -p "   " q4
      echo ""
      echo "5. What would you do if money wasn't a concern?"
      read -p "   " q5
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "💡 Your Answers"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "1. What makes you feel good: $q1"
      echo "2. What would you change: $q2"
      echo "3. What are you curious about: $q3"
      echo "4. What would you do if you weren't afraid: $q4"
      echo "5. What would you do if money wasn't a concern: $q5"
      echo ""
      echo "💡 Look for patterns in your answers. What themes emerge?"
      echo ""
      read -p "Save these answers? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        local vision_file="$HOME/Documents/gtd/life-vision.md"
        mkdir -p "$HOME/Documents/gtd"
        if [[ ! -f "$vision_file" ]]; then
          cat > "$vision_file" <<EOF
# My Life Vision

Created: $(date +"%Y-%m-%d")

## Discovery Questions

1. What makes you feel good?
   $q1

2. What would you change if you could?
   $q2

3. What are you curious about?
   $q3

4. What would you do if you weren't afraid?
   $q4

5. What would you do if money wasn't a concern?
   $q5

## Notes
[Add your thoughts here]

EOF
        else
          cat >> "$vision_file" <<EOF

## Discovery Session - $(date +"%Y-%m-%d")

1. What makes you feel good?
   $q1

2. What would you change if you could?
   $q2

3. What are you curious about?
   $q3

4. What would you do if you weren't afraid?
   $q4

5. What would you do if money wasn't a concern?
   $q5

EOF
        fi
        echo "✓ Saved to: $vision_file"
      fi
      read -p "Press Enter to continue..."
      life_vision_wizard
      ;;
    4)
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "📝 Create Life Vision Document"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      local vision_file="$HOME/Documents/gtd/life-vision.md"
      mkdir -p "$HOME/Documents/gtd"
      
      if [[ -f "$vision_file" ]]; then
        echo "Life vision document already exists: $vision_file"
        read -p "Open it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          if command -v open &>/dev/null; then
            open "$vision_file"
          elif command -v less &>/dev/null; then
            less "$vision_file"
          else
            cat "$vision_file"
          fi
        fi
      else
        echo "Creating life vision document..."
        echo ""
        echo -e "${BOLD}💡 What is a Life Vision?${NC}"
        echo ""
        echo "A life vision is a picture of where you want to be in the future."
        echo "It doesn't need to be perfect or detailed—just a direction to move toward."
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}📝 1-Year Vision${NC}"
        echo ""
        echo "Imagine yourself one year from now. What would make you feel proud?"
        echo "What would you like to have accomplished or changed?"
        echo ""
        echo -e "${CYAN}Examples:${NC}"
        echo "  • 'I want to feel healthier and more energetic'"
        echo "  • 'I want to have learned [skill/topic] and be using it regularly'"
        echo "  • 'I want to have stronger relationships with [people]'"
        echo "  • 'I want to be working on projects that matter to me'"
        echo "  • 'I want to feel more confident in [area]'"
        echo "  • 'I want to have a better work-life balance'"
        echo ""
        echo -e "${YELLOW}💭 Questions to think about:${NC}"
        echo "  • What would make the next year feel meaningful?"
        echo "  • What would you like to be different?"
        echo "  • What would you like to have more of? Less of?"
        echo "  • What would make you feel like you're growing?"
        echo ""
        echo -e "${GREEN}Tip:${NC} It's okay if it's vague! You can refine it later."
        echo ""
        read -p "1-Year Vision: " vision_1yr
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}💎 Values (What Matters to You)${NC}"
        echo ""
        echo "Values are the principles that guide your decisions and actions."
        echo "They're what you stand for, what you prioritize."
        echo ""
        echo -e "${CYAN}Examples:${NC}"
        echo "  • Growth, Learning, Health, Family, Creativity"
        echo "  • Integrity, Adventure, Security, Freedom, Contribution"
        echo "  • Authenticity, Excellence, Balance, Connection, Purpose"
        echo ""
        echo -e "${YELLOW}💭 Questions to think about:${NC}"
        echo "  • What principles do you want to live by?"
        echo "  • What do you want to be known for?"
        echo "  • What matters most when you make decisions?"
        echo ""
        read -p "   Value 1: " value1
        read -p "   Value 2: " value2
        read -p "   Value 3: " value3
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}🎯 Areas to Focus On${NC}"
        echo ""
        echo "These are the key areas of your life where you want to invest energy."
        echo "Think about what domains matter most to you right now."
        echo ""
        echo -e "${CYAN}Examples:${NC}"
        echo "  • Health & Wellness, Career/Work, Relationships"
        echo "  • Learning & Growth, Creative Projects, Finances"
        echo "  • Family, Personal Development, Hobbies, Community"
        echo ""
        echo -e "${YELLOW}💭 Questions to think about:${NC}"
        echo "  • Where do you want to see the most change?"
        echo "  • What areas of your life need attention?"
        echo "  • What would make the biggest positive impact?"
        echo ""
        read -p "   Area 1: " area1
        read -p "   Area 2: " area2
        read -p "   Area 3: " area3
        
        cat > "$vision_file" <<EOF
# My Life Vision

Created: $(date +"%Y-%m-%d")
Last Updated: $(date +"%Y-%m-%d")

## 1-Year Vision
${vision_1yr:-Not sure yet - using reviews to discover}

## Values (What Matters to Me)
1. ${value1:-}
2. ${value2:-}
3. ${value3:-}

## Areas of Focus
1. ${area1:-}
2. ${area2:-}
3. ${area3:-}

## Notes
[Add your thoughts, questions, and discoveries here]

## Discovery Process
- Review this document monthly
- Update as you learn more about yourself
- Use this in your reviews to stay aligned

EOF
        echo "✅ Vision file created: $vision_file"
        echo ""
        echo "Next steps:"
        echo "  1. Review the vision file"
        echo "  2. Fill in the values and areas"
        echo "  3. Update it monthly during reviews"
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
  echo "Press Enter to continue..."
  read
}

greek_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🇬🇷 Greek Language Learning Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_learning_guide
  echo "What would you like to do?"
  echo ""
  echo -e "${GREEN}Learning:${NC}"
  echo "  1) Start learning (interactive menu)"
  echo "  2) Learn specific topic"
  echo "  3) Create study plan"
  echo "  4) View study progress"
  echo "  5) Setup study habit"
  echo ""
  echo -e "${CYAN}🎯 Quiz & Games:${NC}"
  echo "  6) 🎯 Take a Quiz (test your knowledge)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read greek_choice
  
  case "$greek_choice" in
    1)
      gtd-learn-greek
      ;;
    2)
      echo ""
      echo "Available topics:"
      echo "  basics, alphabet, reading, vocabulary, grammar, verbs, nouns, comprehension, pronunciation, practice"
      echo ""
      echo -n "Topic: "
      read topic
      gtd-learn-greek "$topic"
      ;;
    3)
      gtd-study-plan greek
      ;;
    4)
      gtd-learn-greek
      # This will show progress in the menu
      ;;
    5)
      if command -v gtd-greek-setup-habit &>/dev/null; then
        gtd-greek-setup-habit
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-greek-setup-habit" ]]; then
        "$HOME/code/dotfiles/bin/gtd-greek-setup-habit"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-greek-setup-habit" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-greek-setup-habit"
      else
        echo "❌ Greek habit setup not found"
        echo "   Make sure gtd-greek-setup-habit is in your PATH"
      fi
      ;;
    6)
      gtd-quiz greek
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
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

ai_suggestions_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🤖 AI Suggestions & MCP Tools${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_ai_suggestions_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) Get task suggestions from text"
  echo "  2) ⚡ Review high-confidence suggestions (one-keystroke)"
  echo "  3) 📋 Review mode - Medium-confidence suggestions"
  echo "  4) 📊 View suggestion statistics"
  echo "  5) Analyze recent daily logs"
  echo "  6) Generate banter for log entry"
  echo "  7) Trigger weekly review (background)"
  echo "  8) Analyze energy patterns (background)"
  echo "  9) Find connections (background)"
  echo "  10) Generate insights (background)"
  echo "  11) 🔍 Scan Analysis Results for Suggestions"
  echo "  12) 📋 View Analysis Results (weekly reviews, energy analysis, etc.)"
  echo "  13) Check MCP System Status"
  echo "  14) 🚀 Deploy Worker to Kubernetes"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read ai_choice
  
  case "$ai_choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}💡 Get Task Suggestions from Text${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Enter the text to analyze for task suggestions:"
      echo ""
      read -p "Text: " suggestion_text
      
      if [[ -z "$suggestion_text" ]]; then
        echo "❌ No text provided"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo ""
      echo "Analyzing text for task suggestions..."
      
      AUTO_SUGGEST_SCRIPT="$HOME/code/dotfiles/mcp/gtd_auto_suggest.py"
      if [[ ! -f "$AUTO_SUGGEST_SCRIPT" ]]; then
        AUTO_SUGGEST_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_auto_suggest.py"
      fi
      
      if [[ -f "$AUTO_SUGGEST_SCRIPT" ]]; then
        # Get Python executable (prefer virtualenv if available)
        MCP_PYTHON=$(gtd_get_mcp_python)
        if [[ -z "$MCP_PYTHON" ]]; then
          MCP_PYTHON="python3"
        fi
        
        result=$("$MCP_PYTHON" "$AUTO_SUGGEST_SCRIPT" entry "$suggestion_text" 2>&1)
        # Try to parse and display nicely
        if echo "$result" | "$MCP_PYTHON" -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
          # Valid JSON - display formatted
          echo ""
          echo "$result" | "$MCP_PYTHON" -c "
import sys, json
data = json.load(sys.stdin)
if data.get('suggestion_count', 0) > 0:
    print('✅ Found', data['suggestion_count'], 'suggestion(s):')
    print('')
    for i, sid in enumerate(data.get('suggestions', []), 1):
        print(f'{i}. Suggestion ID: {sid}')
    print('')
if data.get('banter'):
    print('💬', data['banter'])
    print('')
print('Use option 2 to review pending suggestions.')
" 2>/dev/null || echo "$result"
        else
          # Not valid JSON, just show the output
          echo "$result"
        fi
      else
        echo "❌ Auto-suggest script not found: $AUTO_SUGGEST_SCRIPT"
        echo ""
        echo "Make sure MCP server is set up. See mcp/README.md for details."
      fi
      ;;
    2)
      # High-confidence suggestions (one-keystroke)
      if command -v gtd-smart-suggestions &>/dev/null; then
        gtd-smart-suggestions immediate
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-smart-suggestions" ]]; then
        "$HOME/code/dotfiles/bin/gtd-smart-suggestions" immediate
      else
        # Fallback to old method
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📋 Pending Suggestions${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
      
      SUGGESTIONS_DIR="${GTD_BASE_DIR}/suggestions"
      if [[ ! -d "$SUGGESTIONS_DIR" ]]; then
        echo "No suggestions directory found. No pending suggestions."
        echo ""
        echo "Press Enter to continue..."
        read
        return 0
      fi
      
      pending_count=0
      suggestions=()
      
      for suggestion_file in "$SUGGESTIONS_DIR"/*.json; do
        if [[ -f "$suggestion_file" ]]; then
          status=$(grep -o '"status":\s*"[^"]*"' "$suggestion_file" | cut -d'"' -f4)
          if [[ "$status" == "pending" ]]; then
            suggestions+=("$suggestion_file")
            ((pending_count++))
          fi
        fi
      done
      
      if [[ $pending_count -eq 0 ]]; then
        echo "✅ No pending suggestions!"
        echo ""
        echo "Press Enter to continue..."
        read
        return 0
      fi
      
      echo "You have $pending_count pending suggestion(s)."
      echo ""
      echo "Processing suggestions..."
      echo ""
      
      for suggestion_file in "${suggestions[@]}"; do
        suggestion_id=$(basename "$suggestion_file" .json)
        
        # Use Python to properly parse JSON and write to temp file to avoid eval issues
        local temp_vars=$(mktemp)
        python3 <<PYTHON_EOF > "$temp_vars" 2>/dev/null
import json
import sys
import os

try:
    with open('$suggestion_file', 'r') as f:
        data = json.load(f)
    
    title = data.get('title', '')
    reason = data.get('reason', '')
    confidence = data.get('confidence', 0.0)
    item_type = data.get('item_type', 'task')
    suggested_project = data.get('suggested_project', '') or data.get('categorization', '')
    suggested_area = data.get('suggested_area', '')
    suggested_moc = data.get('suggested_moc', '')
    
    # Write to file in a format that can be safely sourced
    with open('$temp_vars', 'w') as out:
        # Use printf %q format for safe shell variable assignment
        import shlex
        out.write(f"title={shlex.quote(title)}\n")
        out.write(f"reason={shlex.quote(reason)}\n")
        out.write(f"confidence={confidence}\n")
        out.write(f"item_type={shlex.quote(item_type)}\n")
        out.write(f"suggested_project={shlex.quote(suggested_project)}\n")
        out.write(f"suggested_area={shlex.quote(suggested_area)}\n")
        out.write(f"suggested_moc={shlex.quote(suggested_moc)}\n")
except Exception as e:
    with open('$temp_vars', 'w') as out:
        out.write("title=''\n")
        out.write(f"reason='Error reading suggestion: {str(e)}'\n")
        out.write("confidence=0.0\n")
        out.write("item_type='task'\n")
        out.write("suggested_project=''\n")
        out.write("suggested_area=''\n")
        out.write("suggested_moc=''\n")
PYTHON_EOF
        
        # Source the variables safely
        if [[ -f "$temp_vars" ]]; then
          source "$temp_vars"
          rm -f "$temp_vars"
        else
          # Fallback if Python failed
          title=""
          reason="Error reading suggestion"
          confidence=0.0
          item_type="task"
          suggested_project=""
          suggested_area=""
          suggested_moc=""
        fi
        
        # Capitalize first letter (bash 3.2 compatible)
        item_type_cap=$(echo "$item_type" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "💡 Suggestion: $title"
        echo ""
        echo "   Type: $item_type_cap"
        echo "   Confidence: $confidence"
        echo ""
        echo "   Reason:"
        # Word wrap the reason for better readability (80 chars per line, preserve words)
        echo "$reason" | fold -w 80 -s | sed 's/^/   /'
        echo ""
        if [[ -n "$suggested_project" ]]; then
          echo "   Suggested Project: $suggested_project"
        fi
        if [[ -n "$suggested_area" ]]; then
          echo "   Suggested Area: $suggested_area"
        fi
        if [[ -n "$suggested_moc" ]]; then
          echo "   Suggested MOC: $suggested_moc"
        fi
        echo ""
        echo "What would you like to do?"
        echo ""
        case "$item_type" in
          project)
            echo "  1) Create project from suggestion"
            echo "  2) Create as task instead"
            echo "  3) Create as zettel instead"
            echo "  4) Dismiss suggestion"
            echo "  5) Skip (view next)"
            ;;
          zettel)
            echo "  1) Create zettel from suggestion"
            echo "  2) Create as task instead"
            echo "  3) Create as project instead"
            echo "  4) Dismiss suggestion"
            echo "  5) Skip (view next)"
            ;;
          moc)
            echo "  1) Create MOC from suggestion"
            echo "  2) Create as task instead"
            echo "  3) Create as project instead"
            echo "  4) Dismiss suggestion"
            echo "  5) Skip (view next)"
            ;;
          *)
            echo "  1) Create task from suggestion"
            echo "  2) Create as project instead"
            echo "  3) Create as zettel instead"
            echo "  4) Create as MOC instead"
            echo "  5) Dismiss suggestion"
            echo "  6) Skip (view next)"
            ;;
        esac
        echo ""
        echo -n "Choose: "
        read suggestion_choice
        
        case "$suggestion_choice" in
          1)
            # Create based on item type
            case "$item_type" in
              project)
                echo ""
                echo "Creating project..."
                if [[ -n "$suggested_area" ]]; then
                  gtd-project create "$title" --area="$suggested_area" 2>&1
                else
                  gtd-project create "$title" 2>&1
                fi
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ Project created from suggestion"
                else
                  echo "❌ Failed to create project"
                fi
                ;;
              zettel)
                echo ""
                echo "Creating zettel..."
                if command -v zet &>/dev/null; then
                  zet "$title" 2>&1
                  if [[ $? -eq 0 ]]; then
                    mark_suggestion_accepted "$suggestion_file"
                    echo "✓ Zettel created from suggestion"
                  else
                    echo "❌ Failed to create zettel"
                  fi
                else
                  echo "❌ zet command not found"
                fi
                ;;
              moc)
                echo ""
                echo "Creating MOC..."
                if command -v gtd-brain-moc &>/dev/null; then
                  # Use suggested_moc if available, otherwise use title
                  local moc_title="${suggested_moc:-$title}"
                  gtd-brain-moc create "$moc_title" 2>&1
                  if [[ $? -eq 0 ]]; then
                    mark_suggestion_accepted "$suggestion_file"
                    echo "✓ MOC created from suggestion"
                  else
                    echo "❌ Failed to create MOC"
                  fi
                else
                  echo "❌ gtd-brain-moc command not found"
                fi
                ;;
              *)
                # Default to task
                echo ""
                echo "Creating task..."
                project_flag=""
                if [[ -n "$suggested_project" ]]; then
                  project_flag="--project=$suggested_project"
                fi
                gtd-task add --non-interactive $project_flag "$title" 2>&1
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ Task created from suggestion"
                else
                  echo "❌ Failed to create task"
                fi
                ;;
            esac
            ;;
          2)
            # Create as alternative type
            case "$item_type" in
              project|zettel|moc)
                # Create as task
                echo ""
                echo "Creating task..."
                project_flag=""
                if [[ -n "$suggested_project" ]]; then
                  project_flag="--project=$suggested_project"
                fi
                gtd-task add --non-interactive $project_flag "$title" 2>&1
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ Task created from suggestion"
                else
                  echo "❌ Failed to create task"
                fi
                ;;
              *)
                # Create as project
                echo ""
                echo "Creating project..."
                if [[ -n "$suggested_area" ]]; then
                  gtd-project create "$title" --area="$suggested_area" 2>&1
                else
                  gtd-project create "$title" 2>&1
                fi
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ Project created from suggestion"
                else
                  echo "❌ Failed to create project"
                fi
                ;;
            esac
            ;;
          3)
            # Create as another alternative type
            case "$item_type" in
              project)
                # Create as zettel
                echo ""
                echo "Creating zettel..."
                if command -v zet &>/dev/null; then
                  zet "$title" 2>&1
                  if [[ $? -eq 0 ]]; then
                    mark_suggestion_accepted "$suggestion_file"
                    echo "✓ Zettel created from suggestion"
                  else
                    echo "❌ Failed to create zettel"
                  fi
                else
                  echo "❌ zet command not found"
                fi
                ;;
              zettel)
                # Create as project
                echo ""
                echo "Creating project..."
                if [[ -n "$suggested_area" ]]; then
                  gtd-project create "$title" --area="$suggested_area" 2>&1
                else
                  gtd-project create "$title" 2>&1
                fi
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ Project created from suggestion"
                else
                  echo "❌ Failed to create project"
                fi
                ;;
              moc)
                # Create as project
                echo ""
                echo "Creating project..."
                if [[ -n "$suggested_area" ]]; then
                  gtd-project create "$title" --area="$suggested_area" 2>&1
                else
                  gtd-project create "$title" 2>&1
                fi
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ Project created from suggestion"
                else
                  echo "❌ Failed to create project"
                fi
                ;;
              *)
                # Create as zettel
                echo ""
                echo "Creating zettel..."
                if command -v zet &>/dev/null; then
                  zet "$title" 2>&1
                  if [[ $? -eq 0 ]]; then
                    mark_suggestion_accepted "$suggestion_file"
                    echo "✓ Zettel created from suggestion"
                  else
                    echo "❌ Failed to create zettel"
                  fi
                else
                  echo "❌ zet command not found"
                fi
                ;;
            esac
            ;;
          4)
            # Dismiss or create as MOC (for tasks)
            if [[ "$item_type" == "task" ]]; then
              echo ""
              echo "Creating MOC..."
              if command -v gtd-brain-moc &>/dev/null; then
                # Use suggested_moc if available, otherwise use title
                local moc_title="${suggested_moc:-$title}"
                gtd-brain-moc create "$moc_title" 2>&1
                if [[ $? -eq 0 ]]; then
                  mark_suggestion_accepted "$suggestion_file"
                  echo "✓ MOC created from suggestion"
                else
                  echo "❌ Failed to create MOC"
                fi
              else
                echo "❌ gtd-brain-moc command not found"
              fi
            else
              # Mark as dismissed
              mark_suggestion_dismissed "$suggestion_file"
              echo "✓ Suggestion dismissed"
            fi
            ;;
          5)
            if [[ "$item_type" == "task" ]]; then
              # Dismiss
              mark_suggestion_dismissed "$suggestion_file"
              echo "✓ Suggestion dismissed"
            else
              # Skip
              echo "→ Skipping..."
            fi
            ;;
          6)
            # Skip (only for tasks)
            echo "→ Skipping..."
            ;;
          *)
            echo "Invalid choice, skipping..."
            ;;
        esac
        echo ""
      done
      fi
      ;;
    3)
      # Review mode for medium-confidence
      if command -v gtd-smart-suggestions &>/dev/null; then
        gtd-smart-suggestions review
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-smart-suggestions" ]]; then
        "$HOME/code/dotfiles/bin/gtd-smart-suggestions" review
      else
        echo "Smart suggestions not available"
        echo "Press Enter to continue..."
        read
      fi
      ;;
    4)
      # View suggestion statistics
      if command -v gtd-smart-suggestions &>/dev/null; then
        gtd-smart-suggestions stats
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-smart-suggestions" ]]; then
        "$HOME/code/dotfiles/bin/gtd-smart-suggestions" stats
      else
        echo "Smart suggestions not available"
        echo "Press Enter to continue..."
        read
      fi
      ;;
    5)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📊 Analyze Recent Daily Logs${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      read -p "How many days to analyze? (default: 1): " days
      days="${days:-1}"
      
      echo ""
      echo "Analyzing recent logs..."
      
      AUTO_SUGGEST_SCRIPT="$HOME/code/dotfiles/mcp/gtd_auto_suggest.py"
      if [[ ! -f "$AUTO_SUGGEST_SCRIPT" ]]; then
        AUTO_SUGGEST_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_auto_suggest.py"
      fi
      
      if [[ -f "$AUTO_SUGGEST_SCRIPT" ]]; then
        result=$(python3 "$AUTO_SUGGEST_SCRIPT" analyze "$days" 2>&1)
        echo "$result"
      else
        echo "❌ Auto-suggest script not found"
      fi
      ;;
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}💬 Generate Banter for Log Entry${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      read -p "Enter log entry: " log_entry
      
      if [[ -z "$log_entry" ]]; then
        echo "❌ No entry provided"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo ""
      echo "Generating banter..."
      
      AUTO_SUGGEST_SCRIPT="$HOME/code/dotfiles/mcp/gtd_auto_suggest.py"
      if [[ ! -f "$AUTO_SUGGEST_SCRIPT" ]]; then
        AUTO_SUGGEST_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_auto_suggest.py"
      fi
      
      if [[ -f "$AUTO_SUGGEST_SCRIPT" ]]; then
        # Get Python executable (prefer virtualenv if available)
        MCP_PYTHON=$(gtd_get_mcp_python)
        if [[ -z "$MCP_PYTHON" ]]; then
          echo "❌ Could not find Python executable"
        else
          banter=$("$MCP_PYTHON" "$AUTO_SUGGEST_SCRIPT" banter "$log_entry" 2>&1)
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "💬 $banter"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
      else
        echo "❌ Auto-suggest script not found"
      fi
      ;;
    7)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📅 Queue Weekly Review${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Call queue function via Python
      MCP_PYTHON=$(gtd_get_mcp_python)
      if [[ -z "$MCP_PYTHON" ]]; then
        MCP_PYTHON="python3"
      fi
      
      MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      if [[ ! -f "$MCP_SERVER" ]]; then
        MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
      fi
      
      if [[ ! -f "$MCP_SERVER" ]]; then
        echo -e "${RED}❌ MCP server not found${NC}"
        echo "Expected at: $HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      else
        echo "Queuing weekly review analysis..."
        result=$("$MCP_PYTHON" -c "
import sys
sys.path.insert(0, '$(dirname "$MCP_SERVER")')
from gtd_mcp_server import queue_deep_analysis
from datetime import datetime, timedelta

week_start = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
status = queue_deep_analysis('weekly_review', {'week_start': week_start})
print(status)
" 2>&1)
        
        if [[ "$result" == *"queued"* ]] || [[ "$result" == *"logged"* ]]; then
          echo -e "${GREEN}✅ Job queued successfully${NC}"
          echo ""
          if [[ "$result" == *"file"* ]]; then
            echo -e "Queue method: ${CYAN}File queue${NC}"
            echo -e "Queue file: ${CYAN}~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
          else
            echo -e "Queue method: ${CYAN}RabbitMQ${NC}"
          fi
          echo ""
          echo -e "Results will be saved to: ${CYAN}~/Documents/gtd/deep_analysis_results/${NC}"
          echo ""
          echo "Note: Make sure the background worker is running to process this job."
        else
          echo -e "${RED}❌ Failed to queue job${NC}"
          echo "Error: $result"
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    8)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}⚡ Queue Energy Analysis${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Call queue function via Python
      MCP_PYTHON=$(gtd_get_mcp_python)
      if [[ -z "$MCP_PYTHON" ]]; then
        MCP_PYTHON="python3"
      fi
      
      MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      if [[ ! -f "$MCP_SERVER" ]]; then
        MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
      fi
      
      if [[ ! -f "$MCP_SERVER" ]]; then
        echo -e "${RED}❌ MCP server not found${NC}"
      else
        echo "Queuing energy pattern analysis..."
        result=$("$MCP_PYTHON" -c "
import sys
sys.path.insert(0, '$(dirname "$MCP_SERVER")')
from gtd_mcp_server import queue_deep_analysis

status = queue_deep_analysis('analyze_energy', {'days': 7})
print(status)
" 2>&1)
        
        if [[ "$result" == *"queued"* ]] || [[ "$result" == *"logged"* ]]; then
          echo -e "${GREEN}✅ Job queued successfully${NC}"
          echo ""
          if [[ "$result" == *"file"* ]]; then
            echo -e "Queue method: ${CYAN}File queue${NC}"
            echo -e "Queue file: ${CYAN}~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
          else
            echo -e "Queue method: ${CYAN}RabbitMQ${NC}"
          fi
          echo ""
          echo -e "Results will be saved to: ${CYAN}~/Documents/gtd/deep_analysis_results/${NC}"
          echo ""
          echo "Note: Make sure the background worker is running to process this job."
        else
          echo -e "${RED}❌ Failed to queue job${NC}"
          echo "Error: $result"
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    9)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🔗 Queue Connection Analysis${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Call queue function via Python
      MCP_PYTHON=$(gtd_get_mcp_python)
      if [[ -z "$MCP_PYTHON" ]]; then
        MCP_PYTHON="python3"
      fi
      
      MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      if [[ ! -f "$MCP_SERVER" ]]; then
        MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
      fi
      
      if [[ ! -f "$MCP_SERVER" ]]; then
        echo -e "${RED}❌ MCP server not found${NC}"
      else
        echo "Queuing connection analysis..."
        result=$("$MCP_PYTHON" -c "
import sys
sys.path.insert(0, '$(dirname "$MCP_SERVER")')
from gtd_mcp_server import queue_deep_analysis

status = queue_deep_analysis('find_connections', {'scope': 'all'})
print(status)
" 2>&1)
        
        if [[ "$result" == *"queued"* ]] || [[ "$result" == *"logged"* ]]; then
          echo -e "${GREEN}✅ Job queued successfully${NC}"
          echo ""
          if [[ "$result" == *"file"* ]]; then
            echo -e "Queue method: ${CYAN}File queue${NC}"
            echo -e "Queue file: ${CYAN}~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
          else
            echo -e "Queue method: ${CYAN}RabbitMQ${NC}"
          fi
          echo ""
          echo -e "Results will be saved to: ${CYAN}~/Documents/gtd/deep_analysis_results/${NC}"
          echo ""
          echo "Note: Make sure the background worker is running to process this job."
        else
          echo -e "${RED}❌ Failed to queue job${NC}"
          echo "Error: $result"
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    10)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}💡 Queue Insight Generation${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Call queue function via Python
      MCP_PYTHON=$(gtd_get_mcp_python)
      if [[ -z "$MCP_PYTHON" ]]; then
        MCP_PYTHON="python3"
      fi
      
      MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      if [[ ! -f "$MCP_SERVER" ]]; then
        MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
      fi
      
      if [[ ! -f "$MCP_SERVER" ]]; then
        echo -e "${RED}❌ MCP server not found${NC}"
      else
        echo "Queuing insight generation..."
        result=$("$MCP_PYTHON" -c "
import sys
sys.path.insert(0, '$(dirname "$MCP_SERVER")')
from gtd_mcp_server import queue_deep_analysis

status = queue_deep_analysis('generate_insights', {'focus': 'general'})
print(status)
" 2>&1)
        
        if [[ "$result" == *"queued"* ]] || [[ "$result" == *"logged"* ]]; then
          echo -e "${GREEN}✅ Job queued successfully${NC}"
          echo ""
          if [[ "$result" == *"file"* ]]; then
            echo "Queue method: ${CYAN}File queue${NC}"
            echo "Queue file: ${CYAN}~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
            echo ""
            echo "To verify the job was queued:"
            echo -e "  ${CYAN}wc -l ~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
            echo -e "  ${CYAN}tail -1 ~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
          else
            echo "Queue method: ${CYAN}RabbitMQ${NC}"
          fi
          echo ""
          echo "Results will be saved to: ${CYAN}~/Documents/gtd/deep_analysis_results/${NC}"
          echo ""
          echo "Note: Make sure the background worker is running to process this job."
        else
          echo -e "${RED}❌ Failed to queue job${NC}"
          echo "Error: $result"
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    11)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🔍 Scan Analysis Results for Suggestions${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will scan recent deep analysis results (connections, insights, energy analysis)"
      echo "and extract actionable suggestions that you can review and turn into tasks."
      echo ""
      echo -n "How many days back to scan? (default: 7): "
      read days_input
      days=${days_input:-7}
      
      echo ""
      echo "Scanning analysis results..."
      
      MCP_PYTHON=$(gtd_get_mcp_python)
      if [[ -z "$MCP_PYTHON" ]]; then
        MCP_PYTHON="python3"
      fi
      
      MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      if [[ ! -f "$MCP_SERVER" ]]; then
        MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
      fi
      
      if [[ ! -f "$MCP_SERVER" ]]; then
        echo -e "${RED}❌ MCP server not found${NC}"
      else
        result=$("$MCP_PYTHON" -c "
import sys
sys.path.insert(0, '$(dirname "$MCP_SERVER")')
from gtd_mcp_server import scan_analysis_results_for_suggestions
import json
result = scan_analysis_results_for_suggestions($days, [])
print(json.dumps(result, indent=2))
" 2>&1)
        
        if echo "$result" | "$MCP_PYTHON" -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
          echo ""
          echo "$result" | "$MCP_PYTHON" -c "
import sys, json
data = json.load(sys.stdin)
if data.get('success'):
    print('✅', data.get('message', 'Scan completed'))
    print('')
    if data.get('suggestions_created', 0) > 0:
        print('📋 Created', data['suggestions_created'], 'suggestion(s):')
        print('')
        for i, sug in enumerate(data.get('suggestions', []), 1):
            title = sug.get('title', 'Unknown')
            reason = sug.get('reason', '')
            # Display full title and reason (they're stored complete)
            print(f'  {i}. {title}')
            if reason:
                # Wrap long reasons for readability
                if len(reason) > 100:
                    print(f'     Reason: {reason[:97]}...')
                else:
                    print(f'     Reason: {reason}')
            print('')
        print('💡 Review these suggestions with option 2 (Review pending suggestions)')
    else:
        print('ℹ️  No new suggestions extracted from analysis results')
    if data.get('files_scanned', 0) > 0:
        print('')
        print('📁 Files scanned:', ', '.join(data.get('files', [])[:5]))
        if len(data.get('files', [])) > 5:
            print('   ... and', len(data.get('files', [])) - 5, 'more')
else:
    print('❌', data.get('message', 'Scan failed'))
" 2>/dev/null || echo "$result"
        else
          echo ""
          echo "$result"
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    12)
      # View analysis results - source the function if needed
      # Check if function exists, if not, try to source the file
      if ! type view_analysis_results &>/dev/null 2>&1; then
        # Try to source gtd-wizard-outputs.sh if not already loaded
        local OUTPUTS_FILE="$HOME/code/dotfiles/bin/gtd-wizard-outputs.sh"
        if [[ ! -f "$OUTPUTS_FILE" ]]; then
          OUTPUTS_FILE="$HOME/code/personal/dotfiles/bin/gtd-wizard-outputs.sh"
        fi
        if [[ -f "$OUTPUTS_FILE" ]]; then
          source "$OUTPUTS_FILE" 2>/dev/null
        fi
      fi
      
      # Now try to call the function
      if type view_analysis_results &>/dev/null 2>&1; then
        view_analysis_results
      else
        echo ""
        echo "⚠️  Analysis viewer not available. Please use Review Wizard (option 6) → option 8"
        echo ""
        echo "Press Enter to continue..."
        read
      fi
      ;;
    13)
      clear
      # Run MCP status check
      STATUS_SCRIPT="$HOME/code/dotfiles/mcp/gtd_mcp_status.sh"
      if [[ ! -f "$STATUS_SCRIPT" ]]; then
        STATUS_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_mcp_status.sh"
      fi
      
      if [[ -f "$STATUS_SCRIPT" ]]; then
        bash "$STATUS_SCRIPT"
      else
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📊 MCP System Status${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Status script not found at: $STATUS_SCRIPT"
        echo ""
        echo "Quick checks:"
        echo ""
        
        # Quick LM Studio check
        if curl -s "http://localhost:1234/v1/models" >/dev/null 2>&1; then
          echo -e "${GREEN}✅ LM Studio: Running${NC}"
        else
          echo -e "${RED}❌ LM Studio: Not running${NC}"
        fi
        
        # Quick worker check
        if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
          echo -e "${GREEN}✅ Background Worker: Running${NC}"
        else
          echo -e "${CYAN}ℹ️  Background Worker: Not running${NC}"
        fi
        
        # Quick suggestions check
        SUGGESTIONS_DIR="${GTD_BASE_DIR}/suggestions"
        if [[ -d "$SUGGESTIONS_DIR" ]]; then
          pending_count=$(find "$SUGGESTIONS_DIR" -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; 2>/dev/null | wc -l | tr -d ' ')
          if [[ "$pending_count" -gt 0 ]]; then
            echo -e "${YELLOW}⚠️  Pending Suggestions: $pending_count${NC}"
          else
            echo -e "${GREEN}✅ Pending Suggestions: None${NC}"
          fi
        fi
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    14)
      deployment_wizard
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

deployment_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🚀 Kubernetes Deployment Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) Build Docker image"
  echo "  2) Deploy worker to Kubernetes"
  echo "  3) Update deployment (rebuild & redeploy)"
  echo "  4) Check deployment status"
  echo "  5) View worker logs"
  echo "  6) Remove deployment"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read deploy_choice
  
  DEPLOY_SCRIPT="$HOME/code/dotfiles/mcp/deploy.sh"
  if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
    DEPLOY_SCRIPT="$HOME/code/personal/dotfiles/mcp/deploy.sh"
  fi
  
  if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
    echo ""
    echo "❌ Deployment script not found: $DEPLOY_SCRIPT"
    echo ""
    echo "Make sure the MCP system is set up. See mcp/README.md for details."
    echo ""
    echo "Press Enter to continue..."
    read
    return 1
  fi
  
  case "$deploy_choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🐳 Building Docker Image${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      bash "$DEPLOY_SCRIPT" build
      ;;
    2)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}☸️  Deploying to Kubernetes${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      bash "$DEPLOY_SCRIPT" deploy
      ;;
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🔄 Updating Deployment${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      bash "$DEPLOY_SCRIPT" update
      ;;
    4)
      clear
      bash "$DEPLOY_SCRIPT" status
      ;;
    5)
      clear
      bash "$DEPLOY_SCRIPT" logs
      ;;
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🗑️  Removing Deployment${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "⚠️  This will remove the worker deployment from Kubernetes."
      echo ""
      echo -n "Are you sure? (y/n): "
      read confirm
      if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        bash "$DEPLOY_SCRIPT" undeploy
      else
        echo "Cancelled."
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
  echo "Press Enter to continue..."
  read
}

gamification_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎮 Gamification & Habitica${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_gamification_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) 📊 View Gamification Dashboard"
  echo "  2) 🎖️  View Badge Progress"
  echo "  3) 🏆 Check Achievements"
  echo "  4) 🔥 View Streaks"
  echo "  5) 📈 View Statistics"
  echo "  6) 🎯 Award XP Manually"
  echo "  7) 🤖 AI Badge Suggestions"
  echo "  8) 🎮 Habitica Integration"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read gamify_choice
  
  case "$gamify_choice" in
    1)
      echo ""
      if command -v gtd-gamify &>/dev/null; then
        gtd-gamify dashboard
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/dotfiles/bin/gtd-gamify" dashboard
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-gamify" dashboard
      else
        echo "❌ gtd-gamify command not found"
        echo ""
        echo "Gamification system not installed. See zsh/GAMIFICATION_QUICK_START.md for setup."
      fi
      ;;
    2)
      echo ""
      if command -v gtd-gamify &>/dev/null; then
        gtd-gamify badge-progress
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/dotfiles/bin/gtd-gamify" badge-progress
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-gamify" badge-progress
      else
        echo "❌ gtd-gamify command not found"
        echo ""
        echo "Gamification system not installed. See zsh/GAMIFICATION_QUICK_START.md for setup."
      fi
      ;;
    3)
      echo ""
      if command -v gtd-gamify &>/dev/null; then
        gtd-gamify achievements
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/dotfiles/bin/gtd-gamify" achievements
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-gamify" achievements
      else
        echo "❌ gtd-gamify command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    4)
      echo ""
      echo -e "${BOLD}Streak Information:${NC}"
      echo ""
      if command -v gtd-gamify &>/dev/null; then
        gtd-gamify dashboard | grep -A 10 "Streaks"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/dotfiles/bin/gtd-gamify" dashboard | grep -A 10 "Streaks"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-gamify" dashboard | grep -A 10 "Streaks"
      else
        echo "❌ gtd-gamify command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    5)
      echo ""
      echo -e "${BOLD}Statistics:${NC}"
      echo ""
      if command -v gtd-gamify &>/dev/null; then
        gtd-gamify dashboard | grep -A 10 "Statistics"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/dotfiles/bin/gtd-gamify" dashboard | grep -A 10 "Statistics"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-gamify" dashboard | grep -A 10 "Statistics"
      else
        echo "❌ gtd-gamify command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    6)
      echo ""
      echo -n "XP Amount: "
      read xp_amount
      if [[ -z "$xp_amount" ]] || ! [[ "$xp_amount" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid XP amount"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo -n "Reason: "
      read reason
      reason=${reason:-"Manual award"}
      
      echo -n "Activity Type (optional): "
      read activity_type
      activity_type=${activity_type:-"general"}
      
      if command -v gtd-gamify &>/dev/null; then
        gtd-gamify award "$xp_amount" "$reason" "$activity_type"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/dotfiles/bin/gtd-gamify" award "$xp_amount" "$reason" "$activity_type"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-gamify" award "$xp_amount" "$reason" "$activity_type"
      else
        echo "❌ gtd-gamify command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    7)
      echo ""
      echo "🤖 AI Badge Suggestions:"
      echo ""
      echo "  1) Analyze logs and suggest badges (week)"
      echo "  2) Analyze logs and suggest badges (month)"
      echo "  3) Review pending badge suggestions"
      echo ""
      echo -n "Choose: "
      read badge_suggest_choice
      
      case "$badge_suggest_choice" in
        1)
          echo ""
          if command -v gtd-gamify &>/dev/null; then
            gtd-gamify custom-badge suggest week hank
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
            "$HOME/code/dotfiles/bin/gtd-gamify" custom-badge suggest week hank
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-gamify" custom-badge suggest week hank
          else
            echo "❌ gtd-gamify not found"
          fi
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        2)
          echo ""
          if command -v gtd-gamify &>/dev/null; then
            gtd-gamify custom-badge suggest month hank
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
            "$HOME/code/dotfiles/bin/gtd-gamify" custom-badge suggest month hank
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-gamify" custom-badge suggest month hank
          else
            echo "❌ gtd-gamify not found"
          fi
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        3)
          echo ""
          if command -v gtd-gamify &>/dev/null; then
            gtd-gamify custom-badge review
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-gamify" ]]; then
            "$HOME/code/dotfiles/bin/gtd-gamify" custom-badge review
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-gamify" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-gamify" custom-badge review
          else
            echo "❌ gtd-gamify not found"
          fi
          echo ""
          echo "Press Enter to continue..."
          read
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      ;;
    8)
      echo ""
      echo "Habitica Integration:"
      echo ""
      echo "  1) Setup Habitica Integration"
      echo "  2) Sync GTD → Habitica"
      echo "  3) Sync Habitica → GTD"
      echo "  4) Check Sync Status"
      echo ""
      echo -n "Choose: "
      read habitica_choice
      
      case "$habitica_choice" in
        1)
          echo ""
          if command -v gtd-habitica &>/dev/null; then
            gtd-habitica setup
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/dotfiles/bin/gtd-habitica" setup
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-habitica" setup
          else
            echo "❌ gtd-habitica command not found"
          fi
          ;;
        2)
          echo ""
          echo "Syncing GTD to Habitica..."
          if command -v gtd-habitica &>/dev/null; then
            gtd-habitica sync
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/dotfiles/bin/gtd-habitica" sync
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-habitica" sync
          else
            echo "❌ gtd-habitica command not found"
          fi
          ;;
        3)
          echo ""
          echo "Syncing Habitica to GTD..."
          if command -v gtd-habitica &>/dev/null; then
            gtd-habitica sync-back
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/dotfiles/bin/gtd-habitica" sync-back
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-habitica" sync-back
          else
            echo "❌ gtd-habitica command not found"
          fi
          ;;
        4)
          echo ""
          if command -v gtd-habitica &>/dev/null; then
            gtd-habitica status
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/dotfiles/bin/gtd-habitica" status
          elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-habitica" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-habitica" status
          else
            echo "❌ gtd-habitica command not found"
          fi
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
  esac
}

healthkit_wizard() {
  # Load daily log config
  DAILY_LOG_CONFIG="$HOME/.daily_log_config"
  if [[ -f "$HOME/code/dotfiles/zsh/.daily_log_config" ]]; then
    DAILY_LOG_CONFIG="$HOME/code/dotfiles/zsh/.daily_log_config"
  elif [[ -f "$HOME/code/personal/dotfiles/zsh/.daily_log_config" ]]; then
    DAILY_LOG_CONFIG="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
  fi
  
  if [[ -f "$DAILY_LOG_CONFIG" ]]; then
    source "$DAILY_LOG_CONFIG"
  fi
  
  # Default values
  DAILY_LOG_DIR="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
  
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
  
  # Helper functions for date manipulation
  get_date_by_offset() {
    local offset="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      $DATE_CMD -v${offset}d +"%Y-%m-%d" 2>/dev/null || $DATE_CMD +"%Y-%m-%d"
    else
      $DATE_CMD -d "${offset} days" +"%Y-%m-%d" 2>/dev/null || $DATE_CMD +"%Y-%m-%d"
    fi
  }
  
  get_today() {
    $DATE_CMD +"%Y-%m-%d"
  }
  
  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}💪 HealthKit & Health Data${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    show_healthkit_guide
    echo -e "${BOLD}What would you like to do?${NC}"
    echo ""
    echo "  1) 📊 View Today's Health Summary"
    echo "  2) 📅 View Health Data for Specific Date"
    echo "  3) 📈 View Health Trends (Date Range)"
    echo "  4) 🔄 Sync Health Data from Apple Health"
    echo "  5) 💡 Health Insights & Interpretation"
    echo "  6) 📋 View Recent Health Entries"
    echo "  7) 🔍 Search Health Data"
    echo "  8) 📖 HealthKit Setup Guide"
    echo -e "  ${GRAY}9) 🔵 Sync Health Data from Google Health/Fitness (Currently Disabled)${NC}"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read health_choice
    
    case "$health_choice" in
      1)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📊 Today's Health Summary${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        local today=$(get_today)
        local log_file="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
        
        if [[ ! -f "$log_file" ]]; then
          echo "❌ No daily log found for today"
          echo ""
          echo "💡 Tip: Health data is logged automatically via Apple Health shortcuts"
          echo "   or manually using: gtd-sync-health"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        # Parse health data
        local health_data=$(parse_health_data_from_log "$log_file" "$today")
        
        if [[ -z "$health_data" || "$health_data" == "steps:|calories:|exercise_min:|stand_hours:|heart_rate:|workouts:" ]]; then
          echo "⚠️  No health data found in today's log"
          echo ""
          echo "💡 To sync health data:"
          echo "   • Run option 4 (Sync Health Data) in this menu"
          echo "   • Or manually: gtd-sync-health"
          echo "   • Or set up automatic sync: see Setup Guide (option 8)"
          echo ""
        else
          # Extract values
          local steps=$(echo "$health_data" | grep -oE "steps:[^|]*" | cut -d':' -f2)
          local calories=$(echo "$health_data" | grep -oE "calories:[^|]*" | cut -d':' -f2)
          local exercise_min=$(echo "$health_data" | grep -oE "exercise_min:[^|]*" | cut -d':' -f2)
          local stand_hours=$(echo "$health_data" | grep -oE "stand_hours:[^|]*" | cut -d':' -f2)
          local heart_rate=$(echo "$health_data" | grep -oE "heart_rate:[^|]*" | cut -d':' -f2)
          local workouts=$(echo "$health_data" | grep -oE "workouts:[^|]*" | cut -d':' -f2)
          
          echo -e "${BOLD}Date:${NC} $today"
          echo ""
          
          # Display metrics
          if [[ -n "$steps" && "$steps" != "" ]]; then
            echo -e "${BOLD}👣 Steps:${NC} $(printf "%'d" "$steps" 2>/dev/null || echo "$steps")"
          fi
          
          if [[ -n "$calories" && "$calories" != "" ]]; then
            echo -e "${BOLD}🔥 Calories:${NC} $(printf "%'d" "$calories" 2>/dev/null || echo "$calories")"
          fi
          
          if [[ -n "$exercise_min" && "$exercise_min" != "" ]]; then
            echo -e "${BOLD}⚡ Exercise Minutes:${NC} $exercise_min min"
          fi
          
          if [[ -n "$stand_hours" && "$stand_hours" != "" ]]; then
            echo -e "${BOLD}🕐 Stand Hours:${NC} $stand_hours/12"
          fi
          
          if [[ -n "$heart_rate" && "$heart_rate" != "" ]]; then
            echo -e "${BOLD}❤️  Heart Rate:${NC} $heart_rate bpm"
          fi
          
          if [[ -n "$workouts" && "$workouts" != "" ]]; then
            echo ""
            echo -e "${BOLD}🏃 Workouts:${NC}"
            echo "$workouts" | while IFS= read -r workout; do
              if [[ -n "$workout" ]]; then
                echo "   • $workout"
              fi
            done
          fi
        fi
        
        # Also show raw health entries from log
        echo ""
        echo -e "${BOLD}📝 Recent Health Entries:${NC}"
        if [[ -f "$log_file" ]]; then
          grep -iE "Apple Watch|Health|workout|exercise|steps|calories|heart rate" "$log_file" 2>/dev/null | tail -10 | while IFS= read -r entry; do
            echo "   $entry"
          done || echo "   No health entries found"
        fi
        
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    2)
      configure_mode_specific_ai
      ;;
    3)
      clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📅 Health Data for Specific Date${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -n "Enter date (YYYY-MM-DD) or press Enter for today: "
        read input_date
        
        if [[ -z "$input_date" ]]; then
          input_date=$(get_today)
        fi
        
        local log_file="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${input_date}.md"
        
        if [[ ! -f "$log_file" ]]; then
          echo ""
          echo "❌ No daily log found for $input_date"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo -e "${BOLD}Date:${NC} $input_date"
        echo ""
        
        local health_data=$(parse_health_data_from_log "$log_file" "$input_date")
        
        if [[ -z "$health_data" || "$health_data" == "steps:|calories:|exercise_min:|stand_hours:|heart_rate:|workouts:" ]]; then
          echo "⚠️  No health data found for this date"
        else
          local steps=$(echo "$health_data" | grep -oE "steps:[^|]*" | cut -d':' -f2)
          local calories=$(echo "$health_data" | grep -oE "calories:[^|]*" | cut -d':' -f2)
          local exercise_min=$(echo "$health_data" | grep -oE "exercise_min:[^|]*" | cut -d':' -f2)
          local stand_hours=$(echo "$health_data" | grep -oE "stand_hours:[^|]*" | cut -d':' -f2)
          local heart_rate=$(echo "$health_data" | grep -oE "heart_rate:[^|]*" | cut -d':' -f2)
          local workouts=$(echo "$health_data" | grep -oE "workouts:[^|]*" | cut -d':' -f2)
          
          if [[ -n "$steps" && "$steps" != "" ]]; then
            echo -e "${BOLD}👣 Steps:${NC} $(printf "%'d" "$steps" 2>/dev/null || echo "$steps")"
          fi
          if [[ -n "$calories" && "$calories" != "" ]]; then
            echo -e "${BOLD}🔥 Calories:${NC} $(printf "%'d" "$calories" 2>/dev/null || echo "$calories")"
          fi
          if [[ -n "$exercise_min" && "$exercise_min" != "" ]]; then
            echo -e "${BOLD}⚡ Exercise Minutes:${NC} $exercise_min min"
          fi
          if [[ -n "$stand_hours" && "$stand_hours" != "" ]]; then
            echo -e "${BOLD}🕐 Stand Hours:${NC} $stand_hours/12"
          fi
          if [[ -n "$heart_rate" && "$heart_rate" != "" ]]; then
            echo -e "${BOLD}❤️  Heart Rate:${NC} $heart_rate bpm"
          fi
          if [[ -n "$workouts" && "$workouts" != "" ]]; then
            echo ""
            echo -e "${BOLD}🏃 Workouts:${NC}"
            echo "$workouts" | while IFS= read -r workout; do
              if [[ -n "$workout" ]]; then
                echo "   • $workout"
              fi
            done
          fi
        fi
        
        echo ""
        echo -e "${BOLD}📝 All Health Entries for $input_date:${NC}"
        if [[ -f "$log_file" ]]; then
          grep -iE "Apple Watch|Health|workout|exercise|steps|calories|heart rate" "$log_file" 2>/dev/null | while IFS= read -r entry; do
            echo "   $entry"
          done || echo "   No health entries found"
        fi
        
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      3)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📈 Health Trends (Date Range)${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -n "Start date (YYYY-MM-DD) or press Enter for 7 days ago: "
        read start_date
        echo -n "End date (YYYY-MM-DD) or press Enter for today: "
        read end_date
        
        if [[ -z "$start_date" ]]; then
          start_date=$(get_date_by_offset -7)
        fi
        if [[ -z "$end_date" ]]; then
          end_date=$(get_today)
        fi
        
        echo ""
        echo -e "${BOLD}Health Trends from $start_date to $end_date${NC}"
        echo ""
        
        # Calculate number of days between dates
        local start_ts=$($DATE_CMD -j -f "%Y-%m-%d" "$start_date" +%s 2>/dev/null || echo "0")
        local end_ts=$($DATE_CMD -j -f "%Y-%m-%d" "$end_date" +%s 2>/dev/null || echo "0")
        
        if [[ "$OSTYPE" != "darwin"* ]]; then
          start_ts=$($DATE_CMD -d "$start_date" +%s 2>/dev/null || echo "0")
          end_ts=$($DATE_CMD -d "$end_date" +%s 2>/dev/null || echo "0")
        fi
        
        if [[ "$start_ts" == "0" || "$end_ts" == "0" ]]; then
          echo "❌ Invalid date format. Please use YYYY-MM-DD"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        local days_diff=$(( (end_ts - start_ts) / 86400 ))
        if [[ $days_diff -lt 0 ]]; then
          echo "❌ Start date must be before end date"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if [[ $days_diff -gt 90 ]]; then
          echo "⚠️  Date range is large ($days_diff days). This may take a moment..."
          echo ""
        fi
        
        # Simple trend display - show summary for each day
        local day_count=0
        
        for i in $(seq 0 $days_diff); do
          local current_date=""
          if [[ "$OSTYPE" == "darwin"* ]]; then
            current_date=$($DATE_CMD -j -f "%Y-%m-%d" -v+${i}d "$start_date" +"%Y-%m-%d" 2>/dev/null || echo "")
          else
            current_date=$($DATE_CMD -d "$start_date +${i} days" +"%Y-%m-%d" 2>/dev/null || echo "")
          fi
          
          if [[ -z "$current_date" ]]; then
            continue
          fi
          
          local log_file="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${current_date}.md"
          if [[ -f "$log_file" ]]; then
            local has_health=$(grep -qiE "Apple Watch|Health|workout|exercise|steps|calories" "$log_file" 2>/dev/null && echo "yes" || echo "no")
            if [[ "$has_health" == "yes" ]]; then
              local steps=$(grep -oiE "[0-9,]+ steps" "$log_file" 2>/dev/null | grep -oE "[0-9,]+" | head -1 | tr -d ',')
              if [[ -n "$steps" ]]; then
                echo -e "$current_date: 👣 $(printf "%'d" "$steps" 2>/dev/null || echo "$steps") steps"
              else
                echo -e "$current_date: ✓ Health data logged"
              fi
              ((day_count++))
            fi
          fi
        done
        
        if [[ $day_count -eq 0 ]]; then
          echo "⚠️  No health data found in this date range"
        fi
        
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      4)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}🔄 Sync Health Data from Apple Health${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Syncing health data from Apple Health to your daily log..."
        echo ""
        
        if command -v gtd-sync-health &>/dev/null; then
          gtd-sync-health
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-sync-health" ]]; then
          "$HOME/code/dotfiles/bin/gtd-sync-health"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-sync-health" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-sync-health"
        else
          echo "❌ gtd-sync-health command not found"
          echo ""
          echo "💡 Make sure your dotfiles are set up correctly"
        fi
        
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      5)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}💡 Health Insights & Interpretation${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        local today=$(get_today)
        local log_file="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
        
        if [[ ! -f "$log_file" ]]; then
          echo "❌ No daily log found for today"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        # Check for workouts
        local has_workout=$(grep -qiE "workout|exercise|kettlebell|walk|run|weight|lifting|gym|fitness|training" "$log_file" 2>/dev/null && echo "yes" || echo "no")
        
        # Check for medication
        local has_pills=$(grep -qiE "pill|pills|medication|medicine|meds|took.*pill|took.*med" "$log_file" 2>/dev/null && echo "yes" || echo "no")
        
        # Extract metrics
        local steps=$(grep -oiE "[0-9,]+ steps" "$log_file" 2>/dev/null | grep -oE "[0-9,]+" | head -1 | tr -d ',')
        local exercise_min=$(grep -oiE "[0-9]+ min exercise|[0-9]+ exercise minutes" "$log_file" 2>/dev/null | grep -oE "[0-9]+" | head -1)
        
        echo -e "${BOLD}Health Status for $today${NC}"
        echo ""
        
        if [[ "$has_workout" == "yes" ]]; then
          echo -e "${GREEN}✅ Exercise:${NC} You've logged exercise today! Great work!"
        else
          echo -e "${YELLOW}⚠️  Exercise:${NC} No exercise logged today. Consider a workout!"
        fi
        
        if [[ "$has_pills" == "yes" ]]; then
          echo -e "${GREEN}✅ Medication:${NC} Medication logged. Stay consistent!"
        else
          echo -e "${YELLOW}⚠️  Medication:${NC} No medication logged today."
        fi
        
        if [[ -n "$steps" && "$steps" != "" ]]; then
          if [[ "$steps" -ge 10000 ]]; then
            echo -e "${GREEN}✅ Steps:${NC} Excellent! You've hit 10,000+ steps today! ($steps)"
          elif [[ "$steps" -ge 7500 ]]; then
            echo -e "${CYAN}✓ Steps:${NC} Good progress! $steps steps. Almost at 10k!"
          elif [[ "$steps" -ge 5000 ]]; then
            echo -e "${YELLOW}📊 Steps:${NC} You're at $steps steps. Keep moving!"
          else
            echo -e "${YELLOW}📊 Steps:${NC} $steps steps logged. More movement might help!"
          fi
        fi
        
        if [[ -n "$exercise_min" && "$exercise_min" != "" ]]; then
          if [[ "$exercise_min" -ge 30 ]]; then
            echo -e "${GREEN}✅ Exercise Minutes:${NC} Great! $exercise_min minutes of exercise!"
          elif [[ "$exercise_min" -ge 15 ]]; then
            echo -e "${CYAN}✓ Exercise Minutes:${NC} Good start! $exercise_min minutes logged."
          else
            echo -e "${YELLOW}📊 Exercise Minutes:${NC} $exercise_min minutes. Aim for 30+!"
          fi
        fi
        
        echo ""
        echo -e "${BOLD}💡 Tips:${NC}"
        echo "   • Sync health data regularly using option 4"
        echo "   • Set up automatic evening sync (see Setup Guide)"
        echo "   • Track workouts, steps, and other metrics consistently"
        echo ""
        
        echo "Press Enter to continue..."
        read
        ;;
      6)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📋 Recent Health Entries${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -n "How many days to check? (default: 7): "
        read days
        days="${days:-7}"
        
        echo ""
        echo -e "${BOLD}Health Entries from Last $days Days:${NC}"
        echo ""
        
        for i in $(seq 0 $((days-1))); do
          local check_date=$(get_date_by_offset "-$i")
          local log_file="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${check_date}.md"
          
          if [[ -f "$log_file" ]]; then
            local health_entries=$(grep -iE "Apple Watch|Health|workout|exercise|steps|calories|heart rate" "$log_file" 2>/dev/null)
            if [[ -n "$health_entries" ]]; then
              echo -e "${BOLD}$check_date:${NC}"
              echo "$health_entries" | while IFS= read -r entry; do
                echo "   $entry"
              done
              echo ""
            fi
          fi
        done
        
        echo "Press Enter to continue..."
        read
        ;;
      7)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}🔍 Search Health Data${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -n "Search term (e.g., 'workout', 'steps', 'calories'): "
        read search_term
        
        if [[ -z "$search_term" ]]; then
          echo "❌ No search term provided"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo -e "${BOLD}Searching for: $search_term${NC}"
        echo ""
        
        local log_dir="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
        local found_count=0
        
        for log_file in "$log_dir"/*.md; do
          if [[ -f "$log_file" ]]; then
            local matches=$(grep -iE "$search_term" "$log_file" 2>/dev/null | grep -iE "Apple Watch|Health|workout|exercise|steps|calories|heart rate")
            if [[ -n "$matches" ]]; then
              local date=$(basename "$log_file" .md)
              echo -e "${BOLD}$date:${NC}"
              echo "$matches" | while IFS= read -r match; do
                echo "   $match"
              done
              echo ""
              ((found_count++))
            fi
          fi
        done
        
        if [[ $found_count -eq 0 ]]; then
          echo "⚠️  No matches found"
        else
          echo "Found in $found_count day(s)"
        fi
        
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      8)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📖 HealthKit Setup Guide${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}${GREEN}Quick Setup Steps:${NC}"
        echo ""
        echo -e "${BOLD}${YELLOW}1.${NC} ${BOLD}Create Apple Shortcuts${NC}"
        echo -e "   ${CYAN}•${NC} Open Shortcuts app on iPhone/iPad/Mac"
        echo -e "   ${CYAN}•${NC} Create shortcuts to log health data"
        echo -e "   ${CYAN}•${NC} See: ${GREEN}zsh/APPLE_HEALTH_SHORTCUTS_SETUP.md${NC}"
        echo ""
        echo -e "${BOLD}${YELLOW}2.${NC} ${BOLD}Test Health Logging${NC}"
        echo -e "   ${CYAN}•${NC} Run: ${GREEN}gtd-sync-health${NC}"
        echo -e "   ${CYAN}•${NC} Or use option 4 in this menu"
        echo ""
        echo -e "${BOLD}${YELLOW}3.${NC} ${BOLD}Set Up Automatic Sync${NC}"
        echo -e "   ${CYAN}•${NC} Evening sync: see ${GREEN}zsh/EVENING_HEALTH_SYNC_SETUP.md${NC}"
        echo -e "   ${CYAN}•${NC} Or use Shortcuts automation"
        echo ""
        echo -e "${BOLD}${YELLOW}4.${NC} ${BOLD}View Your Health Data${NC}"
        echo -e "   ${CYAN}•${NC} Use options 1-3 in this menu"
        echo -e "   ${CYAN}•${NC} Data appears in your daily logs"
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}${GREEN}📚 Documentation:${NC}"
        echo ""
        echo -e "   ${CYAN}📄${NC} ${GREEN}APPLE_HEALTH_INTEGRATION_QUICK_START.md${NC}"
        echo -e "      Quick start guide for HealthKit integration"
        echo ""
        echo -e "   ${CYAN}📄${NC} ${GREEN}APPLE_HEALTH_SHORTCUTS_SETUP.md${NC}"
        echo -e "      Complete setup instructions for Shortcuts"
        echo ""
        echo -e "   ${CYAN}📄${NC} ${GREEN}APPLE_HEALTH_SHORTCUTS_EXAMPLES.md${NC}"
        echo -e "      Ready-to-use shortcut templates"
        echo ""
        echo -e "   ${CYAN}📄${NC} ${GREEN}EVENING_HEALTH_SYNC_SETUP.md${NC}"
        echo -e "      Automatic evening sync configuration"
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}💡${NC} ${YELLOW}Tip:${NC} All documentation files are in ${GREEN}zsh/${NC} directory"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      9)
        clear
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}🔵 Google Health/Fitness Integration${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  This feature is currently disabled${NC}"
        echo ""
        echo "Google Health/Fitness integration has been implemented but is not"
        echo "currently active. The integration supports:"
        echo ""
        echo "  • Google Takeout export processing"
        echo "  • Google Data Portability API (OAuth)"
        echo "  • Automatic health data logging"
        echo ""
        echo -e "${BOLD}To enable this feature:${NC}"
        echo "  1. See setup guide: ${GREEN}zsh/GOOGLE_HEALTH_SETUP.md${NC}"
        echo "  2. For OAuth setup: ${GREEN}zsh/GOOGLE_HEALTH_OAUTH_SETUP.md${NC}"
        echo "  3. Or use Google Takeout export method (no OAuth needed)"
        echo ""
        echo "Once configured, you can use:"
        echo "  ${GREEN}gtd-sync-google-health${NC} (command line)"
        echo "  or enable option 9 in this menu"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0)
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

calendar_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📅 Calendar Integration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    show_calendar_guide
    echo "What would you like to do?"
    echo ""
    echo "  1) View calendar (next 7 days)"
    echo "  2) View calendar (custom days)"
    echo "  3) Check for scheduling conflicts"
    echo "  4) Sync task to calendar"
    echo "  5) Add event to Google Calendar"
    echo "  6) List Google Calendar events"
    echo ""
    echo -e "${BOLD}Enhanced Features:${NC}"
    echo "  7) 📅 Show upcoming events (planning context)"
    echo "  8) ⚠️  Check over-scheduled days"
    echo "  9) ⏰ Suggest time-blocking for tasks"
    echo "  10) ⚡ Energy pattern → calendar optimization"
    echo "  11) 📊 Calendar insights & analysis"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read calendar_choice
    
    case "$calendar_choice" in
      1)
        echo ""
        if command -v gtd-calendar &>/dev/null; then
          gtd-calendar view 7
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/dotfiles/bin/gtd-calendar" view 7
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-calendar" view 7
        else
          echo "❌ gtd-calendar command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        echo -n "How many days to view? (default: 7): "
        read days
        days="${days:-7}"
        echo ""
        if command -v gtd-calendar &>/dev/null; then
          gtd-calendar view "$days"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/dotfiles/bin/gtd-calendar" view "$days"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-calendar" view "$days"
        else
          echo "❌ gtd-calendar command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      3)
        echo ""
        echo "Check for scheduling conflicts"
        echo ""
        echo -n "Start time (e.g., '2024-12-05 10:00'): "
        read start_time
        echo -n "End time (e.g., '2024-12-05 11:00'): "
        read end_time
        
        if [[ -z "$start_time" || -z "$end_time" ]]; then
          echo "❌ Both start and end times are required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        if command -v gtd-calendar &>/dev/null; then
          gtd-calendar conflicts "$start_time" "$end_time"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/dotfiles/bin/gtd-calendar" conflicts "$start_time" "$end_time"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-calendar" conflicts "$start_time" "$end_time"
        else
          echo "❌ gtd-calendar command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      4)
        echo ""
        echo "Sync a task to calendar"
        echo ""
        gtd-task list
        echo ""
        echo "💡 Look at the task list above. Each task shows an 'ID:' line."
        echo "   Copy the task ID (e.g., 20240101120000-task) and paste it below."
        echo ""
        echo -n "Task ID to sync: "
        read task_id
        
        if [[ -z "$task_id" ]]; then
          echo "❌ No task ID provided"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo ""
        echo "Which calendar?"
        echo "  1) Google Calendar"
        echo "  2) Office 365"
        echo ""
        echo -n "Choose (1 or 2): "
        read cal_type
        
        case "$cal_type" in
          1)
            calendar_type="google"
            ;;
          2)
            calendar_type="office365"
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
        if command -v gtd-calendar &>/dev/null; then
          gtd-calendar sync "$task_id" "$calendar_type"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/dotfiles/bin/gtd-calendar" sync "$task_id" "$calendar_type"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-calendar" sync "$task_id" "$calendar_type"
        else
          echo "❌ gtd-calendar command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      5)
        echo ""
        echo "Add event to Google Calendar"
        echo ""
        echo -n "Event title: "
        read event_title
        
        if [[ -z "$event_title" ]]; then
          echo "❌ Event title is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo -n "When (e.g., '2024-12-05 10:00' or 'tomorrow 2pm'): "
        read event_when
        
        if [[ -z "$event_when" ]]; then
          echo "❌ Event time is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        echo -n "Duration in minutes (default: 60): "
        read duration
        duration="${duration:-60}"
        
        echo -n "Description (optional): "
        read description
        
        echo ""
        if command -v gtd-calendar &>/dev/null; then
          gtd-calendar google add "$event_title" "$event_when" "$duration" "$description"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/dotfiles/bin/gtd-calendar" google add "$event_title" "$event_when" "$duration" "$description"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-calendar" google add "$event_title" "$event_when" "$duration" "$description"
        else
          echo "❌ gtd-calendar command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    6)
      echo ""
      echo "List calendar events from all configured calendars"
      echo ""
      echo -n "Start date (default: today): "
      read start_date
      start_date="${start_date:-today}"
      
      echo -n "End date (default: tomorrow): "
      read end_date
      end_date="${end_date:-tomorrow}"
      
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar list-events "$start_date" "$end_date"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" list-events "$start_date" "$end_date"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" list-events "$start_date" "$end_date"
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    7)
      echo ""
      echo -n "How many days ahead to show? (default: 7): "
      read days
      days="${days:-7}"
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar upcoming-context "$days"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" upcoming-context "$days"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" upcoming-context "$days"
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    8)
      echo ""
      echo -n "Check which date? (default: tomorrow): "
      read check_date
      check_date="${check_date:-tomorrow}"
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar check-over-scheduled "$check_date"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" check-over-scheduled "$check_date"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" check-over-scheduled "$check_date"
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    9)
      echo ""
      echo "Suggest time-blocking for a task"
      echo ""
      echo -n "Task title: "
      read task_title
      
      if [[ -z "$task_title" ]]; then
        echo "❌ Task title required"
        echo ""
        echo "Press Enter to continue..."
        read
        continue
      fi
      
      echo -n "Target date (default: tomorrow): "
      read target_date
      target_date="${target_date:-tomorrow}"
      
      echo -n "Duration in minutes (default: 60): "
      read duration
      duration="${duration:-60}"
      
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar suggest-time-blocking "$task_title" "$target_date" "$duration"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" suggest-time-blocking "$task_title" "$target_date" "$duration"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" suggest-time-blocking "$task_title" "$target_date" "$duration"
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    10)
      echo ""
      echo -n "Optimize calendar for which date? (default: tomorrow): "
      read opt_date
      opt_date="${opt_date:-tomorrow}"
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar optimize-energy "$opt_date"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" optimize-energy "$opt_date"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" optimize-energy "$opt_date"
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    11)
      echo ""
      echo -n "Get insights for which date? (default: tomorrow): "
      read insight_date
      insight_date="${insight_date:-tomorrow}"
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar insights "$insight_date"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" insights "$insight_date"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" insights "$insight_date"
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
    0|"")
      pop_menu
      return 0
      ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

tips_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💡 Daily Tips${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  if command -v gtd-tips &>/dev/null; then
    gtd-tips
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-tips" ]]; then
    "$HOME/code/dotfiles/bin/gtd-tips"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-tips" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-tips"
  else
    echo "❌ gtd-tips command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

# Kubernetes learning wizard
k8s_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}☸️  Kubernetes/CKA Learning Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_learning_guide
  echo "What would you like to do?"
  echo ""
  echo -e "${GREEN}Learning:${NC}"
  echo "  1) Start learning (interactive menu)"
  echo "  2) Learn specific topic"
  echo "  3) Create study plan"
  echo "  4) View study progress"
  echo ""
  echo -e "${MAGENTA}Gamification:${NC}"
  echo "  5) 🎮 Gamification Dashboard"
  echo ""
  echo -e "${BLUE}Practice:${NC}"
  echo "  6) ⌨️  Typing Simulator (Practice kubectl commands)"
  echo ""
  echo -e "${YELLOW}Quick Study:${NC}"
  echo "  7) ⚡ Quick Study (Low-energy activities)"
  echo ""
  echo -e "${CYAN}🎯 Quiz & Games:${NC}"
  echo "  8) 🎯 Take a Quiz (test your knowledge)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read k8s_choice
  
  case "$k8s_choice" in
    1)
      gtd-learn-kubernetes
      ;;
    2)
      echo ""
      echo "Available topics:"
      echo "  basics, pods, deployments, services, configmaps, storage, networking, troubleshooting, cka-exam, practice"
      echo ""
      echo -n "Topic: "
      read topic
      gtd-learn-kubernetes "$topic"
      ;;
    3)
      gtd-study-plan cka
      ;;
    4)
      gtd-learn-kubernetes
      # This will show progress in the menu
      ;;
    5)
      if command -v gtd-cka-gamification &>/dev/null; then
        gtd-cka-gamification dashboard
      else
        echo "❌ Gamification system not found"
        echo "   Make sure gtd-cka-gamification is in your PATH"
      fi
      ;;
    6)
      if command -v gtd-cka-typing &>/dev/null; then
        gtd-cka-typing
      else
        echo "❌ Typing simulator not found"
        echo "   Make sure gtd-cka-typing is in your PATH"
      fi
      ;;
    7)
      if command -v gtd-cka-quick &>/dev/null; then
        gtd-cka-quick
      else
        echo "❌ Quick study not found"
        echo "   Make sure gtd-cka-quick is in your PATH"
      fi
      ;;
    8)
      if command -v gtd-quiz &>/dev/null; then
        gtd-quiz kubernetes
      else
        echo "❌ Quiz system not found"
        echo "   Make sure gtd-quiz is in your PATH"
      fi
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      echo "Press Enter to continue..."
      read
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}

