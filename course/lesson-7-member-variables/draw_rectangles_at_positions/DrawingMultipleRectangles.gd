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
	_close_polygon()


func test_assignment():
	# EXPORT test_assignment
	position.x = 100
	position.y = 100
	draw_rectangle(100, 100)
	
	position.x = 300
	draw_rectangle(100, 100)

	position.x = 500
	draw_rectangle(100, 100)
	# /EXPORT test_assignment
