# =============================================================================
# Globals.gd — Autoload singleton for global configuration
# =============================================================================
extends Node

## When true: skip all animations, go directly to Game scene on launch.
## The deploy script forces this to false for release builds.
const DEBUG_MODE := false

# ── UI layout constants ───────────────────────────────────────────────────────
const TOP_OFFSET := 37.0    # distance from safe area top to the UI bar
const LABEL_HEIGHT := 93.0  # height of the top bar (level number, icons)
