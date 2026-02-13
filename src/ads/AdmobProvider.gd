extends Node

var _plugin: Object = null
var _interstitial_id := ""
var _rewarded_id := ""
var _reward_callback: Callable = Callable()
var _closed_callback: Callable = Callable()
var _reward_granted := false
var _has_reward_signal := false
var _has_close_signal := false


func configure(config: Dictionary) -> void:
	_interstitial_id = str(config.get("interstitial_id", ""))
	_rewarded_id = str(config.get("rewarded_id", ""))

	if Engine.has_singleton("AdmobPlugin"):
		_plugin = Engine.get_singleton("AdmobPlugin")
	if _plugin == null:
		return

	var app_id := str(config.get("app_id", ""))
	if _plugin.has_method("initialize"):
		_plugin.call("initialize", app_id)
	elif _plugin.has_method("init"):
		_plugin.call("init", app_id)

	_connect_signals()
	_load_interstitial()
	_load_rewarded()


func show_interstitial(_placement: String) -> bool:
	if _plugin == null:
		return false
	var shown := false
	if _plugin.has_method("show_interstitial_ad"):
		_plugin.call("show_interstitial_ad")
		shown = true
	elif _plugin.has_method("showInterstitial"):
		_plugin.call("showInterstitial")
		shown = true
	if shown:
		_load_interstitial()
	return shown


func show_rewarded(_placement: String, on_reward: Callable, on_closed: Callable = Callable()) -> void:
	_reward_callback = on_reward
	_closed_callback = on_closed
	_reward_granted = false

	var shown := false
	if _plugin != null:
		if _plugin.has_method("show_rewarded_ad"):
			_plugin.call("show_rewarded_ad")
			shown = true
		elif _plugin.has_method("showRewarded"):
			_plugin.call("showRewarded")
			shown = true

	if not shown:
		call_deferred("_fallback_reward_and_close")
	elif not _has_reward_signal:
		# No reliable reward callback path from plugin API, fallback to guaranteed reward.
		call_deferred("_fallback_reward_and_close")


func _load_interstitial() -> void:
	if _plugin == null or _interstitial_id.is_empty():
		return
	if _plugin.has_method("load_interstitial_ad"):
		_plugin.call("load_interstitial_ad", _interstitial_id)
	elif _plugin.has_method("loadInterstitial"):
		_plugin.call("loadInterstitial", _interstitial_id)


func _load_rewarded() -> void:
	if _plugin == null or _rewarded_id.is_empty():
		return
	if _plugin.has_method("load_rewarded_ad"):
		_plugin.call("load_rewarded_ad", _rewarded_id)
	elif _plugin.has_method("loadRewarded"):
		_plugin.call("loadRewarded", _rewarded_id)


func _fallback_reward_and_close() -> void:
	_emit_reward_once()
	_emit_close_once()
	_load_rewarded()


func _emit_reward_once() -> void:
	if _reward_granted:
		return
	_reward_granted = true
	if _reward_callback.is_valid():
		_reward_callback.call()


func _emit_close_once() -> void:
	if _closed_callback.is_valid():
		_closed_callback.call()
	_reward_callback = Callable()
	_closed_callback = Callable()
	_reward_granted = false


func _connect_signals() -> void:
	if _plugin == null:
		return
	_has_reward_signal = false
	_has_close_signal = false

	_has_reward_signal = _try_connect("rewarded_ad_user_earned_reward", Callable(self, "_on_reward_signal")) or _has_reward_signal
	_has_reward_signal = _try_connect("on_user_earned_rewarded", Callable(self, "_on_reward_signal")) or _has_reward_signal
	_has_reward_signal = _try_connect("user_earned_rewarded", Callable(self, "_on_reward_signal")) or _has_reward_signal

	_has_close_signal = _try_connect("rewarded_ad_closed", Callable(self, "_on_reward_closed_signal")) or _has_close_signal
	_has_close_signal = _try_connect("on_rewarded_closed", Callable(self, "_on_reward_closed_signal")) or _has_close_signal
	_has_close_signal = _try_connect("rewarded_closed", Callable(self, "_on_reward_closed_signal")) or _has_close_signal


func _try_connect(signal_name: String, callback: Callable) -> bool:
	if _plugin == null or not _plugin.has_signal(signal_name):
		return false
	if not _plugin.is_connected(signal_name, callback):
		_plugin.connect(signal_name, callback)
	return true


func _on_reward_signal(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	_emit_reward_once()


func _on_reward_closed_signal(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	if not _reward_granted:
		_emit_reward_once()
	_emit_close_once()
	_load_rewarded()
