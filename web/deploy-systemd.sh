#!/bin/bash
# Deploy GTD Wizard Web Interface with systemd and nginx
# This script sets up the backend as a systemd service and frontend with nginx

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

USER_NAME="${USER}"
NGINX_SITE_NAME="gtd-wizard"
SYSTEMD_SERVICE_NAME="gtd-wizard-api"
FRONTEND_DIST="${GTD_BASE}/web/frontend/dist"

echo -e "${GREEN}🧙 Deploying GTD Wizard Web Interface${NC}"
echo "GTD Base: ${GTD_BASE}"
echo "User: ${USER_NAME}"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"
if ! command -v systemctl &> /dev/null; then
    echo -e "${RED}Error: systemctl not found. This script requires systemd (Linux).${NC}"
    echo "For macOS, use launchd instead (see deployment guide)."
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Error: nginx not found. Please install nginx first.${NC}"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 not found. Please install Python 3.8+ first.${NC}"
    exit 1
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
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo -e "${GREEN}✅ Backend ready${NC}"
echo ""

# Step 3: Build frontend
echo -e "${YELLOW}Step 3: Building frontend...${NC}"
cd "${GTD_BASE}/web/frontend"

if [[ ! -d "node_modules" ]]; then
    echo "Installing frontend dependencies..."
    npm install
fi

echo "Building frontend..."
npm run build

if [[ ! -d "dist" ]]; then
    echo -e "${RED}Error: Frontend build failed (dist directory not found)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built${NC}"
echo ""

# Step 4: Install systemd service
echo -e "${YELLOW}Step 4: Installing systemd service...${NC}"
SYSTEMD_TEMPLATE="${GTD_BASE}/web/systemd/gtd-wizard-api.service"
SYSTEMD_TARGET="/etc/systemd/system/${SYSTEMD_SERVICE_NAME}.service"

if [[ ! -f "$SYSTEMD_TEMPLATE" ]]; then
    echo -e "${RED}Error: Systemd template not found: ${SYSTEMD_TEMPLATE}${NC}"
    exit 1
fi

# Create service file with variable substitution
sudo tee "$SYSTEMD_TARGET" > /dev/null <<EOF
[Unit]
Description=GTD Wizard API
After=network.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${GTD_BASE}/web/backend
Environment="PATH=${GTD_BASE}/web/backend/venv/bin"
ExecStart=${GTD_BASE}/web/backend/venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable "${SYSTEMD_SERVICE_NAME}"

echo -e "${GREEN}✅ Systemd service installed${NC}"
echo ""

# Step 5: Install nginx configuration
echo -e "${YELLOW}Step 5: Installing nginx configuration...${NC}"
NGINX_TEMPLATE="${GTD_BASE}/web/nginx/gtd-wizard.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/${NGINX_SITE_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${NGINX_SITE_NAME}"

if [[ ! -f "$NGINX_TEMPLATE" ]]; then
    echo -e "${RED}Error: Nginx template not found: ${NGINX_TEMPLATE}${NC}"
    exit 1
fi

# Create nginx config with variable substitution
sudo tee "$NGINX_AVAILABLE" > /dev/null <<EOF
server {
    listen 80;
    server_name gtd-wizard.local localhost;

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

# Create symlink if it doesn't exist
if [[ ! -L "$NGINX_ENABLED" ]]; then
    sudo ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
fi

# Test nginx configuration
echo "Testing nginx configuration..."
if ! sudo nginx -t; then
    echo -e "${RED}Error: Nginx configuration test failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Nginx configuration installed${NC}"
echo ""

# Step 6: Start services
echo -e "${YELLOW}Step 6: Starting services...${NC}"
sudo systemctl start "${SYSTEMD_SERVICE_NAME}"
sudo systemctl reload nginx

echo -e "${GREEN}✅ Services started${NC}"
echo ""

# Step 7: Show status
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Service status:"
sudo systemctl status "${SYSTEMD_SERVICE_NAME}" --no-pager -l | head -n 10
echo ""
echo "Access the application:"
echo "  • Frontend: http://localhost (or http://gtd-wizard.local)"
echo "  • API: http://localhost/api"
echo "  • API Docs: http://localhost/api/docs"
echo "  • Health: http://localhost/health"
echo ""
echo "Useful commands:"
echo "  • Check service status: sudo systemctl status ${SYSTEMD_SERVICE_NAME}"
echo "  • View service logs: sudo journalctl -u ${SYSTEMD_SERVICE_NAME} -f"
echo "  • Restart service: sudo systemctl restart ${SYSTEMD_SERVICE_NAME}"
echo "  • Stop service: sudo systemctl stop ${SYSTEMD_SERVICE_NAME}"
echo "  • Reload nginx: sudo systemctl reload nginx"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

