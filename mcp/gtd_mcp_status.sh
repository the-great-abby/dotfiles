#!/bin/bash
# GTD MCP System Status Checker

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Load config files to get actual model names
# Priority order (later files override earlier ones):
# 1. daily_log_config - Base daily log settings
# 2. gtd_config - General GTD settings  
# 3. gtd_config_ai - AI-specific settings (highest priority)

# Find config files (check both home and dotfiles directories)
DAILY_LOG_CONFIG=""
GTD_CONFIG=""
GTD_AI_CONFIG=""

# Check home directory first, then dotfiles
for base_dir in "$HOME" "$HOME/code/dotfiles/zsh" "$HOME/code/personal/dotfiles/zsh"; do
  if [[ -z "$DAILY_LOG_CONFIG" && -f "$base_dir/.daily_log_config" ]]; then
    DAILY_LOG_CONFIG="$base_dir/.daily_log_config"
  fi
  if [[ -z "$GTD_CONFIG" && -f "$base_dir/.gtd_config" ]]; then
    GTD_CONFIG="$base_dir/.gtd_config"
  fi
  if [[ -z "$GTD_AI_CONFIG" && -f "$base_dir/.gtd_config_ai" ]]; then
    GTD_AI_CONFIG="$base_dir/.gtd_config_ai"
  fi
done

# Helper function to strip URL path components
strip_url_path() {
  local url="$1"
  # Remove trailing slash first
  url="${url%/}"
  # Remove /v1/chat/completions if present (with or without trailing slash)
  url="${url%/v1/chat/completions}"
  # Remove /v1 if present
  url="${url%/v1}"
  # Remove trailing slash again (in case /v1 had one)
  url="${url%/}"
  echo "$url"
}

# Helper function to read a value from a config file
read_config_value() {
  local config_file="$1"
  local key="$2"
  if [[ -f "$config_file" ]] && grep -q "^${key}=" "$config_file" 2>/dev/null; then
    local value=$(grep "^${key}=" "$config_file" | head -1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Remove surrounding quotes
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    # If value contains ${VAR:-default} syntax, extract the default value
    if echo "$value" | grep -q '\${.*:-.*}'; then
      # Extract the default value from ${VAR:-default} syntax
      value=$(echo "$value" | sed -E 's/\$\{[^:]*:-([^}]*)\}/\1/')
    fi
    echo "$value"
  fi
}

# Initialize with defaults
FAST_MODEL_NAME=""
DEEP_MODEL_NAME=""

# Get URLs from environment, but always strip path components first
# (environment variables might have /v1/chat/completions in them)
ENV_LM_STUDIO_URL="${LM_STUDIO_URL:-http://localhost:1234}"
ENV_DEEP_MODEL_URL="${GTD_DEEP_MODEL_URL:-$ENV_LM_STUDIO_URL}"

# Strip paths immediately
LM_STUDIO_URL=$(strip_url_path "$ENV_LM_STUDIO_URL")
DEEP_MODEL_URL=$(strip_url_path "$ENV_DEEP_MODEL_URL")

# Read configs in priority order (later ones override earlier ones)
# Always read from config files, don't rely on environment variables
# 1. daily_log_config (base)
if [[ -n "$DAILY_LOG_CONFIG" ]]; then
  local_fast_model=$(read_config_value "$DAILY_LOG_CONFIG" "LM_STUDIO_CHAT_MODEL")
  if [[ -n "$local_fast_model" ]]; then
    FAST_MODEL_NAME="$local_fast_model"
  fi
  local_url=$(read_config_value "$DAILY_LOG_CONFIG" "LM_STUDIO_URL")
  if [[ -n "$local_url" ]]; then
    LM_STUDIO_URL=$(strip_url_path "$local_url")
  fi
fi

# 2. gtd_config (general GTD settings, overrides daily_log_config)
if [[ -n "$GTD_CONFIG" ]]; then
  local_fast_model=$(read_config_value "$GTD_CONFIG" "LM_STUDIO_CHAT_MODEL")
  if [[ -n "$local_fast_model" ]]; then
    FAST_MODEL_NAME="$local_fast_model"
  fi
  local_deep_model=$(read_config_value "$GTD_CONFIG" "GTD_DEEP_MODEL_NAME")
  if [[ -n "$local_deep_model" ]]; then
    DEEP_MODEL_NAME="$local_deep_model"
  fi
  local_url=$(read_config_value "$GTD_CONFIG" "LM_STUDIO_URL")
  if [[ -n "$local_url" ]]; then
    LM_STUDIO_URL=$(strip_url_path "$local_url")
  fi
  local_deep_url=$(read_config_value "$GTD_CONFIG" "GTD_DEEP_MODEL_URL")
  if [[ -n "$local_deep_url" ]]; then
    DEEP_MODEL_URL=$(strip_url_path "$local_deep_url")
  fi
fi

# 3. gtd_config_ai (highest priority, overrides earlier ones)
if [[ -n "$GTD_AI_CONFIG" ]]; then
  local_fast_model=$(read_config_value "$GTD_AI_CONFIG" "LM_STUDIO_CHAT_MODEL")
  if [[ -n "$local_fast_model" ]]; then
    FAST_MODEL_NAME="$local_fast_model"
  fi
  local_deep_model=$(read_config_value "$GTD_AI_CONFIG" "GTD_DEEP_MODEL_NAME")
  if [[ -n "$local_deep_model" ]]; then
    DEEP_MODEL_NAME="$local_deep_model"
  fi
  local_url=$(read_config_value "$GTD_AI_CONFIG" "LM_STUDIO_URL")
  if [[ -n "$local_url" ]]; then
    LM_STUDIO_URL=$(strip_url_path "$local_url")
  fi
  local_deep_url=$(read_config_value "$GTD_AI_CONFIG" "GTD_DEEP_MODEL_URL")
  if [[ -n "$local_deep_url" ]]; then
    DEEP_MODEL_URL=$(strip_url_path "$local_deep_url")
  fi
fi

# Set defaults if not found
FAST_MODEL_NAME="${FAST_MODEL_NAME:-google/gemma-3-1b}"
DEEP_MODEL_NAME="${DEEP_MODEL_NAME:-gpt-oss-20b}"
LM_STUDIO_URL="${LM_STUDIO_URL:-http://localhost:1234}"
DEEP_MODEL_URL="${DEEP_MODEL_URL:-$LM_STUDIO_URL}"

echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}🔍 GTD MCP System Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check LM Studio (Fast Model)
echo -e "${BOLD}1. LM Studio (Fast Model - ${FAST_MODEL_NAME})${NC}"
if curl -s "${LM_STUDIO_URL}/v1/models" >/dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Running${NC}"
    models=$(curl -s "${LM_STUDIO_URL}/v1/models" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', 'unknown') for m in data.get('data', [])]))" 2>/dev/null || echo "unknown")
    echo -e "   Models loaded: ${CYAN}$models${NC}"
    # Check if configured model is loaded
    if echo "$models" | grep -qi "$(echo "$FAST_MODEL_NAME" | cut -d'/' -f2)"; then
        echo -e "   ${GREEN}✅ Configured model ($FAST_MODEL_NAME) appears to be loaded${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Configured model ($FAST_MODEL_NAME) may not be loaded${NC}"
    fi
else
    echo -e "   ${RED}❌ Not running${NC}"
    echo -e "   ${YELLOW}   → Start LM Studio and load a model${NC}"
fi
echo ""

# Check Deep Model
echo -e "${BOLD}2. Deep Model (${DEEP_MODEL_NAME})${NC}"
if [[ "$DEEP_MODEL_URL" != "$LM_STUDIO_URL" ]]; then
    if curl -s "${DEEP_MODEL_URL}/v1/models" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Running${NC}"
        deep_models=$(curl -s "${DEEP_MODEL_URL}/v1/models" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', 'unknown') for m in data.get('data', [])]))" 2>/dev/null || echo "unknown")
        echo -e "   Models loaded: ${CYAN}$deep_models${NC}"
        # Check if configured model is loaded
        if echo "$deep_models" | grep -qi "$(echo "$DEEP_MODEL_NAME" | cut -d'/' -f2)"; then
            echo -e "   ${GREEN}✅ Configured model ($DEEP_MODEL_NAME) appears to be loaded${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Configured model ($DEEP_MODEL_NAME) may not be loaded${NC}"
        fi
    else
        echo -e "   ${RED}❌ Not running${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  Using same URL as fast model${NC}"
    # Check if deep model is loaded in the same instance
    if curl -s "${LM_STUDIO_URL}/v1/models" >/dev/null 2>&1; then
        models=$(curl -s "${LM_STUDIO_URL}/v1/models" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', 'unknown') for m in data.get('data', [])]))" 2>/dev/null || echo "unknown")
        if echo "$models" | grep -qi "$(echo "$DEEP_MODEL_NAME" | cut -d'/' -f2)"; then
            echo -e "   ${GREEN}✅ Configured model ($DEEP_MODEL_NAME) appears to be loaded${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Configured model ($DEEP_MODEL_NAME) may not be loaded${NC}"
            echo -e "   ${CYAN}   (Note: LM Studio can only load one model at a time)${NC}"
        fi
    fi
fi
echo ""

# Check MCP Server (in Cursor)
echo -e "${BOLD}3. MCP Server (in Cursor)${NC}"
echo -e "   ${CYAN}ℹ️  Status must be checked in Cursor${NC}"
echo -e "   ${YELLOW}   → Check Cursor MCP status indicator${NC}"
echo -e "   ${YELLOW}   → Try asking AI: 'What pending suggestions do I have?'${NC}"
echo ""

# Check Python dependencies
echo -e "${BOLD}4. Python Dependencies${NC}"
if python3 -c "import mcp" 2>/dev/null; then
    echo -e "   ${GREEN}✅ MCP SDK installed${NC}"
else
    echo -e "   ${RED}❌ MCP SDK not installed${NC}"
    echo -e "   ${YELLOW}   → Run: pip3 install mcp${NC}"
fi

if python3 -c "import pika" 2>/dev/null; then
    echo -e "   ${GREEN}✅ RabbitMQ client (pika) installed${NC}"
else
    echo -e "   ${YELLOW}⚠️  RabbitMQ client (pika) not installed (optional)${NC}"
fi
echo ""

# Check Background Worker (local file queue)
echo -e "${BOLD}5. Background Worker (Local)${NC}"
QUEUE_FILE="${HOME}/Documents/gtd/deep_analysis_queue.jsonl"
if [[ -f "$QUEUE_FILE" ]]; then
    queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null || echo "0")
    if [[ "$queue_count" -gt 0 ]]; then
        echo -e "   ${YELLOW}⚠️  $queue_count item(s) in queue (waiting to process)${NC}"
    else
        echo -e "   ${GREEN}✅ Queue empty${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  No queue file (worker hasn't run yet)${NC}"
fi

# Check if worker process is running locally
if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
    echo -e "   ${GREEN}✅ Worker process running locally${NC}"
else
    echo -e "   ${CYAN}ℹ️  Worker not running locally${NC}"
    echo -e "   ${YELLOW}   → Start with: python3 mcp/gtd_deep_analysis_worker.py file${NC}"
fi
echo ""

# Check Background Worker (Kubernetes)
echo -e "${BOLD}6. Background Worker (Kubernetes)${NC}"
if command -v kubectl &>/dev/null; then
    if kubectl get deployment gtd-deep-analysis-worker 2>/dev/null | grep -q "gtd-deep-analysis-worker"; then
        status=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        replicas=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        desired=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [[ "$status" == "True" && "$replicas" == "$desired" && "$replicas" -gt 0 ]]; then
            echo -e "   ${GREEN}✅ Running ($replicas/$desired replicas)${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Deployment exists but not fully ready${NC}"
        fi
    else
        echo -e "   ${CYAN}ℹ️  Not deployed to Kubernetes${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  kubectl not available${NC}"
fi
echo ""

# Check RabbitMQ
echo -e "${BOLD}7. RabbitMQ${NC}"
RABBITMQ_URL="${GTD_RABBITMQ_URL:-amqp://localhost:5672}"
if command -v rabbitmqctl &>/dev/null; then
    if rabbitmqctl status >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ RabbitMQ server running${NC}"
        queue_exists=$(rabbitmqctl list_queues name 2>/dev/null | grep -q "gtd_deep_analysis" && echo "yes" || echo "no")
        if [[ "$queue_exists" == "yes" ]]; then
            echo -e "   ${GREEN}✅ Queue 'gtd_deep_analysis' exists${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Queue 'gtd_deep_analysis' not found${NC}"
        fi
    else
        echo -e "   ${RED}❌ RabbitMQ server not running${NC}"
    fi
elif kubectl get svc rabbitmq 2>/dev/null | grep -q "rabbitmq"; then
    echo -e "   ${GREEN}✅ RabbitMQ service exists in Kubernetes${NC}"
else
    echo -e "   ${CYAN}ℹ️  RabbitMQ not configured (using file queue instead)${NC}"
fi
echo ""

# Check Results Directory
echo -e "${BOLD}8. Analysis Results${NC}"
RESULTS_DIR="${HOME}/Documents/gtd/deep_analysis_results"
if [[ -d "$RESULTS_DIR" ]]; then
    result_count=$(find "$RESULTS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$result_count" -gt 0 ]]; then
        latest=$(ls -t "$RESULTS_DIR"/*.json 2>/dev/null | head -1)
        latest_name=$(basename "$latest" 2>/dev/null || echo "")
        echo -e "   ${GREEN}✅ $result_count result(s) saved${NC}"
        if [[ -n "$latest_name" ]]; then
            echo -e "   ${CYAN}   Latest: $latest_name${NC}"
        fi
    else
        echo -e "   ${CYAN}ℹ️  No results yet${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  Results directory doesn't exist yet${NC}"
fi
echo ""

# Check Pending Suggestions
echo -e "${BOLD}9. Pending Suggestions${NC}"
SUGGESTIONS_DIR="${HOME}/Documents/gtd/suggestions"
if [[ -d "$SUGGESTIONS_DIR" ]]; then
    pending_count=$(find "$SUGGESTIONS_DIR" -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$pending_count" -gt 0 ]]; then
        echo -e "   ${YELLOW}⚠️  $pending_count pending suggestion(s)${NC}"
        echo -e "   ${CYAN}   → Review with: gtd-wizard → 23 → 2${NC}"
    else
        echo -e "   ${GREEN}✅ No pending suggestions${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  No suggestions directory yet${NC}"
fi
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

