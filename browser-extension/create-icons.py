#!/usr/bin/env python3
"""
Create placeholder icons for the browser extension.
Uses Python PIL/Pillow if available, otherwise creates simple SVG icons.
"""

import os
import sys
from pathlib import Path

ICON_DIR = Path(__file__).parent / "icons"
ICON_DIR.mkdir(exist_ok=True)

def create_icons_with_pillow():
    """Create icons using Pillow (PIL)"""
    try:
        from PIL import Image, ImageDraw, ImageFont
        
        # Create 128x128 icon
        size = 128
        img = Image.new('RGB', (size, size), color='#4a90e2')
        draw = ImageDraw.Draw(img)
        
        # Try to use a nice font, fallback to default
        try:
            # Try to use system font
            font_size = 48
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 48)
            except:
                font = ImageFont.load_default()
        
        # Draw "GTD" text
        text = "GTD"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        position = ((size - text_width) // 2, (size - text_height) // 2)
        draw.text(position, text, fill='white', font=font)
        
        # Save all sizes
        img.save(ICON_DIR / "icon128.png")
        img.resize((48, 48), Image.Resampling.LANCZOS).save(ICON_DIR / "icon48.png")
        img.resize((16, 16), Image.Resampling.LANCZOS).save(ICON_DIR / "icon16.png")
        
        print(f"✅ Icons created successfully in {ICON_DIR}/")
        print("   - icon16.png (16x16)")
        print("   - icon48.png (48x48)")
        print("   - icon128.png (128x128)")
        return True
        
    except ImportError:
        return False
    except Exception as e:
        print(f"⚠️  Error creating icons with Pillow: {e}")
        return False

def create_icons_with_svg():
    """Create simple SVG icons as fallback"""
    svg_content = '''<svg width="128" height="128" xmlns="http://www.w3.org/2000/svg">
  <rect width="128" height="128" fill="#4a90e2"/>
  <text x="64" y="80" font-family="Arial, sans-serif" font-size="48" font-weight="bold" 
        text-anchor="middle" fill="white">GTD</text>
</svg>'''
    
    # Save SVG (browsers can use SVG icons in some cases)
    svg_path = ICON_DIR / "icon.svg"
    with open(svg_path, 'w') as f:
        f.write(svg_content)
    
    print(f"✅ SVG icon created: {svg_path}")
    print("   Note: You'll need to convert SVG to PNG for browser extensions.")
    print("   You can:")
    print("   1. Install Pillow: pip3 install Pillow")
    print("   2. Use an online converter: https://convertio.co/svg-png/")
    print("   3. Use ImageMagick: brew install imagemagick")
    return False

def create_simple_png_with_base64():
    """Create a simple PNG using base64 encoded data"""
    # This is a minimal 16x16 blue square as base64 PNG
    # For a real solution, we'd need Pillow or ImageMagick
    print("⚠️  Cannot create PNG icons without Pillow or ImageMagick")
    print("   Installing Pillow is recommended:")
    print("   pip3 install Pillow")
    return False

if __name__ == "__main__":
    print("Creating browser extension icons...")
    print()
    
    # Try Pillow first (best option)
    if create_icons_with_pillow():
        sys.exit(0)
    
    # Try SVG as fallback
    print()
    print("Pillow not available. Trying SVG fallback...")
    create_icons_with_svg()
    
    print()
    print("💡 To create proper PNG icons, you have two options:")
    print()
    print("   Option 1 (Recommended): Install ImageMagick")
    print("   brew install imagemagick")
    print("   ./create-icons.sh")
    print()
    print("   Option 2: Install Pillow in a virtual environment")
    print("   python3 -m venv .venv")
    print("   source .venv/bin/activate")
    print("   pip install Pillow")
    print("   python3 create-icons.py")
    print()
    print("   Option 3: Use an online converter")
    print("   Convert the SVG to PNG at: https://convertio.co/svg-png/")
    print("   Then resize to 16x16, 48x48, and 128x128")
