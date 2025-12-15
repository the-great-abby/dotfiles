# Google Health/Fitness Integration Setup

This guide shows you how to set up Google Health/Fitness integration to automatically log health data to your daily log.

## 🎯 What This Does

Automatically logs health data from Google Fit/Google Health to your daily log:
- **Workouts** (type, duration, calories, distance)
- **Steps** (daily step count)
- **Heart Rate** (resting, walking average, workout average)
- **Active Energy** (calories burned)
- **Exercise Minutes** (active time)
- **Sleep** (sleep duration and quality)

## 🚀 Quick Setup

### Option A: Google Takeout Export (Recommended - Easiest)

This is the simplest and most reliable method:

1. **Export Your Google Fit Data**
   - Go to [Google Takeout](https://takeout.google.com/)
   - Deselect all services, then select only **"Google Fit"**
   - Choose JSON format
   - Click "Create export" and wait for completion
   - Download and extract the archive

2. **Place Export in Config Directory**
   ```bash
   # Extract the Takeout folder
   # Then copy/move it to:
   ~/code/dotfiles/.google_health/takeout/
   
   # Or use a custom path
   ```

3. **Sync Your Data**
   ```bash
   # Sync from default location
   gtd-sync-google-health
   
   # Or specify custom path
   gtd-sync-google-health --takeout ~/Downloads/Takeout
   ```

4. **Set Up Regular Exports**
   - Export from Google Takeout weekly/monthly
   - Run `gtd-sync-google-health` after each export
   - Or automate with a cron job or script

### Option B: Data Portability API (Advanced)

For automated, programmatic access (requires OAuth setup):

1. **Set Up Google Cloud Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable **"Google Data Portability API"**

2. **Create OAuth Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Choose "Desktop app" as application type
   - Download the credentials JSON file

3. **Save Credentials**
   ```bash
   # Create config directory
   mkdir -p ~/code/dotfiles/.google_health
   
   # Save credentials file
   # Copy downloaded JSON to:
   ~/code/dotfiles/.google_health/credentials.json
   ```

4. **Install Python Dependencies**
   ```bash
   # If using the MCP virtualenv
   cd ~/code/dotfiles/mcp
   source venv/bin/activate  # or use your venv
   pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
   
   # Or install globally
   pip3 install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
   ```

5. **First-Time Authentication**
   ```bash
   gtd-sync-google-health --api
   ```
   - This will open a browser for OAuth authentication
   - Grant permissions to access your Google Fit data
   - Token will be saved for future use

6. **Sync Your Data**
   ```bash
   # Sync using API
   gtd-sync-google-health --api
   
   # Sync specific date
   gtd-sync-google-health --api --date 2024-12-15
   ```

## 📋 Usage

### Basic Commands

```bash
# Sync from default Takeout location
gtd-sync-google-health

# Sync from specific Takeout path
gtd-sync-google-health --takeout /path/to/takeout

# Use API mode
gtd-sync-google-health --api

# Force sync even if already logged today
gtd-sync-google-health --force

# Sync specific date
gtd-sync-google-health --date 2024-12-15
```

### Via Wizard

1. Run `gtd-wizard` or `make gtd-wizard`
2. Select option **30** (HealthKit & Health Data)
3. Select option **9** (Sync Health Data from Google Health/Fitness)

## 🔧 Configuration

### Config Directory

All configuration files are stored in:
```
~/code/dotfiles/.google_health/
```

Or if using personal dotfiles:
```
~/code/personal/dotfiles/.google_health/
```

### Files

- `credentials.json` - OAuth credentials (API mode)
- `token.json` - OAuth token (auto-generated, API mode)
- `takeout/` - Directory for Google Takeout exports

### Environment Variables

You can set these in your `.gtd_config` or shell config:

```bash
# Custom Takeout directory
export GOOGLE_HEALTH_TAKEOUT_DIR="$HOME/Downloads/Takeout"

# Custom config directory
export GOOGLE_HEALTH_CONFIG_DIR="$HOME/.config/google_health"
```

## 📊 What Gets Logged

The integration logs entries like:

```
14:30 - Google Fit Daily Summary - 12,345 steps - 500 calories - 45 min active
15:00 - Google Fit Running - 30 min - 300 calories - 5.2 km
16:00 - Google Fit Heart Rate: 72 bpm
```

These entries are compatible with the existing HealthKit wizard and can be viewed using:
- Option 1: View Today's Health Summary
- Option 2: View Health Data for Specific Date
- Option 3: View Health Trends

## 🔄 Automation

### Weekly Takeout Sync

Add to your crontab or automation:

```bash
# Weekly sync on Sundays at 9 AM
0 9 * * 0 cd ~/code/dotfiles && gtd-sync-google-health --takeout ~/Downloads/Takeout
```

### Evening Routine Integration

Add to your evening routine script:

```bash
# In your evening routine
if command -v gtd-sync-google-health &>/dev/null; then
  echo "Syncing Google Health data..."
  gtd-sync-google-health
fi
```

## 🐛 Troubleshooting

### "gtd-sync-google-health not found"

Make sure the script is executable:
```bash
chmod +x ~/code/dotfiles/bin/gtd-sync-google-health
```

### "No JSON files found"

- Verify your Takeout export contains Google Fit data
- Check that the path is correct
- Ensure JSON files are in the expected directory structure

### "Google API libraries not available"

Install the required packages:
```bash
pip3 install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
```

### "Credentials file not found"

For API mode, make sure you've:
1. Created OAuth credentials in Google Cloud Console
2. Saved the JSON file to `~/.google_health/credentials.json`

### Data Not Appearing in Logs

- Check that `gtd-healthkit-log` is working: `gtd-healthkit-log "Test entry" "12:00"`
- Verify your daily log directory is correct
- Check file permissions

## 💡 Tips

1. **Regular Exports**: Set up a reminder to export from Google Takeout weekly or monthly
2. **Backup**: Keep your Takeout exports as backups
3. **Privacy**: OAuth tokens are stored locally and never shared
4. **Compatibility**: Google Health entries work with all existing HealthKit wizard features
5. **Multiple Sources**: You can use both Apple Health and Google Health - they'll both appear in your logs

## 📚 Related Documentation

- `APPLE_HEALTH_SHORTCUTS_SETUP.md` - Apple Health integration
- `HEALTHKIT_WIZARD_INTEGRATION.md` - Using the HealthKit wizard
- `EVENING_HEALTH_SYNC_SETUP.md` - Automatic sync setup

## 🔗 Resources

- [Google Takeout](https://takeout.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Data Portability API](https://developers.google.com/data-portability)
