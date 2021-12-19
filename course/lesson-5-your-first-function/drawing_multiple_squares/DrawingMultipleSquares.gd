extends DrawingTurtle


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


