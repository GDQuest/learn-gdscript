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

func _run() -> void:
	reset()
	# Typed loop variable for Godot 4
	for i: int in range(2):
		level_up()
		
		# FIX: AnimationTree travel logic for Godot 4
		var playback := _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		if playback:
			playback.travel("level")
		
		# yield(node, "signal") -> await node.signal
		await _animation_tree.animation_finished
		
	# Godot 4 signal syntax
	Events.practice_run_completed.emit()
	
func reset():
	level = 1
	max_health = 100
	_health_bar.set_max_health(max_health)
