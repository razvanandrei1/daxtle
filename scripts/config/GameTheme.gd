class_name GameTheme

# ── Font ──────────────────────────────────────────────────────────────────
const FONT_BOLD: Font = preload("res://assets/fonts/Fredoka-Bold.tres")

# ── Palette definitions ────────────────────────────────────────────────────
# Each theme is a Dictionary with keys:
#   background  : Color  — scene/viewport clear colour
#   surface     : Color  — board square fill colour (Element A)
#   blocks      : Array[Color]  — B1…B4 block colours (max 4)

const WARM_SAND := {
	"background": Color(0xf5f0e3ff),
	"surface":    Color(0.85, 0.82, 0.76),
	"text":       Color(0x2b7366ff),  # primary text colour — B1 teal darkened 30% (matches triangle)
	"fixed":      Color(0.35, 0.32, 0.28),  # C — dark charcoal-brown
	"blocks": [
		Color(0x3da391ff),  # B1 — teal
		Color(0.83, 0.38, 0.33),  # B2 — coral
		Color(0.29, 0.51, 0.79),  # B3 — blue
		Color(0.88, 0.65, 0.20),  # B4 — amber
	],
	"teleport": [
		Color(0.85, 0.31, 0.56),  # T1 — magenta
		Color(0.31, 0.64, 0.85),  # T2 — electric blue
		Color(0.85, 0.66, 0.31),  # T3 — gold
		Color(0.31, 0.85, 0.66),  # T4 — teal
	],
}

const COOL_SLATE := {
	"background": Color(0.91, 0.93, 0.95),
	"surface":    Color(0.78, 0.82, 0.87),
	"text":       Color(0.22, 0.25, 0.30),  # primary text colour
	"fixed":      Color(0.30, 0.33, 0.38),  # C — dark blue-gray
	"blocks": [
		Color(0.27, 0.47, 0.78),  # B1 — blue
		Color(0.76, 0.33, 0.33),  # B2 — coral
		Color(0.27, 0.67, 0.61),  # B3 — teal
		Color(0.82, 0.61, 0.22),  # B4 — amber
	],
	"teleport": [
		Color(0.85, 0.31, 0.56),  # T1 — magenta
		Color(0.31, 0.64, 0.85),  # T2 — electric blue
		Color(0.85, 0.66, 0.31),  # T3 — gold
		Color(0.31, 0.85, 0.66),  # T4 — teal
	],
}

const DARK_CHARCOAL := {
	"background": Color(0.13, 0.14, 0.16),
	"surface":    Color(0.21, 0.23, 0.27),
	"text":       Color(0.88, 0.88, 0.90),  # primary text colour (light on dark)
	"fixed":      Color(0.42, 0.44, 0.48),  # C — medium gray (lighter than surface for contrast)
	"blocks": [
		Color(0.38, 0.67, 0.96),  # B1 — blue
		Color(0.96, 0.48, 0.42),  # B2 — coral
		Color(0.33, 0.83, 0.72),  # B3 — teal
		Color(0.96, 0.78, 0.33),  # B4 — amber
	],
	"teleport": [
		Color(0.85, 0.31, 0.56),  # T1 — magenta
		Color(0.31, 0.64, 0.85),  # T2 — electric blue
		Color(0.85, 0.66, 0.31),  # T3 — gold
		Color(0.31, 0.85, 0.66),  # T4 — teal
	],
}

# ── Active theme ───────────────────────────────────────────────────────────
# Change this constant to switch the entire game's colour scheme.
# Options: WARM_SAND | COOL_SLATE | DARK_CHARCOAL
const ACTIVE := WARM_SAND

# ── Layout constants ────────────────────────────────────────────────────────
const GAP_FRACTION    := 0.064   # gap between cells as a fraction of cell size
const CORNER_FRACTION       := 0.126   # corner radius for squares
const ARROW_CORNER_FRACTION := 0.08   # corner radius for arrow triangles (unchanged)
const BLOCK_INSET_FRACTION  := 0.0725  # block shrink per side so target border is visible

# ── Teleport portal colour ───────────────────────────────────────────────────
# Returns the colour for teleport pair at the given index (0-based), cycling if needed.
# ── Safe area (notch / status bar / home indicator) ────────────────────────
# Returns the top inset in pixels (0 on devices without a notch).
static func get_safe_area_top() -> float:
	var safe := DisplayServer.get_display_safe_area()
	return safe.position.y

# Returns the bottom inset in pixels.
static func get_safe_area_bottom() -> float:
	var safe   := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	return screen.y - safe.end.y


static func get_teleport_color(pair_index: int) -> Color:
	var colors: Array = ACTIVE["teleport"]
	return colors[pair_index % colors.size()]


# ── Universal tap pulse ────────────────────────────────────────────────────
# Plays a scale-up / scale-down pulse on any Node2D, then calls `on_done`.
# Use for all tappable icons and buttons.
const PULSE_UP   := 1.15
const PULSE_DUR1 := 0.09   # scale-up duration
const PULSE_DUR2 := 0.12   # scale-down duration

static func play_tap_pulse(node: Node2D, on_done: Callable) -> void:
	AudioManager.play_sfx("click")
	Haptics.tap()
	var orig_scale := node.scale
	var tween := node.create_tween()
	tween.tween_property(node, "scale", orig_scale * PULSE_UP, PULSE_DUR1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", orig_scale, PULSE_DUR2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(on_done)
