extends Control

@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _games_label: Label = %GamesLabel
@onready var _restart_button: Button = %RestartButton
@onready var _rewarded_shuffle_button: Button = %RewardedShuffleButton
@onready var _menu_button: Button = %MenuButton

var _mode_id := "sumslide"


func _ready() -> void:
	_mode_id = RunManager.active_mode_id
	if _mode_id.is_empty():
		_mode_id = "sumslide"

	var score := RunManager.last_score
	var best := SaveStore.get_high_score(_mode_id)
	var games := SaveStore.get_games_played(_mode_id)

	_score_label.text = "Last Score: %d" % score
	_best_label.text = "Best Score: %d" % best
	_games_label.text = "Games Played: %d" % games

	_restart_button.pressed.connect(_on_restart_pressed)
	_rewarded_shuffle_button.pressed.connect(_on_rewarded_shuffle_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_refresh_rewarded_button()

	if games > 0 and games % 3 == 0:
		AdManager.show_interstitial("results_every_third_game")


func _on_restart_pressed() -> void:
	RunManager.restart_mode()


func _on_rewarded_shuffle_pressed() -> void:
	if not AdManager.is_rewarded_ready():
		return
	AdManager.show_rewarded("results_shuffle", Callable(self, "_on_rewarded_shuffle_granted"))


func _on_rewarded_shuffle_granted() -> void:
	RunManager.start_mode(_mode_id, true)


func _on_menu_pressed() -> void:
	RunManager.goto_menu()


func _refresh_rewarded_button() -> void:
	var ready := AdManager.is_rewarded_ready()
	_rewarded_shuffle_button.visible = ready
	_rewarded_shuffle_button.disabled = not ready
