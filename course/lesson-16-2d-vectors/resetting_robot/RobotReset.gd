extends Node2D

# Lowers the chance of the student brute forcing using -/+
var _position_start = Vector2(310.5413, 460.98476)
var _scale_start = Vector2(5.154, 5.154)

onready var _animation_tree := find_node("AnimationTree")

func _ready() -> void:
	reset()

# EXPORT reset
func reset_robot():
	scale = Vector2(1.0, 1.0)
	position = Vector2(0.0, 0.0)
# /EXPORT reset

func _run() -> void:
	reset_robot()
	yield(get_tree().create_timer(1), "timeout")
	Events.emit_signal("practice_run_completed")
	_animation_tree.travel("saying_hi")

func reset():
	position = _position_start
	scale = _scale_start
	_animation_tree.travel("idle")
