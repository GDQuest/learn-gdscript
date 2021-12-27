extends Node2D


func _ready() -> void:
	set_process(false)


# EXPORT move_and_rotate
func _process(_delta):
	rotate(0.05)
	move_local_x(5)
# /EXPORT move_and_rotate


func _run() -> void:
	reset()
	_process(0.0)
	set_process(true)


func reset() -> void:
	rotation = 0.0
	position = Vector2.ZERO
	set_process(false)
