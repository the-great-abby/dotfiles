#!/bin/bash
# Setup script for Cursor MCP configuration

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/mcp_config.json"
MCP_SERVER_PATH="$DOTFILES_DIR/mcp/gtd_mcp_server.py"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔧 Setting up Cursor MCP Configuration${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Check if MCP server exists
if [[ ! -f "$MCP_SERVER_PATH" ]]; then
    echo -e "${YELLOW}⚠️  MCP server not found: $MCP_SERVER_PATH${NC}"
    echo "   Continuing anyway..."
fi

# Detect OS and set Cursor config path
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings"
    CURSOR_CONFIG_FILE="$CURSOR_CONFIG_DIR/cline_mcp_settings.json"
    echo -e "${CYAN}Detected OS: macOS${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    CURSOR_CONFIG_DIR="$HOME/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings"
    CURSOR_CONFIG_FILE="$CURSOR_CONFIG_DIR/cline_mcp_settings.json"
    echo -e "${CYAN}Detected OS: Linux${NC}"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    CURSOR_CONFIG_DIR="$APPDATA/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings"
    CURSOR_CONFIG_FILE="$CURSOR_CONFIG_DIR/cline_mcp_settings.json"
    echo -e "${CYAN}Detected OS: Windows${NC}"
else
    echo -e "${RED}❌ Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo "Cursor config directory: $CURSOR_CONFIG_DIR"
echo ""

# Create directory if it doesn't exist
mkdir -p "$CURSOR_CONFIG_DIR"

# Check if config already exists
if [[ -f "$CURSOR_CONFIG_FILE" ]]; then
    echo -e "${YELLOW}⚠️  Cursor MCP config already exists:${NC}"
    echo "   $CURSOR_CONFIG_FILE"
    echo ""
    read -p "Backup existing config and continue? (y/n): " backup_choice
    if [[ "$backup_choice" == "y" || "$backup_choice" == "Y" ]]; then
        BACKUP_FILE="${CURSOR_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CURSOR_CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backed up to: $BACKUP_FILE${NC}"
    else
        echo "Aborted."
        exit 0
    fi
fi

# Update paths in the config
echo -e "${CYAN}Updating paths in config...${NC}"

# Create a temporary config with updated paths
TEMP_CONFIG=$(mktemp)
sed "s|/Users/abby/code/dotfiles|$DOTFILES_DIR|g" "$CONFIG_FILE" > "$TEMP_CONFIG"

# If on macOS, use the updated config
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Also update user name if needed
    CURRENT_USER=$(whoami)
    sed -i '' "s|\"Abby\"|\"$CURRENT_USER\"|g" "$TEMP_CONFIG" 2>/dev/null || sed -i "s|\"Abby\"|\"$CURRENT_USER\"|g" "$TEMP_CONFIG"
fi

# Copy to Cursor config location
cp "$TEMP_CONFIG" "$CURSOR_CONFIG_FILE"
rm "$TEMP_CONFIG"

echo -e "${GREEN}✓ Config copied to Cursor settings${NC}"
echo ""

# Verify installation
echo -e "${CYAN}Verifying installation...${NC}"

# Check Python
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}❌ python3 not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python3 found${NC}"

# Check MCP dependencies
if python3 -c "import mcp" 2>/dev/null; then
    echo -e "${GREEN}✓ MCP SDK installed${NC}"
else
    echo -e "${YELLOW}⚠️  MCP SDK not installed${NC}"
    echo "   Run: pip3 install mcp"
fi

# Check MCP server file
if [[ -f "$MCP_SERVER_PATH" ]]; then
    echo -e "${GREEN}✓ MCP server script found${NC}"
else
    echo -e "${YELLOW}⚠️  MCP server script not found: $MCP_SERVER_PATH${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Cursor"
echo "  2. Check MCP status indicator in Cursor"
echo "  3. Ask the AI: 'What MCP tools are available?'"
echo ""
echo "Config file location:"
echo "  $CURSOR_CONFIG_FILE"
echo ""

