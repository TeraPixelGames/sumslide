extends Control

@onready var _start_button: Button = %StartButton
@onready var _sound_toggle: CheckButton = %SoundToggle
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _how_to_play_popup: AcceptDialog = %HowToPlayPopup


func _ready() -> void:
	_sound_toggle.button_pressed = SaveStore.get_sound_on()
	_start_button.pressed.connect(_on_start_pressed)
	_sound_toggle.toggled.connect(_on_sound_toggled)
	_how_to_play_button.pressed.connect(_on_how_to_play_pressed)


func _on_start_pressed() -> void:
	RunManager.start_mode("sumslide")


func _on_sound_toggled(enabled: bool) -> void:
	SaveStore.set_sound_on(enabled)
	MusicManager.set_enabled(enabled)


func _on_how_to_play_pressed() -> void:
	_how_to_play_popup.popup_centered()
