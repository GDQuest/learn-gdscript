extends DrawingTurtle


func _run():
	reset()
	draw_rectangle()
	play_draw_animation()


func draw_rectangle():
	# EXPORT draw_corner
	move_forward(200)
	turn_right(90)
	move_forward(200)
	# /EXPORT draw_corner
