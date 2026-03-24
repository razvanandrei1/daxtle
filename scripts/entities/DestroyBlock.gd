class_name DestroyBlock
extends Node2D

var data: DestroyBlockData
var value_a: float
var grid_origin: Vector2i

var block_scale: float = 1.0:
	set(v):
		block_scale = v
		queue_redraw()


func setup(destroy_data: DestroyBlockData, va: float, board: Board) -> void:
	data        = destroy_data
	value_a     = va
	grid_origin = destroy_data.origin
	position    = board.grid_to_local(grid_origin)
	queue_redraw()


func _draw() -> void:
	if block_scale <= 0.0:
		return
	var sq_size := value_a * (1.0 - GameTheme.GAP_FRACTION)
	var radius  := value_a * GameTheme.CORNER_FRACTION
	var size    := sq_size * block_scale
	var r       := radius * block_scale
	var center := Vector2(value_a, value_a) * 0.5

	# Dark block color — darkened version of the surface color
	var col := GameTheme.ACTIVE["fixed"]
	col = col.lightened(0.15)
	_draw_rounded_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), col, r)

	# Draw an X mark to distinguish from fixed blocks
	_draw_x_mark(center)


func _draw_x_mark(center: Vector2) -> void:
	var s := value_a * 0.12 * block_scale
	var col := Color(GameTheme.ACTIVE["fixed"]).darkened(0.25)
	col.a = 0.6
	var w := value_a * 0.035 * block_scale
	draw_line(center + Vector2(-s, -s), center + Vector2(s, s), col, w, true)
	draw_line(center + Vector2(s, -s), center + Vector2(-s, s), col, w, true)


func _draw_rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), rect)
