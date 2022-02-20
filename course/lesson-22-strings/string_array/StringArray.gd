extends Node2D

onready var _animation_tree := find_node("AnimationTree")


func _ready() -> void:
	_animation_tree.travel("idle")


func _run() -> void:
	run()
	play_combo()
	Events.emit_signal("practice_run_completed")


func play_combo() -> void:
	for action in combo:
		if _animation_tree.has_animation(str(action)):
			_animation_tree.travel(action)
			yield(_animation_tree, "animation_finished")


var combo = []

# EXPORT combo
func run():
	combo = ["jump", "jump", "damage", "damage", "level"]
	for animation_name in combo:
		play_animation(animation_name)
# /EXPORT combo

# A blank function because yields don't work with slices.
func play_animation(action: String) -> void:
	pass
