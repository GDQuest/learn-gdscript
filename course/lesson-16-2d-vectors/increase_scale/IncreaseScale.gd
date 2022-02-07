extends Node2D

onready var _animation_tree := find_node("AnimationTree")


var level = 1
var max_health = 100


func _ready():
	scale = Vector2.ONE
	max_health = 100
	level = 1

# EXPORT level_scale
func level_up():
	level += 1
	max_health *= 1.1
	scale += Vector2(0.2, 0.2)
# /EXPORT level_scale

func _run():
	for i in range(2):
		level_up()
		_animation_tree.travel("level")
		yield(_animation_tree, "animation_finished")
	Events.emit_signal("practice_run_completed")
