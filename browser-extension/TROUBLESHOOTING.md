# Troubleshooting Guide

## "Not Found" or "Endpoint not found" Errors

If you get a "Not Found" error when using the extension, the API server is likely running an old version of the code.

### Solution: Restart the API Server

**If running manually:**
```bash
# Stop the server (Ctrl+C in the terminal where it's running)
# Then restart it:
cd ~/code/dotfiles/web/backend
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
```

**If running as a service (launchd on macOS):**
```bash
# Check if it's running
launchctl list | grep gtd

# Restart the service
launchctl unload ~/Library/LaunchAgents/com.gtd.wizard-api.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.gtd.wizard-api.plist

# Or if using systemd (Linux):
sudo systemctl restart gtd-wizard-api
```

**Quick restart script:**
```bash
cd ~/code/dotfiles/web/backend
# Kill any running instances
pkill -f "uvicorn.*main:app" || true
# Start fresh
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
```

## Connection Test Works But Actions Fail

If the connection test shows "Connected" but actions like "Deep Analysis" fail:

1. **Check server logs** for errors:
   ```bash
   # If running manually, check the terminal
   # If running as service:
   tail -f ~/Library/Logs/com.gtd.wizard-api.log
   # Or on Linux:
   sudo journalctl -u gtd-wizard-api -f
   ```

2. **Verify the endpoint exists:**
   ```bash
   curl http://localhost:8000/api/browser/process \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"action":"analyze","content":{"url":"test","title":"Test","text":"test"}}'
   ```

3. **Check if MCP server is accessible:**
   The endpoint requires the MCP server to be importable. Make sure:
   - `~/code/dotfiles/mcp/gtd_mcp_server.py` exists
   - Python can import it (check for import errors in server logs)

## Common Issues

### "Cannot connect to API"
- Make sure the FastAPI server is running on port 8000
- Check firewall settings
- Verify the API endpoint in extension settings matches where the server is running

### "Failed to import MCP functions"
- Ensure `~/code/dotfiles/mcp/gtd_mcp_server.py` exists
- Check that all MCP dependencies are installed:
  ```bash
  cd ~/code/dotfiles/mcp
  pip install -r requirements.txt
  ```

### "Network error" or CORS issues
- The extension should work with CORS automatically
- Make sure you're using `http://localhost:8000` (not `https://`)
- Check browser console (F12) for CORS errors

### Actions work but return errors
- Check server logs for detailed error messages
- Verify your LLM/AI server is running and accessible
- Check that GTD config file exists at `~/.gtd_config`

## Getting Help

1. **Check browser console** (F12 → Console) for JavaScript errors
2. **Check server logs** for Python/API errors
3. **Test the API directly** with curl (see above)
4. **Verify all services are running:**
   - FastAPI backend (port 8000)
   - LLM server (if using local models)
   - MCP server dependencies

## Debug Mode

To see more detailed errors, check:
- Browser console (F12)
- Server terminal/logs
- Network tab in browser DevTools (F12 → Network) to see the actual request/response
