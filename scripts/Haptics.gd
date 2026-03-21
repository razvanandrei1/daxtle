# =============================================================================
# Haptics.gd — Autoload singleton for haptic feedback (iOS & Android)
# =============================================================================
# Provides three haptic patterns: tap (UI/slides), win (celebratory triple-tap),
# and fail (sharp double-hit). Only active on mobile platforms.
# Preference persisted via SaveData; toggle available in Settings screen.
# =============================================================================
extends Node

const TAP_MS := 15   # light tap for UI and slides

var _enabled:    bool = true
var _is_mobile:  bool = false


func _ready() -> void:
	var os := OS.get_name()
	_is_mobile = os == "iOS" or os == "Android"
	_enabled = SaveData.get_haptics_enabled()


func tap() -> void:
	if _enabled and _is_mobile:
		Input.vibrate_handheld(TAP_MS)


## Win pattern: 3 taps with rising intensity, spaced 200ms apart
func win() -> void:
	if not _enabled or not _is_mobile:
		return
	Input.vibrate_handheld(10)
	get_tree().create_timer(0.20).timeout.connect(func() -> void:
		Input.vibrate_handheld(20)
	)
	get_tree().create_timer(0.42).timeout.connect(func() -> void:
		Input.vibrate_handheld(35)
	)


## Fail pattern: 2 sharp hits close together
func fail() -> void:
	if not _enabled or not _is_mobile:
		return
	Input.vibrate_handheld(40)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		Input.vibrate_handheld(60)
	)


func set_enabled(on: bool) -> void:
	_enabled = on
	SaveData.set_haptics_enabled(on)


func is_enabled() -> bool:
	return _enabled
