#!/bin/bash
# GTD Wizard Output Functions
# Functions for viewing reviews, analysis results, and generating suggestions

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

# Load config (if load_gtd_config function exists)
if type load_gtd_config &>/dev/null 2>&1; then
  load_gtd_config 2>/dev/null || true
fi

# GTD_BASE_DIR is already set by init_gtd_paths in gtd-common.sh (DRY - reuse existing helper)
DEEP_ANALYSIS_DIR="${GTD_BASE_DIR}/deep_analysis_results"

# Review Wizard
review_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📋 Review Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "What would you like to review?"
  echo ""
  echo "  1) Review inbox"
  echo "  2) Review waiting items"
  echo "  3) Review projects"
  echo "  4) Review areas"
  echo "  5) Weekly review"
  echo "  6) Review completed tasks"
  echo "  7) Review archived items"
  echo "  8) 📋 View analysis results"
  echo "  9) 📊 Enhanced Review System"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read review_choice
  
  case "$review_choice" in
    1)
      echo "Opening inbox..."
      gtd-process
      ;;
    2)
      echo "Reviewing waiting items..."
      gtd-task list --waiting
      ;;
    3)
      echo "Reviewing projects..."
      gtd-project list
      ;;
    4)
      echo "Reviewing areas..."
      gtd-area list
      ;;
    5)
      echo "Starting weekly review..."
      gtd-review weekly
      ;;
    6)
      echo "Reviewing completed tasks..."
      gtd-task list --completed
      ;;
    7)
      echo "Reviewing archived items..."
      gtd-task list --archived
      ;;
    8)
      view_analysis_results
      ;;
    9)
      # Source enhanced review wizard if available
      local ENHANCED_REVIEW_FILE="$HOME/code/dotfiles/bin/gtd-wizard-enhanced-review.sh"
      if [[ ! -f "$ENHANCED_REVIEW_FILE" ]]; then
        ENHANCED_REVIEW_FILE="$HOME/code/personal/dotfiles/bin/gtd-wizard-enhanced-review.sh"
      fi
      if [[ -f "$ENHANCED_REVIEW_FILE" ]]; then
        source "$ENHANCED_REVIEW_FILE"
        enhanced_review_wizard
      else
        echo "Enhanced Review System not found"
        echo ""
        echo "Press Enter to continue..."
        read
      fi
      ;;
    0)
      return 0
      ;;
    *)
      echo "Invalid choice"
      sleep 1
      ;;
  esac
}

# View Analysis Results
view_analysis_results() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📋 Analysis Results Viewer${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if [[ ! -d "$DEEP_ANALYSIS_DIR" ]]; then
    echo "No analysis results directory found."
    echo "Analysis results will be saved to: $DEEP_ANALYSIS_DIR"
    echo ""
    echo "Press Enter to continue..."
    read
    return 0
  fi
  
  # Find all JSON analysis files
  local analysis_files=($(find "$DEEP_ANALYSIS_DIR" -name "*.json" -type f 2>/dev/null | sort -r))
  
  if [[ ${#analysis_files[@]} -eq 0 ]]; then
    echo "No analysis results found."
    echo ""
    echo "Press Enter to continue..."
    read
    return 0
  fi
  
  echo "Available analysis results:"
  echo ""
  
  # Display list with details
  local count=1
  local selected_files=()
  for file in "${analysis_files[@]}"; do
    local basename=$(basename "$file")
    local filename_no_ext="${basename%.json}"
    
    # Try to extract type and date from filename
    # Patterns: weekly_review_20251205_170713.json, insights_20251207_001226.json, connections_20251205_113930.json
    local type="Unknown"
    local date_str=""
    
    # Try to match pattern: type_date_timestamp or type_subtype_date_timestamp
    if [[ "$filename_no_ext" =~ _([0-9]{8}_[0-9]{6})$ ]]; then
      # Found date pattern at end (e.g., 20251205_170713)
      local date_part="${BASH_REMATCH[1]}"
      # Extract date: 20251205_170713 -> 2025-12-05 17:07
      if [[ "$date_part" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})$ ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}"
      fi
      
      # Extract type (everything before the date)
      local type_part="${filename_no_ext%_$date_part}"
      # Map common type prefixes
      if [[ "$type_part" == "weekly_review" ]]; then
        type="weekly_review"
      elif [[ "$type_part" == "insights" ]]; then
        type="insights"
      elif [[ "$type_part" == "connections" ]]; then
        type="connections"
      else
        type="$type_part"
      fi
    elif [[ "$basename" =~ ^([^_]+)_(.+)$ ]]; then
      # Fallback: simple pattern
      type="${BASH_REMATCH[1]}"
      date_str="${BASH_REMATCH[2]}"
    fi
    
    # Try to get title from JSON
    local title=""
    if command -v python3 &>/dev/null; then
      title=$(python3 -c "import json, sys; data=json.load(open('$file')); print(data.get('title', data.get('week', '')))" 2>/dev/null || echo "")
    fi
    
    if [[ -z "$title" ]]; then
      # Generate title from type
      if [[ "$type" == "weekly_review" ]]; then
        title="Weekly Review"
        # Try to get week from filename or content
        if command -v python3 &>/dev/null; then
          local week=$(python3 -c "import json, sys; data=json.load(open('$file')); print(data.get('week', ''))" 2>/dev/null || echo "")
          if [[ -n "$week" ]]; then
            title="Weekly Review - Week of $week"
          fi
        fi
      elif [[ "$type" == "insights" ]]; then
        title="Insights Generation"
      elif [[ "$type" == "connections" ]]; then
        title="Connection Analysis"
      else
        # Capitalize type for display
        title=$(echo "$type" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
      fi
    fi
    
    echo "  $count) $title"
    echo "     Type: $type | Date: $date_str"
    if [[ "$type" == "weekly_review" ]] && command -v python3 &>/dev/null; then
      local week=$(python3 -c "import json, sys; data=json.load(open('$file')); print(data.get('week', ''))" 2>/dev/null || echo "")
      if [[ -n "$week" ]]; then
        echo "     Week: $week"
      fi
    fi
    echo ""
    
    selected_files+=("$file")
    ((count++))
  done
  
  echo "0) Back to Review Menu"
  echo ""
  echo -n "Choose an analysis to view: "
  read choice
  
  if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
    return 0
  fi
  
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#selected_files[@]} ]]; then
    echo "Invalid choice"
    sleep 1
    return 1
  fi
  
  local selected_file="${selected_files[$((choice - 1))]}"
  
  # Extract analysis text from JSON
  local analysis_text=""
  if command -v python3 &>/dev/null; then
    analysis_text=$(python3 <<PYTHON_EXTRACT
import json
import sys

try:
    with open('$selected_file', 'r') as f:
        data = json.load(f)
    
    # Get analysis field (varies by type)
    analysis = data.get('analysis', '') or data.get('insights', '') or data.get('connections', '')
    
    if analysis:
        # Format with header
        title = data.get('title', 'Analysis Result')
        analysis_type = data.get('type', 'unknown')
        date = data.get('date', data.get('created_at', ''))
        
        print("=" * 70)
        print(f"{title}")
        print(f"Type: {analysis_type} | Date: {date}")
        print("=" * 70)
        print()
        print(analysis)
    else:
        print("No analysis content found in file.")
        sys.exit(1)
except Exception as e:
    print(f"Error reading file: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EXTRACT
)
  else
    echo "python3 not available for parsing JSON"
    sleep 1
    return 1
  fi
  
  if [[ -z "$analysis_text" ]]; then
    echo "Could not extract analysis content"
    sleep 1
    return 1
  fi
  
  # Display in vim or less
  echo "Opening analysis in vim..."
  echo "Tip: Press :q to exit when done reading"
  echo ""
  echo "Press Enter to continue..."
  read
  
  echo "$analysis_text" | vim -R - "+set filetype=markdown" - 2>/dev/null || echo "$analysis_text" | less -R
  
  # Ask if user wants to discuss with AI
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💬 Discuss This Review with AI?${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Would you like to discuss this analysis with AI? You can:"
  echo "  • Ask questions about the analysis"
  echo "  • Get clarification on points raised"
  echo "  • Dig deeper into specific sections"
  echo "  • Challenge or explore the insights"
  echo ""
  echo "y - Yes, discuss with AI"
  echo "n - No, return to list"
  echo ""
  echo -n "Choice: "
  read discuss_choice
  
  if [[ "$discuss_choice" == "y" ]] || [[ "$discuss_choice" == "Y" ]]; then
    discuss_analysis_with_ai "$selected_file" "$analysis_text"
  fi
  
  # Ask if user wants to generate suggestions
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💡 Generate Task Suggestions?${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Would you like to extract actionable task suggestions from this analysis?"
  echo "The system will scan the analysis and generate tasks, projects, zettels, or MOCs."
  echo ""
  echo "y - Yes, generate suggestions from this analysis"
  echo "n - No, return to analysis list"
  echo ""
  echo -n "Choice: "
  read suggest_choice
  
  if [[ "$suggest_choice" == "y" ]] || [[ "$suggest_choice" == "Y" ]]; then
    generate_suggestions_from_analysis "$selected_file"
  fi
}

# Discuss Analysis with AI
discuss_analysis_with_ai() {
  local analysis_file="$1"
  local analysis_text="$2"
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🤖 Choose AI Model for Discussion${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Which AI model would you like to use?"
  echo ""
  echo "1) Deep Thinking Model (for complex analysis, deeper insights)"
  echo "   Best for: Exploring complex patterns, strategic thinking, detailed analysis"
  echo ""
  echo "2) Regular Model with Persona (faster, personality-driven)"
  echo "   Best for: Quick clarifications, conversational exploration, practical advice"
  echo ""
  echo -e "${YELLOW}0)${NC} Cancel"
  echo ""
  echo -n "Choice: "
  read model_choice
  
  if [[ "$model_choice" == "0" ]] || [[ -z "$model_choice" ]]; then
    return 0
  fi
  
  local use_deep_model=false
  local persona="david"
  
  if [[ "$model_choice" == "1" ]]; then
    use_deep_model=true
  elif [[ "$model_choice" == "2" ]]; then
    echo ""
    echo "Which persona would you like to discuss with?"
    echo ""
    echo "1) David Allen (GTD expert) - Recommended for reviews"
    echo "2) Warren Buffett (Strategic thinking)"
    echo "3) Cal Newport (Deep work & focus)"
    echo "4) Choose from full persona list"
    echo ""
    echo -n "Choice (1-4): "
    read persona_choice
    
    case "$persona_choice" in
      1) persona="david" ;;
      2) persona="warren" ;;
      3) persona="cal" ;;
      4)
        persona=$(select_persona)
        persona=$(echo "$persona" | tr -d '\n\r' | xargs) # Trim whitespace/newlines
        if [[ -z "$persona" ]]; then
          echo "No persona selected. Returning to analysis list."
          read
          return 0
        fi
        ;;
      *)
        persona="david"
        ;;
    esac
  else
    return 0
  fi
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💬 Discussion Started${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Selected persona: $persona"
  echo ""
  echo "The AI has read your analysis. Ask questions, get clarification, or explore deeper."
  echo ""
  echo "Tip: Type 'done' or 'exit' when finished"
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Clean up analysis text - remove the header/metadata that was added for display
  local raw_analysis_text="$analysis_text"
  if echo "$raw_analysis_text" | grep -q "^========"; then
    raw_analysis_text=$(echo "$raw_analysis_text" | sed -n '/^======================================================================$/,$p' | sed '1,2d' | tail -n +1)
  fi
  
  # Conversation loop
  local conversation_context="Here is the analysis from a weekly review or deep analysis:\n\n$raw_analysis_text\n\nPlease help the user discuss this analysis. Answer questions, provide insights, and explore the content together."
  
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Your question or comment:"
    echo ""
    echo -e "${CYAN}💡 Tip: Add '[search]' to your question to enable web search${NC}"
    echo ""
    echo -n "❓ "
    read user_question
    
    if [[ "$user_question" == "done" ]] || [[ "$user_question" == "exit" ]] || [[ "$user_question" == "quit" ]]; then
      echo ""
      echo "✓ Finished discussion."
      break
    fi
    
    if [[ -z "$user_question" ]]; then
      continue
    fi
    
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}💭 AI Response${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check if web search is requested
    local enable_web_search=false
    local cleaned_question="$user_question"
    if echo "$user_question" | grep -qiE '\[search\]|web search|search the web|look up'; then
      enable_web_search=true
      cleaned_question=$(echo "$user_question" | sed 's/\[search\]//gi' | sed 's/web search//gi' | sed 's/search the web//gi' | sed 's/look up//gi' | xargs)
    fi
    
    # Build full prompt with all conversation history
    # Include: original analysis + all previous Q&A exchanges + current question
    # Format: context + new user question, ready for AI to respond
    local full_prompt=$(printf "%s\n\nUser: %s\n\nAssistant:" "$conversation_context" "$cleaned_question")
    
    # Create temp file for output
    local ai_output=$(mktemp)
    
    # Define command execution function for use with thinking timer
    execute_ai_command() {
      if [[ "$use_deep_model" == "true" ]]; then
        # Use deep model - find the helper script
      local DEEP_MODEL_HELPER=""
      for path in "$HOME/code/dotfiles/bin/gtd_deep_model_helper.py" "$HOME/code/personal/dotfiles/bin/gtd_deep_model_helper.py" "gtd_deep_model_helper.py"; do
        if [[ -f "$path" ]]; then
          DEEP_MODEL_HELPER="$path"
          break
        fi
      done
      
      if [[ -n "$DEEP_MODEL_HELPER" ]] && [[ -f "$DEEP_MODEL_HELPER" ]]; then
        # Deep model: pass full conversation context
        TIMEOUT="${TIMEOUT:-600}" MAX_TOKENS="${MAX_TOKENS:-4000}" python3 "$DEEP_MODEL_HELPER" "$full_prompt" >"$ai_output" 2>&1
        return $?
      else
        echo "⚠️  Deep model helper not found. Falling back to persona model."
        # For persona model with web search, we need to include context in the question
        if [[ "$enable_web_search" == "true" ]]; then
          echo ""
          echo "🔍 Web search enabled - searching for additional context..."
          # Use --simple --web-search to enable web search functionality
          # Note: We still pass full_prompt for context, but simple mode skips GTD-specific context
          TIMEOUT="${TIMEOUT:-240}" MAX_TOKENS="${MAX_TOKENS:-4000}" gtd-advise --simple --web-search "$persona" "$full_prompt" >"$ai_output" 2>&1
        else
          TIMEOUT="${TIMEOUT:-240}" MAX_TOKENS="${MAX_TOKENS:-4000}" gtd-advise "$persona" "$full_prompt" >"$ai_output" 2>&1
        fi
        return $?
      fi
    else
      # Use persona model
      if [[ "$enable_web_search" == "true" ]]; then
        echo ""
        echo "🔍 Web search enabled - searching for additional context..."
        # Use --simple --web-search to enable web search functionality
        # Note: We still pass full_prompt for context, but simple mode skips GTD-specific context
        TIMEOUT="${TIMEOUT:-240}" MAX_TOKENS="${MAX_TOKENS:-4000}" gtd-advise --simple --web-search "$persona" "$full_prompt" >"$ai_output" 2>&1
        return $?
      else
        TIMEOUT="${TIMEOUT:-240}" MAX_TOKENS="${MAX_TOKENS:-4000}" gtd-advise "$persona" "$full_prompt" >"$ai_output" 2>&1
        return $?
      fi
    fi
    
    }
    
    # Run with automatic thinking timer
    run_with_thinking_timer "Thinking" execute_ai_command
    local ai_exit_code=$?
    
    # Display the response and capture it for context
    local ai_response_text=$(cat "$ai_output")
    cat "$ai_output"
    rm -f "$ai_output"
    
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check if user wants to export this response
    echo ""
    echo -e "${BOLD}💾 Export Options:${NC}"
    echo "  1) Export as diagram"
    echo "  2) Export as zettelkasten note"
    echo "  3) Export as project"
    echo "  4) Export as area"
    echo "  5) Export as task"
    echo "  6) Skip export"
    echo ""
    echo -n "Export this response? (1-6, default 6): "
    read export_choice
    
    if [[ -z "$export_choice" ]]; then
      export_choice="6"
    fi
    
    case "$export_choice" in
      1)
        # Export as diagram
        echo ""
        echo "Exporting as diagram..."
        echo -n "Enter diagram name: "
        read diagram_name
        if [[ -n "$diagram_name" ]]; then
          # Extract pure text from AI response (remove markdown formatting if present)
          local clean_text="$ai_response_text"
          # Remove markdown code blocks if present
          if echo "$clean_text" | grep -q '```'; then
            clean_text=$(echo "$clean_text" | sed '/```/,/```/d' || echo "$clean_text")
          fi
          # Remove markdown headers, bold, etc.
          clean_text=$(echo "$clean_text" | sed 's/^#\+ //' | sed 's/\*\*//g' | sed 's/\*//g')
          
          # Define function to generate diagram for use with thinking timer
          generate_diagram() {
            local diagram_output=$(mktemp)
            (echo "$clean_text" | gtd-diagram mindmap "$diagram_name" --format dot 2>&1 || {
              echo "Error: Falling back to default format..."
              echo "$clean_text" | gtd-diagram mindmap "$diagram_name" 2>&1
            }) > "$diagram_output" 2>&1
            cat "$diagram_output"
            rm -f "$diagram_output"
          }
          
          # Run with automatic thinking timer
          local diagram_output=$(run_with_thinking_timer_capture "Generating diagram" generate_diagram)
          
          # Display diagram creation output
          echo "$diagram_output"
          
          # Automatically render the diagram and create review task
          local diagram_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/diagrams"
          # Use the same safe_name pattern as gtd-diagram uses
          local safe_name=$(echo "$diagram_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
          local dot_file="${diagram_dir}/${safe_name}.dot"
          
          # Wait a moment for file to be created, then check
          sleep 0.5
          if [[ -f "$dot_file" ]]; then
            # Ensure DOT file contains pure DOT code (not markdown)
            # Check if file starts with markdown indicators and clean it
            if head -1 "$dot_file" | grep -qE '^#|^```'; then
              # Extract only DOT code (lines starting with graph, digraph, or comments)
              local dot_content=$(grep -E '^(graph|digraph|//|node|edge|subgraph|})' "$dot_file" || cat "$dot_file")
              # Save pure DOT
              {
                echo "// ${diagram_name}"
                echo "// Created: $(date +"%Y-%m-%d %H:%M")"
                echo ""
                echo "$dot_content"
              } > "$dot_file"
            fi
            
            echo ""
            echo "🖼️  Rendering diagram..."
            if command -v dot &>/dev/null; then
              cd "$diagram_dir"
              if dot -Tpng "${safe_name}.dot" -o "${safe_name}.png" 2>/dev/null; then
                echo "✓ PNG rendered: ${safe_name}.png"
              fi
              if dot -Tsvg "${safe_name}.dot" -o "${safe_name}.svg" 2>/dev/null; then
                echo "✓ SVG rendered: ${safe_name}.svg"
              fi
              echo ""
              echo "💡 View rendered diagrams in: $diagram_dir"
            else
              echo "⚠️  Graphviz not installed. Install with: brew install graphviz"
              echo "   Diagram file saved: $dot_file"
            fi
            
            # Create task to review the diagram
            echo ""
            echo "📋 Creating review task for diagram..."
            local task_desc="Review diagram: ${diagram_name}"
            
            # Get timestamp before creating task to identify the new one
            local before_time=$(date +%s)
            
            # Create task non-interactively (using add command with flags)
            # Priority: not_urgent_important (default for review tasks)
            gtd-task add --non-interactive --context=computer --priority=not_urgent_important "$task_desc" >/dev/null 2>&1
            
            # Find the most recently created task file (created after before_time)
            local task_file=""
            for task in "${TASKS_PATH}"/*-task.md; do
              if [[ -f "$task" ]]; then
                local file_time=$(stat -f "%B" "$task" 2>/dev/null || stat -c "%Y" "$task" 2>/dev/null || echo "0")
                if [[ $file_time -ge $before_time ]]; then
                  task_file=$(basename "$task")
                  break
                fi
              fi
            done
            
            # Fallback: get most recent task if timestamp check didn't work
            if [[ -z "$task_file" ]]; then
              task_file=$(ls -t "${TASKS_PATH}"/*-task.md 2>/dev/null | head -1 | xargs basename 2>/dev/null)
            fi
            
            if [[ -n "$task_file" ]]; then
              local task_path="${TASKS_PATH}/${task_file}"
              if [[ -f "$task_path" ]]; then
                # Add diagram link to task notes
                local diagram_link="[[${diagram_name}|diagrams/${safe_name}.md]]"
                local diagram_path_link="Diagram: \`diagrams/${safe_name}.dot\`"
                
                # Append to task notes section
                if grep -q "## Notes" "$task_path"; then
                  # Add link under Notes section
                  if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "/## Notes/a\\
\\
${diagram_link}\\
${diagram_path_link}
" "$task_path"
                  else
                    sed -i "/## Notes/a\\\n${diagram_link}\n${diagram_path_link}" "$task_path"
                  fi
                else
                  # Add Notes section with link
                  if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "\$a\\
\\
## Notes\\
\\
${diagram_link}\\
${diagram_path_link}
" "$task_path"
                  else
                    echo "" >> "$task_path"
                    echo "## Notes" >> "$task_path"
                    echo "" >> "$task_path"
                    echo "$diagram_link" >> "$task_path"
                    echo "$diagram_path_link" >> "$task_path"
                  fi
                fi
                
                # Add link to diagram markdown file
                local md_file="${diagram_dir}/${safe_name}.md"
                if [[ -f "$md_file" ]]; then
                  # Add task link to diagram's Related section
                  local task_link="Task: [[${task_desc}|tasks/${task_file}]]"
                  if grep -q "## Related" "$md_file"; then
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "/## Related/a\\
${task_link}
" "$md_file"
                    else
                      sed -i "/## Related/a\\${task_link}" "$md_file"
                    fi
                  else
                    # Add Related section
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "\$a\\
\\
## Related\\
${task_link}
" "$md_file"
                    else
                      echo "" >> "$md_file"
                      echo "## Related" >> "$md_file"
                      echo "$task_link" >> "$md_file"
                    fi
                  fi
                fi
                
                echo "✓ Task created: $task_desc"
                echo "✓ Task linked to diagram"
              fi
            fi
          else
            echo ""
            echo "ℹ️  Diagram file not found. It may have been created with a different name."
            echo "   Check: $diagram_dir for recent .dot files"
          fi
        fi
        ;;
      2)
        # Export as zettelkasten note
        echo ""
        echo "Exporting as zettelkasten note..."
        echo -n "Enter note title: "
        read note_title
        if [[ -n "$note_title" ]]; then
          echo "$ai_response_text" > "${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten/${note_title}.md" 2>/dev/null || {
            mkdir -p "${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten"
            echo "$ai_response_text" > "${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten/${note_title}.md"
          }
          echo "✓ Note created at: zettelkasten/${note_title}.md"
        fi
        ;;
      3)
        # Export as project
        echo ""
        echo "Exporting as project..."
        echo -n "Enter project name: "
        read project_name
        if [[ -n "$project_name" ]]; then
          echo -n "Enter area (optional): "
          read project_area
          if [[ -n "$project_area" ]]; then
            gtd-project create "$project_name" --area="$project_area" --description="$ai_response_text" 2>&1 || echo "Error creating project"
          else
            gtd-project create "$project_name" --description="$ai_response_text" 2>&1 || echo "Error creating project"
          fi
        fi
        ;;
      4)
        # Export as area
        echo ""
        echo "Exporting as area..."
        echo -n "Enter area name: "
        read area_name
        if [[ -n "$area_name" ]]; then
          gtd-area create "$area_name" --description="$ai_response_text" 2>&1 || echo "Error creating area"
        fi
        ;;
      5)
        # Export as task
        echo ""
        echo "Exporting as task..."
        echo -n "Enter task description: "
        read task_desc
        if [[ -n "$task_desc" ]]; then
          echo -n "Enter context (default: computer): "
          read task_context
          if [[ -z "$task_context" ]]; then
            task_context="computer"
          fi
          echo -n "Enter priority (1-4, default 2): "
          read task_priority
          if [[ -z "$task_priority" ]]; then
            task_priority="2"
          fi
          
          # Convert priority number to priority value
          case "$task_priority" in
            1) priority_value="urgent_important" ;;
            2) priority_value="not_urgent_important" ;;
            3) priority_value="urgent_not_important" ;;
            4) priority_value="not_urgent_not_important" ;;
            *) priority_value="not_urgent_important" ;;
          esac
          
          # Create task with description from AI response in notes
          gtd-task add --non-interactive --context="$task_context" --priority="$priority_value" "$task_desc" >/dev/null 2>&1
          
          # Find the task file and add AI response as notes
          local task_file=$(ls -t "${TASKS_PATH}"/*-task.md 2>/dev/null | head -1 | xargs basename 2>/dev/null)
          if [[ -n "$task_file" ]] && [[ -f "${TASKS_PATH}/${task_file}" ]]; then
            local task_path="${TASKS_PATH}/${task_file}"
            # Add AI response to task notes
            if grep -q "## Notes" "$task_path"; then
              if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "/## Notes/a\\
\\
${ai_response_text}
" "$task_path"
              else
                sed -i "/## Notes/a\\\n${ai_response_text}" "$task_path"
              fi
            else
              if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "\$a\\
\\
## Notes\\
\\
${ai_response_text}
" "$task_path"
              else
                echo "" >> "$task_path"
                echo "## Notes" >> "$task_path"
                echo "" >> "$task_path"
                echo "$ai_response_text" >> "$task_path"
              fi
            fi
            echo "✓ Task created: $task_desc"
            echo "✓ AI response added to task notes"
          fi
        fi
        ;;
    esac
    
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Update context with this exchange - include the actual AI response
    # Build conversation history: original analysis + all Q&A pairs
    # Append this exchange to maintain full conversation history
    conversation_context=$(printf "%s\n\nUser: %s\n\nAssistant: %s" "$conversation_context" "$cleaned_question" "$ai_response_text")
    
    # Limit context size to avoid token limits (keep last ~12000 chars for better memory)
    # We'll truncate old exchanges but keep the analysis and recent conversation
    local context_length=${#conversation_context}
    if [[ $context_length -gt 12000 ]]; then
      # Extract the analysis intro (first part with the analysis text)
      local analysis_part=$(echo -e "$conversation_context" | head -c 2000)
      # Get the most recent conversation (last ~10000 chars)
      local recent_part=$(echo -e "$conversation_context" | tail -c 10000)
      conversation_context=$(printf "%s\n\n[... earlier conversation truncated to save tokens ...]\n\n%s" "$analysis_part" "$recent_part")
    fi
  done
  
  echo ""
  echo "Press Enter to continue..."
  read
}

# Generate Suggestions from Analysis
generate_suggestions_from_analysis() {
  local analysis_file="$1"
  
  if [[ -z "$analysis_file" ]] || [[ ! -f "$analysis_file" ]]; then
    echo "Error: Invalid analysis file"
    return 1
  fi
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💡 Generating Task Suggestions from Analysis${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Scanning analysis for actionable suggestions..."
  echo ""
  
  # Find MCP Python and server - use the same venv as the wizard
  local mcp_dir="$HOME/code/dotfiles/mcp"
  if [[ ! -d "$mcp_dir" ]]; then
    mcp_dir="$HOME/code/personal/dotfiles/mcp"
  fi
  local MCP_VENV="${MCP_VENV:-${mcp_dir}/venv}"
  local MCP_PYTHON="python3"
  if [[ -f "$MCP_VENV/bin/python3" ]]; then
    MCP_PYTHON="$MCP_VENV/bin/python3"
  elif [[ -f "$MCP_VENV/bin/python" ]]; then
    MCP_PYTHON="$MCP_VENV/bin/python"
  fi
  
  local MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
  if [[ ! -f "$MCP_SERVER" ]]; then
    MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
  fi
  
  # Read analysis file to get type and content
  local analysis_type="unknown"
  local analysis_content=""
  
  if command -v python3 &>/dev/null; then
    local analysis_data=$(python3 <<PYTHON_READ
import json
import sys

try:
    with open('$analysis_file', 'r') as f:
        data = json.load(f)
    
    analysis_type = data.get('type', 'unknown')
    analysis_content = data.get('analysis', '') or data.get('insights', '') or data.get('connections', '')
    
    print(json.dumps({
        'type': analysis_type,
        'content': analysis_content
    }))
except Exception as e:
    print(json.dumps({'error': str(e)}), file=sys.stderr)
    sys.exit(1)
PYTHON_READ
)
    
    if echo "$analysis_data" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
      analysis_type=$(echo "$analysis_data" | python3 -c "import sys, json; print(json.load(sys.stdin)['type'])" 2>/dev/null)
      analysis_content=$(echo "$analysis_data" | python3 -c "import sys, json; print(json.load(sys.stdin)['content'])" 2>/dev/null)
    fi
  fi
  
  if [[ -z "$analysis_content" ]]; then
    echo "❌ Could not read analysis content from file"
    echo ""
    echo "Press Enter to continue..."
    read
    return 1
  fi
  
  # Call MCP server to extract suggestions
  local script_output=$(mktemp)
  local error_output=$(mktemp)
  local result=""
  
    # Ensure we're using the MCP virtualenv if available - use the same venv as the wizard
    local mcp_dir="$HOME/code/dotfiles/mcp"
    if [[ ! -d "$mcp_dir" ]]; then
      mcp_dir="$HOME/code/personal/dotfiles/mcp"
    fi
    local MCP_VENV="${MCP_VENV:-${mcp_dir}/venv}"
    if [[ -f "$MCP_VENV/bin/python3" ]]; then
      MCP_PYTHON="$MCP_VENV/bin/python3"
    elif [[ -f "$MCP_VENV/bin/python" ]]; then
      MCP_PYTHON="$MCP_VENV/bin/python"
    fi
  
  # Define function to execute Python script for use with thinking timer
  execute_suggestions_script() {
    "$MCP_PYTHON" <<PYTHON_SCRIPT 2>>"$error_output"
import sys
import json
import os
from pathlib import Path

# Add MCP directory to path
mcp_dir = Path('$HOME/code/dotfiles/mcp').expanduser()
if not mcp_dir.exists():
    mcp_dir = Path('$HOME/code/personal/dotfiles/mcp').expanduser()

if mcp_dir.exists():
    sys.path.insert(0, str(mcp_dir))

try:
    from gtd_mcp_server import extract_suggestions_from_analysis
    
    analysis_type = '$analysis_type'
    analysis_content = '''$analysis_content'''
    source_file = Path('$analysis_file')
    
    suggestions = extract_suggestions_from_analysis(analysis_type, analysis_content, source_file)
    
    # Save suggestions to suggestions directory
    suggestions_dir = Path(os.path.expanduser('${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions'))
    suggestions_dir.mkdir(parents=True, exist_ok=True)
    
    import uuid
    from datetime import datetime
    
    created_suggestions = []
    for sug in suggestions:
        sug_id = str(uuid.uuid4())
        sug_file = suggestions_dir / f"{sug_id}.json"
        
        sug_data = {
            'id': sug_id,
            'type': sug.get('item_type', 'task'),
            'title': sug.get('title', ''),
            'reason': sug.get('reason', ''),
            'suggested_project': sug.get('suggested_project', ''),
            'suggested_area': sug.get('suggested_area', ''),
            'suggested_moc': sug.get('suggested_moc', ''),
            'confidence': sug.get('confidence', 0.7),
            'status': 'pending',
            'source': sug.get('source', 'analysis'),
            'source_file': sug.get('source_file', ''),
            'created_at': datetime.now().isoformat()
        }
        
        with open(sug_file, 'w') as f:
            json.dump(sug_data, f, indent=2)
        
        created_suggestions.append({
            'id': sug_id,
            'type': sug_data['type'],
            'title': sug_data['title'],
            'reason': sug_data['reason']
        })
    
    output = {
        'success': True,
        'message': f'Generated {len(created_suggestions)} suggestion(s) from analysis',
        'suggestions_created': len(created_suggestions),
        'suggestions': created_suggestions
    }
    
    print(json.dumps(output))
    sys.stdout.flush()
    
except ImportError as e:
    import traceback
    error_data = {
        'success': False,
        'message': f'Failed to import MCP server: {e}',
        'suggestions_created': 0,
        'debug_info': {
            'python_path': sys.path,
            'mcp_dir': str(mcp_dir),
            'error': str(e),
            'traceback': traceback.format_exc(),
            'hint': 'Make sure MCP package is installed: pip install mcp (in the MCP virtualenv)'
        }
    }
    print(json.dumps(error_data, indent=2))
    sys.stdout.flush()
    sys.exit(1)
except Exception as e:
    import traceback
    error_data = {
        'success': False,
        'message': f'Error generating suggestions: {e}',
        'suggestions_created': 0,
        'debug_info': {
            'error': str(e),
            'traceback': traceback.format_exc()
        }
    }
    print(json.dumps(error_data, indent=2))
    sys.stdout.flush()
    sys.exit(1)
PYTHON_SCRIPT
  }
  
  # Run with automatic thinking timer and capture output
  result=$(run_with_thinking_timer_capture "Generating suggestions" execute_suggestions_script)
  local python_exit_code=$?
  
  # Check for errors
  if [[ $python_exit_code -ne 0 ]] || [[ -z "$result" ]]; then
    # Try to read error output
    local error_msg=""
    if [[ -f "$error_output" ]] && [[ -s "$error_output" ]]; then
      # Escape the error message for JSON
      error_msg=$(cat "$error_output" 2>/dev/null | head -50 | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    else
      error_msg="(No error output captured - check MCP virtualenv and package installation)"
    fi
    
    # Also check if result contains any JSON (partial success)
    local result_preview=""
    if [[ -n "$result" ]]; then
      result_preview=$(echo "$result" | head -c 200 | sed 's/"/\\"/g')
    fi
    
    result=$(cat <<JSON
{
  "success": false,
  "message": "Python script failed with exit code $python_exit_code",
  "suggestions_created": 0,
  "debug_info": {
    "exit_code": $python_exit_code,
    "python_error": "$error_msg",
    "result_preview": "$result_preview",
    "script_path": "$MCP_SERVER",
    "mcp_python": "$MCP_PYTHON",
    "mcp_venv": "$MCP_VENV",
    "venv_exists": "$([[ -f "$MCP_VENV/bin/python" ]] && echo 'yes' || echo 'no')"
  }
}
JSON
)
  fi
  
  # Ensure we always output JSON, even on fatal errors
  # Run script and capture both stdout and stderr separately
  # Use a wrapper to ensure we ALWAYS get JSON output
  "$MCP_PYTHON" <<PYTHON_SCRIPT >"$script_output" 2>"$error_output"
import sys
import traceback
import json
import os

# Immediately output something to verify script is running
try:
    # Try to parse the result we already have
    if len('$result'.strip()) > 0:
        data = json.loads('$result')
    else:
        data = {'success': False, 'message': 'No output from script', 'suggestions_created': 0}
    
    print(json.dumps(data))
    sys.stdout.flush()
except Exception as fatal_error:
    # Last resort error output
    error_data = {
        'success': False,
        'message': f'Fatal error: {str(fatal_error)}',
        'traceback': traceback.format_exc(),
        'suggestions_created': 0,
        'debug_info': {
            'raw_result_length': len('$result'),
            'raw_result_preview': '$result'[:200] if len('$result') > 0 else '(empty)'
        }
    }
    print(json.dumps(error_data))
    sys.stdout.flush()
PYTHON_SCRIPT

  # Read the final result
  if [[ -f "$script_output" ]] && [[ -s "$script_output" ]]; then
    result=$(cat "$script_output")
  fi
  
  # Clean up temp files
  rm -f "$script_output" "$error_output"
  
  # Create a temporary Python script file for the parser to avoid quote escaping issues
  local parser_script=$(mktemp)
  cat > "$parser_script" <<'PYTHON_PARSER_SCRIPT'
import sys
import json

# Read all input at once (can't seek on pipes)
stdin_data = sys.stdin.read()
if not stdin_data or not stdin_data.strip():
    print('❌ No data received from script')
    sys.exit(1)

try:
    data = json.loads(stdin_data)
    
    if data.get('success'):
        print('✅', data.get('message', 'Suggestions generated'))
        print('')
        
        if data.get('suggestions_created', 0) > 0:
            suggestions = data.get('suggestions', [])
            print(f'📋 Created {len(suggestions)} suggestion(s):')
            print('')
            
            for i, sug in enumerate(suggestions, 1):
                sug_type = sug.get('type', 'task').upper()
                title = sug.get('title', 'Unknown')
                reason = sug.get('reason', '')
                
                print(f'  {i}. [{sug_type}] {title}')
                if reason:
                    # Wrap long reasons
                    if len(reason) > 100:
                        print(f'     Reason: {reason[:97]}...')
                    else:
                        print(f'     Reason: {reason}')
                print('')
            
            print('💡 Review and approve these suggestions with:')
            print('   gtd-wizard → AI Suggestions → Review pending suggestions')
        else:
            print('ℹ️  No actionable suggestions were found in this analysis.')
            # Show debug info if available
            if 'debug_info' in data and data['debug_info']:
                debug = data['debug_info']
                print('')
                print('Debug information:')
                print(f"  Analysis type: {debug.get('analysis_type', 'unknown')}")
                print(f"  Content length: {debug.get('content_length', 0)} characters")
                if debug.get('content_preview'):
                    print(f"  Content preview: {debug['content_preview'][:100]}...")
    else:
        print('❌', data.get('message', 'Failed to generate suggestions'))
        # Show debug info if available
        if 'debug_info' in data and data['debug_info']:
            debug = data['debug_info']
            print('')
            print('Debug information:')
            if isinstance(debug, dict):
                for key, value in debug.items():
                    if key == 'traceback' and len(str(value)) > 500:
                        print(f"  {key}:")
                        value_lines = str(value).split('\n')
                        for line in value_lines[:10]:
                            print(f"    {line}")
                        if len(value_lines) > 10:
                            remaining = len(value_lines) - 10
                            print(f"    ... ({remaining} more lines)")
                    else:
                        print(f"  {key}: {value}")
            else:
                print('  ', debug)
        
        # Show troubleshooting tips
        print('')
        print('Troubleshooting:')
        print('  1. Verify MCP server exists and is importable')
        print('  2. Check Python can import gtd_mcp_server')
        print('  3. Try running: python3 -c "from gtd_mcp_server import extract_suggestions_from_analysis"')
        print('  4. Make sure MCP package is installed: pip install mcp (in the MCP virtualenv)')
        print('  5. Check GTD_DEBUG=1 environment variable for more details')
        if 'hint' in debug:
            print(f'  6. {debug["hint"]}')
        
except json.JSONDecodeError as e:
    print('❌ Error parsing results as JSON:', str(e))
    print('')
    print('This means the Python script output was not valid JSON.')
    print('Raw output (first 500 chars):')
    try:
        print(stdin_data[:500])
        if len(stdin_data) > 500:
            remaining = len(stdin_data) - 500
            print(f'... (truncated, total {len(stdin_data)} chars)')
    except:
        print('(Could not read raw output)')
except Exception as e:
    print('❌ Error parsing results:', str(e))
    print('')
    print('This means the Python script output was not valid JSON.')
    print('Raw output (first 500 chars):')
    try:
        if 'stdin_data' in locals():
            print(stdin_data[:500])
            if len(stdin_data) > 500:
                remaining = len(stdin_data) - 500
                print(f'... (truncated, total {len(stdin_data)} chars)')
        else:
            print('(No data was read from stdin)')
    except Exception as read_error:
        print(f'(Could not display raw output: {read_error})')
PYTHON_PARSER_SCRIPT
  
  # Parse and display results using the script file
  local suggestions_were_created=false
  if [[ -n "$result" ]] && echo "$result" | "$MCP_PYTHON" -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "$result" | "$MCP_PYTHON" "$parser_script"
    # Check if suggestions were created
    if echo "$result" | "$MCP_PYTHON" -c "import sys, json; data=json.load(sys.stdin); sys.exit(0 if data.get('success') and data.get('suggestions_created', 0) > 0 else 1)" 2>/dev/null; then
      suggestions_were_created=true
    fi
    rm -f "$parser_script"
  else
    echo ""
    echo "⚠️  Could not parse results. Raw output:"
    echo "$result"
    rm -f "$parser_script"
  fi
  
  # Offer export options if suggestions were created
  if [[ "$suggestions_were_created" == "true" ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💾 Export Generated Suggestions?${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✓ Suggestions already saved to pending suggestions${NC}"
    echo "   (JSON files in: ${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions/)"
    echo ""
    echo "Would you like to automatically create items based on suggestion types?"
    echo ""
    echo "  1) Auto-export: Create tasks/zettels/MOCs/projects based on type"
    echo "  2) Export suggestions summary as diagram"
    echo "  3) Export suggestions summary as zettelkasten note"
    echo "  4) Skip export (suggestions remain in pending)"
    echo ""
    echo -n "Choose (1-4, default 4): "
    read export_suggestions_choice
    
    if [[ -z "$export_suggestions_choice" ]]; then
      export_suggestions_choice="4"
    fi
    
    if [[ "$export_suggestions_choice" == "1" ]]; then
      # Auto-export based on suggestion type
      echo ""
      echo "🔄 Auto-exporting suggestions based on their types..."
      echo ""
      local created_count=0
      local total_count=$(echo "$result" | "$MCP_PYTHON" -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('suggestions', [])))" 2>/dev/null || echo "0")
      
      # Process each suggestion
      echo "$result" | "$MCP_PYTHON" <<'PYEOF'
import sys
import json
from pathlib import Path
from datetime import datetime

data = json.load(sys.stdin)
if data.get('success') and data.get('suggestions'):
    gtd_base = Path('${GTD_BASE_DIR:-$HOME/Documents/gtd}').expanduser()
    suggestions_dir = gtd_base / 'suggestions'
    
    for sug in data['suggestions']:
        sug_type = sug.get('type', 'task').lower()
        title = sug.get('title', '')
        sug_id = sug.get('id', '')
        
        if not title:
            continue
        
        # Output format: type|id|title|suggested_area|suggested_moc
        suggested_area = sug.get('suggested_area', '')
        suggested_moc = sug.get('suggested_moc', '')
        
        print(f'{sug_type}|{sug_id}|{title}|{suggested_area}|{suggested_moc}')
PYEOF
        
        while IFS='|' read -r sug_type sug_id title suggested_area suggested_moc; do
          [[ -z "$title" ]] && continue
          
          # Create based on type
          case "$sug_type" in
            task)
              if command -v gtd-task &>/dev/null; then
                if gtd-task add --non-interactive --context=computer --priority=not_urgent_important "$title" >/dev/null 2>&1; then
                  echo "✓ Created task: $title"
                  ((created_count++))
                  
                  # Mark suggestion as accepted
                  local sug_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions/${sug_id}.json"
                  if [[ -f "$sug_file" ]]; then
                    "$MCP_PYTHON" -c "
import json
from datetime import datetime
with open('$sug_file', 'r') as f:
    data = json.load(f)
data['status'] = 'accepted'
data['exported_at'] = datetime.now().isoformat()
with open('$sug_file', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                  fi
                fi
              fi
              ;;
            zettel)
              if command -v zet &>/dev/null; then
                if zet -z "$title" >/dev/null 2>&1; then
                  echo "✓ Created zettel: $title"
                  ((created_count++))
                  
                  local sug_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions/${sug_id}.json"
                  if [[ -f "$sug_file" ]]; then
                    "$MCP_PYTHON" -c "
import json
from datetime import datetime
with open('$sug_file', 'r') as f:
    data = json.load(f)
data['status'] = 'accepted'
data['exported_at'] = datetime.now().isoformat()
with open('$sug_file', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                  fi
                fi
              else
                # Fallback: create in zettelkasten directory
                local zet_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten"
                mkdir -p "$zet_dir"
                local safe_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
                echo "# $title" > "${zet_dir}/${safe_title}.md"
                echo "" >> "${zet_dir}/${safe_title}.md"
                echo "✓ Created zettel: $title"
                ((created_count++))
              fi
              ;;
            moc)
              local moc_title="${suggested_moc:-$title}"
              if command -v gtd-brain-moc &>/dev/null; then
                if gtd-brain-moc create "$moc_title" >/dev/null 2>&1; then
                  echo "✓ Created MOC: $moc_title"
                  ((created_count++))
                  
                  local sug_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions/${sug_id}.json"
                  if [[ -f "$sug_file" ]]; then
                    "$MCP_PYTHON" -c "
import json
from datetime import datetime
with open('$sug_file', 'r') as f:
    data = json.load(f)
data['status'] = 'accepted'
data['exported_at'] = datetime.now().isoformat()
with open('$sug_file', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                  fi
                fi
              else
                # Fallback: create in Second Brain MOCs
                local moc_dir="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}/MOCs"
                mkdir -p "$moc_dir"
                echo "# MOC - $moc_title" > "${moc_dir}/MOC - ${moc_title}.md"
                echo "" >> "${moc_dir}/MOC - ${moc_title}.md"
                echo "✓ Created MOC: $moc_title"
                ((created_count++))
              fi
              ;;
            project)
              if command -v gtd-project &>/dev/null; then
                local cmd_args=("gtd-project" "create" "$title")
                [[ -n "$suggested_area" ]] && cmd_args+=("--area" "$suggested_area")
                if "${cmd_args[@]}" >/dev/null 2>&1; then
                  echo "✓ Created project: $title$([[ -n "$suggested_area" ]] && echo " (area: $suggested_area)")"
                  ((created_count++))
                  
                  local sug_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions/${sug_id}.json"
                  if [[ -f "$sug_file" ]]; then
                    "$MCP_PYTHON" -c "
import json
from datetime import datetime
with open('$sug_file', 'r') as f:
    data = json.load(f)
data['status'] = 'accepted'
data['exported_at'] = datetime.now().isoformat()
with open('$sug_file', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                  fi
                fi
              fi
              ;;
          esac
        done < <(echo "$result" | "$MCP_PYTHON" <<'PYEOF'
import sys
import json
data = json.load(sys.stdin)
if data.get('success') and data.get('suggestions'):
    for sug in data['suggestions']:
        sug_type = sug.get('type', 'task').lower()
        sug_id = sug.get('id', '')
        title = sug.get('title', '')
        suggested_area = sug.get('suggested_area', '')
        suggested_moc = sug.get('suggested_moc', '')
        print(f'{sug_type}|{sug_id}|{title}|{suggested_area}|{suggested_moc}')
PYEOF
        )
        
        echo ""
        echo "✓ Auto-exported $created_count/$total_count suggestion(s)"
      
      echo ""
      echo "💡 Remaining suggestions are still available in pending suggestions"
      echo "   Review with: gtd-wizard → AI Suggestions → Review pending suggestions"
      
    elif [[ "$export_suggestions_choice" == "2" ]]; then
      # Export as diagram
      # Extract suggestions summary
      local suggestions_summary=$(echo "$result" | "$MCP_PYTHON" -c "
import sys, json
data = json.load(sys.stdin)
if data.get('success') and data.get('suggestions'):
    print('Generated Suggestions Summary:\\n')
    for i, sug in enumerate(data['suggestions'], 1):
        sug_type = sug.get('type', 'task').upper()
        title = sug.get('title', 'Unknown')
        reason = sug.get('reason', '')
        print(f'{i}. [{sug_type}] {title}')
        if reason:
            print(f'   Reason: {reason}')
        print()
" 2>/dev/null || echo "")
      
      if [[ -n "$suggestions_summary" ]]; then
        # Export as diagram
        echo ""
        echo "Creating diagram from suggestions..."
        echo -n "Enter diagram name (default: 'Generated Suggestions'): "
        read diagram_name
        if [[ -z "$diagram_name" ]]; then
          diagram_name="Generated Suggestions"
        fi
        if [[ -n "$suggestions_summary" ]]; then
            # Extract pure text from suggestions summary
            local clean_text="$suggestions_summary"
            # Remove markdown code blocks if present
            if echo "$clean_text" | grep -q '```'; then
              clean_text=$(echo "$clean_text" | sed '/```/,/```/d' || echo "$clean_text")
            fi
            
            # Define function to generate diagram for use with thinking timer
            generate_diagram() {
              local diagram_output=$(mktemp)
              (echo "$clean_text" | gtd-diagram mindmap "$diagram_name" --format dot 2>&1 || {
                echo "Error: Falling back to default format..."
                echo "$clean_text" | gtd-diagram mindmap "$diagram_name" 2>&1
              }) > "$diagram_output" 2>&1
              cat "$diagram_output"
              rm -f "$diagram_output"
            }
            
            # Run with automatic thinking timer
            local diagram_output=$(run_with_thinking_timer_capture "Generating diagram" generate_diagram)
            
            # Display diagram creation output
            echo "$diagram_output"
            
            # Automatically render the diagram and create review task
            local diagram_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/diagrams"
            local safe_name=$(echo "$diagram_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
            local dot_file="${diagram_dir}/${safe_name}.dot"
            
            sleep 0.5
            if [[ -f "$dot_file" ]]; then
              # Ensure DOT file contains pure DOT code (not markdown)
              if head -1 "$dot_file" | grep -qE '^#|^```'; then
                local dot_content=$(grep -E '^(graph|digraph|//|node|edge|subgraph|})' "$dot_file" || cat "$dot_file")
                {
                  echo "// ${diagram_name}"
                  echo "// Created: $(date +"%Y-%m-%d %H:%M")"
                  echo ""
                  echo "$dot_content"
                } > "$dot_file"
              fi
              
              echo ""
              echo "🖼️  Rendering diagram..."
              if command -v dot &>/dev/null; then
                cd "$diagram_dir"
                if dot -Tpng "${safe_name}.dot" -o "${safe_name}.png" 2>/dev/null; then
                  echo "✓ PNG rendered: ${safe_name}.png"
                fi
                if dot -Tsvg "${safe_name}.dot" -o "${safe_name}.svg" 2>/dev/null; then
                  echo "✓ SVG rendered: ${safe_name}.svg"
                fi
                echo ""
                echo "💡 View rendered diagrams in: $diagram_dir"
              else
                echo "⚠️  Graphviz not installed. Install with: brew install graphviz"
                echo "   Diagram file saved: $dot_file"
              fi
              
              # Create task to review the diagram
              echo ""
              echo "📋 Creating review task for diagram..."
              local task_desc="Review diagram: ${diagram_name}"
              local before_time=$(date +%s)
              gtd-task add --non-interactive --context=computer --priority=not_urgent_important "$task_desc" >/dev/null 2>&1
              
              local task_file=""
              for task in "${TASKS_PATH}"/*-task.md; do
                if [[ -f "$task" ]]; then
                  local file_time=$(stat -f "%B" "$task" 2>/dev/null || stat -c "%Y" "$task" 2>/dev/null || echo "0")
                  if [[ $file_time -ge $before_time ]]; then
                    task_file=$(basename "$task")
                    break
                  fi
                fi
              done
              
              if [[ -z "$task_file" ]]; then
                task_file=$(ls -t "${TASKS_PATH}"/*-task.md 2>/dev/null | head -1 | xargs basename 2>/dev/null)
              fi
              
              if [[ -n "$task_file" ]]; then
                local task_path="${TASKS_PATH}/${task_file}"
                if [[ -f "$task_path" ]]; then
                  local diagram_link="[[${diagram_name}|diagrams/${safe_name}.md]]"
                  local diagram_path_link="Diagram: \`diagrams/${safe_name}.dot\`"
                  
                  if grep -q "## Notes" "$task_path"; then
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "/## Notes/a\\
\\
${diagram_link}\\
${diagram_path_link}
" "$task_path"
                    else
                      sed -i "/## Notes/a\\\n${diagram_link}\n${diagram_path_link}" "$task_path"
                    fi
                  else
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                      sed -i '' "\$a\\
\\
## Notes\\
\\
${diagram_link}\\
${diagram_path_link}
" "$task_path"
                    else
                      echo "" >> "$task_path"
                      echo "## Notes" >> "$task_path"
                      echo "" >> "$task_path"
                      echo "$diagram_link" >> "$task_path"
                      echo "$diagram_path_link" >> "$task_path"
                    fi
                  fi
                  
                  local md_file="${diagram_dir}/${safe_name}.md"
                  if [[ -f "$md_file" ]]; then
                    local task_link="Task: [[${task_desc}|tasks/${task_file}]]"
                    if grep -q "## Related" "$md_file"; then
                      if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' "/## Related/a\\
${task_link}
" "$md_file"
                      else
                        sed -i "/## Related/a\\${task_link}" "$md_file"
                      fi
                    else
                      if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' "\$a\\
\\
## Related\\
${task_link}
" "$md_file"
                      else
                        echo "" >> "$md_file"
                        echo "## Related" >> "$md_file"
                        echo "$task_link" >> "$md_file"
                      fi
                    fi
                  fi
                  
                  echo "✓ Task created: $task_desc"
                  echo "✓ Task linked to diagram"
                fi
              fi
            else
              echo ""
              echo "ℹ️  Diagram file not found. It may have been created with a different name."
              echo "   Check: $diagram_dir for recent .dot files"
            fi
          fi
      fi
    elif [[ "$export_suggestions_choice" == "3" ]]; then
      # Export as zettelkasten note
      local suggestions_summary=$(echo "$result" | "$MCP_PYTHON" -c "
import sys, json
data = json.load(sys.stdin)
if data.get('success') and data.get('suggestions'):
    print('Generated Suggestions Summary:\\n')
    for i, sug in enumerate(data['suggestions'], 1):
        sug_type = sug.get('type', 'task').upper()
        title = sug.get('title', 'Unknown')
        reason = sug.get('reason', '')
        print(f'{i}. [{sug_type}] {title}')
        if reason:
            print(f'   Reason: {reason}')
        print()
" 2>/dev/null || echo "")
      
      echo ""
      echo "Creating zettelkasten note from suggestions..."
      echo -n "Enter note title (default: 'Generated Suggestions'): "
      read note_title
      if [[ -z "$note_title" ]]; then
        note_title="Generated Suggestions"
      fi
      if [[ -n "$suggestions_summary" ]]; then
        mkdir -p "${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten"
        echo "$suggestions_summary" > "${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten/${note_title}.md" 2>/dev/null || {
          echo "$suggestions_summary" > "${GTD_BASE_DIR:-$HOME/Documents/gtd}/zettelkasten/${note_title}.md"
        }
        echo "✓ Note created at: zettelkasten/${note_title}.md"
      fi
    fi
  fi
  
  echo ""
  echo "Press Enter to continue..."
  read
}

# Express Phase Wizard
express_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}✍️  Express Phase (Create from Notes)${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_express_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) Create article from notes"
  echo "  2) Create presentation from notes"
  echo "  3) Create project plan from notes"
  echo "  4) Browse notes for inspiration"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read express_choice
  
  case "$express_choice" in
    1|2|3|4)
      echo ""
      echo "Express Phase functionality coming soon!"
      echo "This feature helps you create content from your Second Brain notes."
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

# Template Wizard
template_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📋 Templates${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_templates_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) List available templates"
  echo "  2) Create task from template"
  echo "  3) Create project from template"
  echo "  4) Create note from template"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read template_choice
  
  case "$template_choice" in
    1|2|3|4)
      echo ""
      echo "Template functionality coming soon!"
      echo "Use templates to quickly create structured items."
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

# Diagram Wizard
diagram_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎨 Create Diagrams & Mindmaps${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_diagram_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) Create diagram from notes"
  echo "  2) Create mindmap"
  echo "  3) View existing diagrams"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read diagram_choice
  
  case "$diagram_choice" in
    1|2|3)
      if command -v gtd-diagram &>/dev/null; then
        gtd-diagram
      else
        echo ""
        echo "Diagram tool not found. Install gtd-diagram for diagram generation."
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

# Morning Routine Wizard
morning_routine_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🌅 Morning Routine${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Morning routine functionality - guide yourself through morning tasks."
  echo ""
  echo "Use option 19 (Morning/Evening Check-In) for full check-in functionality."
  echo ""
  echo "Press Enter to continue..."
  read
}

# Afternoon Routine Wizard
afternoon_routine_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}☀️  Afternoon Routine${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Afternoon routine functionality - guide yourself through afternoon tasks."
  echo ""
  echo "Use option 19 (Morning/Evening Check-In) for check-in functionality."
  echo ""
  echo "Press Enter to continue..."
  read
}

# Evening Routine Wizard
evening_routine_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🌙 Evening Routine${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Evening routine functionality - guide yourself through evening tasks."
  echo ""
  echo "Use option 19 (Morning/Evening Check-In) for full check-in functionality."
  echo ""
  echo "Press Enter to continue..."
  read
}

# Evening Summary Wizard
evening_summary_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Evening Summary${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Evening summary functionality - review your day and plan tomorrow."
  echo ""
  echo "Use option 19 (Morning/Evening Check-In) for full check-in functionality."
  echo ""
  echo "Press Enter to continue..."
  read
}
