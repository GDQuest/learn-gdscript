extends Node2D


func _ready():
	rotation = -0.5


func _run():
	run()
	await get_tree().create_timer(1.0).timeout
	Events.emit_signal("practice_run_completed")


# EXPORT rotate
func run():
	rotate(0.5)
# /EXPORT rotate


func reset():
	rotation = -0.5
