extends Node2D

var turn := 90
var size := Vector2(200, 120)

onready var _turtle: DrawingTurtle = $DrawingTurtle


func run() -> void:
	_turtle.reset()
	_turtle.move_forward(size.x)
	_turtle.turn_right(turn)
	_turtle.move_forward(size.y)
	_turtle.turn_right(turn)
	_turtle.move_forward(size.x)
	_turtle.turn_right(turn)
	_turtle.move_forward(size.y)
	_turtle.play_draw_animation()

	var rect: Rect2 = _turtle.get_polygons()[0].get_rect()
	_turtle.position = rect.position - rect.size / 2.0
