extends DrawingTurtle

var _length := 240


func _run():
	reset()
	draw_corner(_length, 45)
	jump(-340, -80)
	_length /= 2
	rotation_degrees = 0
	draw_corner(_length, 90)
	jump(-160, -40)
	rotation_degrees = 0
	draw_corner(_length, 135)
	play_draw_animation()


# EXPORT draw_corner
func draw_corner(length, angle):
	move_forward(length)
	turn_right(angle)
	move_forward(length)
# /EXPORT draw_corner
