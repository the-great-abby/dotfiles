# Quick Install Guide

## Step 1: Create Icons (Optional but Recommended)

The extension will work without icons, but they make it look better.

**Easiest method - Install ImageMagick:**
```bash
brew install imagemagick
cd browser-extension
./create-icons.sh
```

**Alternative - Use Python (if you have Pillow):**
```bash
cd browser-extension
python3 create-icons.py
```

**Manual method:**
Create three PNG files in the `icons/` directory:
- `icon16.png` (16x16 pixels)
- `icon48.png` (48x48 pixels)  
- `icon128.png` (128x128 pixels)

You can use any image editor or online tool like https://www.favicon-generator.org/

**Note:** The extension will work even without icons - browsers will use a default icon.

## Step 2: Load Extension in Browser

### Chrome/Edge/Brave (Easiest)
1. Open `chrome://extensions/` (or `edge://extensions/`)
2. Enable "Developer mode" (top right toggle)
3. Click "Load unpacked"
4. Select the `browser-extension` folder

### Firefox
1. Open `about:debugging`
2. Click "This Firefox"
3. Click "Load Temporary Add-on"
4. Select `browser-extension/manifest.json`

### Safari (Requires Xcode)
Safari supports Manifest V3, but requires packaging as a Safari App Extension:

**Option A: Quick Test (Safari 14+)**
1. Enable Safari Developer menu: Safari → Preferences → Advanced → "Show Develop menu"
2. Develop → Allow Unsigned Extensions
3. Open Terminal and run:
   ```bash
   cd ~/code/dotfiles/browser-extension
   safari-web-extension-converter . --app-name "GTD Article Processor" --swift
   ```
   (This requires Xcode Command Line Tools)
4. Open the generated Xcode project and build it
5. Enable the extension in Safari → Preferences → Extensions

**Option B: Manual Xcode Setup**
1. Open Xcode
2. File → New → Project → macOS → App
3. Add Safari Web Extension target
4. Point it to your `browser-extension` folder
5. Build and run, then enable in Safari Preferences

**Note**: Safari extensions must be signed. For development, you can use your Apple Developer account or enable "Allow Unsigned Extensions" in Safari Develop menu.

## Step 3: Start Your API

Make sure your FastAPI backend is running:
```bash
cd ~/code/dotfiles/web/backend
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
```

## Step 4: Configure Extension

1. Click the extension icon in your browser
2. Open Settings (⚙️)
3. Set API Endpoint: `http://localhost:8000`
4. Click "Save Settings"

## Step 5: Test It!

1. Visit any article or blog post
2. Click the extension icon
3. Try "Summarize Article" to test the connection

That's it! You're ready to process articles with your GTD system.
