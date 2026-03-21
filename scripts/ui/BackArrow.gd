class_name BackArrow
extends Node2D

signal pressed

const ARROW_SIZE    := 58.0   # overall arrow size
const HIT_PADDING   := 16.0   # extra tap area around the arrow

var _texture: Texture2D


func _ready() -> void:
	_texture = preload("res://assets/img/icon_back.svg")


func _draw() -> void:
	if _texture:
		var size := Vector2(ARROW_SIZE, ARROW_SIZE)
		draw_texture_rect(_texture, Rect2(-size * 0.5, size), false)


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

	var half := ARROW_SIZE * 0.5 + HIT_PADDING
	var hit := Rect2(
		global_position - Vector2(half, half),
		Vector2(half * 2.0, half * 2.0)
	)
	if hit.has_point(pos):
		get_viewport().set_input_as_handled()
		pressed.emit()
		GameTheme.play_tap_pulse(self, func() -> void: pass)
