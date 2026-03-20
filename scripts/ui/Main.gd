extends Node

@onready var _game:         Node2D      = $Game
@onready var _ui:           CanvasLayer = $UI
@onready var _level_select: Node2D      = $LevelSelect


func _ready() -> void:
	RenderingServer.set_default_clear_color(GameTheme.ACTIVE["background"])
	_ui.back_pressed.connect(_on_back_pressed)
	_level_select.level_selected.connect(_on_level_selected)

	_game.visible      = false
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	_ui.visible        = false


func _on_level_selected(n: int) -> void:
	_level_select.visible      = false
	_level_select.process_mode = Node.PROCESS_MODE_DISABLED
	_game.visible              = true
	_game.process_mode         = Node.PROCESS_MODE_INHERIT
	_ui.visible                = true
	_game.load_level(n)


func _on_back_pressed() -> void:
	_game.visible              = false
	_game.process_mode         = Node.PROCESS_MODE_DISABLED
	_ui.visible                = false
	_level_select.visible      = true
	_level_select.process_mode = Node.PROCESS_MODE_INHERIT
