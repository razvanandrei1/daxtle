class_name MenuIcon
extends Node2D

signal pressed

const ICON_SIZE   := 58.0
const HIT_PADDING := 16.0
const BAR_COUNT   := 3
const BAR_WIDTH   := 0.55   # fraction of ICON_SIZE
const BAR_HEIGHT  := 0.08   # fraction of ICON_SIZE
const BAR_GAP     := 0.18   # fraction of ICON_SIZE
const BAR_RADIUS  := 0.04   # fraction of ICON_SIZE

var _color: Color


func _ready() -> void:
	_color = GameTheme.ACTIVE["text"]


func _draw() -> void:
	var w := ICON_SIZE * BAR_WIDTH
	var h := ICON_SIZE * BAR_HEIGHT
	var gap := ICON_SIZE * BAR_GAP
	var r := ICON_SIZE * BAR_RADIUS
	var total_h := BAR_COUNT * h + (BAR_COUNT - 1) * gap
	var start_y := -total_h * 0.5

	for i in BAR_COUNT:
		var y := start_y + i * (h + gap)
		var rect := Rect2(Vector2(-w * 0.5, y), Vector2(w, h))
		var style := StyleBoxFlat.new()
		style.bg_color = _color
		style.set_corner_radius_all(int(r))
		style.draw(get_canvas_item(), rect)


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
		pressed.emit()
		GameTheme.play_tap_pulse(self, func() -> void: pass)
