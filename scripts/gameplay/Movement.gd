class_name Movement

# resolve() returns a Dictionary:
#   "movers"  : Array[Block] — blocks that will move one step
#   "invalid" : Array[Block] — blocks stopped by a wall or hole (trigger shake)
#
# Inter-block collisions cause the hit block to be pushed along in the mover's
# direction. Only walls/holes can stop movement.

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
		_:       dv = Vector2i( 0, -1)

	# --- Step 1: expand active set via push propagation ---
	var active: Array[Block] = []
	active.assign(candidates)

	var frontier: Array[Block] = []
	frontier.assign(candidates)

	while not frontier.is_empty():
		var next_frontier: Array[Block] = []
		for mover in frontier:
			var new_cells := mover.data.cells(mover.grid_origin + dv)
			for other in all_blocks:
				if active.has(other):
					continue
				for cell in other.data.cells(other.grid_origin):
					if new_cells.has(cell):
						active.append(other)
						next_frontier.append(other)
						break
		frontier = next_frontier

	# --- Step 2: sort front-to-back, check walls/holes ---
	var sorted: Array[Block] = []
	sorted.assign(active)
	sorted.sort_custom(func(a: Block, b: Block) -> bool:
		return (a.grid_origin.x * dv.x + a.grid_origin.y * dv.y) > \
			   (b.grid_origin.x * dv.x + b.grid_origin.y * dv.y)
	)

	var blocked_cells: Dictionary = {}
	var movers:  Array[Block] = []
	var invalid: Array[Block] = []

	for block in sorted:
		var new_origin: Vector2i = block.grid_origin + dv
		var new_cells  := block.data.cells(new_origin)
		var can_move   := true
		var hits_wall  := false

		for cell in new_cells:
			if not board_set.has(cell):
				hits_wall = true
				can_move  = false
				break
			if blocked_cells.has(cell):
				can_move = false
				break

		if can_move:
			movers.append(block)
		else:
			invalid.append(block)  # shake any stopped active block (wall hit or chain stop)
			for cell in block.data.cells(block.grid_origin):
				blocked_cells[cell] = true

	return {"movers": movers, "invalid": invalid}
