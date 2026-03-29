# =============================================================================
# SaveData.gd — Persistent storage (user://save.json)
# =============================================================================
# Stores player progress (last level) and preferences (music, sfx, haptics).
# All methods are static — no instance needed. Uses a load-merge-save pattern
# to preserve existing fields when writing a single value.
# =============================================================================
class_name SaveData

const SAVE_PATH := "user://save.json"


static func get_progress_level() -> int:
	return _get_int("progress_level", 1)


static func set_progress_level(n: int) -> void:
	_set_field("progress_level", n)


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


# ── Hint system ──────────────────────────────────────────────────────────────

static func get_supporter_purchased() -> bool:
	return _get_bool("supporter_purchased", false)


static func set_supporter_purchased(v: bool) -> void:
	_set_field("supporter_purchased", v)


static func get_hints_remaining() -> int:
	return _get_int("hints_remaining", Globals.FREE_DAILY_HINTS)


static func set_hints_remaining(n: int) -> void:
	_set_field("hints_remaining", n)


static func get_daily_hint_limit() -> int:
	if get_supporter_purchased():
		return Globals.SUPPORTER_DAILY_HINTS
	return Globals.FREE_DAILY_HINTS


## Returns the number of hints consumed on a specific level (0 if none).
## Stored as "hints": [[level, count], [level, count], ...]
static func get_level_hints_used(level: int) -> int:
	var hints := _get_hints_array()
	for entry in hints:
		if int(entry[0]) == level:
			return int(entry[1])
	return 0


## Sets the number of hints consumed on a specific level.
static func set_level_hints_used(level: int, count: int) -> void:
	var hints := _get_hints_array()
	var found := false
	for i in hints.size():
		if int(hints[i][0]) == level:
			hints[i] = [level, count]
			found = true
			break
	if not found:
		hints.append([level, count])
	_set_field("hints", hints)


## Clears hint progress for a level (e.g. on level complete).
static func clear_level_hints(level: int) -> void:
	var hints := _get_hints_array()
	hints = hints.filter(func(entry: Array) -> bool: return int(entry[0]) != level)
	_set_field("hints", hints)


static func _get_hints_array() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return []
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []
	var data: Dictionary = json.get_data()
	var raw = data.get("hints", [])
	if not raw is Array:
		return []
	# Ensure all values are int (JSON deserializes numbers as float)
	var result: Array = []
	for entry in raw:
		if entry is Array and entry.size() >= 2:
			result.append([int(entry[0]), int(entry[1])])
	return result


static func check_and_reset_daily_hints() -> void:
	var today := Time.get_date_string_from_system()
	var last_reset := _get_string("last_hint_reset_date", "")
	var limit := get_daily_hint_limit()
	if last_reset != today:
		_set_field("last_hint_reset_date", today)
		_set_field("hints_remaining", limit)


static func _get_string(key: String, default: String) -> String:
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


# ── Challenge ────────────────────────────────────────────────────────────────

static func get_best_streak() -> int:
	return _get_int("best_streak", 0)


static func set_best_streak(n: int) -> void:
	_set_field("best_streak", n)


static func _get_int(key: String, default: int) -> int:
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
