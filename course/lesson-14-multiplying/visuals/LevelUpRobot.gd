extends Node2D

onready var _animation_player := $AnimationPlayer


func animate() -> void:
	_animation_player.play("level")
