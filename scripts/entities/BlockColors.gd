class_name BlockColors

# Colours come from the active theme — change GameTheme.ACTIVE to retheme.

# Returns the colour for a block ID such as "B1", "B2", etc.
static func get_color(block_id: String) -> Color:
	var palette: Array = GameTheme.ACTIVE["blocks"]
	var index := int(block_id.substr(1)) - 1
	if index < 0 or index >= palette.size():
		push_warning("BlockColors: no colour for '%s', using fallback" % block_id)
		return Color(0.65, 0.65, 0.65)
	return palette[index]


# Returns a muted version of a block's colour for use as a target zone tint.
static func get_target_color(block_id: String) -> Color:
	var c := get_color(block_id)
	return Color(c.r, c.g, c.b, 0.35)
