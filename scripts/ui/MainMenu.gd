class_name MainMenu
extends Node2D

signal play_pressed
signal challenge_pressed
signal select_level_pressed
signal settings_pressed
signal about_pressed
signal support_pressed

var _font_bold: Font  = GameTheme.FONT_BOLD

var _play_rect:         Rect2
var _challenge_rect:      Rect2
var _select_rect:       Rect2
var _settings_rect:     Rect2
var _about_rect:        Rect2
var _support_rect:      Rect2
var _play_scale:         float = 1.0
var _challenge_scale:      float = 1.0
var _select_scale:       float = 1.0
var _settings_scale:     float = 1.0
var _about_scale:        float = 1.0

# Title animation
const TITLE_LETTERS := "DAXTLE"
const _CHAIN_DELAY  := 0.10
const _CHAIN_TOTAL  := 0.72
const _CHAIN_SCALE  := 0.66
const _SLIDE_DUR    := 0.45
const _UI_FADE_DUR  := 0.30
var _letter_scales: Array[float] = []
var _slide_progress: Array[float] = []  # per-letter: 0 = center of screen, 1 = final top position
var _ui_alpha:       float = 0.0   # 0 = hidden, 1 = visible
var _btn_intro_scales: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]  # play, select, settings, about
const _BTN_CHAIN_STAGGER := 0.12
const _BTN_CHAIN_DUR     := 0.35

var _settings_tex: Texture2D
var _levels_tex:   Texture2D
var _about_tex:    Texture2D
var _challenge_tex:  Texture2D
var _play_tex:       Texture2D
var _safe_top: float
var _support_alpha: float = 0.0

func _ready() -> void:
	_settings_tex = preload("res://assets/img/icon_settings.svg")
	_levels_tex   = preload("res://assets/img/icon_levels.svg")
	_about_tex    = preload("res://assets/img/icon_about.svg")
	_challenge_tex  = preload("res://assets/img/icon_challenge.svg")
	_play_tex       = preload("res://assets/img/icon_play.svg")
	_safe_top = GameTheme.get_safe_area_top()

	_letter_scales.resize(TITLE_LETTERS.length())
	_slide_progress.resize(TITLE_LETTERS.length())
	_letter_scales.fill(0.0)
	_play_title_intro()


func _play_title_intro() -> void:
	_slide_progress.fill(0.0)
	_ui_alpha = 0.0
	var n       := TITLE_LETTERS.length()
	var stagger := _CHAIN_TOTAL / maxi(n - 1, 1)

	# Phase 1: chain scale at screen center
	for i in n:
		var delay := _CHAIN_DELAY + i * stagger
		var t := create_tween()
		var idx := i
		t.tween_method(func(v: float) -> void:
			_letter_scales[idx] = v
			queue_redraw()
		, 0.0, 1.0, _CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Phase 2: slide from center to top — staggered per letter for snake effect
	var slide_delay := _CHAIN_DELAY + _CHAIN_TOTAL + _CHAIN_SCALE + 0.25
	var slide_stagger := 0.06
	for i in n:
		var delay := slide_delay + i * slide_stagger
		var idx := i
		var st := create_tween()
		st.tween_method(func(v: float) -> void:
			_slide_progress[idx] = v
			queue_redraw()
		, 0.0, 1.0, _SLIDE_DUR) \
			.set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Phase 3: chain-scale buttons after slide (play first, then secondary L→R)
	var btn_delay := slide_delay + (n - 1) * slide_stagger + _SLIDE_DUR * 0.6
	_ui_alpha = 1.0
	_btn_intro_scales = [0.0, 0.0, 0.0, 0.0, 0.0]
	_support_alpha = 0.0
	for i in 5:
		var delay := btn_delay + i * _BTN_CHAIN_STAGGER
		var idx := i
		var bt := create_tween()
		bt.tween_method(func(v: float) -> void:
			_btn_intro_scales[idx] = v
			queue_redraw()
		, 0.0, 1.0, _BTN_CHAIN_DUR) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Phase 4: fade in supporter panel after all buttons are done
	var support_delay := btn_delay + 4 * _BTN_CHAIN_STAGGER + _BTN_CHAIN_DUR
	var st := create_tween()
	st.tween_method(func(v: float) -> void:
		_support_alpha = v
		queue_redraw()
	, 0.0, 1.0, 0.4) \
		.set_delay(support_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func replay_intro() -> void:
	# Kill any paused tweens from initial intro
	for tw in get_tree().get_processed_tweens():
		if tw.is_valid():
			tw.kill()
	# Set everything to final visible state
	_letter_scales.fill(1.0)
	_slide_progress.fill(1.0)
	_ui_alpha = 1.0
	_btn_intro_scales = [1.0, 1.0, 1.0, 1.0, 1.0]
	_support_alpha = 1.0
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport().get_visible_rect().size
	# Title blocks (always drawn, position animated)
	_draw_title_blocks(vp)

	# UI elements — only drawn when visible
	if _ui_alpha <= 0.0:
		return

	# Icon button sizing
	var btn_size := vp.x * 0.18          # square side length
	var btn_gap  := btn_size * 0.35      # gap between primary buttons
	var btn_cy   := vp.y * 0.54         # vertical centre for primary buttons
	var sec_cy   := vp.y * 0.78         # vertical centre for secondary buttons

	# Primary buttons row: Challenge (left) + Play (right), both green
	var primary_gap := btn_size * 0.45
	var primary_cx  := vp.x * 0.5
	_play_rect = _draw_icon_button(
		primary_cx - btn_size * 0.5 - primary_gap * 0.5, btn_cy, btn_size,
		_play_scale * _btn_intro_scales[0], "play")
	_challenge_rect = _draw_icon_button(
		primary_cx + btn_size * 0.5 + primary_gap * 0.5, btn_cy, btn_size,
		_challenge_scale * _btn_intro_scales[1], "challenge")

	# Secondary buttons row (3 buttons)
	var sec_size := btn_size * 0.72
	var sec_gap  := sec_size * 0.5
	var sec_total := sec_size * 3 + sec_gap * 2
	var sec_x0   := (vp.x - sec_total) * 0.5 + sec_size * 0.5

	# Level Select button
	_select_rect = _draw_icon_button(
		sec_x0, sec_cy, sec_size,
		_select_scale * _btn_intro_scales[2], "levels")

	# Settings button
	_settings_rect = _draw_icon_button(
		sec_x0 + sec_size + sec_gap, sec_cy, sec_size,
		_settings_scale * _btn_intro_scales[3], "settings")

	# About button
	_about_rect = _draw_icon_button(
		sec_x0 + (sec_size + sec_gap) * 2, sec_cy, sec_size,
		_about_scale * _btn_intro_scales[4], "about")

	# Bottom status: supporter or "Support Daxtle"
	_support_rect = Rect2()
	if _support_alpha <= 0.0:
		return

	var safe_bot := GameTheme.get_safe_area_bottom()
	var bottom_y := vp.y - maxf(safe_bot, 40.0) - 20.0
	var font := _font_bold
	var text_col := GameTheme.ACTIVE["text"]

	SaveData.check_and_reset_daily_hints()
	if SaveData.get_supporter_purchased():
		# Line 1: Supporter
		var label := "Supporter"
		var fs1 := 36
		var tw1 := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs1).x
		var col1 := text_col
		col1.a = _support_alpha * 0.6
		draw_string(font, Vector2((vp.x - tw1) * 0.5, bottom_y - 28), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs1, col1)
		# Line 2: hints remaining
		var hints_text := "%d/%d hints today" % [SaveData.get_hints_remaining(), SaveData.get_daily_hint_limit()]
		var fs2 := 30
		var tw2 := font.get_string_size(hints_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		var col2 := text_col
		col2.a = _support_alpha * 0.4
		draw_string(font, Vector2((vp.x - tw2) * 0.5, bottom_y), hints_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, col2)
	else:
		var label := "Support Daxtle"
		var fs := 34
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := text_col
		col.a = _support_alpha * 0.5
		var asc := font.get_ascent(fs)
		var text_pos := Vector2((vp.x - tw) * 0.5, bottom_y)
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		_support_rect = Rect2(text_pos.x - 10, text_pos.y - asc - 10, tw + 20, asc + 20)


func _draw_title_blocks(vp: Vector2) -> void:
	var palette: Array = GameTheme.ACTIVE["blocks"]
	var count   := TITLE_LETTERS.length()
	var usable_w := vp.x * (1.0 - 2.0 * Board.MARGIN)
	var sq_size  := usable_w / (count + GameTheme.GAP_FRACTION * (count - 1))
	var gap      := sq_size * GameTheme.GAP_FRACTION
	var total_w  := sq_size * count + gap * (count - 1)
	var start_x  := (vp.x - total_w) * 0.5

	var final_y  := maxf(vp.y * 0.24, _safe_top + 60.0)

	for i in count:
		var s: float = _letter_scales[i] if i < _letter_scales.size() else 1.0
		if s <= 0.0:
			continue

		var sp: float = _slide_progress[i] if i < _slide_progress.size() else 1.0
		var current_y := lerpf(vp.y * 0.5, final_y, sp)

		var col: Color = palette[0]
		var letter_col: Color = GameTheme.ACTIVE["background"]
		var final_x := start_x + i * (sq_size + gap) + sq_size * 0.5
		var cell_center := Vector2(final_x, current_y)

		var sq_draw := sq_size * (1.0 - GameTheme.GAP_FRACTION) * s
		var radius  := sq_size * GameTheme.CORNER_FRACTION * s

		var rect := Rect2(cell_center - Vector2(sq_draw, sq_draw) * 0.5, Vector2(sq_draw, sq_draw))

		var style := StyleBoxFlat.new()
		style.bg_color = col
		style.set_corner_radius_all(int(radius))
		style.draw(get_canvas_item(), rect)

		var font_sz := int(sq_size * (1.0 - GameTheme.GAP_FRACTION) * 0.52 * s)
		if font_sz < 1:
			continue
		var ch  := TITLE_LETTERS[i]
		var tw  := _font_bold.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz).x
		var asc := _font_bold.get_ascent(font_sz)
		draw_string(_font_bold,
			Vector2(cell_center.x - tw * 0.5, cell_center.y + asc * 0.5 - 2.0),
			ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, letter_col)


## Draws a square icon button and returns its Rect2.
func _draw_icon_button(cx: float, cy: float, size: float, btn_scale: float, icon: String) -> Rect2:
	var s   := size * btn_scale
	var rect := Rect2(Vector2(cx - s * 0.5, cy - s * 0.5), Vector2(s, s))
	var radius := s * GameTheme.CORNER_FRACTION * 1.5
	var alpha  := _ui_alpha

	var green_col := GameTheme.ACTIVE["blocks"][0]  # B1 teal
	var grey_col  := GameTheme.ACTIVE["surface"]

	# Background
	var is_primary := icon == "play" or icon == "challenge"
	var style := StyleBoxFlat.new()
	var bg: Color = green_col if is_primary else grey_col
	bg.a = alpha
	style.bg_color = bg
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), rect)

	# Icon colour
	var icon_col: Color = GameTheme.ACTIVE["background"] if is_primary else green_col
	icon_col.a = alpha

	# Draw the icon
	match icon:
		"play":
			_draw_play_icon(cx, cy, s, icon_col)
		"levels":
			_draw_grid_icon(cx, cy, s, icon_col)
		"settings":
			_draw_gear_icon(cx, cy, s, icon_col)
		"about":
			_draw_about_icon(cx, cy, s, icon_col)
		"challenge":
			_draw_challenge_icon(cx, cy, s, icon_col)

	return rect


## Play icon — SVG texture.
func _draw_play_icon(cx: float, cy: float, size: float, _col: Color) -> void:
	if not _play_tex:
		return
	var icon_size := size * 0.55
	var rect := Rect2(Vector2(cx - icon_size * 0.5, cy - icon_size * 0.5), Vector2(icon_size, icon_size))
	draw_texture_rect(_play_tex, rect, false, Color(1, 1, 1, _ui_alpha))


## Level-select icon — SVG texture.
func _draw_grid_icon(cx: float, cy: float, size: float, _col: Color) -> void:
	if not _levels_tex:
		return
	var icon_size := size * 0.55
	var rect := Rect2(Vector2(cx - icon_size * 0.5, cy - icon_size * 0.5), Vector2(icon_size, icon_size))
	draw_texture_rect(_levels_tex, rect, false, Color(1, 1, 1, _ui_alpha))


## Settings icon — SVG texture drawn at the icon's position.
func _draw_gear_icon(cx: float, cy: float, size: float, _col: Color) -> void:
	if not _settings_tex:
		return
	var icon_size := size * 0.55
	var rect := Rect2(Vector2(cx - icon_size * 0.5, cy - icon_size * 0.5), Vector2(icon_size, icon_size))
	draw_texture_rect(_settings_tex, rect, false, Color(1, 1, 1, _ui_alpha))


## About icon — SVG texture.
func _draw_about_icon(cx: float, cy: float, size: float, _col: Color) -> void:
	if not _about_tex:
		return
	var icon_size := size * 0.55
	var rect := Rect2(Vector2(cx - icon_size * 0.5, cy - icon_size * 0.5), Vector2(icon_size, icon_size))
	draw_texture_rect(_about_tex, rect, false, Color(1, 1, 1, _ui_alpha))


## Challenge icon — SVG texture.
func _draw_challenge_icon(cx: float, cy: float, size: float, _col: Color) -> void:
	if not _challenge_tex:
		return
	var icon_size := size * 0.55
	var rect := Rect2(Vector2(cx - icon_size * 0.5, cy - icon_size * 0.5), Vector2(icon_size, icon_size))
	draw_texture_rect(_challenge_tex, rect, false, Color(1, 1, 1, _ui_alpha))


func _unhandled_input(event: InputEvent) -> void:
	if _btn_intro_scales[0] < 0.9 or not is_visible_in_tree():
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

	if _play_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("play")
	elif _select_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("select")
	elif _settings_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("settings")
	elif _challenge_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("challenge")
	elif _about_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		_pulse_button("about")
	elif _support_rect.size != Vector2.ZERO and _support_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		support_pressed.emit()


func _pulse_button(which: String) -> void:
	AudioManager.play_sfx("click")
	Haptics.tap()
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		match which:
			"play":     _play_scale = v
			"challenge":  _challenge_scale = v
			"select":   _select_scale = v
			"settings": _settings_scale = v
			"about":    _about_scale = v
		queue_redraw()
	, 1.0, 1.12, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void:
		match which:
			"play":     _play_scale = v
			"challenge":  _challenge_scale = v
			"select":   _select_scale = v
			"settings": _settings_scale = v
			"about":    _about_scale = v
		queue_redraw()
	, 1.12, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		_play_scale = 1.0
		_challenge_scale = 1.0
		_select_scale = 1.0
		_settings_scale = 1.0
		_about_scale = 1.0
		queue_redraw()
		match which:
			"play":     play_pressed.emit()
			"challenge":  challenge_pressed.emit()
			"select":   select_level_pressed.emit()
			"settings": settings_pressed.emit()
			"about":    about_pressed.emit()
	)
