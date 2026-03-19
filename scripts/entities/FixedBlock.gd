class_name FixedBlock
extends Node2D

var data: FixedBlockData
var value_a: float
var color: Color

# Tweened during intro: scales in with the board wave
var block_scale: float = 1.0:
	set(v):
		block_scale = v
		queue_redraw()


func setup(fixed_block_data: FixedBlockData, va: float, board: Board) -> void:
	data    = fixed_block_data
	value_a = va
	color   = GameTheme.ACTIVE["fixed"]
	position = board.grid_to_local(data.origin)
	queue_redraw()


func _draw() -> void:
	if block_scale <= 0.0:
		return
	var sq_size := value_a * (1.0 - GameTheme.GAP_FRACTION)
	var radius  := value_a * GameTheme.CORNER_FRACTION
	var size    := sq_size * block_scale
	var r       := radius * block_scale
	for sq in data.squares:
		var center := Vector2(sq) * value_a + Vector2(value_a, value_a) * 0.5
		_draw_rounded_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), color, r)


func _draw_rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), rect)
