extends Node

var _is_playing := false


func start_music() -> void:
	_is_playing = SaveStore.get_sound_on()


func stop_music() -> void:
	_is_playing = false


func set_enabled(enabled: bool) -> void:
	SaveStore.set_sound_on(enabled)
	if enabled:
		start_music()
	else:
		stop_music()


func is_playing() -> bool:
	return _is_playing
