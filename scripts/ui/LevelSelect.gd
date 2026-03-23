class_name LevelSelect
extends Node2D

signal level_selected(n: int)
signal menu_pressed
signal new_level_requested(grid_size: int)

const COLS              := 4
const ROWS              := 5
const LEVELS_PER_PAGE   := COLS * ROWS   # 20 — full grid per page
const FRAME_PADDING     := 32.0
const CELL_GAP          := 28.0
const PAGE_GAP          := 40.0
const TOP_OFFSET        := 200.0
const BOT_RESERVE       := 120.0  # space for page dots + bottom padding
const SNAP_THRESHOLD    := 0.25   # drag fraction of frame width to snap next
const TAP_THRESHOLD     := 12.0   # max drag px to count as a tap

var _margin:        float
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
var _progress:      int = 1        # highest unlocked level


@onready var _header: SceneHeader = $SceneHeader

var _new_level_layer: CanvasLayer  # overlay for "New Level" button
var _size_popup_layer: CanvasLayer  # overlay for grid size picker

func _ready() -> void:
	_total_levels = LevelLoader.count_levels()
	_total_pages  = maxi(ceili(float(_total_levels) / LEVELS_PER_PAGE), 1)
	_safe_top     = GameTheme.get_safe_area_top()
	_progress     = SaveData.get_progress_level()
	visibility_changed.connect(func() -> void:
		if visible:
			_progress = SaveData.get_progress_level()
			_total_levels = LevelLoader.count_levels()
			_total_pages  = maxi(ceili(float(_total_levels) / LEVELS_PER_PAGE), 1)
			queue_redraw()
	)
	_header.back_pressed.connect(func() -> void: menu_pressed.emit())
	_compute_layout()
	if Globals.LEVEL_EDITOR_MODE:
		_build_new_level_button()
		visibility_changed.connect(func() -> void:
			if _new_level_layer:
				_new_level_layer.visible = visible
		)


func _compute_layout() -> void:
	var vp := get_viewport().get_visible_rect().size

	_margin      = vp.x * Board.MARGIN
	var frame_w  := vp.x - _margin * 2.0
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

	# Frames (no background)
	for page in _total_pages:
		var fx := _margin + page * _frame_stride + _scroll_x
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
				elif not Globals.LEVEL_EDITOR_MODE and level_n > _progress:
					# Locked — dimmed surface with faded number
					var locked_col := GameTheme.ACTIVE["surface"]
					locked_col.a = 0.35
					_draw_rounded_rect(rect, locked_col, radius)
					var num     := "%d" % level_n
					var fs      := int(_cell_size * 0.38)
					var tw      := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					var ascent  := _font.get_ascent(fs)
					var text_col := GameTheme.ACTIVE["text"]
					text_col.a = 0.2
					draw_string(_font, Vector2(
						rect.position.x + (rect.size.x - tw) * 0.5,
						rect.position.y + (rect.size.y + ascent) * 0.5),
						num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
				else:
					# Unlocked or completed
					var draw_rect := rect
					if level_n == _pulse_level and _pulse_scale != 1.0:
						var center := rect.get_center()
						var sz     := rect.size * _pulse_scale
						draw_rect  = Rect2(center - sz * 0.5, sz)

					var is_completed := level_n < _progress
					var bg_col := GameTheme.ACTIVE["blocks"][0] if is_completed else GameTheme.ACTIVE["surface"]
					_draw_rounded_rect(draw_rect, bg_col, radius)
					var num     := "%d" % level_n
					var fs      := int(_cell_size * 0.38 * (1.0 if level_n != _pulse_level else _pulse_scale))
					var tw      := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					var ascent  := _font.get_ascent(fs)
					var text_col := GameTheme.ACTIVE["background"] if is_completed else GameTheme.ACTIVE["text"]
					draw_string(_font, Vector2(
						draw_rect.position.x + (draw_rect.size.x - tw) * 0.5,
						draw_rect.position.y + (draw_rect.size.y + ascent) * 0.5),
						num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Page dots — positioned above the bottom (hide if single page)
	if _total_pages <= 1:
		return
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
	if _total_pages <= 1:
		return
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
	var fx := _margin + _current_page * _frame_stride + _scroll_x

	for row in ROWS:
		for col in COLS:
			var idx     := row * COLS + col
			var level_n := _current_page * LEVELS_PER_PAGE + idx + 1
			if level_n > _total_levels:
				continue
			if not Globals.LEVEL_EDITOR_MODE and level_n > _progress:
				continue
			var cx := fx + _grid_origin.x + col * (_cell_size + CELL_GAP)
			var cy := _frame_y + _grid_origin.y + row * (_cell_size + CELL_GAP)
			if Rect2(Vector2(cx, cy), Vector2(_cell_size, _cell_size)).has_point(pos):
				_play_pulse(level_n)
				get_viewport().set_input_as_handled()
				return


func _play_pulse(level_n: int) -> void:
	AudioManager.play_sfx("click")
	Haptics.tap()
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


# ── New Level button (editor mode only) ─────────────────────────────────────

func _build_new_level_button() -> void:
	_new_level_layer = CanvasLayer.new()
	_new_level_layer.layer = 5
	add_child(_new_level_layer)

	var vp := get_viewport().get_visible_rect().size
	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]
	var safe_bot := GameTheme.get_safe_area_bottom()

	var btn := Button.new()
	btn.text = "+ New Level"
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 36)
	btn.add_theme_color_override("font_color", text_col)
	btn.custom_minimum_size = Vector2(300, 64)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = text_col
	style.border_color.a = 0.4
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)

	btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_top = -maxf(safe_bot, 40.0) - 80.0
	btn.offset_bottom = btn.offset_top + 64.0
	btn.offset_left = -150.0
	btn.offset_right = 150.0

	btn.pressed.connect(_show_size_picker)
	_new_level_layer.add_child(btn)


func _show_size_picker() -> void:
	if _size_popup_layer:
		_size_popup_layer.queue_free()

	_size_popup_layer = CanvasLayer.new()
	_size_popup_layer.layer = 20
	add_child(_size_popup_layer)

	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]
	var bg_col := GameTheme.ACTIVE["background"]

	# Dimmed background
	var container := Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	_size_popup_layer.add_child(container)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_child(dim)

	# Panel
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 450)
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -250; panel.offset_right = 250
	panel.offset_top = -225; panel.offset_bottom = 225

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = bg_col
	panel_style.border_color = text_col
	panel_style.border_color.a = 0.3
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 32
	panel_style.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Board Size"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", text_col)
	vbox.add_child(title)

	# Size buttons in a grid
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vbox.add_child(grid)

	for size in [3, 4, 5, 6, 7, 8]:
		var btn := Button.new()
		btn.text = "%dx%d" % [size, size]
		btn.custom_minimum_size = Vector2(120, 56)
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 36)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = text_col
		btn_style.set_corner_radius_all(12)
		btn_style.content_margin_left = 16
		btn_style.content_margin_right = 16
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_style)
		btn.add_theme_stylebox_override("pressed", btn_style)
		btn.add_theme_stylebox_override("focus", btn_style)
		btn.add_theme_color_override("font_color", bg_col)

		var captured_size: int = size
		btn.pressed.connect(func() -> void:
			_size_popup_layer.queue_free()
			_size_popup_layer = null
			new_level_requested.emit(captured_size)
		)
		grid.add_child(btn)

	# Cancel button
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.add_theme_font_override("font", font)
	cancel.add_theme_font_size_override("font_size", 36)
	cancel.add_theme_color_override("font_color", text_col)
	cancel.custom_minimum_size = Vector2(200, 48)
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color.TRANSPARENT
	cancel_style.border_color = text_col
	cancel_style.border_color.a = 0.3
	cancel_style.set_border_width_all(2)
	cancel_style.set_corner_radius_all(12)
	cancel.add_theme_stylebox_override("normal", cancel_style)
	cancel.add_theme_stylebox_override("hover", cancel_style)
	cancel.add_theme_stylebox_override("pressed", cancel_style)
	cancel.add_theme_stylebox_override("focus", cancel_style)

	cancel.pressed.connect(func() -> void:
		_size_popup_layer.queue_free()
		_size_popup_layer = null
	)
	vbox.add_child(cancel)
