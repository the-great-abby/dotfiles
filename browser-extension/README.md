# GTD Article Processor Browser Extension

A browser extension that extracts content from web pages and processes it with your GTD system and LLM.

## Features

- **Extract Article Content**: Automatically extracts title, URL, and text content from any web page
- **Summarize Articles**: Generate concise summaries with key points
- **Extract Task Suggestions**: Use AI to identify actionable tasks from article content
- **Create Tasks**: Quickly create GTD tasks from articles
- **Deep Analysis**: Get insights and connections from article content

## Installation

### Chrome/Edge/Brave (Recommended - Easiest)

1. Open Chrome/Edge/Brave and navigate to `chrome://extensions/` (or `edge://extensions/` for Edge)
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select the `browser-extension` directory

### Firefox

1. Open Firefox and navigate to `about:debugging`
2. Click "This Firefox"
3. Click "Load Temporary Add-on"
4. Select `browser-extension/manifest.json`

### Safari

Safari supports Manifest V3 (Safari 15.4+), but requires additional setup:

**Requirements:**
- Xcode installed
- Safari 14+ (for Web Extensions) or Safari 15.4+ (for full MV3 support)

**Quick Setup:**
```bash
cd browser-extension
# Convert to Safari App Extension (requires Xcode)
safari-web-extension-converter . --app-name "GTD Article Processor" --swift
```

Then:
1. Open the generated Xcode project
2. Build the project (⌘B)
3. Run the app (⌘R)
4. Enable the extension: Safari → Preferences → Extensions → Check "GTD Article Processor"

**Development Mode:**
1. Enable Safari Developer menu: Safari → Preferences → Advanced → "Show Develop menu"
2. Develop → Allow Unsigned Extensions
3. This allows testing without code signing

**Note**: Safari extensions must be signed for distribution. For personal use, you can enable "Allow Unsigned Extensions" in development mode.

## Setup

1. **Start your GTD Web API** (if not already running):
   ```bash
   cd ~/code/dotfiles/web/backend
   python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
   ```

2. **Configure the extension**:
   - Click the extension icon
   - Open Settings (⚙️)
   - Set API Endpoint to `http://localhost:8000` (or your API URL)
   - Click "Save Settings"

## Usage

1. Navigate to any web page with article content
2. Click the extension icon
3. Choose an action:
   - **📝 Summarize Article**: Get a summary with key points
   - **✅ Extract Task Suggestions**: Identify actionable tasks
   - **➕ Create Task from Article**: Create a GTD task
   - **🧠 Deep Analysis**: Get insights and connections

## How It Works

1. **Content Extraction**: The extension extracts page content using the content script
2. **API Communication**: Content is sent to your FastAPI backend at `/api/browser/process`
3. **LLM Processing**: The backend uses your MCP server to process content with AI
4. **GTD Integration**: Results are integrated with your GTD system (tasks, suggestions, etc.)

## API Endpoint

The extension communicates with your FastAPI backend at:

```
POST /api/browser/process
```

Request body:
```json
{
  "action": "summarize|suggest_tasks|create_task|analyze",
  "content": {
    "url": "https://example.com/article",
    "title": "Article Title",
    "text": "Article content...",
    "description": "Meta description",
    "author": "Author name"
  }
}
```

## Troubleshooting

### Extension can't connect to API

- Make sure your FastAPI backend is running on `http://localhost:8000`
- Check that CORS is enabled for browser extensions (should be automatic)
- Verify the API endpoint in extension settings

### Content extraction fails

- Some pages may block content extraction
- Try refreshing the page and clicking the extension again
- Check browser console for errors (F12 → Console)

### MCP server errors

- Ensure your MCP server dependencies are installed:
  ```bash
  cd ~/code/dotfiles/mcp
  pip install -r requirements.txt
  ```
- Check that your GTD config file exists at `~/.gtd_config`

## Development

### File Structure

```
browser-extension/
├── manifest.json       # Extension manifest
├── content.js         # Content script (runs on web pages)
├── popup.html         # Extension popup UI
├── popup.js           # Popup logic
├── popup.css          # Popup styles
├── background.js      # Background service worker
├── icons/             # Extension icons
└── README.md          # This file
```

### Testing

1. Load the extension in developer mode
2. Open browser console (F12) to see logs
3. Test on various websites to ensure content extraction works
4. Check FastAPI logs for API requests

## Icons

Place icon files in the `icons/` directory:
- `icon16.png` (16x16)
- `icon48.png` (48x48)
- `icon128.png` (128x128)

You can create simple icons or use a placeholder image generator.

## License

Part of the GTD Unified System dotfiles repository.
