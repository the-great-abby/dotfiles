#!/bin/bash
# Quick check for MCP server connectivity in Cursor

echo "Testing MCP server connection..."
echo ""

# Check if we can import the MCP server module
if python3 -c "import sys; sys.path.insert(0, '.'); from gtd_mcp_server import GTD_BASE_DIR" 2>/dev/null; then
    echo "✅ MCP server module can be imported"
else
    echo "❌ Cannot import MCP server module"
    echo "   Check that gtd_mcp_server.py exists and has correct imports"
fi

# Check dependencies
echo ""
echo "Checking dependencies:"
python3 -c "import mcp" 2>/dev/null && echo "✅ mcp package installed" || echo "❌ mcp package missing (pip install mcp)"

# Check config
echo ""
echo "Checking configuration:"
if [[ -f "$HOME/.gtd_config" ]] || [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
    echo "✅ Config file found"
else
    echo "⚠️  Config file not found"
fi

# Test script syntax
echo ""
echo "Checking script syntax:"
if python3 -m py_compile mcp/gtd_mcp_server.py 2>/dev/null; then
    echo "✅ Script syntax is valid"
else
    echo "❌ Script has syntax errors"
fi

echo ""
echo "To check MCP status in Cursor:"
echo "1. Open Cursor"
echo "2. Look for MCP status indicator in status bar"
echo "3. Or ask AI: 'What pending suggestions do I have?'"
echo "4. Check Cursor DevTools (Help → Toggle Developer Tools) for MCP logs"

