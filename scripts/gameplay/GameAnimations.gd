# =============================================================================
# GameAnimations.gd — All gameplay animation sequences
# =============================================================================
class_name GameAnimations
extends RefCounted

const WIN_BRIGHT := Color(1.5, 1.5, 1.5, 1.0)
const WIN_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const WIN_FADE   := Color(1.0, 1.0, 1.0, 0.0)

const _INTRO_CHAIN_DELAY   := 0.10
const _INTRO_CHAIN_TOTAL   := 0.72
const _INTRO_CHAIN_SCALE   := 0.66
const _INTRO_STAGGER       := 0.09
const _INTRO_SLIDE_DUR     := 0.36
const _INTRO_ARROW_DUR     := 0.10
const _INTRO_HOLD          := 0.20

var game: Game
var _intro_tweens: Array[Tween] = []


func _init(g: Game) -> void:
	game = g


func kill_intro_tweens() -> void:
	for tw in _intro_tweens:
		if tw:
			tw.kill()
	_intro_tweens.clear()


# --- Intro animation ---

func play_intro() -> void:
	game._swipe_detector.enabled = false

	var sorted_squares := game._board.board_squares.duplicate()
	sorted_squares.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x + a.y) < (b.x + b.y)
	)
	var n := sorted_squares.size()
	var stagger := _INTRO_CHAIN_TOTAL / maxi(n - 1, 1)
	for i in n:
		var sq: Vector2i = sorted_squares[i]
		game._board.set_cell_scale(sq, 0.0)
		var delay := _INTRO_CHAIN_DELAY + i * stagger
		var t     := game.create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: game._board.set_cell_scale(sq, v),
			0.0, 1.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Fixed blocks (C) scale in during the same wave
	for fb in game._fixed_blocks:
		fb.block_scale = 0.0
		var fb_diag := fb.data.origin.x + fb.data.origin.y
		for sq in fb.data.squares:
			var cell := fb.data.origin + sq
			fb_diag = mini(fb_diag, cell.x + cell.y)
		var wave_index := 0
		for j in sorted_squares.size():
			if (sorted_squares[j].x + sorted_squares[j].y) <= fb_diag:
				wave_index = j
		var delay := _INTRO_CHAIN_DELAY + wave_index * stagger
		var captured_fb := fb
		var t := game.create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: captured_fb.block_scale = v,
			0.0, 1.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Destroy blocks scale in during the same wave
	for db in game._destroy_blocks:
		db.block_scale = 0.0
		var db_diag := db.grid_origin.x + db.grid_origin.y
		var wave_index := 0
		for j in sorted_squares.size():
			if (sorted_squares[j].x + sorted_squares[j].y) <= db_diag:
				wave_index = j
		var delay := _INTRO_CHAIN_DELAY + wave_index * stagger
		var captured_db := db
		var t := game.create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: captured_db.block_scale = v,
			0.0, 1.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Teleport portals scale in during the same wave
	for tp in game._teleports:
		tp.block_scale = 0.0
		var diag := tp.portal_cell.x + tp.portal_cell.y
		var wave_index := 0
		for j in sorted_squares.size():
			if (sorted_squares[j].x + sorted_squares[j].y) <= diag:
				wave_index = j
		var delay      := _INTRO_CHAIN_DELAY + wave_index * stagger
		var captured   := tp
		var t          := game.create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			0.0, 1.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Blocks scale up after the chain finishes
	var chain_end := _INTRO_CHAIN_DELAY + _INTRO_CHAIN_TOTAL + _INTRO_CHAIN_SCALE

	for i in game._blocks.size():
		var block := game._blocks[i]
		block.block_scale = 0.0
		block.arrow_alpha = 0.0

		var delay := chain_end + i * _INTRO_STAGGER
		var t     := game.create_tween()
		_intro_tweens.append(t)
		t.tween_method(func(v: float) -> void: block.block_scale = v,
			0.0, 1.0, _INTRO_SLIDE_DUR) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_method(func(v: float) -> void: block.arrow_alpha = v,
			0.0, 1.0, _INTRO_ARROW_DUR) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Enable input once all animations have finished
	var total := chain_end \
		+ maxi(game._blocks.size() - 1, 0) * _INTRO_STAGGER \
		+ _INTRO_SLIDE_DUR + _INTRO_ARROW_DUR + _INTRO_HOLD

	game.get_tree().create_timer(total).timeout.connect(func() -> void:
		if not game._active:
			return
		game._swipe_detector.enabled = true
		if game.mode == Game.Mode.CHALLENGE:
			game.challenge.start_timer()
		game.intro_finished.emit()
	)


# --- Exit chain animation ---

func play_exit_chain() -> void:
	var sorted_squares := game._board.board_squares.duplicate()
	sorted_squares.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x + a.y) > (b.x + b.y)
	)
	var n       := sorted_squares.size()
	var stagger := _INTRO_CHAIN_TOTAL / maxi(n - 1, 1)

	for i in n:
		var sq: Vector2i = sorted_squares[i]
		var delay := i * stagger
		var t := game.create_tween()
		t.tween_method(func(v: float) -> void: game._board.set_cell_scale(sq, v),
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	for block in game._blocks:
		var diag := block.grid_origin.x + block.grid_origin.y
		var wave_index := 0
		for j in n:
			if (sorted_squares[j].x + sorted_squares[j].y) >= diag:
				wave_index = j
		var delay := wave_index * stagger
		var captured := block
		var t := game.create_tween()
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	for fb in game._fixed_blocks:
		var fb_diag := fb.data.origin.x + fb.data.origin.y
		for sq in fb.data.squares:
			var cell := fb.data.origin + sq
			fb_diag = maxi(fb_diag, cell.x + cell.y)
		var wave_index := 0
		for j in n:
			if (sorted_squares[j].x + sorted_squares[j].y) >= fb_diag:
				wave_index = j
		var delay := wave_index * stagger
		var captured := fb
		var t := game.create_tween()
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	for tp in game._teleports:
		var diag := tp.portal_cell.x + tp.portal_cell.y
		var wave_index := 0
		for j in n:
			if (sorted_squares[j].x + sorted_squares[j].y) >= diag:
				wave_index = j
		var delay := wave_index * stagger
		var captured := tp
		var t := game.create_tween()
		t.tween_method(func(v: float) -> void: captured.block_scale = v,
			1.0, 0.0, _INTRO_CHAIN_SCALE) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	var total := _INTRO_CHAIN_TOTAL + _INTRO_CHAIN_SCALE + 0.15
	game.get_tree().create_timer(total).timeout.connect(func() -> void:
		if game._active:
			if game.mode == Game.Mode.CHALLENGE:
				game.challenge.streak += 1
				if game.challenge.streak > SaveData.get_best_streak():
					SaveData.set_best_streak(game.challenge.streak)
				game.challenge.load_next()
			elif game.current_level >= LevelLoader.count_levels():
				game.all_levels_completed.emit()
			else:
				game._load_level(game.current_level + 1)
	)


# --- Shake blocks ---

func shake_blocks(blocks: Array[Block], direction: String, re_enable_after: bool) -> void:
	AudioManager.play_sfx("invalid")
	var dv := Vector2i.ZERO
	match direction:
		"right": dv = Vector2i( 1,  0)
		"left":  dv = Vector2i(-1,  0)
		"down":  dv = Vector2i( 0,  1)
		_:       dv = Vector2i( 0, -1)

	var nudge    := Vector2(dv) * game.value_a * 0.18
	var duration := game.MOVE_DURATION

	var tween := game.create_tween().set_parallel(true)
	for block in blocks:
		var origin_pos := block.position
		tween.tween_property(block, "position", origin_pos + nudge, duration * 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(block, "position", origin_pos, duration * 0.85) \
			.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT) \
			.set_delay(duration * 0.45)

	tween.finished.connect(func() -> void:
		if re_enable_after:
			game._swipe_detector.enabled = true
	)


# --- Destroy collisions ---

func handle_destroy_collisions(on_done: Callable) -> void:
	var to_destroy_blocks: Array[Block] = []
	var to_destroy_dbs: Array[DestroyBlock] = []

	for block in game._blocks:
		if game._destroy_set.has(block.grid_origin):
			to_destroy_blocks.append(block)
			to_destroy_dbs.append(game._destroy_set[block.grid_origin])

	if to_destroy_blocks.is_empty():
		on_done.call()
		return

	const FLASH_DUR := 0.10
	const DESTROY_DUR := 0.18

	for db in to_destroy_dbs:
		game._destroy_blocks.erase(db)
		game._destroy_set.erase(db.grid_origin)
		db.queue_free()

	game.get_tree().create_timer(0.18).timeout.connect(func() -> void:
		AudioManager.play_sfx("destroy")
	)

	var flash := game.create_tween()
	flash.tween_method(func(v: float) -> void:
		for block in to_destroy_blocks:
			block.modulate.a = v,
		1.0, 0.0, FLASH_DUR) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flash.tween_method(func(v: float) -> void:
		for block in to_destroy_blocks:
			block.modulate.a = v,
		0.0, 1.0, FLASH_DUR) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	flash.finished.connect(func() -> void:
		var anim := game.create_tween()
		anim.tween_method(func(v: float) -> void:
			for block in to_destroy_blocks:
				block.block_scale = v,
			1.0, 1.15, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		anim.tween_method(func(v: float) -> void:
			for block in to_destroy_blocks:
				block.block_scale = v,
			1.15, 0.0, DESTROY_DUR) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		anim.finished.connect(func() -> void:
			for block in to_destroy_blocks:
				game._blocks.erase(block)
				block.queue_free()
			on_done.call()
		)
	)


# --- Portal pulse ---

func pulse_portal_pair(entry: Vector2i, exit_cell: Vector2i) -> void:
	AudioManager.play_sfx("teleport")
	for tp in game._teleports:
		if tp.portal_cell == entry or tp.portal_cell == exit_cell:
			var t := game.create_tween()
			t.tween_property(tp, "modulate:a", 0.0, 0.10) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t.tween_property(tp, "modulate:a", 1.0, 0.14) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# --- Win sequence ---

func play_win() -> void:
	game._swipe_detector.enabled = false
	if game.mode == Game.Mode.CHALLENGE:
		game.challenge.fade_out_timer()
	AudioManager.play_sfx("win")
	game._hide_reset()

	# Advance progress if this is the furthest level completed (campaign only)
	if game.mode == Game.Mode.CAMPAIGN:
		var next := game.current_level + 1
		if next > SaveData.get_progress_level():
			SaveData.set_progress_level(next)

	if game._has_message:
		game.dismiss_message.emit()

	Haptics.win()
	# Hide targets, A cells under B blocks, and teleports before the flash
	game._board.clear_targets()
	for block in game._blocks:
		game._board.set_cell_scale(block.grid_origin, 0.0)
	for tp in game._teleports:
		tp.visible = false
	for db in game._destroy_blocks:
		db.visible = false

	# Shrink arrows on B blocks, then flash
	var arrow_shrink := game.create_tween().set_parallel(true)
	for block in game._blocks:
		arrow_shrink.tween_method(func(v: float) -> void: block.arrow_scale = v,
			1.0, 0.0, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	arrow_shrink.finished.connect(func() -> void:
		var flash := game.create_tween().set_parallel(true)
		for block in game._blocks:
			flash.tween_property(block, "modulate:a", 0.0, 0.15) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			flash.tween_property(block, "modulate:a", 1.0, 0.20).set_delay(0.20) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flash.tween_property(block, "modulate:a", 0.0, 0.15).set_delay(0.43) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			flash.tween_property(block, "modulate:a", 1.0, 0.20).set_delay(0.63) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		flash.finished.connect(func() -> void:
			play_exit_chain()
		)
	)


# --- Reset icon ---

func show_reset() -> void:
	if game.mode == Game.Mode.CHALLENGE:
		return
	if not game._reset.visible:
		game._reset.visible = true
		game._reset.scale = Vector2.ZERO
		var tween := game.create_tween()
		tween.tween_property(game._reset, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
