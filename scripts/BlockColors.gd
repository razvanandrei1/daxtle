class_name BlockColors

# Project-defined color palette — index 0 = B1, index 1 = B2, etc.
# Update here to retheme all levels at once without touching JSON.
const PALETTE: Array[Color] = [
	Color(0.25, 0.50, 0.85),  # B1 — blue
	Color(0.88, 0.38, 0.33),  # B2 — coral
	Color(0.22, 0.68, 0.62),  # B3 — teal
	Color(0.93, 0.63, 0.18),  # B4 — amber
	Color(0.58, 0.33, 0.78),  # B5 — purple
	Color(0.42, 0.68, 0.38),  # B6 — sage
	Color(0.83, 0.43, 0.63),  # B7 — rose
	Color(0.38, 0.53, 0.73),  # B8 — slate
]


# Returns the color for a block ID such as "B1", "B2", etc.
static func get_color(block_id: String) -> Color:
	var index := int(block_id.substr(1)) - 1
	if index < 0 or index >= PALETTE.size():
		push_warning("BlockColors: no color for '%s', using fallback" % block_id)
		return Color(0.65, 0.65, 0.65)
	return PALETTE[index]


# Returns a muted version of a block's color for use as a target zone tint
static func get_target_color(block_id: String) -> Color:
	var c := get_color(block_id)
	return Color(c.r, c.g, c.b, 0.35)
