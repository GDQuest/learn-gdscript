extends PracticeTester

var target_polygon := [
	Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)
]


func _init() -> void:
	target_polygon.sort()


func test_draw_square_of_200_pixels() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	if polygons.empty():
		return "Nothing drawn. Did you not call draw_square()?"

	var count := polygons.size()
	if count == 1:
		return "You only drew one square. You need to draw three."
	elif count < 3:
		return "You need to draw three squares."
	elif count > 3:
		if polygons.size() == 4 and not polygons.back().is_empty():
			return "You drew more than three squares. You need to draw only three!"

	var index := 1
	for p in polygons:
		var points = Array(p.get_points())
		# We make all points absolute in case the user turns counter-clockwise when
		# making the shape.
		for i in points.size():
			points[i] = points[i].abs()
		points.sort()
		if points != target_polygon:
			return (
				"Shape number %s is not a square of length 200 pixels. Did you change the draw_square() function?"
				% index
			)
		index += 1
		if index == 4:
			break
	return ""
