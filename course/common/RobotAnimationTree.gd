# Helper script to simplify using the AnimationTree.
# We use an AnimationTree to easily move to and from different states.
# Several practices rely on waiting for the animation_finished signal, and this
# became problematic when using a method track to go back to the idle animation.
extends AnimationTree

@onready var _state_machine: AnimationNodeStateMachinePlayback = self["parameters/playback"]


func _ready() -> void:
	active = true


func travel(animation_name: String) -> void:
	_state_machine.travel(animation_name)


func get_current_animation() -> String:
	return _state_machine.get_current_node()
