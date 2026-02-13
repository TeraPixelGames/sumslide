extends Node


func configure(_config: Dictionary) -> void:
	pass


func show_interstitial(_placement: String) -> bool:
	return true


func is_rewarded_ready() -> bool:
	return true


func show_rewarded(_placement: String, on_reward: Callable, on_closed: Callable = Callable()) -> void:
	if on_reward.is_valid():
		on_reward.call_deferred()
	if on_closed.is_valid():
		on_closed.call_deferred()
