extends Node

@onready var _main_menu:    MainMenu    = $MainMenu
@onready var _game:         Node2D      = $Game
@onready var _ui:           CanvasLayer = $UI
@onready var _level_select: LevelSelect = $LevelSelect


func _ready() -> void:
	RenderingServer.set_default_clear_color(GameTheme.ACTIVE["background"])
	_main_menu.play_pressed.connect(_on_play_pressed)
	_ui.back_pressed.connect(_on_back_pressed)
	_level_select.level_selected.connect(_on_level_selected)
	_level_select.back_pressed.connect(_on_level_select_back)
	_game.level_loaded.connect(func(n: int) -> void: _ui.set_level(n))

	# Start on main menu — hide everything else
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED


func _on_play_pressed() -> void:
	_main_menu.visible         = false
	_main_menu.process_mode    = Node.PROCESS_MODE_DISABLED
	_level_select.visible      = true
	_level_select.process_mode = Node.PROCESS_MODE_INHERIT


func _on_level_selected(n: int) -> void:
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED
	_game.visible              = true
	_game.process_mode         = Node.PROCESS_MODE_INHERIT
	_ui.visible                = true
	_ui.set_level(n)
	_game.load_level(n)


func _on_level_select_back() -> void:
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED
	_main_menu.visible         = true
	_main_menu.process_mode    = Node.PROCESS_MODE_INHERIT


func _on_back_pressed() -> void:
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_level_select.visible      = true
	_level_select.process_mode = Node.PROCESS_MODE_INHERIT
