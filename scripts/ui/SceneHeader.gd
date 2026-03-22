class_name SceneHeader
extends Node2D

signal back_pressed

@export var title_text: String = ""
@export var title_font_size: int = 85

var _font: Font = GameTheme.FONT_BOLD
var _safe_top: float
var right_x: float   # x position of the right edge (for external icons like reset)
var bar_cy: float     # vertical centre of the header bar

@onready var _menu: MenuIcon = $MenuIcon


func _ready() -> void:
	_safe_top = GameTheme.get_safe_area_top()
	var vp       := get_viewport().get_visible_rect().size
	var margin_x := vp.x * Board.MARGIN
	var icon_half := MenuIcon.ICON_SIZE * 0.5
	bar_cy   = _safe_top + Globals.TOP_OFFSET + Globals.LABEL_HEIGHT * 0.5
	right_x  = vp.x - margin_x - icon_half
	_menu.pressed.connect(func() -> void: back_pressed.emit())
	_menu.position = Vector2(margin_x + icon_half, bar_cy)


func set_title(text: String) -> void:
	title_text = text
	queue_redraw()


func _draw() -> void:
	if title_text.is_empty():
		return
	var vp := get_viewport().get_visible_rect().size
	var text_col := GameTheme.ACTIVE["text"]
	var title_fs  := title_font_size
	var title_w   := _font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs).x
	var title_asc := _font.get_ascent(title_fs)
	var title_y   := _safe_top + Globals.TOP_OFFSET + Globals.LABEL_HEIGHT * 0.34 + title_asc * 0.5
	draw_string(_font, Vector2((vp.x - title_w) * 0.5, title_y),
		title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, text_col)
