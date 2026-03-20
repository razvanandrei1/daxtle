class_name Movement

# resolve() returns a Dictionary:
#   "movers"         : Array[Block]      — blocks that will move one step
#   "invalid"        : Array[Block]      — blocks stopped by a wall/hole (trigger shake)
#   "teleport_exits" : Dictionary        — Block → Vector2i exit cell for blocks that teleport
#
# Inter-block collisions cause the hit block to be pushed along in the mover's
# direction. Only walls/holes can stop movement.
# If a block steps onto a teleport portal cell it exits at the partner cell instead;
# if the exit is blocked the block cannot enter the portal.

static func resolve(
	candidates:   Array[Block],
	all_blocks:   Array[Block],
	board_set:    Dictionary,
	direction:    String,
	fixed_set:    Dictionary = {},
	teleport_map: Dictionary = {}
) -> Dictionary:

	var empty := {
		"movers":         [] as Array[Block],
		"invalid":        [] as Array[Block],
		"teleport_exits": {}
	}
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

	# --- Step 2: sort front-to-back, check walls/holes/teleports ---
	var sorted: Array[Block] = []
	sorted.assign(active)
	sorted.sort_custom(func(a: Block, b: Block) -> bool:
		return (a.grid_origin.x * dv.x + a.grid_origin.y * dv.y) > \
			   (b.grid_origin.x * dv.x + b.grid_origin.y * dv.y)
	)

	var blocked_cells:   Dictionary = {}
	var movers:          Array[Block] = []
	var invalid:         Array[Block] = []
	var teleport_exits:  Dictionary = {}

	for block in sorted:
		var new_origin := block.grid_origin + dv
		var can_move   := true
		var hits_wall  := false

		# Check entrance is a valid board cell
		for cell in block.data.cells(new_origin):
			if not board_set.has(cell):
				hits_wall = true
				can_move  = false
				break

		if can_move:
			if teleport_map.has(new_origin):
				# Entrance is a portal — try to exit at the partner cell
				var exit := teleport_map[new_origin] as Vector2i
				for cell in block.data.cells(exit):
					if not board_set.has(cell) or fixed_set.has(cell) or blocked_cells.has(cell):
						can_move = false
						break
				if can_move:
					teleport_exits[block] = exit
			else:
				# Normal move — check entrance for fixed/blocked obstructions
				for cell in block.data.cells(new_origin):
					if fixed_set.has(cell) or blocked_cells.has(cell):
						can_move = false
						break

		if can_move:
			movers.append(block)
		else:
			invalid.append(block)
			for cell in block.data.cells(block.grid_origin):
				blocked_cells[cell] = true

	return {"movers": movers, "invalid": invalid, "teleport_exits": teleport_exits}
