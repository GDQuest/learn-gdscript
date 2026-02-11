extends Node2D

onready var camera_2d := $Camera2D

func _ready() -> void:
	set_process(false)
	camera_2d.set_as_toplevel(true)


# EXPORT move_and_rotate
func _process(delta):
	rotate(0.05)
	move_local_x(5)
# /EXPORT move_and_rotate


func _run() -> void:
	reset()
	set_process(true)
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func reset() -> void:
	rotation = 0.0
	position = Vector2(0, 0)
	set_process(false)
