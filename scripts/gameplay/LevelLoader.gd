# =============================================================================
# LevelLoader.gd — Reads level JSON files and parses them into game data
# =============================================================================
# Level format (JSON):
#   "A": [[x,y], [x,y,block_id], ...]  — board squares; 3rd element = target for block_id
#   "B": [{id, dir, origin}, ...]       — movable blocks (dir: "left"/"right"/"up"/"down"/"none")
#   "C": [{id, origin, squares}, ...]   — fixed obstacle blocks (optional)
#   "T": [{id, pos:[ax,ay,bx,by]}, ...] — teleport portal pairs (optional)
#   "message": "..."                     — tutorial text (optional)
# =============================================================================
class_name LevelLoader

const LEVELS_PATH = "res://levels/"
const CHALLENGE_PATH = "res://levels/challenge/"


static func count_levels() -> int:
	var dir := DirAccess.open(LEVELS_PATH)
	if dir == null:
		push_error("LevelLoader: could not open levels directory '%s'" % LEVELS_PATH)
		return 0
	var count := 0
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			count += 1
		fname = dir.get_next()
	dir.list_dir_end()
	return count


static func load_level(level_number: int) -> Dictionary:
	var filename = LEVELS_PATH + "level_%03d.json" % level_number
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		push_error("LevelLoader: could not open '%s' (error %d)" % [filename, FileAccess.get_open_error()])
		return {}
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("LevelLoader: JSON parse error in '%s' at line %d: %s" % [
			filename, json.get_error_line(), json.get_error_message()
		])
		return {}

	return json.get_data()


static func count_challenge_levels() -> int:
	var dir := DirAccess.open(CHALLENGE_PATH)
	if dir == null:
		return 0
	var count := 0
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			count += 1
		fname = dir.get_next()
	dir.list_dir_end()
	return count


static func load_challenge_level(level_number: int) -> Dictionary:
	var filename = CHALLENGE_PATH + "challenge_%03d.json" % level_number
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		push_error("LevelLoader: could not open '%s'" % filename)
		return {}
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("LevelLoader: JSON parse error in '%s'" % filename)
		return {}
	return json.get_data()


static func get_blocks(level_data: Dictionary) -> Array[BlockData]:
	if not level_data.has("B"):
		push_error("LevelLoader: level data missing 'B' array")
		return []
	var blocks: Array[BlockData] = []
	for entry in level_data["B"]:
		blocks.append(BlockData.from_dict(entry))
	return blocks


static func get_fixed_blocks(level_data: Dictionary) -> Array[FixedBlockData]:
	if not level_data.has("C"):
		return []
	var blocks: Array[FixedBlockData] = []
	for entry in level_data["C"]:
		blocks.append(FixedBlockData.from_dict(entry))
	return blocks


static func get_teleports(level_data: Dictionary) -> Array[TeleportData]:
	if not level_data.has("T"):
		return []
	var pairs: Array[TeleportData] = []
	for entry in level_data["T"]:
		pairs.append(TeleportData.from_dict(entry))
	return pairs


static func get_message(level_data: Dictionary) -> String:
	return level_data.get("message", "")


static func get_board_squares(level_data: Dictionary) -> Array[Vector2i]:
	if not level_data.has("A"):
		push_error("LevelLoader: level data missing 'A' array")
		return []
	var squares: Array[Vector2i] = []
	for entry in level_data["A"]:
		squares.append(Vector2i(entry[0], entry[1]))
	return squares


# Extracts target cells from the board data. An A entry with 3 elements
# [x, y, block_id] marks that cell as a target for the given block.
# Returns: { block_id: [Vector2i, ...], ... }
static func get_targets(level_data: Dictionary) -> Dictionary:
	var targets := {}
	if not level_data.has("A"):
		return targets
	for entry in level_data["A"]:
		if entry.size() >= 3:
			var bid := int(entry[2])
			var cell := Vector2i(entry[0], entry[1])
			if not targets.has(bid):
				targets[bid] = []
			targets[bid].append(cell)
	return targets
