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
