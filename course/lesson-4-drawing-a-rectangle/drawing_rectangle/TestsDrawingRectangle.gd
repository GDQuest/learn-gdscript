extends DrawingTurtlePracticeTester

var target_polygon := [Vector2(0, 0), Vector2(200, 0), Vector2(200, 120), Vector2(0, 120), Vector2(0, 0)]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Draw Rectangle Of 200 By 120"), tr(""), test_draw_rectangle_of_200_by_120))


func test_draw_rectangle_of_200_by_120() -> String:
	if shape_count_is(0):
		return tr("Nothing drawn. Did you call move_forward()?")

	if not shape_is(0, target_polygon):
		return tr("The drawn shape is not a rectangle with a width of 200 and a length of 120.")

	return ""
