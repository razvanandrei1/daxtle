# =============================================================================
# GameLogic.gd — Pure state queries (win, stuck, winnable)
# =============================================================================
class_name GameLogic
extends RefCounted

var game: Game


func _init(g: Game) -> void:
	game = g


## Returns true if every block is sitting on one of its target cells.
func check_win() -> bool:
	for block in game._blocks:
		if not block.data.target_origins.has(block.grid_origin):
			return false
	return true


## Returns true if no block can move in any direction from the current state.
func is_stuck() -> bool:
	for dir in ["left", "right", "up", "down"]:
		var candidates: Array[Block] = []
		for block in game._blocks:
			if block.data.dir == dir:
				candidates.append(block)
		if candidates.is_empty():
			continue
		var result := Movement.resolve(candidates, game._blocks, game._board_set, dir, game._fixed_set, game._teleport_map)
		if not (result["movers"] as Array[Block]).is_empty():
			return false
	return true


## Returns true if the current board state can still be solved (BFS check).
func is_winnable() -> bool:
	return PuzzleSolver.is_solvable(game._blocks, game._board_set, game._fixed_set, game._teleport_map, game._destroy_set)


## Returns the next optimal swipe direction, or "" if no solution exists.
func get_hint_direction() -> String:
	var solution := PuzzleSolver.solve(
		game._blocks, game._board_set, game._fixed_set,
		game._teleport_map, game._destroy_set
	)
	if solution.is_empty():
		return ""
	return solution[0]
