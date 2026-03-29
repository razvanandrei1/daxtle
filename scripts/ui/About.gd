class_name About
extends Node2D

signal back_pressed

var _font: Font = GameTheme.FONT_BOLD
var _safe_top: float

@onready var _header: SceneHeader = $SceneHeader


func _ready() -> void:
	_safe_top = GameTheme.get_safe_area_top()
	_header.back_pressed.connect(func() -> void: back_pressed.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
			or (event is InputEventMouseButton \
				and (event as InputEventMouseButton).pressed \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx("click")
		Haptics.tap()
		back_pressed.emit()


func _draw() -> void:
	var vp := get_viewport().get_visible_rect().size
	var text_col := GameTheme.ACTIVE["text"]

	# Body text
	var body_fs := 43
	var body_col := text_col
	body_col.a = 0.7
	var margin   := vp.x * Board.MARGIN
	var max_w    := vp.x - margin * 2.0
	var line_h   := _font.get_height(body_fs) * 1.4
	var start_y  := vp.y * 0.32

	var lines := [
		"DAXTLE is a minimalist puzzle game",
		"where you slide colored blocks onto",
		"their matching targets.",
		"",
		"Swipe to move all blocks at once.",
		"Think ahead — every move counts.",
		"",
		"Designed & developed by",
		"Razvan Andrei",
	]

	for i in lines.size():
		var line: String = lines[i]
		if line.is_empty():
			continue
		var lw := _font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, body_fs).x
		var lx := (vp.x - lw) * 0.5
		draw_string(_font, Vector2(lx, start_y + i * line_h),
			line, HORIZONTAL_ALIGNMENT_LEFT, -1, body_fs, body_col)

	# Supporter thank you
	if SaveData.get_supporter_purchased():
		var ty := start_y + lines.size() * line_h + line_h
		var thank_col := GameTheme.ACTIVE["blocks"][0]
		thank_col.a = 0.8
		var msg := "Thank you for your support!"
		var tw := _font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, body_fs).x
		draw_string(_font, Vector2((vp.x - tw) * 0.5, ty),
			msg, HORIZONTAL_ALIGNMENT_LEFT, -1, body_fs, thank_col)
