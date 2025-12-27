extends Node2D

const _times := [0.1, 0.1, 0.2, 0.1, 0.2]
var _index := 0

@onready var _timer: Timer = $Timer
@onready var _robot: Node2D = $Robot
@onready var _label_rotation: Label = $LabelRotation
@onready var _label_frame: Label = $LabelFrame

func _ready() -> void:
	_timer.timeout.connect(_on_Timer_timeout)

func _on_Timer_timeout() -> void:
	var frame_speed: float = _times[_index]
	var rotation_amount: float = 1.0 * frame_speed

	_robot.rotate(rotation_amount)
	_timer.start(frame_speed)

	_label_rotation.text = "rotation: %s" % rotation_amount
	_label_frame.text = "frame speed: %s" % frame_speed

	_index = wrapi(_index + 1, 0, _times.size())
