extends Node2D

onready var _animation_tree := find_node("AnimationTree") as AnimationTree
onready var _health_bar := find_node("CustomHealthBar")


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
		_animation_tree.travel("level")
		yield(_animation_tree, "animation_finished")
	Events.emit_signal("practice_run_completed")
