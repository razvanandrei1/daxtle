# =============================================================================
# Game.gd — Core gameplay controller (orchestrator)
# =============================================================================
# Manages the game board, blocks, teleports, swipe input, and level transitions.
# Delegates animations to GameAnimations, state checks to GameLogic,
# and challenge mode to ChallengeMode.
# =============================================================================
class_name Game
extends Node2D

const BoardScene      := preload("res://scenes/entities/Board.tscn")
const BlockScene      := preload("res://scenes/entities/Block.tscn")
const FixedBlockScene := preload("res://scenes/entities/FixedBlock.tscn")
const TeleportScene      := preload("res://scenes/entities/Teleport.tscn")
const DestroyBlockScene  := preload("res://scenes/entities/DestroyBlock.tscn")
const _MOVE_DURATION_DEFAULT := 0.13  # fallback if no slide SFX loaded
var MOVE_DURATION: float = _MOVE_DURATION_DEFAULT

# --- Game mode ---
enum Mode { CAMPAIGN, CHALLENGE }
var mode: Mode = Mode.CAMPAIGN

# --- Signals communicated to Main.gd via connections ---
signal level_loaded(n: int)
signal menu_pressed
signal message_changed(text: String, board_bottom: float)
signal intro_finished
signal dismiss_message
signal all_levels_completed
signal challenge_game_over(streak: int, best_streak: int)
var _has_message: bool = false

var current_level: int = 20
var _moved: bool = false
var _active: bool = false
var _current_level_data: Dictionary = {}
var value_a: float = 0.0

var _board: Board
var _blocks: Array[Block] = []
var _fixed_blocks: Array[FixedBlock] = []
var _destroy_blocks: Array[DestroyBlock] = []
var _original_destroy_data: Array = []
var _original_blocks_data: Array = []
var _board_set:    Dictionary = {}
var _fixed_set:    Dictionary = {}
var _destroy_set:  Dictionary = {}
var _teleport_map: Dictionary = {}
var _teleports:    Array[Teleport] = []
var _swipe_detector: SwipeDetector

# --- Composition ---
var challenge: ChallengeMode
var anim: GameAnimations
var logic: GameLogic

@onready var _header: SceneHeader = $SceneHeader
@onready var _reset:  ResetIcon   = $ResetIcon


func _process(delta: float) -> void:
	if mode != Mode.CHALLENGE:
		return
	challenge.process(delta)


func _draw() -> void:
	if mode != Mode.CHALLENGE:
		return
	challenge.draw()


func _ready() -> void:
	# Match slide animation duration to the slide sound effect
	var sfx_dur := AudioManager.get_sfx_duration("slide")
	if sfx_dur > 0.0:
		MOVE_DURATION = sfx_dur

	challenge = ChallengeMode.new(self)
	anim = GameAnimations.new(self)
	logic = GameLogic.new(self)

	_swipe_detector = $SwipeDetector
	_swipe_detector.swiped.connect(_on_swipe)
	_swipe_detector.double_tapped.connect(func() -> void:
		if _active and _moved and mode != Mode.CHALLENGE:
			reset_level()
	)

	_header.back_pressed.connect(func() -> void: menu_pressed.emit())
	_reset.pressed.connect(func() -> void:
		if mode != Mode.CHALLENGE:
			reset_level()
	)
	_reset.position = Vector2(_header.right_x, _header.bar_cy)
	_reset.visible = false


func set_level(n: int) -> void:
	if mode == Mode.CHALLENGE:
		_header.set_title("%d" % challenge.streak)
	else:
		_header.set_title("%d" % n)
	_reset.visible = false


func show_reset() -> void:
	anim.show_reset()


func _hide_reset() -> void:
	if _reset.visible:
		var tween := create_tween()
		tween.tween_property(_reset, "scale", Vector2.ZERO, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.finished.connect(func() -> void:
			_reset.visible = false
		)


func load_level(n: int) -> void:
	_load_level(n)


func start_challenge() -> void:
	mode = Mode.CHALLENGE
	challenge.start()


func _load_level_data(level_data: Dictionary) -> void:
	_current_level_data = level_data
	anim.kill_intro_tweens()

	if _board:
		_board.queue_free()
	_blocks.clear()
	_fixed_blocks.clear()
	_destroy_blocks.clear()
	_teleports.clear()
	_board_set.clear()
	_fixed_set.clear()
	_destroy_set.clear()
	_teleport_map.clear()

	var squares := LevelLoader.get_board_squares(level_data)
	_board = BoardScene.instantiate() as Board
	add_child(_board)
	value_a = _board.setup(squares)

	for sq in squares:
		_board_set[sq] = true

	var fixed_data := LevelLoader.get_fixed_blocks(level_data)
	for fd in fixed_data:
		var fb := FixedBlockScene.instantiate() as FixedBlock
		_board.add_child(fb)
		fb.setup(fd, value_a, _board)
		_fixed_blocks.append(fb)
		for cell in fd.cells():
			_fixed_set[cell] = true

	var destroy_data := LevelLoader.get_destroy_blocks(level_data)
	_original_destroy_data = destroy_data.duplicate()
	for dd in destroy_data:
		var db := DestroyBlockScene.instantiate() as DestroyBlock
		_board.add_child(db)
		db.setup(dd, value_a, _board)
		_destroy_blocks.append(db)
		_destroy_set[dd.origin] = db

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
			tp.setup(cell, value_a, _board, pair_col)
			_teleports.append(tp)

	var blocks_data := LevelLoader.get_blocks(level_data)
	var targets     := LevelLoader.get_targets(level_data)
	for bd in blocks_data:
		var block_num := int(bd.id.substr(1)) if bd.id is String else int(bd.id)
		if targets.has(block_num):
			bd.target_origins.assign(targets[block_num])
	_original_blocks_data = blocks_data.duplicate()
	_board.set_targets(blocks_data)
	for block_data in blocks_data:
		var block := BlockScene.instantiate() as Block
		_board.add_child(block)
		block.setup(block_data, value_a, _board)
		_blocks.append(block)

	_moved = false
	_active = true
	level_loaded.emit(current_level)
	var mn_y := _board.board_squares[0].y
	var mx_y := mn_y
	for sq in _board.board_squares:
		mn_y = mini(mn_y, sq.y)
		mx_y = maxi(mx_y, sq.y)
	var board_bottom := _board.position.y + (mx_y - mn_y + 1) * value_a
	var msg := LevelLoader.get_message(level_data)
	_has_message = not msg.is_empty()
	message_changed.emit(msg, board_bottom)
	queue_redraw()
	anim.play_intro()


func stop() -> void:
	_active = false
	if mode == Mode.CHALLENGE:
		challenge.timer_active = false
		challenge.timer_alpha = 0.0
		challenge.time_left = 0.0
	queue_redraw()
	_swipe_detector.enabled = false
	anim.kill_intro_tweens()


# --- Swipe handling ---
func _on_swipe(direction: String) -> void:
	if not _active:
		return
	var candidates: Array[Block] = []
	for block in _blocks:
		if block.data.dir == direction:
			candidates.append(block)

	if candidates.is_empty():
		return

	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)

	var result            := Movement.resolve(candidates, _blocks, _board_set, direction, _fixed_set, _teleport_map)
	var movers:            Array[Block] = result["movers"]
	var invalid:           Array[Block] = result["invalid"]
	var teleport_exits:    Dictionary   = result["teleport_exits"]
	var teleport_entries:  Dictionary   = result["teleport_entries"]

	var filtered_invalid: Array[Block] = []
	for block in invalid:
		if not block.data.target_origins.has(block.grid_origin):
			filtered_invalid.append(block)
	invalid = filtered_invalid

	if movers.is_empty() and invalid.is_empty():
		return

	# Debug: log movers landing on a target
	for block in movers:
		var landing: Vector2i
		if teleport_exits.has(block):
			landing = teleport_exits[block]
		else:
			landing = block.grid_origin + dv
		if block.data.target_origins.has(landing):
			var block_col := BlockColors.get_color(block.data.id)
			var target_col := BlockColors.get_target_color(block.data.id)
			var match := block_col == target_col
			print("B%s → %s | color=%s target_color=%s match=%s ✓" % [block.data.id, landing, block_col, target_col, match])

	if not _moved:
		_moved = true
		show_reset()

	_swipe_detector.enabled = false

	if not movers.is_empty():
		AudioManager.play_sfx("slide")
		Haptics.tap()
		var par := create_tween().set_parallel(true)
		var has_teleport := false
		var max_tp_dur   := 0.0

		for block in movers:
			if teleport_exits.has(block):
				has_teleport = true

				var entry:     Vector2i = teleport_entries[block]
				var exit_cell: Vector2i = _teleport_map[entry]
				var entry_pos := _board.grid_to_local(entry)
				var exit_pos  := _board.grid_to_local(exit_cell)

				block.grid_origin = teleport_exits[block]
				var final_pos := _board.grid_to_local(block.grid_origin)
				var has_cont  := (final_pos != exit_pos)

				const SHRINK := 0.14
				const POP    := 0.18
				var tp := create_tween()
				tp.tween_property(block, "position", entry_pos, MOVE_DURATION) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tp.tween_method(func(v: float) -> void: block.block_scale = v,
					1.0, 0.0, SHRINK) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tp.tween_callback(func() -> void:
					block.position = exit_pos
					anim.pulse_portal_pair(entry, exit_cell)
				)
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
			anim.handle_destroy_collisions(func() -> void:
				if logic.check_win():
					_on_win()
				elif logic.is_stuck():
					_on_stuck()
				elif mode == Mode.CHALLENGE and not logic.is_winnable():
					_on_stuck()
				else:
					_swipe_detector.enabled = true
			)

		if has_teleport:
			var total_dur := maxf(max_tp_dur, MOVE_DURATION)
			get_tree().create_timer(total_dur).timeout.connect(on_done)
		else:
			par.finished.connect(on_done)

	if not invalid.is_empty():
		anim.shake_blocks(invalid, direction, movers.is_empty())


# Called when no block can move or position is no longer winnable.
func _on_stuck() -> void:
	_swipe_detector.enabled = false
	if mode == Mode.CHALLENGE:
		challenge.fade_out_timer()
	Haptics.fail()
	AudioManager.play_sfx("invalid")

	var origin := _board.position
	var s      := value_a * 0.06

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_board, "position", origin + Vector2( s,       0), 0.08)
	tween.tween_property(_board, "position", origin + Vector2(-s,       0), 0.09)
	tween.tween_property(_board, "position", origin + Vector2( s * 0.5, 0), 0.08)
	tween.tween_property(_board, "position", origin + Vector2(-s * 0.5, 0), 0.08)
	tween.tween_property(_board, "position", origin,                        0.09)

	tween.finished.connect(func() -> void:
		await get_tree().create_timer(0.25).timeout
		if _active:
			if mode == Mode.CHALLENGE:
				_active = false
				var best := SaveData.get_best_streak()
				if challenge.streak > best:
					SaveData.set_best_streak(challenge.streak)
					best = challenge.streak
				challenge_game_over.emit(challenge.streak, best)
			else:
				reset_level()
	)


func _on_win() -> void:
	anim.play_win()


func reset_level() -> void:
	AudioManager.play_sfx("reset")
	_swipe_detector.enabled = false
	_moved = false
	level_loaded.emit(current_level)

	# Restore consumed D blocks
	if _original_destroy_data.size() > _destroy_blocks.size():
		var existing_origins: Dictionary = {}
		for db in _destroy_blocks:
			existing_origins[db.grid_origin] = true
		for dd in _original_destroy_data:
			if not existing_origins.has(dd.origin):
				var db := DestroyBlockScene.instantiate() as DestroyBlock
				_board.add_child(db)
				db.setup(dd, value_a, _board)
				db.block_scale = 0.0
				_destroy_blocks.append(db)
				_destroy_set[dd.origin] = db

	# Restore destroyed B blocks
	if _original_blocks_data.size() > _blocks.size():
		var existing_blocks: Dictionary = {}
		for block in _blocks:
			existing_blocks[block.data.origin] = true
		for block_data in _original_blocks_data:
			if not existing_blocks.has(block_data.origin):
				var block := BlockScene.instantiate() as Block
				_board.add_child(block)
				block.setup(block_data, value_a, _board)
				block.block_scale = 0.0
				_blocks.append(block)

	# Slide all B blocks back to their starting positions
	var slide := create_tween().set_parallel(true)
	for block in _blocks:
		block.grid_origin = block.data.origin
		var target_pos := _board.grid_to_local(block.grid_origin)
		if block.block_scale < 1.0:
			block.position = target_pos
		else:
			slide.tween_property(block, "position", target_pos, MOVE_DURATION * 2.5) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	slide.finished.connect(func() -> void:
		for db in _destroy_blocks:
			if db.block_scale < 1.0:
				var pop := create_tween()
				pop.tween_method(func(v: float) -> void: db.block_scale = v,
					0.0, 1.0, 0.2) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for block in _blocks:
			if block.block_scale < 1.0:
				var pop := create_tween()
				pop.tween_method(func(v: float) -> void: block.block_scale = v,
					0.0, 1.0, 0.2) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_swipe_detector.enabled = true
	)


func go_next_level() -> void:
	_load_level(clamp(current_level + 1, 1, LevelLoader.count_levels()))


func go_prev_level() -> void:
	_load_level(clamp(current_level - 1, 1, LevelLoader.count_levels()))


func _load_level(level_number: int) -> void:
	var level_data := LevelLoader.load_level(level_number)
	if level_data.is_empty():
		push_error("Game: failed to load level %d" % level_number)
		return
	current_level = level_number
	_load_level_data(level_data)
