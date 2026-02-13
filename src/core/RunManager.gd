extends Node

const MENU_SCENE := "res://src/scenes/Menu.tscn"
const RESULTS_SCENE := "res://src/scenes/Results.tscn"
const MODE_SCENES := {
	"sumslide": "res://src/modes/sumslide/SumSlideGame.tscn"
}

var active_mode_id := "sumslide"
var last_score := 0
var start_with_shuffle := false


func goto_menu() -> void:
	start_with_shuffle = false
	_change_scene(MENU_SCENE)


func start_mode(mode_id: String, with_shuffle: bool = false) -> void:
	active_mode_id = mode_id
	start_with_shuffle = with_shuffle
	var scene_path := str(MODE_SCENES.get(mode_id, ""))
	if scene_path.is_empty():
		push_error("Unknown mode id: %s" % mode_id)
		return
	_change_scene(scene_path)


func restart_mode() -> void:
	start_mode(active_mode_id)


func finish_mode(score: int) -> void:
	last_score = score
	SaveStore.increment_games_played(active_mode_id)
	if score > SaveStore.get_high_score(active_mode_id):
		SaveStore.set_high_score(active_mode_id, score)
	_change_scene(RESULTS_SCENE)


func _change_scene(path: String) -> void:
	if get_tree() == null:
		return
	get_tree().call_deferred("change_scene_to_file", path)
