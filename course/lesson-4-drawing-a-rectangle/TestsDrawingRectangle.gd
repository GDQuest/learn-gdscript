extends PracticeTester

var target_polygon := [Vector2(0, 0), Vector2(200, 0), Vector2(200, 120), Vector2(0, 200)]


func _init() -> void:
	target_polygon.sort()


func test_rectangle() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	if polygons.empty():
		return "Nothing drawn. Did you call move_forward()?"

	var rectangle: DrawingTurtle.Polygon = polygons[0]
	var points := rectangle.get_points()
	points.sort()
	if points != target_polygon:
		return "The drawn shape is not a rectangle with a width of 200 and a length of 120."

	return ""
