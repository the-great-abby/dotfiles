# How to Know When Analysis Results Are Available

## Overview

Your GTD system automatically runs deep analysis (weekly reviews, energy analysis, insights, connections) in the background. Here's how you'll know when results are ready:

## 🔔 Notification Methods

### 1. macOS Notifications (Primary Method)

When analysis completes, you'll receive a **macOS notification**:

- **Title**: "✅ [Analysis Type] Complete" (e.g., "✅ Weekly Review Complete")
- **Message**: Preview of the analysis content
- **Sound**: Glass notification sound

**Configuration:**
```bash
# In .gtd_config_database:
GTD_NOTIFICATIONS="true"  # Enable/disable notifications
```

**Setup:**
```bash
gtd-wizard → 1) Configuration & Setup → 11) Setup Deep Analysis Auto-Scheduler → 4) Configure Notifications & Auto-Scan
```

### 2. Discord Notifications (Optional)

If you have Discord webhook configured, you'll also receive rich Discord notifications with full analysis previews.

**Setup:**
```bash
# Add to .gtd_config or .gtd_config_ai:
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
```

## 🎯 Auto-Scan to Suggestions (Recommended!)

Instead of manually checking results, enable **auto-scan** to automatically create suggestions from analysis results:

**What it does:**
- When analysis completes, automatically scans the results
- Extracts actionable items (tasks, projects, etc.)
- Creates suggestions in your suggestions folder
- You review suggestions through the normal workflow

**Enable it:**
```bash
gtd-wizard → 1) Configuration & Setup → 11) Setup Deep Analysis Auto-Scheduler → 4) Configure Notifications & Auto-Scan
```

Or manually in `.gtd_config_database`:
```bash
DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS="true"
DEEP_ANALYSIS_AUTO_SCAN_TYPES="connections,insights"  # Which types to scan
```

**Review suggestions:**
```bash
gtd-wizard → 23) AI Suggestions & MCP Tools → 2) Review pending suggestions
```

## 📊 Manual Checking

If you prefer to check manually:

### Check Status
```bash
gtd-wizard → 17) System status → 3) Background Worker Status
```

### View Latest Results
```bash
# Latest analysis result files
ls -lt ~/Documents/gtd/deep_analysis_results/*.json | head -5

# View a specific result
cat ~/Documents/gtd/deep_analysis_results/weekly_review_*.json | jq .
```

### Scan Results for Suggestions
```bash
gtd-wizard → 23) AI Suggestions & MCP Tools → 11) Scan Analysis Results for Suggestions
```

### View All Results
```bash
gtd-wizard → 23) AI Suggestions & MCP Tools → 12) View Analysis Results
```

## 📋 Suggestion Review Workflow (With Auto-Scan)

When auto-scan is enabled, here's the workflow:

1. **Analysis completes** → macOS notification appears
2. **Results saved** → Automatically scanned for suggestions
3. **Suggestions created** → Available in suggestions folder
4. **Review suggestions** → `gtd-wizard → AI Suggestions → Review pending suggestions`
5. **Create tasks/projects** → From suggestions you want to act on

## 🔍 How to Check What's Available

### Quick Check via Wizard
```bash
gtd-wizard → 17) System status
```

This shows:
- ✅ Latest analysis results
- ✅ Pending suggestions count
- ✅ Worker status
- ✅ Queue status

### Check via Status Script
```bash
~/code/dotfiles/mcp/gtd_mcp_status.sh
```

Shows comprehensive status including:
- Analysis results count
- Latest result file
- Pending suggestions

### Check via Command Line
```bash
# Count pending suggestions
find ~/Documents/gtd/suggestions -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; | wc -l

# Latest analysis result
ls -t ~/Documents/gtd/deep_analysis_results/*.json | head -1
```

## 🎛️ Configuration Summary

**Enable notifications:**
```bash
GTD_NOTIFICATIONS="true"
```

**Enable auto-scan:**
```bash
DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS="true"
DEEP_ANALYSIS_AUTO_SCAN_TYPES="connections,insights"
```

**Which types to scan:**
- `connections` - Connection analysis results
- `insights` - Insight generation results  
- `weekly_review` - Weekly review results
- `analyze_energy` - Energy analysis results

**Recommended setup:**
- ✅ Enable macOS notifications
- ✅ Enable auto-scan for `connections,insights`
- ✅ Review suggestions regularly via wizard

## 💡 Best Practice Workflow

1. **Enable auto-scan** → Results automatically become suggestions
2. **Review suggestions** → `gtd-wizard → AI Suggestions → Review pending suggestions`
3. **Create tasks/projects** → From suggestions you want to act on
4. **Check status periodically** → `gtd-wizard → System status`

This way, you don't have to manually check results - suggestions will surface actionable items automatically!

## 🔔 Notification Examples

**Weekly Review Complete:**
```
Title: ✅ Weekly Review Complete
Message: Analysis of your week's activities, tasks, and energy patterns...
```

**Energy Analysis Complete:**
```
Title: ✅ Energy Analysis Complete
Message: Energy patterns from the last 7 days show...
```

**Connections Found:**
```
Title: ✅ Connection Analysis Complete
Message: Found 3 connections between your tasks and projects...
```

## Summary

**You'll know when results are ready because:**

1. ✅ **macOS notification** appears when analysis completes
2. ✅ **Suggestions are created** (if auto-scan enabled) - review via wizard
3. ✅ **Results saved** to `~/Documents/gtd/deep_analysis_results/`
4. ✅ **Status checks** show latest results and pending suggestions

**Recommended: Enable auto-scan so suggestions surface automatically!**

