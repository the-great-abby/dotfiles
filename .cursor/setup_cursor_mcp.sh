#!/bin/bash
# Setup script for Cursor MCP configuration
# 
# NOTE: Cursor can read MCP config from .cursor/mcp.json automatically!
# This script is only needed if you want to use global Cursor settings instead.

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check for mcp.json first (preferred), then mcp_config.json (legacy)
if [[ -f "$SCRIPT_DIR/mcp.json" ]]; then
    CONFIG_FILE="$SCRIPT_DIR/mcp.json"
elif [[ -f "$SCRIPT_DIR/mcp_config.json" ]]; then
    # Create mcp.json from mcp_config.json if it doesn't exist
    echo -e "${CYAN}Creating mcp.json from mcp_config.json...${NC}"
    cp "$SCRIPT_DIR/mcp_config.json" "$SCRIPT_DIR/mcp.json"
    CONFIG_FILE="$SCRIPT_DIR/mcp.json"
    echo -e "${GREEN}✓ Created .cursor/mcp.json${NC}"
    echo ""
else
    echo -e "${RED}❌ No MCP config file found in $SCRIPT_DIR${NC}"
    exit 1
fi

MCP_SERVER_PATH="$DOTFILES_DIR/mcp/gtd_mcp_server.py"

# Check if workspace config exists (inform user)
if [[ -f "$SCRIPT_DIR/mcp.json" ]]; then
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ℹ️  Workspace MCP Configuration Detected${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ Cursor can automatically use: .cursor/mcp.json${NC}"
    echo ""
    echo "Cursor will automatically detect and use the MCP configuration"
    echo "from .cursor/mcp.json when you open this workspace."
    echo ""
    echo "You don't need to run this script unless you want to use"
    echo "global Cursor settings instead of workspace settings."
    echo ""
    read -p "Continue with global setup anyway? (y/n): " continue_choice
    if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
        echo "Skipping global setup. Using workspace configuration."
        exit 0
    fi
    echo ""
fi

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

# Convert workspace-relative paths to absolute paths
if [[ -f "$CONFIG_FILE" ]]; then
    # Replace ${workspaceFolder} with actual path
    sed "s|\${workspaceFolder}|$DOTFILES_DIR|g" "$CONFIG_FILE" > "$TEMP_CONFIG"
    # Replace ${env:USER} with actual username
    CURRENT_USER=$(whoami)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|\${env:USER}|$CURRENT_USER|g" "$TEMP_CONFIG" 2>/dev/null || sed -i "s|\${env:USER}|$CURRENT_USER|g" "$TEMP_CONFIG"
    else
        sed -i "s|\${env:USER}|$CURRENT_USER|g" "$TEMP_CONFIG"
    fi
else
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    exit 1
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

