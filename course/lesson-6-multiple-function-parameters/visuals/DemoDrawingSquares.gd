extends Node2D

var size := 40.0

@onready var _turtle: DrawingTurtle = $DrawingTurtle


func run():
	_turtle.reset()
	_turtle.position = Vector2.ZERO
	_turtle.move_forward(size)
	_turtle.turn_right(90)
	_turtle.move_forward(size)
	_turtle.turn_right(90)
	_turtle.move_forward(size)
	_turtle.turn_right(90)
	_turtle.move_forward(size)
	_turtle.turn_right(90)

	_turtle.play_draw_animation()

	var rect: Rect2 = _turtle.get_rect()
	_turtle.position = - rect.size / 2.0


func reset():
	_turtle.reset()
