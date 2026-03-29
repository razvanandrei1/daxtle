class_name Board
extends Node2D

const MARGIN := 0.10  # 10% margin on each side → 80% usable area

var COLOR_SURFACE: Color  # set from GameTheme in setup()

var value_a: float = 0.0
var board_squares: Array[Vector2i] = []

var _min_grid := Vector2i.ZERO
var _target_colors: Dictionary = {}  # Vector2i -> Color
var _cell_scale: Dictionary = {}  # Vector2i -> float (0..1), missing key = fully drawn


# Called by Game after the node is in the scene tree.
# Returns value_a so other systems can size themselves.
func setup(squares: Array[Vector2i]) -> float:
	board_squares = squares
	COLOR_SURFACE = GameTheme.ACTIVE["surface"]

	var viewport_size := get_viewport().get_visible_rect().size
	value_a = _calculate_value_a(squares, viewport_size)
	_min_grid = _grid_min(squares)

	var cols := _grid_max(squares).x - _min_grid.x + 1
	var rows := _grid_max(squares).y - _min_grid.y + 1

	# Position the node so the board is centered on screen
	position = (viewport_size - Vector2(cols, rows) * value_a) / 2.0

	queue_redraw()
	return value_a


func set_targets(blocks_data: Array[BlockData]) -> void:
	_target_colors.clear()
	for block_data in blocks_data:
		var tint := BlockColors.get_color(block_data.id)
		for cell in block_data.target_origins:
			_target_colors[cell] = tint
	queue_redraw()



func clear_targets() -> void:
	_target_colors.clear()
	queue_redraw()



func set_cell_scale(cell: Vector2i, s: float) -> void:
	if s >= 1.0:
		_cell_scale.erase(cell)
	else:
		_cell_scale[cell] = s
	queue_redraw()



func _draw() -> void:
	var sq_size := value_a * (1.0 - GameTheme.GAP_FRACTION)
	var radius  := value_a * GameTheme.CORNER_FRACTION
	for sq in board_squares:
		var s := _cell_scale.get(sq, 1.0) as float
		if s <= 0.0:
			continue
		var r      := _square_rect(sq)
		var center := r.position + r.size * 0.5
		var size   := sq_size * s
		_draw_rounded_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), COLOR_SURFACE, radius * s)
	# Target cells: full colored square + inner block-sized square
	var inset := value_a * GameTheme.BLOCK_INSET_FRACTION * 2.0
	var block_size_base := sq_size - inset - 2.0  # same size as B element, 1px tighter each side
	var block_radius_base := radius * (block_size_base / sq_size)
	for cell in _target_colors:
		var s := _cell_scale.get(cell, 1.0) as float
		if s <= 0.0:
			continue
		var r      := _square_rect(cell)
		var center := r.position + r.size * 0.5
		var size   := sq_size * s
		# Full target square
		_draw_rounded_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), _target_colors[cell], radius * s)
		# Inner block-sized square with faded target color background
		var inner_size := block_size_base * s
		var bg_col: Color = _target_colors[cell]
		bg_col.a = 0.15
		var inner_rect := Rect2(center - Vector2(inner_size, inner_size) * 0.5, Vector2(inner_size, inner_size))
		_draw_rounded_rect(inner_rect, COLOR_SURFACE, block_radius_base * s)
		_draw_rounded_rect(inner_rect, bg_col, block_radius_base * s)




func _draw_rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), rect)


# Returns the local-space Rect2 for a grid position
func square_rect(grid_pos: Vector2i) -> Rect2:
	return _square_rect(grid_pos)


# Converts a grid position to a local-space pixel position (top-left of that cell)
func grid_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos - _min_grid) * value_a


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
