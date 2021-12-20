extends Node2D

var angle_inside := 72
var angle_outside := 108 + 36
var length := 80

onready var _turtle: DrawingTurtle = $DrawingTurtle


func run() -> void:
	_turtle.reset()
	
	for i in range(5):
		_turtle.move_forward(length)
		_turtle.turn_left(angle_inside)
		_turtle.move_forward(length)
		_turtle.turn_right(angle_outside)
	
	_turtle.play_draw_animation()
	
	var rect: Rect2 = _turtle.get_polygons()[0].get_rect()
	_turtle.position.x = rect.position.x - rect.size.x / 2.0
	_turtle.position.y = rect.position.y
