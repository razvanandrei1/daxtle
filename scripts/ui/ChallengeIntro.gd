class_name ChallengeIntro
extends Node2D

signal start_pressed
signal back_pressed

var _font: Font = GameTheme.FONT_BOLD
var _safe_top: float
var _ok_rect: Rect2
var _ok_scale: float = 1.0

@onready var _header: SceneHeader = $SceneHeader


func _ready() -> void:
	_safe_top = GameTheme.get_safe_area_top()
	_header.back_pressed.connect(func() -> void: back_pressed.emit())


func _draw() -> void:
	var vp := get_viewport().get_visible_rect().size
	var text_col := GameTheme.ACTIVE["text"]
	var green_col := GameTheme.ACTIVE["blocks"][0]

	# Body text
	var body_fs := 40
	var body_col := text_col
	body_col.a = 0.7
	var margin := vp.x * Board.MARGIN
	var line_h := _font.get_height(body_fs) * 1.4
	var start_y := vp.y * 0.30

	var best := SaveData.get_best_streak()
	var timer_start := int(ChallengeMode.TIME_START)
	var timer_decay := ChallengeMode.TIME_DECAY
	var lines := [
		"Solve as many puzzles",
		"as you can in a row.",
		"",
		"Puzzles get harder",
		"as your streak grows.",
		"",
		"You start with %ds." % timer_start,
		"Each solve removes %.1fs." % timer_decay,
		"",
		"No resets. No undo.",
		"One mistake and it's over.",
		"",
		"Your best: %d" % best,
	]

	for i in lines.size():
		var line: String = lines[i]
		if line.is_empty():
			continue
		var max_w := vp.x - margin * 2.0
		var lw := minf(_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, body_fs).x, max_w)
		var lx := maxf((vp.x - lw) * 0.5, margin)
		draw_string(_font, Vector2(lx, start_y + i * line_h),
			line, HORIZONTAL_ALIGNMENT_LEFT, -1, body_fs, body_col)

	# OK button
	var btn_fs := 44
	var btn_text := "Start"
	var btn_tw := _font.get_string_size(btn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, btn_fs).x
	var btn_asc := _font.get_ascent(btn_fs)
	var btn_h := btn_asc + _font.get_descent(btn_fs)
	var pad_x := 80.0
	var pad_y := 24.0

	var btn_cy := vp.y * 0.78
	var rect_w := (btn_tw + pad_x * 2.0) * _ok_scale
	var rect_h := (btn_h + pad_y * 2.0) * _ok_scale
	_ok_rect = Rect2(Vector2((vp.x - rect_w) * 0.5, btn_cy - rect_h * 0.5), Vector2(rect_w, rect_h))
	var radius := rect_h * 0.22

	var style := StyleBoxFlat.new()
	style.bg_color = green_col
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), _ok_rect)

	var label_fs := int(btn_fs * _ok_scale)
	var label_tw := _font.get_string_size(btn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs).x
	var label_asc := _font.get_ascent(label_fs)
	var label_col := GameTheme.ACTIVE["background"]
	draw_string(_font,
		Vector2((vp.x - label_tw) * 0.5, btn_cy + label_asc * 0.5 - 2.0 * _ok_scale),
		btn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, label_col)


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

	if _ok_rect.has_point(pos):
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx("click")
		Haptics.tap()
		var tween := create_tween()
		tween.tween_method(func(v: float) -> void:
			_ok_scale = v
			queue_redraw()
		, 1.0, 1.12, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_method(func(v: float) -> void:
			_ok_scale = v
			queue_redraw()
		, 1.12, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(func() -> void:
			_ok_scale = 1.0
			queue_redraw()
			start_pressed.emit()
		)
