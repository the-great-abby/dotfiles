#!/bin/bash
# GTD Wizard Analysis Functions
# Analysis wizards for insights, tracking, metrics, patterns

search_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔍 Search Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_search_guide
  echo "What would you like to search?"
  echo ""
  echo "  1) Search GTD system"
  echo "  2) Search Second Brain"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read search_choice
  
  case "$search_choice" in
    1)
      echo ""
      echo -n "Search term: "
      read search_term
      gtd-search "$search_term"
      ;;
    2)
      echo ""
      echo -n "Search term: "
      read search_term
      gtd-brain search "$search_term"
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

status_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 System Status${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_status_guide
  echo "What status would you like to check?"
  echo ""
  echo "  1) Basic GTD System Status"
  echo "  2) MCP Server & AI System Status"
  echo "  3) Background Worker Status"
  echo "  4) Full System Status (All Checks)"
  echo "  5) 🚀 Kubernetes Deployment Status"
  echo "  6) 📋 View Kubernetes Pod Logs (Debug)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read status_choice
  
  case "$status_choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📊 Basic GTD System Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Inbox count
      local inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Inbox:${NC} ${inbox_count} item(s)"
      
      # Projects count
      local projects_count=$(ls -1 ~/Documents/gtd/1-projects/*/README.md 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Active Projects:${NC} ${projects_count}"
      
      # Tasks count
      local tasks_count=$(find ~/Documents/gtd/tasks -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Active Tasks:${NC} ${tasks_count}"
      
      # Today's log entries
      local today=$(date +"%Y-%m-%d")
      local log_file="$HOME/Documents/daily_logs/${today}.md"
      local log_count=0
      if [[ -f "$log_file" ]]; then
        log_count=$(grep -c "^[0-9][0-9]:[0-9][0-9]" "$log_file" 2>/dev/null || echo "0")
      fi
      echo -e "${BOLD}Today's Log Entries:${NC} ${log_count}"
      
      # Areas count
      local areas_count=$(ls -1 ~/Documents/gtd/2-areas/*.md 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Areas:${NC} ${areas_count}"
      ;;
    2)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}🤖 MCP Server & AI System Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check LM Studio
      echo -e "${BOLD}LM Studio (Fast Model):${NC}"
      if curl -s "http://localhost:1234/v1/models" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Running${NC}"
        models=$(curl -s "http://localhost:1234/v1/models" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', 'unknown')[:30] for m in data.get('data', [])[:3]]))" 2>/dev/null || echo "unknown")
        echo "  Models: $models"
      else
        echo -e "  ${RED}❌ Not running${NC}"
        echo "  → Start LM Studio and load a model"
      fi
      echo ""
      
      # Check MCP dependencies (check virtualenv first)
      echo -e "${BOLD}MCP Dependencies:${NC}"
      MCP_PYTHON=$(gtd_get_mcp_python)
      if [[ -n "$MCP_PYTHON" ]] && "$MCP_PYTHON" -c "import mcp" 2>/dev/null; then
        echo -e "  ${GREEN}✅ MCP SDK installed${NC}"
        if [[ "$MCP_PYTHON" == *"/venv/bin/python3" ]]; then
          echo "  (Using virtualenv: $(dirname "$(dirname "$MCP_PYTHON")"))"
        fi
      else
        echo -e "  ${RED}❌ MCP SDK not installed${NC}"
        echo ""
        echo "  Quick setup options:"
        echo "  1. Use wizard: Configuration & Setup → Setup MCP Server & Virtualenv"
        echo "  2. Manual: cd ~/code/dotfiles/mcp && ./setup.sh"
        echo ""
        echo -n "  Run setup now? (y/N): "
        read setup_now
        if [[ "$setup_now" == "y" || "$setup_now" == "Y" ]]; then
          echo ""
          echo "  Running setup..."
          MCP_DIR="$HOME/code/dotfiles/mcp"
          if [[ ! -d "$MCP_DIR" ]]; then
            MCP_DIR="$HOME/code/personal/dotfiles/mcp"
          fi
          SETUP_SCRIPT="${MCP_DIR}/setup.sh"
          if [[ -f "$SETUP_SCRIPT" ]]; then
            bash "$SETUP_SCRIPT"
            echo ""
            echo "  Setup complete! Check status above."
          else
            echo "  ❌ Setup script not found at: $SETUP_SCRIPT"
          fi
        fi
      fi
      echo ""
      
      # Check pending suggestions
      echo -e "${BOLD}Pending Suggestions:${NC}"
      SUGGESTIONS_DIR="${GTD_BASE_DIR}/suggestions"
      if [[ -d "$SUGGESTIONS_DIR" ]]; then
        pending_count=$(find "$SUGGESTIONS_DIR" -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$pending_count" -gt 0 ]]; then
          echo -e "  ${YELLOW}⚠️  $pending_count pending${NC}"
        else
          echo -e "  ${GREEN}✅ None pending${NC}"
        fi
      else
        echo -e "  ${CYAN}ℹ️  No suggestions yet${NC}"
      fi
      echo ""
      
      echo -e "${CYAN}Note:${NC} Check Cursor MCP status indicator for server connection"
      ;;
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}⚙️  Background Worker Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Check Kubernetes
      echo -e "${BOLD}Kubernetes Worker:${NC}"
      if command -v kubectl &>/dev/null; then
        if kubectl get deployment gtd-deep-analysis-worker &>/dev/null 2>&1; then
          replicas=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
          desired=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
          if [[ "$replicas" -gt 0 && "$replicas" == "$desired" ]]; then
            echo -e "  ${GREEN}✅ Running ($replicas/$desired)${NC}"
          else
            echo -e "  ${YELLOW}⚠️  Not fully ready ($replicas/$desired)${NC}"
          fi
        else
          echo -e "  ${CYAN}ℹ️  Not deployed${NC}"
        fi
      else
        echo -e "  ${CYAN}ℹ️  kubectl not available${NC}"
      fi
      echo ""
      
      # Check local worker
      echo -e "${BOLD}Local Worker Process:${NC}"
      if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
        pid=$(pgrep -f "gtd_deep_analysis_worker.py")
        echo -e "  ${GREEN}✅ Running (PID: $pid)${NC}"
        echo ""
        echo "What would you like to do?"
        echo "  1) Stop worker"
        echo "  2) Restart worker"
        echo "  3) View worker logs"
        echo "  0) Back"
        echo ""
        echo -n "Choose: "
        read worker_action
        case "$worker_action" in
          1)
            echo ""
            echo "Stopping worker..."
            kill "$pid" 2>/dev/null
            sleep 1
            if ! pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
              echo -e "${GREEN}✅ Worker stopped${NC}"
            else
              echo -e "${YELLOW}⚠️  Worker still running, trying force kill...${NC}"
              kill -9 "$pid" 2>/dev/null
              sleep 1
              if ! pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
                echo -e "${GREEN}✅ Worker stopped${NC}"
              else
                echo -e "${RED}❌ Could not stop worker${NC}"
              fi
            fi
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
          2)
            echo ""
            echo "Restarting worker..."
            kill "$pid" 2>/dev/null
            sleep 2
            # Start worker (will be done below)
            worker_action="start"
            ;;
          3)
            echo ""
            echo -e "${BOLD}Worker Logs (last 50 lines):${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            # Try to find log file or show process output
            echo "Note: If worker was started in a terminal, check that terminal for logs."
            echo "Worker PID: $pid"
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
        esac
      else
        echo -e "  ${CYAN}ℹ️  Not running${NC}"
        echo ""
        echo "Would you like to start the local worker?"
        echo "  1) Start worker (background)"
        echo "  2) Start worker (foreground - see logs)"
        echo "  0) Back"
        echo ""
        echo -n "Choose: "
        read worker_action
      fi
      
      # Start worker if requested
      if [[ "$worker_action" == "1" || "$worker_action" == "start" ]]; then
        echo ""
        echo "Starting worker in background..."
        
        # Find worker script
        WORKER_SCRIPT="$HOME/code/dotfiles/mcp/gtd_deep_analysis_worker.py"
        if [[ ! -f "$WORKER_SCRIPT" ]]; then
          WORKER_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_deep_analysis_worker.py"
        fi
        
        if [[ ! -f "$WORKER_SCRIPT" ]]; then
          echo -e "${RED}❌ Worker script not found${NC}"
          echo "Expected at: $HOME/code/dotfiles/mcp/gtd_deep_analysis_worker.py"
          echo "or: $HOME/code/personal/dotfiles/mcp/gtd_deep_analysis_worker.py"
        else
          # Ensure queue file and directories exist
          GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
          QUEUE_FILE="${GTD_BASE_DIR}/deep_analysis_queue.jsonl"
          RESULTS_DIR="${GTD_BASE_DIR}/deep_analysis_results"
          
          echo "Setting up worker environment..."
          mkdir -p "$GTD_BASE_DIR" "$RESULTS_DIR"
          
          if [[ ! -f "$QUEUE_FILE" ]]; then
            touch "$QUEUE_FILE"
            echo -e "${GREEN}✓${NC} Created job queue file"
            echo "   Location: ${CYAN}$QUEUE_FILE${NC}"
            echo "   Purpose: Stores background analysis jobs (weekly reviews, energy analysis, etc.)"
          else
            queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ')
            if [[ "$queue_count" -gt 0 ]]; then
              echo -e "${CYAN}ℹ️  Queue file exists with $queue_count job(s) waiting${NC}"
            else
              echo -e "${GREEN}✓${NC} Queue file ready (empty)"
            fi
            echo "   Location: ${CYAN}$QUEUE_FILE${NC}"
          fi
          echo ""
          
          # Find Python executable
          MCP_PYTHON=$(gtd_get_mcp_python)
          if [[ -z "$MCP_PYTHON" ]]; then
            MCP_PYTHON="python3"
          fi
          
          echo "Starting worker process..."
          # Start worker in background
          nohup "$MCP_PYTHON" "$WORKER_SCRIPT" file >/dev/null 2>&1 &
          sleep 2
          
          if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
            new_pid=$(pgrep -f "gtd_deep_analysis_worker.py")
            echo -e "${GREEN}✅ Worker started successfully (PID: $new_pid)${NC}"
            echo ""
            echo "Worker Status:"
            echo -e "  📋 Queue file: ${CYAN}$QUEUE_FILE${NC}"
            echo -e "  📊 Results dir: ${CYAN}$RESULTS_DIR${NC}"
            echo "  🔄 Worker will process jobs from the queue automatically"
            echo ""
            echo "To add jobs: Use MCP tools (weekly_review, analyze_energy, etc.)"
            echo "To view logs: Check the terminal or run worker in foreground mode"
          else
            echo -e "${RED}❌ Failed to start worker${NC}"
            echo ""
            echo "Troubleshooting:"
            echo "  1. Check Python: $MCP_PYTHON --version"
            echo "  2. Check worker script: $WORKER_SCRIPT"
            echo "  3. Try starting manually:"
            echo "     ${CYAN}$MCP_PYTHON $WORKER_SCRIPT file${NC}"
            echo "  4. Check for errors in the output above"
          fi
        fi
        echo ""
        echo "Press Enter to continue..."
        read
      elif [[ "$worker_action" == "2" ]]; then
        echo ""
        echo "Starting worker in foreground (you'll see logs)..."
        echo "Press Ctrl+C to stop"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Find worker script
        WORKER_SCRIPT="$HOME/code/dotfiles/mcp/gtd_deep_analysis_worker.py"
        if [[ ! -f "$WORKER_SCRIPT" ]]; then
          WORKER_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_deep_analysis_worker.py"
        fi
        
        if [[ ! -f "$WORKER_SCRIPT" ]]; then
          echo -e "${RED}❌ Worker script not found${NC}"
        else
          # Ensure queue file and directories exist
          GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
          QUEUE_FILE="${GTD_BASE_DIR}/deep_analysis_queue.jsonl"
          RESULTS_DIR="${GTD_BASE_DIR}/deep_analysis_results"
          
          echo "Setting up worker environment..."
          mkdir -p "$GTD_BASE_DIR" "$RESULTS_DIR"
          
          if [[ ! -f "$QUEUE_FILE" ]]; then
            touch "$QUEUE_FILE"
            echo -e "${GREEN}✓${NC} Created job queue file"
            echo "   Location: ${CYAN}$QUEUE_FILE${NC}"
            echo "   Purpose: Stores background analysis jobs (weekly reviews, energy analysis, etc.)"
            echo ""
          else
            queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ')
            if [[ "$queue_count" -gt 0 ]]; then
              echo -e "${CYAN}ℹ️  Queue file exists with $queue_count job(s) waiting${NC}"
            else
              echo -e "${GREEN}✓${NC} Queue file ready (empty)"
            fi
            echo "   Location: ${CYAN}$QUEUE_FILE${NC}"
            echo ""
          fi
          
          # Find Python executable
          MCP_PYTHON=$(gtd_get_mcp_python)
          if [[ -z "$MCP_PYTHON" ]]; then
            MCP_PYTHON="python3"
          fi
          
          echo "Starting worker (foreground mode - you'll see live logs)..."
          echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          echo ""
          
          # Start worker in foreground
          "$MCP_PYTHON" "$WORKER_SCRIPT" file
        fi
      fi
      echo ""
      
      # Check queue
      echo -e "${BOLD}Queue Status:${NC}"
      QUEUE_FILE="${HOME}/Documents/gtd/deep_analysis_queue.jsonl"
      if [[ -f "$QUEUE_FILE" ]]; then
        queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null || echo "0")
        if [[ "$queue_count" -gt 0 ]]; then
          echo -e "  ${YELLOW}⚠️  $queue_count item(s) in queue${NC}"
        else
          echo -e "  ${GREEN}✅ Queue empty${NC}"
        fi
      else
        echo -e "  ${CYAN}ℹ️  No queue file${NC}"
      fi
      echo ""
      
      # Check results
      echo -e "${BOLD}Analysis Results:${NC}"
      RESULTS_DIR="${HOME}/Documents/gtd/deep_analysis_results"
      if [[ -d "$RESULTS_DIR" ]]; then
        result_count=$(find "$RESULTS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$result_count" -gt 0 ]]; then
          echo -e "  ${GREEN}✅ $result_count result(s)${NC}"
          latest=$(ls -t "$RESULTS_DIR"/*.json 2>/dev/null | head -1)
          if [[ -n "$latest" ]]; then
            echo "  Latest: $(basename "$latest")"
          fi
        else
          echo -e "  ${CYAN}ℹ️  No results yet${NC}"
        fi
      else
        echo -e "  ${CYAN}ℹ️  No results directory${NC}"
      fi
      ;;
    4)
      clear
      # Run full status check script if available
      STATUS_SCRIPT="$HOME/code/dotfiles/mcp/gtd_mcp_status.sh"
      if [[ ! -f "$STATUS_SCRIPT" ]]; then
        STATUS_SCRIPT="$HOME/code/personal/dotfiles/mcp/gtd_mcp_status.sh"
      fi
      
      if [[ -f "$STATUS_SCRIPT" ]]; then
        bash "$STATUS_SCRIPT"
      else
        echo ""
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${CYAN}📊 Full System Status${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Status script not found. Showing basic status instead..."
        echo ""
        
        # Show basic status
        local inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${BOLD}Inbox:${NC} ${inbox_count} item(s)"
        
        local projects_count=$(ls -1 ~/Documents/gtd/1-projects/*/README.md 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${BOLD}Active Projects:${NC} ${projects_count}"
        
        local tasks_count=$(find ~/Documents/gtd/tasks -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${BOLD}Active Tasks:${NC} ${tasks_count}"
      fi
      ;;
    5)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}☸️  Kubernetes Deployment Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      DEPLOY_SCRIPT="$HOME/code/dotfiles/mcp/deploy.sh"
      if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
        DEPLOY_SCRIPT="$HOME/code/personal/dotfiles/mcp/deploy.sh"
      fi
      
      if [[ -f "$DEPLOY_SCRIPT" ]]; then
        bash "$DEPLOY_SCRIPT" status
      else
        echo "❌ Deployment script not found"
        echo ""
        echo "Location checked: $DEPLOY_SCRIPT"
      fi
      ;;
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📋 Kubernetes Pod Logs (Debug)${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      if ! command -v kubectl &>/dev/null; then
        echo -e "${RED}❌ kubectl not found${NC}"
        echo ""
        echo "kubectl is required to view pod logs."
        echo "Install kubectl or ensure it's in your PATH."
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      # Check if we can connect to cluster
      if ! kubectl cluster-info &>/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Cannot connect to Kubernetes cluster${NC}"
        echo ""
        echo "Make sure:"
        echo "  1. kubectl is configured correctly"
        echo "  2. You have access to the cluster"
        echo "  3. KUBECONFIG is set (if needed)"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      # Show deployments and their pods
      echo -e "${BOLD}Deployments:${NC}"
      echo ""
      
      # Check for GTD worker deployment
      if kubectl get deployment gtd-deep-analysis-worker &>/dev/null 2>&1; then
        echo -e "${CYAN}GTD Deep Analysis Worker:${NC}"
        kubectl get deployment gtd-deep-analysis-worker -o wide
        echo ""
        
        # Get pods for this deployment
        pods=$(kubectl get pods -l app=gtd-deep-analysis-worker -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
        
        if [[ -n "$pods" ]]; then
          echo -e "${BOLD}Pods:${NC}"
          kubectl get pods -l app=gtd-deep-analysis-worker
          echo ""
          
          # Show pod status details
          for pod in $pods; do
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}Pod: ${CYAN}$pod${NC}"
            echo ""
            
            # Show pod status
            echo -e "${BOLD}Status:${NC}"
            kubectl get pod "$pod" -o jsonpath='{.status.phase}' 2>/dev/null
            echo ""
            
            # Check if pod is not ready
            ready=$(kubectl get pod "$pod" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
            if [[ "$ready" != "True" ]]; then
              echo -e "${YELLOW}⚠️  Pod is not ready${NC}"
              echo ""
              
              # Show conditions
              echo -e "${BOLD}Conditions:${NC}"
              kubectl get pod "$pod" -o jsonpath='{range .status.conditions[*]}{.type}: {.status} - {.message}{"\n"}{end}' 2>/dev/null
              echo ""
              
              # Show container statuses
              echo -e "${BOLD}Container Statuses:${NC}"
              kubectl get pod "$pod" -o jsonpath='{range .status.containerStatuses[*]}{.name}: {.state}{"\n"}{end}' 2>/dev/null
              echo ""
            fi
            
            # Show recent events
            echo -e "${BOLD}Recent Events:${NC}"
            kubectl get events --field-selector involvedObject.name="$pod" --sort-by='.lastTimestamp' | tail -10
            echo ""
            
            echo -n "View logs for this pod? (y/n): "
            read view_logs
            if [[ "$view_logs" == "y" || "$view_logs" == "Y" ]]; then
              echo ""
              echo -e "${BOLD}${CYAN}Logs for $pod:${NC}"
              echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
              echo ""
              
              # Show last 50 lines
              kubectl logs "$pod" --tail=50 2>&1 || echo "Could not retrieve logs"
              echo ""
              
              # If pod has multiple containers, show init container logs too
              init_containers=$(kubectl get pod "$pod" -o jsonpath='{.spec.initContainers[*].name}' 2>/dev/null)
              if [[ -n "$init_containers" ]]; then
                for container in $init_containers; do
                  echo -e "${CYAN}Init Container: $container${NC}"
                  kubectl logs "$pod" -c "$container" --tail=30 2>&1 || echo "Could not retrieve logs"
                  echo ""
                done
              fi
              
              echo ""
              echo -n "View more logs? (tail -f, y/n): "
              read follow_logs
              if [[ "$follow_logs" == "y" || "$follow_logs" == "Y" ]]; then
                echo ""
                echo "Following logs (Ctrl+C to stop)..."
                kubectl logs "$pod" -f 2>&1 || echo "Could not follow logs"
              fi
            fi
            echo ""
          done
        else
          echo -e "${YELLOW}⚠️  No pods found for this deployment${NC}"
          echo ""
          echo "This might mean:"
          echo "  - Deployment is still creating pods"
          echo "  - Pods failed to start"
          echo "  - Pods were deleted"
          echo ""
          
          # Show recent events for the deployment
          echo -e "${BOLD}Recent Events:${NC}"
          kubectl get events --field-selector involvedObject.kind=Deployment,involvedObject.name=gtd-deep-analysis-worker --sort-by='.lastTimestamp' | tail -20
        fi
      else
        echo -e "${CYAN}ℹ️  No GTD worker deployment found${NC}"
        echo ""
        echo "Available deployments:"
        kubectl get deployments 2>/dev/null | head -10
        echo ""
        echo "Would you like to view logs for a different deployment?"
        echo -n "Enter deployment name (or press Enter to skip): "
        read other_deployment
        if [[ -n "$other_deployment" ]]; then
          pods=$(kubectl get pods -l app="$other_deployment" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
          if [[ -z "$pods" ]]; then
            pods=$(kubectl get pods --selector="app=$other_deployment" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
          fi
          if [[ -n "$pods" ]]; then
            for pod in $pods; do
              echo ""
              echo -e "${BOLD}Logs for $pod:${NC}"
              kubectl logs "$pod" --tail=50 2>&1
            done
          else
            echo "No pods found for deployment: $other_deployment"
          fi
        fi
      fi
      
      echo ""
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      ;;
    *)
      # Default to basic status if invalid choice
      clear
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}${CYAN}📊 Basic GTD System Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      local inbox_count=$(ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Inbox:${NC} ${inbox_count} item(s)"
      
      local projects_count=$(ls -1 ~/Documents/gtd/1-projects/*/README.md 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Active Projects:${NC} ${projects_count}"
      
      local tasks_count=$(find ~/Documents/gtd/tasks -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${BOLD}Active Tasks:${NC} ${tasks_count}"
      ;;
    0|"")
      return 0
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}

goal_tracking_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 Goal Tracking${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_goal_tracking_guide
  echo -e "${BOLD}💡 Why Goals Matter${NC}"
  echo ""
  echo "Goals give your life direction and purpose. They help you:"
  echo "  • Focus your energy on what truly matters"
  echo "  • Make better decisions (does this move me toward my goal?)"
  echo "  • Track progress and celebrate wins"
  echo "  • Stay motivated when things get tough"
  echo "  • Turn your vision into actionable steps"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}📝 What Makes a Good Goal?${NC}"
  echo ""
  echo "Effective goals are:"
  echo "  • ${GREEN}Specific${NC} - Clear and well-defined (not vague)"
  echo "  • ${GREEN}Measurable${NC} - You can track progress"
  echo "  • ${GREEN}Achievable${NC} - Realistic but challenging"
  echo "  • ${GREEN}Relevant${NC} - Aligned with your values and vision"
  echo "  • ${GREEN}Time-bound${NC} - Has a deadline or target date"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}🎯 Examples of Good Goals${NC}"
  echo ""
  echo "  • 'Complete CKA certification by March 2025'"
  echo "  • 'Run a 5K race in under 30 minutes by June'"
  echo "  • 'Save \$5,000 for emergency fund by end of year'"
  echo "  • 'Read 24 books this year (2 per month)'"
  echo "  • 'Learn conversational Greek (basic conversations) by summer'"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}💭 Questions to Ask Yourself${NC}"
  echo ""
  echo "  • What do I want to achieve in the next 3-6 months?"
  echo "  • What would make me feel proud or accomplished?"
  echo "  • What's one area of my life I want to improve?"
  echo "  • What's something I've been putting off that matters?"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}What would you like to do?${NC}"
  echo ""
  echo "  1) Create a new goal"
  echo "  2) Update goal progress"
  echo "  3) View goal dashboard"
  echo "  4) List all goals"
  echo "  5) View goal details"
  echo "  6) Update goal properties (status, deadline, area, description)"
  echo "  7) Mark goal as complete"
  echo "  8) 💬 Restructure with natural language"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read goal_choice
  
  case "$goal_choice" in
    1)
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}📝 Create a New Goal${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "${BOLD}💡 Tips for Creating Your Goal:${NC}"
      echo ""
      echo "  • Be specific: 'Learn Spanish' → 'Have a 15-minute conversation in Spanish'"
      echo "  • Make it measurable: Include numbers, dates, or clear outcomes"
      echo "  • Set a deadline: This creates urgency and helps you plan"
      echo "  • Connect it to an area: Link it to what matters to you"
      echo "  • Write it down: The act of writing makes it more real"
      echo ""
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "${YELLOW}What do you want to achieve?${NC}"
      echo -e "${GREEN}Tip:${NC} Be specific! Instead of 'Get fit', try 'Run 3 miles without stopping'"
      echo ""
      read -p "Goal name: " goal_name
      if [[ -z "$goal_name" ]]; then
        echo "❌ Goal name required"
        echo ""
        echo "Press Enter to continue..."
        read
        goal_tracking_wizard
        return 0
      fi
      
      echo ""
      echo -e "${YELLOW}When do you want to achieve this?${NC}"
      echo -e "${GREEN}Tip:${NC} Set a realistic but challenging deadline (format: YYYY-MM-DD)"
      echo -e "${GREEN}Example:${NC} 2025-06-30"
      echo ""
      read -p "Deadline (YYYY-MM-DD, optional): " deadline
      
      echo ""
      echo -e "${YELLOW}What area of your life does this relate to?${NC}"
      echo ""
      
      # List available areas and let user select, or allow typing a new one
      area=""
      if [[ -d "$AREAS_PATH" ]] && [[ -n "$(find "$AREAS_PATH" -type f -name "*.md" 2>/dev/null)" ]]; then
        echo -e "${GREEN}Available areas:${NC}"
        echo ""
        # Source the select helper if available
        SELECT_HELPER="$HOME/code/dotfiles/bin/gtd-select-helper.sh"
        if [[ ! -f "$SELECT_HELPER" && -f "$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh" ]]; then
          SELECT_HELPER="$HOME/code/personal/dotfiles/bin/gtd-select-helper.sh"
        fi
        
        if [[ -f "$SELECT_HELPER" ]]; then
          source "$SELECT_HELPER"
          selected_area=$(select_from_list "area" "$AREAS_PATH" "name")
          if [[ -n "$selected_area" ]]; then
            # Find the actual area file to get the slug (filename)
            local area_file=$(find "$AREAS_PATH" -type f -name "*.md" 2>/dev/null | while read -r file; do
              local name=$(grep "^name:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || basename "$file" .md)
              if [[ "$name" == "$selected_area" ]]; then
                echo "$file"
                break
              fi
            done)
            
            if [[ -n "$area_file" ]]; then
              # Use the filename (without .md) as the area slug
              area=$(basename "$area_file" .md)
            else
              # Fallback: convert display name to slug format
              area=$(echo "$selected_area" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            fi
          fi
        else
          # Fallback: list areas manually
          local areas=($(find "$AREAS_PATH" -type f -name "*.md" 2>/dev/null | sort))
          local idx=1
          declare -a area_names
          for area_file in "${areas[@]}"; do
            # Try to get name from frontmatter first
            local area_name=$(grep "^name:" "$area_file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//')
            
            # If no name field, try to get from first heading (# Title)
            if [[ -z "$area_name" ]]; then
              area_name=$(grep "^# " "$area_file" 2>/dev/null | head -1 | sed 's/^# //' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            fi
            
            # Convert to readable format if it looks like a slug (contains - or &)
            # This handles both cases: when heading is a slug, or when we fall back to filename
            if [[ -z "$area_name" ]] || [[ "$area_name" =~ - ]] || [[ "$area_name" =~ "&" ]]; then
              if [[ -z "$area_name" ]]; then
                area_name=$(basename "$area_file" .md)
              fi
              # Convert slug to readable: work-&-career -> Work & Career
              # Replace - with space, handle & specially, then capitalize words
              area_name=$(echo "$area_name" | sed 's/-/ /g' | sed 's/ & / \& /g' | sed 's/^&/&/' | sed 's/&$/\&/' | awk '{
                for(i=1;i<=NF;i++){
                  word=$i
                  if(word != "&" && word != "&") {
                    $i=toupper(substr(word,1,1)) substr(word,2)
                  }
                }
                print
              }')
            fi
            
            area_names[$idx]="$area_name"
            echo "  ${idx}) $area_name"
            ((idx++))
          done
          echo ""
          echo -e "${GREEN}Or type a new area name (press Enter to skip):${NC}"
          read -p "Select area (number) or type new area: " area_input
          
          if [[ -n "$area_input" ]]; then
            if [[ "$area_input" =~ ^[0-9]+$ ]]; then
              # User selected a number - get the corresponding area file
              local selected_idx=$area_input
              if [[ $selected_idx -ge 1 && $selected_idx -lt $idx ]]; then
                local selected_display_name="${area_names[$selected_idx]}"
                # Find the actual area file to get the slug
                local area_file=$(find "$AREAS_PATH" -type f -name "*.md" 2>/dev/null | while read -r file; do
                  local name=$(grep "^name:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || basename "$file" .md)
                  if [[ "$name" == "$selected_display_name" ]]; then
                    echo "$file"
                    break
                  fi
                done)
                
                if [[ -n "$area_file" ]]; then
                  area=$(basename "$area_file" .md)
                else
                  # Fallback: convert display name to slug format
                  area=$(echo "$selected_display_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
                fi
              fi
            else
              # User typed a new area name - convert to slug format
              area=$(echo "$area_input" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            fi
          fi
        fi
      else
        echo -e "${GREEN}No areas found.${NC}"
        echo -e "${GREEN}Examples:${NC} Health, Career, Learning, Relationships, Finances, Hobbies"
        echo ""
        read -p "Area (optional, or press Enter to skip): " area_input
        if [[ -n "$area_input" ]]; then
          area=$(echo "$area_input" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
        fi
      fi
      
      echo ""
      echo -e "${YELLOW}Tell us more about this goal:${NC}"
      echo -e "${GREEN}Tip:${NC} Why is this important to you? What will success look like?"
      echo ""
      read -p "Description (optional): " description
      
      if command -v gtd-goal &>/dev/null; then
        gtd-goal create "$goal_name" ${deadline:+--deadline "$deadline"} ${area:+--area "$area"} ${description:+--description "$description"}
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-goal" ]]; then
        "$HOME/code/dotfiles/bin/gtd-goal" create "$goal_name" ${deadline:+--deadline "$deadline"} ${area:+--area "$area"} ${description:+--description "$description"}
      else
        echo "❌ gtd-goal command not found"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      goal_tracking_wizard
      ;;
    2)
      echo ""
      echo -n "Goal name: "
      read goal_name
      if [[ -z "$goal_name" ]]; then
        echo "❌ Goal name required"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo -n "Progress (0-100): "
      read progress
      if [[ -z "$progress" ]]; then
        echo "❌ Progress required"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo -n "Note (optional): "
      read note
      
      if command -v gtd-goal &>/dev/null; then
        gtd-goal progress "$goal_name" "$progress" "$note"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-goal" ]]; then
        "$HOME/code/dotfiles/bin/gtd-goal" progress "$goal_name" "$progress" "$note"
      else
        echo "❌ gtd-goal command not found"
      fi
      ;;
    3)
      echo ""
      if command -v gtd-goal &>/dev/null; then
        gtd-goal dashboard
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-goal" ]]; then
        "$HOME/code/dotfiles/bin/gtd-goal" dashboard
      else
        echo "❌ gtd-goal command not found"
      fi
      ;;
    4)
      echo ""
      if command -v gtd-goal &>/dev/null; then
        gtd-goal list
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-goal" ]]; then
        "$HOME/code/dotfiles/bin/gtd-goal" list
      else
        echo "❌ gtd-goal command not found"
      fi
      ;;
    5)
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}📋 View Goal Details${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -n "Goal name: "
      read goal_name
      if [[ -z "$goal_name" ]]; then
        echo "❌ Goal name required"
        echo ""
        echo "Press Enter to continue..."
        read
        goal_tracking_wizard
        return 0
      fi
      
      # Use MCP server to get goal details if available, otherwise use gtd-goal
      if command -v python3 &>/dev/null && [[ -f "$HOME/code/dotfiles/mcp/gtd_mcp_server.py" ]]; then
        MCP_PYTHON=$(gtd_get_mcp_python)
        if [[ -n "$MCP_PYTHON" ]]; then
          RESULT=$("$MCP_PYTHON" <<PYTHON_SCRIPT 2>/dev/null
import sys
import json
import asyncio
from pathlib import Path

mcp_dir = Path.home() / "code" / "dotfiles" / "mcp"
if mcp_dir.exists():
    sys.path.insert(0, str(mcp_dir))

try:
    from gtd_mcp_server import handle_call_tool
    
    result = asyncio.run(handle_call_tool(
        "get_goal_details",
        {"goal_name": "$goal_name"}
    ))
    
    if result and len(result) > 0:
        response_text = result[0].text if hasattr(result[0], 'text') else str(result[0])
        print(response_text)
    else:
        print(json.dumps({"error": "No response from MCP server"}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
PYTHON_SCRIPT
)
          
          # Parse and display nicely
          echo "$RESULT" | "$MCP_PYTHON" -c "
import sys
import json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        print(f\"❌ Error: {data['error']}\")
    else:
        print(f\"🎯 Goal: {data.get('name', 'Unknown')}\")
        print(f\"Status: {data.get('status', 'unknown')}\")
        print(f\"Progress: {data.get('progress', 0)}%\")
        if data.get('deadline'):
            print(f\"Deadline: {data['deadline']}\")
        if data.get('area'):
            print(f\"Area: {data['area']}\")
        if data.get('description'):
            print(f\"\\nDescription:\\n{data['description']}\")
        if data.get('content'):
            print(f\"\\n{data['content']}\")
except:
    print('Error parsing response')
" 2>/dev/null || echo "Error displaying goal details"
        fi
      fi
      
      # Fallback to viewing the file directly
      GOALS_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}/goals"
      goal_file="${GOALS_DIR}/${goal_name// /_}.md"
      if [[ -f "$goal_file" ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$goal_file"
        echo ""
      else
        echo "❌ Goal not found: $goal_name"
      fi
      echo ""
      echo "Press Enter to continue..."
      read
      goal_tracking_wizard
      ;;
    6)
      echo ""
      echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}✏️  Update Goal Properties${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -n "Goal name: "
      read goal_name
      if [[ -z "$goal_name" ]]; then
        echo "❌ Goal name required"
        echo ""
        echo "Press Enter to continue..."
        read
        goal_tracking_wizard
        return 0
      fi
      
      echo ""
      echo "What would you like to update? (leave blank to skip)"
      echo ""
      
      echo -n "Status (active/completed/on-hold): "
      read status
      
      echo -n "Deadline (YYYY-MM-DD): "
      read deadline
      
      echo -n "Area: "
      read area
      
      echo -n "Description: "
      read description
      
      # Use MCP server if available
      if command -v python3 &>/dev/null && [[ -f "$HOME/code/dotfiles/mcp/gtd_mcp_server.py" ]]; then
        MCP_PYTHON=$(gtd_get_mcp_python)
        if [[ -n "$MCP_PYTHON" ]]; then
          # Build update arguments
          UPDATE_ARGS="{\"goal_name\": \"$goal_name\""
          [[ -n "$status" ]] && UPDATE_ARGS="${UPDATE_ARGS}, \"status\": \"$status\""
          [[ -n "$deadline" ]] && UPDATE_ARGS="${UPDATE_ARGS}, \"deadline\": \"$deadline\""
          [[ -n "$area" ]] && UPDATE_ARGS="${UPDATE_ARGS}, \"area\": \"$area\""
          [[ -n "$description" ]] && UPDATE_ARGS="${UPDATE_ARGS}, \"description\": \"$description\""
          UPDATE_ARGS="${UPDATE_ARGS}}"
          
          RESULT=$("$MCP_PYTHON" <<PYTHON_SCRIPT 2>/dev/null
import sys
import json
import asyncio
from pathlib import Path

mcp_dir = Path.home() / "code" / "dotfiles" / "mcp"
if mcp_dir.exists():
    sys.path.insert(0, str(mcp_dir))

try:
    from gtd_mcp_server import handle_call_tool
    
    update_args = $UPDATE_ARGS
    
    result = asyncio.run(handle_call_tool(
        "update_goal",
        update_args
    ))
    
    if result and len(result) > 0:
        response_text = result[0].text if hasattr(result[0], 'text') else str(result[0])
        print(response_text)
    else:
        print(json.dumps({"error": "No response from MCP server"}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
PYTHON_SCRIPT
)
          
          echo "$RESULT" | "$MCP_PYTHON" -c "
import sys
import json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        print(f\"❌ Error: {data['error']}\")
    elif data.get('success'):
        print(f\"✓ {data.get('message', 'Goal updated')}\")
    else:
        print('Goal updated successfully')
except:
    print('Error parsing response')
" 2>/dev/null || echo "Error updating goal"
        fi
      else
        echo "⚠️  MCP server not available. Some updates may require direct file editing."
      fi
      
      echo ""
      echo "Press Enter to continue..."
      read
      goal_tracking_wizard
      ;;
    7)
      echo ""
      echo -n "Goal name: "
      read goal_name
      if [[ -z "$goal_name" ]]; then
        echo "❌ Goal name required"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      if command -v gtd-goal &>/dev/null; then
        gtd-goal complete "$goal_name"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-goal" ]]; then
        "$HOME/code/dotfiles/bin/gtd-goal" complete "$goal_name"
      else
        echo "❌ gtd-goal command not found"
      fi
      ;;
    8)
      echo ""
      echo -e "${BOLD}💬 Restructure Goal with Natural Language${NC}"
      echo ""
      # Load goals directory
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
      GOALS_DIR="${GOALS_DIR:-${GTD_BASE_DIR}/goals}"
      
      if [[ -d "$GOALS_DIR" ]] && [[ -n "$(find "$GOALS_DIR" -type f -name "*.md" 2>/dev/null)" ]]; then
        echo "Available goals:"
        local goal_count=0
        local goal_names=()
        local goal_files=()
        for goal_file in "$GOALS_DIR"/*.md; do
          [[ ! -f "$goal_file" ]] && continue
          local goal_name=$(grep "^name:" "$goal_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//')
          local goal_status=$(grep "^status:" "$goal_file" 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//')
          if [[ "$goal_status" == "active" ]]; then
            ((goal_count++))
            goal_names+=("$goal_name")
            goal_files+=("$goal_file")
            echo "  $goal_count) $goal_name"
          fi
        done
        
        echo ""
        echo -n "Goal number to restructure: "
        read goal_num
        
        if [[ "$goal_num" =~ ^[0-9]+$ ]] && [[ $goal_num -ge 1 && $goal_num -le ${#goal_names[@]} ]]; then
          local idx=$((goal_num - 1))
          local goal_name="${goal_names[$idx]}"
          local goal_slug=$(echo "$goal_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo ""
          echo -e "${CYAN}Example commands:${NC}"
          echo "  • \"Make this more prominent\""
          echo "  • \"Archive but keep searchable\""
          echo "  • \"Focus on this week\""
          echo "  • \"I'm done with this\""
          echo ""
          echo -n "What would you like to do with this goal? "
          read nl_command
          
          if [[ -z "$nl_command" ]]; then
            echo "❌ No command provided"
            echo "Press Enter to continue..."
            read
            return 0
          fi
          
          echo ""
          if command -v gtd-restructure &>/dev/null; then
            gtd-restructure --goal "$goal_slug" --command "$nl_command"
          elif [[ -f "$HOME/code/dotfiles/bin/gtd-restructure" ]]; then
            "$HOME/code/dotfiles/bin/gtd-restructure" --goal "$goal_slug" --command "$nl_command"
          else
            echo "❌ gtd-restructure command not found"
          fi
        else
          echo "❌ Invalid goal number"
        fi
      else
        echo "No goals found."
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
  
  echo ""
  echo "Press Enter to continue..."
  read
}

energy_audit_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚡ Energy Audit${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_energy_audit_guide
  echo "What would you like to do?"
  echo ""
  echo "  1) Log energy drain"
  echo "  2) Log energy boost"
  echo "  3) Analyze energy patterns"
  echo "  4) Generate energy report"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read energy_choice
  
  case "$energy_choice" in
    1)
      echo ""
      echo -n "Activity: "
      read activity
      if [[ -z "$activity" ]]; then
        echo "❌ Activity required"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo -n "Impact (-5 to -1, default -2): "
      read impact
      impact=${impact:--2}
      
      echo -n "Note (optional): "
      read note
      
      if command -v gtd-energy-audit &>/dev/null; then
        gtd-energy-audit log "$activity" drain "$impact" "$note"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-energy-audit" ]]; then
        "$HOME/code/dotfiles/bin/gtd-energy-audit" log "$activity" drain "$impact" "$note"
      else
        echo "❌ gtd-energy-audit command not found"
      fi
      ;;
    2)
      echo ""
      echo -n "Activity: "
      read activity
      if [[ -z "$activity" ]]; then
        echo "❌ Activity required"
        echo ""
        echo "Press Enter to continue..."
        read
        return 1
      fi
      
      echo -n "Impact (+1 to +5, default +2): "
      read impact
      impact=${impact:-+2}
      
      echo -n "Note (optional): "
      read note
      
      if command -v gtd-energy-audit &>/dev/null; then
        gtd-energy-audit log "$activity" boost "$impact" "$note"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-energy-audit" ]]; then
        "$HOME/code/dotfiles/bin/gtd-energy-audit" log "$activity" boost "$impact" "$note"
      else
        echo "❌ gtd-energy-audit command not found"
      fi
      ;;
    3)
      echo ""
      if command -v gtd-energy-audit &>/dev/null; then
        gtd-energy-audit analyze
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-energy-audit" ]]; then
        "$HOME/code/dotfiles/bin/gtd-energy-audit" analyze
      else
        echo "❌ gtd-energy-audit command not found"
      fi
      ;;
    4)
      echo ""
      echo -n "Days (default 30): "
      read days
      days=${days:-30}
      
      if command -v gtd-energy-audit &>/dev/null; then
        gtd-energy-audit report "$days"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-energy-audit" ]]; then
        "$HOME/code/dotfiles/bin/gtd-energy-audit" report "$days"
      else
        echo "❌ gtd-energy-audit command not found"
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

log_stats_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📈 Log Statistics & Streaks${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  if command -v gtd-log-stats &>/dev/null; then
    gtd-log-stats
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-stats" ]]; then
    "$HOME/code/dotfiles/bin/gtd-log-stats"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-stats" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-log-stats"
  else
    echo "❌ gtd-log-stats command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

metric_correlations_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔗 Metric Correlations${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_metric_correlations_guide
  if command -v gtd-metric-correlations &>/dev/null; then
    gtd-metric-correlations
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-metric-correlations" ]]; then
    "$HOME/code/dotfiles/bin/gtd-metric-correlations"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-metric-correlations" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-metric-correlations"
  else
    echo "❌ gtd-metric-correlations command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

pattern_recognition_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔍 Pattern Recognition${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_pattern_recognition_guide
  if command -v gtd-pattern-recognition &>/dev/null; then
    gtd-pattern-recognition
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-pattern-recognition" ]]; then
    "$HOME/code/dotfiles/bin/gtd-pattern-recognition"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-pattern-recognition" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-pattern-recognition"
  else
    echo "❌ gtd-pattern-recognition command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

weekly_progress_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Weekly Progress Report${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  if command -v gtd-weekly-progress &>/dev/null; then
    gtd-weekly-progress
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-weekly-progress" ]]; then
    "$HOME/code/dotfiles/bin/gtd-weekly-progress"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-weekly-progress" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-weekly-progress"
  else
    echo "❌ gtd-weekly-progress command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

success_metrics_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}📊 Success Metrics${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Tracking system usage and effectiveness..."
  echo ""
  
  if command -v gtd-success-metrics &>/dev/null; then
    gtd-success-metrics
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-success-metrics" ]]; then
    "$HOME/code/dotfiles/bin/gtd-success-metrics"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-success-metrics" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-success-metrics"
  else
    echo "❌ gtd-success-metrics command not found"
  fi
  
  echo ""
  echo "Press Enter to continue..."
  read
}

brain_metrics_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🧠 Second Brain Metrics${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  if command -v gtd-brain-metrics &>/dev/null; then
    gtd-brain-metrics
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-metrics" ]]; then
    "$HOME/code/dotfiles/bin/gtd-brain-metrics"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-metrics" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-brain-metrics"
  else
    echo "❌ gtd-brain-metrics command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

energy_schedule_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚡ Energy-Aware Scheduling${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_energy_schedule_guide
  if command -v gtd-energy-schedule &>/dev/null; then
    gtd-energy-schedule
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-energy-schedule" ]]; then
    "$HOME/code/dotfiles/bin/gtd-energy-schedule"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-energy-schedule" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-energy-schedule"
  else
    echo "❌ gtd-energy-schedule command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

now_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎯 What Should I Do Now?${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  if command -v gtd-now &>/dev/null; then
    gtd-now
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-now" ]]; then
    "$HOME/code/dotfiles/bin/gtd-now"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-now" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-now"
  else
    echo "❌ gtd-now command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

find_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔍 Find Items (Advanced Search)${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -n "Enter search term: "
  read search_term
  if [[ -z "$search_term" ]]; then
    echo "❌ No search term provided"
    echo ""
    echo "Press Enter to continue..."
    read
    return 1
  fi
  
  if command -v gtd-find &>/dev/null; then
    gtd-find "$search_term"
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-find" ]]; then
    "$HOME/code/dotfiles/bin/gtd-find" "$search_term"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-find" ]]; then
    "$HOME/code/personal/dotfiles/bin/gtd-find" "$search_term"
  else
    echo "❌ gtd-find command not found"
  fi
  echo ""
  echo "Press Enter to continue..."
  read
}

milestone_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🎉 Milestone Celebration${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # First, show current streak
  echo -e "${BOLD}📊 Current Status:${NC}"
  echo ""
  
  local streak_script=""
  local current_streak=0
  local next_milestone=""
  
  # Find streak script
  if command -v gtd-log-stats &>/dev/null; then
    streak_script="gtd-log-stats"
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/dotfiles/bin/gtd-log-stats"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/personal/dotfiles/bin/gtd-log-stats"
  fi
  
  # Get current streak
  if [[ -n "$streak_script" && -x "$streak_script" ]]; then
    current_streak=$("$streak_script" streak 2>/dev/null)
    # Clean up any whitespace
    current_streak=$(echo "$current_streak" | tr -d '[:space:]')
    # Ensure it's numeric
    if [[ ! "$current_streak" =~ ^[0-9]+$ ]]; then
      current_streak=0
    fi
  fi
  
  # Always show current streak (even if 0)
  echo "  Current logging streak: ${current_streak} day(s)"
  echo ""
  
  # Show upcoming milestones
  local milestones=(7 30 50 100 200 365)
  for milestone in "${milestones[@]}"; do
    if [[ $current_streak -lt $milestone ]]; then
      local days_away=$((milestone - current_streak))
      echo "  Next milestone: ${milestone} days (${days_away} day(s) away)"
      next_milestone="$milestone"
      break
    fi
  done
  
  if [[ -z "$next_milestone" && $current_streak -ge 365 ]]; then
    echo "  🎉 You've hit all major milestones! Amazing work!"
  elif [[ -z "$next_milestone" ]]; then
    echo "  💡 Keep logging daily to build your streak!"
  fi
  echo ""
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Checking for milestones to celebrate..."
  echo ""
  
  # Run milestone celebration
  local milestone_output=""
  local cmd_found=false
  
  if command -v gtd-milestone-celebration &>/dev/null; then
    milestone_output=$(gtd-milestone-celebration 2>&1)
    cmd_found=true
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-milestone-celebration" ]]; then
    milestone_output=$("$HOME/code/dotfiles/bin/gtd-milestone-celebration" 2>&1)
    # Check if it has meaningful content (more than just whitespace/newlines)
    if [[ ${#milestone_output} -gt 10 ]]; then
      echo "$milestone_output"
    else
      echo "💡 Start logging daily to begin building your streak!"
    fi
  fi
  
  echo ""
  echo "Press Enter to continue..."
  read
}

