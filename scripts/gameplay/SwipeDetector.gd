class_name SwipeDetector
extends Node

# Emitted when a valid swipe is recognised. direction is "left"|"right"|"up"|"down"
signal swiped(direction: String)
signal double_tapped

# T20 — minimum drag distance in pixels before a swipe is registered
const MIN_DISTANCE := 40.0
const DOUBLE_TAP_TIME := 0.3  # max seconds between two taps

# T21 — set to false while animations are playing to ignore input
var enabled := true

var _start := Vector2.ZERO
var _tracking := false
var _last_tap_time := -1.0
var _last_tap_pos := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_start    = event.position
			_tracking = true
		elif _tracking:
			_tracking = false
			var delta: Vector2 = event.position - _start
			if delta.length() < MIN_DISTANCE:
				# It was a tap, not a swipe — check for double tap
				var now := Time.get_ticks_msec() / 1000.0
				if now - _last_tap_time < DOUBLE_TAP_TIME \
						and event.position.distance_to(_last_tap_pos) < MIN_DISTANCE:
					double_tapped.emit()
					_last_tap_time = -1.0
				else:
					_last_tap_time = now
					_last_tap_pos = event.position
			else:
				_evaluate(event.position)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT:  swiped.emit("left")
			KEY_RIGHT: swiped.emit("right")
			KEY_UP:    swiped.emit("up")
			KEY_DOWN:  swiped.emit("down")


func _evaluate(end_pos: Vector2) -> void:
	var delta := end_pos - _start
	if delta.length() < MIN_DISTANCE:
		return

	if abs(delta.x) >= abs(delta.y):
		swiped.emit("right" if delta.x > 0 else "left")
	else:
		swiped.emit("down" if delta.y > 0 else "up")
