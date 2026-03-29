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

# When true, block draws at full cell size (no inset) to cover the target frame
var full_size: bool = false:
	set(v):
		full_size = v
		queue_redraw()

# Tweened to shrink arrow independently of block_scale (e.g. win effect)
var arrow_scale: float = 1.0:
	set(v):
		arrow_scale = v
		queue_redraw()


func setup(block_data: BlockData, va: float, board: Board) -> void:
	data        = block_data
	value_a     = va
	color       = BlockColors.get_color(block_data.id)
	grid_origin = block_data.origin
	position    = board.grid_to_local(grid_origin)
	queue_redraw()


func _draw() -> void:
	if block_scale <= 0.0:
		return
	var full_sq := value_a * (1.0 - GameTheme.GAP_FRACTION)
	var inset   := 0.0 if full_size else value_a * GameTheme.BLOCK_INSET_FRACTION * 2.0
	var sq_size := full_sq - inset
	var radius  := value_a * GameTheme.CORNER_FRACTION * (sq_size / full_sq)
	var size    := sq_size * block_scale
	var r       := radius * block_scale
	var center := Vector2(value_a, value_a) * 0.5
	_draw_rounded_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), color, r)
	_draw_arrow()


func _draw_rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = false
	style.draw(get_canvas_item(), rect)


# --- Direction arrow ---
# Drawn as a rounded triangle matching the square corner style.
const ARROW_LENGTH := 0.36  # tip-to-base as a fraction of value_a
const ARROW_WIDTH  := 0.22  # half-width at base as a fraction of value_a
const ARC_STEPS    := 6     # points per rounded corner arc

func _draw_arrow() -> void:
	if arrow_alpha <= 0.0 or arrow_scale <= 0.0:
		return
	var arrow_color := color.darkened(0.30)
	arrow_color.a   = arrow_alpha

	var s := block_scale * arrow_scale

	var axis: Vector2
	match data.dir:
		"right": axis = Vector2( 1,  0)
		"left":  axis = Vector2(-1,  0)
		"down":  axis = Vector2( 0,  1)
		"up":    axis = Vector2( 0, -1)
		_:
			# Cargo block — draw a small dot instead of an arrow
			var c := Vector2(value_a, value_a) * 0.5
			draw_circle(c, value_a * 0.09 * s, arrow_color)
			return
	var perp := Vector2(-axis.y, axis.x)

	var half_len   := value_a * ARROW_LENGTH * 0.5 * s
	var half_width := value_a * ARROW_WIDTH * s
	var radius     := value_a * GameTheme.ARROW_CORNER_FRACTION * s

	var c      := Vector2(value_a, value_a) * 0.5
	var offset := axis * half_len * 0.12  # nudge toward tip for optical centering
	var tip := c + offset + axis * half_len
	var bl  := c + offset - axis * half_len + perp * half_width
	var br  := c + offset - axis * half_len - perp * half_width
	_draw_rounded_triangle(tip, bl, br, arrow_color, radius)


func _draw_rounded_triangle(v0: Vector2, v1: Vector2, v2: Vector2, col: Color, radius: float) -> void:
	var verts: Array[Vector2] = [v0, v1, v2]
	var pts := PackedVector2Array()

	for i in 3:
		var prev: Vector2 = verts[(i + 2) % 3]
		var curr: Vector2 = verts[i]
		var next: Vector2 = verts[(i + 1) % 3]

		var d1 := (prev - curr).normalized()
		var d2 := (next - curr).normalized()

		var dot_val    := clampf(d1.dot(d2), -1.0, 1.0)
		var half_angle := acos(dot_val) * 0.5
		if half_angle < 0.01:
			pts.append(curr)
			continue

		var bisector   := (d1 + d2).normalized()
		var arc_center := curr + bisector * (radius / sin(half_angle))
		var t1         := curr + d1 * radius
		var t2         := curr + d2 * radius

		var a1   := (t1 - arc_center).angle()
		var a2   := (t2 - arc_center).angle()
		var diff := a2 - a1
		while diff >  PI: diff -= TAU
		while diff < -PI: diff += TAU

		for j in (ARC_STEPS + 1):
			var a := a1 + diff * float(j) / float(ARC_STEPS)
			pts.append(arc_center + Vector2(cos(a), sin(a)) * radius)

	draw_colored_polygon(pts, col)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, col, 1.5, true)
