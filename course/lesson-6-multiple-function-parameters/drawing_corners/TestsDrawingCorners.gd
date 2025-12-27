extends PracticeTester

var expected_corners: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(0, 0), Vector2(240, 0), Vector2(240, 240)]),
	PackedVector2Array([Vector2(0, 0), Vector2(120, 0), Vector2(120, 120)]),
]

func _init() -> void:
	for i in range(expected_corners.size()):
		var arr := Array(expected_corners[i])
		arr.sort()
		expected_corners[i] = PackedVector2Array(arr)

func test_draw_corners_of_varying_lengths() -> String:
	var turtle := _scene_root_viewport.get_child(0) as DrawingTurtle
	if not turtle:
		return "Error: Turtle node not found."
		
	var polygons := turtle.get_polygons()
	
	for index in range(polygons.size()):
		var p := polygons[index] as DrawingTurtle.Polygon
		if not p:
			continue
			
		var raw_points: PackedVector2Array = p.call(&"get_points")
		var points := Array(raw_points)
		points.sort()
		
		var points_count := points.size()
		
		if points_count > 3:
			return tr("The drawn shape has too many points. Did you call move_forward() more than 2 times?")
		elif points_count < 3:
			return tr("The drawn shape has too few points. Did you call move_forward() less than 2 times?")
		
		if not expected_corners[index] == PackedVector2Array(points):
			return tr("The drawn shape doesn't have the expected size. Did you use the length parameter?")

	return ""
