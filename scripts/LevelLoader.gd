class_name LevelLoader

const LEVELS_PATH = "res://levels/"


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


static func get_blocks(level_data: Dictionary) -> Array[BlockData]:
	if not level_data.has("B"):
		push_error("LevelLoader: level data missing 'B' array")
		return []
	var blocks: Array[BlockData] = []
	for entry in level_data["B"]:
		blocks.append(BlockData.from_dict(entry))
	return blocks


static func get_board_squares(level_data: Dictionary) -> Array[Vector2i]:
	if not level_data.has("A"):
		push_error("LevelLoader: level data missing 'A' array")
		return []
	var squares: Array[Vector2i] = []
	for entry in level_data["A"]:
		squares.append(Vector2i(entry["pos_x"], entry["pos_y"]))
	return squares
