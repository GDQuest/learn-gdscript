extends DrawingTurtle


func _ready() -> void:
	if not is_connected("turtle_finished", self, "_complete_run"):
		connect("turtle_finished", self, "_complete_run")


func _run():
	reset()
	draw_rectangle()
	play_draw_animation()


func draw_rectangle():
	# EXPORT draw_corner
	move_forward(200)
	turn_right(90)
	move_forward(200)
	# /EXPORT draw_corner


func _complete_run() -> void:
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")
