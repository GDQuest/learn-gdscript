extends DrawingTurtle


func _run() -> void:
	reset()
	# Works around directly setting variables in parent class 
	# as the parent class isn't recognized from the live editor.
	set("speed_multiplier", 1.25)
	run()
	play_draw_animation()


# EXPORT draw
# Godot 4: Typed arrays are preferred for performance and clarity
var rectangle_sizes: Array[Vector2] = [
	Vector2(200, 120),
	Vector2(140, 80),
	Vector2(80, 140),
	Vector2(200, 140),
]

func run() -> void:
	for rect_size in rectangle_sizes:
		draw_rectangle(rect_size.x, rect_size.y)
		jump(rect_size.x, 0)
# /EXPORT draw


func draw_rectangle(length: float, height: float) -> void:
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)
	move_forward(length)
	turn_right(90)
	move_forward(height)
	turn_right(90)


func _ready() -> void:
	# Godot 4 Signal connection syntax
	# Assuming 'turtle_finished' is defined in DrawingTurtle
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	# Godot 4 Signal emission syntax
	Events.practice_run_completed.emit()
