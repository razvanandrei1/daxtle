extends CanvasLayer

signal prev_pressed
signal next_pressed

@onready var _nav: HBoxContainer  = $LevelNav
@onready var _label: Label        = $LevelNav/LevelLabel
@onready var _prev: Button        = $LevelNav/PrevButton
@onready var _next: Button        = $LevelNav/NextButton


func _ready() -> void:
	_prev.pressed.connect(func(): prev_pressed.emit())
	_next.pressed.connect(func(): next_pressed.emit())
	_position_nav()


func set_level(n: int) -> void:
	_label.text = "%d" % n


# Centre the nav bar horizontally, 16 px from the top
func _position_nav() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	_nav.size = Vector2.ZERO          # let HBoxContainer measure itself first
	_nav.reset_size()
	await get_tree().process_frame   # one frame so the container has computed its size
	_nav.position = Vector2(
		(vp_size.x - _nav.size.x) / 2.0,
		16.0
	)
