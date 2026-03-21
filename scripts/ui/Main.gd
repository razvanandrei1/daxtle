extends Node

const FADE_DURATION := 0.18

@onready var _main_menu:    MainMenu    = $MainMenu
@onready var _game:         Node2D      = $Game
@onready var _ui:           CanvasLayer = $UI
@onready var _level_select: LevelSelect = $LevelSelect
@onready var _settings:     Settings    = $Settings

var _fade_layer: CanvasLayer
var _fade_rect:  ColorRect


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
