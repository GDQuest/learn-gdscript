extends DrawingTurtle

func _run():
	reset()
	test_assignment()
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


func test_assignment():
	# EXPORT test_assignment
	position.x = 120
	position.y = 100
	draw_rectangle(200, 120)
	# /EXPORT test_assignment
