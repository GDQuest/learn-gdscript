extends Node2D

onready var _animation_player := $AnimationPlayer


var level = 1
var max_health = 100

# EXPORT health
func level_up():
	level += 1
	max_health *= 1.1
# /EXPORT health

func _run():
	level_up()
	level_up()
	_animation_player.play("level")
