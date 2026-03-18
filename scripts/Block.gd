class_name Block
extends Node2D

var data: BlockData
var value_a: float
var color: Color

# Current grid origin (changes as the block moves)
var grid_origin: Vector2i


func setup(block_data: BlockData, va: float, board: Board) -> void:
	data        = block_data
	value_a     = va
	color       = BlockColors.get_color(block_data.id)
	grid_origin = block_data.origin
	position    = board.grid_to_local(grid_origin)
	queue_redraw()


func _draw() -> void:
	for sq in data.squares:
		var rect := Rect2(Vector2(sq) * value_a, Vector2(value_a, value_a))
		draw_rect(rect, color)
