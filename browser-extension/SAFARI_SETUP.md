# Safari Setup Guide

Safari supports Manifest V3 extensions (since Safari 15.4+), but requires packaging as a Safari App Extension using Xcode.

## Requirements

- macOS (you're on macOS, so you're good!)
- Xcode installed (from App Store or Apple Developer)
- Safari 14+ (for Web Extensions) or Safari 15.4+ (for full MV3 support)

## Method 1: Using safari-web-extension-converter (Easiest)

This tool automatically converts Chrome extensions to Safari format.

### Step 1: Install Xcode Command Line Tools

```bash
xcode-select --install
```

### Step 2: Convert Extension

```bash
cd ~/code/dotfiles/browser-extension

# Convert to Safari App Extension
safari-web-extension-converter . \
  --app-name "GTD Article Processor" \
  --swift \
  --bundle-identifier "com.yourname.gtd-article-processor"
```

This creates an Xcode project in a new directory.

### Step 3: Build and Run

1. Open the generated `.xcodeproj` file in Xcode
2. Select your development team in Signing & Capabilities
3. Build the project (⌘B)
4. Run the app (⌘R) - this installs the extension

### Step 4: Enable Extension in Safari

1. Open Safari
2. Safari → Preferences → Extensions
3. Check the box next to "GTD Article Processor"
4. You may need to click "Allow" when prompted

## Method 2: Manual Xcode Setup

If the converter doesn't work, you can create the extension manually:

### Step 1: Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "macOS" → "App"
4. Name it "GTD Article Processor"
5. Choose Swift and Storyboard

### Step 2: Add Safari Web Extension Target

1. File → New → Target
2. Choose "Safari Extension" → "Web Extension"
3. Name it "GTDArticleProcessorExtension"
4. Point the extension directory to your `browser-extension` folder

### Step 3: Configure

1. In the extension target settings:
   - Set "Extension Website" to your website (or use a placeholder)
   - Set "Extension Display Name" to "GTD Article Processor"

2. In Signing & Capabilities:
   - Select your development team
   - Enable "App Sandbox" if needed

### Step 4: Build and Run

1. Build the project (⌘B)
2. Run the app (⌘R)
3. Enable the extension in Safari Preferences

## Development Mode (Unsigned Extensions)

For testing without code signing:

1. Enable Safari Developer menu:
   - Safari → Preferences → Advanced
   - Check "Show Develop menu in menu bar"

2. Allow unsigned extensions:
   - Develop → Allow Unsigned Extensions

3. Now you can load unsigned extensions for testing

## Troubleshooting

### Extension doesn't appear in Safari

- Make sure you've built and run the Xcode project
- Check Safari → Preferences → Extensions
- Try restarting Safari

### Service worker issues

Safari's service workers have some limitations:
- On iOS, they may be killed after ~30-45 seconds
- On macOS, they're more stable but debugging can be tricky
- Use Console.app or Safari Web Inspector for debugging

### Permission errors

- Make sure host permissions are set in `manifest.json`
- Check Safari → Preferences → Websites → Extensions
- Grant necessary permissions

### Code signing errors

For development:
- Enable "Allow Unsigned Extensions" in Develop menu
- Or sign with your Apple Developer account

For distribution:
- You'll need an Apple Developer account ($99/year)
- Sign the app with your developer certificate
- Or distribute through Mac App Store

## Testing

1. Visit any article or blog post
2. Click the extension icon in Safari toolbar
3. Try "Summarize Article" to test the connection
4. Check Safari → Develop → Show Web Extension Background Content for debugging

## Differences from Chrome/Firefox

- **Service Workers**: May have shorter lifetime on iOS
- **Debugging**: Use Safari Web Inspector or Console.app
- **Distribution**: Must be signed (or use unsigned mode for dev)
- **Permissions**: May prompt differently than Chrome

## Resources

- [Safari Web Extensions Documentation](https://developer.apple.com/documentation/safariservices/safari_web_extensions)
- [Converting a Web Extension for Safari](https://developer.apple.com/documentation/safariservices/safari_web_extensions/converting_a_web_extension_for_safari)
