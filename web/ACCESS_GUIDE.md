# How to Access Your GTD Wizard Web Interface

## Current Setup

Your site is currently running on **HTTP port 8080**.

## Quick Access (HTTP)

You can access it right now at:
- **http://localhost:8080**
- **http://abbys-macbook-air.tailf0befd.ts.net:8080** (via Tailscale)

## Setting Up HTTPS

To enable HTTPS and access via `https://`, run:

```bash
cd ~/code/dotfiles/web
./setup-tailscale-https.sh
```

This will:
1. Set up SSL certificates (Tailscale automatic, self-signed, or Let's Encrypt)
2. Configure nginx to listen on port 443 (HTTPS)
3. Redirect HTTP to HTTPS

After setup, access at:
- **https://localhost**
- **https://abbys-macbook-air.tailf0befd.ts.net** (via Tailscale)

## Adding a Local Domain Name (Optional)

If you want to use a friendly name like `gtd-wizard.local`:

### Step 1: Add to /etc/hosts

```bash
sudo nano /etc/hosts
```

Add this line:
```
127.0.0.1    gtd-wizard.local
```

### Step 2: Update nginx config

The nginx config already includes `gtd-wizard.local` in the server_name, so after adding it to hosts, you can access:
- **http://gtd-wizard.local:8080** (HTTP)
- **https://gtd-wizard.local** (HTTPS, after running setup script)

## Mobile Access via Tailscale

1. Make sure Tailscale is running on your Mac
2. Install Tailscale app on your phone
3. Connect both devices to the same Tailscale network
4. Access from phone: **http://abbys-macbook-air.tailf0befd.ts.net:8080**

## Troubleshooting

### Can't access the site

1. **Check if services are running:**
   ```bash
   # Backend
   launchctl list | grep com.gtd.wizard-api
   
   # Nginx
   brew services list | grep nginx
   ```

2. **Check if nginx is listening:**
   ```bash
   lsof -i :8080
   # Should show nginx
   ```

3. **Test backend directly:**
   ```bash
   curl http://localhost:8000/api/health
   ```

4. **Check nginx logs:**
   ```bash
   tail -f /opt/homebrew/var/log/nginx/error.log
   ```

### Port 8080 not accessible

Make sure you're using port **8080**, not 80:
- ✅ Correct: `http://localhost:8080`
- ❌ Wrong: `http://localhost` (this won't work)

### HTTPS not working

1. Make sure you ran `./setup-tailscale-https.sh`
2. Check if certificates exist
3. Verify nginx config: `nginx -t`
4. Check nginx is listening on 443: `lsof -i :443`
