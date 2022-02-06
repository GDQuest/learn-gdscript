extends Node2D


func _ready() -> void:
	set_process(false)


# EXPORT move_and_rotate
func _process(delta):
	rotate(2 * delta)
	move_local_x(100 * delta)
# /EXPORT move_and_rotate


func _run() -> void:
	reset()
	_process(0.0)
	set_process(true)


func reset() -> void:
	rotation = 0.0
	position = Vector2(0, 0)
	set_process(false)
