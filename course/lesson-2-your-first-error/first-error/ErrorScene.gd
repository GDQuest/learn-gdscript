extends Node2D

@onready var _animation_tree := find_child("AnimationTree", true, false) as AnimationTree

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	Events.practice_run_completed.emit()

# EXPORT wrong_code
func this_code_is_wrong():
	return
# /EXPORT wrong_code

func _run() -> void:
	var state_machine_playback := _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if state_machine_playback:
		state_machine_playback.travel("saying_hi")
