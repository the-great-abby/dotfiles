# GTD Wizard Web Interface - Deployment Guide

This guide covers setting up and deploying the GTD Wizard web interface.

## Prerequisites

- Python 3.8+ installed
- Node.js 18+ and npm installed
- GTD system already set up (bash scripts in `~/code/dotfiles` or `~/code/personal/dotfiles`)
- Terminal access

## Quick Start

### 1. Clone/Navigate to Repository

```bash
cd ~/code/dotfiles
```

### 2. Set Up Backend

```bash
# Navigate to backend directory
cd web/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows

# Install dependencies
pip install -r requirements.txt
```

### 3. Set Up Frontend

```bash
# Navigate to frontend directory (from repo root)
cd web/frontend

# Install dependencies
npm install
```

### 4. Start Development Servers

#### Terminal 1: Backend
```bash
cd web/backend
source venv/bin/activate  # If not already activated
python main.py
```

The backend will start on `http://localhost:8000`

#### Terminal 2: Frontend
```bash
cd web/frontend
npm run dev
```

The frontend will start on `http://localhost:5173`

### 5. Access the Application

Open your browser and navigate to:
- **Frontend**: http://localhost:5173
- **API Docs**: http://localhost:8000/docs

## Configuration

### Backend Configuration

The backend automatically detects your GTD installation:
- First checks: `~/code/dotfiles`
- Falls back to: `~/code/personal/dotfiles`

To verify the backend can find your GTD scripts:

```bash
cd web/backend
source venv/bin/activate
python -c "from pathlib import Path; print(Path.home() / 'code' / 'dotfiles')"
```

### Frontend Configuration

The frontend is configured to proxy API requests to the backend. This is set in `vite.config.js`:

```javascript
proxy: {
  '/api': {
    target: 'http://localhost:8000',
    changeOrigin: true
  }
}
```

## Production Deployment

### Option 1: Systemd Service (Linux/macOS)

#### Backend Service

Create `/etc/systemd/system/gtd-wizard-api.service`:

```ini
[Unit]
Description=GTD Wizard API
After=network.target

[Service]
Type=simple
User=abby
WorkingDirectory=/home/abby/code/dotfiles/web/backend
Environment="PATH=/home/abby/code/dotfiles/web/backend/venv/bin"
ExecStart=/home/abby/code/dotfiles/web/backend/venv/bin/python main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable gtd-wizard-api
sudo systemctl start gtd-wizard-api
sudo systemctl status gtd-wizard-api
```

#### Frontend Service (with nginx)

Build the frontend:

```bash
cd web/frontend
npm run build
```

Configure nginx (`/etc/nginx/sites-available/gtd-wizard`):

```nginx
server {
    listen 80;
    server_name gtd-wizard.local;

    # Frontend
    location / {
        root /home/abby/code/dotfiles/web/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # WebSocket proxy
    location /ws {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/gtd-wizard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Option 2: Docker Compose

Create `web/docker-compose.yml`:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    volumes:
      - ~/code/dotfiles:/app/gtd:ro
    environment:
      - GTD_BASE=/app/gtd
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: unless-stopped
```

Create `web/backend/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

EXPOSE 8000

CMD ["python", "main.py"]
```

Create `web/frontend/Dockerfile`:

```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Run:

```bash
cd web
docker-compose up -d
```

### Option 3: Launchd (macOS)

Create `~/Library/LaunchAgents/com.gtd.wizard-api.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gtd.wizard-api</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/abby/code/dotfiles/web/backend/venv/bin/python</string>
        <string>/Users/abby/code/dotfiles/web/backend/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/abby/code/dotfiles/web/backend</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/gtd-wizard-api.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/gtd-wizard-api.error.log</string>
</dict>
</plist>
```

Load:

```bash
launchctl load ~/Library/LaunchAgents/com.gtd.wizard-api.plist
launchctl start com.gtd.wizard-api
```

## Security Considerations

### Development

- Backend runs on `0.0.0.0:8000` (accessible from network)
- Frontend proxy allows CORS from localhost
- No authentication required

### Production

1. **Add Authentication** (if needed):
   - Implement API key or JWT authentication
   - Add rate limiting
   - Use HTTPS

2. **Restrict Access**:
   - Bind backend to `127.0.0.1` instead of `0.0.0.0`
   - Use nginx reverse proxy with authentication
   - Firewall rules

3. **Input Validation**:
   - Backend already validates inputs via Pydantic
   - Sanitize shell command arguments
   - Limit command execution timeout

4. **File System Access**:
   - Backend only accesses GTD directories
   - No arbitrary file system access
   - Commands are whitelisted

## Troubleshooting

### Backend Issues

**Problem**: "Command not found" errors

**Solution**: Verify GTD base directory:
```bash
python -c "from pathlib import Path; print(Path.home() / 'code' / 'dotfiles')"
```

**Problem**: Permission denied

**Solution**: Ensure scripts are executable:
```bash
chmod +x ~/code/dotfiles/bin/*
```

**Problem**: Import errors

**Solution**: Ensure virtual environment is activated:
```bash
source web/backend/venv/bin/activate
pip install -r web/backend/requirements.txt
```

### Frontend Issues

**Problem**: Cannot connect to API

**Solution**: 
1. Verify backend is running: `curl http://localhost:8000/api/health`
2. Check CORS settings in `main.py`
3. Verify proxy configuration in `vite.config.js`

**Problem**: WebSocket connection fails

**Solution**:
1. Check WebSocket URL in `App.svelte`
2. Verify backend WebSocket endpoint is accessible
3. Check firewall/network settings

### General Issues

**Problem**: Status shows 0 for all counts

**Solution**: 
- Backend falls back to file counting if commands fail
- Verify GTD directories exist and contain files
- Check backend logs for errors

**Problem**: Commands timeout

**Solution**: 
- Increase timeout in `execute_gtd_command()` (default: 30s)
- Check if GTD scripts are hanging
- Review script execution logs

## Monitoring

### Backend Logs

```bash
# If using systemd
sudo journalctl -u gtd-wizard-api -f

# If running manually
tail -f /tmp/gtd-wizard-api.log
```

### Frontend Logs

Check browser console for errors.

### Health Check

```bash
curl http://localhost:8000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "gtd_base_exists": true
}
```

## Updating

### Backend

```bash
cd web/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
# Restart service
```

### Frontend

```bash
cd web/frontend
npm install
npm run build
# Restart nginx/service
```

## Integration with Existing Wizard

The web interface uses the same bash scripts as the CLI wizard:

- `gtd-capture` - Capture items
- `gtd-task` - Task management
- `gtd-project` - Project management
- `gtd-inbox` - Inbox operations
- `gtd-wizard` - Full wizard (can be called via API)

All operations are compatible with the CLI wizard. You can use both interfaces interchangeably.

## Next Steps

1. **Add More Features**: Extend API endpoints for additional wizard functions
2. **Authentication**: Add user authentication if needed
3. **Mobile App**: Create mobile app using same API
4. **Analytics**: Add usage tracking and analytics
5. **Notifications**: Implement push notifications for important events

## Support

For issues or questions:
1. Check logs (backend and frontend)
2. Verify GTD system is working via CLI
3. Test API endpoints directly: `curl http://localhost:8000/api/status`
4. Review this deployment guide





