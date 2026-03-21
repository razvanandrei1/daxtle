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


static func get_music_enabled() -> bool:
	return _get_bool("music_enabled", true)


static func set_music_enabled(on: bool) -> void:
	_set_field("music_enabled", on)


static func get_sfx_enabled() -> bool:
	return _get_bool("sfx_enabled", true)


static func set_sfx_enabled(on: bool) -> void:
	_set_field("sfx_enabled", on)


static func get_haptics_enabled() -> bool:
	return _get_bool("haptics_enabled", true)


static func set_haptics_enabled(on: bool) -> void:
	_set_field("haptics_enabled", on)


static func _get_bool(key: String, default: bool) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return default
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return default
	var data: Dictionary = json.get_data()
	return data.get(key, default)


static func _set_field(key: String, value: Variant) -> void:
	var data := {}
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				data = json.get_data()
	data[key] = value
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
