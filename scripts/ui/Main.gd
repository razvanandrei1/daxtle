# =============================================================================
# Main.gd — Root scene controller
# =============================================================================
# Orchestrates navigation between MainMenu, Game, LevelSelect, and Settings.
# Manages fade transitions, connects all child signals, and handles the
# completion popup when all levels are beaten.
# =============================================================================
extends Node

const FADE_DURATION := 0.18  # seconds for scene transition fade

@onready var _main_menu:    MainMenu    = $MainMenu
@onready var _game:         Node2D      = $Game
@onready var _ui:           CanvasLayer = $UI
@onready var _level_select: LevelSelect = $LevelSelect
@onready var _settings:     Settings    = $Settings

var _fade_layer:  CanvasLayer
var _fade_rect:   ColorRect
var _popup_layer: CanvasLayer
var _popup_panel: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(GameTheme.ACTIVE["background"])

	# Full-screen fade overlay — topmost layer so it covers everything
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = GameTheme.ACTIVE["background"]
	_fade_rect.color.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_menu.play_pressed.connect(_on_play_pressed)
	_main_menu.select_level_pressed.connect(_on_select_level_pressed)
	_main_menu.settings_pressed.connect(_on_settings_pressed)
	_ui.menu_pressed.connect(_on_menu_pressed)
	_ui.reset_pressed.connect(func() -> void: _game.reset_level())
	_level_select.level_selected.connect(_on_level_selected)
	_level_select.menu_pressed.connect(_on_menu_pressed)
	_settings.back_pressed.connect(_on_settings_back)
	_game.level_loaded.connect(_on_level_loaded)
	_game.first_move.connect(func() -> void: _ui.show_reset())
	_game.message_changed.connect(func(text: String, bb: float) -> void: _ui.set_message(text, bb))
	_game.intro_finished.connect(func() -> void: _ui.animate_message())
	_game.dismiss_message.connect(func() -> void: _ui.dismiss_message())
	_game.hide_reset.connect(func() -> void: _ui.hide_reset())
	_game.all_levels_completed.connect(_on_all_levels_completed)

	# Completion popup overlay
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 90
	add_child(_popup_layer)
	_popup_panel = _create_popup()
	_popup_layer.add_child(_popup_panel)
	_popup_panel.visible = false

	AudioManager.play_music()

	if Globals.DEBUG_MODE:
		# Jump straight into the game, skipping menus
		_main_menu.visible         = false
		_main_menu.process_mode    = Node.PROCESS_MODE_DISABLED
		_level_select.visible      = false
		_level_select.process_mode = Node.PROCESS_MODE_DISABLED
		_settings.visible          = false
		_settings.process_mode     = Node.PROCESS_MODE_DISABLED
		_game.visible              = true
		_game.process_mode         = Node.PROCESS_MODE_INHERIT
		_ui.visible                = true
		var last := SaveData.get_last_level()
		_ui.set_level(last)
		_game.load_level(last)
		return

	# Start on main menu — hide everything else
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED
	_settings.visible          = false
	_settings.process_mode     = Node.PROCESS_MODE_DISABLED


# Fade transition: fades screen to opaque, runs callback (scene switch), fades back in.
# Blocks input during the transition. Skipped entirely in DEBUG_MODE.
func _fade_to(callback: Callable) -> void:
	if Globals.DEBUG_MODE:
		callback.call()
		return
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out := create_tween()
	fade_out.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.finished.connect(func() -> void:
		callback.call()
		var fade_in := create_tween()
		fade_in.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade_in.finished.connect(func() -> void:
			_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		)
	)


func _on_play_pressed() -> void:
	var last := SaveData.get_last_level()
	_fade_to(func() -> void: _show_game(last))


func _on_select_level_pressed() -> void:
	_fade_to(func() -> void:
		_main_menu.visible         = false
		_main_menu.process_mode    = Node.PROCESS_MODE_DISABLED
		_level_select.visible      = true
		_level_select.process_mode = Node.PROCESS_MODE_INHERIT
	)


func _on_level_selected(n: int) -> void:
	_fade_to(func() -> void: _show_game(n))


func _on_level_loaded(n: int) -> void:
	_ui.set_level(n)
	SaveData.set_last_level(n)


func _on_settings_pressed() -> void:
	_fade_to(func() -> void:
		_main_menu.visible         = false
		_main_menu.process_mode    = Node.PROCESS_MODE_DISABLED
		_settings.visible          = true
		_settings.process_mode     = Node.PROCESS_MODE_INHERIT
	)


func _on_settings_back() -> void:
	_fade_to(func() -> void:
		_settings.visible          = false
		_settings.process_mode     = Node.PROCESS_MODE_DISABLED
		_main_menu.visible         = true
		_main_menu.process_mode    = Node.PROCESS_MODE_INHERIT
		_main_menu.replay_intro()
	)


func _on_menu_pressed() -> void:
	_fade_to(func() -> void:
		_game.stop()
		_game.visible              = false
		_game.process_mode         = Node.PROCESS_MODE_DISABLED
		_ui.visible                = false
		_level_select.visible      = false
		_level_select.process_mode = Node.PROCESS_MODE_DISABLED
		_main_menu.visible         = true
		_main_menu.process_mode    = Node.PROCESS_MODE_INHERIT
		_main_menu.replay_intro()
	)


# Called when the player beats the final level — returns to menu and shows congratulations popup.
func _on_all_levels_completed() -> void:
	_game.stop()
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_main_menu.visible         = true
	_main_menu.process_mode    = Node.PROCESS_MODE_INHERIT
	_main_menu.replay_intro()
	_show_popup()


func _create_popup() -> Control:
	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]
	var bg_col := GameTheme.ACTIVE["background"]
	var surface_col := GameTheme.ACTIVE["surface"]

	# Container
	var container := Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dimmed background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_child(dim)

	# Panel
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(700, 500)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -350
	panel.offset_right = 350
	panel.offset_top = -250
	panel.offset_bottom = 250

	var style := StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = text_col
	style.border_color.a = 0.3
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 48
	style.content_margin_bottom = 48
	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)

	# VBox for content
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Congratulations!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", text_col)
	vbox.add_child(title)

	# Message
	var msg := Label.new()
	msg.text = "You have completed all the levels in this MVP game project.\nI hope you enjoyed it and I'm looking forward to your feedback."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_override("font", font)
	msg.add_theme_font_size_override("font_size", 36)
	var msg_col := text_col
	msg_col.a = 0.7
	msg.add_theme_color_override("font_color", msg_col)
	vbox.add_child(msg)

	# OK button
	var btn := Button.new()
	btn.text = "OK"
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", bg_col)
	btn.custom_minimum_size = Vector2(200, 64)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = text_col
	btn_normal.set_corner_radius_all(16)
	btn_normal.content_margin_left = 40
	btn_normal.content_margin_right = 40
	btn_normal.content_margin_top = 12
	btn_normal.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", btn_normal)
	btn.add_theme_stylebox_override("hover", btn_normal)
	btn.add_theme_stylebox_override("pressed", btn_normal)
	btn.add_theme_stylebox_override("focus", btn_normal)
	btn.pressed.connect(_dismiss_popup)
	vbox.add_child(btn)

	return container


func _show_popup() -> void:
	_popup_panel.visible = true
	_popup_panel.modulate = Color.TRANSPARENT
	_popup_panel.scale = Vector2(0.9, 0.9)
	_popup_panel.pivot_offset = _popup_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_popup_panel, "modulate", Color.WHITE, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_popup_panel, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _dismiss_popup() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_popup_panel, "modulate", Color.TRANSPARENT, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_popup_panel, "scale", Vector2(0.9, 0.9), 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		_popup_panel.visible = false
	)


func _show_game(level_n: int) -> void:
	_main_menu.visible         = false
	_main_menu.process_mode    = Node.PROCESS_MODE_DISABLED
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED
	_game.visible              = true
	_game.process_mode         = Node.PROCESS_MODE_INHERIT
	_ui.visible                = true
	_ui.set_level(level_n)
	_game.load_level(level_n)
