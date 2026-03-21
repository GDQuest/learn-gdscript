extends DrawingTurtle


func _ready() -> void:
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _run():
	reset()
	draw_rectangle()
	play_draw_animation()


# EXPORT draw_rectangle
func draw_rectangle():
	move_forward(220)
	turn_right(90)
	move_forward(260)
	turn_right(90)
	move_forward(220)
	turn_right(90)
	move_forward(260)
# /EXPORT draw_rectangle


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
