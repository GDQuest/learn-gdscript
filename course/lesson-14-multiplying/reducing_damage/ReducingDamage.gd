extends Node2D

onready var _animation_player := $AnimationPlayer


var level = 3
var health = 100
var max_health = 100

# EXPORT damage
func take_damage(amount):
	if level > 2:
		amount *= 0.5
	
	health -= amount

	if health > max_health:
		health = max_health

	if health < 0:
		health = 0
# /EXPORT damage

func _run():
	take_damage(10)
	_animation_player.play("level")
