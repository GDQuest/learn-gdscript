extends DrawingTurtlePracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(260, 0), Vector2(260, 180), Vector2(0, 180), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(160, 0), Vector2(160, 210), Vector2(0, 210), Vector2(0, 0)]
]
var swapped_rects := [
	[Vector2(0, 0), Vector2(180, 0), Vector2(180, 260), Vector2(0, 260), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(210, 0), Vector2(210, 160), Vector2(0, 160), Vector2(0, 0)]
]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Draw Rectangles Of Varying Sizes"), tr(""), test_draw_rectangles_of_varying_sizes))


func test_draw_rectangles_of_varying_sizes() -> String:
	if shape_count_is(0):
		return tr("The turtle did not draw anything. Make sure your function calls move_forward(length) to move the turtle.")
	if shape_count_fewer_than(2):
		return tr("The turtle drew fewer than 2 shapes. Make sure your function is repeatable.")
	if shape_count_greater_than(2):
		return tr("The turtle drew more than 2 shapes. Make sure your function only draws one shape.")
	
	var shape_count := get_shape_count()
	for index in shape_count:
		if shape_has_fewer_than(index, 5):
			return tr("The drawn shape has too few points. Did you call move_forward() less than 4 times?")
		if shape_has_greater_than(index, 5):
			return tr("The drawn shape has too many points. Did you call move_forward() more than 4 times?")
		
		if shape_is(index, swapped_rects[index]):
			return tr("The length and height are inverted. Did you swap the length and height function arguments?")
		if not shape_is(index, expected_rects[index]):
			return tr("The drawn shapes don't have the expected length and height. Did you forget to use the length and height parameter?")
	return ""
