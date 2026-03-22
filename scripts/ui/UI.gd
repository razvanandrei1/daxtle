extends CanvasLayer

@onready var _msg_panel: PanelContainer = $MessagePanel
@onready var _msg_label: Label          = $MessagePanel/MessageLabel


func _ready() -> void:
	var text_col := GameTheme.ACTIVE["text"]

	# Message styling
	var msg_col := text_col
	msg_col.a = 0.7
	_msg_label.add_theme_color_override("font_color", msg_col)
	_msg_label.add_theme_font_override("font", GameTheme.FONT_BOLD)
	_msg_label.add_theme_font_size_override("font_size", 42)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color.TRANSPARENT
	var border_col := GameTheme.ACTIVE["text"]
	border_col.a = 1.0
	panel_style.border_color = border_col
	panel_style.set_border_width_all(4)  # updated dynamically via update_panel_border()
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 44
	panel_style.content_margin_right = 44
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	_msg_panel.add_theme_stylebox_override("panel", panel_style)
	_msg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_panel.visible = false



func update_panel_border(value_a: float) -> void:
	var style: StyleBoxFlat = _msg_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		var border_w := int(value_a * 0.041)
		style.set_border_width_all(border_w)
		style.set_corner_radius_all(int(value_a * GameTheme.CORNER_FRACTION))


func set_message(text: String, board_bottom: float) -> void:
	if text.is_empty():
		_msg_panel.visible = false
		return

	_msg_label.text = text

	var vp := get_viewport().get_visible_rect().size
	var safe_bot := GameTheme.get_safe_area_bottom()
	var zone_top := board_bottom + 20.0
	var zone_bot := vp.y - maxf(safe_bot, 40.0)
	var zone_h   := zone_bot - zone_top

	# 80% of screen width, centered horizontally
	var panel_w := vp.x * 0.80
	var panel_x := (vp.x - panel_w) * 0.5
	var pad_x   := 44.0
	var pad_y   := 28.0

	# Compute text height manually
	var font := GameTheme.FONT_BOLD
	var fs   := 42
	var text_w := panel_w - pad_x * 2.0
	var text_h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, text_w, fs).y
	var panel_h := text_h + pad_y * 2.0

	var panel_y := zone_top + (zone_h - panel_h) * 0.5

	_msg_panel.anchor_left   = 0.0
	_msg_panel.anchor_top    = 0.0
	_msg_panel.anchor_right  = 0.0
	_msg_panel.anchor_bottom = 0.0
	_msg_panel.visible  = true
	_msg_panel.modulate = Color.TRANSPARENT

	# Wait one frame for anchor reset to take effect before sizing
	await get_tree().process_frame
	_msg_panel.position     = Vector2(panel_x, panel_y)
	_msg_panel.size         = Vector2(panel_w, panel_h)
	_msg_panel.pivot_offset = _msg_panel.size * 0.5


func animate_message() -> void:
	if not _msg_panel.visible or _msg_label.text.is_empty():
		return

	if Globals.DEBUG_MODE:
		_msg_panel.scale    = Vector2.ONE
		_msg_panel.modulate = Color.WHITE
		return

	_msg_panel.scale    = Vector2(0.8, 0.8)
	_msg_panel.modulate = Color.TRANSPARENT

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_msg_panel, "scale", Vector2.ONE, 0.35) \
		.set_delay(0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_msg_panel, "modulate", Color.WHITE, 0.25) \
		.set_delay(0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func dismiss_message() -> void:
	if not _msg_panel.visible or _msg_label.text.is_empty():
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_msg_panel, "scale", Vector2(0.8, 0.8), 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_msg_panel, "modulate", Color.TRANSPARENT, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		_msg_panel.visible = false
	)
