# =============================================================================
# Haptics.gd — Autoload singleton for haptic feedback (iOS & Android)
# =============================================================================
# On iOS: uses native UIKit haptic generators via the DaxtleHaptics plugin
#   - tap:  UIImpactFeedbackGenerator .light
#   - win:  UINotificationFeedbackGenerator .success
#   - fail: UINotificationFeedbackGenerator .error
# On Android: falls back to Input.vibrate_handheld with timed patterns.
# =============================================================================
extends Node

const TAP_MS := 15   # light tap for UI and slides (Android fallback)

var _enabled:    bool = true
var _is_mobile:  bool = false
var _is_ios:     bool = false
var _ios_haptics: Object = null  # native plugin singleton


func _ready() -> void:
	var os := OS.get_name()
	_is_mobile = os == "iOS" or os == "Android"
	_is_ios = os == "iOS"
	_enabled = SaveData.get_haptics_enabled()

	if _is_ios and Engine.has_singleton("DaxtleHaptics"):
		_ios_haptics = Engine.get_singleton("DaxtleHaptics")


func tap() -> void:
	if not _enabled or not _is_mobile:
		return
	if _ios_haptics:
		_ios_haptics.tapLight()
	else:
		Input.vibrate_handheld(TAP_MS)


## Win: iOS .success notification, Android triple-tap pattern
func win() -> void:
	if not _enabled or not _is_mobile:
		return
	if _ios_haptics:
		_ios_haptics.notifySuccess()
	else:
		Input.vibrate_handheld(10)
		get_tree().create_timer(0.20).timeout.connect(func() -> void:
			Input.vibrate_handheld(20)
		)
		get_tree().create_timer(0.42).timeout.connect(func() -> void:
			Input.vibrate_handheld(35)
		)


## Fail: iOS .error notification, Android double-hit pattern
func fail() -> void:
	if not _enabled or not _is_mobile:
		return
	if _ios_haptics:
		_ios_haptics.notifyError()
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
