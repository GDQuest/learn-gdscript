extends DrawingTurtlePracticeTester

var expected_corners := [
	[Vector2(0, 0), Vector2(240, 0), Vector2(240, 240)],
	[Vector2(0, 0), Vector2(120, 0), Vector2(120, 120)],
]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Draw Corners Of Varying Lengths"), tr(""), test_draw_corners_of_varying_lengths))


func test_draw_corners_of_varying_lengths() -> String:
	if shape_count_is(0):
		return tr("The turtle did not draw anything. Make sure your function calls move_forward(length) to move the turtle.")
	if shape_count_fewer_than(2):
		return tr("The turtle drew fewer than 2 shapes. Make sure your function is repeatable.")
	if shape_count_greater_than(2):
		return tr("The turtle drew more than 2 shapes. Make sure your function only draws one shape.")
	
	var shape_count := get_shape_count()
	for index in shape_count:
		if shape_has_fewer_than(index, 3):
			return tr("The drawn shape has too few points. Did you call move_forward() less than 2 times?")
		if shape_has_greater_than(index, 3):
			return tr("The drawn shape has too many points. Did you call move_forward() more than 2 times?")
		if not shape_is(index, expected_corners[index]):
			return tr("The drawn shape doesn't have the expected size. Did you use the length parameter?")
	return ""
