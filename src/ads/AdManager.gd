extends Node

const AdmobProviderScript = preload("res://src/ads/AdmobProvider.gd")
const MockAdProviderScript = preload("res://src/ads/MockAdProvider.gd")

const REAL_IDS := {
	"app_id": "ca-app-pub-8413230766502262~4714939196",
	"interstitial_id": "ca-app-pub-8413230766502262/2404578421",
	"rewarded_id": "ca-app-pub-8413230766502262/3011907498"
}

const TEST_IDS := {
	"app_id": "ca-app-pub-3940256099942544~3347511713",
	"interstitial_id": "ca-app-pub-3940256099942544/1033173712",
	"rewarded_id": "ca-app-pub-3940256099942544/5224354917"
}

var _provider: Node = null


func _ready() -> void:
	_ensure_project_settings()
	var config := _resolve_config()
	_provider = _build_provider(config)
	if _provider:
		add_child(_provider)


func show_interstitial(placement: String) -> void:
	if _provider and _provider.has_method("show_interstitial"):
		_provider.call("show_interstitial", placement)


func show_rewarded(placement: String, on_reward: Callable, on_closed: Callable = Callable()) -> void:
	if _provider and _provider.has_method("show_rewarded"):
		_provider.call("show_rewarded", placement, on_reward, on_closed)
		return
	if on_reward.is_valid():
		on_reward.call()
	if on_closed.is_valid():
		on_closed.call()


func _ensure_project_settings() -> void:
	if not ProjectSettings.has_setting("sumslide/use_mock_ads"):
		ProjectSettings.set_setting("sumslide/use_mock_ads", true)
	if not ProjectSettings.has_setting("sumslide/ads_force_real"):
		ProjectSettings.set_setting("sumslide/ads_force_real", false)


func _resolve_config() -> Dictionary:
	var force_real := bool(ProjectSettings.get_setting("sumslide/ads_force_real", false))
	if OS.is_debug_build() and not force_real:
		return TEST_IDS.duplicate(true)
	return REAL_IDS.duplicate(true)


func _build_provider(config: Dictionary) -> Node:
	var use_mock := Engine.is_editor_hint() or bool(ProjectSettings.get_setting("sumslide/use_mock_ads", true))
	if use_mock or not Engine.has_singleton("AdmobPlugin"):
		var mock_provider: Node = MockAdProviderScript.new()
		mock_provider.call("configure", config)
		return mock_provider
	var admob_provider: Node = AdmobProviderScript.new()
	admob_provider.call("configure", config)
	return admob_provider
