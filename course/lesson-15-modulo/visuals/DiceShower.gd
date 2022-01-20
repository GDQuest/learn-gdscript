extends Node2D

var max_number := 10
var _result := 0

onready var _result_label := $Sprite/Label as Label
onready var _animation_player := $AnimationPlayer as AnimationPlayer


func run() -> void:
	if _animation_player.is_playing():
		return
	
	roll(max_number)


func roll(max_number: int) -> void:
	_result = randi() % max_number + 1
	_result_label.text = str(_result)
	_animation_player.play("roll")
