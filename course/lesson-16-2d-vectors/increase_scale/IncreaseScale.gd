extends Node2D

@onready var _animation_tree := find_child("AnimationTree")


var level = 1
var max_health = 100


func _ready():
	reset()


# EXPORT level_scale
func level_up():
	level += 1
	max_health *= 1.1
	scale += Vector2(0.2, 0.2)
# /EXPORT level_scale

func _run():
	reset()
	for i in range(2):
		level_up()
		_animation_tree.travel("level")
		await _animation_tree.animation_finished
	Events.emit_signal("practice_run_completed")

func reset():
	scale = Vector2.ONE
	max_health = 100
	level = 1
