class_name GameTheme

# ── Palette definitions ────────────────────────────────────────────────────
# Each theme is a Dictionary with keys:
#   background  : Color  — scene/viewport clear colour
#   surface     : Color  — board square fill colour (Element A)
#   blocks      : Array[Color]  — B1…B4 block colours (max 4)

const WARM_SAND := {
	"background": Color(0.96, 0.94, 0.89),
	"surface":    Color(0.85, 0.82, 0.76),
	"fixed":      Color(0.35, 0.32, 0.28),  # C — dark charcoal-brown
	"blocks": [
		Color(0.29, 0.51, 0.79),  # B1 — blue
		Color(0.83, 0.38, 0.33),  # B2 — coral
		Color(0.24, 0.64, 0.57),  # B3 — teal
		Color(0.88, 0.65, 0.20),  # B4 — amber
	],
	"teleport": [
		Color(0.58, 0.28, 0.86),  # T1 — purple
		Color(0.22, 0.71, 0.87),  # T2 — cyan
		Color(0.95, 0.55, 0.12),  # T3 — orange
		Color(0.35, 0.82, 0.46),  # T4 — green
	],
}

const COOL_SLATE := {
	"background": Color(0.91, 0.93, 0.95),
	"surface":    Color(0.78, 0.82, 0.87),
	"fixed":      Color(0.30, 0.33, 0.38),  # C — dark blue-gray
	"blocks": [
		Color(0.27, 0.47, 0.78),  # B1 — blue
		Color(0.76, 0.33, 0.33),  # B2 — coral
		Color(0.27, 0.67, 0.61),  # B3 — teal
		Color(0.82, 0.61, 0.22),  # B4 — amber
	],
	"teleport": [
		Color(0.55, 0.25, 0.84),  # T1 — purple
		Color(0.18, 0.68, 0.85),  # T2 — cyan
		Color(0.92, 0.52, 0.10),  # T3 — orange
		Color(0.32, 0.78, 0.44),  # T4 — green
	],
}

const DARK_CHARCOAL := {
	"background": Color(0.13, 0.14, 0.16),
	"surface":    Color(0.21, 0.23, 0.27),
	"fixed":      Color(0.42, 0.44, 0.48),  # C — medium gray (lighter than surface for contrast)
	"blocks": [
		Color(0.38, 0.67, 0.96),  # B1 — blue
		Color(0.96, 0.48, 0.42),  # B2 — coral
		Color(0.33, 0.83, 0.72),  # B3 — teal
		Color(0.96, 0.78, 0.33),  # B4 — amber
	],
	"teleport": [
		Color(0.72, 0.42, 0.98),  # T1 — purple
		Color(0.30, 0.82, 0.96),  # T2 — cyan
		Color(0.98, 0.65, 0.22),  # T3 — orange
		Color(0.42, 0.92, 0.56),  # T4 — green
	],
}

# ── Active theme ───────────────────────────────────────────────────────────
# Change this constant to switch the entire game's colour scheme.
# Options: WARM_SAND | COOL_SLATE | DARK_CHARCOAL
const ACTIVE := WARM_SAND

# ── Layout constants ────────────────────────────────────────────────────────
const GAP_FRACTION    := 0.042   # gap between cells as a fraction of cell size
const CORNER_FRACTION := 0.08    # corner radius as a fraction of cell size

# ── Teleport portal colour ───────────────────────────────────────────────────
# Returns the colour for teleport pair at the given index (0-based), cycling if needed.
static func get_teleport_color(pair_index: int) -> Color:
	var colors: Array = ACTIVE["teleport"]
	return colors[pair_index % colors.size()]
