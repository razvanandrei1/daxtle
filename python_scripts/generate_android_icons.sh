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
FG_PADDING="0.215"   # 21.5% on each side for adaptive icons

# Extract background color from the first <rect fill="..."> in icon.svg
BG_COLOR=$(grep -oE '<rect[^>]*fill="[^"]*"' "$SVG_PATH" | head -1 | grep -oE 'fill="[^"]*"' | sed 's/fill="//;s/"//')
echo "Detected background color: $BG_COLOR"

mkdir -p "$OUT_DIR"
echo "Generating Android icons:"

# Compute content size for adaptive icons: 432 * (1 - 2 * 0.215) = 246
CANVAS=432
CONTENT_SIZE=$(python3 -c "print(int($CANVAS * (1.0 - 2.0 * $FG_PADDING)))")
TMP_CONTENT="/tmp/daxtle_fg_content.png"

# ── 1. Legacy icon — 192x192, full bleed ──────────────────────────────────────
cairosvg "$SVG_PATH" -o "$OUT_DIR/icon_192.png" -W 192 -H 192
echo "  icon_192.png           — 192x192"

# ── 2. Render content at reduced size for adaptive icons ──────────────────────
cairosvg "$SVG_PATH" -o "$TMP_CONTENT" -W "$CONTENT_SIZE" -H "$CONTENT_SIZE"

# ── 3. Adaptive foreground — remove background color, center on 432x432 ──────
magick "$TMP_CONTENT" \
  -fuzz 5% -transparent "$BG_COLOR" \
  -gravity center -background none -extent ${CANVAS}x${CANVAS} \
  "$OUT_DIR/icon_adaptive_fg.png"
echo "  icon_adaptive_fg.png   — ${CANVAS}x${CANVAS}, content ${CONTENT_SIZE}px (background removed)"

# ── 4. Adaptive background — solid fill matching SVG background ───────────────
magick -size ${CANVAS}x${CANVAS} "xc:$BG_COLOR" "$OUT_DIR/icon_adaptive_bg.png"
echo "  icon_adaptive_bg.png   — ${CANVAS}x${CANVAS}, solid $BG_COLOR"

# ── 5. Monochrome — non-background pixels → white, rest transparent ──────────
magick "$TMP_CONTENT" \
  -fuzz 5% -transparent "$BG_COLOR" \
  -fill white +opaque none \
  -gravity center -background none -extent ${CANVAS}x${CANVAS} \
  "$OUT_DIR/icon_adaptive_mono.png"
echo "  icon_adaptive_mono.png — ${CANVAS}x${CANVAS}, content ${CONTENT_SIZE}px"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -f "$TMP_CONTENT"

echo "Done!"
