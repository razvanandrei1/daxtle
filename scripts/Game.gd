extends Node2D

const BoardScene := preload("res://scenes/Board.tscn")
const MAX_LEVEL := 4   # bump as more levels are added

signal level_loaded(n: int)

var current_level: int = 1
var value_a: float = 0.0

var _board: Board


func _ready() -> void:
	_load_level(current_level)


func go_next_level() -> void:
	_load_level(clamp(current_level + 1, 1, MAX_LEVEL))


func go_prev_level() -> void:
	_load_level(clamp(current_level - 1, 1, MAX_LEVEL))


func _load_level(level_number: int) -> void:
	if _board:
		_board.queue_free()

	var level_data := LevelLoader.load_level(level_number)
	if level_data.is_empty():
		push_error("Game: failed to load level %d" % level_number)
		return

	current_level = level_number
	var squares := LevelLoader.get_board_squares(level_data)

	_board = BoardScene.instantiate()
	add_child(_board)
	value_a = _board.setup(squares)

	level_loaded.emit(current_level)
