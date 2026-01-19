#!/bin/bash
# Create placeholder icons for the browser extension
# Requires ImageMagick (convert command) or falls back to Python script

ICON_DIR="icons"
mkdir -p "$ICON_DIR"

# Check if ImageMagick is available
if command -v convert &> /dev/null; then
    echo "✅ Using ImageMagick to create icons..."
    
    # Create a simple icon with text "GTD"
    convert -size 128x128 xc:#4a90e2 \
      -gravity center \
      -pointsize 48 \
      -fill white \
      -font Arial-Bold \
      -annotate +0+0 "GTD" \
      "$ICON_DIR/icon128.png"
    
    # Resize to other sizes
    convert "$ICON_DIR/icon128.png" -resize 48x48 "$ICON_DIR/icon48.png"
    convert "$ICON_DIR/icon128.png" -resize 16x16 "$ICON_DIR/icon16.png"
    
    echo "✅ Icons created successfully in $ICON_DIR/"
    echo "   - icon16.png (16x16)"
    echo "   - icon48.png (48x48)"
    echo "   - icon128.png (128x128)"
elif command -v python3 &> /dev/null; then
    echo "⚠️  ImageMagick not found. Trying Python script..."
    echo ""
    python3 "$(dirname "$0")/create-icons.py"
else
    echo "❌ Neither ImageMagick nor Python3 found."
    echo ""
    echo "📦 To create icons, install ImageMagick (recommended):"
    echo "   brew install imagemagick"
    echo ""
    echo "   Then run this script again:"
    echo "   ./create-icons.sh"
    echo ""
    echo "💡 Alternative: Create icons manually or use an online tool:"
    echo "   - icon16.png (16x16 pixels, blue background with 'GTD' text)"
    echo "   - icon48.png (48x48 pixels)"
    echo "   - icon128.png (128x128 pixels)"
    echo ""
    echo "   Online tool: https://www.favicon-generator.org/"
    exit 1
fi
