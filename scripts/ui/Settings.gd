class_name Settings
extends Node2D

signal back_pressed
signal restore_purchases_pressed

var _font: Font = GameTheme.FONT_BOLD
var _safe_top: float

var _music_rect:   Rect2
var _sfx_rect:     Rect2
var _haptics_rect: Rect2
var _restore_rect: Rect2
var _reset_hints_rect: Rect2
var _supporter_rect: Rect2
var _music_scale:   float = 1.0
var _sfx_scale:     float = 1.0
var _haptics_scale: float = 1.0
var _restore_scale: float = 1.0
var _reset_hints_scale: float = 1.0
var _supporter_scale: float = 1.0
var _animating:     bool  = false

@onready var _header: SceneHeader = $SceneHeader


func _ready() -> void:
	_safe_top = GameTheme.get_safe_area_top()
	_header.back_pressed.connect(func() -> void: back_pressed.emit())


func _draw() -> void:
	var vp := get_viewport().get_visible_rect().size
	var text_col := GameTheme.ACTIVE["text"]

	# Toggle rows
	var margin  := vp.x * Board.MARGIN
	var row_w   := vp.x - margin * 2.0
	var row_h   := 86.0
	var row_x   := margin
	var start_y := vp.y * 0.36
	var row_gap := 40.0
	var radius  := row_h * 0.22

	_music_rect = _draw_toggle_row("Music", AudioManager.is_music_enabled(),
		row_x, start_y, row_w, row_h, radius, _music_scale)
	_sfx_rect = _draw_toggle_row("Sound Effects", AudioManager.is_sfx_enabled(),
		row_x, start_y + row_h + row_gap, row_w, row_h, radius, _sfx_scale)

	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		_haptics_rect = _draw_toggle_row("Haptics", Haptics.is_enabled(),
			row_x, start_y + (row_h + row_gap) * 2, row_w, row_h, radius, _haptics_scale)
	else:
		_haptics_rect = Rect2()

	# Restore purchases row
	var restore_row := 3 if _haptics_rect.size != Vector2.ZERO else 2
	_restore_rect = _draw_action_row("Restore purchases",
		row_x, start_y + (row_h + row_gap) * restore_row, row_w, row_h, radius, _restore_scale)

	# Supporter mode toggle (test)
	_supporter_rect = _draw_toggle_row("Supporter mode (test)", SaveData.get_supporter_purchased(),
		row_x, start_y + (row_h + row_gap) * (restore_row + 1), row_w, row_h, radius, _supporter_scale)

	# Reset daily hints (test)
	_reset_hints_rect = _draw_action_row("Reset daily hints (test)",
		row_x, start_y + (row_h + row_gap) * (restore_row + 2), row_w, row_h, radius, _reset_hints_scale)


func _draw_toggle_row(label: String, enabled: bool, x: float, y: float,
		w: float, h: float, radius: float, btn_scale: float) -> Rect2:
	var text_col := GameTheme.ACTIVE["text"]
	var on_col:  Color = GameTheme.ACTIVE["blocks"][0]
	var off_col: Color = GameTheme.ACTIVE["text"]
	off_col.a = 0.3

	# Row background
	var rect := Rect2(Vector2(x, y), Vector2(w, h))
	var center := rect.get_center()
	var scaled_sz := rect.size * btn_scale
	var scaled_rect := Rect2(center - scaled_sz * 0.5, scaled_sz)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = text_col
	style.border_color.a = 0.3
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(radius * btn_scale))
	style.draw(get_canvas_item(), scaled_rect)

	# Label (left side)
	var fs  := int(38 * btn_scale)
	var asc := _font.get_ascent(fs)
	var label_x := scaled_rect.position.x + 28.0 * btn_scale
	var label_y := scaled_rect.position.y + (scaled_rect.size.y + asc) * 0.5 - 2.0
	draw_string(_font, Vector2(label_x, label_y),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Toggle indicator (right side) — filled circle for on, outlined for off
	var dot_r   := 16.0 * btn_scale
	var dot_x   := scaled_rect.position.x + scaled_rect.size.x - 28.0 * btn_scale - dot_r
	var dot_y   := scaled_rect.position.y + scaled_rect.size.y * 0.5
	var dot_pos := Vector2(dot_x, dot_y)

	if enabled:
		draw_circle(dot_pos, dot_r, on_col)
	else:
		draw_circle(dot_pos, dot_r, off_col)
		draw_circle(dot_pos, dot_r - 3.0, GameTheme.ACTIVE["background"])

	return rect


func _draw_action_row(label: String, x: float, y: float,
		w: float, h: float, radius: float, btn_scale: float) -> Rect2:
	var text_col := GameTheme.ACTIVE["text"]

	var rect := Rect2(Vector2(x, y), Vector2(w, h))
	var center := rect.get_center()
	var scaled_sz := rect.size * btn_scale
	var scaled_rect := Rect2(center - scaled_sz * 0.5, scaled_sz)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = text_col
	style.border_color.a = 0.3
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(radius * btn_scale))
	style.draw(get_canvas_item(), scaled_rect)

	# Centered label
	var fs  := int(38 * btn_scale)
	var asc := _font.get_ascent(fs)
	var tw  := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var label_x := scaled_rect.position.x + (scaled_rect.size.x - tw) * 0.5
	var label_y := scaled_rect.position.y + (scaled_rect.size.y + asc) * 0.5 - 2.0
	draw_string(_font, Vector2(label_x, label_y),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	return rect


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

	if _music_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_toggle("music")
	elif _sfx_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_toggle("sfx")
	elif _haptics_rect.size != Vector2.ZERO and _haptics_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_toggle("haptics")
	elif _restore_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_toggle("restore")
	elif _supporter_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_toggle("supporter")
	elif _reset_hints_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_toggle("reset_hints")


func _pulse_toggle(which: String) -> void:
	if _animating:
		return
	_animating = true
	AudioManager.play_sfx("click")
	Haptics.tap()
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		match which:
			"music":   _music_scale = v
			"sfx":     _sfx_scale = v
			"haptics": _haptics_scale = v
			"restore": _restore_scale = v
			"reset_hints": _reset_hints_scale = v
			"supporter": _supporter_scale = v
		queue_redraw()
	, 1.0, 1.06, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void:
		match which:
			"music":   _music_scale = v
			"sfx":     _sfx_scale = v
			"haptics": _haptics_scale = v
			"restore": _restore_scale = v
			"reset_hints": _reset_hints_scale = v
			"supporter": _supporter_scale = v
		queue_redraw()
	, 1.06, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		_music_scale = 1.0
		_sfx_scale = 1.0
		_haptics_scale = 1.0
		_restore_scale = 1.0
		_reset_hints_scale = 1.0
		_supporter_scale = 1.0
		_animating = false
		match which:
			"music":   AudioManager.set_music_enabled(not AudioManager.is_music_enabled())
			"sfx":     AudioManager.set_sfx_enabled(not AudioManager.is_sfx_enabled())
			"haptics": Haptics.set_enabled(not Haptics.is_enabled())
			"restore": restore_purchases_pressed.emit()
			"supporter":
				SaveData.set_supporter_purchased(not SaveData.get_supporter_purchased())
				SaveData.set_hints_remaining(SaveData.get_daily_hint_limit())
			"reset_hints":
				SaveData.set_hints_remaining(SaveData.get_daily_hint_limit())
		queue_redraw()
	)
