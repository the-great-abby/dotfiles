#!/bin/bash
# Setup HTTPS for GTD Wizard on Tailscale
# This script configures nginx with SSL certificates for Tailscale domains

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔒 Setting up HTTPS for GTD Wizard (Tailscale)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get Tailscale domain
TAILSCALE_DOMAIN="${GTD_TAILSCALE_DOMAIN:-}"

# Try to find tailscale CLI in common locations
TAILSCALE_CMD=""
if command -v tailscale &>/dev/null; then
    TAILSCALE_CMD="tailscale"
elif [[ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
    # Try using the app bundle (though this is usually the GUI)
    TAILSCALE_CMD="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
elif [[ -f "/usr/local/bin/tailscale" ]]; then
    TAILSCALE_CMD="/usr/local/bin/tailscale"
elif [[ -f "/opt/homebrew/bin/tailscale" ]]; then
    TAILSCALE_CMD="/opt/homebrew/bin/tailscale"
fi

# Try to get domain from tailscale CLI if available
if [[ -z "$TAILSCALE_DOMAIN" ]] && [[ -n "$TAILSCALE_CMD" ]]; then
    # Try to get from tailscale status
    if "$TAILSCALE_CMD" status &>/dev/null; then
        TAILSCALE_DOMAIN=$("$TAILSCALE_CMD" status --json 2>/dev/null | grep -o '"DNSName":"[^"]*' | head -1 | cut -d'"' -f4 || echo "")
    fi
fi

# If still not found, ask user
if [[ -z "$TAILSCALE_DOMAIN" ]]; then
    echo -e "${YELLOW}Enter your Tailscale domain (e.g., abbys-macbook-air.tailf0befd.ts.net):${NC} "
    read -r TAILSCALE_DOMAIN
fi

if [[ -z "$TAILSCALE_DOMAIN" ]]; then
    echo -e "${RED}Error: Tailscale domain is required${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Using Tailscale domain: ${TAILSCALE_DOMAIN}${NC}"
echo ""

# Check if Tailscale is running (optional check - don't fail if CLI not available)
if [[ -n "$TAILSCALE_CMD" ]]; then
    if "$TAILSCALE_CMD" status &>/dev/null; then
        echo -e "${GREEN}✓ Tailscale is running${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify Tailscale status (CLI not available or not running)${NC}"
        echo -e "${YELLOW}⚠ Make sure Tailscale app is running before proceeding${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Tailscale CLI not found in PATH${NC}"
    echo -e "${YELLOW}⚠ Make sure Tailscale app is installed and running${NC}"
    echo ""
    echo -e "${BLUE}To install Tailscale CLI (optional):${NC}"
    echo -e "  brew install tailscale"
    echo ""
fi
echo ""

# Find nginx config directory
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    NGINX_CONFIG_DIR="/opt/homebrew/etc/nginx"
    if [[ ! -d "$NGINX_CONFIG_DIR" ]]; then
        NGINX_CONFIG_DIR="/usr/local/etc/nginx"
    fi
    if [[ -d "${NGINX_CONFIG_DIR}/servers" ]]; then
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/servers/gtd-wizard.conf"
    else
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/gtd-wizard.conf"
    fi
else
    # Linux
    NGINX_CONFIG_DIR="/etc/nginx"
    if [[ -d "${NGINX_CONFIG_DIR}/sites-available" ]]; then
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/sites-available/gtd-wizard.conf"
    elif [[ -d "${NGINX_CONFIG_DIR}/conf.d" ]]; then
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/conf.d/gtd-wizard.conf"
    else
        NGINX_CONFIG="${NGINX_CONFIG_DIR}/gtd-wizard.conf"
    fi
fi

if [[ ! -f "$NGINX_CONFIG" ]]; then
    echo -e "${RED}Error: Nginx config not found at: $NGINX_CONFIG${NC}"
    echo -e "${YELLOW}Please run the deployment script first: ./web/deploy-launchd.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found nginx config: $NGINX_CONFIG${NC}"
echo ""

# Get frontend dist path from existing config
FRONTEND_DIST=$(grep -E "^\s*root\s+" "$NGINX_CONFIG" | head -1 | awk '{print $2}' | tr -d ';' || echo "")
if [[ -z "$FRONTEND_DIST" ]]; then
    FRONTEND_DIST="$HOME/code/dotfiles/web/frontend/dist"
fi

echo -e "${GREEN}✓ Frontend directory: $FRONTEND_DIST${NC}"
echo ""

# Method 1: Tailscale HTTPS (Recommended - Automatic Let's Encrypt)
echo -e "${YELLOW}Choose HTTPS method:${NC}"
echo "  1) Tailscale HTTPS (Automatic - Recommended)"
echo "  2) Self-signed certificate (For testing)"
echo "  3) Manual Let's Encrypt with certbot"
echo ""
echo -n "Choose (1-3, default: 1): "
read -r method
method="${method:-1}"

case "$method" in
    1)
        echo ""
        echo -e "${YELLOW}Setting up Tailscale HTTPS...${NC}"
        echo ""
        echo -e "${BLUE}Tailscale can automatically provision Let's Encrypt certificates${NC}"
        echo -e "${BLUE}for .ts.net domains. This requires:${NC}"
        echo "  1. HTTPS enabled in Tailscale admin console"
        echo "  2. MagicDNS enabled"
        echo ""
        echo -e "${YELLOW}To enable HTTPS in Tailscale:${NC}"
        echo "  1. Go to: https://login.tailscale.com/admin/settings/keys"
        echo "  2. Enable 'HTTPS Certificates'"
        echo "  3. Enable 'MagicDNS'"
        echo ""
        echo -n "Have you enabled HTTPS in Tailscale admin console? (y/n): "
        read -r enabled
        if [[ "$enabled" != "y" && "$enabled" != "Y" ]]; then
            echo -e "${YELLOW}Please enable HTTPS in Tailscale admin console first, then run this script again.${NC}"
            exit 0
        fi
        
        # Tailscale stores certificates in a specific location
        # On macOS: ~/Library/Application Support/Tailscale/certificates/
        # The certs are managed by Tailscale, we just need to reference them
        
        TAILSCALE_CERT_DIR="$HOME/Library/Application Support/Tailscale/certificates"
        if [[ "$(uname)" != "Darwin" ]]; then
            TAILSCALE_CERT_DIR="$HOME/.local/share/tailscale/certificates"
        fi
        
        if [[ ! -d "$TAILSCALE_CERT_DIR" ]]; then
            echo -e "${YELLOW}⚠ Tailscale certificate directory not found.${NC}"
            echo -e "${YELLOW}This is normal if HTTPS was just enabled. Tailscale will create it.${NC}"
            echo ""
            echo -e "${YELLOW}Waiting for Tailscale to provision certificate...${NC}"
            echo -e "${YELLOW}This may take a few minutes.${NC}"
            echo ""
            
            # Wait for certificate to be created (up to 5 minutes)
            for i in {1..60}; do
                if [[ -d "$TAILSCALE_CERT_DIR" ]] && find "$TAILSCALE_CERT_DIR" -name "*${TAILSCALE_DOMAIN}*" -type f 2>/dev/null | grep -q .; then
                    echo -e "${GREEN}✓ Certificate found${NC}"
                    break
                fi
                echo -n "."
                sleep 5
            done
            echo ""
        fi
        
        # Find the certificate files
        # Check Tailscale certificate directory first
        CERT_FILE=$(find "$TAILSCALE_CERT_DIR" -name "*${TAILSCALE_DOMAIN}*.crt" 2>/dev/null | head -1 || echo "")
        KEY_FILE=$(find "$TAILSCALE_CERT_DIR" -name "*${TAILSCALE_DOMAIN}*.key" 2>/dev/null | head -1 || echo "")
        
        # If not found, check current directory (where tailscale cert generates them)
        if [[ -z "$CERT_FILE" ]]; then
            if [[ -f "${TAILSCALE_DOMAIN}.crt" ]]; then
                CERT_FILE="${TAILSCALE_DOMAIN}.crt"
                echo -e "${YELLOW}Found certificate in current directory, moving to Tailscale directory...${NC}"
                mkdir -p "$TAILSCALE_CERT_DIR"
                mv "${TAILSCALE_DOMAIN}.crt" "${TAILSCALE_DOMAIN}.key" "$TAILSCALE_CERT_DIR/" 2>/dev/null || true
                CERT_FILE="$TAILSCALE_CERT_DIR/${TAILSCALE_DOMAIN}.crt"
                KEY_FILE="$TAILSCALE_CERT_DIR/${TAILSCALE_DOMAIN}.key"
            fi
        fi
        
        if [[ -z "$CERT_FILE" || -z "$KEY_FILE" ]]; then
            echo -e "${RED}Error: Could not find Tailscale certificate files${NC}"
            echo -e "${YELLOW}Please ensure:${NC}"
            echo "  1. HTTPS is enabled in Tailscale admin console"
            echo "  2. MagicDNS is enabled"
            echo "  3. Wait a few minutes for Tailscale to provision the certificate"
            echo ""
            echo -e "${YELLOW}You can check certificate status with:${NC}"
            echo "  tailscale cert ${TAILSCALE_DOMAIN}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ Found certificate: $CERT_FILE${NC}"
        echo -e "${GREEN}✓ Found key: $KEY_FILE${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}Generating self-signed certificate...${NC}"
        
        CERT_DIR="/tmp/gtd-wizard-certs"
        mkdir -p "$CERT_DIR"
        
        CERT_FILE="$CERT_DIR/${TAILSCALE_DOMAIN}.crt"
        KEY_FILE="$CERT_DIR/${TAILSCALE_DOMAIN}.key"
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$KEY_FILE" \
            -out "$CERT_FILE" \
            -subj "/CN=${TAILSCALE_DOMAIN}" \
            -addext "subjectAltName=DNS:${TAILSCALE_DOMAIN},DNS:localhost"
        
        echo -e "${GREEN}✓ Self-signed certificate created${NC}"
        echo -e "${YELLOW}⚠ Note: Browsers will show a security warning for self-signed certificates${NC}"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}Setting up Let's Encrypt with certbot...${NC}"
        
        if ! command -v certbot &>/dev/null; then
            echo -e "${RED}Error: certbot not found. Please install certbot first.${NC}"
            if [[ "$(uname)" == "Darwin" ]]; then
                echo "  brew install certbot"
            else
                echo "  sudo apt-get install certbot python3-certbot-nginx"
            fi
            exit 1
        fi
        
        # Certbot will handle certificate generation
        echo -e "${YELLOW}Running certbot...${NC}"
        sudo certbot --nginx -d "$TAILSCALE_DOMAIN" --non-interactive --agree-tos --email "${USER}@${TAILSCALE_DOMAIN}" || {
            echo -e "${RED}Error: certbot failed${NC}"
            echo -e "${YELLOW}Note: Let's Encrypt requires the domain to be publicly accessible${NC}"
            echo -e "${YELLOW}For Tailscale-only access, use method 1 (Tailscale HTTPS) instead${NC}"
            exit 1
        }
        
        # Certbot modifies nginx config, so we're done
        echo -e "${GREEN}✓ Let's Encrypt certificate installed${NC}"
        sudo nginx -t && sudo nginx -s reload
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Create nginx SSL config
echo ""
echo -e "${YELLOW}Creating nginx SSL configuration...${NC}"

# Backup existing config
cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✓ Backed up existing config${NC}"

# Create new config with SSL
cat > "$NGINX_CONFIG" <<EOF
# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${TAILSCALE_DOMAIN} localhost;

    # Redirect all HTTP to HTTPS
    return 301 https://\$host\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${TAILSCALE_DOMAIN} localhost;

    # SSL certificates
    ssl_certificate "${CERT_FILE}";
    ssl_certificate_key "${KEY_FILE}";

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

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

echo -e "${GREEN}✓ Nginx SSL configuration created${NC}"
echo ""

# Test nginx configuration
echo -e "${YELLOW}Testing nginx configuration...${NC}"
if nginx -t 2>/dev/null || sudo nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓ Nginx configuration is valid${NC}"
else
    echo -e "${RED}Error: Nginx configuration test failed${NC}"
    echo -e "${YELLOW}Restoring backup...${NC}"
    mv "${NGINX_CONFIG}.backup"* "$NGINX_CONFIG" 2>/dev/null || true
    exit 1
fi

# Reload nginx
echo ""
echo -e "${YELLOW}Reloading nginx...${NC}"
if brew services restart nginx 2>/dev/null || sudo nginx -s reload 2>/dev/null || sudo systemctl reload nginx 2>/dev/null; then
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    echo -e "${YELLOW}⚠ Please reload nginx manually${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ HTTPS setup complete!${NC}"
echo ""
echo -e "${BLUE}Access your site at:${NC}"
echo -e "${GREEN}  • https://${TAILSCALE_DOMAIN}${NC}"
echo -e "${GREEN}  • https://localhost${NC}"
echo ""
echo -e "${YELLOW}Note: HTTP requests will automatically redirect to HTTPS${NC}"
echo ""
