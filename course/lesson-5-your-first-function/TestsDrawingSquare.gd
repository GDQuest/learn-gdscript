extends PracticeTester

var target_polygon := [Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)]


func _init() -> void:
	target_polygon.sort()


func test_draw_square_of_200_pixels() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	if polygons.empty():
		return "Nothing drawn. Did you not call move_forward()?"

	var square: DrawingTurtle.Polygon = polygons[0]
	var points := square.points.duplicate()
	points.sort()
	if points != target_polygon:
		return "The drawn shape is not a square of length 200 pixels."

	return ""
