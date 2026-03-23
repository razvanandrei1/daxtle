# =============================================================================
# Globals.gd — Autoload singleton for global configuration
# =============================================================================
extends Node

## When true: skip all animations, go directly to Game scene on launch.
## The deploy script forces this to false for release builds.
const DEBUG_MODE := false

## When true: level selection opens the LevelEditor instead of the game,
## and a "New Level" button appears in Level Selection.
const LEVEL_EDITOR_MODE := true

## Temporary storage for level data passed between editor and play-test scene.
var editor_level_data: Dictionary = {}
var editor_level_number: int = -1

# ── UI layout constants ───────────────────────────────────────────────────────
const TOP_OFFSET := 37.0    # distance from safe area top to the UI bar
const LABEL_HEIGHT := 93.0  # height of the top bar (level number, icons)
