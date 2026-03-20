extends Node2D

@onready var _animation_tree := find_child("AnimationTree") as AnimationTree
@onready var _health_bar := find_child("CustomHealthBar")


# EXPORT level
var level = 1
var max_health = 100

func level_up():
	level += 1
	max_health *= 1.1
# /EXPORT level
	_health_bar.set_max_health(max_health)

func _run():
	reset()
	for i in range(2):
		level_up()
		_animation_tree.travel("level")
		await _animation_tree.animation_finished
	Events.emit_signal("practice_run_completed")

func reset():
	level = 1
	max_health = 100
	_health_bar.set_max_health(max_health)
