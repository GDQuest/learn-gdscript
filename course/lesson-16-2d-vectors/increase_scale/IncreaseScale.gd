extends Node2D

onready var _animation_player := $AnimationPlayer


var level = 1
var max_health = 100

# EXPORT level_scale
func level_up():
	level += 1
	max_health *= 1.1
	scale += Vector2(0.1, 0.1)
# /EXPORT level_scale

func _run():
	for i in range(5):
		level_up()
		_animation_player.play("level")
		yield(_animation_player, "animation_finished")
	Events.emit_signal("practice_run_completed")
