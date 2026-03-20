class_name ResetIcon
extends Node2D

signal pressed

const ICON_SIZE   := 58.0
const HIT_PADDING := 16.0
const ARC_STEPS   := 6

var _color: Color


func _ready() -> void:
	_color = GameTheme.ACTIVE["text"]


func _draw() -> void:
	var r      := ICON_SIZE * 0.36
	var weight := ICON_SIZE * 0.09

	# Draw a smooth ¾ arc (from ~40° past 12 o'clock, sweeping 280°)
	var gap     := PI * 0.28  # gap at the top where the arrowhead sits
	var start_a := -PI * 0.5 + gap
	var end_a   := -PI * 0.5 + TAU - gap * 0.15
	draw_arc(Vector2.ZERO, r, start_a, end_a, 48, _color, weight, true)

	# Arrowhead at the start of the arc (clockwise direction)
	# The arrow tip points in the tangent direction of the arc at start_a
	var tip_on_arc := Vector2(r, 0.0).rotated(start_a)

	# Tangent at start_a points clockwise (perpendicular inward to the arc direction)
	var tangent := Vector2(-sin(start_a), cos(start_a))  # clockwise tangent
	var normal  := Vector2(cos(start_a), sin(start_a))   # outward radial

	var arrow_len := ICON_SIZE * 0.22
	var arrow_w   := ICON_SIZE * 0.15

	var tip := tip_on_arc + tangent * arrow_len * 0.6
	var al  := tip_on_arc + normal * arrow_w - tangent * arrow_len * 0.3
	var ar  := tip_on_arc - normal * arrow_w - tangent * arrow_len * 0.3

	_draw_rounded_triangle(tip, al, ar, _color, ICON_SIZE * 0.05)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var pos: Vector2
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton \
			and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (event as InputEventMouseButton).position
	else:
		return

	var half := ICON_SIZE * 0.5 + HIT_PADDING
	var hit := Rect2(
		global_position - Vector2(half, half),
		Vector2(half * 2.0, half * 2.0)
	)
	if hit.has_point(pos):
		get_viewport().set_input_as_handled()
		GameTheme.play_tap_pulse(self, func() -> void: pressed.emit())


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
