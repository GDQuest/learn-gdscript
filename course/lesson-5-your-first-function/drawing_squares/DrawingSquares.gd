extends DrawingTurtle


func _ready() -> void:
	# Godot 4 signal syntax
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)

func _run() -> void:
	reset()
	draw_square()
	play_draw_animation()


# EXPORT draw_square
func draw_square() -> void:
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
	move_forward(200)
	turn_right(90)
# /EXPORT draw_square


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
