extends PracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100), Vector2(0, 0)]
]

var turtle: DrawingTurtle

# We sort vertices for accurate comparison
func _init() -> void:
	for rect in expected_rects:
		rect.sort()


func _prepare():
	turtle = _scene_root_viewport.get_child(0)


func test_turtle_ends_facing_towards_the_right() -> String:
	var turn_right_between_jumps := 0
	for command in turtle.get_command_stack():
		if command.command == "turn":
			turn_right_between_jumps += 1
			if not is_equal_approx(command.angle, 90.0):
				return tr("The turtle should always turn by 90 degrees. Instead, we found that it turned by %s degrees in one call to turn_right()." % command.angle)
		elif command.command == "jump":
			if turn_right_between_jumps != 4:
				return tr("The turtle should turn four times to draw a square so that it always starts drawing the squares in the same direction. Did you call turn_right() four times?")
	return ""


func test_turtle_starts_each_square_facing_towards_the_right() -> String:
	if not is_equal_approx(wrapf(turtle.turn_degrees, 0.0, 360.0), 0.0):
		return tr(
			"The turtle should be facing towards the right to draw squares in the same direction every time. Did you call turn_right(90) four times in your function?"
		)
	return ""


func test_draw_squares_of_varying_sizes() -> String:
	var polygons := turtle.get_polygons()
	for index in polygons.size():
		var p = polygons[index]
		var points = Array(p.get_points())
		points.sort()
		var points_count = points.size()
		if points_count > 5:
			return tr(
				"The drawn shape has too many points. Did you call move_forward() more than 4 times?"
			)
		elif points_count < 5:
			return tr(
				"The drawn shape has too few points. Did you call move_forward() less than 4 times?"
			)
		if points != expected_rects[index]:
			return tr(
				"The shape is not a square or not turned in the expected direction. Did you use 90 degree angles when calling turn_right()?"
			)
	return ""
