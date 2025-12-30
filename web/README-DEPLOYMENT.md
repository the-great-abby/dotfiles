# GTD Wizard Web Interface - Systemd & Nginx Deployment

This guide covers deploying the GTD Wizard web interface using systemd (for the backend) and nginx (for the frontend).

## Quick Deployment

Run the deployment script:

```bash
cd ~/code/dotfiles/web
./deploy-systemd.sh
```

This script will:
1. ✅ Check prerequisites (systemd, nginx, python3, npm)
2. ✅ Set up backend virtual environment
3. ✅ Build frontend
4. ✅ Install systemd service
5. ✅ Install nginx configuration
6. ✅ Start services

## Prerequisites

- **Linux system with systemd** (this deployment method is for Linux)
- **nginx** installed and running
- **Python 3.8+**
- **Node.js 18+** and npm
- **GTD system** installed at `~/code/dotfiles` or `~/code/personal/dotfiles`

### Install Prerequisites (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y nginx python3 python3-venv nodejs npm
```

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Build Frontend

```bash
cd ~/code/dotfiles/web/frontend
npm install
npm run build
```

### 2. Set Up Backend

```bash
cd ~/code/dotfiles/web/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Install Systemd Service

Copy and customize the systemd service file:

```bash
sudo cp ~/code/dotfiles/web/systemd/gtd-wizard-api.service /etc/systemd/system/gtd-wizard-api.service
```

Edit the service file and replace:
- `%USER%` with your username
- `%GTD_BASE%` with your GTD base path (e.g., `/home/abby/code/dotfiles`)

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable gtd-wizard-api
sudo systemctl start gtd-wizard-api
```

### 4. Install Nginx Configuration

Copy the nginx configuration:

```bash
sudo cp ~/code/dotfiles/web/nginx/gtd-wizard.conf /etc/nginx/sites-available/gtd-wizard
```

Edit the config file and replace:
- `%FRONTEND_DIST%` with your frontend dist path (e.g., `/home/abby/code/dotfiles/web/frontend/dist`)

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/gtd-wizard /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl reload nginx
```

## Access

After deployment, access the application at:

- **Frontend**: http://localhost (or http://gtd-wizard.local if you've configured DNS)
- **API**: http://localhost/api
- **API Docs**: http://localhost/api/docs
- **Health Check**: http://localhost/health

## Service Management

### Backend Service

```bash
# Check status
sudo systemctl status gtd-wizard-api

# View logs
sudo journalctl -u gtd-wizard-api -f

# Restart service
sudo systemctl restart gtd-wizard-api

# Stop service
sudo systemctl stop gtd-wizard-api

# Start service
sudo systemctl start gtd-wizard-api
```

### Nginx

```bash
# Test configuration
sudo nginx -t

# Reload configuration (without downtime)
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

## Configuration

### Backend Configuration

The backend automatically detects your GTD installation:
- First checks: `~/code/dotfiles`
- Falls back to: `~/code/personal/dotfiles`

The backend runs on `127.0.0.1:8000` (accessible only from localhost for security).

### Nginx Configuration

The nginx configuration includes:

- **Frontend static files**: Served from `/dist` directory
- **API proxy**: `/api` → `http://127.0.0.1:8000`
- **WebSocket proxy**: `/ws` → `ws://127.0.0.1:8000`
- **Health check**: `/health` → `/api/health`

### Customizing Server Name

To use a custom domain, edit `/etc/nginx/sites-available/gtd-wizard`:

```nginx
server_name your-domain.com www.your-domain.com;
```

Then update your DNS or `/etc/hosts`:

```
127.0.0.1 your-domain.com
```

## Updating

### Update Backend

```bash
cd ~/code/dotfiles/web/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
sudo systemctl restart gtd-wizard-api
```

### Update Frontend

```bash
cd ~/code/dotfiles/web/frontend
npm install
npm run build
sudo systemctl reload nginx  # No restart needed, just reload
```

## Troubleshooting

### Backend Not Starting

1. Check service status:
   ```bash
   sudo systemctl status gtd-wizard-api
   ```

2. Check logs:
   ```bash
   sudo journalctl -u gtd-wizard-api -n 50
   ```

3. Verify virtual environment exists:
   ```bash
   ls -la ~/code/dotfiles/web/backend/venv/bin/python
   ```

4. Test backend manually:
   ```bash
   cd ~/code/dotfiles/web/backend
   source venv/bin/activate
   python main.py
   ```

### Frontend Not Loading

1. Check nginx status:
   ```bash
   sudo systemctl status nginx
   sudo nginx -t
   ```

2. Check if frontend is built:
   ```bash
   ls -la ~/code/dotfiles/web/frontend/dist
   ```

3. Check nginx error logs:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

4. Check nginx access logs:
   ```bash
   sudo tail -f /var/log/nginx/access.log
   ```

### API Not Working

1. Check if backend is running:
   ```bash
   curl http://localhost:8000/api/health
   ```

2. Check nginx proxy configuration:
   ```bash
   curl http://localhost/api/health
   ```

3. Check CORS settings in `web/backend/main.py` if accessing from a different origin

### WebSocket Not Connecting

1. Check nginx WebSocket proxy configuration
2. Verify backend WebSocket endpoint:
   ```bash
   curl http://localhost/api/ws  # Should return upgrade required
   ```

3. Check browser console for WebSocket errors
4. Verify nginx `proxy_set_header Upgrade` and `Connection` headers are set

## Security Considerations

### Production Deployment

For production, consider:

1. **HTTPS**: Set up SSL/TLS certificates (Let's Encrypt)
2. **Authentication**: Add authentication to the API
3. **Rate Limiting**: Configure nginx rate limiting
4. **Firewall**: Restrict access to port 80/443
5. **Backend Access**: Backend only listens on 127.0.0.1 (localhost) - don't expose port 8000 publicly

### Nginx SSL Configuration Example

```nginx
server {
    listen 443 ssl;
    server_name gtd-wizard.local;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # ... rest of configuration
}

server {
    listen 80;
    server_name gtd-wizard.local;
    return 301 https://$server_name$request_uri;
}
```

## Uninstall

To remove the deployment:

```bash
# Stop and disable systemd service
sudo systemctl stop gtd-wizard-api
sudo systemctl disable gtd-wizard-api
sudo rm /etc/systemd/system/gtd-wizard-api.service
sudo systemctl daemon-reload

# Remove nginx configuration
sudo rm /etc/nginx/sites-enabled/gtd-wizard
sudo rm /etc/nginx/sites-available/gtd-wizard
sudo systemctl reload nginx
```

## Support

For issues:
1. Check logs (systemd and nginx)
2. Verify GTD system works via CLI
3. Test API endpoints directly: `curl http://localhost:8000/api/status`
4. Review this deployment guide

