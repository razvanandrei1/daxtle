class_name PuzzleSolver
## Checks if the current board state is still winnable via BFS.
## Only used for challenge mode — small boards make this fast.

const MAX_DEPTH := 20  # max moves to search before declaring unsolvable


## Returns true if the puzzle is solvable from the given block positions.
static func is_solvable(
	blocks: Array[Block],
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary
) -> bool:
	# Encode initial state
	var initial := _encode_state(blocks)

	# Quick check: already won?
	if _is_win(blocks):
		return true

	var visited := { initial: true }
	var queue: Array[Dictionary] = []
	queue.append({ "positions": _get_positions(blocks), "depth": 0 })

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var positions: Array = current["positions"]
		var depth: int = current["depth"]

		if depth >= MAX_DEPTH:
			continue

		for dir in ["left", "right", "up", "down"]:
			var new_positions := _simulate_move(positions, blocks, dir, board_set, fixed_set, teleport_map)
			if new_positions.is_empty():
				continue

			var state := _encode_positions(new_positions)
			if visited.has(state):
				continue
			visited[state] = true

			# Check win
			if _check_win_positions(new_positions, blocks):
				return true

			queue.append({ "positions": new_positions, "depth": depth + 1 })

	return false


static func _get_positions(blocks: Array[Block]) -> Array:
	var positions: Array = []
	for block in blocks:
		positions.append(block.grid_origin)
	return positions


static func _encode_state(blocks: Array[Block]) -> String:
	var parts: Array[String] = []
	for block in blocks:
		parts.append("%d,%d" % [block.grid_origin.x, block.grid_origin.y])
	return "|".join(parts)


static func _encode_positions(positions: Array) -> String:
	var parts: Array[String] = []
	for pos in positions:
		parts.append("%d,%d" % [pos.x, pos.y])
	return "|".join(parts)


static func _is_win(blocks: Array[Block]) -> bool:
	for block in blocks:
		if not block.data.target_origins.has(block.grid_origin):
			return false
	return true


static func _check_win_positions(positions: Array, blocks: Array[Block]) -> bool:
	for i in blocks.size():
		if not blocks[i].data.target_origins.has(positions[i]):
			return false
	return true


## Simulate a single swipe in a direction. Returns new positions array, or empty if nothing moves.
static func _simulate_move(
	positions: Array,
	blocks: Array[Block],
	direction: String,
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary
) -> Array:
	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i(1, 0)
		"left":  dv = Vector2i(-1, 0)
		"down":  dv = Vector2i(0, 1)
		"up":    dv = Vector2i(0, -1)

	# Build occupied set from current positions
	var occupied := {}
	for i in positions.size():
		occupied[positions[i]] = i

	# Find movers (blocks matching direction)
	var movers: Array[int] = []
	for i in blocks.size():
		if blocks[i].data.dir == direction:
			movers.append(i)

	if movers.is_empty():
		return []

	# Simple movement: each mover tries to move, pushing others
	var new_positions: Array = positions.duplicate()
	var any_moved := false

	# Sort movers so we process front-to-back
	movers.sort_custom(func(a: int, b: int) -> bool:
		var pa: Vector2i = new_positions[a]
		var pb: Vector2i = new_positions[b]
		return (pa.x * dv.x + pa.y * dv.y) > (pb.x * dv.x + pb.y * dv.y)
	)

	for mover_idx in movers:
		var result := _try_move_block(mover_idx, dv, new_positions, blocks, board_set, fixed_set, teleport_map, occupied)
		if result:
			any_moved = true
			# Rebuild occupied
			occupied.clear()
			for i in new_positions.size():
				occupied[new_positions[i]] = i

	if not any_moved:
		return []
	return new_positions


## Try to move a single block, handling pushes. Returns true if moved.
static func _try_move_block(
	idx: int,
	dv: Vector2i,
	positions: Array,
	blocks: Array[Block],
	board_set: Dictionary,
	fixed_set: Dictionary,
	teleport_map: Dictionary,
	occupied: Dictionary
) -> bool:
	var dest: Vector2i = positions[idx] + dv

	# Check board bounds
	if not board_set.has(dest):
		return false

	# Check fixed blocks
	if fixed_set.has(dest):
		return false

	# Check if another block is there
	if occupied.has(dest):
		var other_idx: int = occupied[dest]
		# Try to push
		if not _try_move_block(other_idx, dv, positions, blocks, board_set, fixed_set, teleport_map, occupied):
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
