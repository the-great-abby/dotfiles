# GTD Wizard Mobile Access via Tailscale

This guide explains how to access your GTD Wizard web interface from your mobile phone using Tailscale.

## Quick Setup

1. **Run the configuration script:**
   ```bash
   cd ~/code/dotfiles/web
   ./configure-tailscale.sh abbys-macbook-air.tailf0befd.ts.net
   ```

2. **Make sure services are running:**
   ```bash
   # Check backend service
   launchctl list | grep gtd-wizard-api
   
   # Check nginx
   brew services list | grep nginx
   ```

3. **Access from your phone:**
   - Open your mobile browser
   - Navigate to: `http://abbys-macbook-air.tailf0befd.ts.net:8080`
   - Make sure your phone is connected to the same Tailscale network

## Prerequisites

- ✅ Tailscale installed and running on your Mac
- ✅ Tailscale app installed on your phone
- ✅ Both devices connected to the same Tailscale network
- ✅ GTD Wizard web interface deployed (run `deploy-launchd.sh` first)

## Configuration Details

The configuration script does the following:

1. **Updates backend CORS** - Allows requests from your Tailscale domain
2. **Updates nginx configuration** - Adds your Tailscale domain to `server_name`
3. **Updates launchd service** - Sets `GTD_TAILSCALE_DOMAIN` environment variable

## Custom Tailscale Domain

If your Tailscale domain is different, you can specify it:

```bash
./configure-tailscale.sh your-custom-domain.tailf0befd.ts.net
```

Or set it as an environment variable:

```bash
export GTD_TAILSCALE_DOMAIN="your-custom-domain.tailf0befd.ts.net"
./configure-tailscale.sh
```

## Troubleshooting

### Can't access from phone

1. **Check Tailscale connection:**
   ```bash
   # On Mac
   tailscale status
   ```

2. **Check if services are running:**
   ```bash
   # Backend
   launchctl list | grep gtd-wizard-api
   
   # Nginx
   brew services list | grep nginx
   ```

3. **Check nginx is listening on all interfaces:**
   ```bash
   lsof -i :8080
   # Should show nginx listening on *:8080 or 0.0.0.0:8080
   ```

4. **Check firewall settings:**
   - macOS may block incoming connections
   - Go to System Settings > Network > Firewall
   - Make sure nginx is allowed

### CORS errors in browser

- Make sure the Tailscale domain is in the backend CORS list
- Check the backend logs: `tail -f /tmp/gtd-wizard-api.log`
- Restart the backend service: `launchctl stop com.gtd.wizard-api && launchctl start com.gtd.wizard-api`

### Port 8080 not accessible

- On macOS, nginx typically runs on port 8080 (not 80) to avoid conflicts
- Make sure you're accessing `http://your-domain:8080` (not port 80)
- If you want to use port 80, you'll need to run nginx with sudo or configure it differently

## Security Notes

- The web interface is only accessible within your Tailscale network
- Tailscale provides encrypted connections between devices
- No additional authentication is configured - anyone on your Tailscale network can access it
- Consider adding authentication if you share your Tailscale network with others

## Direct Backend Access (Alternative)

If you prefer to access the backend directly without nginx:

1. Set environment variable to bind to all interfaces:
   ```bash
   export GTD_BIND_HOST="0.0.0.0"
   ```

2. Update launchd plist to include this environment variable

3. Access directly: `http://abbys-macbook-air.tailf0befd.ts.net:8000`

Note: This bypasses nginx and serves the API only (no frontend UI).
