extends PracticeTester

var expected_corners := [
	[Vector2(0, 0), Vector2(240, 0), Vector2(240, 240)],
	[Vector2(0, 0), Vector2(120, 0), Vector2(120, 120)],
]


# We sort vertices for accurate comparison
func _init() -> void:
	for rect in expected_corners:
		rect.sort()


func test_draw_corners_of_varying_lengths() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	for index in polygons.size():
		var p = polygons[index]
		var points = Array(p.get_points())
		points.sort()
		var points_count = points.size()
		if points_count > 3:
			return tr("The drawn shape has too many points. Did you call move_forward() more than 2 times?")
		elif points_count < 3:
			return tr("The drawn shape has too few points. Did you call move_forward() less than 2 times?")
		elif not expected_corners[index] == points:
			return tr("The drawn shape doesn't have the expected size. Did you use the length parameter?")

	return ""
