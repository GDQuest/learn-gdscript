extends Node2D

onready var _animation_tree := find_node("AnimationTree")

# EXPORT welcome_to_app
func _ready():
	print("Welcome!")
# /EXPORT welcome_to_app
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")

func _run():
	_animation_tree.travel("saying_hi")
