extends Node2D

func _ready():
	rotation = -0.5

func _run():
	# EXPORT rotate
	rotate(0.5)
	# /EXPORT rotate
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")
