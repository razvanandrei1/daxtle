extends CanvasLayer

signal back_pressed
signal reset_pressed

@onready var _back:  BackArrow = $BackArrow
@onready var _reset: ResetIcon = $ResetIcon
@onready var _level: Label     = $LevelLabel


func _ready() -> void:
	var text_col := GameTheme.ACTIVE["text"]
	var safe_top := GameTheme.get_safe_area_top()
	var vp       := get_viewport().get_visible_rect().size
	var margin_x := vp.x * Board.MARGIN
	var top_y    := safe_top + 32.0

	_back.pressed.connect(func(): back_pressed.emit())
	_reset.pressed.connect(func(): reset_pressed.emit())

	# Level label vertical center
	var label_h  := 62.0  # font size
	var label_cy := top_y + label_h * 0.5

	_back.position  = Vector2(margin_x, label_cy)
	_reset.position = Vector2(vp.x - margin_x, label_cy)
	_level.offset_top    = top_y
	_level.offset_bottom = top_y + label_h

	# Level label styling
	_level.add_theme_color_override("font_color", text_col)
	_level.add_theme_font_override("font", GameTheme.FONT_BOLD)
	_level.add_theme_font_size_override("font_size", 62)

	_reset.visible = false


func set_level(n: int) -> void:
	_level.text = "%d" % n
	_reset.visible = false


func show_reset() -> void:
	if not _reset.visible:
		_reset.visible = true
		_reset.scale = Vector2.ZERO
		var tween := create_tween()
		tween.tween_property(_reset, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
