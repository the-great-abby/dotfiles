#!/bin/bash
# Deploy GTD Wizard Web Interface with launchd (macOS)
# This script sets up the backend as a launchd service and frontend with nginx

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
GTD_BASE="${HOME}/code/dotfiles"
if [[ ! -d "$GTD_BASE" ]]; then
    GTD_BASE="${HOME}/code/personal/dotfiles"
fi

if [[ ! -d "$GTD_BASE" ]]; then
    echo -e "${RED}Error: GTD base directory not found${NC}"
    echo "Expected: ${HOME}/code/dotfiles or ${HOME}/code/personal/dotfiles"
    exit 1
fi

PLIST_LABEL="com.gtd.wizard-api"
PLIST_FILE="${HOME}/Library/LaunchAgents/${PLIST_LABEL}.plist"
PLIST_TEMPLATE="${GTD_BASE}/web/launchd/${PLIST_LABEL}.plist"
FRONTEND_DIST="${GTD_BASE}/web/frontend/dist"

echo -e "${GREEN}🧙 Deploying GTD Wizard Web Interface (macOS)${NC}"
echo "GTD Base: ${GTD_BASE}"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    echo "For Linux, use: ${GTD_BASE}/web/deploy-systemd.sh"
    exit 1
fi

if ! command -v launchctl &> /dev/null; then
    echo -e "${RED}Error: launchctl not found${NC}"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 not found. Please install Python 3.8+ first.${NC}"
    exit 1
fi

# Check Python version and prefer 3.11-3.13 over 3.14+
PYTHON_CMD="python3"
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

# Python 3.14+ may have compatibility issues - try to use 3.11-3.13 if available
if [[ "$PYTHON_MAJOR" -eq 3 ]] && [[ "$PYTHON_MINOR" -ge 14 ]]; then
    echo -e "${YELLOW}⚠️  Python $PYTHON_VERSION detected - may have compatibility issues${NC}"
    echo "Checking for Python 3.11, 3.12, or 3.13..."
    
    # Try to find a compatible Python version
    for pyver in python3.13 python3.12 python3.11; do
        if command -v "$pyver" &>/dev/null; then
            PYTHON_CMD="$pyver"
            PYTHON_VERSION=$($pyver --version 2>&1 | awk '{print $2}')
            echo -e "${GREEN}✓ Found $PYTHON_CMD ($PYTHON_VERSION) - will use this instead${NC}"
            break
        fi
    done
    
    # If still using 3.14+, warn user
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
    if [[ "$PYTHON_MAJOR" -eq 3 ]] && [[ "$PYTHON_MINOR" -ge 14 ]]; then
        echo -e "${YELLOW}⚠️  No compatible Python version found, using Python 3.14+${NC}"
        echo "Installation may fail. Consider installing Python 3.11 or 3.12:"
        echo "  brew install python@3.12"
        echo ""
        echo -n "Continue anyway? (y/n): "
        read continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            echo "Installation cancelled"
            exit 0
        fi
    fi
    echo ""
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm not found. Please install Node.js 18+ first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"
echo ""

# Step 2: Set up backend virtual environment
echo -e "${YELLOW}Step 2: Setting up backend...${NC}"
cd "${GTD_BASE}/web/backend"

if [[ ! -d "venv" ]]; then
    echo "Creating virtual environment with $PYTHON_CMD..."
    "$PYTHON_CMD" -m venv venv
fi

source venv/bin/activate
pip install -q --upgrade pip

# Try to install requirements, with better error handling
echo "Installing dependencies (this may take a few minutes)..."
if ! pip install -r requirements.txt; then
    echo ""
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    echo ""
    echo "This may be due to Python version compatibility issues."
    echo "Recommended solutions:"
    echo ""
    echo "1. Use Python 3.11 or 3.12 (recommended):"
    echo "   brew install python@3.12"
    echo "   python3.12 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
    echo ""
    echo "2. Or update pip and try again:"
    echo "   pip install --upgrade pip setuptools wheel"
    echo "   pip install -r requirements.txt"
    echo ""
    exit 1
fi

VENV_PYTHON="${GTD_BASE}/web/backend/venv/bin/python"

echo -e "${GREEN}✅ Backend ready${NC}"
echo ""

# Step 3: Build frontend
echo -e "${YELLOW}Step 3: Building frontend...${NC}"
cd "${GTD_BASE}/web/frontend"

if [[ ! -d "node_modules" ]]; then
    echo "Installing frontend dependencies..."
    npm install --legacy-peer-deps
fi

echo "Building frontend..."
npm run build

if [[ ! -d "dist" ]]; then
    echo -e "${RED}Error: Frontend build failed (dist directory not found)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built${NC}"
echo ""

# Step 4: Install launchd plist
echo -e "${YELLOW}Step 4: Installing launchd service...${NC}"

if [[ ! -f "$PLIST_TEMPLATE" ]]; then
    echo -e "${RED}Error: Plist template not found: ${PLIST_TEMPLATE}${NC}"
    exit 1
fi

# Create LaunchAgents directory if it doesn't exist
mkdir -p "${HOME}/Library/LaunchAgents"

# Create plist file with variable substitution
# Use different delimiter (|) to avoid conflicts with paths
sed "s|%GTD_BASE%|${GTD_BASE}|g; s|%VENV_PYTHON%|${VENV_PYTHON}|g" "$PLIST_TEMPLATE" > "$PLIST_FILE" || {
  echo -e "${RED}Error: Failed to create plist file${NC}"
  exit 1
}

echo -e "${GREEN}✅ Launchd plist installed: $PLIST_FILE${NC}"

# Unload if already loaded
if launchctl list | grep -q "$PLIST_LABEL"; then
    echo "Unloading existing service..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
fi

# Load the service
echo "Loading service..."
if launchctl load "$PLIST_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ Service loaded${NC}"
else
    echo -e "${YELLOW}⚠️  Service may already be loaded${NC}"
fi

# Start the service
launchctl start "$PLIST_LABEL" 2>/dev/null || true

echo -e "${GREEN}✅ Service started${NC}"
echo ""

# Step 5: Check/setup nginx (optional but recommended)
echo -e "${YELLOW}Step 5: Nginx setup (optional)...${NC}"

NGINX_CONFIG=""
if command -v nginx &>/dev/null; then
    echo "Nginx is installed. Setting up configuration..."
    
    # macOS nginx config location (Homebrew default)
    NGINX_CONFIG_DIR="/opt/homebrew/etc/nginx"
    if [[ ! -d "$NGINX_CONFIG_DIR" ]]; then
        NGINX_CONFIG_DIR="/usr/local/etc/nginx"
    fi
    
    if [[ -d "$NGINX_CONFIG_DIR" ]]; then
        NGINX_MAIN_CONF="${NGINX_CONFIG_DIR}/nginx.conf"
        
        # Check what's included in nginx.conf
        NGINX_SERVERS_DIR="${NGINX_CONFIG_DIR}/servers"
        NGINX_CONFD_DIR="${NGINX_CONFIG_DIR}/conf.d"
        
        # Use servers directory if it exists or is included in nginx.conf
        if [[ -d "$NGINX_SERVERS_DIR" ]] || grep -q "include.*servers" "$NGINX_MAIN_CONF" 2>/dev/null; then
            mkdir -p "$NGINX_SERVERS_DIR" 2>/dev/null || true
            NGINX_CONFIG="${NGINX_SERVERS_DIR}/gtd-wizard.conf"
            # Make sure servers directory is included in nginx.conf if not already
            if ! grep -q "include.*servers" "$NGINX_MAIN_CONF" 2>/dev/null; then
                # Backup original
                cp "$NGINX_MAIN_CONF" "${NGINX_MAIN_CONF}.bak.$(date +%s)" 2>/dev/null || true
                # Add include for servers directory (inside http block, before default_server)
                if grep -q "http {" "$NGINX_MAIN_CONF" 2>/dev/null; then
                    # Try to add include directive (this is best effort, user may need to do manually)
                    echo ""
                    echo -e "${YELLOW}⚠ Note:${NC} You may need to add this to ${NGINX_MAIN_CONF}:"
                    echo "   include servers/*.conf;"
                    echo "   (Add it inside the 'http {' block)"
                fi
            fi
        elif [[ -d "$NGINX_CONFD_DIR" ]] || grep -q "include.*conf.d" "$NGINX_MAIN_CONF" 2>/dev/null; then
            mkdir -p "$NGINX_CONFD_DIR" 2>/dev/null || true
            NGINX_CONFIG="${NGINX_CONFD_DIR}/gtd-wizard.conf"
        else
            # Fallback: place in config directory (will need manual include)
            NGINX_CONFIG="${NGINX_CONFIG_DIR}/gtd-wizard.conf"
            echo ""
            echo -e "${YELLOW}⚠ Note:${NC} Config file created but you may need to include it in ${NGINX_MAIN_CONF}"
        fi
        
        # Check for Tailscale domain configuration
        TAILSCALE_DOMAIN="${GTD_TAILSCALE_DOMAIN:-abbys-macbook-air.tailf0befd.ts.net}"
        SERVER_NAMES="localhost"
        if [[ -n "$TAILSCALE_DOMAIN" ]]; then
            SERVER_NAMES="localhost $TAILSCALE_DOMAIN"
        fi
        
        # Check if HTTPS config already exists (preserve it)
        # Check for any SSL configuration (port 443, 8443, or any port with ssl)
        HAS_HTTPS=false
        if [[ -f "$NGINX_CONFIG" ]] && grep -qE "listen.*ssl|ssl_certificate" "$NGINX_CONFIG"; then
            HAS_HTTPS=true
            echo -e "${GREEN}✓ Detected existing HTTPS configuration - preserving it${NC}"
            # Backup existing HTTPS config
            cp "$NGINX_CONFIG" "${NGINX_CONFIG}.https-backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Only create HTTP config if HTTPS doesn't exist
        if [[ "$HAS_HTTPS" == "false" ]]; then
            # Create nginx config
            cat > "$NGINX_CONFIG" <<EOF
server {
    listen 8080;
    listen [::]:8080;
    server_name ${SERVER_NAMES};

    # Frontend static files
    location / {
        root ${FRONTEND_DIST};
        try_files \$uri \$uri/ /index.html;
        index index.html;
    }

    # API proxy
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket proxy
    location /ws {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/api/health;
        proxy_set_header Host \$host;
    }
}
EOF
            echo -e "${GREEN}✓ Nginx configuration created: $NGINX_CONFIG${NC}"
        else
            echo -e "${GREEN}✓ Preserved existing HTTPS configuration${NC}"
        fi
        
        # Test nginx configuration
        if nginx -t 2>/dev/null; then
            echo -e "${GREEN}✓ Nginx configuration test passed${NC}"
            
            # Check if nginx is running
            if pgrep -x nginx >/dev/null 2>&1 || brew services list 2>/dev/null | grep -q "nginx.*started"; then
                echo "Restarting nginx to load new configuration..."
                if brew services restart nginx 2>/dev/null; then
                    echo -e "${GREEN}✓ Nginx restarted${NC}"
                elif sudo nginx -s reload 2>/dev/null; then
                    echo -e "${GREEN}✓ Nginx reloaded${NC}"
                else
                    echo -e "${YELLOW}⚠ Could not restart nginx automatically${NC}"
                    echo "   Please restart manually: brew services restart nginx"
                fi
            else
                echo "Starting nginx..."
                if brew services start nginx 2>/dev/null; then
                    echo -e "${GREEN}✓ Nginx started${NC}"
                else
                    echo -e "${YELLOW}⚠ Could not start nginx automatically${NC}"
                    echo "   Please start manually: brew services start nginx"
                fi
            fi
        else
            echo -e "${YELLOW}⚠ Nginx configuration test failed${NC}"
            echo "   Please check the config file: $NGINX_CONFIG"
            echo "   You may need to manually configure nginx"
        fi
        echo ""
    else
        echo -e "${YELLOW}⚠ Nginx config directory not found${NC}"
        echo "   Manually configure nginx or access backend directly at http://localhost:8000"
    fi
else
    echo -e "${YELLOW}⚠ Nginx not installed${NC}"
    echo ""
    echo "Options:"
    echo "  1. Install nginx: brew install nginx"
    echo "  2. Use backend directly: http://localhost:8000/api/docs"
    echo "  3. Use Vite dev server (development): cd frontend && npm run dev"
    echo ""
fi

# Step 6: Show status
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Service status:"
if launchctl list | grep -q "$PLIST_LABEL"; then
    echo -e "${GREEN}✓ Backend service is loaded and running${NC}"
    echo "  Backend API: http://localhost:8000"
    echo "  API Docs: http://localhost:8000/docs"
else
    echo -e "${YELLOW}⚠ Backend service may not be running${NC}"
fi

if command -v nginx &>/dev/null && [[ -n "${NGINX_CONFIG:-}" ]] && [[ -f "${NGINX_CONFIG}" ]]; then
    echo -e "${GREEN}✓ Frontend configured${NC}"
    
    # Check if HTTPS is configured
    if grep -q "listen.*ssl" "$NGINX_CONFIG" 2>/dev/null; then
        TAILSCALE_DOMAIN="${GTD_TAILSCALE_DOMAIN:-abbys-macbook-air.tailf0befd.ts.net}"
        
        # Detect HTTPS port
        HTTPS_PORT=$(grep -E "listen.*ssl" "$NGINX_CONFIG" | head -1 | grep -oE "listen[^;]*" | grep -oE "[0-9]+" | head -1 || echo "443")
        
        if [[ "$HTTPS_PORT" == "443" ]]; then
            echo -e "  Frontend (HTTPS): ${BOLD}https://localhost${NC}"
            if [[ -n "$TAILSCALE_DOMAIN" ]]; then
                echo -e "  Frontend (HTTPS via Tailscale): ${BOLD}https://${TAILSCALE_DOMAIN}${NC}"
            fi
            echo "  Frontend (HTTP redirects to HTTPS): http://localhost"
        else
            echo -e "  Frontend (HTTPS): ${BOLD}https://localhost:${HTTPS_PORT}${NC}"
            if [[ -n "$TAILSCALE_DOMAIN" ]]; then
                echo -e "  Frontend (HTTPS via Tailscale): ${BOLD}https://${TAILSCALE_DOMAIN}:${HTTPS_PORT}${NC}"
            fi
            echo "  Frontend (HTTP redirects to HTTPS): http://localhost"
            echo -e "${YELLOW}  Note: Using port ${HTTPS_PORT} because port 443 is in use${NC}"
        fi
        echo "  Backend API: http://localhost:8000"
        echo ""
        echo -e "${CYAN}💡${NC} HTTPS is configured and ready!"
    else
        echo "  Frontend (HTTP): ${BOLD}http://localhost:8080${NC} (Note: port 8080, not 80!)"
        if [[ -n "${GTD_TAILSCALE_DOMAIN:-}" ]]; then
            echo "  Frontend (HTTP via Tailscale): ${BOLD}http://${GTD_TAILSCALE_DOMAIN}:8080${NC}"
        fi
        echo "  Backend API: http://localhost:8000"
        echo ""
        echo -e "${CYAN}💡${NC} To enable HTTPS, run: ${BOLD}./setup-tailscale-https.sh${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Frontend: Not served (backend-only mode)${NC}"
    echo "  Install nginx or use backend API directly"
fi

echo ""
echo "Useful commands:"
echo "  • Check service status: launchctl list | grep $PLIST_LABEL"
echo "  • View service logs: tail -f /tmp/gtd-wizard-api.log"
echo "  • Stop service: launchctl stop $PLIST_LABEL"
echo "  • Start service: launchctl start $PLIST_LABEL"
echo "  • Unload service: launchctl unload $PLIST_FILE"
if command -v nginx &>/dev/null; then
    echo "  • Restart nginx: brew services restart nginx"
fi
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

