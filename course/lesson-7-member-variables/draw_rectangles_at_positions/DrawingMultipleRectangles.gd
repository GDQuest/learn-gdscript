extends DrawingTurtle

func _run():
	reset()
	run()
	play_draw_animation()


func draw_rectangle(length, height):
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	_close_polygon()


# EXPORT run
func run():
	position.x = 100
	position.y = 100
	draw_rectangle(100, 100)
	
	position.x = 300
	draw_rectangle(100, 100)

	position.x = 500
	draw_rectangle(100, 100)
# /EXPORT run


func _ready() -> void:
	if not is_connected("turtle_finished", Callable(self, "_complete_run")):
		connect("turtle_finished", Callable(self, "_complete_run"))


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
