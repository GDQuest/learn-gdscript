extends DrawingTurtle

var _length := 240
var _offset := 80

func _run():
	reset()
	draw_corner(_length)
	jump(-_length, -_length + _offset)
	_length /= 2
	rotation_degrees = 0
	draw_corner(_length)
	jump(-_length, -_length + _offset)
	_length /= 2
	rotation_degrees = 0
	draw_corner(_length)
	play_draw_animation()


# EXPORT draw_corner
func draw_corner(length):
	move_forward(length)
	turn_right(90)
	move_forward(length)
# /EXPORT draw_corner
