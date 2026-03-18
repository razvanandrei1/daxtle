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


const SHRINK := 0.10  # each square drawn at 75% of value_a, centred in the cell

func _draw() -> void:
	var pad  := value_a * SHRINK * 0.5  # inset on each side to keep it centred
	var size := value_a * (1.0 - SHRINK)
	for sq in data.squares:
		var origin := Vector2(sq) * value_a
		draw_rect(Rect2(origin + Vector2(pad, pad), Vector2(size, size)), color)
	_draw_chevrons()


# --- Chevrons ---

func _draw_chevrons() -> void:
	var ch_color := color.darkened(0.35)
	var half_h   := value_a * 0.28
	var depth    := value_a * 0.18
	var line_w   := maxf(2.0, value_a * 0.05)

	var axis: Vector2
	match data.dir:
		"right": axis = Vector2( 1,  0)
		"left":  axis = Vector2(-1,  0)
		"down":  axis = Vector2( 0,  1)
		"up":    axis = Vector2( 0, -1)
		_: return
	var perp := Vector2(-axis.y, axis.x)

	for sq in data.squares:
		var c        := Vector2(sq) * value_a + Vector2(value_a, value_a) * 0.5
		var tip      := c + axis  * depth
		var base_top := c - axis  * depth + perp * half_h
		var base_bot := c - axis  * depth - perp * half_h
		draw_polyline(PackedVector2Array([base_top, tip, base_bot]), ch_color, line_w, true)
