class_name SaveData

const SAVE_PATH := "user://save.json"


static func get_last_level() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 1
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return 1
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return 1
	var data: Dictionary = json.get_data()
	return data.get("last_level", 1)


static func set_last_level(n: int) -> void:
	var data := {}
	# Load existing data to preserve other fields
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				data = json.get_data()
	data["last_level"] = n
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
