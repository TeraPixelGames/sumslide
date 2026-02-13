extends Node

const SAVE_PATH := "user://sumslide_save.json"

var _data: Dictionary = {}

var settings: Dictionary:
	get:
		return _data.get("settings", {})


func _ready() -> void:
	load_data()


func load_data() -> void:
	_data = _default_data().duplicate(true)
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	_ensure_defaults()
	_save()


func get_high_score(mode_id: String) -> int:
	_ensure_mode(mode_id)
	var modes: Dictionary = _data.get("modes", {})
	var mode_data: Dictionary = modes.get(mode_id, {})
	return int(mode_data.get("high_score", 0))


func set_high_score(mode_id: String, score: int) -> void:
	_ensure_mode(mode_id)
	var modes: Dictionary = _data.get("modes", {})
	var mode_data: Dictionary = modes.get(mode_id, {})
	mode_data["high_score"] = max(score, int(mode_data.get("high_score", 0)))
	modes[mode_id] = mode_data
	_data["modes"] = modes
	_save()


func increment_games_played(mode_id: String) -> void:
	_ensure_mode(mode_id)
	var modes: Dictionary = _data.get("modes", {})
	var mode_data: Dictionary = modes.get(mode_id, {})
	mode_data["games_played"] = int(mode_data.get("games_played", 0)) + 1
	modes[mode_id] = mode_data
	_data["modes"] = modes
	_save()


func get_games_played(mode_id: String) -> int:
	_ensure_mode(mode_id)
	var modes: Dictionary = _data.get("modes", {})
	var mode_data: Dictionary = modes.get(mode_id, {})
	return int(mode_data.get("games_played", 0))


func get_sound_on() -> bool:
	var settings_dict: Dictionary = _data.get("settings", {})
	return bool(settings_dict.get("sound_on", true))


func set_sound_on(enabled: bool) -> void:
	var settings_dict: Dictionary = _data.get("settings", {})
	settings_dict["sound_on"] = enabled
	_data["settings"] = settings_dict
	_save()


func _default_data() -> Dictionary:
	return {
		"modes": {
			"sumslide": {
				"high_score": 0,
				"games_played": 0
			}
		},
		"settings": {
			"sound_on": true
		}
	}


func _ensure_defaults() -> void:
	if not (_data is Dictionary):
		_data = _default_data().duplicate(true)
		return

	if not _data.has("modes") or not (_data["modes"] is Dictionary):
		_data["modes"] = {}
	_ensure_mode("sumslide")

	if not _data.has("settings") or not (_data["settings"] is Dictionary):
		_data["settings"] = {}
	var settings_dict: Dictionary = _data["settings"]
	settings_dict["sound_on"] = bool(settings_dict.get("sound_on", true))
	_data["settings"] = settings_dict


func _ensure_mode(mode_id: String) -> void:
	var modes: Dictionary = _data.get("modes", {})
	if not modes.has(mode_id) or not (modes[mode_id] is Dictionary):
		modes[mode_id] = {
			"high_score": 0,
			"games_played": 0
		}
	else:
		var mode_data: Dictionary = modes[mode_id]
		mode_data["high_score"] = int(mode_data.get("high_score", 0))
		mode_data["games_played"] = int(mode_data.get("games_played", 0))
		modes[mode_id] = mode_data
	_data["modes"] = modes


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data, "\t"))
