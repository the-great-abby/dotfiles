#!/bin/bash
# Test GTD Vector Database Connection
# Tests actual database connection with real credentials

set -e

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh" 2>/dev/null || {
  echo "Error: test_helpers.sh not found" >&2
  exit 1
}

# Source colors if available
if [[ -f "$SCRIPT_DIR/../bin/gtd-common.sh" ]]; then
  source "$SCRIPT_DIR/../bin/gtd-common.sh" 2>/dev/null || true
fi

# Find config directory
GTD_CONFIG_DIR="$HOME/code/dotfiles/zsh"
if [[ ! -d "$GTD_CONFIG_DIR" ]]; then
  GTD_CONFIG_DIR="$HOME/code/personal/dotfiles/zsh"
fi

# Load database config
if [[ -f "$GTD_CONFIG_DIR/.gtd_config_database" ]]; then
  source "$GTD_CONFIG_DIR/.gtd_config_database"
elif [[ -f "$HOME/.gtd_config_database" ]]; then
  source "$HOME/.gtd_config_database"
fi

# Default values
VECTOR_DB_HOST="${VECTOR_DB_HOST:-localhost}"
VECTOR_DB_PORT="${VECTOR_DB_PORT:-13003}"
VECTOR_DB_NAME="${VECTOR_DB_NAME:-gtd_organization_system}"
VECTOR_DB_USER="${VECTOR_DB_USER:-gtd_organization_system}"
VECTOR_DB_PASSWORD="${VECTOR_DB_PASSWORD:-gtd_organization_system}"

# Python script path
PYTHON_SCRIPT="$HOME/code/dotfiles/zsh/functions/gtd_vectorization.py"
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
  PYTHON_SCRIPT="$HOME/code/personal/dotfiles/zsh/functions/gtd_vectorization.py"
fi

test_init "GTD Vector Database Connection"

echo "Testing database connection with:"
echo "  Host: $VECTOR_DB_HOST"
echo "  Port: $VECTOR_DB_PORT"
echo "  Database: $VECTOR_DB_NAME"
echo "  User: $VECTOR_DB_USER"
echo ""

# Test 1: Check if Python script exists
test_assert_file_exists "$PYTHON_SCRIPT" "Python vectorization script should exist"

# Test 2: Test database connection
echo -n "  Testing: Database connection ... "
if python3 "$PYTHON_SCRIPT" test-connection 2>/dev/null; then
  echo -e "${TEST_PASS} PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${TEST_FAIL} FAIL"
  echo "    Error: Could not connect to database"
  echo "    Check:"
  echo "      - Database is running on $VECTOR_DB_HOST:$VECTOR_DB_PORT"
  echo "      - Credentials in .gtd_config_database are correct"
  echo "      - Database '$VECTOR_DB_NAME' exists"
  echo "      - User '$VECTOR_DB_USER' has access"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 3: Test schema initialization (if connection works)
if python3 "$PYTHON_SCRIPT" test-connection 2>/dev/null; then
  echo -n "  Testing: Schema initialization ... "
  if python3 "$PYTHON_SCRIPT" init-schema 2>/dev/null; then
    echo -e "${TEST_PASS} PASS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_FAIL} FAIL"
    echo "    Error: Could not initialize schema"
    echo "    Check: pgvector extension is installed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 4: Test config reading
echo -n "  Testing: Config file reading ... "
if [[ -f "$GTD_CONFIG_DIR/.gtd_config_database" ]] || [[ -f "$HOME/.gtd_config_database" ]]; then
  echo -e "${TEST_PASS} PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${TEST_FAIL} FAIL"
  echo "    Error: .gtd_config_database not found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 5: Test Python imports
echo -n "  Testing: Python dependencies ... "
if python3 -c "import psycopg2; import json; import urllib.request" 2>/dev/null; then
  echo -e "${TEST_PASS} PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${TEST_FAIL} FAIL"
  echo "    Error: Missing Python dependencies"
  echo "    Install with: pip install psycopg2-binary"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 6: Test embedding model config (if available)
if [[ -f "$GTD_CONFIG_DIR/.gtd_config_ai" ]] || [[ -f "$HOME/.gtd_config_ai" ]]; then
  echo -n "  Testing: Embedding model configuration ... "
  # Check if embedding model is configured
  if grep -q "LM_STUDIO_EMBEDDING_MODEL" "$GTD_CONFIG_DIR/.gtd_config_ai" 2>/dev/null || \
     grep -q "LM_STUDIO_EMBEDDING_MODEL" "$HOME/.gtd_config_ai" 2>/dev/null; then
    echo -e "${TEST_PASS} PASS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_FAIL} FAIL"
    echo "    Warning: LM_STUDIO_EMBEDDING_MODEL not configured"
    echo "    Add to .gtd_config_ai: LM_STUDIO_EMBEDDING_MODEL=\"nomic-embed-text-v2-moe-GGUF\""
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
fi

test_summary

# Additional diagnostic information
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Diagnostic Information:"
  echo ""
  
  # Check PostgreSQL connection
  echo "Testing PostgreSQL connection directly..."
  if command -v psql >/dev/null 2>&1; then
    export PGPASSWORD="$VECTOR_DB_PASSWORD"
    if psql -h "$VECTOR_DB_HOST" -p "$VECTOR_DB_PORT" -U "$VECTOR_DB_USER" -d "$VECTOR_DB_NAME" -c "SELECT version();" >/dev/null 2>&1; then
      echo "✓ Direct PostgreSQL connection successful"
    else
      echo "✗ Direct PostgreSQL connection failed"
      echo "  Try: psql -h $VECTOR_DB_HOST -p $VECTOR_DB_PORT -U $VECTOR_DB_USER -d $VECTOR_DB_NAME"
    fi
  else
    echo "ℹ psql not found, skipping direct connection test"
  fi
  
  # Check if pgvector extension is available
  if command -v psql >/dev/null 2>&1; then
    export PGPASSWORD="$VECTOR_DB_PASSWORD"
    if psql -h "$VECTOR_DB_HOST" -p "$VECTOR_DB_PORT" -U "$VECTOR_DB_USER" -d "$VECTOR_DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1; then
      echo "✓ pgvector extension available"
    else
      echo "✗ pgvector extension not available"
      echo "  Install with: CREATE EXTENSION vector;"
    fi
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

exit $((TESTS_FAILED > 0 ? 1 : 0))

