extends CanvasLayer

signal back_pressed

@onready var _back:  BackArrow = $BackArrow
@onready var _level: Label     = $LevelLabel


func _ready() -> void:
	var text_col := GameTheme.ACTIVE["text"]

	_back.pressed.connect(func(): back_pressed.emit())

	# Level label styling
	_level.add_theme_color_override("font_color", text_col)
	_level.add_theme_font_override("font", GameTheme.FONT_BOLD)

	_level.add_theme_font_size_override("font_size", 62)


func set_level(n: int) -> void:
	_level.text = "%d" % n
