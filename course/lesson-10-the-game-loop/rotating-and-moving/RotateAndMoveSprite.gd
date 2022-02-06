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
	set_process(true)
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func reset() -> void:
	rotation = 0.0
	position = Vector2(0, 0)
	set_process(false)
