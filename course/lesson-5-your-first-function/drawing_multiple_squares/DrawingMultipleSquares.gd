extends DrawingTurtle


func _ready() -> void:
	if not is_connected("turtle_finished", Callable(self, "_complete_run")):
		connect("turtle_finished", Callable(self, "_complete_run"))


func _run():
	reset()
	draw_three_squares()
	play_draw_animation()


# EXPORT draw_three_squares
func draw_square():
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)


func draw_three_squares():
	draw_square()
	jump(300, 300)
	draw_square()
	jump(300, 300)
	draw_square()
# /EXPORT draw_three_squares


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
