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
