extends DrawingTurtle

func _run():
	reset()
	draw_corner(240)
	turn_left(90)
	jump(-240, -140)
	draw_corner(120)
	play_draw_animation()


# EXPORT draw_corner
func draw_corner(length):
	move_forward(length)
	turn_right(90)
	move_forward(length)
# /EXPORT draw_corner


func _ready() -> void:
	if not is_connected("turtle_finished", Callable(self, "_complete_run")):
		connect("turtle_finished", Callable(self, "_complete_run"))


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
