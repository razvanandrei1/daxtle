#!/bin/bash
# Regenerate iOS app icon from SVG.
# Renders a single 1024px PNG from icon.svg using cairosvg, copies it to the
# Xcode project, and patches Contents.json so iOS auto-generates all sizes.
# Run this after each Godot iOS export (called automatically by deploy_firebase.sh).
#
# Usage: ./scripts/tools/regenerate_ios_icons.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SVG="$PROJECT_DIR/icon.svg"
DST_DIR="$PROJECT_DIR/build/ios/daxtle/Images.xcassets/AppIcon.appiconset"

if [ ! -f "$SVG" ]; then
    echo "Error: icon.svg not found at $SVG"
    exit 1
fi

if [ ! -d "$DST_DIR" ]; then
    echo "Error: Icon directory not found at $DST_DIR"
    echo "Have you exported the iOS build from Godot?"
    exit 1
fi

if ! command -v cairosvg &> /dev/null; then
    echo "Error: cairosvg not found. Install with: pip3 install cairosvg"
    exit 1
fi

echo "Regenerating iOS icon from $SVG..."

# Render SVG to 1024px PNG
cairosvg "$SVG" -o "$DST_DIR/Icon-1024.png" --output-width 1024 --output-height 1024
echo "  Icon-1024.png ✓"

# Patch Contents.json — single icon, iOS auto-generates all sizes
cat > "$DST_DIR/Contents.json" << 'EOF'
{
  "images": [
    {
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024",
      "filename": "Icon-1024.png"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
EOF
echo "  Contents.json patched ✓"

echo "Done. iOS will auto-generate all sizes from the 1024px source."
