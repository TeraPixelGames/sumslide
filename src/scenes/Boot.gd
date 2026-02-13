extends Node


func _ready() -> void:
	SaveStore.load_data()
	MusicManager.start_music()
	RunManager.goto_menu()
