class_name GameTheme

# ── Palette definitions ────────────────────────────────────────────────────
# Each theme is a Dictionary with keys:
#   background  : Color  — scene/viewport clear colour
#   surface     : Color  — board square fill colour (Element A)
#   blocks      : Array[Color]  — B1…B4 block colours (max 4)

const WARM_SAND := {
	"background": Color(0.96, 0.94, 0.89),
	"surface":    Color(0.85, 0.82, 0.76),
	"blocks": [
		Color(0.29, 0.51, 0.79),  # B1 — blue
		Color(0.83, 0.38, 0.33),  # B2 — coral
		Color(0.24, 0.64, 0.57),  # B3 — teal
		Color(0.88, 0.65, 0.20),  # B4 — amber
	],
}

const COOL_SLATE := {
	"background": Color(0.91, 0.93, 0.95),
	"surface":    Color(0.78, 0.82, 0.87),
	"blocks": [
		Color(0.27, 0.47, 0.78),  # B1 — blue
		Color(0.76, 0.33, 0.33),  # B2 — coral
		Color(0.27, 0.67, 0.61),  # B3 — teal
		Color(0.82, 0.61, 0.22),  # B4 — amber
	],
}

const DARK_CHARCOAL := {
	"background": Color(0.13, 0.14, 0.16),
	"surface":    Color(0.21, 0.23, 0.27),
	"blocks": [
		Color(0.38, 0.67, 0.96),  # B1 — blue
		Color(0.96, 0.48, 0.42),  # B2 — coral
		Color(0.33, 0.83, 0.72),  # B3 — teal
		Color(0.96, 0.78, 0.33),  # B4 — amber
	],
}

# ── Active theme ───────────────────────────────────────────────────────────
# Change this constant to switch the entire game's colour scheme.
# Options: WARM_SAND | COOL_SLATE | DARK_CHARCOAL
const ACTIVE := WARM_SAND

# ── Layout constants ────────────────────────────────────────────────────────
const GAP_FRACTION    := 0.042   # gap between cells as a fraction of cell size
const CORNER_FRACTION := 0.08   # corner radius as a fraction of cell size
