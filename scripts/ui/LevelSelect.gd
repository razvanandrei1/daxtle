class_name LevelSelect
extends Node2D

signal level_selected(n: int)

const COLS        := 5
const ROWS        := 8
const PADDING     := 48.0
const TOP_OFFSET  := 160.0
const BOT_PADDING := 48.0
const CELL_GAP    := 14.0

var _cell_size:    float
var _origin:       Vector2
var _total_levels: int
var _font:         Font


func _ready() -> void:
	_total_levels = LevelLoader.count_levels()
	_font         = ThemeDB.fallback_font
	_compute_layout()


func _compute_layout() -> void:
	var vp    := get_viewport().get_visible_rect().size
	var avail_w := vp.x - PADDING * 2.0
	var avail_h := vp.y - TOP_OFFSET - BOT_PADDING
	var cell_w  := (avail_w - CELL_GAP * (COLS - 1)) / COLS
	var cell_h  := (avail_h - CELL_GAP * (ROWS - 1)) / ROWS
	_cell_size  = minf(cell_w, cell_h)
	var grid_w  := _cell_size * COLS + CELL_GAP * (COLS - 1)
	var grid_h  := _cell_size * ROWS + CELL_GAP * (ROWS - 1)
	_origin     = Vector2((vp.x - grid_w) * 0.5, TOP_OFFSET + (avail_h - grid_h) * 0.5)


func _draw() -> void:
	var vp     := get_viewport().get_visible_rect().size
	var radius := _cell_size * GameTheme.CORNER_FRACTION

	# Title
	var title_size := int(_cell_size * 0.42)
	var title_w    := _font.get_string_size("LEVELS", HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var title_x    := (vp.x - title_w) * 0.5
	var title_y    := TOP_OFFSET - CELL_GAP * 2.0
	draw_string(_font, Vector2(title_x, title_y), "LEVELS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, GameTheme.ACTIVE["fixed"])

	# Cells
	for row in ROWS:
		for col in COLS:
			var level_n  := row * COLS + col + 1
			var cell_pos := _origin + Vector2(col * (_cell_size + CELL_GAP), row * (_cell_size + CELL_GAP))
			var rect     := Rect2(cell_pos, Vector2(_cell_size, _cell_size))

			if level_n > _total_levels:
				var dim := GameTheme.ACTIVE["surface"]
				dim.a   = 0.35
				_draw_rounded_rect(rect, dim, radius)
			else:
				_draw_rounded_rect(rect, GameTheme.ACTIVE["surface"], radius)
				var num_str   := "%d" % level_n
				var font_size := int(_cell_size * 0.38)
				var tw        := _font.get_string_size(num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				var ascent    := _font.get_ascent(font_size)
				var tx        := cell_pos.x + (_cell_size - tw) * 0.5
				var ty        := cell_pos.y + (_cell_size + ascent) * 0.5
				draw_string(_font, Vector2(tx, ty), num_str,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, GameTheme.ACTIVE["fixed"])


func _unhandled_input(event: InputEvent) -> void:
	var pos: Vector2
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton \
			and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (event as InputEventMouseButton).position
	else:
		return

	for row in ROWS:
		for col in COLS:
			var level_n  := row * COLS + col + 1
			if level_n > _total_levels:
				continue
			var cell_pos := _origin + Vector2(col * (_cell_size + CELL_GAP), row * (_cell_size + CELL_GAP))
			if Rect2(cell_pos, Vector2(_cell_size, _cell_size)).has_point(pos):
				level_selected.emit(level_n)
				get_viewport().set_input_as_handled()
				return


func _draw_rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(int(radius))
	style.draw(get_canvas_item(), rect)
