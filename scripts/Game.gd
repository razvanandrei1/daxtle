extends Node2D

const BoardScene := preload("res://scenes/Board.tscn")
const BlockScene := preload("res://scenes/Block.tscn")
const MAX_LEVEL     := 5    # bump as more levels are added
const MOVE_DURATION := 0.13 # seconds per slide animation

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

	var movers := Movement.resolve(candidates, _blocks, _board_set, direction)

	if movers.is_empty():
		return

	_swipe_detector.enabled = false

	var tween := create_tween().set_parallel(true)

	for block in movers:
		block.grid_origin += block.data.dir_vector()
		var target_pos := _board.grid_to_local(block.grid_origin)
		tween.tween_property(block, "position", target_pos, MOVE_DURATION) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)

	tween.finished.connect(func() -> void:
		_swipe_detector.enabled = true  # T30 will also trigger win check here
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
