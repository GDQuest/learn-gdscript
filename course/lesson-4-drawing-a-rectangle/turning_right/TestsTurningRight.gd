extends DrawingTurtlePracticeTester

var target_polygon := [Vector2(200, 0), Vector2(200, 200), Vector2(0, 0)]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Draw Corner Of 200 By 200"), tr(""), test_draw_corner_of_200_by_200))


func test_draw_corner_of_200_by_200() -> String:
	if shape_count_is(0):
		return tr("Nothing drawn. Did you call move_forward()?")

	if not shape_is(0, target_polygon):
		return tr("The drawn shape is not a corner connected by two lines of length 200.")

	return ""
