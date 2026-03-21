# =============================================================================
# Movement.gd — Pure movement resolution logic (no visuals)
# =============================================================================
# Given a swipe direction, determines which blocks move, which are blocked,
# and which teleport. Handles push chains (block A pushes block B),
# push chains through portals, and post-teleport continuation steps.
# =============================================================================
class_name Movement

# resolve() returns a Dictionary:
#   "movers"           : Array[Block]      — blocks that will move one step
#   "invalid"          : Array[Block]      — blocks stopped by a wall/hole (trigger shake)
#   "teleport_exits"   : Dictionary        — Block → Vector2i final cell for blocks that teleport
#   "teleport_entries" : Dictionary        — Block → Vector2i portal entrance cell
#
# Inter-block collisions cause the hit block to be pushed along in the mover's
# direction. Only walls/holes can stop movement.
#
# T72 — Continuation: a block that teleports slides one extra step after the exit
#        if that step is clear (not a wall, fixed block, stopped block, or another portal).
#
# T74 — Push-chain through portals: if an active block's next cell is a portal entrance,
#        any block sitting at the exit cell is added to the active (push) set.

static func resolve(
	candidates:   Array[Block],
	all_blocks:   Array[Block],
	board_set:    Dictionary,
	direction:    String,
	fixed_set:    Dictionary = {},
	teleport_map: Dictionary = {}
) -> Dictionary:

	var empty := {
		"movers":           [] as Array[Block],
		"invalid":          [] as Array[Block],
		"teleport_exits":   {},
		"teleport_entries": {},
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

	# --- Step 1b (T74): push-chain through portal exits ---
	# If an active block's next step lands on a portal entrance, any block
	# sitting at the corresponding exit cell joins the active set.
	if not teleport_map.is_empty():
		var portal_frontier: Array[Block] = []
		for mover in active:
			var entry := mover.grid_origin + dv
			if not teleport_map.has(entry):
				continue
			var exit := teleport_map[entry] as Vector2i
			for other in all_blocks:
				if active.has(other):
					continue
				for cell in other.data.cells(other.grid_origin):
					if cell == exit:
						active.append(other)
						portal_frontier.append(other)
						break
		# Continue normal push propagation from newly added portal-exit blocks
		frontier.assign(portal_frontier)
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

	# Cells occupied by non-active blocks (they will not move)
	var stationary_cells: Dictionary = {}
	for block in all_blocks:
		if not active.has(block):
			for cell in block.data.cells(block.grid_origin):
				stationary_cells[cell] = true

	var blocked_cells:    Dictionary = {}
	var movers:           Array[Block] = []
	var invalid:          Array[Block] = []
	var teleport_exits:   Dictionary = {}
	var teleport_entries: Dictionary = {}

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
					teleport_entries[block] = new_origin
					teleport_exits[block]   = exit

					# T72 — Continuation: try one extra step past the exit
					var cont := exit + dv
					var cont_ok := board_set.has(cont) \
						and not fixed_set.has(cont) \
						and not blocked_cells.has(cont) \
						and not stationary_cells.has(cont) \
						and not teleport_map.has(cont)
					# Also ensure cont isn't occupied by a block in the sorted set
					# that hasn't been processed yet (it may be a future mover or invalid)
					if cont_ok:
						for other in sorted:
							if other == block:
								continue
							if not movers.has(other) and not invalid.has(other):
								for cell in other.data.cells(other.grid_origin):
									if cell == cont:
										cont_ok = false
										break
							if not cont_ok:
								break
					if cont_ok:
						teleport_exits[block] = cont
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

	return {
		"movers":           movers,
		"invalid":          invalid,
		"teleport_exits":   teleport_exits,
		"teleport_entries": teleport_entries,
	}
