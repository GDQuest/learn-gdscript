extends Node2D

onready var _animation_player := $AnimationPlayer


var level = 1
var max_health = 100

# EXPORT level
func level_up():
	level += 1
	max_health *= 1.1
# /EXPORT level

func _run():
	level_up()
	level_up()
	_animation_player.play("level")
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")
