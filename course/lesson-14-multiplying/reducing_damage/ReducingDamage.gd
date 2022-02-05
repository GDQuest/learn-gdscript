extends Node2D


var level = 3
var health = 100
var max_health = 100

onready var _animation_player := $AnimationPlayer
onready var _health_bar := $CustomHealthBar as ColorRect

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
	_health_bar.set_health(health)
	_animation_player.play("damage")
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")
