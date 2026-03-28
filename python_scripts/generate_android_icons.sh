#!/usr/bin/env bash
# Generates Android launcher icons from icon.svg.
# Extracts the background color from the SVG's first <rect> fill automatically.
# Requirements: cairosvg (pip3 install cairosvg), ImageMagick (brew install imagemagick)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SVG_PATH="$PROJECT_ROOT/icon.svg"
OUT_DIR="$PROJECT_ROOT/assets/android_icons"

# Padding config
FG_PADDING="0.20"    # 30% on each side — keeps triangle within adaptive icon safe zone

# Extract background color from the first <rect fill="..."> in icon.svg
BG_COLOR=$(grep -oE '<rect[^>]*fill="[^"]*"' "$SVG_PATH" | head -1 | grep -oE 'fill="[^"]*"' | sed 's/fill="//;s/"//')
echo "Detected background color: $BG_COLOR"

mkdir -p "$OUT_DIR"
echo "Generating Android icons:"

# Compute content size for adaptive icons
CANVAS=432
CONTENT_SIZE=$(python3 -c "print(int($CANVAS * (1.0 - 2.0 * $FG_PADDING)))")
TMP_FG_SVG="/tmp/daxtle_fg.svg"
TMP_FG_PNG="/tmp/daxtle_fg.png"

# Create a foreground-only SVG by removing the full-size background <rect>
# Matches the 1024x1024 rect specifically, keeps all other elements
sed '/<rect width="1024" height="1024"/d' "$SVG_PATH" > "$TMP_FG_SVG"

# ── 1. Legacy icon — 192x192, full bleed ──────────────────────────────────────
cairosvg "$SVG_PATH" -o "$OUT_DIR/icon_192.png" -W 192 -H 192
echo "  icon_192.png           — 192x192"

# ── 2. Render foreground (transparent background), then resize + pad ───────────
cairosvg "$TMP_FG_SVG" -o "$TMP_FG_PNG"
magick "$TMP_FG_PNG" \
  -resize ${CONTENT_SIZE}x${CONTENT_SIZE} \
  -gravity center -background none -extent ${CANVAS}x${CANVAS} \
  "$OUT_DIR/icon_adaptive_fg.png"
echo "  icon_adaptive_fg.png   — ${CANVAS}x${CANVAS}, content ${CONTENT_SIZE}px"

# ── 4. Adaptive background — solid fill matching SVG background ───────────────
magick -size ${CANVAS}x${CANVAS} "xc:$BG_COLOR" "$OUT_DIR/icon_adaptive_bg.png"
echo "  icon_adaptive_bg.png   — ${CANVAS}x${CANVAS}, solid $BG_COLOR"

# ── 5. Monochrome — foreground pixels → white, rest transparent ───────────────
magick "$TMP_FG_PNG" \
  -resize ${CONTENT_SIZE}x${CONTENT_SIZE} \
  -fill white -colorize 100 \
  -gravity center -background none -extent ${CANVAS}x${CANVAS} \
  "$OUT_DIR/icon_adaptive_mono.png"
echo "  icon_adaptive_mono.png — ${CANVAS}x${CANVAS}, content ${CONTENT_SIZE}px"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -f "$TMP_FG_SVG" "$TMP_FG_PNG"

echo "Done!"
