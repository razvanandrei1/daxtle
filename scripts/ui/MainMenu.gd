class_name MainMenu
extends Node2D

signal play_pressed
signal settings_pressed

var _font:      Font  = GameTheme.FONT_BOLD
var _font_bold: Font  = GameTheme.FONT_BOLD
var _text_col:  Color
var _sub_col:   Color

var _play_rect:     Rect2
var _settings_rect: Rect2
var _play_scale:     float = 1.0
var _settings_scale: float = 1.0

# Title letter scales (animated on show)
const TITLE_LETTERS := "DAXTLE"
const _CHAIN_DELAY  := 0.10
const _CHAIN_TOTAL  := 0.72
const _CHAIN_SCALE  := 0.66
var _letter_scales: Array[float] = []

var _safe_top: float

func _ready() -> void:
	_text_col = GameTheme.ACTIVE["text"]
	_sub_col  = GameTheme.ACTIVE["text"]
	_sub_col.a = 0.5
	_safe_top = GameTheme.get_safe_area_top()

	# Init letter scales to 0 and play intro
	_letter_scales.resize(TITLE_LETTERS.length())
	_letter_scales.fill(0.0)
	_play_title_intro()


func _play_title_intro() -> void:
	var n       := TITLE_LETTERS.length()
	var stagger := _CHAIN_TOTAL / maxi(n - 1, 1)
	for i in n:
		var delay := _CHAIN_DELAY + i * stagger
		var t := create_tween()
		var idx := i  # capture
		t.tween_method(func(v: float) -> void:
			_letter_scales[idx] = v
			queue_redraw()
		, 0.0, 1.0, _CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func replay_intro() -> void:
	_letter_scales.fill(0.0)
	queue_redraw()
	_play_title_intro()


func _draw() -> void:
	var vp := get_viewport().get_visible_rect().size

	# Title — "DAXTLE" in B-component colored squares
	_draw_title_blocks(vp)

	# Play button — slightly below center
	_play_rect = _draw_button("Play", vp.x * 0.5, vp.y * 0.52, _play_scale, true)

	# Settings button — below play
	_settings_rect = _draw_button("Settings", vp.x * 0.5, vp.y * 0.62, _settings_scale, false)

	# Subtitle
	var sub_fs   := 22
	var sub_text := "This is a MVP project"
	var sub_tw   := _font.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs).x
	draw_string(_font, Vector2((vp.x - sub_tw) * 0.5, vp.y * 0.85),
		sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs, _sub_col)


func _draw_title_blocks(vp: Vector2) -> void:
	var palette: Array = GameTheme.ACTIVE["blocks"]
	var count   := TITLE_LETTERS.length()
	# Use the same sizing as the game board: 10% margin, GAP_FRACTION between cells
	var usable_w := vp.x * (1.0 - 2.0 * Board.MARGIN)
	var sq_size  := usable_w / (count + GameTheme.GAP_FRACTION * (count - 1))
	var gap      := sq_size * GameTheme.GAP_FRACTION
	var center_y := maxf(vp.y * 0.28, _safe_top + 80.0)
	var total_w  := sq_size * count + gap * (count - 1)
	var start_x  := (vp.x - total_w) * 0.5

	for i in count:
		var s: float = _letter_scales[i] if i < _letter_scales.size() else 1.0
		if s <= 0.0:
			continue

		var col: Color = palette[i % palette.size()]
		var dark_col := col.darkened(0.30)
		var cell_x := start_x + i * (sq_size + gap)
		var cell_center := Vector2(cell_x + sq_size * 0.5, center_y)

		var sq_draw := sq_size * (1.0 - GameTheme.GAP_FRACTION) * s
		var radius  := sq_size * GameTheme.CORNER_FRACTION * s

		var rect := Rect2(cell_center - Vector2(sq_draw, sq_draw) * 0.5, Vector2(sq_draw, sq_draw))

		# Square
		var style := StyleBoxFlat.new()
		style.bg_color = col
		style.set_corner_radius_all(int(radius))
		style.draw(get_canvas_item(), rect)

		# Letter centered in square
		var font_sz := int(sq_size * (1.0 - GameTheme.GAP_FRACTION) * 0.52 * s)
		if font_sz < 1:
			continue
		var ch  := TITLE_LETTERS[i]
		var tw  := _font_bold.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz).x
		var asc := _font_bold.get_ascent(font_sz)
		draw_string(_font_bold,
			Vector2(cell_center.x - tw * 0.5, cell_center.y + asc * 0.5 - 2.0),
			ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, dark_col)


## Draws a rounded-rect button and returns its Rect2.
## filled=true → solid bg with inverted text; filled=false → outline only.
func _draw_button(text: String, cx: float, cy: float, btn_scale: float, filled: bool) -> Rect2:
	var btn_fs  := 42
	var btn_tw  := _font_bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, btn_fs).x
	var btn_asc := _font_bold.get_ascent(btn_fs)
	var btn_h   := btn_asc + _font_bold.get_descent(btn_fs)
	var pad_x   := 60.0
	var pad_y   := 24.0

	var rect_w := (btn_tw + pad_x * 2.0) * btn_scale
	var rect_h := (btn_h + pad_y * 2.0) * btn_scale
	var rect   := Rect2(Vector2(cx - rect_w * 0.5, cy - rect_h * 0.5), Vector2(rect_w, rect_h))
	var radius := rect_h * 0.22

	if filled:
		var style := StyleBoxFlat.new()
		style.bg_color = _text_col
		style.set_corner_radius_all(int(radius))
		style.draw(get_canvas_item(), rect)
	else:
		# Outline only
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = _text_col
		style.set_border_width_all(3)
		style.set_corner_radius_all(int(radius))
		style.draw(get_canvas_item(), rect)

	var text_fs  := int(btn_fs * btn_scale)
	var text_tw  := _font_bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_fs).x
	var text_asc := _font_bold.get_ascent(text_fs)
	var label_col := GameTheme.ACTIVE["background"] if filled else _text_col
	draw_string(_font_bold,
		Vector2(cx - text_tw * 0.5, cy + text_asc * 0.5 - 2.0 * btn_scale),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_fs, label_col)

	return rect


func _unhandled_input(event: InputEvent) -> void:
	var pos: Vector2
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton \
			and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (event as InputEventMouseButton).position
	else:
		return

	if _play_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("play")
	elif _settings_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("settings")


func _pulse_button(which: String) -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		if which == "play": _play_scale = v
		else: _settings_scale = v
		queue_redraw()
	, 1.0, 1.12, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void:
		if which == "play": _play_scale = v
		else: _settings_scale = v
		queue_redraw()
	, 1.12, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		_play_scale = 1.0
		_settings_scale = 1.0
		queue_redraw()
		if which == "play":
			play_pressed.emit()
		else:
			settings_pressed.emit()
	)
