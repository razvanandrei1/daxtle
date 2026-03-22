# =============================================================================
# Game.gd — Core gameplay controller
# =============================================================================
# Manages the game board, blocks, teleports, and all gameplay animations.
# Handles swipe input, movement resolution, win/stuck detection, and
# level transitions (intro, exit, reset).
# =============================================================================
class_name Game
extends Node2D

const BoardScene      := preload("res://scenes/entities/Board.tscn")
const BlockScene      := preload("res://scenes/entities/Block.tscn")
const FixedBlockScene := preload("res://scenes/entities/FixedBlock.tscn")
const TeleportScene   := preload("res://scenes/entities/Teleport.tscn")
const _MOVE_DURATION_DEFAULT := 0.13  # fallback if no slide SFX loaded
var MOVE_DURATION: float = _MOVE_DURATION_DEFAULT

const WIN_BRIGHT := Color(1.5, 1.5, 1.5, 1.0)
const WIN_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const WIN_FADE   := Color(1.0, 1.0, 1.0, 0.0)

# --- Game mode ---
enum Mode { CAMPAIGN, CHALLENGE }
var mode: Mode = Mode.CAMPAIGN
var _challenge_streak: int = 0
var _challenge_pool: Array[int] = []
var _challenge_pool_index: int = 0

# --- Challenge timer ---
const CHALLENGE_TIME_START := 30.0   # seconds for first puzzle
const CHALLENGE_TIME_DECAY := 1.5    # seconds removed per streak point
const CHALLENGE_TIME_MIN   := 10.0   # minimum time allowed
var _challenge_time_left: float = 0.0
var _challenge_time_max:  float = 0.0
var _challenge_timer_active: bool = false
var _challenge_timer_alpha: float = 0.5

# --- Signals communicated to Main.gd via connections ---
signal level_loaded(n: int)          # emitted after a level is fully loaded
signal menu_pressed                  # emitted when menu icon is tapped
signal message_changed(text: String, board_bottom: float)  # level tutorial message
signal intro_finished                # intro animation done (triggers message display)
signal dismiss_message               # hide tutorial message (on win)
signal all_levels_completed          # last level beaten — triggers completion popup
signal challenge_game_over(streak: int, best_streak: int)
var _has_message: bool = false

var current_level: int = 20
var _moved: bool = false
var _active: bool = false   # false while stopped or transitioning out
var value_a: float = 0.0    # cell size in pixels, computed by Board.setup()

var _board: Board
var _blocks: Array[Block] = []
var _fixed_blocks: Array[FixedBlock] = []
var _board_set:    Dictionary = {}   # Vector2i -> true, for fast cell lookup
var _fixed_set:    Dictionary = {}   # Vector2i -> true, C block occupied cells
var _teleport_map: Dictionary = {}   # Vector2i -> Vector2i, portal entrance -> exit
var _teleports:    Array[Teleport] = []
var _swipe_detector: SwipeDetector
var _intro_tweens: Array[Tween] = []

@onready var _header: SceneHeader = $SceneHeader
@onready var _reset:  ResetIcon   = $ResetIcon


func _process(delta: float) -> void:
	if mode != Mode.CHALLENGE or not _challenge_timer_active:
		return
	_challenge_time_left -= delta
	queue_redraw()
	if _challenge_time_left <= 0.0:
		_challenge_time_left = 0.0
		_challenge_timer_active = false
		_on_stuck()


func _draw() -> void:
	if mode != Mode.CHALLENGE:
		return
	var vp := get_viewport().get_visible_rect().size

	# Timer — rounded frame around the board that shrinks from a corner
	if _challenge_timer_alpha > 0.0 and _board:
		var ratio := clampf(_challenge_time_left / _challenge_time_max, 0.0, 1.0)
		if ratio > 0.0:
			var timer_col := GameTheme.ACTIVE["text"]
			timer_col.a = _challenge_timer_alpha
			_draw_timer_frame(ratio, timer_col)

	# Best streak text at bottom
	var font := GameTheme.FONT_BOLD
	var text := "Best: %d" % SaveData.get_best_streak()
	var fs := 42
	var col := GameTheme.ACTIVE["text"]
	col.a = 0.5
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var safe_bot := GameTheme.get_safe_area_bottom()
	var y := vp.y - maxf(safe_bot, 40.0) - 20.0
	draw_string(font, Vector2((vp.x - tw) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_timer_frame(ratio: float, col: Color) -> void:
	# Build a rounded rect path around the board
	var padding := value_a * 0.14
	var mn := _board.board_squares[0]
	var mx := mn
	for sq in _board.board_squares:
		mn = Vector2i(mini(mn.x, sq.x), mini(mn.y, sq.y))
		mx = Vector2i(maxi(mx.x, sq.x), maxi(mx.y, sq.y))
	var cols_count := mx.x - mn.x + 1
	var rows_count := mx.y - mn.y + 1

	var rect_pos := _board.position - Vector2(padding, padding)
	var rect_size := Vector2(cols_count, rows_count) * value_a + Vector2(padding * 2, padding * 2)
	var r := value_a * GameTheme.CORNER_FRACTION * 2.0
	r = minf(r, minf(rect_size.x, rect_size.y) * 0.5)

	# Generate points along the rounded rect (clockwise from top-center)
	var pts := PackedVector2Array()
	var x0 := rect_pos.x
	var y0 := rect_pos.y
	var x1 := rect_pos.x + rect_size.x
	var y1 := rect_pos.y + rect_size.y
	var cx := (x0 + x1) * 0.5
	var arc_steps := 8

	# Start at top-center, go right
	pts.append(Vector2(cx, y0))
	pts.append(Vector2(x1 - r, y0))
	# Top-right corner
	for i in arc_steps + 1:
		var a := -PI * 0.5 + float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x1 - r + cos(a) * r, y0 + r + sin(a) * r))
	# Right edge
	pts.append(Vector2(x1, y1 - r))
	# Bottom-right corner
	for i in arc_steps + 1:
		var a := float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x1 - r + cos(a) * r, y1 - r + sin(a) * r))
	# Bottom edge (right to left)
	pts.append(Vector2(x0 + r, y1))
	# Bottom-left corner
	for i in arc_steps + 1:
		var a := PI * 0.5 + float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x0 + r + cos(a) * r, y1 - r + sin(a) * r))
	# Left edge
	pts.append(Vector2(x0, y0 + r))
	# Top-left corner
	for i in arc_steps + 1:
		var a := PI + float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x0 + r + cos(a) * r, y0 + r + sin(a) * r))
	# Top edge back to center
	pts.append(Vector2(cx, y0))

	# Calculate cumulative distances
	var total_len := 0.0
	var lengths := PackedFloat32Array()
	lengths.append(0.0)
	for i in range(1, pts.size()):
		total_len += pts[i].distance_to(pts[i - 1])
		lengths.append(total_len)

	# Draw only the portion corresponding to ratio
	var draw_len := total_len * ratio
	var draw_pts := PackedVector2Array()
	for i in pts.size():
		if lengths[i] <= draw_len:
			draw_pts.append(pts[i])
		else:
			# Interpolate the final point
			if i > 0:
				var seg_len := lengths[i] - lengths[i - 1]
				if seg_len > 0:
					var t := (draw_len - lengths[i - 1]) / seg_len
					draw_pts.append(pts[i - 1].lerp(pts[i], t))
			break

	if draw_pts.size() >= 2:
		var width := value_a * 0.055
		# Flash red when below 5 seconds
		var draw_col := col
		if _challenge_time_left < 5.0 and _challenge_timer_active:
			draw_col = GameTheme.ACTIVE["blocks"][1]  # coral/red
			var flash := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
			draw_col.a = lerpf(0.3, col.a, flash)
		draw_polyline(draw_pts, draw_col, width, true)


func _ready() -> void:
	# Match slide animation duration to the slide sound effect
	var sfx_dur := AudioManager.get_sfx_duration("slide")
	if sfx_dur > 0.0:
		MOVE_DURATION = sfx_dur

	_swipe_detector = $SwipeDetector
	_swipe_detector.swiped.connect(_on_swipe)
	_swipe_detector.double_tapped.connect(func() -> void:
		if _active and _moved and mode != Mode.CHALLENGE:
			reset_level()
	)

	_header.back_pressed.connect(func() -> void: menu_pressed.emit())
	_reset.pressed.connect(func() -> void:
		if mode != Mode.CHALLENGE:
			reset_level()
	)
	_reset.position = Vector2(_header.right_x, _header.bar_cy)
	_reset.visible = false


func set_level(n: int) -> void:
	if mode == Mode.CHALLENGE:
		_header.set_title("%d" % _challenge_streak)
	else:
		_header.set_title("%d" % n)
	_reset.visible = false


func show_reset() -> void:
	if mode == Mode.CHALLENGE:
		return
	if not _reset.visible:
		_reset.visible = true
		if Globals.DEBUG_MODE:
			_reset.scale = Vector2.ONE
			return
		_reset.scale = Vector2.ZERO
		var tween := create_tween()
		tween.tween_property(_reset, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_reset() -> void:
	if _reset.visible:
		if Globals.DEBUG_MODE:
			_reset.visible = false
			return
		var tween := create_tween()
		tween.tween_property(_reset, "scale", Vector2.ZERO, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.finished.connect(func() -> void:
			_reset.visible = false
		)


func load_level(n: int) -> void:
	_load_level(n)


func _start_challenge_timer() -> void:
	if mode != Mode.CHALLENGE:
		return
	_challenge_time_max = maxf(
		CHALLENGE_TIME_START - _challenge_streak * CHALLENGE_TIME_DECAY,
		CHALLENGE_TIME_MIN
	)
	_challenge_time_left = _challenge_time_max
	_challenge_timer_alpha = 0.0
	_challenge_timer_active = true
	var fade_in := create_tween()
	fade_in.tween_method(func(v: float) -> void:
		_challenge_timer_alpha = v
		queue_redraw()
	, 0.0, 0.5, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func start_challenge() -> void:
	mode = Mode.CHALLENGE
	_challenge_streak = 0
	_challenge_timer_active = false
	_challenge_timer_alpha = 0.0
	_challenge_time_left = 0.0
	queue_redraw()
	var count := LevelLoader.count_challenge_levels()
	_challenge_pool.clear()
	for i in count:
		_challenge_pool.append(i + 1)
	_challenge_pool.shuffle()
	_challenge_pool_index = 0
	_load_challenge_next()


func _load_challenge_next() -> void:
	if _challenge_pool.is_empty():
		return
	if _challenge_pool_index >= _challenge_pool.size():
		_challenge_pool.shuffle()
		_challenge_pool_index = 0
	var level_n := _challenge_pool[_challenge_pool_index]
	_challenge_pool_index += 1
	var level_data := LevelLoader.load_challenge_level(level_n)
	if level_data.is_empty():
		return
	_load_level_data(level_data)


func _load_level_data(level_data: Dictionary) -> void:
	# Shared level loading logic — used by both campaign and challenge
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

	var squares := LevelLoader.get_board_squares(level_data)
	_board = BoardScene.instantiate() as Board
	add_child(_board)
	value_a = _board.setup(squares)

	for sq in squares:
		_board_set[sq] = true

	var fixed_data := LevelLoader.get_fixed_blocks(level_data)
	for fd in fixed_data:
		var fb := FixedBlockScene.instantiate() as FixedBlock
		_board.add_child(fb)
		fb.setup(fd, value_a, _board)
		_fixed_blocks.append(fb)
		for cell in fd.cells():
			_fixed_set[cell] = true

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

	var blocks_data := LevelLoader.get_blocks(level_data)
	var targets     := LevelLoader.get_targets(level_data)
	for bd in blocks_data:
		var block_num := int(bd.id.substr(1)) if bd.id is String else int(bd.id)
		if targets.has(block_num):
			bd.target_origins.assign(targets[block_num])
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
	queue_redraw()
	_play_intro_animation()


# Debug: skip intro animation and jump to a level instantly
func _debug_load(n: int) -> void:
	n = clampi(n, 1, LevelLoader.count_levels())
	stop()
	_load_level(n)
	# Skip intro — set everything to final state immediately
	for tw in _intro_tweens:
		if tw:
			tw.kill()
	_intro_tweens.clear()
	for sq in _board.board_squares:
		_board.set_cell_scale(sq, 1.0)
	for fb in _fixed_blocks:
		fb.block_scale = 1.0
	for tp in _teleports:
		tp.block_scale = 1.0
	for block in _blocks:
		block.block_scale = 1.0
		block.arrow_alpha = 1.0
	_swipe_detector.enabled = true
	_active = true


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not Globals.DEBUG_MODE:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_COMMA:
				_debug_load(current_level - 1)
			KEY_PERIOD:
				_debug_load(current_level + 1)
			KEY_R:
				_debug_load(current_level)


func stop() -> void:
	_active = false
	_challenge_timer_active = false
	_challenge_timer_alpha = 0.0
	_challenge_time_left = 0.0
	queue_redraw()
	_swipe_detector.enabled = false
	for tw in _intro_tweens:
		if tw:
			tw.kill()
	_intro_tweens.clear()


# --- Swipe handling ---
# Called when the player swipes in a direction. Resolves movement via Movement.resolve(),
# then animates movers (normal slide or teleport sequence) and shakes invalid blocks.
func _on_swipe(direction: String) -> void:
	if not _active:
		return
	# Collect blocks that match the swipe direction
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

	# Resolve which blocks can move, which are blocked, and which teleport
	var result            := Movement.resolve(candidates, _blocks, _board_set, direction, _fixed_set, _teleport_map)
	var movers:            Array[Block] = result["movers"]
	var invalid:           Array[Block] = result["invalid"]
	var teleport_exits:    Dictionary   = result["teleport_exits"]
	var teleport_entries:  Dictionary   = result["teleport_entries"]

	if movers.is_empty() and invalid.is_empty():
		return

	if not _moved:
		_moved = true
		show_reset()

	_swipe_detector.enabled = false

	if Globals.DEBUG_MODE:
		if not movers.is_empty():
			AudioManager.play_sfx("slide")
			Haptics.tap()
		for block in movers:
			if teleport_exits.has(block):
				block.grid_origin = teleport_exits[block]
			else:
				block.grid_origin += dv
			block.position = _board.grid_to_local(block.grid_origin)

		if _check_win():
			_on_win()
		elif _is_stuck():
			_on_stuck()
		elif mode == Mode.CHALLENGE and not _is_winnable():
			_on_stuck()
		else:
			_swipe_detector.enabled = true
		return

	if not movers.is_empty():
		AudioManager.play_sfx("slide")
		Haptics.tap()
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

				# Sequential: slide → shrink → jump → pop → slide
				const SHRINK := 0.14
				const POP    := 0.18
				var tp := create_tween()
				tp.tween_property(block, "position", entry_pos, MOVE_DURATION) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tp.tween_method(func(v: float) -> void: block.block_scale = v,
					1.0, 0.0, SHRINK) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tp.tween_callback(func(): block.position = exit_pos)
				tp.tween_method(func(v: float) -> void: block.block_scale = v,
					0.0, 1.0, POP) \
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
			elif mode == Mode.CHALLENGE and not _is_winnable():
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


# Plays a nudge-and-spring-back animation on blocks that can't move (hit a wall/obstacle).
func _shake_blocks(blocks: Array[Block], direction: String, re_enable_after: bool) -> void:
	AudioManager.play_sfx("invalid")
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


# Returns true if every block is sitting on one of its target cells.
func _check_win() -> bool:
	for block in _blocks:
		if not block.data.target_origins.has(block.grid_origin):
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


# Returns true if the current board state can still be solved (BFS check).
func _is_winnable() -> bool:
	return PuzzleSolver.is_solvable(_blocks, _board_set, _fixed_set, _teleport_map)


# Called when no block can move or position is no longer winnable.
func _on_stuck() -> void:
	_swipe_detector.enabled = false
	_challenge_timer_active = false
	if mode == Mode.CHALLENGE:
		var fade := create_tween()
		fade.tween_method(func(v: float) -> void:
			_challenge_timer_alpha = v
			queue_redraw()
		, _challenge_timer_alpha, 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	Haptics.fail()

	if Globals.DEBUG_MODE:
		reset_level()
		return

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
			if mode == Mode.CHALLENGE:
				_active = false
				var best := SaveData.get_best_streak()
				if _challenge_streak > best:
					SaveData.set_best_streak(_challenge_streak)
					best = _challenge_streak
				challenge_game_over.emit(_challenge_streak, best)
			else:
				reset_level()
	)


# --- Win sequence: flash B blocks → exit chain animation → load next level (or complete) ---
func _on_win() -> void:
	_swipe_detector.enabled = false
	_challenge_timer_active = false
	if mode == Mode.CHALLENGE:
		var fade := create_tween()
		fade.tween_method(func(v: float) -> void:
			_challenge_timer_alpha = v
			queue_redraw()
		, _challenge_timer_alpha, 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("win")
	_hide_reset()

	# Advance progress if this is the furthest level completed (campaign only)
	if mode == Mode.CAMPAIGN:
		var next := current_level + 1
		if next > SaveData.get_progress_level():
			SaveData.set_progress_level(next)

	if Globals.DEBUG_MODE:
		if _has_message:
			dismiss_message.emit()
		if current_level >= LevelLoader.count_levels():
			all_levels_completed.emit()
		else:
			_load_level(current_level + 1)
		return

	if _has_message:
		dismiss_message.emit()

	Haptics.win()
	# Hide targets, A cells under B blocks, and teleports before the flash
	_board.clear_targets()
	for block in _blocks:
		_board.set_cell_scale(block.grid_origin, 0.0)
	for tp in _teleports:
		tp.visible = false

	# --- Shrink arrows on B blocks, then flash ---
	var arrow_shrink := create_tween().set_parallel(true)
	for block in _blocks:
		arrow_shrink.tween_method(func(v: float) -> void: block.arrow_scale = v,
			1.0, 0.0, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	arrow_shrink.finished.connect(func() -> void:
		# Smooth double fade flash on B blocks
		var flash := create_tween().set_parallel(true)
		for block in _blocks:
			flash.tween_property(block, "modulate:a", 0.0, 0.15) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			flash.tween_property(block, "modulate:a", 1.0, 0.20).set_delay(0.20) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flash.tween_property(block, "modulate:a", 0.0, 0.15).set_delay(0.43) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			flash.tween_property(block, "modulate:a", 1.0, 0.20).set_delay(0.63) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		flash.finished.connect(func() -> void:
			_play_exit_chain()
		)
	)


# Exit animation: all elements scale down in a diagonal wave (bottom-right → top-left),
# then loads the next level or emits all_levels_completed.
func _play_exit_chain() -> void:
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
			if mode == Mode.CHALLENGE:
				_challenge_streak += 1
				_load_challenge_next()
			elif current_level >= LevelLoader.count_levels():
				all_levels_completed.emit()
			else:
				_load_level(current_level + 1)
	)


func reset_level() -> void:
	AudioManager.play_sfx("reset")
	_swipe_detector.enabled = false
	_moved = false
	level_loaded.emit(current_level)  # triggers UI to hide reset icon via set_level

	if Globals.DEBUG_MODE:
		for block in _blocks:
			block.grid_origin = block.data.origin
			block.position = _board.grid_to_local(block.grid_origin)

		_swipe_detector.enabled = true
		return

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


# --- Level loading ---
# Clears the current level, parses JSON data via LevelLoader, instantiates
# all entities (board, blocks, fixed blocks, teleports), and plays the intro animation.
func _load_level(level_number: int) -> void:
	var level_data := LevelLoader.load_level(level_number)
	if level_data.is_empty():
		push_error("Game: failed to load level %d" % level_number)
		return
	current_level = level_number
	_load_level_data(level_data)


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
	if Globals.DEBUG_MODE:
		# Skip intro — set everything to final state immediately
		for sq in _board.board_squares:
			_board.set_cell_scale(sq, 1.0)
		for fb in _fixed_blocks:
			fb.block_scale = 1.0
		for tp in _teleports:
			tp.block_scale = 1.0
		for block in _blocks:
			block.block_scale = 1.0
			block.arrow_alpha = 1.0
		_swipe_detector.enabled = true
		_start_challenge_timer()
		intro_finished.emit()
		return

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
		_start_challenge_timer()
		intro_finished.emit()
	)

# --- Teleport portal visual feedback ---

# Flash the two nodes of a portal pair when a block passes through.
func _pulse_portal_pair(entry: Vector2i, exit_cell: Vector2i) -> void:
	AudioManager.play_sfx("teleport")
	for tp in _teleports:
		if tp.portal_cell == entry or tp.portal_cell == exit_cell:
			var t := create_tween()
			t.tween_property(tp, "modulate:a", 0.0, 0.10) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t.tween_property(tp, "modulate:a", 1.0, 0.14) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
