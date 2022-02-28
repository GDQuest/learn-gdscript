# Helper script to simplify using the AnimationTree.
# We use an AnimationTree to easily move to and from different states.
# Several practices rely on waiting for the animation_finished signal, and this
# became problematic when using a method track to go back to the idle animation.
extends AnimationTree

signal animation_finished

onready var _state_machine = self["parameters/playback"]
onready var _animation_player = get_node(anim_player) as AnimationPlayer


func _ready() -> void:
	active = true
	_animation_player.connect("animation_finished", self, "_on_animation_finished")


func travel(animation_name: String) -> void:
	_state_machine.travel(animation_name)


func _on_animation_finished() -> void:
	emit_signal("animation_finished")


func get_current_animation() -> String:
	return _state_machine.get_current_node()


func has_animation(animation_name: String) -> bool:
	return _animation_player.has_animation(animation_name)
