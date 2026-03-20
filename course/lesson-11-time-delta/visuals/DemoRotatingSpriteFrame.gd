extends Node2D

const _times := preload("./DemoRotatingTime.gd")._times;
var _index := 0

@onready var _timer := $Timer as Timer
@onready var _sprite := $DemoRotateSprite as Node2D
@onready var _label_rotation := $LabelRotation as Label
@onready var _label_frame := $LabelFrame as Label

func _ready():
	_on_Timer_timeout()

func _on_Timer_timeout():
	var rotation_amount := 0.2;
	var frame_speed:float = _times[_index]
	_sprite.rotate(rotation_amount)
	_timer.start(frame_speed)
	
	_label_rotation.text = "rotation: %s"%[rotation_amount]
	_label_frame.text = "frame speed: %s"%[frame_speed]
	
	_index = wrapi(_index + 1, 0, _times.size() - 1)
