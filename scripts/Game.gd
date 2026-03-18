extends Node2D

const BoardScene := preload("res://scenes/Board.tscn")
const BlockScene := preload("res://scenes/Block.tscn")
const MAX_LEVEL     := 5    # bump as more levels are added
const MOVE_DURATION := 0.13 # seconds per slide animation

const WIN_BRIGHT := Color(1.5, 1.5, 1.5, 1.0)  # brightened modulate for glow pulse
const WIN_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const WIN_FADE   := Color(1.0, 1.0, 1.0, 0.0)

signal level_loaded(n: int)

var current_level: int = 1
var value_a: float = 0.0

var _board: Board
var _blocks: Array[Block] = []
var _board_set: Dictionary = {}   # Vector2i -> true, for fast cell lookup
var _swipe_detector: SwipeDetector


func _ready() -> void:
	_swipe_detector = $SwipeDetector
	_swipe_detector.swiped.connect(_on_swipe)
	_load_level(current_level)


func _on_swipe(direction: String) -> void:
	var candidates: Array[Block] = []
	for block in _blocks:
		if block.data.dir == direction:
			candidates.append(block)

	if candidates.is_empty():
		return

	var result   := Movement.resolve(candidates, _blocks, _board_set, direction)
	var movers:  Array[Block] = result["movers"]
	var invalid: Array[Block] = result["invalid"]

	if movers.is_empty() and invalid.is_empty():
		return

	_swipe_detector.enabled = false

	if not movers.is_empty():
		var tween := create_tween().set_parallel(true)
		for block in movers:
			block.grid_origin += block.data.dir_vector()
			var target_pos := _board.grid_to_local(block.grid_origin)
			tween.tween_property(block, "position", target_pos, MOVE_DURATION) \
				.set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_OUT)
		tween.finished.connect(func() -> void:
			if _check_win():
				_on_win()
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
		_load_level(clamp(current_level + 1, 1, MAX_LEVEL))
		_swipe_detector.enabled = true
	)


func go_next_level() -> void:
	_load_level(clamp(current_level + 1, 1, MAX_LEVEL))


func go_prev_level() -> void:
	_load_level(clamp(current_level - 1, 1, MAX_LEVEL))


func _load_level(level_number: int) -> void:
	if _board:
		_board.queue_free()
	_blocks.clear()
	_board_set.clear()

	var level_data := LevelLoader.load_level(level_number)
	if level_data.is_empty():
		push_error("Game: failed to load level %d" % level_number)
		return

	current_level = level_number

	# Board
	var squares := LevelLoader.get_board_squares(level_data)
	_board = BoardScene.instantiate()
	add_child(_board)
	value_a = _board.setup(squares)

	for sq in squares:
		_board_set[sq] = true

	# Blocks — added as children of the board so they share its coordinate space
	var blocks_data := LevelLoader.get_blocks(level_data)
	_board.set_targets(blocks_data)
	for block_data in blocks_data:
		var block: Block = BlockScene.instantiate()
		_board.add_child(block)
		block.setup(block_data, value_a, _board)
		_blocks.append(block)

	level_loaded.emit(current_level)
