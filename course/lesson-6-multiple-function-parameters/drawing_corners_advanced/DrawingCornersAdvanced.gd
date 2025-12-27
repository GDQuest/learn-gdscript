extends DrawingTurtle

var _length := 240


func _run():
	reset()
	draw_corner(_length, 45)
	turn_left(45)
	jump(-340, -80)
	_length /= 2
	draw_corner(_length, 90)
	play_draw_animation()


# EXPORT draw_corner
func draw_corner(length: float, angle: float) -> void:
	move_forward(length)
	turn_right(angle)
	move_forward(length)
# /EXPORT draw_corner


func _ready() -> void:
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
