extends Node2D

@onready var _animation_tree := find_child("AnimationTree") as AnimationTree
# EXPORT welcome_to_app
func _ready() -> void:
	print("Welcome!")
	# /EXPORT welcome_to_app
	await get_tree().create_timer(1.0).timeout
	
	Events.practice_run_completed.emit()


func _run() -> void:
	var state_machine_playback := _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	
	if state_machine_playback:
		state_machine_playback.travel("saying_hi")
