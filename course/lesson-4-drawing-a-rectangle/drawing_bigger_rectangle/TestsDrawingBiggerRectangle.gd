extends DrawingTurtlePracticeTester

var target_polygon := [Vector2(0, 0), Vector2(220, 0), Vector2(220, 260), Vector2(0, 260), Vector2(0, 0)]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Draw Rectangle Of 220 By 260"), tr(""), test_draw_rectangle_of_220_by_260))


func test_draw_rectangle_of_220_by_260() -> String:
	if shape_count_is(0):
		return tr("Nothing drawn. Did you call move_forward()?")
	
	if not shape_is(0, target_polygon):
		return tr("The drawn shape is not a rectangle with a width of 220 and a length of 260.")
	
	return ""
