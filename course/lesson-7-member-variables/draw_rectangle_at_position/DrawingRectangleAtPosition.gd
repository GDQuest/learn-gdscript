extends DrawingTurtle

func _run() -> void:
	reset()
	run()
	play_draw_animation()


func draw_rectangle(length: float, height: float) -> void:
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)


# EXPORT test_assignment
func run() -> void:
	# Accessing position.x/y remains the same in Godot 4
	position.x = 120
	position.y = 100
	draw_rectangle(200, 120)
# /EXPORT test_assignment


func _ready() -> void:
	# Godot 4 Signal connection syntax: signal.connect(callable)
	# Assuming 'turtle_finished' is defined in the parent DrawingTurtle class
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	# Godot 4 Signal emission: signal.emit()
	Events.practice_run_completed.emit()
