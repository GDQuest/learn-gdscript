extends PracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100), Vector2(0, 0)]
]

var turtle: DrawingTurtle
# Number of times the user calls turn_right(90) on the turtle.
var turn_right_count := 0


# We sort vertices for accurate comparison
func _init() -> void:
	for rect in expected_rects:
		rect.sort()


func _prepare():
	turtle = _scene_root_viewport.get_child(0)

	turn_right_count = 0
	for line in _slice.current_text.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if line.empty():
			continue

		if line.begins_with("turn_right(90)"):
			turn_right_count += 1


func test_turtle_ends_facing_towards_the_right() -> String:
	if turn_right_count != 4:
		return tr(
			"The turtle should be facing towards the right to draw squares in the same direction every time. Did you call turn_right(90) four times in your function?"
		)
	return ""


func test_draw_squares_of_varying_sizes() -> String:
	var polygons := turtle.get_polygons()
	for index in polygons.size():
		var p = polygons[index]
		var points = Array(p.get_points())
		points.sort()
		var points_count = points.size()
		if points_count > 5:
			return tr(
				"The drawn shape has too many points. Did you call move_forward() more than 4 times?"
			)
		elif points_count < 5:
			return tr(
				"The drawn shape has too few points. Did you call move_forward() less than 4 times?"
			)
		if points != expected_rects[index]:
			return tr(
				"The shape is not a square or not turned in the expected direction. Did you use 90 degree angles when calling turn_right()?"
			)
	return ""
