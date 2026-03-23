# =============================================================================
# LevelEditorPlay.gd — Quick play-test for the level editor
# =============================================================================
# Loads a level from Globals.editor_level_data and lets the player test it.
# Only sliding and teleportation animations — no intro/outro.
# =============================================================================
class_name LevelEditorPlay
extends Node2D

const BoardScene      := preload("res://scenes/entities/Board.tscn")
const BlockScene      := preload("res://scenes/entities/Block.tscn")
const FixedBlockScene := preload("res://scenes/entities/FixedBlock.tscn")
const TeleportScene   := preload("res://scenes/entities/Teleport.tscn")
const MOVE_DURATION   := 0.13

signal back_pressed

var _board: Board
var _blocks: Array[Block] = []
var _fixed_blocks: Array[FixedBlock] = []
var _teleports: Array[Teleport] = []
var _board_set: Dictionary = {}
var _fixed_set: Dictionary = {}
var _teleport_map: Dictionary = {}
var _active: bool = false
var _value_a: float = 0.0
var _win_layer: CanvasLayer

@onready var _header: SceneHeader = $SceneHeader
@onready var _swipe_detector: SwipeDetector = $SwipeDetector


func _ready() -> void:
	_header.back_pressed.connect(func() -> void: back_pressed.emit())
	_swipe_detector.swiped.connect(_on_swipe)
	_swipe_detector.double_tapped.connect(func() -> void: _reload())


func load_from_editor() -> void:
	_header.set_title("Test %d" % Globals.editor_level_number)
	var level_data := Globals.editor_level_data
	if level_data.is_empty():
		return
	_load_level_data(level_data)


func _reload() -> void:
	load_from_editor()


func _load_level_data(level_data: Dictionary) -> void:
	if _win_layer:
		_win_layer.queue_free()
		_win_layer = null
	if _board:
		_board.queue_free()
	_blocks.clear()
	_fixed_blocks.clear()
	_teleports.clear()
	_board_set.clear()
	_fixed_set.clear()
	_teleport_map.clear()

	var squares := LevelLoader.get_board_squares(level_data)
	_board = BoardScene.instantiate() as Board
	add_child(_board)
	_value_a = _board.setup(squares)

	for sq in squares:
		_board_set[sq] = true

	var fixed_data := LevelLoader.get_fixed_blocks(level_data)
	for fd in fixed_data:
		var fb := FixedBlockScene.instantiate() as FixedBlock
		_board.add_child(fb)
		fb.setup(fd, _value_a, _board)
		_fixed_blocks.append(fb)
		for cell in fd.cells():
			_fixed_set[cell] = true

	var teleport_data := LevelLoader.get_teleports(level_data)
	for i in teleport_data.size():
		var td: TeleportData = teleport_data[i]
		var pair_col := GameTheme.get_teleport_color(i)
		_teleport_map[td.portal_a] = td.portal_b
		if not td.one_way:
			_teleport_map[td.portal_b] = td.portal_a
		for cell in [td.portal_a, td.portal_b]:
			var tp := TeleportScene.instantiate() as Teleport
			_board.add_child(tp)
			tp.setup(cell, _value_a, _board, pair_col)
			_teleports.append(tp)

	var blocks_data := LevelLoader.get_blocks(level_data)
	var targets := LevelLoader.get_targets(level_data)
	for bd in blocks_data:
		var block_num := int(bd.id.substr(1)) if bd.id is String else int(bd.id)
		if targets.has(block_num):
			bd.target_origins.assign(targets[block_num])
	_board.set_targets(blocks_data)

	for block_data in blocks_data:
		var block := BlockScene.instantiate() as Block
		_board.add_child(block)
		block.setup(block_data, _value_a, _board)
		_blocks.append(block)

	_active = true
	_swipe_detector.enabled = true


func _on_swipe(direction: String) -> void:
	if not _active:
		return

	var candidates: Array[Block] = []
	for block in _blocks:
		if block.data.dir == direction:
			candidates.append(block)

	if candidates.is_empty():
		return

	var dv := _dir_to_vec(direction)
	var result := Movement.resolve(candidates, _blocks, _board_set, direction, _fixed_set, _teleport_map)
	var movers: Array[Block] = result["movers"]
	var invalid: Array[Block] = result["invalid"]
	var teleport_exits: Dictionary = result["teleport_exits"]
	var teleport_entries: Dictionary = result["teleport_entries"]

	if movers.is_empty() and invalid.is_empty():
		return

	_swipe_detector.enabled = false
	_active = false

	if not movers.is_empty():
		AudioManager.play_sfx("slide")
		Haptics.tap()

		var par := create_tween().set_parallel(true)
		var has_teleport := false
		var max_tp_dur := 0.0

		for block in movers:
			if teleport_exits.has(block):
				has_teleport = true
				var entry: Vector2i = teleport_entries[block]
				var exit_cell: Vector2i = _teleport_map[entry]
				var entry_pos := _board.grid_to_local(entry)
				var exit_pos := _board.grid_to_local(exit_cell)

				block.grid_origin = teleport_exits[block]
				var final_pos := _board.grid_to_local(block.grid_origin)
				var has_cont := (final_pos != exit_pos)

				const SHRINK := 0.14
				const POP := 0.18
				var tp := create_tween()
				tp.tween_property(block, "position", entry_pos, MOVE_DURATION) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tp.tween_method(func(v: float) -> void: block.block_scale = v,
					1.0, 0.0, SHRINK) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tp.tween_callback(func() -> void: block.position = exit_pos)
				tp.tween_method(func(v: float) -> void: block.block_scale = v,
					0.0, 1.0, POP) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if has_cont:
					tp.tween_property(block, "position", final_pos, MOVE_DURATION) \
						.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

				max_tp_dur = maxf(max_tp_dur,
					MOVE_DURATION + SHRINK + POP + (MOVE_DURATION if has_cont else 0.0))
			else:
				block.grid_origin += dv
				var target_pos := _board.grid_to_local(block.grid_origin)
				par.tween_property(block, "position", target_pos, MOVE_DURATION) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		var on_done := func() -> void:
			_active = true
			_swipe_detector.enabled = true
			_check_win()

		if has_teleport:
			var total_dur := maxf(max_tp_dur, MOVE_DURATION)
			get_tree().create_timer(total_dur).timeout.connect(on_done)
		else:
			par.finished.connect(on_done)

	if not invalid.is_empty():
		_shake_blocks(invalid, direction, movers.is_empty())


func _shake_blocks(blocks: Array[Block], direction: String, re_enable_after: bool) -> void:
	AudioManager.play_sfx("invalid")
	var dv := _dir_to_vec(direction)
	var nudge := Vector2(dv) * _value_a * 0.18

	var tween := create_tween().set_parallel(true)
	for block in blocks:
		var origin_pos := block.position
		tween.tween_property(block, "position", origin_pos + nudge, MOVE_DURATION * 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(block, "position", origin_pos, MOVE_DURATION * 0.85) \
			.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT) \
			.set_delay(MOVE_DURATION * 0.45)

	tween.finished.connect(func() -> void:
		if re_enable_after:
			_active = true
			_swipe_detector.enabled = true
	)


func _check_win() -> void:
	for block in _blocks:
		if not block.data.target_origins.has(block.grid_origin):
			return
	_active = false
	_swipe_detector.enabled = false
	_show_win()


func _show_win() -> void:
	# Brief flash then allow return
	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]

	var label := Label.new()
	label.text = "Solved!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", text_col)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.offset_left = -200
	label.offset_right = 200
	label.offset_top = -50
	label.offset_bottom = 50

	if _win_layer:
		_win_layer.queue_free()
	_win_layer = CanvasLayer.new()
	_win_layer.layer = 50
	add_child(_win_layer)
	_win_layer.add_child(label)

	label.modulate = Color.TRANSPARENT
	var tween := create_tween()
	tween.tween_property(label, "modulate", Color.WHITE, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate", Color.TRANSPARENT, 0.3)
	tween.finished.connect(func() -> void:
		if _win_layer:
			_win_layer.queue_free()
			_win_layer = null
		_reload()
	)


func _dir_to_vec(direction: String) -> Vector2i:
	match direction:
		"right": return Vector2i(1, 0)
		"left":  return Vector2i(-1, 0)
		"up":    return Vector2i(0, -1)
		"down":  return Vector2i(0, 1)
	return Vector2i.ZERO
