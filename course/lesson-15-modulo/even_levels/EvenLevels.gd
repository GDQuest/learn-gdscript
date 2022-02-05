extends Node2D

export var health := 100
export var max_health := 100

var level := 1

onready var _health_bar := $CustomHealthBar as ColorRect
onready var _label_level := $LevelLabel as Label
onready var _animation_tree := $AnimationTree as AnimationTree
onready var _state_machine = _animation_tree["parameters/playback"]

func _run():
	
	for i in range(3):
		level_up()
		_health_bar.set_health(health)
		_label_level.text = "Level %s" % level
		_animation_tree.play("level")
		yield(_animation_tree, "animation_finished")
	
	Events.emit_signal("practice_run_completed")
	
# EXPORT even_level
func level_up():
	level += 1
	max_health += 5
	if level % 2 == 0:
		max_health += 5
# /EXPORT even_level
