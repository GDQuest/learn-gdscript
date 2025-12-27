extends DrawingTurtle

func _run():
	reset()
	run()
	play_draw_animation()


func draw_rectangle(length: float, height: float):
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	_close_polygon()


# EXPORT run
func run():
	for number in range(3):
		jump(200, 0)
		draw_rectangle(100, 100)
# /EXPORT run


func _ready() -> void:
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
