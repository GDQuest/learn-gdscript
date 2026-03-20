extends DrawingTurtle


func _run():
	reset()
	draw_square(200)
	jump(50.0, 50.0)
	draw_square(100.0)
	play_draw_animation()


# EXPORT draw
func draw_square(length):
	move_forward(length)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(length)
	turn_right(90)
# /EXPORT draw


func _ready() -> void:
	if not is_connected("turtle_finished", Callable(self, "_complete_run")):
		connect("turtle_finished", Callable(self, "_complete_run"))


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
