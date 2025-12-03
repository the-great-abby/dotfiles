#!/bin/bash
# Setup script for GTD MCP Server

set -e

echo "🚀 Setting up GTD MCP Server..."

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "✓ Found Python $PYTHON_VERSION"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
pip3 install -r "$SCRIPT_DIR/requirements.txt" || {
    echo "⚠️  Failed to install some dependencies. Continuing anyway..."
}

# Make scripts executable
chmod +x "$SCRIPT_DIR/gtd_mcp_server.py"
chmod +x "$SCRIPT_DIR/gtd_auto_suggest.py"
chmod +x "$SCRIPT_DIR/gtd_deep_analysis_worker.py"

# Create necessary directories
GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
mkdir -p "$GTD_BASE_DIR/suggestions"
mkdir -p "$GTD_BASE_DIR/deep_analysis_results"

echo "✓ Created directories"

# Check for config file
if [[ ! -f "$HOME/.gtd_config" ]] && [[ ! -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
    echo ""
    echo "⚠️  No .gtd_config file found. Creating basic config..."
    cat > "$HOME/.gtd_config" <<EOF
# GTD Configuration for MCP Server
GTD_BASE_DIR="$HOME/Documents/gtd"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
LM_STUDIO_CHAT_MODEL="google/gemma-3-1b"
GTD_USER_NAME="${GTD_USER_NAME:-Abby}"
EOF
    echo "✓ Created $HOME/.gtd_config"
fi

# Test imports
echo ""
echo "🧪 Testing imports..."
python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
try:
    from gtd_mcp_server import GTD_BASE_DIR
    print('✓ gtd_mcp_server imports successfully')
except Exception as e:
    print(f'❌ Error importing gtd_mcp_server: {e}')
    sys.exit(1)
"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure MCP server in Cursor (see README.md)"
echo "2. Start LM Studio and load your model"
echo "3. (Optional) Set up RabbitMQ for background processing"
echo "4. Test with: python3 $SCRIPT_DIR/gtd_auto_suggest.py entry 'test entry'"

