# =============================================================================
# ChallengeMode.gd — Challenge mode state, timer, pools, and drawing
# =============================================================================
class_name ChallengeMode
extends RefCounted

const TIME_START := 30.0   # seconds for first puzzle
const TIME_DECAY := 1.5    # seconds removed per streak point
const TIME_MIN   := 10.0   # minimum time allowed
const POOL_RATIO := 0.4    # fraction of easy/medium pool used as streak threshold

var game: Game

var streak: int = 0
var time_left: float = 0.0
var time_max:  float = 0.0
var timer_active: bool = false
var timer_alpha: float = 0.5

var _pool_easy:   Array[int] = []
var _pool_medium: Array[int] = []
var _pool_hard:   Array[int] = []


func _init(g: Game) -> void:
	game = g


func process(delta: float) -> void:
	if not timer_active:
		return
	time_left -= delta
	game.queue_redraw()
	if time_left <= 0.0:
		time_left = 0.0
		timer_active = false
		game._on_stuck()


func draw() -> void:
	var vp := game.get_viewport().get_visible_rect().size

	# Timer — rounded frame around the board that shrinks from a corner
	if timer_alpha > 0.0 and game._board:
		var ratio := clampf(time_left / time_max, 0.0, 1.0)
		if ratio > 0.0:
			var timer_col := GameTheme.ACTIVE["text"]
			timer_col.a = timer_alpha
			_draw_timer_frame(ratio, timer_col)

	# Best streak text at bottom
	var font := GameTheme.FONT_BOLD
	var best := maxi(SaveData.get_best_streak(), streak)
	var text := "Best: %d" % best
	var fs := 42
	var col := GameTheme.ACTIVE["text"]
	col.a = 0.5
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var safe_bot := GameTheme.get_safe_area_bottom()
	var y := vp.y - maxf(safe_bot, 40.0) - 20.0
	game.draw_string(font, Vector2((vp.x - tw) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_timer_frame(ratio: float, col: Color) -> void:
	var value_a := game.value_a
	var _board := game._board

	var padding := value_a * 0.14
	var mn := _board.board_squares[0]
	var mx := mn
	for sq in _board.board_squares:
		mn = Vector2i(mini(mn.x, sq.x), mini(mn.y, sq.y))
		mx = Vector2i(maxi(mx.x, sq.x), maxi(mx.y, sq.y))
	var cols_count := mx.x - mn.x + 1
	var rows_count := mx.y - mn.y + 1

	var rect_pos := _board.position - Vector2(padding, padding)
	var rect_size := Vector2(cols_count, rows_count) * value_a + Vector2(padding * 2, padding * 2)
	var r := value_a * GameTheme.CORNER_FRACTION * 2.0
	r = minf(r, minf(rect_size.x, rect_size.y) * 0.5)

	# Generate points along the rounded rect (clockwise from top-center)
	var pts := PackedVector2Array()
	var x0 := rect_pos.x
	var y0 := rect_pos.y
	var x1 := rect_pos.x + rect_size.x
	var y1 := rect_pos.y + rect_size.y
	var cx := (x0 + x1) * 0.5
	var arc_steps := 8

	pts.append(Vector2(cx, y0))
	pts.append(Vector2(x1 - r, y0))
	for i in arc_steps + 1:
		var a := -PI * 0.5 + float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x1 - r + cos(a) * r, y0 + r + sin(a) * r))
	pts.append(Vector2(x1, y1 - r))
	for i in arc_steps + 1:
		var a := float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x1 - r + cos(a) * r, y1 - r + sin(a) * r))
	pts.append(Vector2(x0 + r, y1))
	for i in arc_steps + 1:
		var a := PI * 0.5 + float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x0 + r + cos(a) * r, y1 - r + sin(a) * r))
	pts.append(Vector2(x0, y0 + r))
	for i in arc_steps + 1:
		var a := PI + float(i) / float(arc_steps) * PI * 0.5
		pts.append(Vector2(x0 + r + cos(a) * r, y0 + r + sin(a) * r))
	pts.append(Vector2(cx, y0))

	# Calculate cumulative distances
	var total_len := 0.0
	var lengths := PackedFloat32Array()
	lengths.append(0.0)
	for i in range(1, pts.size()):
		total_len += pts[i].distance_to(pts[i - 1])
		lengths.append(total_len)

	# Draw only the portion corresponding to ratio
	var draw_len := total_len * ratio
	var draw_pts := PackedVector2Array()
	for i in pts.size():
		if lengths[i] <= draw_len:
			draw_pts.append(pts[i])
		else:
			if i > 0:
				var seg_len := lengths[i] - lengths[i - 1]
				if seg_len > 0:
					var t := (draw_len - lengths[i - 1]) / seg_len
					draw_pts.append(pts[i - 1].lerp(pts[i], t))
			break

	if draw_pts.size() >= 2:
		var width := value_a * 0.055
		var draw_col := col
		if time_left < 5.0 and timer_active:
			draw_col = GameTheme.ACTIVE["blocks"][1]
			var flash := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
			draw_col.a = lerpf(0.3, col.a, flash)
		game.draw_polyline(draw_pts, draw_col, width, true)


func start_timer() -> void:
	time_max = maxf(TIME_START - streak * TIME_DECAY, TIME_MIN)
	time_left = time_max
	timer_alpha = 0.0
	timer_active = true
	var fade_in := game.create_tween()
	fade_in.tween_method(func(v: float) -> void:
		timer_alpha = v
		game.queue_redraw()
	, 0.0, 0.5, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func fade_out_timer() -> void:
	timer_active = false
	var fade := game.create_tween()
	fade.tween_method(func(v: float) -> void:
		timer_alpha = v
		game.queue_redraw()
	, timer_alpha, 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func start() -> void:
	streak = 0
	timer_active = false
	timer_alpha = 0.0
	time_left = 0.0
	game.queue_redraw()
	_build_pools()
	load_next()


func _build_pools() -> void:
	_pool_easy.clear()
	_pool_medium.clear()
	_pool_hard.clear()
	for i in LevelLoader.count_challenge_easy():
		_pool_easy.append(i + 1)
	for i in LevelLoader.count_challenge_medium():
		_pool_medium.append(i + 1)
	for i in LevelLoader.count_challenge_hard():
		_pool_hard.append(i + 1)
	_pool_easy.shuffle()
	_pool_medium.shuffle()
	_pool_hard.shuffle()


func _pick_from_pool(pool: Array[int]) -> int:
	if pool.is_empty():
		return -1
	return pool.pop_back()


func _pick_challenge() -> Dictionary:
	var easy_threshold  := int(LevelLoader.count_challenge_easy() * POOL_RATIO)
	var medium_threshold := easy_threshold + int(LevelLoader.count_challenge_medium() * POOL_RATIO)
	var tier := 2
	var n := -1

	if streak < easy_threshold:
		tier = 1; n = _pick_from_pool(_pool_easy)
		if n == -1:
			tier = 2; n = _pick_from_pool(_pool_medium)
	elif streak < medium_threshold:
		tier = 2; n = _pick_from_pool(_pool_medium)
		if n == -1:
			tier = 3; n = _pick_from_pool(_pool_hard)
	else:
		tier = 3; n = _pick_from_pool(_pool_hard)
		if n == -1:
			tier = 2; n = _pick_from_pool(_pool_medium)

	# Fallback: any non-empty pool
	if n == -1:
		var pools: Array[Array] = [_pool_easy, _pool_medium, _pool_hard]
		for t in [1, 2, 3]:
			if not pools[t - 1].is_empty():
				tier = t; n = _pick_from_pool(pools[t - 1])
				break

	# Hard pool exhausted — reshuffle hard only
	if n == -1:
		_pool_hard.clear()
		for i in LevelLoader.count_challenge_hard():
			_pool_hard.append(i + 1)
		_pool_hard.shuffle()
		tier = 3; n = _pick_from_pool(_pool_hard)

	if n == -1:
		return {}
	return {"n": n, "tier": tier}


func load_next() -> void:
	var pick := _pick_challenge()
	if pick.is_empty():
		return
	var level_data: Dictionary
	match pick["tier"]:
		1: level_data = LevelLoader.load_challenge_easy(pick["n"])
		2: level_data = LevelLoader.load_challenge_medium(pick["n"])
		3: level_data = LevelLoader.load_challenge_hard(pick["n"])
	if level_data.is_empty():
		return
	game._load_level_data(level_data)
