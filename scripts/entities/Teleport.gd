class_name Teleport
extends Node2D

var portal_cell: Vector2i
var value_a:     float

# Tweened during intro alongside the board chain
var block_scale: float = 1.0:
	set(v):
		block_scale = v
		queue_redraw()


func setup(cell: Vector2i, va: float, board: Board) -> void:
	portal_cell = cell
	value_a     = va
	position    = board.grid_to_local(cell)
	queue_redraw()


func _draw() -> void:
	if block_scale <= 0.0:
		return
	var center := Vector2(value_a, value_a) * 0.5
	var radius  := value_a * 0.28 * block_scale
	var width   := value_a * 0.065 * block_scale
	var col     := GameTheme.TELEPORT_COLOR
	col.a        = block_scale
	draw_arc(center, radius, 0.0, TAU, 48, col, width, true)
	# Inner dot
	var dot_r := value_a * 0.07 * block_scale
	draw_circle(center, dot_r, col)
