extends Node2D

const BoardScene      := preload("res://scenes/Board.tscn")
const BlockScene      := preload("res://scenes/Block.tscn")
const FixedBlockScene := preload("res://scenes/FixedBlock.tscn")
const MOVE_DURATION := 0.13 # seconds per slide animation

const WIN_BRIGHT := Color(1.5, 1.5, 1.5, 1.0)  # brightened modulate for glow pulse
const WIN_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const WIN_FADE   := Color(1.0, 1.0, 1.0, 0.0)

signal level_loaded(n: int)

var current_level: int = 20
var value_a: float = 0.0

var _board: Board
var _blocks: Array[Block] = []
var _fixed_blocks: Array[FixedBlock] = []
var _board_set: Dictionary = {}   # Vector2i -> true, for fast cell lookup
var _fixed_set: Dictionary = {}   # Vector2i -> true, C block occupied cells
var _swipe_detector: SwipeDetector
var _intro_tweens: Array[Tween] = []


func _ready() -> void:
	_swipe_detector = $SwipeDetector
	_swipe_detector.swiped.connect(_on_swipe)


func load_level(n: int) -> void:
	_load_level(n)


func _on_swipe(direction: String) -> void:
	var candidates: Array[Block] = []
	for block in _blocks:
		if block.data.dir == direction:
			candidates.append(block)

	if candidates.is_empty():
		return

	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)

	var result   := Movement.resolve(candidates, _blocks, _board_set, direction, _fixed_set)
	var movers:  Array[Block] = result["movers"]
	var invalid: Array[Block] = result["invalid"]

	if movers.is_empty() and invalid.is_empty():
		return

	_swipe_detector.enabled = false

	if not movers.is_empty():
		var tween := create_tween().set_parallel(true)
		for block in movers:
			block.grid_origin += dv  # always swipe direction, even for pushed blocks
			var target_pos := _board.grid_to_local(block.grid_origin)
			tween.tween_property(block, "position", target_pos, MOVE_DURATION) \
				.set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_OUT)
		tween.finished.connect(func() -> void:
			if _check_win():
				_on_win()
			elif _is_dead_state():
				_on_dead_state()
			else:
				_swipe_detector.enabled = true
		)

	if not invalid.is_empty():
		_shake_blocks(invalid, direction, movers.is_empty())


func _shake_blocks(blocks: Array[Block], direction: String, re_enable_after: bool) -> void:
	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)

	var nudge    := Vector2(dv) * value_a * 0.18
	var duration := MOVE_DURATION

	var tween := create_tween().set_parallel(true)
	for block in blocks:
		var origin_pos := block.position
		# Nudge toward the wall …
		tween.tween_property(block, "position", origin_pos + nudge, duration * 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# … then spring back
		tween.tween_property(block, "position", origin_pos, duration * 0.85) \
			.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT) \
			.set_delay(duration * 0.45)

	tween.finished.connect(func() -> void:
		if re_enable_after:
			_swipe_detector.enabled = true
	)


func _check_win() -> bool:
	for block in _blocks:
		if block.grid_origin != block.data.target_origin:
			return false
	return true


func _on_win() -> void:
	_swipe_detector.enabled = false

	var tween := create_tween().set_parallel(true)

	for block in _blocks:
		# Pulse 1
		tween.tween_property(block, "modulate", WIN_BRIGHT, 0.14) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(block, "modulate", WIN_NORMAL, 0.14) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.14)
		# Pulse 2
		tween.tween_property(block, "modulate", WIN_BRIGHT, 0.14) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.28)
		tween.tween_property(block, "modulate", WIN_NORMAL, 0.14) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.42)
		# Fade out
		tween.tween_property(block, "modulate", WIN_FADE, 0.35) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(0.56)

	# Board fades out shortly after blocks begin fading
	tween.tween_property(_board, "modulate", WIN_FADE, 0.40) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(0.70)

	tween.finished.connect(func() -> void:
		_load_level(clamp(current_level + 1, 1, LevelLoader.count_levels()))
	)


# --- Dead-state detection (BFS over reachable states) ---

const _BFS_STATE_LIMIT := 8000  # safety cap; keeps detection fast on small levels

func _is_dead_state() -> bool:
	var initial := _encode_state()
	var targets := _encode_targets()

	if initial == targets:
		return false  # already won, not dead

	var visited := {_state_key(initial): true}
	var queue   := [initial]

	while not queue.is_empty():
		var state: Array = queue.pop_front()

		for dir in ["left", "right", "up", "down"]:
			var next := _bfs_sim_move(state, dir)

			if next == targets:
				return false  # winning state reachable

			var key := _state_key(next)
			if not visited.has(key):
				if visited.size() >= _BFS_STATE_LIMIT:
					return false  # hit limit — assume not stuck (safe default)
				visited[key] = true
				queue.append(next)

	return true  # exhausted all reachable states, no win found


func _on_dead_state() -> void:
	_swipe_detector.enabled = false

	var origin := _board.position
	var s      := value_a * 0.06  # shake amplitude

	# Gentle oscillation with easing — blocks are children of board so they shake too
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_board, "position", origin + Vector2( s,       0), 0.08)
	tween.tween_property(_board, "position", origin + Vector2(-s,       0), 0.09)
	tween.tween_property(_board, "position", origin + Vector2( s * 0.5, 0), 0.08)
	tween.tween_property(_board, "position", origin + Vector2(-s * 0.5, 0), 0.08)
	tween.tween_property(_board, "position", origin,                        0.09)

	tween.finished.connect(func() -> void:
		await get_tree().create_timer(0.25).timeout
		_reset_blocks()
	)


func _reset_blocks() -> void:
	var slide := create_tween().set_parallel(true)
	for block in _blocks:
		block.grid_origin = block.data.origin
		var target_pos := _board.grid_to_local(block.grid_origin)
		slide.tween_property(block, "position", target_pos, MOVE_DURATION * 2.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slide.finished.connect(func() -> void:
		_swipe_detector.enabled = true
	)


# Simulate one swipe on an abstract state (Array of Vector2i origins, one per block).
# Mirrors the push mechanic in Movement.resolve() without touching Block nodes.
func _bfs_sim_move(origins: Array, direction: String) -> Array:
	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)

	# Candidates: blocks whose dir matches
	var active: Array[int] = []
	for i in _blocks.size():
		if _blocks[i].data.dir == direction:
			active.append(i)

	if active.is_empty():
		return origins

	# Push propagation
	var frontier: Array[int] = active.duplicate()
	while not frontier.is_empty():
		var next_frontier: Array[int] = []
		for ai in frontier:
			var new_cells := _blocks[ai].data.cells(origins[ai] + dv)
			for bi in _blocks.size():
				if active.has(bi):
					continue
				for cell in _blocks[bi].data.cells(origins[bi]):
					if new_cells.has(cell):
						active.append(bi)
						next_frontier.append(bi)
						break
		frontier = next_frontier

	# Sort front-to-back
	active.sort_custom(func(a: int, b: int) -> bool:
		return (origins[a].x * dv.x + origins[a].y * dv.y) > \
			   (origins[b].x * dv.x + origins[b].y * dv.y)
	)

	# Wall check — build new origins
	var new_origins: Array = origins.duplicate()
	var blocked_cells: Dictionary = {}

	for ai in active:
		var new_origin: Vector2i = origins[ai] + dv
		var new_cells  := _blocks[ai].data.cells(new_origin)
		var can_move   := true

		for cell in new_cells:
			if not _board_set.has(cell) or _fixed_set.has(cell) or blocked_cells.has(cell):
				can_move = false
				break

		if can_move:
			new_origins[ai] = new_origin
		else:
			for cell in _blocks[ai].data.cells(origins[ai]):
				blocked_cells[cell] = true

	return new_origins


func _encode_state() -> Array:
	var s: Array = []
	for block in _blocks:
		s.append(block.grid_origin)
	return s


func _encode_targets() -> Array:
	var t: Array = []
	for block in _blocks:
		t.append(block.data.target_origin)
	return t


func _state_key(origins: Array) -> String:
	var parts: Array[String] = []
	for o: Vector2i in origins:
		parts.append("%d,%d" % [o.x, o.y])
	return "|".join(parts)


func go_next_level() -> void:
	_load_level(clamp(current_level + 1, 1, LevelLoader.count_levels()))


func go_prev_level() -> void:
	_load_level(clamp(current_level - 1, 1, LevelLoader.count_levels()))


func _load_level(level_number: int) -> void:
	for tw in _intro_tweens:
		if tw:
			tw.kill()
	_intro_tweens.clear()

	if _board:
		_board.queue_free()
	_blocks.clear()
	_fixed_blocks.clear()
	_board_set.clear()
	_fixed_set.clear()

	var level_data := LevelLoader.load_level(level_number)
	if level_data.is_empty():
		push_error("Game: failed to load level %d" % level_number)
		return

	current_level = level_number

	# Board
	var squares := LevelLoader.get_board_squares(level_data)
	_board = BoardScene.instantiate() as Board
	add_child(_board)
	value_a = _board.setup(squares)

	for sq in squares:
		_board_set[sq] = true

	# Fixed blocks (C) — instantiated before B blocks so they render beneath them
	var fixed_data := LevelLoader.get_fixed_blocks(level_data)
	for fd in fixed_data:
		var fb := FixedBlockScene.instantiate() as FixedBlock
		_board.add_child(fb)
		fb.setup(fd, value_a, _board)
		_fixed_blocks.append(fb)
		for cell in fd.cells():
			_fixed_set[cell] = true

	# Blocks — added as children of the board so they share its coordinate space
	var blocks_data := LevelLoader.get_blocks(level_data)
	_board.set_targets(blocks_data)
	for block_data in blocks_data:
		var block := BlockScene.instantiate() as Block
		_board.add_child(block)
		block.setup(block_data, value_a, _board)
		_blocks.append(block)

	level_loaded.emit(current_level)
	_play_intro_animation()


# --- Level intro animation ---
# Sequence: board fades in → blocks slide in from above (staggered) → arrows fade in.
# Re-enables input when complete.

const _INTRO_CHAIN_DELAY   := 0.10   # delay before chain starts
const _INTRO_CHAIN_TOTAL   := 0.72   # total chain spread duration (stagger span), constant regardless of square count
const _INTRO_CHAIN_SCALE   := 0.66   # scale-up duration per square
const _INTRO_STAGGER       := 0.09   # delay between successive blocks
const _INTRO_SLIDE_DUR     := 0.36   # each block's slide duration
const _INTRO_ARROW_DUR     := 0.10   # arrow fade-in duration after block lands
const _INTRO_HOLD          := 0.20   # pause after last arrow before input opens

func _play_intro_animation() -> void:
	_swipe_detector.enabled = false

	# Chain scale across board squares — diagonal wave top-left → bottom-right
	var sorted_squares := _board.board_squares.duplicate()
	sorted_squares.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x + a.y) < (b.x + b.y)
	)
	var n := sorted_squares.size()
	var stagger := _INTRO_CHAIN_TOTAL / maxi(n - 1, 1)
	for i in n:
		var sq: Vector2i = sorted_squares[i]
		_board.set_cell_scale(sq, 0.0)
		var delay := _INTRO_CHAIN_DELAY + i * stagger
		var t     := create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: _board.set_cell_scale(sq, v),
			0.0, 1.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Fixed blocks (C) scale in during the same wave, timed by their diagonal position
	for fb in _fixed_blocks:
		fb.block_scale = 0.0
		var fb_diag := fb.data.origin.x + fb.data.origin.y
		for sq in fb.data.squares:
			var cell := fb.data.origin + sq
			fb_diag = mini(fb_diag, cell.x + cell.y)
		var wave_index := 0
		for j in sorted_squares.size():
			if (sorted_squares[j].x + sorted_squares[j].y) <= fb_diag:
				wave_index = j
		var delay := _INTRO_CHAIN_DELAY + wave_index * stagger
		var captured_fb := fb
		var t := create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: captured_fb.block_scale = v,
			0.0, 1.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Blocks scale up immediately after the chain finishes (no gap)
	var chain_end := _INTRO_CHAIN_DELAY + _INTRO_CHAIN_TOTAL + _INTRO_CHAIN_SCALE

	for i in _blocks.size():
		var block := _blocks[i]
		block.block_scale = 0.0
		block.arrow_alpha = 0.0

		var delay := chain_end + i * _INTRO_STAGGER
		var t     := create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: block.block_scale = v,
			0.0, 1.0, _INTRO_SLIDE_DUR) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_method(func(v: float) -> void: block.arrow_alpha = v,
			0.0, 1.0, _INTRO_ARROW_DUR) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Enable input once all animations have finished
	var total := chain_end \
		+ maxi(_blocks.size() - 1, 0) * _INTRO_STAGGER \
		+ _INTRO_SLIDE_DUR + _INTRO_ARROW_DUR + _INTRO_HOLD

	get_tree().create_timer(total).timeout.connect(func() -> void:
		_swipe_detector.enabled = true
	)
