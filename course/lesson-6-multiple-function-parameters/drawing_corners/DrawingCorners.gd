extends DrawingTurtle

func _run() -> void:
	reset()
	draw_corner(240)
	turn_left(90)
	jump(-240, -140)
	draw_corner(120)
	play_draw_animation()


# EXPORT draw_corner
func draw_corner(length: float) -> void:
	move_forward(length)
	turn_right(90)
	move_forward(length)
# /EXPORT draw_corner


func _ready() -> void:
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
