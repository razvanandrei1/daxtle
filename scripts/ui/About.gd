class_name About
extends Node2D

signal back_pressed

var _font: Font = GameTheme.FONT_BOLD
var _safe_top: float

@onready var _menu: MenuIcon = $MenuIcon


func _ready() -> void:
	_safe_top = GameTheme.get_safe_area_top()
	var vp       := get_viewport().get_visible_rect().size
	var margin_x := vp.x * Board.MARGIN
	var title_cy := _safe_top + Globals.TOP_OFFSET + Globals.LABEL_HEIGHT * 0.5
	_menu.pressed.connect(func() -> void: back_pressed.emit())
	_menu.position = Vector2(margin_x, title_cy)


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

	# Title
	var title_fs   := 62
	var title_text := "About"
	var title_w    := _font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs).x
	var title_asc  := _font.get_ascent(title_fs)
	var title_y    := _safe_top + Globals.TOP_OFFSET + Globals.LABEL_HEIGHT * 0.5 + title_asc * 0.5
	draw_string(_font, Vector2((vp.x - title_w) * 0.5, title_y),
		title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, text_col)

	# Body text
	var body_fs := 43
	var body_col := text_col
	body_col.a = 0.7
	var margin   := vp.x * 0.12
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
