class_name Movement

# resolve() returns a Dictionary:
#   "movers"  : Array[Block] — blocks that will move one step
#   "invalid" : Array[Block] — blocks that hit a boundary or hole (trigger shake)
# Blocks silently stopped by another block appear in neither list.

static func resolve(
	candidates: Array[Block],
	all_blocks: Array[Block],
	board_set: Dictionary,
	direction: String
) -> Dictionary:

	var empty := {"movers": [] as Array[Block], "invalid": [] as Array[Block]}
	if candidates.is_empty():
		return empty

	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)  # "up"

	# Sort front-to-back so chain blocking propagates correctly
	var sorted: Array[Block] = []
	sorted.assign(candidates)
	sorted.sort_custom(func(a: Block, b: Block) -> bool:
		return (a.grid_origin.x * dv.x + a.grid_origin.y * dv.y) > \
			   (b.grid_origin.x * dv.x + b.grid_origin.y * dv.y)
	)

	# Seed blocked_cells with cells occupied by non-moving blocks
	var blocked_cells: Dictionary = {}
	for block in all_blocks:
		if not candidates.has(block):
			for cell in block.data.cells(block.grid_origin):
				blocked_cells[cell] = true

	var movers:  Array[Block] = []
	var invalid: Array[Block] = []

	for block in sorted:
		var new_origin: Vector2i = block.grid_origin + dv
		var new_cells := block.data.cells(new_origin)
		var hits_wall  := false
		var hits_block := false

		for cell in new_cells:
			if not board_set.has(cell):
				hits_wall = true
				break
			if blocked_cells.has(cell):
				hits_block = true
				break

		if not hits_wall and not hits_block:
			movers.append(block)
			for cell in new_cells:
				blocked_cells[cell] = true
		else:
			if hits_wall:
				invalid.append(block)
			# Whether wall or block, current cells become barriers for blocks behind
			for cell in block.data.cells(block.grid_origin):
				blocked_cells[cell] = true

	return {"movers": movers, "invalid": invalid}
