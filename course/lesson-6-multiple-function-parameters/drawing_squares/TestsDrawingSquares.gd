extends PracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100), Vector2(0, 0)]
]


# We sort vertices for accurate comparison
func _init() -> void:
	for rect in expected_rects:
		rect.sort()


func test_draw_squares_of_varying_sizes() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	for index in polygons.size():
		var p = polygons[index]
		var points = Array(p.get_points())
		points.sort()
		var points_count = points.size()
		if points_count > 5:
			return "The drawn shape has too many points. Did you call move_forward() more than 4 times?"
		elif points_count < 5:
			return "The drawn shape has too few points. Did you call move_forward() less than 4 times?"
	return ""
