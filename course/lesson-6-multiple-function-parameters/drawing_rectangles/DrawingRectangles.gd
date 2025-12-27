extends DrawingTurtle


func _run() -> void:
	reset()
	draw_rectangle(260.0, 180.0)
	jump(0.0, 220.0)
	draw_rectangle(160.0, 210.0)
	play_draw_animation()


# EXPORT draw
func draw_rectangle(length: float, height: float) -> void:
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
# /EXPORT draw


func _ready() -> void:
	# Godot 4 signal syntax
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)

func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
