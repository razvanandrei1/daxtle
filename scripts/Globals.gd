# =============================================================================
# Globals.gd — Autoload singleton for global configuration
# =============================================================================
extends Node

## When true: skip all animations, go directly to Game scene on launch.
## The deploy script forces this to false for release builds.
const DEBUG_MODE := true
