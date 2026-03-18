extends Node2D

const BoardScene := preload("res://scenes/Board.tscn")
const BlockScene := preload("res://scenes/Block.tscn")
const MAX_LEVEL  := 5   # bump as more levels are added

signal level_loaded(n: int)

var current_level: int = 1
var value_a: float = 0.0

var _board: Board
var _blocks: Array[Block] = []


func _ready() -> void:
	_load_level(current_level)


func go_next_level() -> void:
	_load_level(clamp(current_level + 1, 1, MAX_LEVEL))


func go_prev_level() -> void:
	_load_level(clamp(current_level - 1, 1, MAX_LEVEL))


func _load_level(level_number: int) -> void:
	if _board:
		_board.queue_free()
	_blocks.clear()

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

	# Blocks — added as children of the board so they share its coordinate space
	var blocks_data := LevelLoader.get_blocks(level_data)
	_board.set_targets(blocks_data)
	for block_data in blocks_data:
		var block: Block = BlockScene.instantiate()
		_board.add_child(block)
		block.setup(block_data, value_a, _board)
		_blocks.append(block)

	level_loaded.emit(current_level)
