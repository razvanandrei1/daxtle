class_name Board
extends Node2D

const MARGIN := 0.10  # 10% margin on each side → 80% usable area

var value_a: float = 0.0
var board_squares: Array[Vector2i] = []


func setup(squares: Array[Vector2i]) -> float:
	board_squares = squares
	value_a = _calculate_value_a(squares, get_viewport().get_visible_rect().size)
	return value_a


static func _calculate_value_a(squares: Array[Vector2i], viewport_size: Vector2) -> float:
	if squares.is_empty():
		push_error("Board: cannot calculate Value_A — squares array is empty")
		return 0.0

	var min_x := squares[0].x
	var max_x := squares[0].x
	var min_y := squares[0].y
	var max_y := squares[0].y

	for sq in squares:
		min_x = min(min_x, sq.x)
		max_x = max(max_x, sq.x)
		min_y = min(min_y, sq.y)
		max_y = max(max_y, sq.y)

	var cols := max_x - min_x + 1
	var rows := max_y - min_y + 1

	var usable_width  := viewport_size.x * (1.0 - 2.0 * MARGIN)
	var usable_height := viewport_size.y * (1.0 - 2.0 * MARGIN)

	return min(usable_width / cols, usable_height / rows)
