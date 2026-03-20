extends DrawingTurtle


func _run():
	reset()
	draw_rectangle(260.0, 180.0)
	jump(0.0, 220.0)
	draw_rectangle(160.0, 210.0)
	play_draw_animation()


# EXPORT draw
func draw_rectangle(length, height):
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
# /EXPORT draw


func _ready() -> void:
	if not is_connected("turtle_finished", Callable(self, "_complete_run")):
		connect("turtle_finished", Callable(self, "_complete_run"))


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
