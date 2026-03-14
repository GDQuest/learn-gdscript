extends Node2D

var _position_start: Vector2
var _scale_start: Vector2

onready var _animation_tree := find_node("AnimationTree")
onready var _camera := $Camera2D

func _ready() -> void:
	_position_start = position
	_scale_start = scale
	_camera.set_as_toplevel(true)
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
