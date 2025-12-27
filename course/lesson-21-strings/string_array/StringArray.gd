extends Node2D

@onready var _animation_tree := find_child("AnimationTree")


func _ready() -> void:
	_animation_tree.travel("idle")


func _run() -> void:
	_animation_queue.clear()
	run()
	play_combo()
	Events.emit_signal("practice_run_completed")


# We use this internal queue because we need to yield between animations and 
# we can't have the student do that in their for loop at this stage.
var _animation_queue := []

func play_combo() -> void:
	for action in _animation_queue:
		if _animation_tree.has_animation(str(action)):
			_animation_tree.travel(action)
			await _animation_tree.animation_finished


var combo = []

# EXPORT combo
func run():
	combo = ["jab", "jab", "uppercut"]
	for animation_name in combo:
		play_animation(animation_name)
# /EXPORT combo

func play_animation(action: String) -> void:
	_animation_queue.append(action)
