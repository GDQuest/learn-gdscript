extends Node2D

onready var _animation_tree := find_node("AnimationTree")
onready var _label := find_node("Label")


func _ready() -> void:
	_animation_tree.travel("idle")


func _run() -> void:
	run()
	if robot_name is String:
		_label.text = robot_name
	yield(get_tree().create_timer(1.0), "timeout")
	_animation_tree.travel("saying_hi")
	Events.emit_signal("practice_run_completed")


var robot_name = -1

# EXPORT print_string
func run():
	robot_name = "Robi"
# /EXPORT print_string
