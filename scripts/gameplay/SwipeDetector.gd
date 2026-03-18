class_name SwipeDetector
extends Node

# Emitted when a valid swipe is recognised. direction is "left"|"right"|"up"|"down"
signal swiped(direction: String)

# T20 — minimum drag distance in pixels before a swipe is registered
const MIN_DISTANCE := 40.0

# T21 — set to false while animations are playing to ignore input
var enabled := true

var _start := Vector2.ZERO
var _tracking := false


func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_start    = event.position
			_tracking = true
		elif _tracking:
			_tracking = false
			_evaluate(event.position)


func _evaluate(end_pos: Vector2) -> void:
	var delta := end_pos - _start
	if delta.length() < MIN_DISTANCE:
		return

	if abs(delta.x) >= abs(delta.y):
		swiped.emit("right" if delta.x > 0 else "left")
	else:
		swiped.emit("down" if delta.y > 0 else "up")
