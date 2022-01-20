extends Node2D


func _run():
	# EXPORT show
	show()
	# /EXPORT show
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")
