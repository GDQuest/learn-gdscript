# Helper script to simplify using the AnimationTree.
# We use an AnimationTree to easily move to and from different states.
# Several practices rely on waiting for the animation_finished signal, and this
# became problematic when using a method track to go back to the idle animation.
#
# NOTE: Godot 4 already provides animation_finished on AnimationTree/AnimationMixer and the
# AnimationPlayer signal now passes StringName. This helper now acts as a thin wrapper around the 
# state machine playback and proxies AnimationPlayer events using Godot 4 signal/callable conventions.
extends AnimationTree

signal anim_tree_finished(anim_name: StringName)

@onready var _state_machine: AnimationNodeStateMachinePlayback = self["parameters/playback"]
@onready var _animation_player: AnimationPlayer = get_node(anim_player) as AnimationPlayer



func _ready() -> void:
	active = true
	_animation_player.animation_finished.connect(_on_animation_finished)


func travel(animation_name: String) -> void:
	_state_machine.travel(animation_name)


func _on_animation_finished(anim_name: StringName) -> void:
	emit_signal("anim_tree_finished", anim_name)


func get_current_animation() -> StringName:
	return _state_machine.get_current_node()


func player_has_animation(animation_name: StringName) -> bool:
	return _animation_player.has_animation(animation_name)
