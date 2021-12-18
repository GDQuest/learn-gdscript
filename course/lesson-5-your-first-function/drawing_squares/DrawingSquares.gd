extends DrawingTurtle


func _run():
	reset()
	draw_square()
	play_draw_animation()


# EXPORT draw_square
func draw_square():
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
# /EXPORT draw_square
