extends DrawingTurtlePracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100), Vector2(0, 0)]
]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Turtle Ends Facing Towards The Right"), tr(""), test_turtle_ends_facing_towards_the_right))
	checks.append(Check.new(tr("Turtle Starts Each Square Facing Towards The Right"), tr(""), test_turtle_starts_each_square_facing_towards_the_right))
	checks.append(Check.new(tr("Draw Squares Of Varying Sizes"), tr(""), test_draw_squares_of_varying_sizes))


func test_turtle_ends_facing_towards_the_right() -> String:
	if shape_count_is(0):
		return tr("The turtle did not draw anything. Make sure your function calls move_forward(length) to move the turtle.")
	if shape_count_fewer_than(2):
		return tr("The turtle drew fewer than 2 shapes. Make sure your function is repeatable.")
	if shape_count_greater_than(2):
		return tr("The turtle drew more than 2 shapes. Make sure your function only draws one shape.")
	
	var turn_right_between_jumps := 0
	for command in _get_turtle().get_command_stack():
		if command.command == "turn":
			turn_right_between_jumps += 1
			if not is_equal_approx(command.angle, 90.0):
				return tr("The turtle should always turn by 90 degrees. Instead, we found that it turned by %s degrees in one call to turn_right()." % command.angle)
		elif command.command == "jump":
			if turn_right_between_jumps != 4:
				return tr("The turtle should turn four times to draw a square so that it always starts drawing the squares in the same direction. Did you call turn_right() four times?")
	return ""


func test_turtle_starts_each_square_facing_towards_the_right() -> String:
	if shape_count_is(0):
		return tr("The turtle did not draw anything. Make sure your function calls move_forward(length) to move the turtle.")
	if shape_count_fewer_than(2):
		return tr("The turtle drew fewer than 2 shapes. Make sure your function is repeatable.")
	if shape_count_greater_than(2):
		return tr("The turtle drew more than 2 shapes. Make sure your function only draws one shape.")
	
	if not turtle_faces_right():
		return tr(
			"The turtle should be facing towards the right to draw squares in the same direction every time. Did you call turn_right(90) four times in your function?"
		)
	return ""


func test_draw_squares_of_varying_sizes() -> String:
	if shape_count_is(0):
		return tr("The turtle did not draw anything. Make sure your function calls move_forward(length) to move the turtle.")
	if shape_count_fewer_than(2):
		return tr("The turtle drew fewer than 2 shapes. Make sure your function is repeatable.")
	if shape_count_greater_than(2):
		return tr("The turtle drew more than 2 shapes. Make sure your function only draws one shape.")
	
	for index in get_shape_count():
		if shape_has_fewer_than(index, 5):
			return tr(
				"The drawn shape has too many points. Did you call move_forward() more than 4 times?"
			)
		if shape_has_greater_than(index, 5):
			return tr(
				"The drawn shape has too few points. Did you call move_forward() less than 4 times?"
			)
		if not shape_is(index, expected_rects[index]):
			return tr(
				"The shape is not a square or not turned in the expected direction. Did you use 90 degree angles when calling turn_right()?"
			)
	return ""
