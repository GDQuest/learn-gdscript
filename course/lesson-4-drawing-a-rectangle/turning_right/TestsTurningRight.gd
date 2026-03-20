extends PracticeTester

var target_polygon := [Vector2(200, 0), Vector2(200, 200), Vector2(0, 0)]


func _init() -> void:
	target_polygon.sort()


func test_draw_corner_of_200_by_200() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	if polygons.is_empty():
		return tr("Nothing drawn. Did you call move_forward()?")

	var rectangle: DrawingTurtle.Polygon = polygons[0]
	var points := Array(rectangle.get_points())
	# We make all points absolute in case the user turns counter-clockwise when
	# making the shape.
	for i in points.size():
		points[i] = points[i].abs()
	points.sort()
	if points != target_polygon:
		return tr("The drawn shape is not a corner connected by two lines of length 200.")

	return ""
