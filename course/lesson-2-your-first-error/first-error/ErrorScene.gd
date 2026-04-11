extends Node2D

@onready var _animation_tree := find_child("AnimationTree")

func _ready():
	await get_tree().create_timer(1.0).timeout
	Events.emit_signal("practice_run_completed")

# EXPORT wrong_code
func this_code_is_wrong():
	return
# /EXPORT wrong_code

func _run():
	_animation_tree.travel("saying_hi")
