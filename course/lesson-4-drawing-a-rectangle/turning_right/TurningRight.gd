extends DrawingTurtle


func _ready() -> void:
	if not is_connected("turtle_finished", Callable(self, "_complete_run")):
		connect("turtle_finished", Callable(self, "_complete_run"))


func _run():
	reset()
	draw_corner()
	play_draw_animation()


# EXPORT draw_corner
func draw_corner():
	move_forward(200)
	turn_right(90)
	move_forward(200)
# /EXPORT draw_corner


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
