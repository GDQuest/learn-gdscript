extends DrawingTurtle


func _ready() -> void:
	# Godot 4 signal syntax: signal.is_connected(Callable) and signal.connect(Callable)
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _run() -> void:
	reset()
	draw_corner()
	play_draw_animation()


# EXPORT draw_corner
func draw_corner() -> void:
	move_forward(200)
	turn_right(90)
	move_forward(200)
# /EXPORT draw_corner


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
