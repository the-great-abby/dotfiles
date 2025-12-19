# Cursor MCP Configuration & Deployment Setup

## Summary

This document describes the setup completed for:
1. **Cursor MCP Configuration** - Automated setup for Cursor IDE
2. **Kubernetes Deployment Integration** - Built into `gtd-wizard`

## ✅ What Was Added

### 1. Cursor MCP Configuration (`.cursor/` directory)

Created a `.cursor` directory with:

- **`mcp_config.json`** - MCP server configuration template
- **`setup_cursor_mcp.sh`** - Automated setup script
- **`README.md`** - Setup instructions
- **`QUICK_SETUP.md`** - Quick reference guide

**Quick Setup:**

```bash
cd .cursor
./setup_cursor_mcp.sh
```

This automatically:
- Detects your OS
- Updates paths in the config
- Copies config to Cursor settings directory
- Verifies installation

**Manual Setup:**

The config file is located at:
- **macOS**: `~/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- **Linux**: `~/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- **Windows**: `%APPDATA%\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`

### 2. Kubernetes Deployment Integration

#### Deployment Script (`mcp/deploy.sh`)

A comprehensive deployment script with commands:

- `build` - Build Docker image
- `deploy` - Deploy to Kubernetes
- `undeploy` - Remove deployment
- `status` - Check deployment status
- `logs` - View worker logs
- `update` - Rebuild & redeploy

**Usage:**

```bash
cd mcp
./deploy.sh build      # Build image
./deploy.sh deploy     # Deploy to K8s
./deploy.sh status     # Check status
./deploy.sh logs       # View logs
```

#### Integration with gtd-wizard

Added deployment wizard to `gtd-wizard` in two places:

**Option 1: Via AI Suggestions Menu**

1. Run: `gtd-wizard`
2. Choose: `23) 🤖 AI Suggestions & MCP Tools`
3. Choose: `10) 🚀 Deploy Worker to Kubernetes`

This provides an interactive menu to:
- Build Docker image
- Deploy to Kubernetes
- Update deployment
- Check status
- View logs
- Remove deployment

**Option 2: Via System Status**

1. Run: `gtd-wizard`
2. Choose: `17) 📊 System status`
3. Choose: `5) 🚀 Kubernetes Deployment Status`

This shows the current deployment status.

### 3. Documentation

- **`DEPLOYMENT_GUIDE.md`** - Complete deployment guide
- Updated `kubernetes/README.md` with deployment information
- Quick setup guides in `.cursor/` directory

## File Structure

```
dotfiles/
├── .cursor/
│   ├── mcp_config.json          # MCP config template
│   ├── setup_cursor_mcp.sh      # Setup script
│   ├── README.md                # Setup instructions
│   └── QUICK_SETUP.md           # Quick reference
├── mcp/
│   ├── deploy.sh                # Deployment script
│   ├── DEPLOYMENT_GUIDE.md      # Full deployment guide
│   └── kubernetes/
│       ├── deployment.yaml      # K8s deployment
│       └── service.yaml         # K8s service
└── bin/
    └── gtd-wizard               # Updated with deployment options
```

## Next Steps

### 1. Configure Cursor

```bash
cd .cursor
./setup_cursor_mcp.sh
```

Then restart Cursor and verify MCP connection.

### 2. Deploy Worker (Optional)

If you want background deep analysis:

```bash
gtd-wizard
# Navigate to deployment wizard
```

Or use the script directly:

```bash
cd mcp
./deploy.sh build
./deploy.sh deploy
```

### 3. Verify Everything Works

1. **MCP Server**: Check Cursor's MCP status indicator
2. **Worker**: Check deployment status via wizard or `kubectl`
3. **Test**: Ask the AI to use MCP tools

## Usage Examples

### Via Cursor (MCP Tools)

Once configured, you can ask Cursor:

- "What pending task suggestions do I have?"
- "List my tasks for computer context"
- "Create a task: Review the PR"
- "What's the status of project X?"

### Via gtd-wizard

Interactive menus for:
- Deployment management
- Status checking
- Log viewing
- System monitoring

## Troubleshooting

### Cursor MCP Not Connecting

1. Check setup: `cat ~/Library/Application\ Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
2. Verify paths in config
3. Test server: `python3 mcp/gtd_mcp_server.py`
4. Check Cursor logs: Help → Toggle Developer Tools

### Deployment Issues

See `DEPLOYMENT_GUIDE.md` for detailed troubleshooting, or use:

```bash
gtd-wizard
# Check status via deployment wizard
```

## See Also

- `mcp/README.md` - Main MCP documentation
- `mcp/DEPLOYMENT_GUIDE.md` - Deployment guide
- `mcp/CURSOR_MCP_CONFIG.md` - Cursor configuration details
- `.cursor/README.md` - Cursor setup instructions

