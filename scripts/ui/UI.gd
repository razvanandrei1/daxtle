extends CanvasLayer

signal back_pressed

@onready var _back: Button = $BackButton


func _ready() -> void:
	_back.pressed.connect(func(): back_pressed.emit())
