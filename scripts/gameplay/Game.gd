extends Node2D

const BoardScene      := preload("res://scenes/entities/Board.tscn")
const BlockScene      := preload("res://scenes/entities/Block.tscn")
const FixedBlockScene := preload("res://scenes/entities/FixedBlock.tscn")
const TeleportScene   := preload("res://scenes/entities/Teleport.tscn")
const MOVE_DURATION := 0.13 # seconds per slide animation

const WIN_BRIGHT := Color(1.5, 1.5, 1.5, 1.0)  # brightened modulate for glow pulse
const WIN_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const WIN_FADE   := Color(1.0, 1.0, 1.0, 0.0)

signal level_loaded(n: int)
signal first_move
signal message_changed(text: String, board_bottom: float)
signal intro_finished
signal dismiss_message
var _has_message: bool = false

var current_level: int = 20
var _moved: bool = false
var _active: bool = false  # false while stopped or transitioning out
var value_a: float = 0.0

var _board: Board
var _blocks: Array[Block] = []
var _fixed_blocks: Array[FixedBlock] = []
var _board_set:    Dictionary = {}   # Vector2i -> true, for fast cell lookup
var _fixed_set:    Dictionary = {}   # Vector2i -> true, C block occupied cells
var _teleport_map: Dictionary = {}   # Vector2i -> Vector2i, portal entrance -> exit
var _teleports:    Array[Teleport] = []
var _swipe_detector: SwipeDetector
var _intro_tweens: Array[Tween] = []


func _ready() -> void:
	_swipe_detector = $SwipeDetector
	_swipe_detector.swiped.connect(_on_swipe)


func load_level(n: int) -> void:
	_load_level(n)


func stop() -> void:
	_active = false
	_swipe_detector.enabled = false
	for tw in _intro_tweens:
		if tw:
			tw.kill()
	_intro_tweens.clear()


func _on_swipe(direction: String) -> void:
	if not _active:
		return
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

	var result            := Movement.resolve(candidates, _blocks, _board_set, direction, _fixed_set, _teleport_map)
	var movers:            Array[Block] = result["movers"]
	var invalid:           Array[Block] = result["invalid"]
	var teleport_exits:    Dictionary   = result["teleport_exits"]
	var teleport_entries:  Dictionary   = result["teleport_entries"]

	if movers.is_empty() and invalid.is_empty():
		return

	if not _moved:
		_moved = true
		first_move.emit()

	_swipe_detector.enabled = false

	if not movers.is_empty():
		# Separate normal movers from teleporters so they can use different animations
		var par := create_tween().set_parallel(true)
		var has_teleport := false
		var max_tp_dur   := 0.0

		for block in movers:
			if teleport_exits.has(block):
				has_teleport = true

				var entry:     Vector2i = teleport_entries[block]
				var exit_cell: Vector2i = _teleport_map[entry]
				var entry_pos := _board.grid_to_local(entry)
				var exit_pos  := _board.grid_to_local(exit_cell)

				block.grid_origin = teleport_exits[block]
				var final_pos := _board.grid_to_local(block.grid_origin)
				var has_cont  := (final_pos != exit_pos)

				_pulse_portal_pair(entry, exit_cell)

				# Sequential per-block tween: slide → shrink → jump → pop → slide
				const SHRINK := 0.07
				const POP    := 0.10
				var tp := create_tween()
				tp.tween_property(block, "position", entry_pos, MOVE_DURATION) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tp.tween_property(block, "scale", Vector2.ZERO, SHRINK) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tp.tween_callback(func(): block.position = exit_pos)
				tp.tween_property(block, "scale", Vector2.ONE, POP) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if has_cont:
					tp.tween_property(block, "position", final_pos, MOVE_DURATION) \
						.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

				max_tp_dur = maxf(max_tp_dur,
					MOVE_DURATION + SHRINK + POP + (MOVE_DURATION if has_cont else 0.0))
			else:
				block.grid_origin += dv
				var target_pos := _board.grid_to_local(block.grid_origin)
				par.tween_property(block, "position", target_pos, MOVE_DURATION) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		var on_done := func() -> void:
			if _check_win():
				_on_win()
			elif _is_stuck():
				_on_stuck()
			else:
				_swipe_detector.enabled = true

		if has_teleport:
			var total_dur := maxf(max_tp_dur, MOVE_DURATION)
			get_tree().create_timer(total_dur).timeout.connect(on_done)
		else:
			par.finished.connect(on_done)

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


# Returns true if no block can move in any direction from the current state.
func _is_stuck() -> bool:
	for dir in ["left", "right", "up", "down"]:
		var candidates: Array[Block] = []
		for block in _blocks:
			if block.data.dir == dir:
				candidates.append(block)
		if candidates.is_empty():
			continue
		var result := Movement.resolve(candidates, _blocks, _board_set, dir, _fixed_set, _teleport_map)
		if not (result["movers"] as Array[Block]).is_empty():
			return false
	return true


func _on_stuck() -> void:
	_swipe_detector.enabled = false

	var origin := _board.position
	var s      := value_a * 0.06

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_board, "position", origin + Vector2( s,       0), 0.08)
	tween.tween_property(_board, "position", origin + Vector2(-s,       0), 0.09)
	tween.tween_property(_board, "position", origin + Vector2( s * 0.5, 0), 0.08)
	tween.tween_property(_board, "position", origin + Vector2(-s * 0.5, 0), 0.08)
	tween.tween_property(_board, "position", origin,                        0.09)

	tween.finished.connect(func() -> void:
		await get_tree().create_timer(0.25).timeout
		if _active:
			reset_level()
	)


func _on_win() -> void:
	_swipe_detector.enabled = false

	if _has_message:
		dismiss_message.emit()
		await get_tree().create_timer(0.40).timeout
		if not _active:
			return

	# --- Phase 1: 2 flashes on B blocks ---
	var flash := create_tween().set_parallel(true)
	for block in _blocks:
		flash.tween_property(block, "modulate", WIN_FADE, 0.10).set_delay(0.08)
		flash.tween_property(block, "modulate", WIN_NORMAL, 0.10).set_delay(0.18)
		flash.tween_property(block, "modulate", WIN_FADE, 0.10).set_delay(0.34)
		flash.tween_property(block, "modulate", WIN_NORMAL, 0.10).set_delay(0.44)

	flash.finished.connect(func() -> void:
		_play_exit_chain()
	)


func _play_exit_chain() -> void:
	# Reverse chain: bottom-right → top-left
	var sorted_squares := _board.board_squares.duplicate()
	sorted_squares.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x + a.y) > (b.x + b.y)
	)
	var n       := sorted_squares.size()
	var stagger := _INTRO_CHAIN_TOTAL / maxi(n - 1, 1)

	# Board squares scale down in reverse wave
	for i in n:
		var sq: Vector2i = sorted_squares[i]
		var delay := i * stagger
		var t := create_tween()
		t.tween_method(func(v: float) -> void: _board.set_cell_scale(sq, v),
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# B blocks scale down during the same wave, timed by their cell diagonal
	for block in _blocks:
		var diag := block.grid_origin.x + block.grid_origin.y
		var wave_index := 0
		for j in n:
			if (sorted_squares[j].x + sorted_squares[j].y) >= diag:
				wave_index = j
		var delay := wave_index * stagger
		var captured := block
		var t := create_tween()
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# Fixed blocks scale down in the same wave
	for fb in _fixed_blocks:
		var fb_diag := fb.data.origin.x + fb.data.origin.y
		for sq in fb.data.squares:
			var cell := fb.data.origin + sq
			fb_diag = maxi(fb_diag, cell.x + cell.y)
		var wave_index := 0
		for j in n:
			if (sorted_squares[j].x + sorted_squares[j].y) >= fb_diag:
				wave_index = j
		var delay := wave_index * stagger
		var captured := fb
		var t := create_tween()
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# Teleport portals scale down in the same wave
	for tp in _teleports:
		var diag := tp.portal_cell.x + tp.portal_cell.y
		var wave_index := 0
		for j in n:
			if (sorted_squares[j].x + sorted_squares[j].y) >= diag:
				wave_index = j
		var delay := wave_index * stagger
		var captured := tp
		var t := create_tween()
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	var total := _INTRO_CHAIN_TOTAL + _INTRO_CHAIN_SCALE + 0.15
	get_tree().create_timer(total).timeout.connect(func() -> void:
		if _active:
			_load_level(clamp(current_level + 1, 1, LevelLoader.count_levels()))
	)


func reset_level() -> void:
	_swipe_detector.enabled = false
	_moved = false
	level_loaded.emit(current_level)  # triggers UI to hide reset icon via set_level
	var slide := create_tween().set_parallel(true)
	for block in _blocks:
		block.grid_origin = block.data.origin
		var target_pos := _board.grid_to_local(block.grid_origin)
		slide.tween_property(block, "position", target_pos, MOVE_DURATION * 2.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slide.finished.connect(func() -> void:
		_swipe_detector.enabled = true
	)


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
	_teleports.clear()
	_board_set.clear()
	_fixed_set.clear()
	_teleport_map.clear()

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

	# Teleport portals (T) — added before blocks so they render beneath them
	var teleport_data := LevelLoader.get_teleports(level_data)
	for i in teleport_data.size():
		var td: TeleportData = teleport_data[i]
		var pair_col := GameTheme.get_teleport_color(i)
		_teleport_map[td.portal_a] = td.portal_b
		if not td.one_way:
			_teleport_map[td.portal_b] = td.portal_a
		for cell in [td.portal_a, td.portal_b]:
			var tp := TeleportScene.instantiate() as Teleport
			_board.add_child(tp)
			tp.setup(cell, value_a, _board, pair_col)
			_teleports.append(tp)

	# Blocks — added as children of the board so they share its coordinate space
	var blocks_data := LevelLoader.get_blocks(level_data)
	var targets     := LevelLoader.get_targets(level_data)
	for bd in blocks_data:
		var block_num := int(bd.id.substr(1))
		if targets.has(block_num):
			bd.target_origin = targets[block_num]
	_board.set_targets(blocks_data)
	for block_data in blocks_data:
		var block := BlockScene.instantiate() as Block
		_board.add_child(block)
		block.setup(block_data, value_a, _board)
		_blocks.append(block)

	_moved = false
	_active = true
	level_loaded.emit(current_level)
	var mn_y := _board.board_squares[0].y
	var mx_y := mn_y
	for sq in _board.board_squares:
		mn_y = mini(mn_y, sq.y)
		mx_y = maxi(mx_y, sq.y)
	var board_bottom := _board.position.y + (mx_y - mn_y + 1) * value_a
	var msg := LevelLoader.get_message(level_data)
	_has_message = not msg.is_empty()
	message_changed.emit(msg, board_bottom)
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

	# Teleport portals scale in during the same wave, timed by their cell diagonal
	for tp in _teleports:
		tp.block_scale = 0.0
		var diag := tp.portal_cell.x + tp.portal_cell.y
		var wave_index := 0
		for j in sorted_squares.size():
			if (sorted_squares[j].x + sorted_squares[j].y) <= diag:
				wave_index = j
		var delay      := _INTRO_CHAIN_DELAY + wave_index * stagger
		var captured   := tp
		var t          := create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
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
		if not _active:
			return
		_swipe_detector.enabled = true
		intro_finished.emit()
	)

# --- Teleport portal visual feedback ---

# Flash the two nodes of a portal pair when a block passes through.
func _pulse_portal_pair(entry: Vector2i, exit_cell: Vector2i) -> void:
	const PULSE := Color(2.0, 2.0, 2.0, 1.0)
	for tp in _teleports:
		if tp.portal_cell == entry or tp.portal_cell == exit_cell:
			var t := create_tween()
			t.tween_property(tp, "modulate", PULSE, 0.08) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			t.tween_property(tp, "modulate", Color.WHITE, 0.28) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
