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


func _ready() -> void:
	if not is_connected("turtle_finished", self, "_complete_run"):
		connect("turtle_finished", self, "_complete_run")


func _complete_run() -> void:
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")
