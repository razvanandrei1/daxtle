class_name MenuIcon
extends Node2D

signal pressed

const ICON_SIZE   := 74.0
const HIT_PADDING := 16.0

var _texture: Texture2D


func _ready() -> void:
	_texture = preload("res://assets/img/icon_menu.svg")


func _draw() -> void:
	if _texture:
		var size := Vector2(ICON_SIZE, ICON_SIZE)
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

	var half := ICON_SIZE * 0.5 + HIT_PADDING
	var hit := Rect2(
		global_position - Vector2(half, half),
		Vector2(half * 2.0, half * 2.0)
	)
	if hit.has_point(pos):
		get_viewport().set_input_as_handled()
		GameTheme.play_tap_pulse(self, func() -> void: pressed.emit())
