extends Node2D

const RobotAnimationTree := preload("res://course/common/RobotAnimationTree.gd")

@onready var _animation_tree: RobotAnimationTree = find_child("AnimationTree")


func _init() -> void:
	ready.connect(_on_node_ready)


# EXPORT welcome_to_app
func _ready():
	print("Welcome!")
# /EXPORT welcome_to_app


func _on_node_ready() -> void:
	await get_tree().create_timer(1.0).timeout
	Events.emit_signal("practice_run_completed")


func _run():
	_animation_tree.travel("saying_hi")
