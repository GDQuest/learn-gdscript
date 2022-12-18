extends Node2D

export var max_health := 100

var level := 1

onready var _health_bar := find_node("CustomHealthBar") as ColorRect
onready var _label_level := find_node("LevelLabel") as Label
onready var _animation_tree := find_node("AnimationTree") as AnimationTree

func _run():
	reset()
	for i in range(3):
		level_up()
		_health_bar.set_max_health(max_health)
		_label_level.text = "Level %s" % level
		_animation_tree.travel("level")
		yield(_animation_tree, "animation_finished")
	
	Events.emit_signal("practice_run_completed")
	
# EXPORT even_level
func level_up():
	level += 1
	max_health += 5
	if level % 2 == 0:
		max_health += 5
# /EXPORT even_level

func reset():
	level = 1
	max_health = 100
	_health_bar.set_max_health(max_health)
