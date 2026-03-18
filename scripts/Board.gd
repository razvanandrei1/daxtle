class_name Board
extends Node2D

const MARGIN := 0.10  # 10% margin on each side → 80% usable area

const COLOR_LIGHT := Color(0.94, 0.92, 0.87)  # warm cream
const COLOR_DARK  := Color(0.78, 0.75, 0.69)  # warm grey-beige

var value_a: float = 0.0
var board_squares: Array[Vector2i] = []

var _min_grid := Vector2i.ZERO


# Called by Game after the node is in the scene tree.
# Returns value_a so other systems can size themselves.
func setup(squares: Array[Vector2i]) -> float:
	board_squares = squares

	var viewport_size := get_viewport().get_visible_rect().size
	value_a = _calculate_value_a(squares, viewport_size)
	_min_grid = _grid_min(squares)

	var cols := _grid_max(squares).x - _min_grid.x + 1
	var rows := _grid_max(squares).y - _min_grid.y + 1

	# Position the node so the board is centered on screen
	position = (viewport_size - Vector2(cols, rows) * value_a) / 2.0

	queue_redraw()
	return value_a


func _draw() -> void:
	for sq in board_squares:
		var color := COLOR_LIGHT if (sq.x + sq.y) % 2 == 0 else COLOR_DARK
		draw_rect(_square_rect(sq), color)


# Returns the local-space Rect2 for a grid position
func square_rect(grid_pos: Vector2i) -> Rect2:
	return _square_rect(grid_pos)


func _square_rect(grid_pos: Vector2i) -> Rect2:
	var local := Vector2(grid_pos - _min_grid) * value_a
	return Rect2(local, Vector2(value_a, value_a))


# --- Static helpers ---

static func _calculate_value_a(squares: Array[Vector2i], viewport_size: Vector2) -> float:
	if squares.is_empty():
		push_error("Board: cannot calculate Value_A — squares array is empty")
		return 0.0
	var mn := _grid_min(squares)
	var mx := _grid_max(squares)
	var cols := mx.x - mn.x + 1
	var rows := mx.y - mn.y + 1
	var usable_width  := viewport_size.x * (1.0 - 2.0 * MARGIN)
	var usable_height := viewport_size.y * (1.0 - 2.0 * MARGIN)
	return min(usable_width / cols, usable_height / rows)


static func _grid_min(squares: Array[Vector2i]) -> Vector2i:
	var mn := squares[0]
	for sq in squares:
		mn = Vector2i(min(mn.x, sq.x), min(mn.y, sq.y))
	return mn


static func _grid_max(squares: Array[Vector2i]) -> Vector2i:
	var mx := squares[0]
	for sq in squares:
		mx = Vector2i(max(mx.x, sq.x), max(mx.y, sq.y))
	return mx
