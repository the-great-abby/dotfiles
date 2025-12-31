#!/bin/bash
# Configure GTD Wizard Web Interface for Tailscale mobile access

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

GTD_BASE="${HOME}/code/dotfiles"
if [[ ! -d "$GTD_BASE" ]]; then
    GTD_BASE="${HOME}/code/personal/dotfiles"
fi

if [[ ! -d "$GTD_BASE" ]]; then
    echo -e "${RED}Error: GTD base directory not found${NC}"
    exit 1
fi

echo -e "${BLUE}🧙 Configuring GTD Wizard for Tailscale Mobile Access${NC}"
echo ""

# Get Tailscale domain
TAILSCALE_DOMAIN="${1:-abbys-macbook-air.tailf0befd.ts.net}"

if [[ -z "$TAILSCALE_DOMAIN" ]]; then
    echo -e "${YELLOW}Usage: $0 [tailscale-domain]${NC}"
    echo "Example: $0 abbys-macbook-air.tailf0befd.ts.net"
    exit 1
fi

echo -e "${GREEN}✓ Using Tailscale domain: ${TAILSCALE_DOMAIN}${NC}"
echo ""

# Step 1: Update launchd plist with environment variable
PLIST_FILE="${HOME}/Library/LaunchAgents/com.gtd.wizard-api.plist"
if [[ -f "$PLIST_FILE" ]]; then
    echo -e "${YELLOW}Step 1: Updating launchd service configuration...${NC}"
    
    # Check if environment variable is already set
    if grep -q "GTD_TAILSCALE_DOMAIN" "$PLIST_FILE"; then
        # Update existing value
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS sed
            sed -i '' "s|<string>GTD_TAILSCALE_DOMAIN</string>.*</string>|<string>GTD_TAILSCALE_DOMAIN</string><string>${TAILSCALE_DOMAIN}</string>|g" "$PLIST_FILE" || true
        else
            sed -i "s|<string>GTD_TAILSCALE_DOMAIN</string>.*</string>|<string>GTD_TAILSCALE_DOMAIN</string><string>${TAILSCALE_DOMAIN}</string>|g" "$PLIST_FILE" || true
        fi
    else
        # Add environment variable to plist
        # Find the EnvironmentVariables dict and add the key
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - use a Python script to properly modify XML
            python3 <<PYTHON_SCRIPT
import plistlib
import sys

plist_path = "$PLIST_FILE"
domain = "$TAILSCALE_DOMAIN"

try:
    with open(plist_path, 'rb') as f:
        plist = plistlib.load(f)
    
    if 'EnvironmentVariables' not in plist:
        plist['EnvironmentVariables'] = {}
    
    plist['EnvironmentVariables']['GTD_TAILSCALE_DOMAIN'] = domain
    
    with open(plist_path, 'wb') as f:
        plistlib.dump(plist, f)
    
    print("✓ Updated plist file")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
PYTHON_SCRIPT
        else
            echo -e "${YELLOW}⚠ Please manually add GTD_TAILSCALE_DOMAIN=${TAILSCALE_DOMAIN} to ${PLIST_FILE}${NC}"
        fi
    fi
    
    # Reload the service
    if launchctl list | grep -q "com.gtd.wizard-api"; then
        echo "Reloading service..."
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        launchctl load "$PLIST_FILE" 2>/dev/null || true
        launchctl start com.gtd.wizard-api 2>/dev/null || true
        echo -e "${GREEN}✓ Service reloaded${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Launchd plist not found. Run deploy-launchd.sh first.${NC}"
fi
echo ""

# Step 2: Update nginx configuration
echo -e "${YELLOW}Step 2: Updating nginx configuration...${NC}"

NGINX_CONFIG_DIR="/opt/homebrew/etc/nginx"
if [[ ! -d "$NGINX_CONFIG_DIR" ]]; then
    NGINX_CONFIG_DIR="/usr/local/etc/nginx"
fi

NGINX_CONFIG=""
if [[ -d "$NGINX_CONFIG_DIR" ]]; then
    # Check for config in servers or conf.d
    if [[ -d "${NGINX_CONFIG_DIR}/servers" ]]; then
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/servers/gtd-wizard.conf"
    elif [[ -d "${NGINX_CONFIG_DIR}/conf.d" ]]; then
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/conf.d/gtd-wizard.conf"
    else
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/gtd-wizard.conf"
    fi
    
    if [[ -f "$NGINX_CONFIG" ]]; then
        # Update server_name to include Tailscale domain
        if ! grep -q "$TAILSCALE_DOMAIN" "$NGINX_CONFIG"; then
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s|server_name.*;|server_name localhost ${TAILSCALE_DOMAIN};|g" "$NGINX_CONFIG"
            else
                sed -i "s|server_name.*;|server_name localhost ${TAILSCALE_DOMAIN};|g" "$NGINX_CONFIG"
            fi
            echo -e "${GREEN}✓ Updated nginx configuration${NC}"
            
            # Test and reload nginx
            if nginx -t 2>/dev/null; then
                if brew services restart nginx 2>/dev/null || sudo nginx -s reload 2>/dev/null; then
                    echo -e "${GREEN}✓ Nginx reloaded${NC}"
                else
                    echo -e "${YELLOW}⚠ Please restart nginx manually: brew services restart nginx${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ Nginx configuration test failed. Please check: $NGINX_CONFIG${NC}"
            fi
        else
            echo -e "${GREEN}✓ Tailscale domain already in nginx config${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Nginx config not found. Run deploy-launchd.sh first.${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Nginx config directory not found${NC}"
fi
echo ""

# Step 3: Show access information
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Configuration complete!${NC}"
echo ""
echo -e "${BLUE}📱 Mobile Access URLs:${NC}"
echo "  • http://${TAILSCALE_DOMAIN}:8080"
echo ""
echo -e "${BLUE}💻 Local Access URLs:${NC}"
echo "  • http://localhost:8080"
echo "  • http://localhost:8000 (API only)"
echo ""
echo -e "${YELLOW}📝 Notes:${NC}"
echo "  • Make sure Tailscale is running on your Mac"
echo "  • Make sure your phone is connected to the same Tailscale network"
echo "  • The service must be running (check: launchctl list | grep gtd-wizard-api)"
echo "  • Nginx must be running (check: brew services list | grep nginx)"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
