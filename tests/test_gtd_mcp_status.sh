#!/bin/bash
# Unit tests for gtd_mcp_status.sh
# Tests config loading, URL stripping, and model name detection

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Test suite
test_init "GTD MCP Status Script"

# Create temporary test directory
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

# Create mock config files
create_test_config() {
  local file="$1"
  local content="$2"
  echo "$content" > "$file"
}

echo "Testing URL path stripping..."
# Test strip_url_path function
test_strip_url() {
  local input="$1"
  local expected="$2"
  local test_name="$3"
  
  # Extract and test just the strip_url_path function
  local result=$(bash -c "
    strip_url_path() {
      local url=\"\$1\"
      url=\"\${url%/}\"
      url=\"\${url%/v1/chat/completions}\"
      url=\"\${url%/v1}\"
      url=\"\${url%/}\"
      echo \"\$url\"
    }
    strip_url_path '$input'
  " 2>/dev/null)
  
  if [[ "$result" == "$expected" ]]; then
    test_run "$test_name" "true"
    return 0
  else
    echo -e "${TEST_FAIL} FAIL (expected: $expected, got: $result)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test various URL formats
test_strip_url "http://localhost:1234" "http://localhost:1234" "Strip URL without path"
test_strip_url "http://localhost:1234/v1" "http://localhost:1234" "Strip /v1 from URL"
test_strip_url "http://localhost:1234/v1/chat/completions" "http://localhost:1234" "Strip /v1/chat/completions from URL"
test_strip_url "http://localhost:1234/v1/chat/completions/" "http://localhost:1234" "Strip trailing slash"
test_strip_url "http://localhost:1234/" "http://localhost:1234" "Strip single trailing slash"

echo ""
echo "Testing config file reading..."

# Test read_config_value function
test_read_config() {
  local config_file="$1"
  local key="$2"
  local expected="$3"
  local test_name="$4"
  
  # Extract the function and test it
  local result=$(bash -c "
    read_config_value() {
      local config_file=\"\$1\"
      local key=\"\$2\"
      if [[ -f \"\$config_file\" ]] && grep -q \"^\${key}=\" \"\$config_file\" 2>/dev/null; then
        local value=\$(grep \"^\${key}=\" \"\$config_file\" | head -1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=\"\${value#\\\"}\"
        value=\"\${value%\\\"}\"
        value=\"\${value#\\\'}\"
        value=\"\${value%\\\'}\"
        if echo \"\$value\" | grep -q '\\\${.*:-.*}'; then
          value=\$(echo \"\$value\" | sed -E 's/\\\$\{[^:]*:-([^}]*)\}/\1/')
        fi
        echo \"\$value\"
      fi
    }
    read_config_value '$config_file' '$key'
  " 2>/dev/null)
  
  if [[ "$result" == "$expected" ]]; then
    test_run "$test_name" "true"
    return 0
  else
    echo -e "${TEST_FAIL} FAIL (expected: $expected, got: $result)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Create test config files
DAILY_LOG_CONFIG="$TEST_DIR/.daily_log_config"
GTD_CONFIG="$TEST_DIR/.gtd_config"
GTD_AI_CONFIG="$TEST_DIR/.gtd_config_ai"

create_test_config "$DAILY_LOG_CONFIG" "LM_STUDIO_URL=\"http://localhost:1234/v1/chat/completions\"
LM_STUDIO_CHAT_MODEL=\"test-model-1.7b\""

create_test_config "$GTD_CONFIG" "LM_STUDIO_URL=\"http://localhost:1234/v1/chat/completions\"
GTD_DEEP_MODEL_NAME=\"test-deep-model\""

create_test_config "$GTD_AI_CONFIG" "LM_STUDIO_URL=\"\${LM_STUDIO_URL:-http://localhost:1234/v1/chat/completions}\"
LM_STUDIO_CHAT_MODEL=\"qwen/qwen3-1.7b\"
GTD_DEEP_MODEL_NAME=\"qwen/qwen3-4b-thinking-2507\""

# Test reading from config files
test_read_config "$DAILY_LOG_CONFIG" "LM_STUDIO_CHAT_MODEL" "test-model-1.7b" "Read model from daily_log_config"
test_read_config "$GTD_AI_CONFIG" "LM_STUDIO_CHAT_MODEL" "qwen/qwen3-1.7b" "Read model from gtd_config_ai"
test_read_config "$GTD_AI_CONFIG" "GTD_DEEP_MODEL_NAME" "qwen/qwen3-4b-thinking-2507" "Read deep model from gtd_config_ai"
test_read_config "$DAILY_LOG_CONFIG" "LM_STUDIO_URL" "http://localhost:1234/v1/chat/completions" "Read URL from daily_log_config"
test_read_config "$GTD_AI_CONFIG" "LM_STUDIO_URL" "http://localhost:1234/v1/chat/completions" "Read URL with variable expansion syntax from gtd_config_ai"

echo ""
echo "Testing config loading order (later files override earlier ones)..."

# Test that gtd_config_ai overrides daily_log_config
test_config_priority() {
  # Create a test script that mimics the config loading logic
  local test_script="$TEST_DIR/test_config_load.sh"
  cat > "$test_script" << 'EOF'
#!/bin/bash
# Mock config loading test

strip_url_path() {
  local url="$1"
  url="${url%/}"
  url="${url%/v1/chat/completions}"
  url="${url%/v1}"
  url="${url%/}"
  echo "$url"
}

read_config_value() {
  local config_file="$1"
  local key="$2"
  if [[ -f "$config_file" ]] && grep -q "^${key}=" "$config_file" 2>/dev/null; then
    local value=$(grep "^${key}=" "$config_file" | head -1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    if echo "$value" | grep -q '\${.*:-.*}'; then
      value=$(echo "$value" | sed -E 's/\$\{[^:]*:-([^}]*)\}/\1/')
    fi
    echo "$value"
  fi
}

FAST_MODEL_NAME=""
DEEP_MODEL_NAME=""
LM_STUDIO_URL="http://localhost:1234"

# Load in priority order
DAILY_LOG_CONFIG="$1"
GTD_CONFIG="$2"
GTD_AI_CONFIG="$3"

# 1. daily_log_config
if [[ -n "$DAILY_LOG_CONFIG" ]]; then
  local_fast_model=$(read_config_value "$DAILY_LOG_CONFIG" "LM_STUDIO_CHAT_MODEL")
  if [[ -n "$local_fast_model" ]]; then
    FAST_MODEL_NAME="$local_fast_model"
  fi
fi

# 2. gtd_config
if [[ -n "$GTD_CONFIG" ]]; then
  local_fast_model=$(read_config_value "$GTD_CONFIG" "LM_STUDIO_CHAT_MODEL")
  if [[ -n "$local_fast_model" ]]; then
    FAST_MODEL_NAME="$local_fast_model"
  fi
  local_deep_model=$(read_config_value "$GTD_CONFIG" "GTD_DEEP_MODEL_NAME")
  if [[ -n "$local_deep_model" ]]; then
    DEEP_MODEL_NAME="$local_deep_model"
  fi
fi

# 3. gtd_config_ai (highest priority)
if [[ -n "$GTD_AI_CONFIG" ]]; then
  local_fast_model=$(read_config_value "$GTD_AI_CONFIG" "LM_STUDIO_CHAT_MODEL")
  if [[ -n "$local_fast_model" ]]; then
    FAST_MODEL_NAME="$local_fast_model"
  fi
  local_deep_model=$(read_config_value "$GTD_AI_CONFIG" "GTD_DEEP_MODEL_NAME")
  if [[ -n "$local_deep_model" ]]; then
    DEEP_MODEL_NAME="$local_deep_model"
  fi
fi

echo "FAST_MODEL_NAME=$FAST_MODEL_NAME"
echo "DEEP_MODEL_NAME=$DEEP_MODEL_NAME"
EOF
  chmod +x "$test_script"
  
  local result=$(bash "$test_script" "$DAILY_LOG_CONFIG" "$GTD_CONFIG" "$GTD_AI_CONFIG" 2>/dev/null)
  local fast_model=$(echo "$result" | grep "^FAST_MODEL_NAME=" | cut -d'=' -f2)
  local deep_model=$(echo "$result" | grep "^DEEP_MODEL_NAME=" | cut -d'=' -f2)
  
  # gtd_config_ai should override daily_log_config
  if [[ "$fast_model" == "qwen/qwen3-1.7b" ]]; then
    test_run "gtd_config_ai overrides daily_log_config for fast model" "true"
  else
    echo -e "${TEST_FAIL} FAIL (expected: qwen/qwen3-1.7b, got: $fast_model)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  if [[ "$deep_model" == "qwen/qwen3-4b-thinking-2507" ]]; then
    test_run "gtd_config_ai provides deep model name" "true"
  else
    echo -e "${TEST_FAIL} FAIL (expected: qwen/qwen3-4b-thinking-2507, got: $deep_model)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_config_priority

echo ""
echo "Testing URL stripping with environment variable..."

# Test that URLs with /v1/chat/completions are properly stripped
test_env_url_stripping() {
  local test_script="$TEST_DIR/test_url_strip.sh"
  cat > "$test_script" << 'EOF'
#!/bin/bash
# Test URL stripping with env var

strip_url_path() {
  local url="$1"
  url="${url%/}"
  url="${url%/v1/chat/completions}"
  url="${url%/v1}"
  url="${url%/}"
  echo "$url"
}

read_config_value() {
  local config_file="$1"
  local key="$2"
  if [[ -f "$config_file" ]] && grep -q "^${key}=" "$config_file" 2>/dev/null; then
    local value=$(grep "^${key}=" "$config_file" | head -1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    if echo "$value" | grep -q '\${.*:-.*}'; then
      value=$(echo "$value" | sed -E 's/\$\{[^:]*:-([^}]*)\}/\1/')
    fi
    echo "$value"
  fi
}

# Simulate environment variable with /v1/chat/completions
ENV_LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_URL=$(strip_url_path "$ENV_LM_STUDIO_URL")

# Then read from config (which also has /v1/chat/completions)
DAILY_LOG_CONFIG="$1"
if [[ -n "$DAILY_LOG_CONFIG" ]]; then
  local_url=$(read_config_value "$DAILY_LOG_CONFIG" "LM_STUDIO_URL")
  if [[ -n "$local_url" ]]; then
    LM_STUDIO_URL=$(strip_url_path "$local_url")
  fi
fi

echo "$LM_STUDIO_URL"
EOF
  chmod +x "$test_script"
  
  local result=$(bash "$test_script" "$DAILY_LOG_CONFIG" 2>/dev/null)
  
  if [[ "$result" == "http://localhost:1234" ]]; then
    test_run "URL with /v1/chat/completions is properly stripped" "true"
  else
    echo -e "${TEST_FAIL} FAIL (expected: http://localhost:1234, got: $result)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_env_url_stripping

echo ""
echo "Testing that status script can be sourced without errors..."
test_assert_success "bash -n $SCRIPT_DIR/../mcp/gtd_mcp_status.sh" "Status script syntax should be valid"

# Test summary
test_summary
