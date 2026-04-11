extends Node2D

const _times := preload("./DemoRotatingTime.gd")._times;

@export var _timer: Timer
@export var _sprite: Node2D
@export var _label_rotation: Label
@export var _label_frame: Label

var _index := 0


func _ready():
	_timer.timeout.connect(_on_Timer_timeout)
	_on_Timer_timeout()


func _on_Timer_timeout():
	var rotation_amount := 0.2;
	var frame_speed:float = _times[_index]
	_sprite.rotate(rotation_amount)
	_timer.start(frame_speed)
	
	_label_rotation.text = "rotation: %s"%[rotation_amount]
	_label_frame.text = "frame speed: %s"%[frame_speed]
	
	_index = wrapi(_index + 1, 0, _times.size() - 1)
