# Status Checks Added to gtd-wizard

Status checking functionality has been integrated into the `gtd-wizard` menu system.

## What Was Added

### 1. Enhanced Status Wizard (Option 17)

The existing "System status" option now has multiple sub-options:

**Main Menu → 17) 📊 System status**

Then choose:
- **1) Basic GTD System Status** - Quick overview of inbox, projects, tasks, logs
- **2) MCP Server & AI System Status** - LM Studio, MCP dependencies, pending suggestions
- **3) Background Worker Status** - Kubernetes/local worker, queue, results
- **4) Full System Status** - Runs comprehensive status script

### 2. Status Check in AI Menu (Option 23 → 9)

Added to AI Suggestions & MCP Tools menu:

**Main Menu → 23) 🤖 AI Suggestions & MCP Tools → 9) Check MCP System Status**

This runs the full `gtd_mcp_status.sh` script or shows quick checks.

## How to Use

### Quick Status Check

```bash
gtd-wizard
# Choose: 17
# Then choose: 2 (for MCP status) or 3 (for worker status)
```

### Full Status

```bash
gtd-wizard
# Choose: 17 → 4
# Runs comprehensive status check
```

### From AI Menu

```bash
gtd-wizard
# Choose: 23 → 9
# Check MCP system status
```

## What Each Check Shows

### Basic GTD Status (Option 1)
- Inbox count
- Active projects count
- Active tasks count
- Today's log entries
- Areas count

### MCP Server Status (Option 2)
- LM Studio running status
- Models loaded
- MCP SDK installed
- Pending suggestions count
- Connection status notes

### Background Worker Status (Option 3)
- Kubernetes deployment status
- Local worker process status
- Queue status (items waiting)
- Analysis results count
- Latest results

### Full Status (Option 4)
- Runs `gtd_mcp_status.sh` script
- Comprehensive check of all components
- Detailed output with colors and status indicators

## Benefits

1. **Integrated** - All status checks available from one place
2. **Accessible** - No need to remember separate commands
3. **Comprehensive** - Covers all components of the system
4. **User-friendly** - Clear menu options and status indicators

## Files Modified

- `bin/gtd-wizard` - Enhanced status_wizard() function
- Added status checking to AI suggestions menu

## Quick Reference

| Menu Path | What It Checks |
|-----------|---------------|
| 17 → 1 | Basic GTD stats |
| 17 → 2 | MCP & AI system |
| 17 → 3 | Background worker |
| 17 → 4 | Everything (full check) |
| 23 → 9 | MCP system status |

Now you can easily check the status of your entire GTD MCP system directly from the wizard! 🎉

