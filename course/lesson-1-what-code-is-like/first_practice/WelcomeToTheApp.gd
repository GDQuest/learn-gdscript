extends Node2D

@onready var _animation_tree := find_child("AnimationTree")

# EXPORT welcome_to_app
func _ready():
	print("Welcome!")
# /EXPORT welcome_to_app
	await get_tree().create_timer(1.0).timeout
	Events.emit_signal("practice_run_completed")

func _run():
	_animation_tree.travel("saying_hi")
