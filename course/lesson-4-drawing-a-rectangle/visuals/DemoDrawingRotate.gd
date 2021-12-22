extends Node2D

var turn := 45
var length := 80

onready var _turtle: DrawingTurtle = $DrawingTurtle


func run() -> void:
	_turtle.reset()
	_turtle.move_forward(length)
	_turtle.turn_right(turn)
	_turtle.move_forward(length)
	_turtle.turn_left(turn)
	_turtle.move_forward(length)
	_turtle.play_draw_animation()

	var rect: Rect2 = _turtle.get_polygons()[0].get_rect()
	_turtle.position = rect.position - rect.size / 2.0
