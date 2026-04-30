extends Node2D

const RobotAnimationTree := preload("res://course/common/RobotAnimationTree.gd")

@onready var _animation_tree: RobotAnimationTree = find_child("AnimationTree")


# EXPORT welcome_to_app
func _ready():
	print("Welcome!")
# /EXPORT welcome_to_app

	await get_tree().create_timer(1.0).timeout
	Events.practice_run_completed.emit()


func _run():
	_animation_tree.travel("saying_hi")
