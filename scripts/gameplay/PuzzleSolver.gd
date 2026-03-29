class_name PuzzleSolver
## Checks if the current board state is still winnable via BFS.
## Supports destroy blocks (D): when a B block lands on a D cell, both are removed.

const MAX_DEPTH := 20  # max moves to search before declaring unsolvable


## Returns the solution as an Array[String] of swipe directions, or empty if unsolvable.
static func solve(
	blocks: Array[Block],
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary,
	destroy_set: Dictionary = {}
) -> Array[String]:
	var initial_positions := _get_positions(blocks)
	var initial_alive: Array[bool] = []
	initial_alive.resize(blocks.size())
	initial_alive.fill(true)
	var initial_destroy := destroy_set.duplicate()

	if _check_win(initial_positions, initial_alive, blocks):
		return []

	var initial_state := _encode(initial_positions, initial_alive, initial_destroy)
	# came_from maps state -> { "parent": parent_state, "dir": direction }
	var came_from := { initial_state: null }
	var queue: Array[Dictionary] = []
	queue.append({
		"positions": initial_positions,
		"alive": initial_alive,
		"destroy": initial_destroy,
		"depth": 0,
		"state": initial_state,
	})

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var positions: Array = current["positions"]
		var alive: Array[bool] = current["alive"]
		var destroy: Dictionary = current["destroy"]
		var depth: int = current["depth"]
		var current_state: String = current["state"]

		if depth >= MAX_DEPTH:
			continue

		for dir in ["left", "right", "up", "down"]:
			var result := _simulate_move(positions, alive, blocks, dir, board_set, fixed_set, teleport_map, destroy)
			if result.is_empty():
				continue

			var new_positions: Array = result["positions"]
			var new_alive: Array[bool] = result["alive"]
			var new_destroy: Dictionary = result["destroy"]

			var state := _encode(new_positions, new_alive, new_destroy)
			if came_from.has(state):
				continue
			came_from[state] = { "parent": current_state, "dir": dir }

			if _check_win(new_positions, new_alive, blocks):
				# Backtrack to build solution path
				var path: Array[String] = []
				var s := state
				while came_from[s] != null:
					path.push_front(came_from[s]["dir"])
					s = came_from[s]["parent"]
				return path

			queue.append({
				"positions": new_positions,
				"alive": new_alive,
				"destroy": new_destroy,
				"depth": depth + 1,
				"state": state,
			})

	return []


## Returns true if the puzzle is solvable from the given block positions.
static func is_solvable(
	blocks: Array[Block],
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary,
	destroy_set: Dictionary = {}
) -> bool:
	var initial_positions := _get_positions(blocks)
	var initial_alive: Array[bool] = []
	initial_alive.resize(blocks.size())
	initial_alive.fill(true)
	var initial_destroy := destroy_set.duplicate()

	# Quick check: already won?
	if _check_win(initial_positions, initial_alive, blocks):
		return true

	var initial_state := _encode(initial_positions, initial_alive, initial_destroy)
	var visited := { initial_state: true }
	var queue: Array[Dictionary] = []
	queue.append({
		"positions": initial_positions,
		"alive": initial_alive,
		"destroy": initial_destroy,
		"depth": 0,
	})

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var positions: Array = current["positions"]
		var alive: Array[bool] = current["alive"]
		var destroy: Dictionary = current["destroy"]
		var depth: int = current["depth"]

		if depth >= MAX_DEPTH:
			continue

		for dir in ["left", "right", "up", "down"]:
			var result := _simulate_move(positions, alive, blocks, dir, board_set, fixed_set, teleport_map, destroy)
			if result.is_empty():
				continue

			var new_positions: Array = result["positions"]
			var new_alive: Array[bool] = result["alive"]
			var new_destroy: Dictionary = result["destroy"]

			var state := _encode(new_positions, new_alive, new_destroy)
			if visited.has(state):
				continue
			visited[state] = true

			if _check_win(new_positions, new_alive, blocks):
				return true

			queue.append({
				"positions": new_positions,
				"alive": new_alive,
				"destroy": new_destroy,
				"depth": depth + 1,
			})

	return false


static func _get_positions(blocks: Array[Block]) -> Array:
	var positions: Array = []
	for block in blocks:
		positions.append(block.grid_origin)
	return positions


static func _encode(positions: Array, alive: Array[bool], destroy: Dictionary) -> String:
	var parts: Array[String] = []
	for i in positions.size():
		if alive[i]:
			parts.append("%d,%d" % [positions[i].x, positions[i].y])
		else:
			parts.append("X")
	# Include remaining D cells in state
	var d_cells: Array = destroy.keys()
	d_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	for cell in d_cells:
		parts.append("D%d,%d" % [cell.x, cell.y])
	return "|".join(parts)


static func _check_win(positions: Array, alive: Array[bool], blocks: Array[Block]) -> bool:
	for i in blocks.size():
		if not alive[i]:
			continue
		if not blocks[i].data.target_origins.has(positions[i]):
			return false
	return true


## Simulate a single swipe. Returns a Dictionary with "positions", "alive", "destroy"
## or an empty Dictionary if nothing moves.
static func _simulate_move(
	positions: Array,
	alive: Array[bool],
	blocks: Array[Block],
	direction: String,
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary,
	destroy: Dictionary,
) -> Dictionary:
	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i(1, 0)
		"left":  dv = Vector2i(-1, 0)
		"down":  dv = Vector2i(0, 1)
		"up":    dv = Vector2i(0, -1)

	# Build occupied set from alive blocks
	var occupied := {}
	for i in positions.size():
		if alive[i]:
			occupied[positions[i]] = i

	# Find movers (alive blocks matching direction)
	var movers: Array[int] = []
	for i in blocks.size():
		if alive[i] and blocks[i].data.dir == direction:
			movers.append(i)

	if movers.is_empty():
		return {}

	var new_positions: Array = positions.duplicate()
	var any_moved := false

	# Sort movers front-to-back
	movers.sort_custom(func(a: int, b: int) -> bool:
		var pa: Vector2i = new_positions[a]
		var pb: Vector2i = new_positions[b]
		return (pa.x * dv.x + pa.y * dv.y) > (pb.x * dv.x + pb.y * dv.y)
	)

	for mover_idx in movers:
		var result := _try_move_block(mover_idx, dv, new_positions, alive, blocks, board_set, fixed_set, teleport_map, occupied)
		if result:
			any_moved = true
			occupied.clear()
			for i in new_positions.size():
				if alive[i]:
					occupied[new_positions[i]] = i

	if not any_moved:
		return {}

	# Handle destroy collisions
	var new_alive: Array[bool] = []
	new_alive.assign(alive)
	var new_destroy := destroy.duplicate()
	for i in new_positions.size():
		if new_alive[i] and new_destroy.has(new_positions[i]):
			new_alive[i] = false
			new_destroy.erase(new_positions[i])

	return { "positions": new_positions, "alive": new_alive, "destroy": new_destroy }


## Try to move a single block, handling pushes. Returns true if moved.
static func _try_move_block(
	idx: int,
	dv: Vector2i,
	positions: Array,
	alive: Array[bool],
	blocks: Array[Block],
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary,
	occupied: Dictionary
) -> bool:
	if not alive[idx]:
		return false

	var dest: Vector2i = positions[idx] + dv

	if not board_set.has(dest):
		return false

	if fixed_set.has(dest):
		return false

	if occupied.has(dest):
		var other_idx: int = occupied[dest]
		if not _try_move_block(other_idx, dv, positions, alive, blocks, board_set, fixed_set, teleport_map, occupied):
			return false

	# Handle teleport
	if teleport_map.has(dest):
		var exit_cell: Vector2i = teleport_map[dest]
		var cont_cell: Vector2i = exit_cell + dv
		if board_set.has(cont_cell) and not fixed_set.has(cont_cell) and not occupied.has(cont_cell):
			positions[idx] = cont_cell
		else:
			positions[idx] = exit_cell
	else:
		positions[idx] = dest
	return true
