# =============================================================================
# LevelEditor.gd — In-game level editor (active when LEVEL_EDITOR_MODE = true)
# =============================================================================
# Loads a level's board and lets the user place/remove blocks, targets,
# teleports, and board squares. Provides validate, save, reposition,
# and quick-play buttons.
# =============================================================================
class_name LevelEditor
extends Node2D

const BoardScene      := preload("res://scenes/entities/Board.tscn")
const BlockScene      := preload("res://scenes/entities/Block.tscn")
const FixedBlockScene := preload("res://scenes/entities/FixedBlock.tscn")
const TeleportScene   := preload("res://scenes/entities/Teleport.tscn")

signal menu_pressed
signal play_pressed

# ── Tool enum ────────────────────────────────────────────────────────────────
enum Tool {
	NONE,
	BLOCK_1, BLOCK_2, BLOCK_3, BLOCK_4,
	TARGET_1, TARGET_2, TARGET_3, TARGET_4,
	TELEPORT_1, TELEPORT_2, TELEPORT_3,
}

const TOOL_LABELS := {
	Tool.BLOCK_1: "B1", Tool.BLOCK_2: "B2", Tool.BLOCK_3: "B3", Tool.BLOCK_4: "B4",
	Tool.TARGET_1: "T1", Tool.TARGET_2: "T2", Tool.TARGET_3: "T3", Tool.TARGET_4: "T4",
	Tool.TELEPORT_1: "TP1", Tool.TELEPORT_2: "TP2", Tool.TELEPORT_3: "TP3",
}

# ── State ────────────────────────────────────────────────────────────────────
var current_level: int = 1
var _active_tool: Tool = Tool.NONE

# Level data — mutable editor state
var _squares: Dictionary = {}          # Vector2i -> true
var _removed_squares: Dictionary = {}  # Vector2i -> true (squares toggled off)
var _targets: Dictionary = {}          # Vector2i -> int (block_id)
var _blocks: Array = []                # [{id:int, dir:String, origin:Vector2i}, ...]
var _teleports: Array = []             # [{id:int, portal_a:Vector2i, portal_b:Vector2i}, ...]
var _message: String = ""              # tutorial message preserved across saves

# Visual nodes
var _board: Board
var _block_nodes: Array[Block] = []
var _teleport_nodes: Array[Teleport] = []
var _value_a: float = 0.0

# UI
var _panel_layer: CanvasLayer
var _tool_buttons: Dictionary = {}     # Tool -> Button
var _status_label: Label
var _tp_pending: Dictionary = {}       # Tool -> Vector2i (first portal click)
var _last_click_frame: int = -1        # prevent double-fire from touch emulation

@onready var _header: SceneHeader = $SceneHeader


func _ready() -> void:
	_header.back_pressed.connect(func() -> void: menu_pressed.emit())
	_build_panel()
	visibility_changed.connect(func() -> void:
		if _panel_layer:
			_panel_layer.visible = visible
	)


func load_level(n: int) -> void:
	current_level = n
	_header.set_title("Edit %d" % n)
	var level_data := LevelLoader.load_level(n)
	if level_data.is_empty():
		return
	_parse_level_data(level_data)
	_rebuild_visuals()


func load_empty(n: int, grid_size: int) -> void:
	current_level = n
	_header.set_title("Edit %d" % n)
	_squares.clear()
	_removed_squares.clear()
	_targets.clear()
	_blocks.clear()
	_teleports.clear()
	_message = ""
	for y in grid_size:
		for x in grid_size:
			_squares[Vector2i(x, y)] = true
	_rebuild_visuals()


# ── Level data parsing ───────────────────────────────────────────────────────

func _parse_level_data(data: Dictionary) -> void:
	_squares.clear()
	_removed_squares.clear()
	_targets.clear()
	_blocks.clear()
	_teleports.clear()
	_message = data.get("message", "")

	if data.has("A"):
		for entry in data["A"]:
			var cell := Vector2i(entry[0], entry[1])
			_squares[cell] = true
			if entry.size() >= 3:
				_targets[cell] = int(entry[2])

	if data.has("B"):
		for entry in data["B"]:
			_blocks.append({
				"id": int(entry["id"]),
				"dir": entry["dir"],
				"origin": Vector2i(entry["origin"][0], entry["origin"][1]),
			})

	if data.has("T"):
		for entry in data["T"]:
			var pos: Array = entry["pos"]
			_teleports.append({
				"id": int(entry.get("id", _teleports.size() + 1)),
				"portal_a": Vector2i(pos[0], pos[1]),
				"portal_b": Vector2i(pos[2], pos[3]),
			})


# ── Visual rebuild ───────────────────────────────────────────────────────────

func _rebuild_visuals() -> void:
	if _board:
		_board.queue_free()
		_board = null
	_block_nodes.clear()
	_teleport_nodes.clear()

	var active_squares: Array[Vector2i] = []
	for sq in _squares:
		if not _removed_squares.has(sq):
			active_squares.append(sq)

	if active_squares.is_empty():
		return

	_board = BoardScene.instantiate() as Board
	add_child(_board)
	_value_a = _board.setup(active_squares)

	# Targets → build BlockData array for set_targets
	var block_data_for_targets: Array[BlockData] = []
	var target_by_id: Dictionary = {}  # id -> Array[Vector2i]
	for cell in _targets:
		if _removed_squares.has(cell):
			continue
		var bid: int = _targets[cell]
		if not target_by_id.has(bid):
			target_by_id[bid] = []
		target_by_id[bid].append(cell)
	for bid in target_by_id:
		var bd := BlockData.new()
		bd.id = "B%d" % bid
		bd.dir = "none"
		bd.origin = Vector2i.ZERO
		bd.target_origins.assign(target_by_id[bid])
		block_data_for_targets.append(bd)
	_board.set_targets(block_data_for_targets)

	# Teleports
	for i in _teleports.size():
		var td: Dictionary = _teleports[i]
		var pair_col := GameTheme.get_teleport_color(i)
		for cell in [td["portal_a"], td["portal_b"]]:
			if _removed_squares.has(cell):
				continue
			var tp := TeleportScene.instantiate() as Teleport
			_board.add_child(tp)
			tp.setup(cell, _value_a, _board, pair_col)
			_teleport_nodes.append(tp)

	# Blocks
	for entry in _blocks:
		var bd := BlockData.new()
		bd.id = "B%d" % entry["id"]
		bd.dir = entry["dir"]
		bd.origin = entry["origin"]
		var targets_for_block: Array[Vector2i] = []
		if target_by_id.has(entry["id"]):
			targets_for_block.assign(target_by_id[entry["id"]])
		bd.target_origins = targets_for_block

		var block := BlockScene.instantiate() as Block
		_board.add_child(block)
		block.setup(bd, _value_a, _board)
		_block_nodes.append(block)

	queue_redraw()


# ── Input handling ───────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	# Keyboard shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_COMMA:
				if current_level > 1:
					load_level(current_level - 1)
				get_viewport().set_input_as_handled()
				return
			KEY_PERIOD:
				if current_level < LevelLoader.count_levels():
					load_level(current_level + 1)
				get_viewport().set_input_as_handled()
				return
			KEY_W:
				if event.ctrl_pressed:
					_expand_grid("up")
					get_viewport().set_input_as_handled()
					return
				elif event.shift_pressed:
					_shrink_grid("up")
					get_viewport().set_input_as_handled()
					return
			KEY_S:
				if event.ctrl_pressed:
					_expand_grid("down")
					get_viewport().set_input_as_handled()
					return
				elif event.shift_pressed:
					_shrink_grid("down")
					get_viewport().set_input_as_handled()
					return
			KEY_A:
				if event.ctrl_pressed:
					_expand_grid("left")
					get_viewport().set_input_as_handled()
					return
				elif event.shift_pressed:
					_shrink_grid("left")
					get_viewport().set_input_as_handled()
					return
			KEY_D:
				if event.ctrl_pressed:
					_expand_grid("right")
					get_viewport().set_input_as_handled()
					return
				elif event.shift_pressed:
					_shrink_grid("right")
					get_viewport().set_input_as_handled()
					return
			KEY_X:
				_select_tool(Tool.NONE)
				for tid in _tool_buttons:
					_tool_buttons[tid].button_pressed = false
				get_viewport().set_input_as_handled()
				return


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	var is_click := false

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			is_click = true
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			is_click = true

	if is_click and _board:
		var frame := Engine.get_process_frames()
		if frame == _last_click_frame:
			return
		_last_click_frame = frame
		var cell := _pixel_to_grid()
		if cell != Vector2i(-999, -999):
			_handle_cell_click(cell, event)
			get_viewport().set_input_as_handled()


func _pixel_to_grid() -> Vector2i:
	if not _board:
		return Vector2i(-999, -999)

	var local := _board.get_local_mouse_position()
	var min_grid := _get_min_grid()

	# First check active (visible) squares
	for sq in _squares:
		if _removed_squares.has(sq):
			continue
		var cell_pos := Vector2(sq - min_grid) * _value_a
		var rect := Rect2(cell_pos, Vector2(_value_a, _value_a))
		if rect.has_point(local):
			return sq

	# Then check removed squares so they can be restored
	for sq in _removed_squares:
		var cell_pos := Vector2(sq - min_grid) * _value_a
		var rect := Rect2(cell_pos, Vector2(_value_a, _value_a))
		if rect.has_point(local):
			return sq

	return Vector2i(-999, -999)


func _get_min_grid() -> Vector2i:
	var active_squares: Array[Vector2i] = []
	for sq in _squares:
		if not _removed_squares.has(sq):
			active_squares.append(sq)
	if active_squares.is_empty():
		return Vector2i.ZERO
	return Board._grid_min(active_squares)


func _handle_cell_click(cell: Vector2i, event: InputEvent) -> void:
	# If cell has any existing element, remove it first
	if _remove_element_at(cell):
		_rebuild_visuals()
		return

	# No tool selected — toggle board square on/off
	if _active_tool == Tool.NONE:
		_toggle_square(cell)
		return

	# Otherwise place with the active tool
	match _active_tool:
		Tool.NONE:
			return
		Tool.BLOCK_1, Tool.BLOCK_2, Tool.BLOCK_3, Tool.BLOCK_4:
			_place_block(cell)
		Tool.TARGET_1, Tool.TARGET_2, Tool.TARGET_3, Tool.TARGET_4:
			_place_target(cell)
		Tool.TELEPORT_1, Tool.TELEPORT_2, Tool.TELEPORT_3:
			_handle_teleport_click(cell)


func _expand_grid(direction: String) -> void:
	var active: Array[Vector2i] = []
	for sq in _squares:
		if not _removed_squares.has(sq):
			active.append(sq)
	if active.is_empty():
		return

	var mn := Board._grid_min(active)
	var mx := Board._grid_max(active)

	match direction:
		"up":
			var y := mn.y - 1
			for x in range(mn.x, mx.x + 1):
				_squares[Vector2i(x, y)] = true
		"down":
			var y := mx.y + 1
			for x in range(mn.x, mx.x + 1):
				_squares[Vector2i(x, y)] = true
		"left":
			var x := mn.x - 1
			for y in range(mn.y, mx.y + 1):
				_squares[Vector2i(x, y)] = true
		"right":
			var x := mx.x + 1
			for y in range(mn.y, mx.y + 1):
				_squares[Vector2i(x, y)] = true

	_rebuild_visuals()


func _shrink_grid(direction: String) -> void:
	var active: Array[Vector2i] = []
	for sq in _squares:
		if not _removed_squares.has(sq):
			active.append(sq)
	if active.is_empty():
		return

	var mn := Board._grid_min(active)
	var mx := Board._grid_max(active)

	# Don't shrink below 1 row/column
	if direction in ["up", "down"] and mn.y == mx.y:
		return
	if direction in ["left", "right"] and mn.x == mx.x:
		return

	var remove_y := -999
	var remove_x := -999
	match direction:
		"up":    remove_y = mn.y
		"down":  remove_y = mx.y
		"left":  remove_x = mn.x
		"right": remove_x = mx.x

	# Remove squares, targets, blocks, and teleports on that row/column
	var to_erase: Array[Vector2i] = []
	for sq in _squares:
		if remove_y != -999 and sq.y == remove_y:
			to_erase.append(sq)
		elif remove_x != -999 and sq.x == remove_x:
			to_erase.append(sq)
	for sq in to_erase:
		_squares.erase(sq)
		_removed_squares.erase(sq)
		_targets.erase(sq)

	for i in range(_blocks.size() - 1, -1, -1):
		var o: Vector2i = _blocks[i]["origin"]
		if (remove_y != -999 and o.y == remove_y) or (remove_x != -999 and o.x == remove_x):
			_blocks.remove_at(i)

	for i in range(_teleports.size() - 1, -1, -1):
		var td: Dictionary = _teleports[i]
		var a: Vector2i = td["portal_a"]
		var b: Vector2i = td["portal_b"]
		if (remove_y != -999 and (a.y == remove_y or b.y == remove_y)) \
			or (remove_x != -999 and (a.x == remove_x or b.x == remove_x)):
			_teleports.remove_at(i)

	_rebuild_visuals()


## Returns true if something was removed at this cell.
func _remove_element_at(cell: Vector2i) -> bool:
	# Remove any block at this cell
	for i in range(_blocks.size() - 1, -1, -1):
		if _blocks[i]["origin"] == cell:
			_blocks.remove_at(i)
			return true

	# Remove any target at this cell
	if _targets.has(cell):
		_targets.erase(cell)
		return true

	# Remove any teleport portal at this cell
	for i in range(_teleports.size() - 1, -1, -1):
		var td: Dictionary = _teleports[i]
		if td["portal_a"] == cell or td["portal_b"] == cell:
			_teleports.remove_at(i)
			_tp_pending.erase(_active_tool)
			return true

	return false


func _toggle_square(cell: Vector2i) -> void:
	if _removed_squares.has(cell):
		_removed_squares.erase(cell)
	elif _squares.has(cell):
		_removed_squares[cell] = true
	_rebuild_visuals()


func _get_block_id_from_tool() -> int:
	match _active_tool:
		Tool.BLOCK_1: return 1
		Tool.BLOCK_2: return 2
		Tool.BLOCK_3: return 3
		Tool.BLOCK_4: return 4
	return 0


func _get_target_id_from_tool() -> int:
	match _active_tool:
		Tool.TARGET_1: return 1
		Tool.TARGET_2: return 2
		Tool.TARGET_3: return 3
		Tool.TARGET_4: return 4
	return 0


func _get_teleport_id_from_tool() -> int:
	match _active_tool:
		Tool.TELEPORT_1: return 1
		Tool.TELEPORT_2: return 2
		Tool.TELEPORT_3: return 3
	return 0


func _place_block(cell: Vector2i) -> void:
	var bid := _get_block_id_from_tool()

	# Determine direction from WASD keys
	var dir := "none"
	if Input.is_key_pressed(KEY_D): dir = "right"
	elif Input.is_key_pressed(KEY_A): dir = "left"
	elif Input.is_key_pressed(KEY_W): dir = "up"
	elif Input.is_key_pressed(KEY_S): dir = "down"

	_blocks.append({"id": bid, "dir": dir, "origin": cell})
	_rebuild_visuals()


func _place_target(cell: Vector2i) -> void:
	var tid := _get_target_id_from_tool()
	_targets[cell] = tid
	_rebuild_visuals()


func _handle_teleport_click(cell: Vector2i) -> void:
	var tp_id := _get_teleport_id_from_tool()

	# Pending first portal click?
	if _tp_pending.has(_active_tool):
		var portal_a: Vector2i = _tp_pending[_active_tool]
		if portal_a == cell:
			_tp_pending.erase(_active_tool)
			_set_status("")
			return
		_teleports.append({
			"id": tp_id,
			"portal_a": portal_a,
			"portal_b": cell,
		})
		_tp_pending.erase(_active_tool)
		_set_status("")
		_rebuild_visuals()
		return

	# First click — store as pending
	_tp_pending[_active_tool] = cell
	_set_status("Click second portal for TP%d" % tp_id)


# ── Serialization ────────────────────────────────────────────────────────────

func _to_level_dict() -> Dictionary:
	var data := {}

	# A array
	var a_arr: Array = []
	for sq in _squares:
		if _removed_squares.has(sq):
			continue
		if _targets.has(sq):
			a_arr.append([sq.x, sq.y, _targets[sq]])
		else:
			a_arr.append([sq.x, sq.y])
	data["A"] = a_arr

	# B array
	var b_arr: Array = []
	for entry in _blocks:
		b_arr.append({
			"id": entry["id"],
			"dir": entry["dir"],
			"origin": [entry["origin"].x, entry["origin"].y],
		})
	data["B"] = b_arr

	# T array (only if non-empty)
	if not _teleports.is_empty():
		var t_arr: Array = []
		for entry in _teleports:
			t_arr.append({
				"id": entry["id"],
				"pos": [
					entry["portal_a"].x, entry["portal_a"].y,
					entry["portal_b"].x, entry["portal_b"].y,
				],
				"one_way": false,
			})
		data["T"] = t_arr

	if not _message.is_empty():
		data["message"] = _message

	return data


func _reposition() -> void:
	# Shift all coordinates so the minimum is (0,0)
	var active: Array[Vector2i] = []
	for sq in _squares:
		if not _removed_squares.has(sq):
			active.append(sq)
	if active.is_empty():
		return

	var mn := Board._grid_min(active)
	if mn == Vector2i.ZERO:
		return

	# Shift squares
	var new_squares: Dictionary = {}
	for sq in _squares:
		new_squares[sq - mn] = true
	_squares = new_squares

	var new_removed: Dictionary = {}
	for sq in _removed_squares:
		new_removed[sq - mn] = true
	_removed_squares = new_removed

	# Shift targets
	var new_targets: Dictionary = {}
	for cell in _targets:
		new_targets[cell - mn] = _targets[cell]
	_targets = new_targets

	# Shift blocks
	for entry in _blocks:
		entry["origin"] = entry["origin"] - mn

	# Shift teleports
	for entry in _teleports:
		entry["portal_a"] = entry["portal_a"] - mn
		entry["portal_b"] = entry["portal_b"] - mn

	_rebuild_visuals()


func _save_level() -> void:
	_reposition()
	var data := _to_level_dict()
	# Build JSON with each top-level key on its own line
	var parts: Array[String] = []
	for key in data:
		parts.append('"%s":%s' % [key, JSON.stringify(data[key])])
	var json_str := "{\n" + ",\n".join(parts) + "\n}"

	# Save to file
	var path := "res://levels/level_%03d.json" % current_level
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		_set_status("Saved to %s" % path)
		print("=== Level %d saved ===" % current_level)
	else:
		_set_status("Save failed — check console")
		print("ERROR: Could not save to %s" % path)

	# Always print to console as backup
	print(json_str)


func _validate() -> void:
	var data := _to_level_dict()

	# Check minimum requirements
	if not data.has("B") or data["B"].is_empty():
		_set_status("No blocks placed!")
		return

	var active_squares: Array[Vector2i] = []
	for sq in _squares:
		if not _removed_squares.has(sq):
			active_squares.append(sq)

	# Build required data structures for PuzzleSolver
	var board_set: Dictionary = {}
	for sq in active_squares:
		board_set[sq] = true

	var fixed_set: Dictionary = {}

	var teleport_map: Dictionary = {}
	for td in _teleports:
		teleport_map[td["portal_a"]] = td["portal_b"]
		teleport_map[td["portal_b"]] = td["portal_a"]

	# Build targets lookup
	var target_by_id: Dictionary = {}
	for cell in _targets:
		if _removed_squares.has(cell):
			continue
		var bid: int = _targets[cell]
		if not target_by_id.has(bid):
			target_by_id[bid] = []
		target_by_id[bid].append(cell)

	# Build Block nodes for PuzzleSolver
	var blocks: Array[Block] = []
	for entry in _blocks:
		var bd := BlockData.new()
		bd.id = "B%d" % entry["id"]
		bd.dir = entry["dir"]
		bd.origin = entry["origin"]
		var tgts: Array[Vector2i] = []
		if target_by_id.has(entry["id"]):
			tgts.assign(target_by_id[entry["id"]])
		bd.target_origins = tgts

		var block := Block.new()
		block.data = bd
		block.grid_origin = entry["origin"]
		blocks.append(block)

	# Check every block has at least one target
	for block in blocks:
		if block.data.target_origins.is_empty():
			_set_status("Block %s has no target!" % block.data.id)
			for b in blocks:
				b.queue_free()
			return

	var solvable := PuzzleSolver.is_solvable(blocks, board_set, fixed_set, teleport_map)

	for b in blocks:
		b.queue_free()

	if solvable:
		_set_status("Solvable!")
	else:
		_set_status("NOT solvable (within %d moves)" % PuzzleSolver.MAX_DEPTH)


func _quick_play() -> void:
	_reposition()
	Globals.editor_level_data = _to_level_dict()
	Globals.editor_level_number = current_level
	play_pressed.emit()


# ── UI Panel ─────────────────────────────────────────────────────────────────

func _build_panel() -> void:
	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = 10
	add_child(_panel_layer)

	var vp := get_viewport().get_visible_rect().size
	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]
	var bg_col := GameTheme.ACTIVE["background"]
	var safe_bot := GameTheme.get_safe_area_bottom()

	var panel_h := 280.0 + safe_bot
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -panel_h
	var style := StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = text_col
	style.border_color.a = 0.15
	style.border_width_top = 2
	panel.add_theme_stylebox_override("panel", style)
	_panel_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", int(safe_bot) + 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Row 1: Tool buttons (B1-B4)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row1)
	for tool_id in [Tool.BLOCK_1, Tool.BLOCK_2, Tool.BLOCK_3, Tool.BLOCK_4]:
		var btn := _create_tool_button(tool_id, row1)
		_tool_buttons[tool_id] = btn

	# Row 2: Target + Teleport buttons
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row2)
	for tool_id in [Tool.TARGET_1, Tool.TARGET_2, Tool.TARGET_3, Tool.TARGET_4]:
		var btn := _create_tool_button(tool_id, row2)
		_tool_buttons[tool_id] = btn
	# separator
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(16, 0)
	row2.add_child(sep)
	for tool_id in [Tool.TELEPORT_1, Tool.TELEPORT_2, Tool.TELEPORT_3]:
		var btn := _create_tool_button(tool_id, row2)
		_tool_buttons[tool_id] = btn

	# Row 3: Action buttons
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 12)
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row3)

	_create_action_button("Validate", _validate, row3)
	_create_action_button("Save", _save_level, row3)
	_create_action_button("Play", _quick_play, row3)

	# Status label
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_override("font", font)
	_status_label.add_theme_font_size_override("font_size", 28)
	_status_label.add_theme_color_override("font_color", text_col)
	vbox.add_child(_status_label)

	# Instructions label
	var help := Label.new()
	help.text = "WASD: block dir | Ctrl+WASD: add row/col | Shift+WASD: remove row/col | X: deselect | , . : prev/next level"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_override("font", font)
	help.add_theme_font_size_override("font_size", 20)
	var help_col := text_col
	help_col.a = 0.45
	help.add_theme_color_override("font_color", help_col)
	vbox.add_child(help)


func _create_tool_button(tool_id: Tool, parent: Node) -> Button:
	var btn := Button.new()
	btn.text = TOOL_LABELS[tool_id]
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(72, 56)

	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]
	var bg_col := GameTheme.ACTIVE["background"]

	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 26)

	# Color based on type
	var btn_col := _get_tool_color(tool_id)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = btn_col
	normal_style.bg_color.a = 0.2
	normal_style.set_corner_radius_all(10)
	normal_style.set_border_width_all(2)
	normal_style.border_color = btn_col
	normal_style.border_color.a = 0.5

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = btn_col
	pressed_style.set_corner_radius_all(10)
	pressed_style.set_border_width_all(2)
	pressed_style.border_color = btn_col

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", normal_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", normal_style)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_pressed_color", bg_col)

	btn.toggled.connect(func(on: bool) -> void:
		if on:
			_select_tool(tool_id)
		else:
			if _active_tool == tool_id:
				_active_tool = Tool.NONE
	)

	parent.add_child(btn)
	return btn


func _create_action_button(label: String, callback: Callable, parent: Node) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 48)

	var font := GameTheme.FONT_BOLD
	var text_col := GameTheme.ACTIVE["text"]
	var bg_col := GameTheme.ACTIVE["background"]

	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 28)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = text_col
	style.border_color.a = 0.4
	style.content_margin_left = 16
	style.content_margin_right = 16

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_color_override("font_color", text_col)

	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _get_tool_color(tool_id: Tool) -> Color:
	match tool_id:
		Tool.BLOCK_1, Tool.TARGET_1: return GameTheme.ACTIVE["blocks"][0]
		Tool.BLOCK_2, Tool.TARGET_2: return GameTheme.ACTIVE["blocks"][1]
		Tool.BLOCK_3, Tool.TARGET_3: return GameTheme.ACTIVE["blocks"][2]
		Tool.BLOCK_4, Tool.TARGET_4: return GameTheme.ACTIVE["blocks"][3]
		Tool.TELEPORT_1: return GameTheme.ACTIVE["teleport"][0]
		Tool.TELEPORT_2: return GameTheme.ACTIVE["teleport"][1]
		Tool.TELEPORT_3: return GameTheme.ACTIVE["teleport"][2]
	return GameTheme.ACTIVE["text"]


func _select_tool(tool_id: Tool) -> void:
	_active_tool = tool_id
	_tp_pending.clear()
	_set_status("")
	# Unpress all other buttons
	for tid in _tool_buttons:
		if tid != tool_id:
			_tool_buttons[tid].button_pressed = false


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text
