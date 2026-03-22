#!/usr/bin/env python3
"""
Generates Android launcher icons from icon.svg.
Run from the project root: python3 scripts/tools/generate_icons.py
"""

import io
import os
import sys

try:
    import cairosvg
    from PIL import Image
except ImportError:
    print("Required: pip3 install cairosvg Pillow")
    sys.exit(1)

# ── Configuration ─────────────────────────────────────────────────────────────
PROJECT_ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SVG_PATH     = os.path.join(PROJECT_ROOT, "icon.svg")
OUT_DIR      = os.path.join(PROJECT_ROOT, "assets", "android_icons")

LEGACY_PADDING = 0.0     # 192px icon: no padding
FG_PADDING     = 0.215   # adaptive foreground: 21.5% padding
MONO_PADDING   = 0.215   # monochrome: same as foreground

BG_COLOR       = (245, 240, 227)  # Warm Sand
BG_THRESHOLD   = 10               # tolerance for background detection


# ── Helpers ───────────────────────────────────────────────────────────────────
def svg_to_image(size: int) -> Image.Image:
    png_data = cairosvg.svg2png(url=SVG_PATH, output_width=size, output_height=size)
    return Image.open(io.BytesIO(png_data)).convert("RGBA")


def remove_background(img: Image.Image) -> Image.Image:
    img = img.copy()
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if (abs(r - BG_COLOR[0]) < BG_THRESHOLD and
                abs(g - BG_COLOR[1]) < BG_THRESHOLD and
                abs(b - BG_COLOR[2]) < BG_THRESHOLD):
                pixels[x, y] = (0, 0, 0, 0)
    return img


def to_monochrome(img: Image.Image) -> Image.Image:
    img = img.copy()
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if (abs(r - BG_COLOR[0]) < BG_THRESHOLD and
                abs(g - BG_COLOR[1]) < BG_THRESHOLD and
                abs(b - BG_COLOR[2]) < BG_THRESHOLD):
                pixels[x, y] = (0, 0, 0, 0)
            elif a > 0:
                pixels[x, y] = (255, 255, 255, a)
    return img


def place_centered(content: Image.Image, canvas_size: int) -> Image.Image:
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = (canvas_size - content.width) // 2
    canvas.paste(content, (offset, offset), content)
    return canvas


# ── Generators ────────────────────────────────────────────────────────────────
def generate_legacy():
    size = 192
    content_size = int(size * (1.0 - 2.0 * LEGACY_PADDING))
    content = svg_to_image(content_size)
    canvas = Image.new("RGBA", (size, size), BG_COLOR + (255,))
    offset = (size - content_size) // 2
    canvas.paste(content, (offset, offset), content)
    canvas.save(os.path.join(OUT_DIR, "icon_192.png"))
    print(f"  icon_192.png           — {size}x{size}, content {content_size}px, padding {LEGACY_PADDING:.0%}")


def generate_foreground():
    size = 432
    content_size = int(size * (1.0 - 2.0 * FG_PADDING))
    content = remove_background(svg_to_image(content_size))
    place_centered(content, size).save(os.path.join(OUT_DIR, "icon_adaptive_fg.png"))
    print(f"  icon_adaptive_fg.png   — {size}x{size}, content {content_size}px, padding {FG_PADDING:.0%}")


def generate_background():
    img = Image.new("RGBA", (432, 432), (255, 255, 255, 255))
    img.save(os.path.join(OUT_DIR, "icon_adaptive_bg.png"))
    print(f"  icon_adaptive_bg.png   — 432x432, white background")


def generate_monochrome():
    size = 432
    content_size = int(size * (1.0 - 2.0 * MONO_PADDING))
    content = to_monochrome(svg_to_image(content_size))
    place_centered(content, size).save(os.path.join(OUT_DIR, "icon_adaptive_mono.png"))
    print(f"  icon_adaptive_mono.png — {size}x{size}, content {content_size}px, padding {MONO_PADDING:.0%}")


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    print("Generating Android icons:")
    generate_legacy()
    generate_foreground()
    generate_background()
    generate_monochrome()
    print("Done!")
