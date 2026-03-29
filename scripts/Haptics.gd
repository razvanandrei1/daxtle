# =============================================================================
# Haptics.gd — Autoload singleton for haptic feedback (iOS & Android)
# =============================================================================
# On iOS:     native UIKit haptic generators via DaxtleHaptics plugin
# On Android: native VibrationEffect / HapticFeedbackConstants via DaxtleHaptics plugin
# Fallback:   Input.vibrate_handheld (if native plugin unavailable)
# =============================================================================
extends Node

const TAP_MS := 15   # light tap for UI and slides (fallback)

var _enabled:    bool = true
var _is_mobile:  bool = false
var _native:     Object = null  # native plugin singleton (iOS or Android)


func _ready() -> void:
	var os := OS.get_name()
	_is_mobile = os == "iOS" or os == "Android"
	_enabled = SaveData.get_haptics_enabled()

	if _is_mobile and Engine.has_singleton("DaxtleHaptics"):
		_native = Engine.get_singleton("DaxtleHaptics")


func tap() -> void:
	if not _enabled or not _is_mobile:
		return
	if _native:
		_native.tapLight()
	else:
		Input.vibrate_handheld(TAP_MS)


## Win: success notification
func win() -> void:
	if not _enabled or not _is_mobile:
		return
	if _native:
		_native.notifySuccess()
	else:
		Input.vibrate_handheld(10)
		get_tree().create_timer(0.20).timeout.connect(func() -> void:
			Input.vibrate_handheld(20)
		)
		get_tree().create_timer(0.42).timeout.connect(func() -> void:
			Input.vibrate_handheld(35)
		)


## Fail: error notification
func fail() -> void:
	if not _enabled or not _is_mobile:
		return
	if _native:
		_native.notifyError()
	else:
		Input.vibrate_handheld(40)
		get_tree().create_timer(0.08).timeout.connect(func() -> void:
			Input.vibrate_handheld(60)
		)


func set_enabled(on: bool) -> void:
	_enabled = on
	SaveData.set_haptics_enabled(on)


func is_enabled() -> bool:
	return _enabled
