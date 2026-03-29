class_name HintIcon
extends Node2D

signal pressed

const ICON_SIZE   := 111.0
const HIT_PADDING := 16.0

var _texture: Texture2D

## "available" = tapping costs a hint; "consumed" = re-shows nudge; "disabled" = faded, no interaction
var state: StringName = &"available":
	set(v):
		state = v
		queue_redraw()

var hints_remaining: int = 0:
	set(v):
		hints_remaining = v
		queue_redraw()

var hints_total: int = 0:
	set(v):
		hints_total = v
		queue_redraw()

var _message: String = ""
var _message_alpha: float = 0.0


func _ready() -> void:
	_texture = preload("res://assets/img/icon_hint.svg")


func _draw() -> void:
	if _texture:
		var size := Vector2(ICON_SIZE, ICON_SIZE)
		var col := Color(1, 1, 1, 0.3) if state == &"disabled" else Color.WHITE
		draw_texture_rect(_texture, Rect2(-size * 0.5, size), false, col)

	# Show remaining counter in "available" and "disabled" states
	if state != &"consumed":
		var font := GameTheme.FONT_BOLD
		var fs := 28
		var text := "%d/%d" % [hints_remaining, hints_total]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var text_col := GameTheme.ACTIVE["text"]
		text_col.a = 0.5
		draw_string(font, Vector2(-tw * 0.5, ICON_SIZE * 0.5 + 24), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Temporary message below counter
	if _message_alpha > 0.0 and not _message.is_empty():
		var font := GameTheme.FONT_BOLD
		var fs := 22
		var msg_col := GameTheme.ACTIVE["text"]
		msg_col.a = _message_alpha * 0.6
		var tw := font.get_string_size(_message, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(-tw * 0.5, ICON_SIZE * 0.5 + 50), _message,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, msg_col)


func show_message(text: String) -> void:
	_message = text
	_message_alpha = 1.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_message_alpha = v
		queue_redraw()
	, 1.0, 0.0, 2.0).set_delay(1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


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
