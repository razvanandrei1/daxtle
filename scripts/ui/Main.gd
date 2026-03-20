extends Node

@onready var _main_menu:    MainMenu    = $MainMenu
@onready var _game:         Node2D      = $Game
@onready var _ui:           CanvasLayer = $UI
@onready var _level_select: LevelSelect = $LevelSelect


func _ready() -> void:
	RenderingServer.set_default_clear_color(GameTheme.ACTIVE["background"])
	_main_menu.play_pressed.connect(_on_play_pressed)
	_main_menu.select_level_pressed.connect(_on_select_level_pressed)
	_ui.menu_pressed.connect(_on_menu_pressed)
	_ui.reset_pressed.connect(func() -> void: _game.reset_level())
	_level_select.level_selected.connect(_on_level_selected)
	_game.level_loaded.connect(_on_level_loaded)
	_game.first_move.connect(func() -> void: _ui.show_reset())
	_game.message_changed.connect(func(text: String, bb: float) -> void: _ui.set_message(text, bb))
	_game.intro_finished.connect(func() -> void: _ui.animate_message())
	_game.dismiss_message.connect(func() -> void: _ui.dismiss_message())

	# Start on main menu — hide everything else
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED


func _on_play_pressed() -> void:
	var last := SaveData.get_last_level()
	_show_game(last)


func _on_select_level_pressed() -> void:
	_main_menu.visible         = false
	_main_menu.process_mode    = Node.PROCESS_MODE_DISABLED
	_level_select.visible      = true
	_level_select.process_mode = Node.PROCESS_MODE_INHERIT


func _on_level_selected(n: int) -> void:
	_show_game(n)


func _on_level_loaded(n: int) -> void:
	_ui.set_level(n)
	SaveData.set_last_level(n)



func _on_menu_pressed() -> void:
	_game.stop()
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED
	_main_menu.visible         = true
	_main_menu.process_mode    = Node.PROCESS_MODE_INHERIT
	_main_menu.replay_intro()


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
