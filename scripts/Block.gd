class_name Block
extends Node2D

const ARROW_COLOR := Color(1.0, 1.0, 1.0, 0.90)

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
	_draw_arrow()


# --- Arrow ---

func _draw_arrow() -> void:
	var center := _block_center()
	var s      := value_a * 0.30  # half-length of the arrow

	var pts: PackedVector2Array
	match data.dir:
		"right":
			pts = PackedVector2Array([
				center + Vector2( s,       0.0   ),
				center + Vector2(-s * 0.5, -s * 0.75),
				center + Vector2(-s * 0.5,  s * 0.75),
			])
		"left":
			pts = PackedVector2Array([
				center + Vector2(-s,       0.0   ),
				center + Vector2( s * 0.5,  s * 0.75),
				center + Vector2( s * 0.5, -s * 0.75),
			])
		"down":
			pts = PackedVector2Array([
				center + Vector2( 0.0,    s      ),
				center + Vector2(-s * 0.75, -s * 0.5),
				center + Vector2( s * 0.75, -s * 0.5),
			])
		"up":
			pts = PackedVector2Array([
				center + Vector2( 0.0,   -s      ),
				center + Vector2( s * 0.75, s * 0.5),
				center + Vector2(-s * 0.75, s * 0.5),
			])

	if pts.size() == 3:
		draw_polygon(pts, PackedColorArray([ARROW_COLOR, ARROW_COLOR, ARROW_COLOR]))


# Visual center of the block in local space
func _block_center() -> Vector2:
	var sum := Vector2.ZERO
	for sq in data.squares:
		sum += Vector2(sq) * value_a + Vector2(value_a, value_a) * 0.5
	return sum / data.squares.size()
