extends Node2D

@onready var _animation_tree := find_child("AnimationTree")
@onready var _label := find_child("Label")


func _ready() -> void:
	_animation_tree.travel("idle")


func _run() -> void:
	run()
	if robot_name is String:
		_label.text = robot_name
	else:
		_label.text = "robot_name"
	await get_tree().create_timer(1.0).timeout
	_animation_tree.travel("saying_hi")
	Events.emit_signal("practice_run_completed")


# EXPORT print_string
var robot_name = "Robi"

func run():
	print("Hi, " + robot_name + "!")
# /EXPORT print_string
