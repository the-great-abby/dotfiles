# Google Health OAuth Setup Guide

This guide walks you through setting up OAuth authentication for Google Health/Fitness API access.

## 🎯 Quick Setup (5 minutes)

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name it (e.g., "GTD Health Sync")
4. Click "Create"

### Step 2: Enable Data Portability API

1. In your project, go to "APIs & Services" → "Library"
2. Search for "Data Portability API"
3. Click on it and press "Enable"

### Step 3: Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "+ CREATE CREDENTIALS" → "OAuth client ID"
3. If prompted, configure OAuth consent screen:
   - User Type: "External" (or "Internal" if using Google Workspace)
   - App name: "GTD Health Sync"
   - User support email: Your email
   - Developer contact: Your email
   - Click "Save and Continue"
   - Scopes: Click "Add or Remove Scopes"
     - Search for "Data Portability" and select it
     - Click "Update" → "Save and Continue"
   - Test users: Add your Google account email
   - Click "Save and Continue" → "Back to Dashboard"

4. Create OAuth Client ID:
   - Application type: **"Desktop app"**
   - Name: "GTD Health Sync Desktop"
   - Click "Create"

5. Download credentials:
   - Click "Download JSON" (or copy the JSON)
   - Save the file

### Step 4: Save Credentials

```bash
# Create config directory
mkdir -p ~/code/dotfiles/.google_health

# Copy downloaded JSON file to:
# ~/code/dotfiles/.google_health/credentials.json

# Or if using personal dotfiles:
mkdir -p ~/code/personal/dotfiles/.google_health
# Copy to: ~/code/personal/dotfiles/.google_health/credentials.json
```

### Step 5: First-Time Authentication

Run the sync command with `--api` flag:

```bash
gtd-sync-google-health --api
```

This will:
1. Open your browser
2. Ask you to sign in with your Google account
3. Request permission to access your Google Fit data
4. Save the authentication token for future use

**Note:** The token is stored locally at `~/.google_health/token.json` and never shared.

## 🔒 Security Notes

- **Credentials file** (`credentials.json`): Contains your OAuth client ID/secret. Keep this private.
- **Token file** (`token.json`): Auto-generated, contains your access token. Also keep private.
- Both files are stored locally and never uploaded or shared.
- You can revoke access anytime from [Google Account Security](https://myaccount.google.com/permissions)

## 🔄 Token Refresh

The token will automatically refresh when it expires. If you see authentication errors:

1. Delete the token file: `rm ~/code/dotfiles/.google_health/token.json`
2. Run the sync again: `gtd-sync-google-health --api`
3. Re-authenticate in the browser

## 🐛 Troubleshooting

### "Credentials file not found"

- Make sure you downloaded the JSON file from Google Cloud Console
- Check the path: `~/code/dotfiles/.google_health/credentials.json`
- Verify the file is valid JSON

### "Access denied" or "Permission denied"

- Make sure you enabled "Data Portability API" in Google Cloud Console
- Check that you added your email as a test user (if using External app type)
- Verify the OAuth consent screen is configured

### "Invalid client" error

- Make sure you selected "Desktop app" as application type
- Re-download the credentials JSON file
- Check that the project has Data Portability API enabled

### Browser doesn't open

- Make sure you're running from a terminal (not a script)
- Try running with `--api` flag explicitly
- Check firewall settings

## 📚 Alternative: Use Google Takeout (No OAuth Needed)

If OAuth setup seems complicated, you can use Google Takeout instead:

1. Go to [Google Takeout](https://takeout.google.com/)
2. Select "Google Fit"
3. Download and extract
4. Run: `gtd-sync-google-health --takeout /path/to/takeout`

This doesn't require any authentication setup!

## 🔗 Resources

- [Google Cloud Console](https://console.cloud.google.com/)
- [OAuth 2.0 Setup Guide](https://developers.google.com/identity/protocols/oauth2)
- [Data Portability API](https://developers.google.com/data-portability)
