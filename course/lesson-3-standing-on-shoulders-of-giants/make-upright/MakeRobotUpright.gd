extends Node2D

onready var start_rotation := rotation

func _run():
	rotation = start_rotation
	# EXPORT rotate
	rotate(0.5)
	# /EXPORT rotate
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")
