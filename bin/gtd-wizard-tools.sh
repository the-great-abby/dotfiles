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
  local thread_id="${6:-}"
  local skip_prompt="${7:-false}"
  
  # Store conversation
  local conversation_questions=("$initial_question")
  local conversation_answers=("$initial_answer")
  
  # Create thread for this conversation if not provided
  if [[ -z "$thread_id" ]]; then
    thread_id=$(create_conversation_thread "" "$initial_question" "$initial_answer" "$persona")
  else
    # Update existing thread with initial answer if needed
    create_conversation_thread "$thread_id" "$initial_question" "$initial_answer" "$persona" >/dev/null
  fi
  
  # Ask if they want to continue the conversation (unless skip_prompt is true)
  if [[ "$skip_prompt" != "true" ]]; then
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Do you have any follow-up questions?${NC}"
    echo -e "${GREEN}y${NC} - Ask more questions"
    echo -e "${GREEN}b${NC} - Ask in background (continue later)"
    echo -e "${GREEN}n${NC} - Done (save advice)"
    echo ""
    echo -e "${CYAN}💡 Thread ID: ${thread_id}${NC}"
    echo "   View thread: gtd-wizard → 11) Get Advice → 7) View Conversation Threads"
    echo ""
    read -p "Choice: " continue_conv
    echo ""
  else
    # Skip prompt - user already said yes, proceed directly to asking questions
    continue_conv="y"
  fi
  
  if [[ "$continue_conv" == "y" || "$continue_conv" == "Y" || "$continue_conv" == "b" || "$continue_conv" == "B" ]]; then
    local use_background=false
    if [[ "$continue_conv" == "b" || "$continue_conv" == "B" ]]; then
      use_background=true
    fi
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
      
      # Check if we should queue in background or process immediately
      if [[ "$use_background" == "true" ]]; then
        # Queue in background
        echo ""
        echo -e "${CYAN}📤 Queuing follow-up question for background processing...${NC}"
        
        # Add follow-up to thread and queue
        local request_id=$(add_followup_to_thread "$thread_id" "$followup_question" "$persona" "${use_simple_mode:+simple}" "$use_web_search")
        
        echo -e "${GREEN}✓ Follow-up queued (Thread: $thread_id, Request: $request_id)${NC}"
        echo ""
        echo "💡 You'll receive a Discord notification when the answer is ready."
        echo "   View thread: gtd-wizard → 11) Get Advice → 7) View Conversation Threads"
        echo ""
        
        # Start worker if not running
        if ! pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1 && ! pgrep -f "gtd_advice_worker.py" >/dev/null 2>&1; then
          echo "Starting advice worker..."
          if command -v gtd-advice-worker &>/dev/null; then
            (nohup gtd-advice-worker daemon >/tmp/advice-worker.log 2>&1 &) 2>/dev/null || true
            disown -a 2>/dev/null || true
            sleep 1
            local worker_pid=$(pgrep -f "gtd-advice-worker.*daemon" | head -1 || echo "")
            echo "✓ Worker started${worker_pid:+ (PID: $worker_pid)}"
            echo ""
          fi
        fi
        
        # Ask if they want to ask another question
        echo "Ask another follow-up question? (y/n): "
        read another_question
        if [[ "$another_question" != "y" && "$another_question" != "Y" ]]; then
          break
        fi
        continue
      fi
      
      # Process immediately (existing code)
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
      local advise_exit_code=0
      local temp_output=$(mktemp)
      
      # Disable exit on error temporarily to handle gtd-advise failures gracefully
      set +e
      if [[ "$use_simple_mode" == "true" ]]; then
        if [[ "$use_web_search" == "true" ]]; then
          # Build contextual search query
          local search_query="${initial_question} ${followup_question}"
          echo "🔍 Performing web search for follow-up question..."
          echo ""
          # Use timeout to prevent hanging (5 minutes max)
          timeout 300 gtd-advise --simple --web-search "$persona" "$search_query" > "$temp_output" 2>&1
          advise_exit_code=$?
        else
          # Use timeout to prevent hanging (5 minutes max)
          timeout 300 gtd-advise --simple "$persona" "$followup_prompt" > "$temp_output" 2>&1
          advise_exit_code=$?
        fi
      else
        # Regular mode - include context from original question
        if [[ "$persona" == "random" ]]; then
          # Use timeout to prevent hanging (5 minutes max)
          timeout 300 gtd-advise --random "$followup_prompt" > "$temp_output" 2>&1
          advise_exit_code=$?
        else
          # Use timeout to prevent hanging (5 minutes max)
          timeout 300 gtd-advise "$persona" "$followup_prompt" > "$temp_output" 2>&1
          advise_exit_code=$?
        fi
      fi
      set -e
      
      # Read output from temp file
      if [[ -f "$temp_output" ]]; then
        followup_answer=$(cat "$temp_output")
        rm -f "$temp_output"
      fi
      
      # Check if gtd-advise failed or timed out
      if [[ $advise_exit_code -ne 0 ]]; then
        echo ""
        if [[ $advise_exit_code -eq 124 ]]; then
          echo -e "${RED}❌ Request timed out${NC}"
          echo "The advice request took too long (>5 minutes). This might indicate a connection issue."
        else
          echo -e "${RED}❌ Error getting advice response${NC}"
          echo "The advice command encountered an error (exit code: $advise_exit_code)."
        fi
        echo ""
        if [[ -n "$followup_answer" ]]; then
          echo "Error output:"
          echo "$followup_answer"
          echo ""
        fi
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        # Ask if user wants to try again or continue
        echo "Would you like to:"
        echo "  1) Try asking the question again"
        echo "  2) Skip this question and continue"
        echo ""
        read -p "Choice (1/2, default: 2): " retry_choice
        retry_choice="${retry_choice:-2}"
        if [[ "$retry_choice" == "1" ]]; then
          continue  # Loop back to ask the question again
        else
          break  # Exit the follow-up loop
        fi
      fi
      
      # Check if we got an empty answer
      if [[ -z "$followup_answer" ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  No response received${NC}"
        echo "The advice command returned empty output. Would you like to try again?"
        echo ""
        read -p "Try again? (y/n, default: n): " retry_empty
        retry_empty="${retry_empty:-n}"
        if [[ "$retry_empty" == "y" || "$retry_empty" == "Y" ]]; then
          continue  # Loop back to ask the question again
        else
          break  # Exit the follow-up loop
        fi
      fi
      
      echo "$followup_answer"
      conversation_answers+=("$followup_answer")
      
      # Update thread with completed answer
      python3 <<PYTHON_EOF
import json
from pathlib import Path
from datetime import datetime

thread_file = Path("${HOME}/Documents/gtd/advice_threads/${thread_id}.json")
if thread_file.exists():
    with open(thread_file, 'r') as f:
        thread = json.load(f)
    
    # Add this Q&A pair to thread
    thread["questions"].append({
        "question": """$followup_question""",
        "timestamp": datetime.now().isoformat() + "Z"
    })
    thread["answers"].append({
        "answer": """$followup_answer""",
        "timestamp": datetime.now().isoformat() + "Z",
        "status": "completed"
    })
    thread["updated_at"] = datetime.now().isoformat() + "Z"
    
    with open(thread_file, 'w') as f:
        json.dump(thread, f, indent=2)
PYTHON_EOF
      
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

# Helper function to create or get conversation thread
create_conversation_thread() {
  local thread_id="$1"
  local initial_question="$2"
  local initial_answer="$3"
  local persona="$4"
  
  THREADS_DIR="${HOME}/Documents/gtd/advice_threads"
  mkdir -p "$THREADS_DIR"
  
  # Generate thread ID if not provided
  if [[ -z "$thread_id" ]]; then
    thread_id="thread_$(date +%Y%m%d_%H%M%S)_$$"
  fi
  
  local thread_file="${THREADS_DIR}/${thread_id}.json"
  
  # Create or update thread
  python3 <<PYTHON_EOF
import json
import sys
from datetime import datetime
from pathlib import Path

thread_id = "$thread_id"
thread_file = Path("$thread_file")
initial_question = """$initial_question"""
initial_answer = """$initial_answer"""
persona = "$persona"

# Load existing thread or create new
if thread_file.exists():
    with open(thread_file, 'r') as f:
        thread = json.load(f)
else:
    thread = {
        "id": thread_id,
        "persona": persona,
        "created_at": datetime.now().isoformat() + "Z",
        "questions": [],
        "answers": [],
        "status": "active"
    }

# Add initial Q&A if provided
if initial_question and initial_answer:
    thread["questions"].append({
        "question": initial_question,
        "timestamp": datetime.now().isoformat() + "Z"
    })
    thread["answers"].append({
        "answer": initial_answer,
        "timestamp": datetime.now().isoformat() + "Z",
        "status": "completed"
    })
    thread["updated_at"] = datetime.now().isoformat() + "Z"

# Save thread
with open(thread_file, 'w') as f:
    json.dump(thread, f, indent=2)

print(thread_id)
PYTHON_EOF
}

# Helper function to add follow-up question to thread (queued)
add_followup_to_thread() {
  local thread_id="$1"
  local followup_question="$2"
  local persona="$3"
  local mode="${4:-normal}"
  local web_search="${5:-false}"
  
  THREADS_DIR="${HOME}/Documents/gtd/advice_threads"
  local thread_file="${THREADS_DIR}/${thread_id}.json"
  
  if [[ ! -f "$thread_file" ]]; then
    echo "Error: Thread not found: $thread_id" >&2
    return 1
  fi
  
  # Add question to thread (pending status)
  python3 <<PYTHON_EOF
import json
import sys
from datetime import datetime
from pathlib import Path

thread_file = Path("$thread_file")
followup_question = """$followup_question"""

with open(thread_file, 'r') as f:
    thread = json.load(f)

# Add pending question
thread["questions"].append({
    "question": followup_question,
    "timestamp": datetime.now().isoformat() + "Z"
})
thread["answers"].append({
    "answer": "",
    "timestamp": datetime.now().isoformat() + "Z",
    "status": "pending"
})
thread["updated_at"] = datetime.now().isoformat() + "Z"

with open(thread_file, 'w') as f:
    json.dump(thread, f, indent=2)
PYTHON_EOF
  
  # Queue the follow-up question with thread context
  # Build context from previous Q&A pairs
  local context=$(python3 <<PYTHON_EOF
import json
from pathlib import Path

thread_file = Path("$thread_file")
with open(thread_file, 'r') as f:
    thread = json.load(f)

# Build context from previous Q&A
context_parts = []
for i in range(len(thread["questions"]) - 1):  # Exclude the current pending question
    if i < len(thread["answers"]) and thread["answers"][i].get("status") == "completed":
        q = thread["questions"][i]["question"]
        a = thread["answers"][i]["answer"]
        context_parts.append(f"Q: {q}\nA: {a}")

context = "\n\n".join(context_parts)
print(context)
PYTHON_EOF
)
  
  # Build prompt with full conversation context
  local full_prompt="Context: We were discussing:\n\n${context}\n\nFollow-up question: ${followup_question}\n\nAnswer this follow-up question about the same topic. Be specific and accurate."
  
  # Queue with thread_id
  queue_advice_request "$persona" "$full_prompt" "$mode" "$web_search" "$thread_id"
}

# Helper function to update thread with completed answer
update_thread_with_answer() {
  local thread_id="$1"
  local request_id="$2"
  
  THREADS_DIR="${HOME}/Documents/gtd/advice_threads"
  RESULTS_DIR="${HOME}/Documents/gtd/advice_results"
  local thread_file="${THREADS_DIR}/${thread_id}.json"
  local result_file="${RESULTS_DIR}/${request_id}.json"
  
  if [[ ! -f "$thread_file" ]] || [[ ! -f "$result_file" ]]; then
    return 1
  fi
  
  python3 <<PYTHON_EOF
import json
from pathlib import Path
from datetime import datetime

thread_file = Path("$thread_file")
result_file = Path("$result_file")

with open(thread_file, 'r') as f:
    thread = json.load(f)

with open(result_file, 'r') as f:
    result = json.load(f)

# Find the last pending answer and update it
for i in range(len(thread["answers"]) - 1, -1, -1):
    if thread["answers"][i].get("status") == "pending":
        thread["answers"][i]["answer"] = result.get("answer", "")
        thread["answers"][i]["status"] = result.get("status", "completed")
        thread["answers"][i]["completed_at"] = result.get("completed_at", datetime.now().isoformat() + "Z")
        thread["updated_at"] = datetime.now().isoformat() + "Z"
        break

with open(thread_file, 'w') as f:
    json.dump(thread, f, indent=2)
PYTHON_EOF
}

# Helper function to queue advice request for background processing
queue_advice_request() {
  local persona="$1"
  local question="$2"
  local mode="${3:-normal}"
  local web_search="${4:-false}"
  local thread_id="${5:-}"
  
  QUEUE_FILE="${HOME}/Documents/gtd/advice_queue.jsonl"
  mkdir -p "$(dirname "$QUEUE_FILE")"
  
  # Generate request ID
  local request_id="advice_$(date +%Y%m%d_%H%M%S)_$$"
  
  # Create request JSON - use temp file to safely pass question with special characters
  local temp_question=$(mktemp)
  python3 -c "import sys, json; print(json.dumps(sys.argv[1]))" "$question" > "$temp_question"
  
  # Find Python executable (prefer virtualenv)
  MCP_VENV="$HOME/code/dotfiles/mcp/venv/bin/python3"
  if [[ ! -f "$MCP_VENV" ]]; then
    MCP_VENV="$HOME/code/personal/dotfiles/mcp/venv/bin/python3"
  fi
  
  if [[ -f "$MCP_VENV" ]]; then
    PYTHON_CMD="$MCP_VENV"
  else
    PYTHON_CMD="python3"
  fi
  
  # Try RabbitMQ first, fall back to file queue
  local queue_result=$("$PYTHON_CMD" <<PYTHON_EOF
import json
import sys
import os
from pathlib import Path
from datetime import datetime

# Read question from temp file
with open("$temp_question", "r") as f:
    question = json.load(f)

request = {
    "id": "$request_id",
    "persona": "$persona",
    "question": question,
    "mode": "$mode",
    "web_search": "$web_search",
    "created_at": datetime.now().isoformat() + "Z"
}

# Add thread_id if provided
thread_id_val = "$thread_id"
if thread_id_val:
    request["thread_id"] = thread_id_val

# Try RabbitMQ first if available
try:
    import pika
    
    # Read RabbitMQ config
    sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
    try:
        from gtd_vector_db import read_database_config
        db_config = read_database_config()
        rabbitmq_enabled = db_config.get("rabbitmq_enabled", False)
        rabbitmq_url = db_config.get("rabbitmq_url", "amqp://localhost:5672")
        rabbitmq_queue = "gtd_advice"  # Advice queue name
    except:
        rabbitmq_enabled = False
        rabbitmq_url = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
        rabbitmq_queue = "gtd_advice"
    
    if rabbitmq_enabled:
        try:
            params = pika.URLParameters(rabbitmq_url)
            params.blocked_connection_timeout = 5
            connection = pika.BlockingConnection(params)
            channel = connection.channel()
            channel.queue_declare(queue=rabbitmq_queue, durable=True)
            
            channel.basic_publish(
                exchange='',
                routing_key=rabbitmq_queue,
                body=json.dumps(request),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Make message persistent
                )
            )
            connection.close()
            print("queued_to_rabbitmq")
            sys.exit(0)
        except Exception as e:
            # RabbitMQ failed, fall back to file queue
            pass
except ImportError:
    # pika not installed, use file queue
    pass

# Fallback to file queue
QUEUE_FILE = Path("$QUEUE_FILE")
QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)

with open(QUEUE_FILE, "a") as f:
    f.write(json.dumps(request) + "\n")

print("queued_to_file")
PYTHON_EOF
  )
  
  rm -f "$temp_question"
  
  # Return request ID
  echo "$request_id"
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
        local create_output
        create_output=$(echo "$content" | gtd-brain create "$title" "$para_location" 2>&1)
        local create_exit=$?
        if [[ $create_exit -eq 0 ]]; then
          echo "✓ Saved as Second Brain note in ${para_location}"
          echo "$create_output"
        else
          echo "❌ Failed to create note. Error:"
          echo "$create_output" | head -3
          echo ""
          echo "Saving to inbox instead..."
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
  
  # Check for pending results
  RESULTS_DIR="${HOME}/Documents/gtd/advice_results"
  QUEUE_FILE="${HOME}/Documents/gtd/advice_queue.jsonl"
  local pending_results=0
  local pending_queue=0
  
  if [[ -d "$RESULTS_DIR" ]]; then
    pending_results=$(find "$RESULTS_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [[ -f "$QUEUE_FILE" ]]; then
    pending_queue=$(wc -l < "$QUEUE_FILE" | tr -d ' ')
  fi
  
  if [[ "$pending_results" -gt 0 ]] || [[ "$pending_queue" -gt 0 ]]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💡 Background Advice Status${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ "$pending_results" -gt 0 ]]; then
      echo -e "${GREEN}  ✓ $pending_results advice result(s) ready for review${NC}"
    fi
    if [[ "$pending_queue" -gt 0 ]]; then
      echo -e "${YELLOW}  ⏳ $pending_queue request(s) pending in queue${NC}"
    fi
    echo ""
  fi
  
  echo "How would you like to get advice?"
  echo ""
  echo "  1) Random persona"
  echo "  2) Specific persona"
  echo "  3) All personas"
  echo "  4) Review daily log"
  echo "  5) Simple factual question (no GTD context)"
  if [[ "$pending_results" -gt 0 ]]; then
    echo -e "  6) 📋 Review Background Advice Results ${GREEN}($pending_results ready)${NC}"
  else
    echo "  6) 📋 Review Background Advice Results"
  fi
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
          echo ""
          echo "How would you like to process this request?"
          echo ""
          echo "  1) Process now (wait for response)"
          echo "  2) Process in background (get Discord notification when ready)"
          echo ""
          echo -n "Choose (default: 1): "
          read process_mode
          process_mode="${process_mode:-1}"
          
          if [[ "$process_mode" == "2" ]]; then
            # Queue for background processing
            echo ""
            echo -e "${CYAN}📤 Queuing advice request for background processing...${NC}"
            local request_id=$(queue_advice_request "random" "$question" "random" "false")
            echo -e "${GREEN}✓ Request queued (ID: $request_id)${NC}"
            echo ""
            echo "💡 You'll receive a Discord notification when the advice is ready."
            echo "   Review results: Option 6) Review Background Advice Results"
            echo ""
            
            # Start worker if not running
            if ! pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1; then
              echo "Starting advice worker..."
              (nohup gtd-advice-worker daemon >/tmp/advice-worker.log 2>&1 &) 2>/dev/null || true
              disown -a 2>/dev/null || true
              sleep 1
              local worker_pid=$(pgrep -f "gtd-advice-worker.*daemon" | head -1 || echo "")
              echo "✓ Worker started${worker_pid:+ (PID: $worker_pid)}"
              echo "   Logs: tail -f /tmp/advice-worker.log"
              echo ""
            fi
          else
            # Process immediately
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
          echo ""
          echo "How would you like to process this request?"
          echo ""
          echo "  1) Process now (wait for response)"
          echo "  2) Process in background (get Discord notification when ready)"
          echo ""
          echo -n "Choose (default: 1): "
          read process_mode
          process_mode="${process_mode:-1}"
          
          if [[ "$process_mode" == "2" ]]; then
            # Queue for background processing
            echo ""
            echo -e "${CYAN}📤 Queuing advice request for background processing...${NC}"
            local request_id=$(queue_advice_request "$persona" "$question" "normal" "false")
            echo -e "${GREEN}✓ Request queued (ID: $request_id)${NC}"
            echo ""
            echo "💡 You'll receive a Discord notification when the advice is ready."
            echo "   Review results: Option 6) Review Background Advice Results"
            echo ""
            
            # Start worker if not running
            if ! pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1; then
              echo "Starting advice worker..."
              (nohup gtd-advice-worker daemon >/tmp/advice-worker.log 2>&1 &) 2>/dev/null || true
              disown -a 2>/dev/null || true
              sleep 1
              local worker_pid=$(pgrep -f "gtd-advice-worker.*daemon" | head -1 || echo "")
              echo "✓ Worker started${worker_pid:+ (PID: $worker_pid)}"
              echo "   Logs: tail -f /tmp/advice-worker.log"
              echo ""
            fi
          else
            # Process immediately
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
      
      # Handle follow-up questions (extract persona from output or use random)
      # Note: advise_random prints "Randomly selected: <persona>", but for simplicity
      # we'll use random selection for follow-ups too to maintain variety
      local followup_persona="random"
      handle_followup_questions "$followup_persona" "Daily log review" "$advice_output" "false" "false"
      
      # Save conversation if there were follow-ups, or ask to save if no follow-ups
      if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]]; then
        echo ""
        echo -e "${BOLD}Save this conversation? (y/n):${NC} "
        read save_advice
        if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
          save_advice_conversation "Daily log review" "$followup_persona" "$FOLLOWUP_CONVERSATION"
        fi
      else
        echo ""
        echo -e "${BOLD}Save this review? (y/n):${NC} "
        read save_advice
        if [[ "$save_advice" == "y" || "$save_advice" == "Y" ]]; then
          save_advice_conversation "Daily log review" "random persona" "$advice_output"
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
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📋 Review Background Advice Results${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check for pending requests
      QUEUE_FILE="${HOME}/Documents/gtd/advice_queue.jsonl"
      if [[ -f "$QUEUE_FILE" ]] && [[ -s "$QUEUE_FILE" ]]; then
        local queue_count=$(wc -l < "$QUEUE_FILE" | tr -d ' ')
        echo -e "${YELLOW}⚠️  $queue_count advice request(s) pending in queue${NC}"
        echo ""
        
        # Check if Python RabbitMQ worker is running (correct one)
        if ! pgrep -f "gtd_advice_worker.py" >/dev/null 2>&1; then
          # Check if old bash worker is running (wrong one)
          if pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Old bash worker detected (doesn't connect to RabbitMQ)${NC}"
            echo ""
            echo -n "Stop old worker and start Python RabbitMQ worker? (y/n): "
            read start_worker
            if [[ "$start_worker" == "y" || "$start_worker" == "Y" ]]; then
              pkill -f "gtd-advice-worker.*daemon" 2>/dev/null || true
              sleep 1
              make -C "$HOME/code/dotfiles" advice-worker-start 2>/dev/null || true
              sleep 2
              local worker_pid=$(pgrep -f "gtd_advice_worker.py" | head -1 || echo "")
              if [[ -n "$worker_pid" ]]; then
                echo -e "${GREEN}✓ Python RabbitMQ worker started (PID: $worker_pid)${NC}"
              else
                echo -e "${YELLOW}⚠️  Worker may not have started. Check logs: tail -f /tmp/advice-worker.log${NC}"
              fi
              echo "   Logs: tail -f /tmp/advice-worker.log"
              echo ""
            fi
          else
            echo -e "${YELLOW}⚠️  Advice worker is not running${NC}"
            echo ""
            echo -n "Start the Python RabbitMQ worker now? (y/n): "
            read start_worker
            if [[ "$start_worker" == "y" || "$start_worker" == "Y" ]]; then
              make -C "$HOME/code/dotfiles" advice-worker-start 2>/dev/null || true
              sleep 2
              local worker_pid=$(pgrep -f "gtd_advice_worker.py" | head -1 || echo "")
              if [[ -n "$worker_pid" ]]; then
                echo -e "${GREEN}✓ Python RabbitMQ worker started (PID: $worker_pid)${NC}"
              else
                echo -e "${YELLOW}⚠️  Worker may not have started. Check logs: tail -f /tmp/advice-worker.log${NC}"
              fi
              echo "   Logs: tail -f /tmp/advice-worker.log"
              echo ""
            fi
          fi
        else
          echo -e "${GREEN}✓ Python RabbitMQ worker is running${NC}"
          echo ""
        fi
      fi
      
      RESULTS_DIR="${HOME}/Documents/gtd/advice_results"
      if [[ ! -d "$RESULTS_DIR" ]] || [[ -z "$(find "$RESULTS_DIR" -name "*.json" -type f 2>/dev/null)" ]]; then
        echo "No background advice results found."
        echo ""
        echo "Results are stored in: $RESULTS_DIR"
        echo ""
        echo "💡 Tip: When asking for advice, choose the background option to get"
        echo "   notified via Discord when the advice is ready!"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # List all results
      echo "Available advice results:"
      echo ""
      
      local results=()
      while IFS= read -r result_file; do
        [[ -f "$result_file" ]] && results+=("$result_file")
      done < <(find "$RESULTS_DIR" -name "*.json" -type f -exec ls -t {} + 2>/dev/null | head -20)
      
      if [[ ${#results[@]} -eq 0 ]]; then
        echo "No results found."
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Display list
      local i=1
      for result_file in "${results[@]}"; do
        local result_id=$(basename "$result_file" .json)
        local persona=$(python3 -c "import sys, json; print(json.load(open('$result_file')).get('persona', 'unknown'))" 2>/dev/null || echo "unknown")
        local question=$(python3 -c "import sys, json; q=json.load(open('$result_file')).get('question', ''); print(q[:60] + '...' if len(q) > 60 else q)" 2>/dev/null || echo "")
        local status=$(python3 -c "import sys, json; print(json.load(open('$result_file')).get('status', 'unknown'))" 2>/dev/null || echo "unknown")
        local completed_at=$(python3 -c "import sys, json; print(json.load(open('$result_file')).get('completed_at', '')[:10])" 2>/dev/null || echo "")
        
        local status_color="${GREEN}"
        [[ "$status" == "error" ]] && status_color="${RED}"
        
        echo -e "  ${i}) [${status_color}${status}${NC}] ${persona} - ${completed_at}"
        echo "     ${question}"
        i=$((i + 1))
      done
      
      echo ""
      echo -n "Select result to view (number) or 0 to go back: "
      read selection
      
      if [[ "$selection" == "0" ]] || [[ -z "$selection" ]]; then
        return 0
      fi
      
      # Validate selection
      if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#results[@]} ]]; then
        echo "Invalid selection"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Get selected result
      local selected_file="${results[$((selection - 1))]}"
      local answer_file="${selected_file%.json}_answer.txt"
      
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📋 Advice Result${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Show metadata
      local persona=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('persona', 'unknown'))" 2>/dev/null || echo "unknown")
      local question=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('question', ''))" 2>/dev/null || echo "")
      local completed_at=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('completed_at', ''))" 2>/dev/null || echo "")
      local duration=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('duration_seconds', 0))" 2>/dev/null || echo "0")
      
      echo -e "${BOLD}Persona:${NC} $persona"
      echo -e "${BOLD}Question:${NC} $question"
      echo -e "${BOLD}Completed:${NC} $completed_at"
      echo -e "${BOLD}Duration:${NC} ${duration}s"
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      
      # Show answer
      local saved_answer=""
      if [[ -f "$answer_file" ]]; then
        echo -e "${BOLD}Answer:${NC}"
        echo ""
        saved_answer=$(cat "$answer_file")
        echo "$saved_answer"
      else
        echo "Answer file not found: $answer_file"
      fi
      
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      
      # Ask if user wants to discuss this advice (conversation feature)
      if [[ -n "$saved_answer" ]]; then
        echo -e "${BOLD}Do you have any follow-up questions about this advice?${NC}"
        echo -e "${GREEN}y${NC} - Ask more questions"
        echo -e "${GREEN}n${NC} - Continue to options"
        echo ""
        read -p "Choice: " discuss_choice
        echo ""
        
        if [[ "$discuss_choice" == "y" || "$discuss_choice" == "Y" ]]; then
          # Use conversation feature - skip the prompt since user already said yes
          handle_followup_questions "$persona" "$question" "$saved_answer" "false" "false" "" "true"
          
          # Save conversation if there were follow-ups
          if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]]; then
            echo ""
            echo -e "${BOLD}Save this conversation? (y/n):${NC} "
            read save_conv
            if [[ "$save_conv" == "y" || "$save_conv" == "Y" ]]; then
              save_advice_conversation "$question" "$persona" "$FOLLOWUP_CONVERSATION"
              echo ""
              echo "✓ Conversation saved!"
            fi
          fi
        fi
      fi
      
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Options:"
      echo "  1) Save this advice"
      echo "  2) Delete this result"
      echo "  0) Back to list"
      echo ""
      echo -n "Choose: "
      read action
      
      case "$action" in
        1)
        local saved_question="$question"
        local saved_persona="$persona"
        local answer_to_save="$saved_answer"
        if [[ -z "$answer_to_save" ]]; then
          [[ -f "$answer_file" ]] && answer_to_save=$(cat "$answer_file")
        fi
        if [[ -n "$answer_to_save" ]]; then
          # If we have a conversation, save that; otherwise save the original answer
          if [[ "$FOLLOWUP_HAS_FOLLOWUPS" -eq 1 ]] && [[ -n "$FOLLOWUP_CONVERSATION" ]]; then
            save_advice_conversation "$saved_question" "$saved_persona" "$FOLLOWUP_CONVERSATION"
          else
            save_advice_conversation "$saved_question" "$saved_persona" "$answer_to_save"
          fi
          echo ""
          echo "✓ Advice saved!"
        else
          echo "Error: No answer to save"
        fi
          ;;
        2)
          echo -n "Delete this result? (y/n): "
          read confirm
          if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm -f "$selected_file" "$answer_file"
            echo "✓ Result deleted"
          fi
          ;;
      esac
      
      echo ""
      # No auto-continue - user can read and press Enter when ready
      read -p "Press Enter to continue..."
      ;;
    7)
      # View Conversation Threads
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}💬 Conversation Threads${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      THREADS_DIR="${HOME}/Documents/gtd/advice_threads"
      if [[ ! -d "$THREADS_DIR" ]] || [[ -z "$(find "$THREADS_DIR" -name "*.json" -type f 2>/dev/null)" ]]; then
        echo "No conversation threads found."
        echo ""
        echo "Threads are created when you ask follow-up questions."
        echo "💡 Tip: When asking follow-up questions, choose 'b' for background mode"
        echo "   to continue the conversation later!"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # List all threads
      echo "Available conversation threads:"
      echo ""
      
      local threads=()
      while IFS= read -r thread_file; do
        [[ -f "$thread_file" ]] && threads+=("$thread_file")
      done < <(find "$THREADS_DIR" -name "*.json" -type f -exec ls -t {} + 2>/dev/null | head -20)
      
      if [[ ${#threads[@]} -eq 0 ]]; then
        echo "No threads found."
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Display list
      local i=1
      for thread_file in "${threads[@]}"; do
        local thread_id=$(basename "$thread_file" .json)
        local persona=$(python3 -c "import sys, json; print(json.load(open('$thread_file')).get('persona', 'unknown'))" 2>/dev/null || echo "unknown")
        local first_question=$(python3 -c "import sys, json; qs=json.load(open('$thread_file')).get('questions', []); print(qs[0]['question'][:60] + '...' if qs and len(qs[0]['question']) > 60 else (qs[0]['question'] if qs else 'No questions'))" 2>/dev/null || echo "")
        local created_at=$(python3 -c "import sys, json; print(json.load(open('$thread_file')).get('created_at', '')[:10])" 2>/dev/null || echo "")
        local q_count=$(python3 -c "import sys, json; print(len(json.load(open('$thread_file')).get('questions', [])))" 2>/dev/null || echo "0")
        local pending_count=$(python3 -c "import sys, json; answers=json.load(open('$thread_file')).get('answers', []); print(sum(1 for a in answers if a.get('status') == 'pending'))" 2>/dev/null || echo "0")
        
        local status_indicator=""
        if [[ "$pending_count" -gt 0 ]]; then
          status_indicator="${YELLOW}⏳ $pending_count pending${NC}"
        else
          status_indicator="${GREEN}✓ Complete${NC}"
        fi
        
        echo -e "  ${i}) [${status_indicator}] ${persona} - ${created_at} (${q_count} Q&A)"
        echo "     ${first_question}"
        echo "     Thread ID: ${CYAN}${thread_id}${NC}"
        i=$((i + 1))
      done
      
      echo ""
      echo -n "Select thread to view (number) or 0 to go back: "
      read selection
      
      if [[ "$selection" == "0" ]] || [[ -z "$selection" ]]; then
        return 0
      fi
      
      # Validate selection
      if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#threads[@]} ]]; then
        echo "Invalid selection"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Get selected thread
      local selected_file="${threads[$((selection - 1))]}"
      local thread_id=$(basename "$selected_file" .json)
      
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}💬 Conversation Thread${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Display full conversation
      python3 <<PYTHON_EOF
import json
from pathlib import Path
from datetime import datetime

thread_file = Path("$selected_file")
with open(thread_file, 'r') as f:
    thread = json.load(f)

persona = thread.get("persona", "unknown")
created_at = thread.get("created_at", "")[:10]
updated_at = thread.get("updated_at", "")[:10] if thread.get("updated_at") else created_at

print(f"Persona: {persona}")
print(f"Created: {created_at}")
print(f"Updated: {updated_at}")
print(f"Thread ID: {thread.get('id', 'unknown')}")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")

questions = thread.get("questions", [])
answers = thread.get("answers", [])

for i in range(len(questions)):
    q = questions[i]
    a = answers[i] if i < len(answers) else None
    
    print(f"**Q{i+1}:** {q['question']}")
    print("")
    
    if a:
        if a.get("status") == "pending":
            print(f"**A{i+1}:** ⏳ Pending... (check background results)")
        else:
            print(f"**A{i+1}:**")
            print(a.get("answer", ""))
    else:
        print(f"**A{i+1}:** (No answer yet)")
    
    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
PYTHON_EOF
      
      echo ""
      echo "Options:"
      echo "  1) Ask a follow-up question (background)"
      echo "  2) Ask a follow-up question (now)"
      echo "  3) Save this conversation"
      echo "  4) Delete this thread"
      echo "  0) Back to list"
      echo ""
      echo -n "Choose: "
      read thread_action
      
      case "$thread_action" in
        1)
          # Ask follow-up in background
          echo ""
          echo -n "Your follow-up question: "
          read followup_q
          if [[ -n "$followup_q" ]]; then
            local persona=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('persona', 'random'))" 2>/dev/null || echo "random")
            local request_id=$(add_followup_to_thread "$thread_id" "$followup_q" "$persona" "normal" "false")
            echo ""
            echo -e "${GREEN}✓ Follow-up queued (Request: $request_id)${NC}"
            echo "💡 You'll receive a Discord notification when the answer is ready."
            echo ""
            
            # Start worker if not running
            if ! pgrep -f "gtd-advice-worker.*daemon" >/dev/null 2>&1 && ! pgrep -f "gtd_advice_worker.py" >/dev/null 2>&1; then
              echo "Starting advice worker..."
              if command -v gtd-advice-worker &>/dev/null; then
                (nohup gtd-advice-worker daemon >/tmp/advice-worker.log 2>&1 &) 2>/dev/null || true
                disown -a 2>/dev/null || true
                sleep 1
                local worker_pid=$(pgrep -f "gtd-advice-worker.*daemon" | head -1 || echo "")
                echo "✓ Worker started${worker_pid:+ (PID: $worker_pid)}"
                echo ""
              fi
            fi
          fi
          ;;
        2)
          # Ask follow-up now
          echo ""
          echo -n "Your follow-up question: "
          read followup_q
          if [[ -n "$followup_q" ]]; then
            local persona=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('persona', 'random'))" 2>/dev/null || echo "random")
            local initial_q=$(python3 -c "import sys, json; qs=json.load(open('$selected_file')).get('questions', []); print(qs[0]['question'] if qs else '')" 2>/dev/null || echo "")
            local initial_a=$(python3 -c "import sys, json; ans=json.load(open('$selected_file')).get('answers', []); print(ans[0]['answer'] if ans and ans[0].get('status') == 'completed' else '')" 2>/dev/null || echo "")
            
            # Use handle_followup_questions with existing thread
            handle_followup_questions "$persona" "$initial_q" "$initial_a" "false" "false" "$thread_id" "false"
          fi
          ;;
        3)
          # Save conversation
          local full_conversation=$(python3 <<PYTHON_EOF
import json
from pathlib import Path

thread_file = Path("$selected_file")
with open(thread_file, 'r') as f:
    thread = json.load(f)

questions = thread.get("questions", [])
answers = thread.get("answers", [])

conversation = ""
for i in range(len(questions)):
    q = questions[i]
    a = answers[i] if i < len(answers) else None
    conversation += f"**Q{i+1}:** {q['question']}\n\n"
    if a and a.get("status") == "completed":
        conversation += f"**A{i+1}:**\n{a.get('answer', '')}\n\n---\n\n"

print(conversation)
PYTHON_EOF
)
          local first_q=$(python3 -c "import sys, json; qs=json.load(open('$selected_file')).get('questions', []); print(qs[0]['question'] if qs else '')" 2>/dev/null || echo "")
          local persona=$(python3 -c "import sys, json; print(json.load(open('$selected_file')).get('persona', 'unknown'))" 2>/dev/null || echo "unknown")
          save_advice_conversation "$first_q" "$persona" "$full_conversation"
          echo ""
          echo "✓ Conversation saved!"
          ;;
        4)
          echo -n "Delete this thread? (y/n): "
          read confirm
          if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm -f "$selected_file"
            echo "✓ Thread deleted"
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
    gtd_quick_pause
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
      gtd_quick_pause
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
          gtd_quick_pause
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
  gtd_quick_pause
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
    gtd_quick_pause
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
  
  gtd_quick_pause
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
  gtd_quick_pause
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
  echo "  4) 🧪 Test LM Service Connection (LM Studio/Ollama)"
  echo "  5) 📋 View Current Configuration"
  echo "  6) 📖 Installation Instructions"
  echo "  7) 🔧 Setup MCP Server & Virtualenv"
  echo "  8) 🤖 Manage AI Models (Check & Load)"
  echo "  9) ✏️  Edit Configuration Files (via vim)"
  echo "  10) 🐰 Setup RabbitMQ Connection"
  echo "  11) 📁 Setup Vector Filewatcher (Auto-queue files)"
  echo "  12) 🧠 Setup Deep Analysis Auto-Scheduler (Auto-submit jobs)"
  echo "  13) 🚀 Deploy External Services (RabbitMQ, Database)"
  echo "  14) 👷 Manage Background Workers (Start/Stop/Restart)"
  echo "  15) ☸️  Switch Kubernetes Context (Docker Desktop ↔ Rancher Desktop)"
  echo ""
  echo -e "${BOLD}${GREEN}Guided Setup:${NC}"
  echo "  16) 🚀 Complete Guided Setup (Walk through entire setup process)"
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
          gtd_quick_pause
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
      # Test LM Service Connection
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🧪 Test LM Service Connection${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Find config files
      GTD_CONFIG="$HOME/.gtd_config"
      GTD_CONFIG_AI="$HOME/.gtd_config_ai"
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/personal/dotfiles/zsh/.gtd_config"
      elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
        GTD_CONFIG="$HOME/code/dotfiles/zsh/.gtd_config"
      fi
      if [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config_ai" ]]; then
        GTD_CONFIG_AI="$HOME/code/personal/dotfiles/zsh/.gtd_config_ai"
      elif [[ -f "$HOME/code/dotfiles/zsh/.gtd_config_ai" ]]; then
        GTD_CONFIG_AI="$HOME/code/dotfiles/zsh/.gtd_config_ai"
      fi
      
      # Source config to get current settings
      if [[ -f "$GTD_CONFIG" ]]; then
        source "$GTD_CONFIG" 2>/dev/null || true
      fi
      if [[ -f "$GTD_CONFIG_AI" ]]; then
        source "$GTD_CONFIG_AI" 2>/dev/null || true
      fi
      
      # Get computer mode (work/home) to use correct model variables
      local computer_mode="${GTD_COMPUTER_MODE:-home}"
      computer_mode=$(echo "$computer_mode" | tr '[:upper:]' '[:lower:]')
      
      # Determine current backend (check mode-specific first, then default)
      local current_backend=""
      if [[ "$computer_mode" == "work" ]]; then
        current_backend="${WORK_AI_BACKEND:-${AI_BACKEND:-lmstudio}}"
      else
        current_backend="${HOME_AI_BACKEND:-${AI_BACKEND:-lmstudio}}"
      fi
      current_backend=$(echo "$current_backend" | tr '[:upper:]' '[:lower:]')
      
      echo -e "${BOLD}Current Configuration:${NC}"
      echo "  Mode: $computer_mode"
      echo "  Backend: $current_backend"
      echo ""
      
      # Test based on backend
      if [[ "$current_backend" == "ollama" ]]; then
        # Test Ollama - use mode-specific model if available
        ollama_url="${OLLAMA_URL:-http://localhost:11434/v1/chat/completions}"
        if [[ "$computer_mode" == "work" ]]; then
          ollama_model="${WORK_OLLAMA_CHAT_MODEL:-${OLLAMA_CHAT_MODEL:-gemma2:1b}}"
        else
          ollama_model="${HOME_OLLAMA_CHAT_MODEL:-${OLLAMA_CHAT_MODEL:-gemma2:1b}}"
        fi
        base_url=$(echo "$ollama_url" | sed 's|/v1/chat/completions||')
        
        echo -e "${BOLD}Testing Ollama Connection:${NC}"
        echo "  URL: $base_url"
        echo "  Model: $ollama_model"
        echo ""
        
        # Test 1: Check if server is running
        echo -n "  1. Checking if server is running... "
        if curl -s --max-time 5 "${base_url}/v1/models" >/dev/null 2>&1; then
          echo -e "${GREEN}✅ Server is running${NC}"
          
          # Get available models
          models_response=$(curl -s --max-time 5 "${base_url}/v1/models" 2>/dev/null)
          if [[ -n "$models_response" ]]; then
            available_models=$(echo "$models_response" | python3 -c "import sys, json; data=json.load(sys.stdin); models=[m.get('id', 'unknown') for m in data.get('data', [])]; print(', '.join(models[:5]))" 2>/dev/null || echo "unknown")
            echo "     Available models: $available_models"
          fi
        else
          echo -e "${RED}❌ Server is not running${NC}"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   1. Start Ollama server: ollama serve"
          echo "   2. Or check if Ollama is installed: ollama --version"
          echo ""
          gtd_quick_pause
          continue
        fi
        
        # Test 2: Check if model is available
        echo -n "  2. Checking if model '$ollama_model' is available... "
        models_response=$(curl -s --max-time 5 "${base_url}/v1/models" 2>/dev/null)
        if echo "$models_response" | python3 -c "import sys, json; data=json.load(sys.stdin); models=[m.get('id', '') for m in data.get('data', [])]; sys.exit(0 if '$ollama_model' in models else 1)" 2>/dev/null; then
          echo -e "${GREEN}✅ Model is available${NC}"
        else
          echo -e "${YELLOW}⚠️  Model not found in available models${NC}"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   Pull the model: ollama pull $ollama_model"
          echo "   Or check available models: ollama list"
          echo ""
        fi
        
        # Test 3: Test actual API call
        echo -n "  3. Testing API call with model... "
        test_payload=$(cat <<EOF
{
  "model": "$ollama_model",
  "messages": [{"role": "user", "content": "Say hello"}],
  "max_tokens": 10
}
EOF
)
        api_response=$(curl -s --max-time 30 -X POST "$ollama_url" \
          -H "Content-Type: application/json" \
          -d "$test_payload" 2>&1)
        
        if echo "$api_response" | grep -q '"choices"' 2>/dev/null; then
          echo -e "${GREEN}✅ API call successful${NC}"
          response_text=$(echo "$api_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('choices', [{}])[0].get('message', {}).get('content', '')[:50])" 2>/dev/null || echo "")
          if [[ -n "$response_text" ]]; then
            echo "     Response preview: ${response_text}..."
          fi
        elif echo "$api_response" | grep -qi "timeout\|connection refused\|connection reset" 2>/dev/null; then
          echo -e "${RED}❌ Connection failed${NC}"
          echo "     Error: Connection timeout or refused"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   1. Make sure Ollama server is running: ollama serve"
          echo "   2. Check if the model is loaded: ollama list"
          echo "   3. Try pulling the model: ollama pull $ollama_model"
        elif echo "$api_response" | grep -qi "model.*not found\|model.*not available" 2>/dev/null; then
          echo -e "${RED}❌ Model not found${NC}"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   Pull the model: ollama pull $ollama_model"
        else
          echo -e "${YELLOW}⚠️  Unexpected response${NC}"
          error_msg=$(echo "$api_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', {}).get('message', 'Unknown error')[:100])" 2>/dev/null || echo "Unknown error")
          echo "     Error: $error_msg"
        fi
        
      else
        # Test LM Studio - use mode-specific model if available
        lm_url="${LM_STUDIO_URL:-http://localhost:1234/v1/chat/completions}"
        if [[ "$computer_mode" == "work" ]]; then
          lm_model="${WORK_LM_STUDIO_CHAT_MODEL:-${LM_STUDIO_CHAT_MODEL:-google/gemma-3-1b}}"
        else
          lm_model="${HOME_LM_STUDIO_CHAT_MODEL:-${LM_STUDIO_CHAT_MODEL:-qwen/qwen3-1.7b}}"
        fi
        base_url=$(echo "$lm_url" | sed 's|/v1/chat/completions||')
        
        echo -e "${BOLD}Testing LM Studio Connection:${NC}"
        echo "  URL: $base_url"
        echo "  Model: $lm_model"
        echo ""
        
        # Test 1: Check if server is running
        echo -n "  1. Checking if server is running... "
        if curl -s --max-time 5 "${base_url}/v1/models" >/dev/null 2>&1; then
          echo -e "${GREEN}✅ Server is running${NC}"
          
          # Get available models
          models_response=$(curl -s --max-time 5 "${base_url}/v1/models" 2>/dev/null)
          if [[ -n "$models_response" ]]; then
            available_models=$(echo "$models_response" | python3 -c "import sys, json; data=json.load(sys.stdin); models=[m.get('id', 'unknown') for m in data.get('data', [])]; print(', '.join(models[:5]))" 2>/dev/null || echo "unknown")
            echo "     Available models: $available_models"
          fi
        else
          echo -e "${RED}❌ Server is not running${NC}"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   1. Open LM Studio application"
          echo "   2. Go to the 'Server' tab"
          echo "   3. Click 'Start Server'"
          echo "   4. Make sure it's running on port 1234 (or your configured port)"
          echo ""
          gtd_quick_pause
          continue
        fi
        
        # Test 2: Check if model is available
        echo -n "  2. Checking if model '$lm_model' is available... "
        models_response=$(curl -s --max-time 5 "${base_url}/v1/models" 2>/dev/null)
        if echo "$models_response" | python3 -c "import sys, json; data=json.load(sys.stdin); models=[m.get('id', '') for m in data.get('data', [])]; sys.exit(0 if '$lm_model' in models else 1)" 2>/dev/null; then
          echo -e "${GREEN}✅ Model is available${NC}"
        else
          echo -e "${YELLOW}⚠️  Model not found in available models${NC}"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   1. Open LM Studio"
          echo "   2. Go to the 'Chat' or 'Models' tab"
          echo "   3. Find and load the model: $lm_model"
          echo "   4. Wait for the model to finish loading"
          echo ""
        fi
        
        # Test 3: Test actual API call
        echo -n "  3. Testing API call with model... "
        test_payload=$(cat <<EOF
{
  "model": "$lm_model",
  "messages": [{"role": "user", "content": "Say hello"}],
  "max_tokens": 10
}
EOF
)
        api_response=$(curl -s --max-time 30 -X POST "$lm_url" \
          -H "Content-Type: application/json" \
          -d "$test_payload" 2>&1)
        
        if echo "$api_response" | grep -q '"choices"' 2>/dev/null; then
          echo -e "${GREEN}✅ API call successful${NC}"
          response_text=$(echo "$api_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('choices', [{}])[0].get('message', {}).get('content', '')[:50])" 2>/dev/null || echo "")
          if [[ -n "$response_text" ]]; then
            echo "     Response preview: ${response_text}..."
          fi
        elif echo "$api_response" | grep -qi "timeout\|connection refused\|connection reset" 2>/dev/null; then
          echo -e "${RED}❌ Connection failed${NC}"
          echo "     Error: Connection timeout or refused"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   1. Make sure LM Studio server is running (Server tab → Start Server)"
          echo "   2. Check if a model is loaded in LM Studio"
          echo "   3. Wait for the model to finish loading if it's still loading"
        elif echo "$api_response" | grep -qi "model.*not found\|model.*not available\|model.*not loaded" 2>/dev/null; then
          echo -e "${RED}❌ Model not loaded${NC}"
          echo ""
          echo -e "${YELLOW}💡 To fix:${NC}"
          echo "   1. Open LM Studio"
          echo "   2. Go to the 'Chat' or 'Models' tab"
          echo "   3. Find and load the model: $lm_model"
          echo "   4. Wait for the model to finish loading"
        else
          echo -e "${YELLOW}⚠️  Unexpected response${NC}"
          error_msg=$(echo "$api_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', {}).get('message', 'Unknown error')[:100])" 2>/dev/null || echo "Unknown error")
          echo "     Error: $error_msg"
        fi
      fi
      
      echo ""
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Test complete!"
      echo ""
      gtd_enter_to_continue
      ;;
    5)
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
      echo -e "${BOLD}Complete Setup Guide:${NC}"
      echo "  📚 See: docs/COMPLETE_SETUP_GUIDE.md for full step-by-step instructions"
      echo ""
      echo -e "${BOLD}External Services:${NC}"
      echo ""
      echo -e "${GREEN}1. Download External Service Repositories:${NC}"
      echo "   mkdir -p ~/code/external_services"
      echo "   cd ~/code/external_services"
      echo ""
      echo -e "${GREEN}   Database (PostgreSQL):${NC}"
      echo "   git clone git@github.com:the-great-abby/postgres_databases.git database"
      echo "   cd database && make setup"
      echo ""
      echo -e "${GREEN}   RabbitMQ:${NC}"
      echo "   git clone git@github.com:the-great-abby/message_queue.git rabbitmq"
      echo "   cd rabbitmq && make setup"
      echo ""
      echo -e "${GREEN}   Ollama Controller:${NC}"
      echo "   git clone git@github.com:the-great-abby/llm_proxy.git ollama_controller"
      echo "   cd ollama_controller && make k8s-deploy"
      echo ""
      echo -e "${GREEN}2. Get Connection Information:${NC}"
      echo "   Database: cd ~/code/external_services/database && make connection-info"
      echo "   RabbitMQ: cd ~/code/external_services/rabbitmq && make connection-info"
      echo "   Ollama Controller: cd ~/code/external_services/ollama_controller && make connection-info"
      echo ""
      echo -e "${BOLD}AI Host Setup:${NC}"
      echo ""
      echo -e "${GREEN}LM Studio:${NC}"
      echo "  1. Download from: https://lmstudio.ai/"
      echo "  2. Install and open LM Studio"
      echo "  3. Download a model (Search tab → Download)"
      echo "  4. Load the model (Chat tab → Select model → Load)"
      echo "  5. Start local server (Server tab → Start Server)"
      echo "  6. Default port: 1234"
      echo ""
      echo -e "${GREEN}Ollama:${NC}"
      echo "  1. Install:"
      echo "     macOS: brew install ollama"
      echo "     Linux: curl -fsSL https://ollama.com/install.sh | sh"
      echo "  2. Start server: ollama serve"
      echo "  3. Pull a model: ollama pull gemma2:1b"
      echo "  4. List models: ollama list"
      echo "  5. Default port: 11434"
      echo ""
      echo -e "${GREEN}Ollama Controller (Recommended):${NC}"
      echo "  Provides request throttling and queuing for AI requests."
      echo "  1. Clone: git clone git@github.com:the-great-abby/llm_proxy.git ~/code/external_services/ollama_controller"
      echo "  2. Deploy: cd ~/code/external_services/ollama_controller && make k8s-deploy"
      echo "  3. Configure: Use wizard → Infrastructure → External Services → Ollama Controller"
      echo ""
      echo -e "${BOLD}Configuration:${NC}"
      echo "  Use this wizard to configure services after installation:"
      echo "  • Option 1: Configure AI Backend"
      echo "  • Option 63 (Main Menu): Database Infrastructure Wizard"
      echo "  • Option 64 (Main Menu): RabbitMQ Management Wizard"
      echo "  • Infrastructure → External Services → Ollama Controller"
      echo ""
      echo -e "${BOLD}Full Documentation:${NC}"
      echo "  📚 Complete Setup Guide: docs/COMPLETE_SETUP_GUIDE.md"
      echo "  📋 Setup Checklist: docs/SETUP_CHECKLIST.md"
      echo "  🤖 MCP Setup: mcp/README.md"
      echo "  💻 LM Studio Setup: mcp/LM_STUDIO_SETUP.md"
      echo ""
      gtd_enter_to_continue
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
      
      # Show MCP server status and restart info
      echo -e "${BOLD}MCP Server Status:${NC}"
      echo ""
      echo "The MCP server runs inside Cursor and provides AI tools for your GTD system."
      echo ""
      echo -e "${YELLOW}To restart MCP server after code changes:${NC}"
      echo "  1. Restart Cursor (the MCP server will reload automatically)"
      echo "  2. Or use Cursor's MCP server reload (if available)"
      echo ""
      echo -e "${CYAN}Current MCP Server Config:${NC}"
      MCP_CONFIG="$HOME/.cursor/mcp_config.json"
      if [[ ! -f "$MCP_CONFIG" ]]; then
        MCP_CONFIG="$HOME/code/dotfiles/.cursor/mcp_config.json"
      fi
      if [[ -f "$MCP_CONFIG" ]]; then
        echo "  Config file: $MCP_CONFIG"
        if grep -q "GTD_RABBITMQ_URL" "$MCP_CONFIG" 2>/dev/null; then
          RABBITMQ_URL=$(grep "GTD_RABBITMQ_URL" "$MCP_CONFIG" | head -1 | sed 's/.*"GTD_RABBITMQ_URL": "\([^"]*\)".*/\1/')
          echo "  RabbitMQ URL: $RABBITMQ_URL"
        fi
      else
        echo "  ⚠️  MCP config not found"
      fi
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Setup Options:"
      echo ""
      echo "  1) 🔧 Run MCP Server Setup (create venv + install dependencies)"
      echo "  2) 📦 Install/Update Requirements (update dependencies only)"
      echo "  3) 📋 View MCP Server Configuration"
      echo "  4) 🔄 Restart Instructions (for code changes)"
      echo "  5) 🧪 Test MCP Tools (call MCP server functions directly)"
      echo ""
      echo -e "${YELLOW}0)${NC} Back"
      echo ""
      echo -n "Choose: "
      read mcp_setup_choice
      
      case "$mcp_setup_choice" in
        1)
          # Continue with setup
          ;;
        2)
          # Install/Update Requirements
          VENV_DIR="${MCP_DIR}/venv"
          VENV_PYTHON="${VENV_DIR}/bin/python3"
          REQUIREMENTS_FILE="${MCP_DIR}/requirements.txt"
          
          if [[ ! -d "$VENV_DIR" ]] || [[ ! -f "$VENV_PYTHON" ]]; then
            echo ""
            echo -e "${YELLOW}⚠️  Virtualenv not found${NC}"
            echo "   Virtualenv: $VENV_DIR"
            echo ""
            echo "Run option 1 first to create the virtualenv, or:"
            echo "   cd $MCP_DIR && ./setup.sh"
            echo ""
            gtd_quick_pause
            return 0
          fi
          
          if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
            echo ""
            echo -e "${RED}❌ Requirements file not found${NC}"
            echo "   Expected: $REQUIREMENTS_FILE"
            echo ""
            gtd_quick_pause
            return 0
          fi
          
          echo ""
          echo -e "${BOLD}📦 Installing/Updating Requirements${NC}"
          echo ""
          echo "Virtualenv: $VENV_DIR"
          echo "Requirements: $REQUIREMENTS_FILE"
          echo ""
          echo "This will install/update:"
          cat "$REQUIREMENTS_FILE" | grep -v "^#" | grep -v "^$" | sed 's/^/  - /'
          echo ""
          echo -n "Continue? (y/N): "
          read confirm
          
          if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Cancelled."
            echo ""
            gtd_quick_pause
            return 0
          fi
          
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          
          # Upgrade pip first
          echo "Upgrading pip..."
          "$VENV_PYTHON" -m pip install --upgrade pip --quiet
          
          # Install requirements
          echo "Installing requirements..."
          if "$VENV_PYTHON" -m pip install -r "$REQUIREMENTS_FILE"; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo -e "${GREEN}✅ Requirements installed/updated successfully!${NC}"
            echo ""
            
            # Verify key packages
            echo "Verifying key packages:"
            if "$VENV_PYTHON" -c "import mcp" 2>/dev/null; then
              echo "  ✅ mcp"
            else
              echo "  ❌ mcp (not installed)"
            fi
            
            if "$VENV_PYTHON" -c "import pika" 2>/dev/null; then
              echo "  ✅ pika (RabbitMQ)"
            else
              echo "  ⚠️  pika (optional - for RabbitMQ)"
            fi
            
            if "$VENV_PYTHON" -c "import psycopg2" 2>/dev/null; then
              echo "  ✅ psycopg2 (PostgreSQL)"
            else
              echo "  ⚠️  psycopg2 (optional - for vector database)"
            fi
            
            if "$VENV_PYTHON" -c "import watchdog" 2>/dev/null; then
              echo "  ✅ watchdog (filewatcher)"
            else
              echo "  ⚠️  watchdog (optional - for filewatcher)"
            fi
          else
            echo ""
            echo -e "${YELLOW}⚠️  Some packages may have failed to install${NC}"
            echo "   Check the output above for errors"
          fi
          
          echo ""
          gtd_quick_pause
          return 0
          ;;
        3)
          echo ""
          echo -e "${BOLD}MCP Server Configuration:${NC}"
          echo ""
          if [[ -f "$MCP_CONFIG" ]]; then
            echo "Config file: $MCP_CONFIG"
            echo ""
            cat "$MCP_CONFIG" | python3 -m json.tool 2>/dev/null || cat "$MCP_CONFIG"
          else
            echo "⚠️  MCP config not found at: $MCP_CONFIG"
            echo ""
            echo "Expected location:"
            echo "  ~/.cursor/mcp_config.json"
            echo "  or"
            echo "  ~/code/dotfiles/.cursor/mcp_config.json"
          fi
          echo ""
          gtd_quick_pause
          return 0
          ;;
        4)
          echo ""
          echo -e "${BOLD}🔄 Restarting MCP Server${NC}"
          echo ""
          echo "The MCP server runs inside Cursor. To restart it:"
          echo ""
          echo "  1. ${GREEN}Restart Cursor${NC} (recommended)"
          echo "     - Quit Cursor completely (Cmd+Q on macOS)"
          echo "     - Reopen Cursor"
          echo "     - The MCP server will reload with updated code"
          echo ""
          echo "  2. ${CYAN}Check MCP Status${NC}"
          echo "     - Look for MCP status indicator in Cursor"
          echo "     - Should show 'gtd-unified-system' as connected"
          echo ""
          echo "  3. ${YELLOW}Verify Connection${NC}"
          echo "     - Ask the AI: 'What MCP tools are available?'"
          echo "     - Should list GTD tools if connected"
          echo ""
          echo -e "${YELLOW}Note:${NC} After updating gtd_mcp_server.py code, you must restart"
          echo "Cursor for the changes to take effect."
          echo ""
          gtd_quick_pause
          return 0
          ;;
        5)
          clear
          echo ""
          echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          echo -e "${BOLD}${CYAN}🧪 Test MCP Tools${NC}"
          echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          echo ""
          echo "This allows you to call MCP server functions directly for testing."
          echo ""
          echo "Available tool categories:"
          echo ""
          echo "  📋 Task Management:"
          echo "    - list_tasks"
          echo "    - get_task_details"
          echo "    - create_task"
          echo "    - update_task"
          echo "    - complete_task"
          echo ""
          echo "  📁 Project Management:"
          echo "    - list_projects"
          echo "    - get_project_details"
          echo "    - create_project"
          echo ""
          echo "  💡 Task Suggestions:"
          echo "    - suggest_tasks_from_text"
          echo "    - get_pending_suggestions"
          echo ""
          echo "  📝 Daily Logs:"
          echo "    - read_daily_log"
          echo "    - read_recent_logs"
          echo ""
          echo "  🔍 Discovery:"
          echo "    - get_inbox_count"
          echo "    - get_context_tasks"
          echo "    - list_areas"
          echo ""
          echo "  🧠 Deep Analysis (queued):"
          echo "    - weekly_review"
          echo "    - analyze_energy"
          echo "    - find_connections"
          echo "    - generate_insights"
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo -n "Enter tool name to test (or 'list' to see all): "
          read tool_name
          
          if [[ -z "$tool_name" ]]; then
            echo "❌ No tool name provided"
            echo ""
            gtd_quick_pause
            return 0
          fi
          
          if [[ "$tool_name" == "list" ]]; then
            echo ""
            echo "📋 All Available MCP Tools:"
            echo ""
            MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
            if [[ ! -f "$MCP_SERVER" ]]; then
              MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
            fi
            
            if [[ -f "$MCP_SERVER" ]]; then
              MCP_PYTHON=$(gtd_get_mcp_python)
              if [[ -z "$MCP_PYTHON" ]]; then
                MCP_PYTHON="python3"
              fi
              
              "$MCP_PYTHON" -c "
import sys
from pathlib import Path
sys.path.insert(0, '$(dirname "$MCP_SERVER")')
from gtd_mcp_server import handle_list_tools
import asyncio

tools = asyncio.run(handle_list_tools())
for tool in tools:
    print(f'  • {tool.name}')
    if hasattr(tool, 'description') and tool.description:
        desc = tool.description[:60]
        if len(tool.description) > 60:
            desc += '...'
        print(f'    {desc}')
    print()
" 2>/dev/null || echo "⚠️  Could not list tools. Make sure MCP server is set up."
            else
              echo "❌ MCP server not found"
            fi
            echo ""
            gtd_quick_pause
            return 0
          fi
          
          echo ""
          echo -n "Enter tool arguments as JSON (or press Enter for no args): "
          read tool_args
          
          if [[ -z "$tool_args" ]]; then
            tool_args="{}"
          fi
          
          echo ""
          echo "Calling MCP tool: $tool_name"
          echo "Arguments: $tool_args"
          echo ""
          
          MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
          if [[ ! -f "$MCP_SERVER" ]]; then
            MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
          fi
          
          if [[ ! -f "$MCP_SERVER" ]]; then
            echo -e "${RED}❌ MCP server not found${NC}"
            echo "Expected at: $HOME/code/dotfiles/mcp/gtd_mcp_server.py"
            echo ""
            gtd_quick_pause
            return 0
          fi
          
          MCP_PYTHON=$(gtd_get_mcp_python)
          if [[ -z "$MCP_PYTHON" ]]; then
            MCP_PYTHON="python3"
          fi
          
          result=$("$MCP_PYTHON" -c "
import sys
import json
import asyncio
from pathlib import Path

sys.path.insert(0, '$(dirname "$MCP_SERVER")')

try:
    from gtd_mcp_server import handle_call_tool
    
    # Parse arguments
    try:
        args = json.loads('$tool_args')
    except:
        args = {}
    
    # Call the tool
    result = asyncio.run(handle_call_tool('$tool_name', args))
    
    # Extract and display text content
    if result and len(result) > 0:
        for content in result:
            if hasattr(content, 'text'):
                print(content.text)
            else:
                print(str(content))
    else:
        print(json.dumps({'error': 'No response from tool'}))
        
except Exception as e:
    print(json.dumps({'error': f'Error calling tool: {str(e)}'}))
    import traceback
    traceback.print_exc()
" 2>&1)
          
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Result:"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          
          # Try to format JSON nicely if it's JSON
          if echo "$result" | "$MCP_PYTHON" -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
            echo "$result" | "$MCP_PYTHON" -m json.tool 2>/dev/null || echo "$result"
          else
            echo "$result"
          fi
          
          echo ""
          gtd_quick_pause
          return 0
          ;;
        0)
          return 0
          ;;
        *)
          echo "Invalid choice"
          echo ""
          gtd_quick_pause
          return 0
          ;;
      esac
      
      if [[ "$mcp_setup_choice" != "1" ]]; then
        return 0
      fi
      
      if [[ ! -f "$SETUP_SCRIPT" ]]; then
        echo -e "${RED}❌ MCP setup script not found${NC}"
        echo ""
        echo "Expected at: $SETUP_SCRIPT"
        echo ""
        echo "Make sure the MCP directory exists and contains setup.sh"
        echo ""
        gtd_quick_pause
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
          gtd_quick_pause
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
        gtd_quick_pause
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
        echo "  2. Restart Cursor to load MCP server with updated code"
        echo "  3. Start LM Studio or Ollama"
        echo "  4. (Optional) Set up Vector Filewatcher for auto-vectorization"
        echo "  5. Test with: Generate banter for log entry (option 4 in AI Suggestions menu)"
        echo ""
        echo -e "${YELLOW}Note:${NC} After code changes to gtd_mcp_server.py, restart Cursor to pick up changes."
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
    8)
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
    9)
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
        gtd_quick_pause
        return 0
      fi
      
      local selected_index=$((edit_choice - 1))
      local selected_file="${file_paths[$selected_index]}"
      local file_name=$(basename "$selected_file")
      
      # Check if vim is available
      if ! command -v vim &>/dev/null; then
        echo "❌ vim not found. Please install vim to edit configuration files."
        echo ""
        gtd_quick_pause
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
      gtd_quick_pause
      
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
    10)
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
              gtd_quick_pause
              return 0
            fi
            
            # Check if RabbitMQ service exists
            if ! kubectl get svc -n rabbitmq-system rabbitmq &> /dev/null; then
              echo -e "${YELLOW}⚠️  RabbitMQ service not found in rabbitmq-system namespace${NC}"
              echo ""
              echo "Available RabbitMQ services:"
              kubectl get svc -A | grep rabbitmq || echo "  None found"
              echo ""
              gtd_quick_pause
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
            echo ""
            gtd_quick_pause
            continue
          fi
          
          # After showing status, offer to view logs
          echo ""
          echo "View Worker Logs:"
          echo "  1) 📋 View Deep Analysis Worker Logs"
          echo "  2) 📋 View Vectorization Worker Logs"
          echo "  3) 📋 View Both Worker Logs"
          echo "  0) Back"
          echo ""
          echo -n "Choose: "
          read log_choice
          
          case "$log_choice" in
            1)
              echo ""
              echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo -e "${BOLD}Deep Analysis Worker Logs${NC}"
              echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo ""
              DEEP_LOG="/tmp/deep-worker.log"
              if [[ -f "$DEEP_LOG" ]]; then
                LOG_SIZE=$(wc -l < "$DEEP_LOG" 2>/dev/null || echo "0")
                if [[ "$LOG_SIZE" -gt 0 ]]; then
                  echo "Showing last 50 lines (${LOG_SIZE} total lines):"
                  echo ""
                  tail -50 "$DEEP_LOG"
                  echo ""
                  echo "Options:"
                  echo "  1) View more (last 100 lines)"
                  echo "  2) Follow logs (tail -f)"
                  echo "  0) Back"
                  echo ""
                  echo -n "Choose: "
                  read more_choice
                  case "$more_choice" in
                    1)
                      echo ""
                      tail -100 "$DEEP_LOG"
                      ;;
                    2)
                      echo ""
                      echo "Following logs (Ctrl+C to stop)..."
                      tail -f "$DEEP_LOG"
                      ;;
                  esac
                else
                  echo -e "${YELLOW}⚠️  Log file is empty${NC}"
                  echo "The worker may have just started or logs are being written elsewhere."
                fi
              else
                echo -e "${YELLOW}⚠️  Log file not found: $DEEP_LOG${NC}"
                echo "The worker may not be running or logs are in a different location."
                echo ""
                echo "Check if worker is running:"
                if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
                  pid=$(pgrep -f "gtd_deep_analysis_worker.py")
                  echo "  ✅ Worker running (PID: $pid)"
                  echo "  Logs should be at: $DEEP_LOG"
                else
                  echo "  ❌ Worker not running"
                  echo "  Start with: make worker-deep-start"
                fi
              fi
              ;;
            2)
              echo ""
              echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo -e "${BOLD}Vectorization Worker Logs${NC}"
              echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo ""
              VECTOR_LOG="/tmp/vector-worker.log"
              if [[ -f "$VECTOR_LOG" ]]; then
                LOG_SIZE=$(wc -l < "$VECTOR_LOG" 2>/dev/null || echo "0")
                if [[ "$LOG_SIZE" -gt 0 ]]; then
                  echo "Showing last 50 lines (${LOG_SIZE} total lines):"
                  echo ""
                  tail -50 "$VECTOR_LOG"
                  echo ""
                  echo "Options:"
                  echo "  1) View more (last 100 lines)"
                  echo "  2) Follow logs (tail -f)"
                  echo "  0) Back"
                  echo ""
                  echo -n "Choose: "
                  read more_choice
                  case "$more_choice" in
                    1)
                      echo ""
                      tail -100 "$VECTOR_LOG"
                      ;;
                    2)
                      echo ""
                      echo "Following logs (Ctrl+C to stop)..."
                      tail -f "$VECTOR_LOG"
                      ;;
                  esac
                else
                  echo -e "${YELLOW}⚠️  Log file is empty${NC}"
                  echo "The worker may have just started or logs are being written elsewhere."
                fi
              else
                echo -e "${YELLOW}⚠️  Log file not found: $VECTOR_LOG${NC}"
                echo "The worker may not be running or logs are in a different location."
                echo ""
                echo "Check if worker is running:"
                if pgrep -f "gtd_vector_worker.py" >/dev/null; then
                  pid=$(pgrep -f "gtd_vector_worker.py")
                  echo "  ✅ Worker running (PID: $pid)"
                  echo "  Logs should be at: $VECTOR_LOG"
                else
                  echo "  ❌ Worker not running"
                  echo "  Start with: make worker-vector-start"
                fi
              fi
              ;;
            3)
              echo ""
              echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo -e "${BOLD}Both Worker Logs${NC}"
              echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo ""
              DEEP_LOG="/tmp/deep-worker.log"
              VECTOR_LOG="/tmp/vector-worker.log"
              
              if [[ -f "$DEEP_LOG" ]]; then
                echo -e "${BOLD}Deep Analysis Worker:${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                tail -30 "$DEEP_LOG"
                echo ""
              else
                echo -e "${YELLOW}⚠️  Deep Analysis log not found: $DEEP_LOG${NC}"
                echo ""
              fi
              
              if [[ -f "$VECTOR_LOG" ]]; then
                echo -e "${BOLD}Vectorization Worker:${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                tail -30 "$VECTOR_LOG"
                echo ""
              else
                echo -e "${YELLOW}⚠️  Vectorization log not found: $VECTOR_LOG${NC}"
                echo ""
              fi
              ;;
            0|"")
              ;;
            *)
              echo "Invalid choice"
              ;;
          esac
          
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
          ;;
    11)
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
      echo "  7) 🔄 Restart Filewatcher (to pick up config changes)"
      echo "  8) 📊 Check Filewatcher Status"
      echo "  9) 📦 Install Required Dependencies (watchdog)"
      echo " 10) 🔍 Scan Existing Files (queue all files for vectorization)"
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
              gtd_quick_pause
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
              gtd_quick_pause
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
              gtd_quick_pause
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
                gtd_quick_pause
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
              gtd_quick_pause
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
                    gtd_quick_pause
                    continue
                  fi
                else
                  echo ""
                  gtd_quick_pause
                  continue
                fi
              fi
              
              cd "$HOME/code/dotfiles" && make filewatcher-start
              echo ""
              gtd_quick_pause
              ;;
            6)
              echo ""
              echo -e "${CYAN}Stopping Vector Filewatcher...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make filewatcher-stop
              echo ""
              gtd_quick_pause
              ;;
            7)
              echo ""
              echo -e "${CYAN}Restarting Vector Filewatcher...${NC}"
              echo ""
              echo "This will stop and restart the filewatcher to pick up any configuration changes."
              echo ""
              cd "$HOME/code/dotfiles" && make filewatcher-stop
              sleep 2
              cd "$HOME/code/dotfiles" && make filewatcher-start
              echo ""
              echo -e "${GREEN}✅ Filewatcher restarted${NC}"
              echo ""
              gtd_quick_pause
              ;;
            8)
              echo ""
              cd "$HOME/code/dotfiles" && make filewatcher-status
              echo ""
              gtd_quick_pause
              ;;
            9)
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
              gtd_quick_pause
              ;;
            10)
              echo ""
              echo -e "${BOLD}Scan Existing Files${NC}"
              echo ""
              echo "This will scan all existing files in your configured directories"
              echo "and queue them for vectorization. Useful for:"
              echo "  • Initial setup"
              echo "  • Repopulating the queue after it's been cleared"
              echo "  • Re-queuing files that may have been missed"
              echo ""
              echo -n "Continue? (y/n): "
              read confirm_scan
              if [[ "$confirm_scan" == "y" || "$confirm_scan" == "Y" ]]; then
                echo ""
                echo "Scanning and queueing files..."
                echo ""
                cd "$HOME/code/dotfiles" && make filewatcher-scan
                echo ""
                gtd_quick_pause
              else
                echo "Cancelled."
                sleep 1
              fi
              ;;
            0)
              ;;
            *)
              echo "Invalid choice"
              ;;
      esac
      ;;
    12)
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
              gtd_quick_pause
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
              gtd_quick_pause
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
              gtd_quick_pause
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
              gtd_quick_pause
              ;;
            5)
              echo ""
              echo -e "${CYAN}Starting Scheduler Daemon...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-start
              echo ""
              gtd_quick_pause
              ;;
            6)
              echo ""
              echo -e "${CYAN}Stopping Scheduler Daemon...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-stop
              echo ""
              gtd_quick_pause
              ;;
            7)
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-status
              echo ""
              gtd_quick_pause
              ;;
            8)
              echo ""
              echo -e "${CYAN}Running scheduler (one-time check)...${NC}"
              echo ""
              cd "$HOME/code/dotfiles" && make scheduler-run
              echo ""
              gtd_quick_pause
              ;;
            0)
              ;;
            *)
              echo "Invalid choice"
              ;;
          esac
      ;;
    13)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🚀 Deploy External Services${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Deploy external services (RabbitMQ, PostgreSQL) to Kubernetes."
      echo ""
      echo "Options:"
      echo ""
      echo "  1) 🐰 Deploy RabbitMQ"
      echo "  2) 🗄️  Deploy PostgreSQL Database"
      echo "  3) 🚀 Deploy All Services"
      echo "  4) 📊 Check Service Status"
      echo ""
      echo -e "${YELLOW}0)${NC} Back"
      echo ""
      echo -n "Choose: "
      read deploy_choice
      
      case "$deploy_choice" in
        1)
          echo ""
          echo -e "${CYAN}Deploying RabbitMQ to Kubernetes...${NC}"
          echo ""
          cd "$HOME/code/dotfiles" && make services-deploy-rabbitmq
          echo ""
          echo "✓ RabbitMQ deployment initiated"
          echo ""
          echo "💡 After deployment, set up port-forward:"
          echo "   Use: gtd-wizard → Configuration → Setup RabbitMQ → Start Port-Forward"
          echo ""
          gtd_quick_pause
          ;;
        2)
          echo ""
          echo -e "${CYAN}Deploying PostgreSQL Database to Kubernetes...${NC}"
          echo ""
          cd "$HOME/code/dotfiles" && make services-deploy-database
          echo ""
          echo "✓ PostgreSQL deployment initiated"
          echo ""
          echo "💡 After deployment, set up port-forward:"
          echo "   setup-port-forward 13003"
          echo ""
          gtd_quick_pause
          ;;
        3)
          echo ""
          echo -e "${CYAN}Deploying all external services...${NC}"
          echo ""
          cd "$HOME/code/dotfiles" && make services-deploy-all
          echo ""
          echo "✓ All services deployment initiated"
          echo ""
          gtd_quick_pause
          ;;
        4)
          echo ""
          echo -e "${CYAN}Checking service status...${NC}"
          echo ""
          echo "RabbitMQ:"
          kubectl get pods -n rabbitmq-system 2>/dev/null || echo "  (Not found or not accessible)"
          echo ""
          echo "PostgreSQL:"
          kubectl get pods -A | grep -i postgres || echo "  (Not found)"
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
      ;;
    14)
      # Manage Background Workers
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}👷 Manage Background Workers${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check if manage_worker function exists (from gtd-wizard-analysis.sh)
      if type manage_worker &>/dev/null 2>&1; then
        # Show worker status first
        echo -e "${BOLD}Current Worker Status:${NC}"
        echo ""
        
        # Deep Analysis Worker
        echo -e "${CYAN}Deep Analysis Worker:${NC}"
        if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
          pid=$(pgrep -f "gtd_deep_analysis_worker.py")
          echo -e "  ${GREEN}✅ Running (PID: $pid)${NC}"
        else
          echo -e "  ${CYAN}ℹ️  Not running${NC}"
        fi
        echo ""
        
        # Vectorization Worker
        echo -e "${CYAN}Vectorization Worker:${NC}"
        if pgrep -f "gtd_vector_worker.py" >/dev/null; then
          pid=$(pgrep -f "gtd_vector_worker.py")
          echo -e "  ${GREEN}✅ Running (PID: $pid)${NC}"
        else
          echo -e "  ${CYAN}ℹ️  Not running${NC}"
        fi
        echo ""
        
        # Check RabbitMQ connection (NodePort or port-forward)
        echo -e "${BOLD}RabbitMQ Connection:${NC}"
        RABBITMQ_AVAILABLE=false
        if nc -zv 192.168.64.2 30672 &>/dev/null 2>&1; then
          echo -e "  ${GREEN}✅ NodePort accessible (192.168.64.2:30672)${NC}"
          RABBITMQ_AVAILABLE=true
        elif nc -zv localhost 5672 &>/dev/null 2>&1; then
          echo -e "  ${GREEN}✅ Port-forward active (localhost:5672)${NC}"
          RABBITMQ_AVAILABLE=true
        else
          echo -e "  ${YELLOW}⚠️  RabbitMQ not accessible${NC}"
          echo "  Check: cd ~/code/external_services/rabbitmq && make connection-info"
          echo "  Note: NodePort (192.168.64.2:30672) is preferred, no port-forward needed"
        fi
        echo ""
        
        echo "What would you like to do?"
        echo "  1) Manage Deep Analysis Worker"
        echo "  2) Manage Vectorization Worker"
        echo "  3) Start All Workers"
        echo "  4) Stop All Workers"
        echo "  5) Restart All Workers (Reconnect to RabbitMQ)"
        echo "  6) View RabbitMQ Queue Status"
        echo "  7) 📦 Migrate File Queue to RabbitMQ"
        echo ""
        echo -e "${YELLOW}0)${NC} Back"
        echo ""
        echo -n "Choose: "
        read worker_action
        
        case "$worker_action" in
          1)
            manage_worker "gtd_deep_analysis_worker.py" "Deep Analysis"
            ;;
          2)
            manage_worker "gtd_vector_worker.py" "Vectorization"
            ;;
          3)
            echo ""
            echo "Starting all workers..."
            make -C "$HOME/code/dotfiles" worker-deep-start 2>/dev/null || true
            make -C "$HOME/code/dotfiles" worker-vector-start 2>/dev/null || true
            echo ""
            gtd_quick_pause
            ;;
          4)
            echo ""
            echo "Stopping all workers..."
            make -C "$HOME/code/dotfiles" worker-deep-stop 2>/dev/null || true
            make -C "$HOME/code/dotfiles" worker-vector-stop 2>/dev/null || true
            echo ""
            gtd_quick_pause
            ;;
          5)
            echo ""
            echo "Restarting all workers..."
            make -C "$HOME/code/dotfiles" worker-deep-stop 2>/dev/null || true
            make -C "$HOME/code/dotfiles" worker-vector-stop 2>/dev/null || true
            sleep 2
            make -C "$HOME/code/dotfiles" worker-deep-start 2>/dev/null || true
            make -C "$HOME/code/dotfiles" worker-vector-start 2>/dev/null || true
            echo ""
            echo "✓ Workers restarted"
            echo ""
            gtd_quick_pause
            ;;
          6)
            echo ""
            if [[ -f "$HOME/code/dotfiles/bin/gtd-rabbitmq-status" ]]; then
              "$HOME/code/dotfiles/bin/gtd-rabbitmq-status"
            else
              echo "❌ RabbitMQ status script not found"
            fi
            echo ""
            gtd_quick_pause
            ;;
          7)
            # Migrate file queue to RabbitMQ
            echo ""
            if [[ -f "$HOME/code/dotfiles/bin/migrate-file-queue-to-rabbitmq" ]]; then
              "$HOME/code/dotfiles/bin/migrate-file-queue-to-rabbitmq"
            elif [[ -f "$HOME/code/personal/dotfiles/bin/migrate-file-queue-to-rabbitmq" ]]; then
              "$HOME/code/personal/dotfiles/bin/migrate-file-queue-to-rabbitmq"
            else
              echo -e "${RED}❌ Migration script not found${NC}"
            fi
            echo ""
            gtd_quick_pause
            ;;
          0|"")
            return 0
            ;;
          *)
            echo "Invalid choice"
            echo ""
            gtd_quick_pause
            ;;
        esac
      else
        echo "⚠️  Worker management functions not available"
        echo "  Use: Main Menu → 17) System Status → 3) Background Worker Status"
        echo ""
        gtd_quick_pause
      fi
      ;;
    15)
      # Switch Kubernetes Context
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}☸️  Switch Kubernetes Context${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check if kubectl is installed
      if ! command -v kubectl &>/dev/null; then
        echo -e "${RED}❌ kubectl not found${NC}"
        echo ""
        echo "kubectl is required to switch contexts."
        echo "Install kubectl:"
        echo "  macOS: brew install kubernetes-cli"
        echo "  Linux: See https://kubernetes.io/docs/tasks/tools/"
        echo ""
        gtd_enter_to_continue
        return 0
      fi
      
      # Get current context
      local current_context=$(kubectl config current-context 2>/dev/null || echo "none")
      echo -e "${BOLD}Current Context:${NC} ${CYAN}${current_context}${NC}"
      echo ""
      
      # Get available contexts
      echo -e "${BOLD}Available Contexts:${NC}"
      local contexts=$(kubectl config get-contexts -o name 2>/dev/null | sort)
      if [[ -z "$contexts" ]]; then
        echo -e "${YELLOW}⚠️  No contexts found${NC}"
        echo ""
        echo "You may need to:"
        echo "  1. Start Docker Desktop or Rancher Desktop"
        echo "  2. Ensure Kubernetes is enabled in your desktop environment"
        echo ""
        gtd_enter_to_continue
        return 0
      fi
      
      # Display contexts with indicators
      local context_num=1
      declare -a context_list
      while IFS= read -r context; do
        context_list+=("$context")
        if [[ "$context" == "$current_context" ]]; then
          echo -e "  ${GREEN}${context_num})${NC} ${BOLD}${context}${NC} ${GREEN}(current)${NC}"
        else
          echo -e "  ${context_num}) ${context}"
        fi
        ((context_num++))
      done <<< "$contexts"
      echo ""
      echo -e "${YELLOW}0)${NC} Back"
      echo ""
      echo -n "Choose context to switch to: "
      read context_choice
      
      if [[ -z "$context_choice" || "$context_choice" == "0" ]]; then
        return 0
      fi
      
      # Validate choice
      if ! [[ "$context_choice" =~ ^[0-9]+$ ]] || [[ $context_choice -lt 1 ]] || [[ $context_choice -gt ${#context_list[@]} ]]; then
        echo -e "${RED}❌ Invalid choice${NC}"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      local selected_index=$((context_choice - 1))
      local selected_context="${context_list[$selected_index]}"
      
      # Check if already on this context
      if [[ "$selected_context" == "$current_context" ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  Already using context: ${selected_context}${NC}"
        echo ""
        gtd_quick_pause
        return 0
      fi
      
      # Switch context
      echo ""
      echo -n "Switching to context: ${selected_context}... "
      if kubectl config use-context "$selected_context" &>/dev/null; then
        echo -e "${GREEN}✅${NC}"
        echo ""
        
        # Verify the switch
        local new_context=$(kubectl config current-context 2>/dev/null)
        if [[ "$new_context" == "$selected_context" ]]; then
          echo -e "${GREEN}✓ Successfully switched to: ${new_context}${NC}"
          echo ""
          
          # Test connection
          echo -n "Testing cluster connection... "
          if kubectl cluster-info &>/dev/null 2>&1; then
            echo -e "${GREEN}✅ Connected${NC}"
          else
            echo -e "${YELLOW}⚠️  Cannot connect to cluster${NC}"
            echo ""
            echo "The context was switched, but the cluster may not be running."
            echo "Make sure Docker Desktop or Rancher Desktop is running and Kubernetes is enabled."
          fi
        else
          echo -e "${YELLOW}⚠️  Context switch may have failed${NC}"
          echo "Expected: $selected_context"
          echo "Current: $new_context"
        fi
      else
        echo -e "${RED}❌ Failed${NC}"
        echo ""
        echo "Could not switch to context: $selected_context"
        echo "Make sure the context exists and is accessible."
      fi
      
      echo ""
      gtd_enter_to_continue
      ;;
    16)
      guided_setup_wizard
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

# Guided setup wizard - walks through complete setup process
guided_setup_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🚀 Complete Guided Setup${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "This wizard will guide you through the complete setup process:"
  echo "  1. Download external service repositories"
  echo "  2. Setup PostgreSQL database"
  echo "  3. Setup RabbitMQ message queue"
  echo "  4. Setup Ollama Controller (AI request throttling)"
  echo "  5. Configure AI host (LM Studio or Ollama)"
  echo "  6. Configure GTD system to use these services"
  echo "  7. Setup MCP server"
  echo ""
  echo -e "${YELLOW}⚠️  This will take 15-20 minutes.${NC}"
  echo ""
  echo -n "Continue with guided setup? (y/N): "
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Setup cancelled."
    echo ""
    gtd_quick_pause
    return 0
  fi
  
  local step=1
  local total_steps=7
  
  # Step 1: Download External Service Repositories
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Download External Service Repositories${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "We'll download three repositories:"
  echo "  • Database: git@github.com:the-great-abby/postgres_databases.git"
  echo "  • RabbitMQ: git@github.com:the-great-abby/message_queue.git"
  echo "  • Ollama Controller: git@github.com:the-great-abby/llm_proxy.git"
  echo ""
  echo -n "Ready to download? (y/N): "
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    mkdir -p ~/code/external_services
    cd ~/code/external_services
    
    # Download database repo
    if [[ ! -d "database" ]]; then
      echo ""
      echo "Downloading database repository..."
      if git clone git@github.com:the-great-abby/postgres_databases.git database 2>&1; then
        echo -e "${GREEN}✓ Database repository downloaded${NC}"
      else
        echo -e "${RED}❌ Failed to download database repository${NC}"
        echo "You can manually clone it later:"
        echo "  git clone git@github.com:the-great-abby/postgres_databases.git ~/code/external_services/database"
      fi
    else
      echo -e "${GREEN}✓ Database repository already exists${NC}"
    fi
    
    # Download rabbitmq repo
    if [[ ! -d "rabbitmq" ]]; then
      echo ""
      echo "Downloading RabbitMQ repository..."
      if git clone git@github.com:the-great-abby/message_queue.git rabbitmq 2>&1; then
        echo -e "${GREEN}✓ RabbitMQ repository downloaded${NC}"
      else
        echo -e "${RED}❌ Failed to download RabbitMQ repository${NC}"
        echo "You can manually clone it later:"
        echo "  git clone git@github.com:the-great-abby/message_queue.git ~/code/external_services/rabbitmq"
      fi
    else
      echo -e "${GREEN}✓ RabbitMQ repository already exists${NC}"
    fi
    
    # Download ollama controller repo
    if [[ ! -d "ollama_controller" ]]; then
      echo ""
      echo "Downloading Ollama Controller repository..."
      if git clone git@github.com:the-great-abby/llm_proxy.git ollama_controller 2>&1; then
        echo -e "${GREEN}✓ Ollama Controller repository downloaded${NC}"
      else
        echo -e "${RED}❌ Failed to download Ollama Controller repository${NC}"
        echo "You can manually clone it later:"
        echo "  git clone git@github.com:the-great-abby/llm_proxy.git ~/code/external_services/ollama_controller"
      fi
    else
      echo -e "${GREEN}✓ Ollama Controller repository already exists${NC}"
    fi
  else
    echo "Skipping repository download. You can do this manually:"
    echo "  mkdir -p ~/code/external_services"
    echo "  cd ~/code/external_services"
    echo "  git clone git@github.com:the-great-abby/postgres_databases.git database"
    echo "  git clone git@github.com:the-great-abby/message_queue.git rabbitmq"
    echo "  git clone git@github.com:the-great-abby/llm_proxy.git ollama_controller"
  fi
  echo ""
  gtd_enter_to_continue
  ((step++))
  
  # Step 2: Setup PostgreSQL Database
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Setup PostgreSQL Database${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "We'll deploy PostgreSQL to your Kubernetes cluster."
  echo ""
  echo -e "${YELLOW}Prerequisites:${NC}"
  echo "  • Kubernetes cluster running and accessible via kubectl"
  echo "  • kubectl configured correctly"
  echo ""
  echo -n "Ready to setup database? (y/N): "
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    if [[ -d ~/code/external_services/database ]]; then
      cd ~/code/external_services/database
      echo ""
      echo "Deploying PostgreSQL..."
      if make setup 2>&1; then
        echo ""
        echo -e "${GREEN}✓ PostgreSQL deployment initiated${NC}"
        echo ""
        echo "Waiting for database to be ready (this may take 30-60 seconds)..."
        if kubectl wait --for=condition=ready pod -l app=postgres -n postgres-system --timeout=120s 2>/dev/null; then
          echo -e "${GREEN}✓ Database is ready!${NC}"
          echo ""
          echo "Connection information:"
          make connection-info
        else
          echo -e "${YELLOW}⚠️  Database is still starting up${NC}"
          echo "You can check status with: cd ~/code/external_services/database && make status"
        fi
      else
        echo -e "${RED}❌ Failed to deploy database${NC}"
        echo "You can try manually: cd ~/code/external_services/database && make setup"
      fi
    else
      echo -e "${RED}❌ Database repository not found${NC}"
      echo "Please complete step 1 first, or manually clone the repository."
    fi
  else
    echo "Skipping database setup. You can do this manually:"
    echo "  cd ~/code/external_services/database && make setup"
  fi
  echo ""
  gtd_enter_to_continue
  ((step++))
  
  # Step 3: Setup RabbitMQ
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Setup RabbitMQ Message Queue${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "We'll deploy RabbitMQ to your Kubernetes cluster."
  echo ""
  echo -n "Ready to setup RabbitMQ? (y/N): "
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    if [[ -d ~/code/external_services/rabbitmq ]]; then
      cd ~/code/external_services/rabbitmq
      echo ""
      echo "Deploying RabbitMQ..."
      if make setup 2>&1; then
        echo ""
        echo -e "${GREEN}✓ RabbitMQ deployment initiated${NC}"
        echo ""
        echo "Waiting for RabbitMQ to be ready (this may take 30-60 seconds)..."
        if kubectl wait --for=condition=ready pod -l app=rabbitmq -n rabbitmq-system --timeout=120s 2>/dev/null; then
          echo -e "${GREEN}✓ RabbitMQ is ready!${NC}"
          echo ""
          echo "Connection information:"
          make connection-info
        else
          echo -e "${YELLOW}⚠️  RabbitMQ is still starting up${NC}"
          echo "You can check status with: cd ~/code/external_services/rabbitmq && make status"
        fi
      else
        echo -e "${RED}❌ Failed to deploy RabbitMQ${NC}"
        echo "You can try manually: cd ~/code/external_services/rabbitmq && make setup"
      fi
    else
      echo -e "${RED}❌ RabbitMQ repository not found${NC}"
      echo "Please complete step 1 first, or manually clone the repository."
    fi
  else
    echo "Skipping RabbitMQ setup. You can do this manually:"
    echo "  cd ~/code/external_services/rabbitmq && make setup"
  fi
  echo ""
  gtd_enter_to_continue
  ((step++))
  
  # Step 4: Setup Ollama Controller
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Setup Ollama Controller${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "The Ollama Controller provides request throttling and queuing for AI requests."
  echo "This helps manage load and ensures reliable AI responses."
  echo ""
  echo -e "${YELLOW}Prerequisites:${NC}"
  echo "  • Kubernetes cluster running and accessible via kubectl"
  echo "  • kubectl configured correctly"
  echo "  • PostgreSQL database already set up (from step 2)"
  echo ""
  echo -n "Ready to setup Ollama Controller? (y/N): "
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    if [[ -d ~/code/external_services/ollama_controller ]]; then
      cd ~/code/external_services/ollama_controller
      echo ""
      echo "Deploying Ollama Controller..."
      if make k8s-deploy 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Ollama Controller deployment initiated${NC}"
        echo ""
        echo "Waiting for Ollama Controller to be ready (this may take 30-60 seconds)..."
        if kubectl wait --for=condition=ready pod -l app=ollama-controller-api -n ollama-controller --timeout=120s 2>/dev/null; then
          echo -e "${GREEN}✓ Ollama Controller is ready!${NC}"
          echo ""
          echo "Connection information:"
          make connection-info 2>/dev/null || echo "  Run 'make connection-info' for details"
        else
          echo -e "${YELLOW}⚠️  Ollama Controller is still starting up${NC}"
          echo "You can check status with: cd ~/code/external_services/ollama_controller && kubectl get pods -n ollama-controller"
        fi
      else
        echo -e "${RED}❌ Failed to deploy Ollama Controller${NC}"
        echo "You can try manually: cd ~/code/external_services/ollama_controller && make k8s-deploy"
      fi
    else
      echo -e "${RED}❌ Ollama Controller repository not found${NC}"
      echo "Please complete step 1 first, or manually clone the repository."
    fi
  else
    echo "Skipping Ollama Controller setup. You can do this manually:"
    echo "  cd ~/code/external_services/ollama_controller && make k8s-deploy"
  fi
  echo ""
  gtd_enter_to_continue
  ((step++))
  
  # Step 5: Configure AI Host
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Configure AI Host${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Choose your AI backend:"
  echo ""
  echo "  1) LM Studio (Desktop app, recommended for macOS/Windows)"
  echo "  2) Ollama (Command-line, recommended for Linux)"
  echo "  3) Skip (configure later)"
  echo ""
  echo -n "Choose: "
  read ai_choice
  
  case "$ai_choice" in
    1)
      echo ""
      echo -e "${BOLD}LM Studio Setup:${NC}"
      echo ""
      echo "1. Download LM Studio from: https://lmstudio.ai/"
      echo "2. Install and open LM Studio"
      echo "3. Download a model (Search tab → Download)"
      echo "   Recommended: qwen/qwen3-1.7b or google/gemma-3-1b"
      echo "4. Load the model (Chat tab → Select model → Load)"
      echo "5. Start local server (Server tab → Start Server)"
      echo "   Default port: 1234"
      echo ""
      echo -n "Have you completed the LM Studio setup? (y/N): "
      read done
      if [[ "$done" == "y" || "$done" == "Y" ]]; then
        echo ""
        echo "Configuring LM Studio..."
        echo "Please enter the exact model name as shown in LM Studio:"
        echo -n "Model name: "
        read model_name
        if [[ -n "$model_name" ]]; then
          # Use the existing AI backend configuration
          echo ""
          echo "Opening AI Backend configuration..."
          # We'll let the user configure it via the existing wizard
          echo "Please use: Configuration & Setup → Configure AI Backend"
          echo "Or edit: ~/code/dotfiles/zsh/.gtd_config"
          echo "  Set: AI_BACKEND=\"lmstudio\""
          echo "  Set: LM_STUDIO_CHAT_MODEL=\"$model_name\""
        fi
      else
        echo "You can configure LM Studio later via: Configuration & Setup → Configure AI Backend"
      fi
      ;;
    2)
      echo ""
      echo -e "${BOLD}Ollama Setup:${NC}"
      echo ""
      echo "1. Install Ollama:"
      echo "   macOS: brew install ollama"
      echo "   Linux: curl -fsSL https://ollama.com/install.sh | sh"
      echo "2. Start server: ollama serve"
      echo "3. Pull a model: ollama pull qwen2.5:1.5b"
      echo "4. List models: ollama list"
      echo ""
      echo -n "Have you completed the Ollama setup? (y/N): "
      read done
      if [[ "$done" == "y" || "$done" == "Y" ]]; then
        echo ""
        echo "Configuring Ollama..."
        echo "Please enter the model name (from 'ollama list'):"
        echo -n "Model name: "
        read model_name
        if [[ -n "$model_name" ]]; then
          echo ""
          echo "Opening AI Backend configuration..."
          echo "Please use: Configuration & Setup → Configure AI Backend"
          echo "Or edit: ~/code/dotfiles/zsh/.gtd_config"
          echo "  Set: AI_BACKEND=\"ollama\""
          echo "  Set: OLLAMA_CHAT_MODEL=\"$model_name\""
        fi
      else
        echo "You can configure Ollama later via: Configuration & Setup → Configure AI Backend"
      fi
      ;;
    3)
      echo "Skipping AI host configuration. You can configure it later."
      ;;
    *)
      echo "Invalid choice. Skipping AI host configuration."
      ;;
  esac
  echo ""
  gtd_enter_to_continue
  ((step++))
  
  # Step 6: Configure GTD System
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Configure GTD System${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Now we'll configure the GTD system to use the services we just set up."
  echo ""
  echo "You'll need connection information from the previous steps."
  echo ""
  echo -n "Ready to configure? (y/N): "
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo ""
    echo "Please configure services via the wizard:"
    echo ""
    echo -e "${BOLD}1. Database Configuration:${NC}"
    echo "   Main Menu → 63) Database Infrastructure Wizard → Setup Database Connection"
    echo ""
    echo -e "${BOLD}2. RabbitMQ Configuration:${NC}"
    echo "   Main Menu → 64) RabbitMQ Management Wizard → Setup RabbitMQ Connection"
    echo ""
    echo "   Or: Configuration & Setup → Setup RabbitMQ Connection"
    echo ""
    echo "Get connection info:"
    echo "  Database: cd ~/code/external_services/database && make connection-info"
    echo "  RabbitMQ: cd ~/code/external_services/rabbitmq && make connection-info"
  else
    echo "Skipping configuration. You can configure later via the wizard menus."
  fi
  echo ""
  gtd_enter_to_continue
  ((step++))
  
  # Step 7: Setup MCP Server
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}Step $step/$total_steps: Setup MCP Server & Virtualenv${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "The MCP server provides AI tools for your GTD system."
  echo ""
  echo "This will:"
  echo "  • Create Python virtualenv"
  echo "  • Install MCP SDK"
  echo "  • Install RabbitMQ client (pika)"
  echo "  • Install watchdog (for filewatcher)"
  echo ""
  echo -n "Ready to setup MCP server? (y/N): "
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    MCP_DIR="$HOME/code/dotfiles/mcp"
    if [[ ! -d "$MCP_DIR" ]]; then
      MCP_DIR="$HOME/code/personal/dotfiles/mcp"
    fi
    SETUP_SCRIPT="${MCP_DIR}/setup.sh"
    
    if [[ -f "$SETUP_SCRIPT" ]]; then
      echo ""
      echo "Running MCP server setup..."
      cd "$MCP_DIR"
      if bash "$SETUP_SCRIPT" 2>&1; then
        echo ""
        echo -e "${GREEN}✓ MCP server setup complete${NC}"
      else
        echo ""
        echo -e "${YELLOW}⚠️  Setup completed with warnings${NC}"
        echo "You can review the output above for any issues."
      fi
    else
      echo -e "${RED}❌ Setup script not found${NC}"
      echo "Expected: $SETUP_SCRIPT"
    fi
  else
    echo "Skipping MCP server setup. You can do this later via:"
    echo "  Configuration & Setup → Setup MCP Server & Virtualenv"
  fi
  echo ""
  gtd_enter_to_continue
  
  # Final summary
  clear
  echo ""
  echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${GREEN}🎉 Setup Complete!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "You've completed the guided setup process!"
  echo ""
  echo -e "${BOLD}Next Steps:${NC}"
  echo ""
  echo "1. Verify everything is working:"
  echo "   gtd-wizard → 17) System status"
  echo ""
  echo "2. Start background workers (if not already running):"
  echo "   gtd-wizard → 17) System status → 3) Background Worker Status → 3) Start All Workers"
  echo ""
  echo "3. Test the system:"
  echo "   gtd-task add \"Test task\""
  echo "   gtd-wizard → 24) AI Suggestions"
  echo ""
  echo -e "${BOLD}Documentation:${NC}"
  echo "  • Complete Setup Guide: docs/COMPLETE_SETUP_GUIDE.md"
  echo "  • Setup Checklist: docs/SETUP_CHECKLIST.md"
  echo ""
  gtd_enter_to_continue
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      
      gtd_quick_pause
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
      gtd_quick_pause
      ;;
    8)
      clear
      echo ""
      echo "📊 Your Second Brain Status"
      echo ""
      gtd-brain-metrics dashboard 2>/dev/null || echo "Run: gtd-brain-metrics dashboard"
      echo ""
      gtd_quick_pause
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
          gtd_quick_pause
          ;;
        2)
          gtd-daily-log-sync push
          echo ""
          gtd_quick_pause
          ;;
        3)
          gtd-daily-log-sync pull
          echo ""
          gtd_quick_pause
          ;;
        4)
          gtd-daily-log-sync status
          echo ""
          gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
  gtd_quick_pause
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
  gtd_quick_pause
}

vector_database_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔍 Vector Database Management${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Manage your vector database for semantic search and content retrieval."
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) 📊 View Database Statistics"
  echo "  2) 📋 List All Embeddings"
  echo "  3) 🔍 List Embeddings by Content Type"
  echo "  4) 🔢 Count Embeddings"
  echo "  5) ✅ Test Database Connection"
  echo "  6) 🔍 Search Vector Database (semantic search)"
  echo "  7) 🔧 Create pgvector Extension (requires postgres superuser)"
  echo "  8) 🏗️  Initialize Database Schema (create tables)"
  echo "  9) 🔍 Scan Existing Files (queue for vectorization)"
  echo "  10) 🔌 Fix NodePort IP Address"
  echo "  11) 📁 Setup Vector Filewatcher"
  echo "  12) 📊 System Statistics (document_vectors table)"
  echo "  13) 📄 File Information (detailed file stats)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read vector_choice
  
  case "$vector_choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📊 Vector Database Statistics${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      cd "$HOME/code/dotfiles" && gtd-vector-db-status stats
      echo ""
      gtd_quick_pause
      ;;
    2)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📋 List All Embeddings${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -n "Limit (default: 100): "
      read limit_input
      limit="${limit_input:-100}"
      cd "$HOME/code/dotfiles" && gtd-vector-db-status list "" "$limit"
      echo ""
      gtd_quick_pause
      ;;
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔍 List Embeddings by Content Type${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Content types: daily_log, task, project, note, file"
      echo ""
      echo -n "Content type (default: all): "
      read content_type
      echo -n "Limit (default: 20): "
      read limit_input
      limit="${limit_input:-20}"
      cd "$HOME/code/dotfiles" && gtd-vector-db-status list "$content_type" "$limit"
      echo ""
      gtd_quick_pause
      ;;
    4)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔢 Count Embeddings${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -n "Content type (optional, press Enter for all): "
      read content_type
      if [[ -n "$content_type" ]]; then
        cd "$HOME/code/dotfiles" && gtd-vector-db-status count "$content_type"
      else
        cd "$HOME/code/dotfiles" && gtd-vector-db-status count
      fi
      echo ""
      gtd_quick_pause
      ;;
    5)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}✅ Test Database Connection${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      cd "$HOME/code/dotfiles" && gtd-vector-db-status test
      echo ""
      gtd_quick_pause
      ;;
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔍 Search Vector Database${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Search your vectorized content using semantic search."
      echo ""
      echo -n "Search query: "
      read search_query
      
      if [[ -z "$search_query" ]]; then
        echo "No query provided."
        echo ""
        gtd_quick_pause
      else
        echo ""
        echo "Search options:"
        echo "  1) Search all content types (excludes advice results automatically)"
        echo "  2) Search specific content type only"
        echo ""
        echo -n "Choose (default: 1): "
        read search_option
        search_option="${search_option:-1}"
        
        # Set search parameters based on option
        content_type_filter="None"
        threshold="0.4"  # Balanced threshold for better quality (was 0.3)
        
        case "$search_option" in
          1)
            content_type_filter="None"
            # Note: Advice results are automatically filtered by file_path in search_similar()
            ;;
          2)
            echo ""
            echo "Content types: daily_log, task, project, note, file, document"
            echo -n "Content type: "
            read content_type_filter
            if [[ -z "$content_type_filter" ]]; then
              content_type_filter="None"
            else
              content_type_filter="'$content_type_filter'"
            fi
            ;;
        esac
        
        echo ""
        echo "Searching..."
        echo ""
        
        # Use Python to search
        cd "$HOME/code/dotfiles" && mcp/venv/bin/python3 << PYEOF
import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

from zsh.functions.gtd_vectorization import search_similar

# Parse content type filter
content_type = $content_type_filter if $content_type_filter != "None" else None

# Note: Advice results are automatically filtered out by file_path check
results = search_similar(
    query_text="$search_query",
    content_type=content_type,
    limit=10,
    threshold=$threshold
)

if results:
    print(f"Found {len(results)} results:\n")
    for i, r in enumerate(results, 1):
        print(f"[{i}] {r['content_type']}:{r['content_id']}")
        print(f"    Similarity: {r.get('similarity', 0):.2f}")
        if r.get('content_text'):
            preview = r['content_text'][:200].replace('\n', ' ')
            if len(r['content_text']) > 200:
                preview += "..."
            print(f"    Preview: {preview}")
        print()
else:
    print("No results found.")
    print("\n💡 Try:")
    print("  - Lowering the similarity threshold")
    print("  - Using different keywords")
    print("  - Checking if content has been vectorized")
PYEOF
        echo ""
        gtd_quick_pause
      fi
      ;;
    7)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔧 Create pgvector Extension${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will create the pgvector extension in your database."
      echo "⚠️  Requires connecting as 'postgres' superuser."
      echo ""
      echo "The extension only needs to be created once per database."
      echo ""
      gtd_quick_pause
      cd "$HOME/code/dotfiles" && make vector-db-init-extension
      echo ""
      gtd_quick_pause
      ;;
    8)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🏗️  Initialize Database Schema${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will create the vector_embeddings table and indexes."
      echo "⚠️  Requires pgvector extension to be installed first (option 6)."
      echo ""
      gtd_quick_pause
      cd "$HOME/code/dotfiles" && make vector-db-init-schema
      echo ""
      gtd_quick_pause
      ;;
    9)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔍 Scan Existing Files${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will scan all markdown files in configured directories"
      echo "and queue them for vectorization."
      echo ""
      gtd_quick_pause
      cd "$HOME/code/dotfiles" && make filewatcher-scan
      echo ""
      gtd_quick_pause
      ;;
    10)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔌 Fix NodePort IP Address${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will detect the correct IP address for your Kubernetes setup"
      echo "and update your database configuration."
      echo ""
      gtd_quick_pause
      cd "$HOME/code/dotfiles" && bash bin/fix-nodeport-ip
      echo ""
      gtd_quick_pause
      ;;
    10)
      # Reuse the filewatcher setup from config wizard
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📁 Setup Vector Filewatcher${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will help you set up automatic vectorization of files."
      echo ""
      gtd_quick_pause
      
      # Call the filewatcher setup from config wizard
      GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
      if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
        GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
      fi
      CONFIG_DB_FILE="${GTD_CONFIG_DIR}/.gtd_config_database"
      
      echo "What would you like to do?"
      echo ""
      echo "  1) Enable/Disable Filewatcher"
      echo "  2) Configure Watch Directories"
      echo "  3) Setup Symlinks (for external directories)"
      echo "  4) Start Filewatcher"
      echo "  5) Stop Filewatcher"
      echo "  6) Check Filewatcher Status"
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
      
      case "$filewatcher_choice" in
        1)
          echo ""
          if [[ -f "$CONFIG_DB_FILE" ]]; then
            source "$CONFIG_DB_FILE"
          fi
          current_status="${VECTOR_FILEWATCHER_ENABLED:-false}"
          echo "Current status: $current_status"
          echo ""
          echo -n "Enable filewatcher? (y/n, current: $current_status): "
          read enable_choice
          if [[ "$enable_choice" == "y" || "$enable_choice" == "Y" ]]; then
            if [[ "$(uname)" == "Darwin" ]]; then
              sed -i '' "s/^VECTOR_FILEWATCHER_ENABLED=.*/VECTOR_FILEWATCHER_ENABLED=true/" "$CONFIG_DB_FILE" 2>/dev/null || echo "VECTOR_FILEWATCHER_ENABLED=true" >> "$CONFIG_DB_FILE"
            else
              sed -i "s/^VECTOR_FILEWATCHER_ENABLED=.*/VECTOR_FILEWATCHER_ENABLED=true/" "$CONFIG_DB_FILE" 2>/dev/null || echo "VECTOR_FILEWATCHER_ENABLED=true" >> "$CONFIG_DB_FILE"
            fi
            echo "✅ Filewatcher enabled"
          else
            if [[ "$(uname)" == "Darwin" ]]; then
              sed -i '' "s/^VECTOR_FILEWATCHER_ENABLED=.*/VECTOR_FILEWATCHER_ENABLED=false/" "$CONFIG_DB_FILE" 2>/dev/null || echo "VECTOR_FILEWATCHER_ENABLED=false" >> "$CONFIG_DB_FILE"
            else
              sed -i "s/^VECTOR_FILEWATCHER_ENABLED=.*/VECTOR_FILEWATCHER_ENABLED=false/" "$CONFIG_DB_FILE" 2>/dev/null || echo "VECTOR_FILEWATCHER_ENABLED=false" >> "$CONFIG_DB_FILE"
            fi
            echo "✅ Filewatcher disabled"
          fi
          ;;
        2)
          echo ""
          echo -n "Enter directories to watch (comma-separated, default: GTD_BASE_DIR and DAILY_LOG_DIR): "
          read watch_dirs_input
          if [[ -n "$watch_dirs_input" ]]; then
            if [[ "$(uname)" == "Darwin" ]]; then
              sed -i '' "s|^VECTOR_WATCH_DIRS=.*|VECTOR_WATCH_DIRS=\"$watch_dirs_input\"|" "$CONFIG_DB_FILE" 2>/dev/null || echo "VECTOR_WATCH_DIRS=\"$watch_dirs_input\"" >> "$CONFIG_DB_FILE"
            else
              sed -i "s|^VECTOR_WATCH_DIRS=.*|VECTOR_WATCH_DIRS=\"$watch_dirs_input\"|" "$CONFIG_DB_FILE" 2>/dev/null || echo "VECTOR_WATCH_DIRS=\"$watch_dirs_input\"" >> "$CONFIG_DB_FILE"
            fi
            echo "✅ Watch directories updated"
          fi
          ;;
        3)
          echo ""
          echo "Setting up symlinks for external directories..."
          cd "$HOME/code/dotfiles" && make filewatcher-setup-symlinks 2>/dev/null || echo "Symlink setup not available"
          ;;
        4)
          echo ""
          cd "$HOME/code/dotfiles" && make filewatcher-start
          ;;
        5)
          echo ""
          cd "$HOME/code/dotfiles" && make filewatcher-stop
          ;;
        6)
          echo ""
          cd "$HOME/code/dotfiles" && make filewatcher-status
          ;;
        0)
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
      echo ""
      gtd_quick_pause
      ;;
    11)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📊 System Statistics (document_vectors)${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      cd "$HOME/code/dotfiles" && gtd-vector-db-status system-stats
      echo ""
      gtd_quick_pause
      ;;
    13)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📄 File Information${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Enter the file path to get detailed information:"
      echo ""
      echo -n "File path: "
      read file_path_input
      if [[ -n "$file_path_input" ]]; then
        echo ""
        cd "$HOME/code/dotfiles" && gtd-vector-db-status file-info "$file_path_input"
      else
        echo "❌ No file path provided"
      fi
      echo ""
      gtd_quick_pause
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      gtd_quick_pause
      ;;
  esac
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
  echo "  8) 🔍 Vector Database Status & Inspection"
  echo "  9) Analyze energy patterns (background)"
  echo "  10) Find connections (background)"
  echo "  11) Generate insights (background)"
  echo "  12) 🔍 Scan Analysis Results for Suggestions"
  echo "  13) 📋 View Analysis Results (weekly reviews, energy analysis, etc.)"
  echo "  14) Check MCP System Status"
  echo "  15) 🚀 Deploy Worker to Kubernetes"
  echo "  16) 🗺️  Scan for MoC/Area Opportunities (background)"
  echo "  17) 📚 Review Knowledge Organization Results"
  echo "  18) 📊 View Unified Learning Stats (All Suggestions)"
  echo "  19) 🤖 Auto-Suggest Controls (Autonomous Implementation)"
  echo "  20) 🎛️  Manage Suggestion Thresholds (Show More/Less)"
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
        gtd_quick_pause
        return 1
      fi
      
      echo ""
      echo "Analyzing text for task suggestions..."
      
      # Use MCP server's suggest_tasks_from_text tool
      MCP_SERVER="$HOME/code/dotfiles/mcp/gtd_mcp_server.py"
      if [[ ! -f "$MCP_SERVER" ]]; then
        MCP_SERVER="$HOME/code/personal/dotfiles/mcp/gtd_mcp_server.py"
      fi
      
      MCP_PYTHON=$(gtd_get_mcp_python 2>/dev/null || echo "python3")
      
      if [[ -f "$MCP_SERVER" ]]; then
        # Call the MCP tool via Python
        result=$("$MCP_PYTHON" -c "
import sys
import json
import asyncio
from pathlib import Path

sys.path.insert(0, '$(dirname "$MCP_SERVER")')

try:
    from gtd_mcp_server import handle_call_tool
    
    # Call suggest_tasks_from_text
    result = asyncio.run(handle_call_tool('suggest_tasks_from_text', {
        'text': '''$suggestion_text''',
        'context': 'wizard',
        'mode': 'review'
    }))
    
    # Extract text content
    if result and len(result) > 0:
        for content in result:
            if hasattr(content, 'text'):
                print(content.text)
            else:
                print(str(content))
    else:
        print(json.dumps({'error': 'No response from tool'}))
        
except Exception as e:
    print(json.dumps({'error': f'Error calling tool: {str(e)}'}))
" 2>&1)
        
        # Parse the result
        if echo "$result" | "$MCP_PYTHON" -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
          # Valid JSON response
          echo ""
          echo "$result" | "$MCP_PYTHON" -c "
import sys
import json

try:
    data = json.load(sys.stdin)
    
    if 'error' in data:
        print(f\"❌ Error: {data['error']}\")
        sys.exit(1)
    
    suggestions = data.get('suggestions', [])
    auto_created = data.get('auto_created', [])
    saved_suggestions = data.get('saved_suggestions', [])
    
    if auto_created:
        print(f\"✅ Auto-created {len(auto_created)} high-confidence task(s):\")
        print('')
        for task in auto_created:
            print(f\"  • {task.get('title', 'Unknown')}\")
        print('')
    
    if saved_suggestions:
        print(f\"💡 Found {len(saved_suggestions)} suggestion(s) for review:\")
        print('')
        for i, sug in enumerate(saved_suggestions, 1):
            title = sug.get('title', 'Unknown')
            reason = sug.get('reason', '')
            confidence = sug.get('confidence', 0)
            print(f\"  {i}. {title}\")
            print(f\"     Confidence: {confidence:.0%}\")
            if reason:
                print(f\"     Reason: {reason[:60]}...\" if len(reason) > 60 else f\"     Reason: {reason}\")
            print('')
        
        print('Use option 2 to review and create tasks from these suggestions.')
    elif not auto_created:
        print('No actionable tasks found in the text.')
        
except Exception as e:
    print(f\"Error parsing response: {e}\")
    print('Raw response:')
    sys.stdin.seek(0)
    print(sys.stdin.read())
" 2>/dev/null || echo "$result"
        else
          # Not valid JSON, show raw output
          echo ""
          echo "$result"
        fi
      else
        echo "❌ MCP server not found: $MCP_SERVER"
        echo ""
        echo "Make sure MCP server is set up. See mcp/README.md for details."
      fi
      
      echo ""
      gtd_quick_pause
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
        gtd_quick_pause
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
        gtd_quick_pause
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
        gtd_quick_pause
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
        gtd_quick_pause
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
      
      PROGRESS_ANALYZER="$HOME/code/dotfiles/mcp/gtd_progress_analyzer.py"
      if [[ ! -f "$PROGRESS_ANALYZER" ]]; then
        PROGRESS_ANALYZER="$HOME/code/personal/dotfiles/mcp/gtd_progress_analyzer.py"
      fi
      
      if [[ -f "$PROGRESS_ANALYZER" ]]; then
        # Get Python executable (prefer virtualenv if available)
        MCP_PYTHON=$(gtd_get_mcp_python 2>/dev/null || echo "python3")
        result=$("$MCP_PYTHON" "$PROGRESS_ANALYZER" summary "$days" 2>&1)
        echo "$result"
      else
        echo "❌ Progress analyzer script not found"
        echo "Expected location: $PROGRESS_ANALYZER"
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
        gtd_quick_pause
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
      gtd_quick_pause
      ;;
    8)
      vector_database_wizard
      ;;
    9)
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
      gtd_quick_pause
      ;;
    10)
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
      gtd_quick_pause
      ;;
    11)
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
            echo -e "Queue method: ${CYAN}File queue${NC}"
            echo -e "Queue file: ${CYAN}~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
            echo ""
            echo "To verify the job was queued:"
            echo -e "  ${CYAN}wc -l ~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
            echo -e "  ${CYAN}tail -1 ~/Documents/gtd/deep_analysis_queue.jsonl${NC}"
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
      gtd_quick_pause
      ;;
    12)
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
      echo "Queuing analysis results for suggestion extraction..."
      echo "This will use the deep worker (thinking model) for better quality suggestions."
      echo ""
      
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
    print('✅', data.get('message', 'Scan queued'))
    print('')
    if data.get('files_queued', 0) > 0:
        print('📋 Queued', data['files_queued'], 'analysis result(s) for processing')
        print('   Using deep worker (thinking model) for suggestion extraction')
        print('')
        if data.get('files'):
            print('📁 Files queued:', ', '.join(data.get('files', [])[:5]))
            if len(data.get('files', [])) > 5:
                print('   ... and', len(data.get('files', [])) - 5, 'more')
            print('')
        print('💡 Suggestions will be created in the background by the deep worker.')
        print('   Check suggestions later or wait for notifications.')
    else:
        print('ℹ️  No analysis results found to queue')
else:
    print('❌', data.get('message', 'Scan failed'))
" 2>/dev/null || echo "$result"
        else
          echo ""
          echo "$result"
        fi
      fi
      echo ""
      gtd_quick_pause
      ;;
    13)
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
        gtd_quick_pause
      fi
      ;;
    14)
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
      gtd_quick_pause
      ;;
    15)
      deployment_wizard
      ;;
    16)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🗺️  Scan for MoC/Area Opportunities${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "This will analyze your GTD system and suggest:"
      echo "  • MoCs (Maps of Content) to create from note clusters"
      echo "  • Areas of Responsibility for orphaned projects"
      echo "  • New Areas based on daily log themes"
      echo ""
      echo "What type of scan would you like?"
      echo ""
      echo "  1) Full scan (all analysis)"
      echo "  2) Area assignments only (orphaned projects)"
      echo "  3) MoC suggestions only (note clusters)"
      echo "  4) Theme analysis only (daily logs)"
      echo ""
      echo -n "Choose (1-4): "
      read scan_choice
      
      local scan_type="full"
      case "$scan_choice" in
        1) scan_type="full" ;;
        2) scan_type="areas" ;;
        3) scan_type="mocs" ;;
        4) scan_type="themes" ;;
        *)
          echo "Invalid choice"
          echo ""
          gtd_quick_pause
          continue
          ;;
      esac
      
      echo ""
      echo "Queuing knowledge organization scan (type: $scan_type)..."
      
      local python_cmd=$(gtd_get_mcp_python 2>/dev/null || echo "python3")
      local queue_result=$("$python_cmd" -c "
import sys
sys.path.insert(0, '$(dirname "$0")/../mcp')
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_mcp_server import queue_knowledge_organization

status = queue_knowledge_organization('$scan_type')
print(status)
" 2>&1)
      
      if [[ "$queue_result" =~ "queued_to_rabbitmq" || "$queue_result" =~ "queued_to_file" ]]; then
        echo "✅ Analysis queued! Processing in the background."
        echo ""
        echo "You'll see results in the wizard when complete, or use option 17."
        echo ""
      else
        echo "⚠️  Failed to queue analysis: $queue_result"
        echo ""
      fi
      ;;
    17)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📚 Knowledge Organization Results${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      local results_dir="$GTD_BASE_DIR/knowledge_organization_results"
      
      if [[ ! -d "$results_dir" ]] || [[ -z "$(find "$results_dir" -name "knowledge_org_*.json" -type f 2>/dev/null)" ]]; then
        echo "No knowledge organization results found."
        echo ""
        echo "Run option 16 to trigger a scan first."
        echo ""
        gtd_quick_pause
        continue
      fi
      
      # Find most recent result
      local result_file=$(find "$results_dir" -name "knowledge_org_*.json" -type f 2>/dev/null | sort -r | head -1)
      
      if [[ -z "$result_file" ]]; then
        echo "No results found."
        echo ""
        gtd_quick_pause
        continue
      fi
      
      local python_cmd=$(gtd_get_mcp_python 2>/dev/null || echo "python3")
      
      # Display results
      "$python_cmd" -c "
import json
with open('$result_file') as f:
    data = json.load(f)

suggestions = data.get('suggestions', [])
counts = data.get('counts', {})
learning_applied = data.get('learning_applied', False)
learning_stats = data.get('learning_stats', {})

print(f\"Found {len(suggestions)} suggestion(s):\")
print(f\"  • {counts.get('area_assignments', 0)} area assignment(s)\")
print(f\"  • {counts.get('moc_creations', 0)} MoC creation(s)\")
print(f\"  • {counts.get('area_creations', 0)} new area suggestion(s)\")
print()

# Show learning stats if available
if learning_applied and learning_stats:
    print(\"📊 Learning System Active:\")
    thresholds = learning_stats.get('thresholds', {})
    acceptance_rates = learning_stats.get('acceptance_rates', {})
    
    print(f\"  Confidence thresholds:\")
    for stype, threshold in thresholds.items():
        rate = acceptance_rates.get(stype, 0.0)
        print(f\"    {stype}: {threshold:.0%} (acceptance: {rate:.0%})\")
    
    total_decisions = learning_stats.get('total_decisions', 0)
    print(f\"  Total decisions tracked: {total_decisions}\")
    print()
print()

# Group by type
for suggestion_type in ['area_assignment', 'moc_creation', 'area_creation']:
    typed_suggestions = [s for s in suggestions if s.get('type') == suggestion_type]
    if not typed_suggestions:
        continue
    
    type_names = {
        'area_assignment': 'Area Assignments',
        'moc_creation': 'MoC Creations',
        'area_creation': 'New Area Suggestions'
    }
    
    print(f\"{type_names[suggestion_type]}:\")
    print()
    
    for idx, s in enumerate(typed_suggestions, 1):
        if suggestion_type == 'area_assignment':
            print(f\"[{idx}] {s.get('project_name', 'Unknown')}\")
            print(f\"    → {s.get('suggested_area', 'Unknown')}\")
            print(f\"    Confidence: {int(s.get('confidence', 0) * 100)}%\")
            print(f\"    Reason: {s.get('reason', 'N/A')}\")
        elif suggestion_type == 'moc_creation':
            print(f\"[{idx}] Create MoC: {s.get('moc_name', 'Unknown')}\")
            print(f\"    Estimated notes: {s.get('estimated_note_count', 'N/A')}\")
            print(f\"    Confidence: {int(s.get('confidence', 0) * 100)}%\")
            print(f\"    Reason: {s.get('reason', 'N/A')}\")
        elif suggestion_type == 'area_creation':
            print(f\"[{idx}] Create Area: {s.get('area_name', 'Unknown')}\")
            print(f\"    Themes: {', '.join(s.get('supporting_themes', []))}\")
            print(f\"    Confidence: {int(s.get('confidence', 0) * 100)}%\")
            print(f\"    Reason: {s.get('reason', 'N/A')}\")
        print()
"
      
      echo ""
      echo "What would you like to do?"
      echo ""
      echo "  1) Implement these suggestions (guided)"
      echo "  2) Delete this result"
      echo "  3) Keep and go back"
      echo ""
      echo -n "Choose (1-3): "
      read results_choice
      
      case "$results_choice" in
        1)
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Implementation Options"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "  1) Implement all suggestions"
          echo "  2) Choose specific suggestions"
          echo "  3) Cancel"
          echo ""
          echo -n "Choose (1-3): "
          read impl_choice
          
          case "$impl_choice" in
            1)
              # Implement all
              echo ""
              echo "Implementing all suggestions..."
              echo ""
              "$python_cmd" "$HOME/code/dotfiles/mcp/knowledge_org_implement.py" "$result_file"
              echo ""
              gtd_quick_pause
              ;;
            2)
              # Choose specific
              echo ""
              echo -n "Enter suggestion numbers (comma-separated, e.g., 1,3,5): "
              read indices
              echo ""
              echo "Implementing selected suggestions..."
              echo ""
              "$python_cmd" "$HOME/code/dotfiles/mcp/knowledge_org_implement.py" "$result_file" --indices="$indices"
              echo ""
              gtd_quick_pause
              ;;
            3)
              # Cancel
              ;;
          esac
          ;;
        2)
          rm -f "$result_file"
          echo ""
          echo "✓ Result deleted"
          echo ""
          ;;
        3)
          # Just go back
          ;;
      esac
      ;;
    18)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📊 Unified Learning Stats (All Suggestions)${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      local python_cmd=$(gtd_get_mcp_python 2>/dev/null || echo "python3")
      
      # Display unified learning stats
      "$python_cmd" "$HOME/code/dotfiles/mcp/gtd_unified_learning.py" stats
      
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "💡 Cross-Domain Insights"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      "$python_cmd" "$HOME/code/dotfiles/mcp/gtd_unified_learning.py" insights
      
      echo ""
      echo "What would you like to do?"
      echo ""
      echo "  1) View stats for specific suggestion type"
      echo "  2) Reset learning data (start fresh)"
      echo "  3) Migrate old learning data"
      echo "  4) Go back"
      echo ""
      echo -n "Choose (1-4): "
      read stats_choice
      
      case "$stats_choice" in
        1)
          echo ""
          echo "Suggestion types:"
          echo "  1) Task from Log"
          echo "  2) Area Assignment"
          echo "  3) MoC Creation"
          echo "  4) Area Creation"
          echo "  5) Project Suggestion"
          echo "  6) Insight"
          echo ""
          echo -n "Choose type (1-6): "
          read type_choice
          
          type_map=("task_from_log" "area_assignment" "moc_creation" "area_creation" "project_suggestion" "insight")
          if [[ "$type_choice" =~ ^[1-6]$ ]]; then
            selected_type="${type_map[$((type_choice - 1))]}"
            echo ""
            "$python_cmd" "$HOME/code/dotfiles/mcp/gtd_unified_learning.py" stats --type="$selected_type"
          fi
          echo ""
          gtd_quick_pause
          ;;
        2)
          echo ""
          echo -n "Are you sure you want to reset learning data? (y/N): "
          read confirm_reset
          if [[ "$confirm_reset" =~ ^[Yy]$ ]]; then
            "$python_cmd" "$HOME/code/dotfiles/mcp/gtd_unified_learning.py" reset
            echo ""
            gtd_quick_pause
          fi
          ;;
        3)
          echo ""
          echo "Running migration..."
          "$python_cmd" "$HOME/code/dotfiles/mcp/migrate_to_unified_learning.py"
          echo ""
          gtd_quick_pause
          ;;
        4)
          # Go back
          ;;
      esac
      ;;
    19)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🤖 Auto-Suggest Controls (Autonomous Implementation)${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Show current status
      echo "Current Status:"
      echo ""
      "$HOME/code/dotfiles/bin/gtd-auto-suggest" status
      
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "What would you like to do?"
      echo ""
      echo "  1) Run auto-suggest (dry-run mode - safe preview)"
      echo "  2) Run auto-suggest (LIVE mode - actually implement)"
      echo "  3) Enable auto-suggest (dry-run mode)"
      echo "  4) Enable auto-suggest (LIVE mode)"
      echo "  5) Disable auto-suggest"
      echo "  6) Configure thresholds"
      echo "  7) View action history"
      echo "  8) Go back"
      echo ""
      echo -n "Choose (1-8): "
      read auto_choice
      
      case "$auto_choice" in
        1)
          echo ""
          echo "Running auto-suggest in DRY-RUN mode..."
          echo "(No actual changes will be made)"
          echo ""
          "$HOME/code/dotfiles/bin/gtd-auto-suggest" run --dry-run
          echo ""
          gtd_quick_pause
          ;;
        2)
          echo ""
          echo -e "${YELLOW}⚠️  WARNING: This will ACTUALLY implement suggestions!${NC}"
          echo -n "Are you sure? (y/N): "
          read confirm_live
          if [[ "$confirm_live" =~ ^[Yy]$ ]]; then
            echo ""
            "$HOME/code/dotfiles/bin/gtd-auto-suggest" run --live
          else
            echo "Cancelled"
          fi
          echo ""
          gtd_quick_pause
          ;;
        3)
          echo ""
          "$HOME/code/dotfiles/bin/gtd-auto-suggest" enable
          echo ""
          gtd_quick_pause
          ;;
        4)
          echo ""
          echo -e "${YELLOW}⚠️  WARNING: This will enable AUTONOMOUS suggestion implementation!${NC}"
          echo -n "Are you sure? (y/N): "
          read confirm_enable_live
          if [[ "$confirm_enable_live" =~ ^[Yy]$ ]]; then
            echo ""
            "$HOME/code/dotfiles/bin/gtd-auto-suggest" enable --live --force
          else
            echo "Cancelled"
          fi
          echo ""
          gtd_quick_pause
          ;;
        5)
          echo ""
          "$HOME/code/dotfiles/bin/gtd-auto-suggest" disable
          echo ""
          gtd_quick_pause
          ;;
        6)
          echo ""
          echo "Configure Auto-Suggest Thresholds"
          echo ""
          echo "Suggestion types:"
          echo "  1) task_suggestion"
          echo "  2) project_suggestion"
          echo "  3) moc_suggestion"
          echo "  4) area_suggestion"
          echo ""
          echo -n "Choose type (1-4, or 0 to go back): "
          read type_choice
          
          case "$type_choice" in
            1) type_name="task_suggestion" ;;
            2) type_name="project_suggestion" ;;
            3) type_name="moc_suggestion" ;;
            4) type_name="area_suggestion" ;;
            0|"") ;;
            *) 
              echo "Invalid choice"
              echo ""
              gtd_quick_pause
              ;;
          esac
          
          if [[ -n "$type_name" ]]; then
            echo ""
            echo "Configure $type_name:"
            echo ""
            echo "  1) Enable/Disable"
            echo "  2) Set minimum confidence (0.0 - 1.0)"
            echo ""
            echo -n "Choose (1-2): "
            read config_choice
            
            case "$config_choice" in
              1)
                echo ""
                echo -n "Enable $type_name? (y/n): "
                read enable_choice
                if [[ "$enable_choice" =~ ^[Yy]$ ]]; then
                  "$HOME/code/dotfiles/bin/gtd-auto-suggest" config --type="$type_name" --value="true"
                else
                  "$HOME/code/dotfiles/bin/gtd-auto-suggest" config --type="$type_name" --value="false"
                fi
                ;;
              2)
                echo ""
                echo -n "Enter minimum confidence (0.0 - 1.0): "
                read confidence_value
                "$HOME/code/dotfiles/bin/gtd-auto-suggest" config --type="$type_name" --value="$confidence_value"
                ;;
            esac
            
            echo ""
            gtd_quick_pause
          fi
          ;;
        7)
          echo ""
          "$HOME/code/dotfiles/bin/gtd-auto-suggest" history
          echo ""
          gtd_quick_pause
          ;;
        8)
          # Go back
          ;;
      esac
      ;;
    20)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🎛️  Manage Suggestion Thresholds${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Thresholds control how many suggestions you see. Lower = more suggestions."
      echo ""
      
      local python_cmd=$(gtd_get_mcp_python 2>/dev/null || echo "python3")
      
      # Show current thresholds
      echo "Current Thresholds:"
      echo ""
      "$python_cmd" -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_unified_learning import load_learning_data, SUGGESTION_TYPES

data = load_learning_data()
thresholds = data.get('thresholds', {})

for stype, info in SUGGESTION_TYPES.items():
    threshold = thresholds.get(stype, info['default_threshold'])
    default = info['default_threshold']
    name = info['name']
    
    status = ''
    if threshold < default:
        status = '${GREEN}(↓ showing more)${NC}'
    elif threshold > default:
        status = '${YELLOW}(↑ showing less)${NC}'
    else:
        status = '${CYAN}(default)${NC}'
    
    print(f\"  {name:40} {threshold:.0%} {status}\")
" 2>/dev/null || echo "  Error loading thresholds"
      
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "What would you like to do?"
      echo ""
      echo "  1) Show MORE of a suggestion type (lower threshold)"
      echo "  2) Show LESS of a suggestion type (raise threshold)"
      echo "  3) Set custom threshold for a type"
      echo "  4) View explanation for a suggestion type"
      echo "  5) Reset all thresholds to defaults"
      echo "  6) Run diagnostic (see why suggestions aren't showing)"
      echo "  7) Go back"
      echo ""
      echo -n "Choose (1-7): "
      read threshold_choice
      
      case "$threshold_choice" in
        1)
          echo ""
          echo "Show MORE of which suggestion type?"
          echo ""
          echo "  1) Task from Log"
          echo "  2) Area Assignment"
          echo "  3) MoC Creation"
          echo "  4) Area Creation"
          echo "  5) Project Suggestion"
          echo "  6) Insight"
          echo ""
          echo -n "Choose (1-6): "
          read type_choice
          
          type_map=("task_from_log" "area_assignment" "moc_creation" "area_creation" "project_suggestion" "insight")
          if [[ "$type_choice" =~ ^[1-6]$ ]]; then
            selected_type="${type_map[$((type_choice - 1))]}"
            echo ""
            result=$("$python_cmd" -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_unified_learning import adjust_threshold
adjust_threshold('$selected_type', 'more')
" 2>&1)
            echo "$result"
            echo ""
            echo -e "${GREEN}✓ Threshold lowered - you'll see more suggestions of this type${NC}"
          else
            echo "Invalid choice"
          fi
          echo ""
          gtd_quick_pause
          ;;
        2)
          echo ""
          echo "Show LESS of which suggestion type?"
          echo ""
          echo "  1) Task from Log"
          echo "  2) Area Assignment"
          echo "  3) MoC Creation"
          echo "  4) Area Creation"
          echo "  5) Project Suggestion"
          echo "  6) Insight"
          echo ""
          echo -n "Choose (1-6): "
          read type_choice
          
          type_map=("task_from_log" "area_assignment" "moc_creation" "area_creation" "project_suggestion" "insight")
          if [[ "$type_choice" =~ ^[1-6]$ ]]; then
            selected_type="${type_map[$((type_choice - 1))]}"
            echo ""
            result=$("$python_cmd" -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_unified_learning import adjust_threshold
adjust_threshold('$selected_type', 'less')
" 2>&1)
            echo "$result"
            echo ""
            echo -e "${YELLOW}✓ Threshold raised - you'll see fewer, higher-quality suggestions${NC}"
          else
            echo "Invalid choice"
          fi
          echo ""
          gtd_quick_pause
          ;;
        3)
          echo ""
          echo "Set custom threshold for which type?"
          echo ""
          echo "  1) Task from Log"
          echo "  2) Area Assignment"
          echo "  3) MoC Creation"
          echo "  4) Area Creation"
          echo "  5) Project Suggestion"
          echo "  6) Insight"
          echo ""
          echo -n "Choose (1-6): "
          read type_choice
          
          type_map=("task_from_log" "area_assignment" "moc_creation" "area_creation" "project_suggestion" "insight")
          if [[ "$type_choice" =~ ^[1-6]$ ]]; then
            selected_type="${type_map[$((type_choice - 1))]}"
            echo ""
            echo -n "Enter new threshold (0-100%): "
            read threshold_percent
            
            if [[ "$threshold_percent" =~ ^[0-9]+$ ]] && [[ $threshold_percent -ge 0 ]] && [[ $threshold_percent -le 100 ]]; then
              # Convert to decimal
              threshold=$(echo "scale=2; $threshold_percent / 100" | bc 2>/dev/null || echo "scale=2; $threshold_percent / 100" | awk '{printf "%.2f", $1/100}')
              
              result=$("$python_cmd" -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_unified_learning import set_threshold
if set_threshold('$selected_type', $threshold):
    print('✓ Threshold set to ${threshold_percent}%')
else:
    print('✗ Failed to set threshold')
" 2>&1)
              echo ""
              echo "$result"
            else
              echo "Invalid threshold. Must be 0-100."
            fi
          else
            echo "Invalid choice"
          fi
          echo ""
          gtd_quick_pause
          ;;
        4)
          echo ""
          echo "Explain which suggestion type?"
          echo ""
          echo "  1) Task from Log"
          echo "  2) Area Assignment"
          echo "  3) MoC Creation"
          echo "  4) Area Creation"
          echo "  5) Project Suggestion"
          echo "  6) Insight"
          echo ""
          echo -n "Choose (1-6): "
          read type_choice
          
          type_map=("task_from_log" "area_assignment" "moc_creation" "area_creation" "project_suggestion" "insight")
          if [[ "$type_choice" =~ ^[1-6]$ ]]; then
            selected_type="${type_map[$((type_choice - 1))]}"
            echo ""
            "$python_cmd" -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_explain_suggestions import explain_threshold
print(explain_threshold('$selected_type'))
" 2>/dev/null || echo "Error loading explanation"
          else
            echo "Invalid choice"
          fi
          echo ""
          gtd_quick_pause
          ;;
        5)
          echo ""
          echo -n "Reset ALL thresholds to defaults? (y/N): "
          read confirm
          
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            result=$("$python_cmd" -c "
import sys
sys.path.insert(0, '$HOME/code/dotfiles/mcp')
from gtd_unified_learning import load_learning_data, save_learning_data, SUGGESTION_TYPES

data = load_learning_data()
for stype, info in SUGGESTION_TYPES.items():
    data['thresholds'][stype] = info['default_threshold']
save_learning_data(data)
print('✓ All thresholds reset to defaults')
" 2>&1)
            echo ""
            echo "$result"
          else
            echo "Cancelled"
          fi
          echo ""
          gtd_quick_pause
          ;;
        6)
          echo ""
          if [[ -f "$HOME/code/dotfiles/bin/gtd-diagnose-suggestions" ]]; then
            "$HOME/code/dotfiles/bin/gtd-diagnose-suggestions"
          else
            echo "Diagnostic script not found"
            echo ""
            gtd_quick_pause
          fi
          ;;
        7)
          # Go back
          ;;
        *)
          echo "Invalid choice"
          echo ""
          gtd_quick_pause
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
  gtd_quick_pause
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
    gtd_quick_pause
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
  gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
      ;;
    6)
      echo ""
      echo -n "XP Amount: "
      read xp_amount
      if [[ -z "$xp_amount" ]] || ! [[ "$xp_amount" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid XP amount"
        echo ""
        gtd_quick_pause
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
      gtd_quick_pause
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
          gtd_quick_pause
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
          gtd_quick_pause
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
          gtd_quick_pause
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
      gtd_quick_pause
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      gtd_quick_pause
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
          gtd_quick_pause
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
      gtd_quick_pause
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
          gtd_quick_pause
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
        gtd_quick_pause
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
          gtd_quick_pause
          continue
        fi
        
        local days_diff=$(( (end_ts - start_ts) / 86400 ))
        if [[ $days_diff -lt 0 ]]; then
          echo "❌ Start date must be before end date"
          echo ""
          gtd_quick_pause
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
        gtd_quick_pause
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
        gtd_quick_pause
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
          gtd_quick_pause
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
        
        gtd_quick_pause
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
        
        gtd_quick_pause
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
          gtd_quick_pause
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
        gtd_quick_pause
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
        gtd_quick_pause
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
        gtd_quick_pause
        ;;
      0)
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        gtd_quick_pause
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
    echo -e "${BOLD}Settings:${NC}"
    echo "  12) 🔐 Re-authenticate Google Calendar (gcalcli)"
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
        gtd_enter_to_continue
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
        gtd_enter_to_continue
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
          gtd_quick_pause
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
        gtd_enter_to_continue
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
          gtd_quick_pause
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
            gtd_quick_pause
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
        gtd_quick_pause
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
          gtd_quick_pause
          continue
        fi
        
        echo -n "When (e.g., '2024-12-05 10:00' or 'tomorrow 2pm'): "
        read event_when
        
        if [[ -z "$event_when" ]]; then
          echo "❌ Event time is required"
          echo ""
          gtd_quick_pause
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
        gtd_quick_pause
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
      gtd_enter_to_continue
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
      gtd_quick_pause
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
      gtd_quick_pause
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
        gtd_quick_pause
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
      gtd_enter_to_continue
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
      gtd_enter_to_continue
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
      gtd_enter_to_continue
      ;;
    12)
      echo ""
      if command -v gtd-calendar &>/dev/null; then
        gtd-calendar auth 2>&1
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/dotfiles/bin/gtd-calendar" auth 2>&1
      elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-calendar" ]]; then
        "$HOME/code/personal/dotfiles/bin/gtd-calendar" auth 2>&1
      else
        echo "❌ gtd-calendar command not found"
      fi
      echo ""
      echo "💡 If a link was generated, open it in your browser to authenticate."
      echo ""
      gtd_enter_to_continue
      ;;
    0|"")
      pop_menu
      return 0
      ;;
      *)
        echo "Invalid choice"
        echo ""
        gtd_quick_pause
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
  gtd_quick_pause
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
      gtd_quick_pause
      ;;
  esac
  
  echo ""
  gtd_quick_pause
}

