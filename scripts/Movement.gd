class_name Movement

# Returns the subset of `candidates` that are allowed to move one step.
# Candidates are blocks whose dir matches the current swipe direction.
#
# T24 adds inter-block blocking.
# T25/T26 add boundary and missing-square checks.
static func resolve(
	candidates: Array[Block],
	all_blocks: Array[Block],
	board_set: Dictionary,
	direction: String
) -> Array[Block]:

	if candidates.is_empty():
		return []

	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)  # "up"

	# Sort candidates front-to-back so chain blocking propagates correctly (T24)
	var sorted: Array[Block] = []
	sorted.assign(candidates)
	sorted.sort_custom(func(a: Block, b: Block) -> bool:
		return (a.grid_origin.x * dv.x + a.grid_origin.y * dv.y) > \
			   (b.grid_origin.x * dv.x + b.grid_origin.y * dv.y)
	)

	# Cells that are off-limits: occupied by non-moving blocks + blocked movers
	var blocked_cells: Dictionary = {}
	for block in all_blocks:
		if not candidates.has(block):
			for cell in block.data.cells(block.grid_origin):
				blocked_cells[cell] = true

	var result: Array[Block] = []

	for block in sorted:
		var new_origin := block.grid_origin + dv
		var new_cells  := block.data.cells(new_origin)
		var allowed    := true

		for cell in new_cells:
			# T25/T26 — boundary and missing-square check
			if not board_set.has(cell):
				allowed = false
				break
			# T24 — blocked by a stopped block (non-moving or a mover that can't move)
			if blocked_cells.has(cell):
				allowed = false
				break

		if allowed:
			result.append(block)
			# Reserve new cells so blocks behind this one respect it (T24 chain)
			for cell in new_cells:
				blocked_cells[cell] = true
		else:
			# Block stays put — add its current cells so blocks behind it stop too
			for cell in block.data.cells(block.grid_origin):
				blocked_cells[cell] = true

	return result
