class_name LevelSelect
extends Node2D

signal level_selected(n: int)
signal menu_pressed

const COLS              := 4
const ROWS              := 5
const LEVELS_PER_PAGE   := COLS * ROWS   # 20 — full grid per page
const FRAME_PADDING     := 32.0
const CELL_GAP          := 28.0
const PAGE_GAP          := 40.0
const FRAME_MARGIN      := 48.0
const TOP_OFFSET        := 200.0
const BOT_RESERVE       := 120.0  # space for page dots + bottom padding
const SNAP_THRESHOLD    := 0.25   # drag fraction of frame width to snap next
const TAP_THRESHOLD     := 12.0   # max drag px to count as a tap

var _cell_size:     float
var _frame_size:    Vector2
var _frame_stride:  float
var _grid_origin:   Vector2   # grid origin inside frame (relative)
var _frame_y:       float     # y position of frames
var _safe_top:      float     # notch / status bar inset
var _total_levels:  int
var _total_pages:   int
var _current_page:  int = 0
var _scroll_x:      float = 0.0
var _font:          Font = GameTheme.FONT_BOLD

# Touch state
var _touch_active:  bool = false
var _touch_start:   Vector2
var _scroll_start:  float
var _is_dragging:   bool = false

# Pulse feedback
var _pulse_level:   int = -1       # level number being pulsed, -1 = none
var _pulse_scale:   float = 1.0    # animated scale of the pulsed cell


func _ready() -> void:
	_total_levels = LevelLoader.count_levels()
	_total_pages  = maxi(ceili(float(_total_levels) / LEVELS_PER_PAGE), 1)
	_safe_top     = GameTheme.get_safe_area_top()
	_compute_layout()


func _compute_layout() -> void:
	var vp := get_viewport().get_visible_rect().size

	var frame_w  := vp.x - FRAME_MARGIN * 2.0
	var inner_w  := frame_w - FRAME_PADDING * 2.0
	var cell_w   := (inner_w - CELL_GAP * (COLS - 1)) / COLS

	var avail_h  := vp.y - (TOP_OFFSET + _safe_top) - BOT_RESERVE
	var inner_h  := avail_h - FRAME_PADDING * 2.0
	var cell_h   := (inner_h - CELL_GAP * (ROWS - 1)) / ROWS

	_cell_size   = minf(cell_w, cell_h)

	var grid_w   := _cell_size * COLS + CELL_GAP * (COLS - 1)
	var grid_h   := _cell_size * ROWS + CELL_GAP * (ROWS - 1)

	_frame_size  = Vector2(frame_w, grid_h + FRAME_PADDING * 2.0)
	_grid_origin = Vector2((frame_w - grid_w) * 0.5, FRAME_PADDING)
	_frame_stride = frame_w + PAGE_GAP
	_frame_y     = TOP_OFFSET + _safe_top + (avail_h - _frame_size.y) * 0.5

	_scroll_x = -_current_page * _frame_stride


func _draw() -> void:
	var vp     := get_viewport().get_visible_rect().size
	var radius := _cell_size * GameTheme.CORNER_FRACTION
	# Title — centered, matching game scene level number style
	var title_fs := 62
	var title_text := "Level select"
	var title_w  := _font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs).x
	var title_asc := _font.get_ascent(title_fs)
	var title_y  := _safe_top + 32.0 + 62.0 * 0.5 + title_asc * 0.5
	draw_string(_font, Vector2((vp.x - title_w) * 0.5, title_y),
		title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs,
		GameTheme.ACTIVE["text"])

	# Frames (no background)
	for page in _total_pages:
		var fx := FRAME_MARGIN + page * _frame_stride + _scroll_x
		if fx + _frame_size.x < -50.0 or fx > vp.x + 50.0:
			continue

		# Level cells
		for row in ROWS:
			for col in COLS:
				var idx     := row * COLS + col
				var level_n := page * LEVELS_PER_PAGE + idx + 1
				var cx := fx + _grid_origin.x + col * (_cell_size + CELL_GAP)
				var cy := _frame_y + _grid_origin.y + row * (_cell_size + CELL_GAP)
				var rect := Rect2(Vector2(cx, cy), Vector2(_cell_size, _cell_size))

				if level_n > _total_levels:
					var dim := GameTheme.ACTIVE["surface"]
					dim.a   = 0.35
					_draw_rounded_rect(rect, dim, radius)
				else:
					# Apply pulse scale if this cell is being pulsed
					var draw_rect := rect
					if level_n == _pulse_level and _pulse_scale != 1.0:
						var center := rect.get_center()
						var sz     := rect.size * _pulse_scale
						draw_rect  = Rect2(center - sz * 0.5, sz)

					_draw_rounded_rect(draw_rect, GameTheme.ACTIVE["surface"], radius)
					var num     := "%d" % level_n
					var fs      := int(_cell_size * 0.38 * (1.0 if level_n != _pulse_level else _pulse_scale))
					var tw      := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					var ascent  := _font.get_ascent(fs)
					draw_string(_font, Vector2(
						draw_rect.position.x + (draw_rect.size.x - tw) * 0.5,
						draw_rect.position.y + (draw_rect.size.y + ascent) * 0.5),
						num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GameTheme.ACTIVE["text"])

	# Page dots — positioned above the bottom
	var dot_y   := vp.y - 80.0
	var dot_r   := 8.0
	var dot_gap := 28.0
	var dots_w  := _total_pages * dot_r * 2.0 + (_total_pages - 1) * dot_gap
	var dot_x0  := (vp.x - dots_w) * 0.5 + dot_r

	for i in _total_pages:
		var col := GameTheme.ACTIVE["text"]
		col.a    = 1.0 if i == _current_page else 0.3
		draw_circle(Vector2(dot_x0 + i * (dot_r * 2.0 + dot_gap), dot_y), dot_r, col)


# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Touch start / end
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_begin_touch(t.position)
		elif _touch_active:
			_end_touch(t.position)
		return

	# Touch drag
	if event is InputEventScreenDrag and _touch_active:
		_update_drag((event as InputEventScreenDrag).position)
		return

	# Mouse fallback
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_touch(mb.position)
			elif _touch_active:
				_end_touch(mb.position)
		return

	if event is InputEventMouseMotion and _touch_active:
		_update_drag((event as InputEventMouseMotion).position)


func _begin_touch(pos: Vector2) -> void:
	_touch_active = true
	_touch_start  = pos
	_scroll_start = _scroll_x
	_is_dragging  = false


func _update_drag(pos: Vector2) -> void:
	var dx := pos.x - _touch_start.x
	if absf(dx) > TAP_THRESHOLD:
		_is_dragging = true
	_scroll_x = _scroll_start + dx
	queue_redraw()


func _end_touch(pos: Vector2) -> void:
	_touch_active = false
	if _is_dragging:
		_snap_to_page()
	else:
		_handle_tap(pos)


func _snap_to_page() -> void:
	var drag_dx     := _scroll_x - _scroll_start
	var target_page := _current_page

	if absf(drag_dx) > _frame_size.x * SNAP_THRESHOLD:
		if drag_dx > 0:
			target_page = maxi(_current_page - 1, 0)
		else:
			target_page = mini(_current_page + 1, _total_pages - 1)

	_current_page = target_page
	var target_x  := -_current_page * _frame_stride

	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_scroll_x = v
		queue_redraw()
	, _scroll_x, target_x, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _handle_tap(pos: Vector2) -> void:
	var fx := FRAME_MARGIN + _current_page * _frame_stride + _scroll_x

	for row in ROWS:
		for col in COLS:
			var idx     := row * COLS + col
			var level_n := _current_page * LEVELS_PER_PAGE + idx + 1
			if level_n > _total_levels:
				continue
			var cx := fx + _grid_origin.x + col * (_cell_size + CELL_GAP)
			var cy := _frame_y + _grid_origin.y + row * (_cell_size + CELL_GAP)
			if Rect2(Vector2(cx, cy), Vector2(_cell_size, _cell_size)).has_point(pos):
				_play_pulse(level_n)
				get_viewport().set_input_as_handled()
				return


func _play_pulse(level_n: int) -> void:
	_pulse_level = level_n
	_pulse_scale = 1.0
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_pulse_scale = v
		queue_redraw()
	, 1.0, 1.12, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void:
		_pulse_scale = v
		queue_redraw()
	, 1.12, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		_pulse_level = -1
		_pulse_scale = 1.0
		queue_redraw()
		level_selected.emit(level_n)
	)


func _draw_rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), rect)
