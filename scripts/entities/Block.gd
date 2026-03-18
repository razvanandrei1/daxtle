class_name Block
extends Node2D

var data: BlockData
var value_a: float
var color: Color

# Current grid origin (changes as the block moves)
var grid_origin: Vector2i

# Tweened during intro: squares scale up from centre before arrow appears
var block_scale: float = 1.0:
	set(v):
		block_scale = v
		queue_redraw()

# Tweened separately so the arrow fades in after the block scales up
var arrow_alpha: float = 1.0:
	set(v):
		arrow_alpha = v
		queue_redraw()


func setup(block_data: BlockData, va: float, board: Board) -> void:
	data        = block_data
	value_a     = va
	color       = BlockColors.get_color(block_data.id)
	grid_origin = block_data.origin
	position    = board.grid_to_local(grid_origin)
	queue_redraw()


const SHRINK := 0.10  # each square drawn at 90% of value_a, centred in the cell

func _draw() -> void:
	if block_scale <= 0.0:
		return
	var base := value_a * (1.0 - SHRINK)
	var size := base * block_scale
	for sq in data.squares:
		var center := Vector2(sq) * value_a + Vector2(value_a, value_a) * 0.5
		draw_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), color)
	_draw_arrow()


# --- Direction arrow ---
# Drawn as a filled triangle: clean and readable at any size.
const ARROW_LENGTH := 0.36  # tip-to-base as a fraction of value_a
const ARROW_WIDTH  := 0.22  # half-width at base as a fraction of value_a

func _draw_arrow() -> void:
	if arrow_alpha <= 0.0:
		return
	var arrow_color := color.darkened(0.30)
	arrow_color.a   = arrow_alpha

	var axis: Vector2
	match data.dir:
		"right": axis = Vector2( 1,  0)
		"left":  axis = Vector2(-1,  0)
		"down":  axis = Vector2( 0,  1)
		"up":    axis = Vector2( 0, -1)
		_: return
	var perp := Vector2(-axis.y, axis.x)

	var half_len   := value_a * ARROW_LENGTH * 0.5
	var half_width := value_a * ARROW_WIDTH

	for sq in data.squares:
		var c    := Vector2(sq) * value_a + Vector2(value_a, value_a) * 0.5
		var tip  := c + axis * half_len
		var bl   := c - axis * half_len + perp * half_width
		var br   := c - axis * half_len - perp * half_width
		draw_polygon(
			PackedVector2Array([tip, bl, br]),
			PackedColorArray([arrow_color, arrow_color, arrow_color])
		)
