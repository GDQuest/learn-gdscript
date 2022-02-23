extends PracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(260, 0), Vector2(260, 180), Vector2(0, 180), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(160, 0), Vector2(160, 210), Vector2(0, 210), Vector2(0, 0)]
]
var swapped_rects := [
	[Vector2(0, 0), Vector2(180, 0), Vector2(180, 260), Vector2(0, 260), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(210, 0), Vector2(210, 160), Vector2(0, 160), Vector2(0, 0)]
]


# We sort vertices for accurate comparison
func _init() -> void:
	for rect in expected_rects:
		rect.sort()
	for rect in swapped_rects:
		rect.sort()


func test_draw_rectangles_of_varying_sizes() -> String:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	var polygons := turtle.get_polygons()
	for index in polygons.size():
		var p = polygons[index]
		var points = Array(p.get_points())
		# We make all points absolute in case the user turns counter-clockwise when
		# making the shape.
		for i in points.size():
			points[i] = points[i].abs()
		points.sort()
		var points_count = points.size()
		if points_count > 5:
			return tr("The drawn shape has too many points. Did you call move_forward() more than 4 times?")
		elif points_count < 5:
			return tr("The drawn shape has too few points. Did you call move_forward() less than 4 times?")

		if points == swapped_rects[index]:
			return tr("The length and height are inverted. Did you swap the length and height function arguments?")
		elif points != expected_rects[index]:
			return tr("The drawn shapes don't have the expected length and height. Did you forget to use the length and height parameter?")
	return ""
