extends Node2D

var _times := [0.1, 0.1, 0.2, 0.1, 0.2]
var _index := 0

onready var _timer := $Timer
onready var _sprite := $DemoRotateSprite


func _on_Timer_timeout():
	_sprite.rotate(0.2)
	_timer.start(_times[_index])
	
	_index = wrapi(_index + 1, 0, _times.size() - 1)
