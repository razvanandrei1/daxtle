extends Node

@onready var _game: Node2D      = $Game
@onready var _ui: CanvasLayer   = $UI


func _ready() -> void:
	RenderingServer.set_default_clear_color(GameTheme.ACTIVE["background"])
	_ui.prev_pressed.connect(_game.go_prev_level)
	_ui.next_pressed.connect(_game.go_next_level)
	_game.level_loaded.connect(_ui.set_level)
