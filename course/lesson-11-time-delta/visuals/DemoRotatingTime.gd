extends Node2D

const _times := [0.1, 0.1, 0.2, 0.1, 0.2]
var _index := 0

@onready var _timer := find_child("Timer") as Timer
@onready var _robot := find_child("Robot") as Node2D
@onready var _label_rotation := find_child("LabelRotation") as Label
@onready var _label_frame := find_child("LabelFrame") as Label

func _ready():
	_on_Timer_timeout()

func _on_Timer_timeout():
	var rotation_amount := 1 * _timer.wait_time;
	var frame_speed:float = _times[_index]
	_robot.rotate(rotation_amount)
	_timer.start(frame_speed)
	
	_label_rotation.text = "rotation: %s"%[rotation_amount]
	_label_frame.text = "frame speed: %s"%[frame_speed]
	
	_index = wrapi(_index + 1, 0, _times.size() - 1)
