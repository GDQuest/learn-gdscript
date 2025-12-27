extends DrawingTurtle


func _run() -> void:
	reset()
	draw_square(200)
	jump(50.0, 50.0)
	draw_square(100.0)
	play_draw_animation()


# EXPORT draw
func draw_square(length: float) -> void:
	move_forward(length)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(length)
	turn_right(90)
# /EXPORT draw


func _ready() -> void:
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
