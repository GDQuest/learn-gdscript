extends Node2D

onready var _animation_player := $AnimationPlayer as AnimationPlayer
onready var _health_bar := $CustomHealthBar


var level = 1
var max_health = 100

# EXPORT level
func level_up():
	level += 1
	max_health *= 1.1
# /EXPORT level
	_health_bar.set_max_health(max_health)

func _run():
	for i in range(2):
		level_up()
		_animation_player.play("level")
		yield(_animation_player, "animation_finished")
	Events.emit_signal("practice_run_completed")
