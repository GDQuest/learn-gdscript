extends Node2D

var side_length := 40.0

onready var _turtle: DrawingTurtle = $DrawingTurtle

func run():
	_turtle.reset()
	_turtle.move_forward(side_length)
	_turtle.turn_right(90)
	_turtle.move_forward(side_length)
	_turtle.turn_right(90)
	_turtle.move_forward(side_length)
	_turtle.turn_right(90)
	_turtle.move_forward(side_length)
	_turtle.turn_right(90)

	_turtle.play_draw_animation()

	var rect: Rect2 = _turtle.get_polygons()[0].get_rect()
	_turtle.position = rect.position - rect.size / 2.0
