extends DrawingTurtle

func _run() ->void:
	reset()
	run()
	play_draw_animation()


func draw_rectangle(length: float, height: float) ->void:
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
func run() ->void:
	position.x = 100
	position.y = 100
	draw_rectangle(100, 100)
	
	position.x = 300
	draw_rectangle(100, 100)

	position.x = 500
	draw_rectangle(100, 100)
# /EXPORT run


func _ready() -> void:
	if not turtle_finished.is_connected(_complete_run):
		turtle_finished.connect(_complete_run)


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()
