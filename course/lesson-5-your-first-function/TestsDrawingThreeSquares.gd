extends DrawingTurtlePracticeTester

var target_polygon := [
	Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)
]


func _get_turtle() -> DrawingTurtle:
	return _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Draw Three Squares Of 200 Pixels"), tr(""), test_draw_three_squares_of_200_pixels))


func test_draw_three_squares_of_200_pixels() -> String:
	if shape_count_is(0):
		return tr("Nothing drawn. Did you not call draw_square()?")

	if shape_count_is(1):
		return tr("You only drew one square. You need to draw three.")
	elif shape_count_fewer_than(3):
		return tr("You need to draw three squares.")
	elif shape_count_is(4):
		if not shape_is(3, []):
			return tr("You drew more than three squares. You need to draw only three!")
	elif shape_count_greater_than(4):
		return tr("You drew more than three squares. You need to draw only three!")

	var shape_count := get_shape_count()
	for index in shape_count:
		if shape_has_fewer_than(index, target_polygon.size()):
			return(
				tr("Shape3D number %s has too few corners! Did you change the draw_square() function?")
				% index
			)
		if shape_has_greater_than(index, target_polygon.size()):
			return(
				tr("Shape3D number %s has too many corners! Did you change the draw_square() function?")
				% index
			)
		if not shape_is(index, target_polygon):
			return (
				tr("Shape3D number %s is not a square of length 200 pixels. Did you change the draw_square() function?")
				% index
			)

	var turtle := _get_turtle()
	for first_index in range(3):
		var first_rect: Rect2 = turtle.get_polygons()[first_index].get_positioned_rect()
		for second_index in range(first_index + 1, 3):
			var second_rect: Rect2 = turtle.get_polygons()[second_index].get_positioned_rect()
			if first_rect.intersects(second_rect):
				return tr("The squares should not overlap. Did you move the turtle between drawing each square?")
	return ""
