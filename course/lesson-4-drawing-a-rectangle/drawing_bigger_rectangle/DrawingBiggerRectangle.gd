extends DrawingTurtle


func _run():
	reset()
	draw_rectangle()
	play_draw_animation()


func draw_rectangle():
# EXPORT draw_rectangle
	move_forward(220)
	turn_right(90)
	move_forward(260)
	turn_right(90)
	move_forward(220)
	turn_right(90)
	move_forward(260)
# /EXPORT draw_rectangle
